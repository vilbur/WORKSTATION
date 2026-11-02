/* Chrome history state is independent from the live-window list.
*/
global chrome_history_file := ""
global history_items := Map()
global history_observed := Map()
global history_rows := Map()
global history_list := ""
global history_splitter := ""
global history_header := ""
global history_menu_key := ""
global history_split_dragging := false
global history_tip_visible := false
global history_last_signature := ""
global history_client_width := 220
global history_client_height := 500
global history_split_ratio := 0.5
global options_history_limit := ""
global options_history_sort := ""
global options_history_show := ""
global history_bridge_v2 := false
global history_live_urls := Map()
global history_open_requests := []
global history_claimed_windows := Map()
global history_reopened_windows := Map()

/* Create the independent bottom list before the manager is first shown.
*/
initChromeHistory()
{
    global chrome_history_file, history_split_ratio, history_list, history_splitter, history_header
    chrome_history_file := project_dir "\Window-List-Manager.chrome-history.tsv"
    saved_ratio := IniRead(settings_file, "History", "SplitRatio", "0.5")
    history_split_ratio := IsNumber(saved_ratio) ? Max(0.15, Min(0.85, Number(saved_ratio))) : 0.5
    history_splitter := manager_gui.AddText("x1 y245 w218 h6 Background555D68 +0x100 Hidden", "")
    history_header := manager_gui.AddText("x3 y252 w214 h20 cE8EAED Background343A43 +0x200 +0x100 Hidden", "Chrome history")
    history_header.SetFont("s9 cE8EAED")
    history_header.OnEvent("Click", toggleHistorySort)
    history_list := manager_gui.AddListView("x1 y273 w218 h226 -Multi -Hdr +0x8 Hidden", ["Chrome history"])
    history_list.OnEvent("DoubleClick", openHistoryPage)
    history_list.OnEvent("ContextMenu", historyContextMenu)
    loadChromeHistory()
}

/* Return the saved page limit, rejecting corrupt or impractically large values.
*/
getHistoryLimit()
{
    value := IniRead(settings_file, "History", "Limit", "20")
    return RegExMatch(value, "^[1-9][0-9]{0,4}$") && Integer(value) <= 10000 ? Integer(value) : 20
}

/* Read history's sort independently of the live window order.
*/
getHistorySort()
{
    return IniRead(settings_file, "History", "Sort", "Recent") = "Alphabetical" ? "Alphabetical" : "Recent"
}

/* Resolve the nearest domain history rule; disabled children override enabled parents.
*/
getHistoryRuleDomain(domain)
{
    candidate := normalizeDomainName(domain)
    while InStr(candidate, ".")
    {
        rule := IniRead(settings_file, "DomainHistory", candidate, "")
        if (rule = "0")
            return ""
        if (rule = "1")
            return candidate
        candidate := SubStr(candidate, InStr(candidate, ".") + 1)
    }
    return ""
}

/* Validate saved/opened URLs and return their normalized hostnames.
*/
historyDomainFromUrl(url)
{
    if (StrLen(url) > 16384 || RegExMatch(url, "[\x00-\x20\x7F]"))
        return ""
    if !RegExMatch(url, "i)^https?://([^/?#:@]+)(?::[0-9]+)?(?:[/?#]|$)", &match)
        return ""
    return normalizeDomainName(match[1])
}

/* Replace field delimiters without losing the complete already-encoded URL.
*/
historyField(value)
{
    return RegExReplace(value, "[\t\r\n]", " ")
}

/* Restore valid rows individually so one damaged line cannot discard the file.
*/
loadChromeHistory()
{
    global history_items, history_observed
    history_items := Map()
    history_observed := Map()
    if !FileExist(chrome_history_file)
        return
    try
    {
        for line in StrSplit(FileRead(chrome_history_file, "UTF-8"), "`n")
        {
            fields := StrSplit(Trim(line, "`r"), "`t")
            if (fields.Length = 4 && fields[1] = "@seen" && RegExMatch(fields[2], "^[a-zA-Z0-9_-]{1,128}$") && RegExMatch(fields[3], "^[0-9]+$"))
            {
                history_observed[fields[2] "`t" fields[3]] := fields[4]
                continue
            }
            if (fields.Length != 9 || !RegExMatch(fields[4], "^[0-9]{1,16}$"))
                continue
            domain := historyDomainFromUrl(fields[2])
            if (domain = "" || domain != fields[1] || !RegExMatch(fields[5], "^[a-zA-Z0-9_-]{1,128}$"))
                continue
            key := domain "`t" fields[2]
            history_items[key] := {domain: domain, url: fields[2], title: fields[3], last_seen: Integer(fields[4]), client: fields[5], window_id: fields[6], tab_id: fields[7], visit_id: fields[8], bucket: fields[9]}
        }
        trimChromeHistory()
    }
}

