param(
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [Parameter(Mandatory = $true)][int]$ManagerPid,
    [string]$CachePath = ""
)

# Snapshot state is separate for every Chrome profile.
$clients = @{}
$utf8 = [Text.UTF8Encoding]::new($false)

# Replace a complete file without exposing partially written records.
function Write-Atomic([string]$Path, [string]$Text) {
    $temporary = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        [IO.File]::WriteAllText($temporary, $Text, $utf8)
        if ([IO.File]::Exists($Path)) { [IO.File]::Replace($temporary, $Path, $null) }
        else { [IO.File]::Move($temporary, $Path) }
    } finally { Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue }
}

# Only explicit HTTP(S) data can be returned as a URL-open command.
function Test-WebUrl([string]$Value) {
    $parsed = $null
    return ($Value -notmatch '[\t\r\n]' -and [Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$parsed) -and $parsed.Scheme -in @('http','https') -and $parsed.Host.Length -gt 0)
}

# Publish all recently connected profiles, preserving the six legacy columns.
function Publish-Snapshots {
    $now = [DateTime]::UtcNow
    foreach ($key in @($clients.Keys)) {
        if (($now - $clients[$key].Seen).TotalSeconds -gt 90) { $clients.Remove($key) }
    }
    $lines = [System.Collections.Generic.List[string]]::new()
    $cached = [System.Collections.Generic.List[string]]::new()
    foreach ($snapshot in $clients.Values) {
        foreach ($line in $snapshot.Lines) {
            $lines.Add($line)
            $cached.Add((($line -split "`t", 7)[0..5] -join "`t"))
        }
    }
    Write-Atomic $OutputPath ($lines -join "`n")
    if ($CachePath) { Write-Atomic $CachePath ($cached -join "`n") }
}

# Acknowledge only commands belonging to the posting profile; bound queue lifetime.
function Get-Commands([string]$ClientId, $Acks) {
    $commands = [System.Collections.Generic.List[object]]::new()
    $directory = "$OutputPath.commands"
    if (-not (Test-Path -LiteralPath $directory)) { return @() }
    foreach ($file in @(Get-ChildItem -LiteralPath $directory -Filter '*.tsv' -File)) {
        if (([DateTime]::UtcNow - $file.LastWriteTimeUtc).TotalMinutes -gt 5) {
            Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
            continue
        }
        $id = $file.BaseName
        if ($id -notmatch '^[A-Za-z0-9_-]{1,128}$') { continue }
        $fields = [IO.File]::ReadAllText($file.FullName, $utf8) -split "`t"
        if ($fields.Count -lt 2 -or $fields[0] -cne $ClientId) { continue }
        if (@($Acks) -ccontains $id) {
            Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
        } elseif ($commands.Count -lt 10) {
            if ($fields.Count -eq 2 -and (Test-WebUrl $fields[1])) {
                $commands.Add(@{ id = $id; type = 'open_url'; url = $fields[1] })
            } elseif (
                $fields.Count -eq 4 -and
                $fields[1] -ceq 'detach_tab' -and
                $fields[2] -match '^[1-9][0-9]{0,15}$' -and
                $fields[3] -match '^[1-9][0-9]{0,15}$'
            ) {
                $commands.Add(@{
                    id = $id
                    type = 'detach_tab'
                    window_id = [long]$fields[2]
                    tab_id = [long]$fields[3]
                })
            }
        }
    }
    return $commands.ToArray()
}

# Accept domain snapshots only on this computer. Never send browsing data to a remote server.
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 18763)
try {
    $listener.Start()
} catch {
    exit 1
}

