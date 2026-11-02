#Requires AutoHotkey v2.0

/*
Checks whether text is a valid HTTP or HTTPS URL.
Used before URLs are written to the yt-dlp batch file.
*/
isHttpUrl(url)
{
    return RegExMatch(Trim(url), "i)^https?://[^\s]+$") = 1
}

/*
Splits multiline URL input and keeps only valid HTTP/HTTPS URLs.
Blank lines are ignored and duplicates are removed while preserving order.
*/
parseUrlList(text)
{
    urls := []
    seen := Map()

    Loop Parse text, "`n", "`r"
    {
        url := Trim(A_LoopField)

        if (url = "")
        {
            continue
        }

        if (!isHttpUrl(url))
        {
            throw Error("Invalid URL: " url)
        }

        if (!seen.Has(url))
        {
            urls.Push(url)
            seen[url] := true
        }
    }

    return urls
}

/*
Returns yt-dlp format arguments for the selected download preset.
The returned string is safe to append to a generated Windows CMD file.
*/
getQualityArgs(preset)
{
    switch preset
    {
        case "Best MP4":
            return "-f " quoteArg("bv*+ba/b") " --merge-output-format mp4 --remux-video mp4"

        case "1080p MP4":
            return "-f " quoteArg("bv*[height<=1080]+ba/b[height<=1080]") " --merge-output-format mp4 --remux-video mp4"

        case "720p MP4":
            return "-f " quoteArg("bv*[height<=720]+ba/b[height<=720]") " --merge-output-format mp4 --remux-video mp4"

        case "Audio MP3":
            return "-x --audio-format mp3 --audio-quality 0"

        default:
            throw Error("Unknown quality preset: " preset)
    }
}

/*
Returns the yt-dlp cookies-from-browser argument for the selected browser.
An empty string means that no browser cookies should be used.
*/
getBrowserArgs(browser_name)
{
    switch browser_name
    {
        case "No cookies":
            return ""

        case "Chrome":
            return " --cookies-from-browser chrome"

        case "Edge":
            return " --cookies-from-browser edge"

        case "Firefox":
            return " --cookies-from-browser firefox"

        default:
            throw Error("Unknown browser selection: " browser_name)
    }
}

/*
Quotes one Windows command-line argument.
Embedded double quotes are escaped for normal command-line parsing.
*/
quoteArg(value)
{
    quote := Chr(34)
    value := StrReplace(value, quote, "\" quote)
    return quote value quote
}

/*
Escapes one path or text value for a single-quoted PowerShell string.
This is used by the dependency installer.
*/
quotePowerShell(value)
{
    return "'" StrReplace(value, "'", "''") "'"
}

/*
Builds the static yt-dlp argument string used by the generated command file.
URLs are supplied separately through --batch-file rather than interpolated here.
*/
buildYtDlpArgs(batch_path, output_dir, preset, browser_name, allow_playlist := false)
{
    output_template := output_dir "\%%(title)s [%%(id)s].%%(ext)s"
    progress_template := "download:PROGRESS:%%(progress._percent_str)s|%%(progress._speed_str)s|%%(progress._eta_str)s"

    args := "--newline --no-warnings --encoding utf-8 --windows-filenames"
    args .= " --progress-template " quoteArg(progress_template)
    args .= " --ffmpeg-location " quoteArg(A_ScriptDir "\lib")
    args .= " --batch-file " quoteArg(batch_path)
    args .= " -o " quoteArg(output_template)
    args .= getBrowserArgs(browser_name)

    if (!allow_playlist)
    {
        args .= " --no-playlist"
    }

    args .= " " getQualityArgs(preset)

    return args
}