/* Persist atomically; a failed write leaves the previous history file intact.
*/
saveChromeHistory()
{
    temporary := chrome_history_file ".tmp"
    output := ""
    for key, item in history_items
        output .= historyField(item.domain) "`t" historyField(item.url) "`t" historyField(item.title) "`t" item.last_seen "`t" historyField(item.client) "`t" item.window_id "`t" item.tab_id "`t" historyField(item.visit_id) "`t" historyField(item.bucket) "`n"
    for key, visit_id in history_observed
        output .= "@seen`t" key "`t" historyField(visit_id) "`n"
    file := FileOpen(temporary, "w", "UTF-8-RAW")
    if !IsObject(file)
        throw Error("Chrome history could not be saved.")
    file.Write(output)
    file.Close()
    FileMove(temporary, chrome_history_file, 1)
}

/* Sort history records by title or last real page observation with stable ties.
*/
sortHistoryItems(items, mode)
{
    result := []
    for item in items
    {
        insert_at := result.Length + 1
        for index, existing in result
        {
            comparison := mode = "Alphabetical" ? StrCompare(item.title, existing.title) : existing.last_seen - item.last_seen
            if !comparison
                comparison := StrCompare(item.url, existing.url)
            if (comparison < 0)
            {
                insert_at := index
                break
            }
        }
        result.InsertAt(insert_at, item)
    }
    return result
}

/* Keep the most recent pages per enabled domain regardless of display sort mode.
*/
trimChromeHistory()
{
    items := []
    counts := Map()
    changed := false
    for key, item in history_items
        items.Push(item)
    for item in sortHistoryItems(items, "Recent")
    {
        rule := getHistoryRuleDomain(item.domain)
        bucket := rule != "" ? rule : (item.bucket != "" ? item.bucket : item.domain)
        item.bucket := bucket
        counts[bucket] := counts.Get(bucket, 0) + 1
        if (counts[bucket] > getHistoryLimit())
        {
            history_items.Delete(item.domain "`t" item.url)
            changed := true
        }
    }
    return changed
}

/* Collect only fresh API v2 pages; unchanged heartbeats never advance recency.
*/
observeChromeHistory(records)
{
    global history_bridge_v2
    changed := false
    for record in records
    {
        if (!record.HasOwnProp("url") || record.url = "" || !record.live)
            continue
        history_bridge_v2 := true
        domain := historyDomainFromUrl(record.url)
        bucket := getHistoryRuleDomain(domain)
        if (domain = "" || bucket = "" || !RegExMatch(record.client, "^[a-zA-Z0-9_-]{1,128}$") || !RegExMatch(record.visited_at, "^[0-9]{1,16}$"))
            continue
        key := domain "`t" record.url
        observation_key := record.client "`t" record.window_id
        if (history_observed.Get(observation_key, "") = record.visit_id && !history_items.Has(key))
            continue
        if (history_observed.Get(observation_key, "") != record.visit_id)
        {
            history_observed[observation_key] := record.visit_id
            changed := true
            if (history_observed.Count > 512)
            {
                for old_key in history_observed
                {
                    history_observed.Delete(old_key)
                    break
                }
            }
        }
        seen := Integer(record.visited_at)
        if history_items.Has(key)
        {
            existing := history_items[key]
            if (existing.visit_id = record.visit_id && existing.client = record.client)
            {
                if (existing.title != record.title)
                {
                    existing.title := record.title
                    changed := true
                }
                continue
            }
            if (seen < existing.last_seen)
                continue
        }
        history_items[key] := {domain: domain, url: record.url, title: record.title != "" ? record.title : record.url, last_seen: seen, client: record.client, window_id: record.window_id, tab_id: record.tab_id, visit_id: record.visit_id, bucket: bucket}
        changed := true
    }
    if changed
    {
        trimChromeHistory()
        try saveChromeHistory()
        catch as history_error
            history_header.Text := history_error.Message
        updateChromeHistoryList(true)
    }
    else
        updateChromeHistoryList()
}