try {
    while ($null -ne (Get-Process -Id $ManagerPid -ErrorAction SilentlyContinue)) {
        if (-not $listener.Pending()) {
            if (@($clients.Values | Where-Object { ([DateTime]::UtcNow - $_.Seen).TotalSeconds -gt 90 }).Count -gt 0) { Publish-Snapshots }
            Start-Sleep -Milliseconds 150
            continue
        }
        $client = $listener.AcceptTcpClient()
        try {
            $client.ReceiveTimeout = 2000
            $client.SendTimeout = 2000
            $stream = $client.GetStream()
            $raw = [System.Collections.Generic.List[byte]]::new()
            $one = New-Object byte[] 1
            while ($raw.Count -lt 8192) {
                if ($stream.Read($one, 0, 1) -ne 1) { break }
                $raw.Add($one[0])
                $count = $raw.Count
                if ($count -ge 4 -and $raw[$count-4] -eq 13 -and $raw[$count-3] -eq 10 -and $raw[$count-2] -eq 13 -and $raw[$count-1] -eq 10) { break }
            }
            $header = [Text.Encoding]::ASCII.GetString($raw.ToArray())
            $first = ($header -split "`r`n")[0]
            $reply = @{ api_version = 2; commands = @() }
            $length_match = [regex]::Match($header, '(?im)^Content-Length:\s*(\d+)')
            $length = if ($length_match.Success) { [int]$length_match.Groups[1].Value } else { 0 }
            if ($first -match '^POST /domains ' -and $length -gt 0 -and $length -le 65536) {
                $body = New-Object byte[] $length
                $offset = 0
                while ($offset -lt $length) {
                    $read = $stream.Read($body, $offset, $length - $offset)
                    if ($read -le 0) { break }
                    $offset += $read
                }
                if ($offset -eq $length) {
                    $payload = [Text.Encoding]::UTF8.GetString($body) | ConvertFrom-Json
                    $is_v2 = $payload.api_version -eq 2
                    $client_id = if ($is_v2) { [string]$payload.client_id } else { 'legacy' }
                    if ($client_id -notmatch '^[A-Za-z0-9_-]{1,128}$') { throw 'Invalid client identity' }
                    $lines = [System.Collections.Generic.List[string]]::new()
                    foreach ($item in $payload.windows) {
                        $title = [regex]::Replace([string]$item.title, '[\t\r\n]', ' ')
                        $domain = [string]$item.domain
                        if ($domain -ne '' -and $domain -notmatch '^[a-zA-Z0-9.-]{1,253}$') { continue }
                        $fields = @($title, $domain, [int]$item.left, [int]$item.top, [int]$item.width, [int]$item.height)
                        if ($is_v2) {
                            $url = if (Test-WebUrl ([string]$item.url)) { [string]$item.url } else { '' }
                            $visit_id = [regex]::Replace([string]$item.visit_id, '[\t\r\n]', ' ')
                            $tab_count = [Math]::Max(0, [Math]::Min(10000, [int]$item.tab_count))
                            $fields += @($url, $client_id, [long]$item.window_id, [long]$item.tab_id, [long]$item.visited_at, $visit_id, $tab_count)
                        }
                        $lines.Add(($fields -join "`t"))
                    }
                    $clients[$client_id] = @{ Seen = [DateTime]::UtcNow; Lines = $lines }
                    Publish-Snapshots
                    if ($is_v2) { $reply.commands = @(Get-Commands $client_id $payload.acks) }
                }
            }
            $json = ConvertTo-Json -InputObject $reply -Compress -Depth 5
            $body_bytes = [Text.Encoding]::UTF8.GetBytes($json)
            $response = "HTTP/1.1 200 OK`r`nAccess-Control-Allow-Origin: *`r`nAccess-Control-Allow-Private-Network: true`r`nAccess-Control-Allow-Headers: content-type`r`nAccess-Control-Allow-Methods: POST, OPTIONS`r`nContent-Type: application/json; charset=utf-8`r`nContent-Length: $($body_bytes.Length)`r`nConnection: close`r`n`r`n"
            $header_bytes = [Text.Encoding]::ASCII.GetBytes($response)
            $bytes = New-Object byte[] ($header_bytes.Length + $body_bytes.Length)
            [Array]::Copy($header_bytes, 0, $bytes, 0, $header_bytes.Length)
            [Array]::Copy($body_bytes, 0, $bytes, $header_bytes.Length, $body_bytes.Length)
            $stream.Write($bytes, 0, $bytes.Length)
        } catch {
            # A malformed local request must not terminate the listener.
        } finally {
            $client.Close()
        }
    }
} finally {
    $listener.Stop()
    Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue
}