/* Show the history area when enabled and at least one domain is configured or saved.
*/
isChromeHistoryVisible()
{
    if (IniRead(settings_file, "History", "Show", "1") != "1")
        return false
    if history_items.Count
        return true
    try
        return RegExMatch(IniRead(settings_file, "DomainHistory"), "m)=1(?:\r?$)") != 0
    return false
}

/* Compute top/bottom anchoring with enough room for both lists at any panel size.
*/
getHistoryLayout(width, height, visible, ratio)
{
    available := Max(60, height - 19)
    if !visible
        return {live_height: available, splitter_y: 0, history_y: 0, history_height: 0}
    live_height := Max(28, Min(available - 54, Round((available - 26) * ratio)))
    history_y := 18 + live_height + 26
    return {live_height: live_height, splitter_y: 18 + live_height, history_y: history_y, history_height: Max(28, height - history_y - 1)}
}

/* Resize the two native lists while retaining top and bottom edges.
*/
layoutChromeHistory(width, height)
{
    global history_client_width, history_client_height
    history_client_width := width
    history_client_height := height
    visible := isChromeHistoryVisible()
    rect := getHistoryLayout(width, height, visible, history_split_ratio)
    window_list.Move(1, 18, Max(20, width - 2), rect.live_height)
    window_list.ModifyCol(1, Max(20, width - 6))
    if !IsObject(history_list)
        return
    history_list.Visible := visible
    history_splitter.Visible := visible
    history_header.Visible := visible
    if !visible
        return
    history_splitter.Move(1, rect.splitter_y, Max(20, width - 2), 6)
    history_header.Move(3, rect.splitter_y + 6, Max(20, width - 6), 20)
    history_list.Move(1, rect.history_y, Max(20, width - 2), rect.history_height)
    history_list.ModifyCol(1, Max(20, width - 6))
}

/* Collect URLs of pending launches and reopened Chrome windows that still exist.
*/
getOpenedHistoryUrls()
{
    opened_urls := Map()
    stale_hwnds := []
    for request in history_open_requests
        opened_urls[request.url] := true
    for hwnd, opened in history_reopened_windows
    {
        is_open := false
        try is_open := WinExist("ahk_id " hwnd) && WinGetPID("ahk_id " hwnd) = opened.pid
        if is_open
            opened_urls[opened.url] := true
        else
            stale_hwnds.Push(hwnd)
    }
    for hwnd in stale_hwnds
        history_reopened_windows.Delete(hwnd)
    return opened_urls
}

/* Exclude live pages and history URLs opened without a bridge match.
*/
getVisibleHistoryItems(items, live_urls)
{
    visible := []
    opened_urls := getOpenedHistoryUrls()
    for item in items
    {
        if (!live_urls.Has(item.url) && !opened_urls.Has(item.url))
            visible.Push(item)
    }
    return visible
}

/* Rebuild only the separate history list and preserve its selected URL.
*/
updateChromeHistoryList(force := false)
{
    global history_last_signature
    if !IsObject(history_list)
        return
    items := []
    signature := getHistorySort() "|" getDefaultFontColor()
    for key, item in history_items
        items.Push(item)
    items := getVisibleHistoryItems(items, history_live_urls)
    for item in items
    {
        signature .= item.domain "`t" item.url "|" item.title "|" item.last_seen "|" getGroupColor("chrome.exe", item.title, item.domain)
    }
    if (signature != history_last_signature || force)
    {
        selected_key := history_rows.Get(history_list.GetNext(), "")
        history_last_signature := signature
        history_list.Opt("-Redraw")
        history_list.Delete()
        history_rows.Clear()
        for item in sortHistoryItems(items, getHistorySort())
        {
            key := item.domain "`t" item.url
            row := history_list.Add("", item.title)
            history_rows[row] := key
            if (key = selected_key)
                history_list.Modify(row, "Select")
        }
        history_list.Opt("+Redraw")
        repaintManagerList(history_list)
    }
    history_header.Text := "Chrome history · " getHistorySort() (items.Length ? " (" items.Length ")" : (history_bridge_v2 ? " — empty" : " — update extension"))
    layoutChromeHistory(history_client_width, history_client_height)
}

/* Start a divider drag without initiating the panel's native move operation.
*/
startHistorySplit()
{
    global history_split_dragging
    history_split_dragging := true
    hideHoverClose()
    DllCall("user32\SetCapture", "Ptr", history_splitter.Hwnd, "Ptr")
    SetTimer(updateHistorySplit, 16)
}

/* Track the divider in GUI coordinates and persist its final proportion.
*/
updateHistorySplit(*)
{
    global history_split_dragging, history_split_ratio
    if (!history_split_dragging || !GetKeyState("LButton", "P"))
    {
        history_split_dragging := false
        SetTimer(updateHistorySplit, 0)
        DllCall("user32\ReleaseCapture")
        IniWrite(history_split_ratio, settings_file, "History", "SplitRatio")
        return
    }
    point := Buffer(8, 0)
    DllCall("user32\GetCursorPos", "Ptr", point)
    DllCall("user32\ScreenToClient", "Ptr", manager_gui.Hwnd, "Ptr", point)
    y := NumGet(point, 4, "Int") / (A_ScreenDPI / 96)
    history_split_ratio := Max(0.15, Min(0.85, (y - 18) / Max(1, history_client_height - 45)))
    layoutChromeHistory(history_client_width, history_client_height)
    DllCall("user32\SetCursor", "Ptr", DllCall("user32\LoadCursorW", "Ptr", 0, "Ptr", 32645, "Ptr"), "Ptr")
}

/* Render domain/program colors for history rows independently of live HWNDs.
*/
onChromeHistoryDraw(l_param)
{
    if (NumGet(l_param, A_PtrSize = 8 ? 16 : 8, "Int") != -12)
        return
    stage := NumGet(l_param, A_PtrSize = 8 ? 24 : 12, "UInt")
    if (stage = 1)
        return 0x20
    if (stage != 0x10001)
        return
    row := NumGet(l_param, A_PtrSize = 8 ? 56 : 36, "UPtr") + 1
    key := history_rows.Get(row, "")
    if !history_items.Has(key)
        return
    item := history_items[key]
    NumPut("UInt", toColorRef(getGroupColor("chrome.exe", item.title, item.domain)), l_param, A_PtrSize = 8 ? 80 : 48)
    NumPut("UInt", toColorRef(0x202124), l_param, A_PtrSize = 8 ? 84 : 52)
    return 0x2
}

/* Open a history row in a new Chrome window on the manager's monitor.
*/
openHistoryPage(control := "", row := 0)
{
    key := row ? history_rows.Get(row, "") : history_menu_key
    if history_items.Has(key)
        openHistoryItem(history_items[key])
}

/* Find the installed Chrome executable without using the default URL handler.
*/
getChromeExecutablePath()
{
    for registry_key in ["HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe"]
    {
        try
        {
            chrome_path := RegRead(registry_key)
            if FileExist(chrome_path)
                return chrome_path
        }
    }
    for chrome_path in [EnvGet("LOCALAPPDATA") "\Google\Chrome\Application\chrome.exe", EnvGet("ProgramFiles") "\Google\Chrome\Application\chrome.exe", EnvGet("ProgramFiles(x86)") "\Google\Chrome\Application\chrome.exe"]
    {
        if FileExist(chrome_path)
            return chrome_path
    }
    return "chrome.exe"
}

/* Quote both the executable and URL for a dedicated Chrome window.
*/
buildChromeLaunchCommand(chrome_path, url)
{
    if (historyDomainFromUrl(url) = "" || InStr(url, Chr(34)))
        return ""
    quote := Chr(34)
    return quote chrome_path quote " --new-window " quote url quote
}

/* Read the work area of the monitor containing Window List Manager.
*/
getChromeOpenMonitorArea()
{
    monitor_hwnd := DllCall("user32\MonitorFromWindow", "Ptr", manager_gui.Hwnd, "UInt", 2, "Ptr")
    info := Buffer(40, 0)
    NumPut("UInt", 40, info)
    if (!monitor_hwnd || !DllCall("user32\GetMonitorInfoW", "Ptr", monitor_hwnd, "Ptr", info, "Int"))
        return ""
    return {left: NumGet(info, 20, "Int"), top: NumGet(info, 24, "Int"), right: NumGet(info, 28, "Int"), bottom: NumGet(info, 32, "Int")}
}

/* Center the original outer window rectangle within a monitor work area.
*/
getCenteredChromeRect(width, height, left, top, right, bottom)
{
    work_width := right - left
    work_height := bottom - top
    target_width := Min(width, work_width)
    target_height := Min(height, work_height)
    return {x: left + (work_width - target_width) // 2, y: top + (work_height - target_height) // 2, width: target_width, height: target_height}
}

/* Move the newly created Chrome window without altering another window's size.
*/
centerHistoryChromeWindow(hwnd, area)
{
    if !IsObject(area)
        return
    target := "ahk_id " hwnd
    if (WinGetMinMax(target) != 0)
        WinRestore(target)
    WinGetPos(, , &width, &height, target)
    rect := getCenteredChromeRect(width, height, area.left, area.top, area.right, area.bottom)
    WinMove(rect.x, rect.y, rect.width, rect.height, target)
}

/* Locate each newly opened Chrome HWND and center it once the window is ready.
*/
centerPendingHistoryChromeWindows(*)
{
    chrome_windows := WinGetList("ahk_exe chrome.exe")
    index := 1
    changed := false
    while (index <= history_open_requests.Length)
    {
        request := history_open_requests[index]
        if !request.hwnd
        {
            for hwnd in chrome_windows
            {
                try
                {
                    if (request.existing.Has(hwnd) || history_claimed_windows.Has(hwnd) || !DllCall("user32\IsWindowVisible", "Ptr", hwnd, "Int") || WinGetClass("ahk_id " hwnd) != "Chrome_WidgetWin_1" || WinGetTitle("ahk_id " hwnd) = "")
                        continue
                    request.hwnd := hwnd
                    request.center_after := A_TickCount + 350
                    history_claimed_windows[hwnd] := true
                    history_reopened_windows[hwnd] := {url: request.url, pid: WinGetPID("ahk_id " hwnd)}
                    break
                }
            }
        }
        if (request.hwnd && A_TickCount >= request.center_after)
        {
            try centerHistoryChromeWindow(request.hwnd, request.area)
            history_open_requests.RemoveAt(index)
            changed := true
            continue
        }
        if (A_TickCount >= request.deadline)
        {
            history_open_requests.RemoveAt(index)
            changed := true
            continue
        }
        index += 1
    }
    if !history_open_requests.Length
    {
        SetTimer(centerPendingHistoryChromeWindows, 0)
        history_claimed_windows.Clear()
    }
    if changed
        updateChromeHistoryList(true)
}

/* Launch Chrome directly: its extension is not required to reopen history.
*/
openHistoryItem(item)
{
    command := buildChromeLaunchCommand(getChromeExecutablePath(), item.url)
    if (command = "")
        return false
    existing := Map()
    for hwnd in WinGetList("ahk_exe chrome.exe")
        existing[hwnd] := true
    area := getChromeOpenMonitorArea()
    try
    {
        Run(command)
        history_open_requests.Push({url: item.url, existing: existing, area: area, hwnd: 0, center_after: 0, deadline: A_TickCount + 10000})
        SetTimer(centerPendingHistoryChromeWindows, 100)
        updateChromeHistoryList(true)
        return true
    }
    catch as open_error
    {
        MsgBox(open_error.Message, "Chrome history")
        return false
    }
}

/* Offer explicit history actions without mixing them with live window operations.
*/
historyContextMenu(control, row, is_right_click, x, y)
{
    global history_menu_key
    history_menu_key := history_rows.Get(row, "")
    history_context_menu := createHistoryContextMenu()
    history_context_menu.Show(x, y)
}

/* Build the history actions separately so their creation can be tested without opening a menu.
*/
createHistoryContextMenu()
{
    history_context_menu := Menu()
    if history_items.Has(history_menu_key)
    {
        history_context_menu.Add("Open URL", (*) => openHistoryPage())
        history_context_menu.Add("Copy URL", copyHistoryUrl)
        history_context_menu.Add("Remove History Item", removeHistoryItem)
        history_context_menu.Add()
    }
    history_context_menu.Add("Sort: " (getHistorySort() = "Recent" ? "Alphabetical" : "Recent"), toggleHistorySort)
    history_context_menu.Add("Clear History...", clearChromeHistory)
    return history_context_menu
}

/* Copy the exact saved URL to the clipboard on explicit request.
*/
copyHistoryUrl(*)
{
    if history_items.Has(history_menu_key)
        A_Clipboard := history_items[history_menu_key].url
}

/* Remove one saved page while leaving domain collection preferences intact.
*/
removeHistoryItem(*)
{
    if history_items.Has(history_menu_key)
    {
        history_items.Delete(history_menu_key)
        saveChromeHistory()
        updateChromeHistoryList(true)
    }
}

/* Clear persisted browsing records only after the user explicitly confirms.
*/
clearChromeHistory(*)
{
    if (MsgBox("Clear all saved Chrome pages? Domain settings will be kept.", "Chrome history", "YesNo Icon?") != "Yes")
        return
    history_items.Clear()
    saveChromeHistory()
    updateChromeHistoryList(true)
}

/* Change history order without affecting live-window sort mode.
*/
toggleHistorySort(*)
{
    mode := getHistorySort() = "Recent" ? "Alphabetical" : "Recent"
    IniWrite(mode, settings_file, "History", "Sort")
    if IsObject(options_history_sort)
        options_history_sort.Choose(mode = "Recent" ? 1 : 2)
    updateChromeHistoryList(true)
}

/* Toggle persistent per-domain collection independently from saved color and sizing.
*/
toggleDomainHistory(row)
{
    if (row < 1 || row > options_domain_list.GetCount())
        return
    domain := normalizeDomainName(options_domain_list.GetText(row, 1))
    if (domain = "")
        return
    IniWrite(getHistoryRuleDomain(domain) = "" ? "1" : "0", settings_file, "DomainHistory", domain)
    updateOptionsDomainList()
    observeChromeHistory(readChromeDomains())
    updateChromeHistoryList(true)
}

/* Add dark history settings below the existing Options controls.
*/
addHistoryOptions()
{
    global options_history_limit, options_history_sort, options_history_show
    options_history_show := options_gui.AddCheckBox("x12 y716 w430 h24", "Show Chrome history list")
    options_history_show.Value := IniRead(settings_file, "History", "Show", "1") = "1" ? 1 : 0
    options_history_show.OnEvent("Click", changeHistoryOptions)
    options_gui.AddText("x12 y752 w115 h24", "Pages per domain:")
    options_history_limit := options_gui.AddEdit("x132 y748 w70 h26 Number", getHistoryLimit())
    options_history_limit.OnEvent("LoseFocus", changeHistoryOptions)
    options_gui.AddText("x218 y752 w45 h24", "Sort:")
    options_history_sort := options_gui.AddDropDownList("x267 y748 w175", ["Recent", "Alphabetical"])
    options_history_sort.Choose(getHistorySort() = "Recent" ? 1 : 2)
    options_history_sort.OnEvent("Change", changeHistoryOptions)
    options_gui.AddButton("x12 y786 w190 h26", "Clear Chrome History...").OnEvent("Click", clearChromeHistory)
    options_gui.AddText("x214 y782 w228 h38", "Enable History beside each domain above. Limit: 1–10000.")
}

/* Apply limit, sort and visibility without discarding disabled-domain history.
*/
changeHistoryOptions(*)
{
    if !IsObject(options_history_limit)
        return
    value := Trim(options_history_limit.Value)
    if (!RegExMatch(value, "^[1-9][0-9]{0,4}$") || Integer(value) > 10000)
    {
        options_history_limit.Value := getHistoryLimit()
        return
    }
    IniWrite(value, settings_file, "History", "Limit")
    IniWrite(options_history_show.Value = 1 ? "1" : "0", settings_file, "History", "Show")
    IniWrite(options_history_sort.Value = 2 ? "Alphabetical" : "Recent", settings_file, "History", "Sort")
    if trimChromeHistory()
        saveChromeHistory()
    updateChromeHistoryList(true)
}

/* Show complete URLs over the history list without replacing its compact titles.
*/
updateHistoryTooltip()
{
    global history_tip_visible
    if (!IsObject(history_list) || !history_list.Visible || manager_hidden)
    {
        if history_tip_visible
            ToolTip(, , , 20)
        history_tip_visible := false
        return
    }
    MouseGetPos(, , , &control_hwnd, 2)
    if (control_hwnd != history_list.Hwnd)
    {
        if history_tip_visible
            ToolTip(, , , 20)
        history_tip_visible := false
        return
    }
    point := Buffer(8, 0)
    DllCall("user32\GetCursorPos", "Ptr", point)
    DllCall("user32\ScreenToClient", "Ptr", history_list.Hwnd, "Ptr", point)
    hit := Buffer(24, 0)
    NumPut("Int", NumGet(point, 0, "Int"), "Int", NumGet(point, 4, "Int"), hit)
    row := SendMessage(0x1012, 0, hit.Ptr, history_list.Hwnd) + 1
    key := history_rows.Get(row, "")
    if history_items.Has(key)
    {
        ToolTip(history_items[key].url, , , 20)
        history_tip_visible := true
    }
    else if history_tip_visible
    {
        ToolTip(, , , 20)
        history_tip_visible := false
    }
}

/* Force native custom draw after row colors are ready, including the first paint.
*/
repaintManagerList(control)
{
    DllCall("user32\RedrawWindow", "Ptr", control.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x185, "Int")
}
