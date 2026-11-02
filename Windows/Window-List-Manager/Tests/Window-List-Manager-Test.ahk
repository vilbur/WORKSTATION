#Requires AutoHotkey v2.0
#Include ..\Lib\Window-List-Manager-0.243.ahk

original_history_file := chrome_history_file
original_history_items := history_items
original_history_observed := history_observed
chrome_history_file := A_Temp "\WindowListManager-History-Test-" DllCall("GetCurrentProcessId", "UInt") ".tsv"
history_items := Map()
history_observed := Map()
original_settings_file := settings_file
original_dock_side := dock_side
original_reserve_enabled := reserve_space_enabled
reserve_space_enabled := false
releaseManagerSpace()
applyPanelTopmost()
dock_side := ""
SetTimer(enforceManagerDock, 0)
SetTimer(refreshWindows, 0)
SetTimer(saveManagerPosition, 0)
SetTimer(updateHoverClose, 0)
SetTimer(checkFocusResize, 0)
SetTimer(checkRaisedPreview, 0)
settings_file := A_Temp "\WindowListManager-Test-" DllCall("GetCurrentProcessId", "UInt") ".ini"
if FileExist(settings_file)
    FileDelete(settings_file)

/*
Smoke-test sorting and default category colors.
*/
assertEqual(actual_value, expected_value, description)
{
    if (actual_value != expected_value)
        throw Error(description ": expected " expected_value ", got " actual_value)
}

entries := [
    {hwnd: 1, title: "Chrome Z", group: "chrome.exe|", priority: 5, top: "", recent: 8, order: 1},
    {hwnd: 2, title: "Max", group: "3dsmax.exe|", priority: 5, top: "", recent: 2, order: 2},
    {hwnd: 3, title: "Chrome A", group: "chrome.exe|", priority: 5, top: "", recent: 4, order: 3},
    {hwnd: 4, title: "Total Commander", group: "totalcmd64.exe|", priority: 1, top: "", recent: 1, order: 4}
]
sorted_entries := sortEntries(entries, "Alphabetical")
assertEqual(sorted_entries[1].hwnd, 4, "priority one first")
assertEqual(sorted_entries[2].hwnd, 2, "app sorting")
assertEqual(sorted_entries[3].hwnd, 3, "alphabetical Chrome title A")
assertEqual(sorted_entries[4].hwnd, 1, "alphabetical Chrome title Z")
recent_entries := sortEntries(entries, "Recent")
assertEqual(recent_entries[1].hwnd, 4, "priority survives recent sort")
assertEqual(recent_entries[2].hwnd, 2, "recent app grouping")
assertEqual(recent_entries[3].hwnd, 1, "recent Chrome Z")
assertEqual(recent_entries[4].hwnd, 3, "older Chrome A")
assertEqual(getGroupColor("3dsmax.exe", "Max"), 0xD0D0D0, "Max default color")
assertEqual(getGroupColor("chrome.exe", "ChatGPT"), 0xD0D0D0, "GPT default color")
assertEqual(window_list.GetCount("Column"), 1, "title-only list")
assertEqual(getDisplayTitle("Inbox - Google Chrome"), "Inbox", "Chrome suffix")
assertEqual(getDisplayTitle("Scene - Autodesk 3ds Max 2026"), "Scene", "Max suffix")
assertEqual(getDisplayTitle("Report - Other App"), "Report - Other App", "unknown suffix remains")
assertEqual(getGroupColor("chrome.exe", "Inbox", "example.com"), 0xD0D0D0, "default Chrome color")
wrong_prefix_record := {title: "Project", domain: "other.example", left: 100, top: 100, width: 900, height: 700}
exact_title_record := {title: "Project Settings", domain: "settings.example", left: 101, top: 101, width: 900, height: 700}
matched_domain_record := matchChromeRecordByRect("Project Settings - Google Chrome", 100, 100, 900, 700, [wrong_prefix_record, exact_title_record])
assertEqual(matched_domain_record.domain, "settings.example", "Chrome color match uses exact active tab title, not a title fragment")
assertEqual(IsObject(matchChromeRecordByRect("Unrelated - Google Chrome", 100, 100, 900, 700, [wrong_prefix_record])), false, "unrelated Chrome tab never takes another domain color")
assertEqual(IsObject(matchChromeRecordByRect("Project - Google Chrome", 100, 100, 900, 700, [
    {title: "Project", domain: "first.example", left: 100, top: 100, width: 900, height: 700},
    {title: "Project", domain: "second.example", left: 100, top: 100, width: 900, height: 700}
])), false, "ambiguous same-title overlapping Chrome windows use fallback color")
assertEqual(IsObject(matchChromeRecordByRect("Project - Google Chrome", 100, 100, 900, 700, [
    {title: "Project", domain: "stale.example", left: 2000, top: 100, width: 900, height: 700}
])), false, "stale far-away Chrome window does not supply domain color")
assertEqual(canDetachChromeTab({live: true, tab_count: 2, client: "profile_1", window_id: "42", tab_id: "99"}), true, "two-tab Chrome window supports detach")
assertEqual(canDetachChromeTab({live: true, tab_count: 1, client: "profile_1", window_id: "42", tab_id: "99"}), false, "one-tab Chrome window cannot detach")
assertEqual(canDetachChromeTab({live: false, tab_count: 3, client: "profile_1", window_id: "42", tab_id: "99"}), false, "stale cached Chrome snapshot cannot detach")
assertEqual(canDetachChromeTab({live: true, tab_count: 3, client: "", window_id: "42", tab_id: "99"}), false, "missing profile identity cannot receive command")
assertEqual(canDetachChromeTab({live: true, tab_count: 3, client: "profile_1", window_id: "-1", tab_id: "99"}), false, "invalid Chrome window ID cannot detach")
/* Verify fallback configuration while preserving explicit app/domain priority.
*/
assertEqual(getDefaultFontColor(), 0xD0D0D0, "light grey fallback")
setDefaultFontColor(0xAABBCC)
assertEqual(IniRead(settings_file, "Panel", "DefaultFontColor"), "AABBCC", "fallback saved")
assertEqual(getGroupColor("unassigned.exe", "", "unknown.example"), 0xAABBCC, "configured fallback used")
IniWrite("123456", settings_file, "Colors", "unassigned.exe")
assertEqual(getGroupColor("unassigned.exe", "", "unknown.example"), 0x123456, "program rule overrides fallback")
IniWrite("654321", settings_file, "DomainColors", "unknown.example")
assertEqual(getGroupColor("unassigned.exe", "", "child.unknown.example"), 0x654321, "inherited domain overrides program and fallback")
IniWrite("invalid", settings_file, "Panel", "DefaultFontColor")
assertEqual(getDefaultFontColor(), 0xD0D0D0, "invalid setting falls back to grey")
setDefaultFontColor(0)
assertEqual(getDefaultFontColor(), 0, "black fallback supported")
resetDefaultFontColor()
assertEqual(getDefaultFontColor(), 0xD0D0D0, "reset restores light grey")

IniWrite("AA7755", settings_file, "DomainColors", "example.com")
assertEqual(getGroupColor("chrome.exe", "Inbox", "example.com"), 0xAA7755, "domain color")
IniWrite("55AACC", settings_file, "Colors", "chrome.exe")
assertEqual(getGroupColor("chrome.exe", "Inbox", "example.com"), 0xAA7755, "domain color has priority")
assertEqual(getGroupColor("chrome.exe", "Inbox", "other.example"), 0x55AACC, "EXE color is fallback for other domains")
showOptions()
testTaskbarOption()
assertEqual(options_gui.Title, "Window List Manager Options v" app_version, "Options title shows current version")
row_groups[9999] := "chrome.exe"
updateOptionsList()
app_row := 0
Loop options_list.GetCount()
{
    if (options_list.GetText(A_Index, 1) = "chrome.exe")
        app_row := A_Index
}
assertEqual(app_row > 0, true, "Chrome appears in the application Options list")
assertEqual(options_list.GetText(app_row, 3), "Choose...", "application row offers color picker instead of hex code")
assertEqual(options_app_colors[app_row], 0x55AACC, "app swatch previews effective program color")
IniDelete(settings_file, "Colors", "chrome.exe")
updateOptionsList()
assertEqual(options_app_colors[app_row], getDefaultFontColor(), "app swatch previews fallback color after reset")
IniWrite("55AACC", settings_file, "Colors", "chrome.exe")
updateOptionsList()
row_groups.Delete(9999)
row_domains[1] := "example.com"
updateOptionsDomainList()
domain_row := 0
Loop options_domain_list.GetCount()
{
    if (options_domain_list.GetText(A_Index, 1) = "example.com")
        domain_row := A_Index
}
assertEqual(domain_row > 0, true, "domain shown in Options")
options_domain_list.Modify(domain_row, "Select")
assertEqual(optionsSelectedDomain(), "example.com", "domain selection in Options")
assertEqual(options_domain_list.GetText(domain_row, 2), "Choose...", "domain row offers picker instead of hex code")
assertEqual(options_domain_colors[domain_row], 0xAA7755, "domain swatch previews effective saved color")
assertEqual(isFocusResizeEnabled("chrome.exe", "example.com"), false, "domain focus sizing defaults off")
toggleDomainFocusResize(domain_row)
assertEqual(IniRead(settings_file, "DomainFocusResize", "example.com"), "1", "domain checkbox persists enabled")
assertEqual(isFocusResizeEnabled("chrome.exe", "deep.example.com"), true, "domain focus sizing includes subdomains")
assertEqual(resolveFocusResizeDomain("chrome.exe", 0, "deep.example.com"), "deep.example.com", "listed Chrome domain survives missing fresh bridge match")
assertEqual(isFocusResizeEnabled("chrome.exe", resolveFocusResizeDomain("chrome.exe", 0, "deep.example.com")), true, "listed Chrome domain enables resize on list activation")
assertEqual(resolveFocusResizeDomain("notepad.exe", 0, "deep.example.com"), "", "non-Chrome apps ignore listed domain hints")
assertEqual(isFocusResizeEnabled("chrome.exe", "notexample.com"), false, "domain sizing respects hostname boundaries")
assertEqual(isFocusResizeEnabled("other.exe", "example.com"), false, "domain rule only affects Chrome")
assertEqual(options_domain_list.GetText(domain_row, 3), Chr(0x2611), "enabled domain checkbox shown")
IniWrite("1", settings_file, "FocusResize", "chrome.exe")
toggleDomainFocusResize(domain_row)
assertEqual(isFocusResizeEnabled("chrome.exe", "example.com"), false, "domain unchecked overrides app opt-in")
assertEqual(isFocusResizeEnabled("chrome.exe", "other.example"), true, "unrelated domain retains app opt-in")
assertEqual(options_domain_list.GetText(domain_row, 3), Chr(0x2610), "disabled domain checkbox shown")
IniWrite("1", settings_file, "DomainFocusResize", "app.example.com")
assertEqual(isFocusResizeEnabled("chrome.exe", "deep.app.example.com"), true, "nearest domain rule wins")
IniDelete(settings_file, "FocusResize", "chrome.exe")
IniDelete(settings_file, "DomainFocusResize")
assertEqual(onDomainResizeKey(0x20, 0, 0x100, options_domain_list.Hwnd), 0, "Space handles selected domain checkbox")
assertEqual(isFocusResizeEnabled("chrome.exe", "example.com"), true, "Space enables selected domain")
onDomainResizeKey(0x20, 0x40000000, 0x100, options_domain_list.Hwnd)
assertEqual(isFocusResizeEnabled("chrome.exe", "example.com"), true, "held Space does not repeatedly toggle")
closeOptions()
closeOptions()
testDestroyedControlNotifications()
assertEqual(IsObject(options_history_limit), false, "closing Options releases history limit control")
assertEqual(IsObject(options_history_sort), false, "closing Options releases history sort control")
assertEqual(IsObject(options_history_show), false, "closing Options releases history visibility control")
toggleHistorySort()
showOptions()
assertEqual(isFocusResizeEnabled("chrome.exe", "example.com"), true, "domain preference survives Options reopen")
IniDelete(settings_file, "DomainFocusResize")
assertEqual(getColorLabelText(0xFFFFFF), 0x000000, "light swatch uses dark label")
assertEqual(getColorLabelText(0x000000), 0xFFFFFF, "dark swatch uses light label")
closeOptions()
window_list.Delete()
row_handles.Clear()
row_handles[window_list.Add("", "One")] := 111
row_handles[window_list.Add("", "Two")] := 222
last_active_hwnd := 222
selectActiveRow()
assertEqual(window_list.GetNext(), 2, "active window uses native row selection")
last_active_hwnd := 111
selectActiveRow()
assertEqual(window_list.GetNext(), 1, "selection follows active window")
last_active_hwnd := 333
selectActiveRow()
assertEqual(window_list.GetNext(), 0, "unlisted active window clears selection")
assertEqual(getAppPriority("totalcmd64.exe"), 1, "Total Commander default priority")
assertEqual(getAppPriority("chrome.exe"), 5, "other app default priority")
IniWrite("2", settings_file, "AppPriorities", "chrome.exe")
assertEqual(getAppPriority("chrome.exe"), 2, "saved app priority")

/* Verify unrestricted positive priorities persist and sort without numeric overflow.
*/
assertEqual(isValidAppPriority("10"), true, "priority above nine is accepted")
assertEqual(isValidAppPriority("100000000000000000000000000000001"), true, "very large priority is accepted")
for invalid_priority in ["0", "-1", "1.5", "", "abc"]
    assertEqual(isValidAppPriority(invalid_priority), false, "reject invalid priority " invalid_priority)
IniWrite("100", settings_file, "AppPriorities", "chrome.exe")
assertEqual(getAppPriority("chrome.exe"), "100", "large priority persists")
huge_priority := "100000000000000000000000000000001"
IniWrite(huge_priority, settings_file, "AppPriorities", "chrome.exe")
assertEqual(StrCompare(getAppPriority("chrome.exe"), huge_priority), 0, "huge priority retains every digit")
priority_entries := [
    {hwnd: 1, title: "A", group: "a|", priority: "100000000000000000000000000000002", recent: 0, order: 1},
    {hwnd: 2, title: "B", group: "b|", priority: huge_priority, recent: 0, order: 2},
    {hwnd: 3, title: "C", group: "c|", priority: 100, recent: 0, order: 3},
    {hwnd: 4, title: "D", group: "d|", priority: 10, recent: 0, order: 4}
]
for test_mode in ["Alphabetical", "Recent"]
{
    priority_sorted := sortEntries(priority_entries, test_mode)
    assertEqual(priority_sorted[1].hwnd, 4, "ten precedes one hundred in " test_mode)
    assertEqual(priority_sorted[2].hwnd, 3, "one hundred precedes huge priority in " test_mode)
    assertEqual(priority_sorted[3].hwnd, 2, "huge priorities sort exactly in " test_mode)
    assertEqual(priority_sorted[4].hwnd, 1, "largest priority sorts last in " test_mode)
}
IniWrite("2", settings_file, "AppPriorities", "chrome.exe")

/* Exercise closing against a disposable test window only.
*/
test_close_gui := Gui("+ToolWindow", "Window List Manager Close Test")
test_close_gui.Show("w180 h80")
test_close_hwnd := test_close_gui.Hwnd
test_close_row := window_list.Add("", "Disposable close test")
row_handles[test_close_row] := test_close_hwnd
hover_close_hwnd := test_close_hwnd
closeHoveredWindow()
Sleep(100)
assertEqual(WinExist("ahk_id " test_close_hwnd), 0, "hover close requests normal window closure")
assertEqual(hover_close_hwnd, 0, "close clears overlay target")
test_close_gui.Destroy()
row_handles.Delete(test_close_row)
window_list.Delete(test_close_row)
MonitorGetWorkArea(MonitorGetPrimary(), &test_left, &test_top, &test_right, &test_bottom)
assertEqual(rectangleOnScreen(test_left, test_top, 100, 100), true, "visible saved position")
assertEqual(rectangleOnScreen(1000000, 1000000, 100, 100), false, "off-screen saved position")
WinGetPos(&original_x, &original_y, &original_width, &original_height, "ahk_id " manager_gui.Hwnd)
original_center_x := original_x + original_width // 2
original_center_y := original_y + original_height // 2
test_monitor := MonitorGetPrimary()
Loop MonitorGetCount()
{
    MonitorGetWorkArea(A_Index, &work_left, &work_top, &work_right, &work_bottom)
    if (original_center_x >= work_left && original_center_x < work_right && original_center_y >= work_top && original_center_y < work_bottom)
        test_monitor := A_Index
}
MonitorGetWorkArea(test_monitor, &work_left, &work_top, &work_right, &work_bottom)
for dock_side in ["Right", "Left", "Right"]
{
    dockManager(dock_side, false)
    WinGetPos(&docked_x, &docked_y, &docked_width, &docked_height, "ahk_id " manager_gui.Hwnd)
    assertEqual(docked_x >= work_left, true, dock_side " dock left edge inside work area")
    assertEqual(docked_x + docked_width <= work_right, true, dock_side " dock right edge inside work area")
    assertEqual(docked_y >= work_top, true, dock_side " dock top edge inside work area")
    assertEqual(docked_y + docked_height <= work_bottom, true, dock_side " dock bottom edge inside work area")
    expected_width := original_width
    assertEqual(docked_width, expected_width, dock_side " dock preserves outer width")
    assertEqual(docked_height, original_height, dock_side " dock preserves user height")
    assertEqual(dock_side = "Right" ? docked_x + docked_width : docked_x, dock_side = "Right" ? work_right : work_left, dock_side " dock aligns to edge")
}
/* Docking remains suspended during a drag and reapplies after release.
*/
for test_side in ["Left", "Right"]
{
    dock_side := test_side
    free_x := work_left + 25
    free_y := work_top + 25
    WinMove(free_x, free_y, , , "ahk_id " manager_gui.Hwnd)
    onManagerMoveStart(0, 0, 0x231, manager_gui.Hwnd)
    enforceManagerDock()
    WinGetPos(&free_actual_x, &free_actual_y, , , "ahk_id " manager_gui.Hwnd)
    assertEqual(free_actual_x, free_x, "drag is not pulled back horizontally")
    assertEqual(free_actual_y, free_y, "drag is not pulled back vertically")
    onManagerMoveEnd(0, 0, 0x232, manager_gui.Hwnd)
    SetTimer(enforceManagerDock, 0)
    assertEqual(manager_moving, false, "release clears moving flag")
    enforceManagerDock()
    WinGetPos(&snap_x, &snap_y, &snap_width, &snap_height, "ahk_id " manager_gui.Hwnd)
    assertEqual(test_side = "Right" ? snap_x + snap_width : snap_x, test_side = "Right" ? work_right : work_left, "release snaps to chosen edge")
    assertEqual(snap_y, Max(work_top, Min(free_y, work_bottom - original_height)), "release preserves vertical position within work area")
    assertEqual(snap_height, original_height, "release preserves user height")
}
dock_side := ""
WinMove(original_x, original_y, original_width, original_height, "ahk_id " manager_gui.Hwnd)
assertEqual((WinGetExStyle("ahk_id " manager_gui.Hwnd) & 0x8) != 0, main_topmost, "saved main panel topmost state")
previous_lock_enabled := lock_width_enabled
previous_locked_width := locked_width
lock_width_enabled := true
locked_width := 240
minmax_info := Buffer(40, 0)
onManagerMinMax(0, minmax_info.Ptr, 0x24, manager_gui.Hwnd)
assertEqual(NumGet(minmax_info, 24, "Int"), 240, "locked minimum track width")
assertEqual(NumGet(minmax_info, 32, "Int"), 240, "locked maximum track width")
assertEqual(NumGet(minmax_info, 28, "Int"), 0, "height remains unconstrained")
lock_width_enabled := previous_lock_enabled
locked_width := previous_locked_width
assertEqual(InStr(getStartupCommand(), project_dir "\Window-List-Manager.ahk") > 0, true, "startup command points to this script")
testReservedSpace()
/* Verify nearest-parent inheritance, hostname boundaries, and program fallback.
*/
IniWrite("112233", settings_file, "DomainColors", "example.com")
IniWrite("445566", settings_file, "Colors", "chrome.exe")
assertEqual(getGroupColor("chrome.exe", "", "example.com"), 0x112233, "exact root domain color")
assertEqual(getGroupColor("chrome.exe", "", "www.example.com"), 0x112233, "www inherits root domain color")
assertEqual(getGroupColor("chrome.exe", "", "deep.app.example.com"), 0x112233, "nested subdomain inherits root")
assertEqual(getGroupColor("chrome.exe", "", "WWW.EXAMPLE.COM."), 0x112233, "hostname normalization")
IniWrite("778899", settings_file, "DomainColors", "app.example.com")
assertEqual(getGroupColor("chrome.exe", "", "app.example.com"), 0x778899, "explicit subdomain wins")
assertEqual(getGroupColor("chrome.exe", "", "deep.app.example.com"), 0x778899, "nearest ancestor wins")
assertEqual(getGroupColor("chrome.exe", "", "notexample.com"), 0x445566, "hostname boundary prevents unrelated match")
assertEqual(getGroupColor("chrome.exe", "", "example.com.other.net"), 0x445566, "suffix extension does not match")
IniDelete(settings_file, "DomainColors", "app.example.com")
assertEqual(getGroupColor("chrome.exe", "", "app.example.com"), 0x112233, "reset child restores inherited root color")
IniWrite("000000", settings_file, "DomainColors", "app.example.com")
assertEqual(getGroupColor("chrome.exe", "", "app.example.com"), 0, "black remains a valid domain override")

testFocusSizing()
testListClickActivation()
testTrayControls()
testAppbarCallbackLifecycle()
testChromeHistory()
FileDelete(settings_file)
if FileExist(chrome_history_file)
    FileDelete(chrome_history_file)
chrome_history_file := original_history_file
history_items := original_history_items
history_observed := original_history_observed
settings_file := original_settings_file
dock_side := original_dock_side
reserve_space_enabled := original_reserve_enabled
applyPanelTopmost()
SetTimer(enforceManagerDock, 300)
SetTimer(refreshWindows, 900)
SetTimer(saveManagerPosition, 1200)
SetTimer(updateHoverClose, 100)
SetTimer(checkFocusResize, 150)
SetTimer(checkRaisedPreview, 150)
/* Verify foreground lookup remains safe when no window is active.
*/
manager_source := FileRead(A_ScriptDir "\..\Lib\Window-List-Manager-0.241.ahk", "UTF-8")
assertEqual(InStr(manager_source, 'WinGet' 'ID("A")'), 0, "foreground lookup must not throw for a missing window")
assertEqual(InStr(manager_source, 'active_hwnd := WinExist("A")') > 0, true, "safe foreground lookup present")
assertEqual(InStr(manager_source, 'list_activation_in_progress || !active_hwnd') > 0, true, "zero handle excluded from focus tracking")
assertEqual(WinExist("WindowListManagerMissingWindow" A_TickCount " ahk_pid " DllCall("GetCurrentProcessId", "UInt")), 0, "missing window returns zero")
refreshWindows(true)
assertEqual(refresh_busy, false, "refresh releases busy flag")
assertEqual(recent_order.Has(0), false, "zero handle absent from recent history")

assertEqual(normalizeDomainName(" HTTPS://ChatGPT.COM/c/123 "), "chatgpt.com", "domain URL normalization")
assertEqual(normalizeDomainName("example.com"), "example.com", "plain domain")
assertEqual(normalizeDomainName("not a domain"), "", "invalid hostname")
assertEqual(normalizeDomainName("bad=host.com"), "", "invalid INI key characters")
assertEqual(InStr(manager_source, 'if (menu_domain != "")' "`n" '            context_menu.Add("Assign Color to Domain..."'), 0, "domain menu not hidden without detection")
assertEqual(InStr(manager_source, 'context_menu.Add("Assign Color to Program...", assignGroupColor)' "`n" '        context_menu.Add("Assign Color to Domain...", assignDomainColor)') > 0, true, "color actions stay together below window topmost")
assertEqual(getWindowDomain(0, "example.com"), "example.com", "domain fallback retained")
assertEqual(getWindowDomain(0), "", "unknown domain stays empty")
window_domain_overrides[-123] := "chatgpt.com"
assertEqual(getWindowDomain(-123), "chatgpt.com", "manual domain prefills assignment")
window_domain_overrides.Delete(-123)
assertEqual(InStr(manager_source, '"w400 h150", detected_domain)') > 0, true, "domain input receives selected window default")
assertEqual(InStr(manager_source, 'hover_close.SetFont("s10 Bold cFFFFFF", "Segoe UI")') > 0, true, "close overlay has explicit bright font")
manager_close.GetPos(&close_x, &close_y, &close_width, &close_height)
drag_bar.GetPos(&strip_x, &strip_y, &strip_width, &strip_height)
assertEqual(manager_close.Visible, true, "manager close button is visible")
assertEqual(manager_close.Text, "×", "manager close glyph")
assertEqual(close_x, strip_x + strip_width, "close button follows drag strip")
assertEqual(close_y, strip_y, "close button aligned to title strip")
assertEqual(close_width, close_height, "manager close button is square")
assertEqual(close_height, strip_height, "manager close button matches strip height")
assertEqual(drag_bar.Text, "v" app_version "  Window List Manager", "title strip displays running tool version")
assertEqual((WinGetExStyle("ahk_id " manager_gui.Hwnd) & 0x80) != 0, hide_from_taskbar, "manager taskbar style matches setting")
assertEqual((WinGetExStyle("ahk_id " manager_gui.Hwnd) & 0x40000) = 0, true, "manager does not force a taskbar button")
testRecentListActivation()
MsgBox("SMOKE TEST PASSED. Now perform the manual UI tests in README.md.")

/* Verify stale native notification and key events ignore destroyed GUI controls.
*/
testDestroyedControlNotifications()
{
    global options_domain_list, history_list
    previous_domain_list := options_domain_list
    previous_history_list := history_list
    dead_gui := Gui()
    dead_control := dead_gui.AddListView("w150 h80", ["Dead control"])
    dead_hwnd := dead_control.Hwnd
    notification := Buffer(128, 0)
    NumPut("Ptr", dead_hwnd, notification)
    dead_gui.Destroy()
    try
    {
        options_domain_list := dead_control
        onListNotify(0, notification.Ptr, 0x4E, manager_gui.Hwnd)
        onDomainResizeKey(0x20, 0, 0x100, dead_hwnd)
        options_domain_list := ""
        history_list := dead_control
        onListNotify(0, notification.Ptr, 0x4E, manager_gui.Hwnd)
    }
    finally
    {
        options_domain_list := previous_domain_list
        history_list := previous_history_list
    }
}

/* Validate real Shell work-area reservation and release on connected monitors.
*/
testReservedSpace()
{
    global reserve_space_enabled, dock_side, manager_moving
    data := createAppbarData()
    assertEqual(data.Size, A_PtrSize = 8 ? 48 : 36, "APPBARDATA native size")
    assertEqual(NumGet(data, 0, "UInt"), data.Size, "APPBARDATA size field")
    assertEqual(NumGet(data, A_PtrSize = 8 ? 8 : 4, "Ptr"), manager_gui.Hwnd, "APPBARDATA window handle")
    WinGetPos(&saved_x, &saved_y, &saved_width, &saved_height, "ahk_id " manager_gui.Hwnd)
    baseline_areas := []
    Loop MonitorGetCount()
    {
        MonitorGetWorkArea(A_Index, &left, &top, &right, &bottom)
        baseline_areas.Push([left, top, right, bottom])
    }
    try
    {
        showOptions()
        options_reserve_space.Value := 1
        changeReserveSetting()
        assertEqual(reserve_space_enabled, true, "Options enables reservation")
        assertEqual(IniRead(settings_file, "Panel", "ReserveSpace"), "1", "reservation setting persists")
        assertEqual(appbar_registered, true, "Shell appbar registered")
        assertEqual((WinGetExStyle("ahk_id " manager_gui.Hwnd) & 0x8) != 0, false, "reservation does not require topmost")
        Loop MonitorGetCount()
        {
            target_monitor := A_Index
            MonitorGet(target_monitor, &left, &top, &right, &bottom)
            onManagerMoveStart(0, 0, 0x231, manager_gui.Hwnd)
            assertEqual(appbar_registered, false, "drag releases old reservation")
            WinMove(left + (right - left) // 2, top + 30, , , "ahk_id " manager_gui.Hwnd)
            onManagerMoveEnd(0, 0, 0x232, manager_gui.Hwnd)
            SetTimer(enforceManagerDock, 0)
            for side in ["Left", "Right"]
            {
                dockManager(side)
                Sleep(100)
                WinGetPos(&panel_x, , &panel_width, , "ahk_id " manager_gui.Hwnd)
                MonitorGetWorkArea(target_monitor, &work_left, , &work_right)
                if (side = "Left")
                    assertEqual(work_left >= panel_x + panel_width, true, "left reservation excludes panel")
                else
                    assertEqual(work_right <= panel_x, true, "right reservation excludes panel")
                /* Activation and unexpected placement must not replace the chosen monitor.
                */
                expected_monitor := dock_monitor_handle
                WinGetPos(&before_x, &before_y, &before_width, &before_height, "ahk_id " manager_gui.Hwnd)
                WinActivate("ahk_id " manager_gui.Hwnd)
                Sleep(100)
                onAppbarActivate(0, 0, 0x6, manager_gui.Hwnd)
                if (MonitorGetCount() > 1 && target_monitor != MonitorGetPrimary())
                {
                    MonitorGetWorkArea(MonitorGetPrimary(), &primary_left, &primary_top)
                    WinMove(primary_left + 40, primary_top + 40, , , "ahk_id " manager_gui.Hwnd)
                }
                enforceManagerDock()
                assertEqual(dock_monitor_handle, expected_monitor, "activation retains chosen monitor")
                WinGetPos(&after_x, &after_y, &after_width, &after_height, "ahk_id " manager_gui.Hwnd)
                assertEqual(after_x, before_x, "activation recovers docked x on selected monitor")
                assertEqual(after_width, before_width, "activation preserves width")
                assertEqual(after_height, before_height, "activation preserves height")
                Loop MonitorGetCount()
                {
                    if (A_Index = target_monitor)
                        continue
                    MonitorGetWorkArea(A_Index, &other_left, &other_top, &other_right, &other_bottom)
                    actual_area := other_left "," other_top "," other_right "," other_bottom
                    baseline := baseline_areas[A_Index]
                    assertEqual(actual_area, baseline[1] "," baseline[2] "," baseline[3] "," baseline[4], "other monitors remain unreserved")
                }
            }
        }
        /* Simulate a FancyZones resize while reserved, then verify the timer preserves it.
        */
        onManagerMoveStart(0, 0, 0x231, manager_gui.Hwnd)
        WinMove(, , 280, 320, "ahk_id " manager_gui.Hwnd)
        WinGetPos(, , &zone_width, &zone_height, "ahk_id " manager_gui.Hwnd)
        enforceManagerDock()
        WinGetPos(, , &during_width, &during_height, "ahk_id " manager_gui.Hwnd)
        assertEqual(during_width, zone_width, "drag preserves FancyZones width")
        assertEqual(during_height, zone_height, "drag preserves custom height")
        onManagerMoveEnd(0, 0, 0x232, manager_gui.Hwnd)
        SetTimer(enforceManagerDock, 0)
        enforceManagerDock()
        WinGetPos(, , &after_width, &after_height, "ahk_id " manager_gui.Hwnd)
        assertEqual(after_width, zone_width, "reserved snap preserves FancyZones width")
        assertEqual(after_height, zone_height, "reserved snap preserves custom height")
        if lock_width_enabled
            assertEqual(locked_width, after_width, "width lock follows external resize")
        options_reserve_space.Value := 0
        changeReserveSetting()
        assertEqual(appbar_registered, false, "Options unregisters appbar")
        Loop MonitorGetCount()
        {
            MonitorGetWorkArea(A_Index, &left, &top, &right, &bottom)
            baseline := baseline_areas[A_Index]
            assertEqual(left "," top "," right "," bottom, baseline[1] "," baseline[2] "," baseline[3] "," baseline[4], "disable restores monitor work area")
        }
    }
    finally
    {
        reserve_space_enabled := false
        manager_moving := false
        releaseManagerSpace()
        applyPanelTopmost()
        dock_side := ""
        WinMove(saved_x, saved_y, saved_width, saved_height, "ahk_id " manager_gui.Hwnd)
        getManagerMonitorInfo(true)
        if (options_gui != "")
            closeOptions()
    }
}

/* Check both taskbar modes, persisted values, and preservation of panel geometry.
*/
testTaskbarOption()
{
    previous_hidden := hide_from_taskbar
    WinGetPos(&saved_x, &saved_y, &saved_width, &saved_height, "ahk_id " manager_gui.Hwnd)
    try
    {
        for hidden in [false, true]
        {
            options_hide_taskbar.Value := hidden ? 1 : 0
            changeTaskbarSetting()
            assertEqual((WinGetExStyle("ahk_id " manager_gui.Hwnd) & 0x80) != 0, hidden, "taskbar option changes window style")
            assertEqual(IniRead(settings_file, "Panel", "HideFromTaskbar"), hidden ? "1" : "0", "taskbar choice saved")
            WinGetPos(&actual_x, &actual_y, &actual_width, &actual_height, "ahk_id " manager_gui.Hwnd)
            assertEqual(actual_x "," actual_y "," actual_width "," actual_height, saved_x "," saved_y "," saved_width "," saved_height, "taskbar toggle preserves geometry")
        }
    }
    finally
    {
        options_hide_taskbar.Value := previous_hidden ? 1 : 0
        changeTaskbarSetting()
    }
}

/* Verify list activation highlights immediately but changes Recent only on a later focus.
*/
testRecentListActivation()
{
    global recent_order, recent_counter, last_active_hwnd, pending_list_activation_hwnd, list_activation_in_progress
    saved_order := recent_order
    saved_counter := recent_counter
    saved_active := last_active_hwnd
    saved_pending := pending_list_activation_hwnd
    saved_progress := list_activation_in_progress
    try
    {
        recent_order := Map()
        recent_counter := 0
        last_active_hwnd := 100001
        pending_list_activation_hwnd := 100002
        list_activation_in_progress := false
        assertEqual(trackActiveWindow(0), false, "zero focus ignored")
        assertEqual(trackActiveWindow(100002), false, "list activation defers Recent")
        assertEqual(last_active_hwnd, 100002, "list activation tracks active target")
        assertEqual(recent_order.Count, 0, "list target not reordered immediately")
        assertEqual(trackActiveWindow(manager_gui.Hwnd), false, "manager focus keeps pending activation")
        assertEqual(pending_list_activation_hwnd, 100002, "pending survives manager focus")
        assertEqual(trackActiveWindow(100003), true, "external focus releases Recent")
        assertEqual(pending_list_activation_hwnd, 0, "pending activation cleared")
        assertEqual(recent_order[100003] > recent_order[100002], true, "new external target is newest")
        if row_handles.Count
        {
            test_row := 0
            for row, hwnd in row_handles
            {
                test_row := row
                last_active_hwnd := hwnd
                break
            }
            assertEqual(getRowBackground(test_row), 0x334E68, "active row uses blue highlight")
        }
    }
    finally
    {
        recent_order := saved_order
        recent_counter := saved_counter
        last_active_hwnd := saved_active
        pending_list_activation_hwnd := saved_pending
        list_activation_in_progress := saved_progress
    }
}

/* Verify landscape/portrait geometry and restore an opt-in disposable window on blur.
*/
testFocusSizing()
{
    rect := getFocusRectangle(10, 20, 300, 250, 0, 0, 1920, 1040, true)
    assertEqual(rect.x "," rect.y "," rect.width "," rect.height, "0,0,960,1040", "landscape left half")
    rect := getFocusRectangle(1400, 20, 300, 250, 0, 0, 1920, 1040, true)
    assertEqual(rect.x, 960, "landscape preserves right side")
    rect := getFocusRectangle(-1000, 1200, 400, 300, -1080, 0, 0, 1920, false)
    assertEqual(rect.x "," rect.y "," rect.width "," rect.height, "-1080,960,1080,960", "portrait bottom half on negative display")
    test_window := Gui("+ToolWindow +Resize -DPIScale", "Focus Resize Test")
    other_window := Gui("+ToolWindow", "Focus Blur Test")
    try
    {
        test_window.Show("w360 h260")
        other_window.Show("w220 h160 NA")
        target := "ahk_id " test_window.Hwnd
        WinActivate(target)
        if !WinWaitActive(target, , 2)
            throw Error("Disposable test window could not be activated.")
        WinGetPos(&x, &y, &width, &height, target)
        chrome_record := {title: "Example page", domain: "example.com", url: "https://example.com/current", left: x, top: y, width: width, height: height, live: true}
        assertEqual(matchChromeRecord(test_window.Hwnd, "Example page - Google Chrome", [chrome_record]).url, "https://example.com/current", "matched live window retains exact active Chrome URL")
        app_name := StrLower(WinGetProcessName(target))
        assertEqual(isFocusResizeEnabled(app_name), false, "focus sizing defaults off")
        IniWrite("1", settings_file, "FocusResize", app_name)
        applyFocusResize(test_window.Hwnd)
        assertEqual(IsObject(focus_resize_state), true, "activation saves original rectangle")
        WinActivate("ahk_id " other_window.Hwnd)
        if !WinWaitActive("ahk_id " other_window.Hwnd, , 2)
            throw Error("Disposable blur window could not be activated.")
        checkFocusResize()
        WinGetPos(&actual_x, &actual_y, &actual_width, &actual_height, target)
        assertEqual(actual_x "," actual_y "," actual_width "," actual_height, x "," y "," width "," height, "blur restores original grid rectangle")
        assertEqual(WinGetMinMax(target) != -1, true, "blur does not minimize")
        assertEqual(WinActive("ahk_id " other_window.Hwnd) != 0, true, "restore does not steal focus")
        assertEqual(IsObject(focus_resize_state), false, "restore clears saved state")
        IniDelete(settings_file, "FocusResize", app_name)
    }
    finally
    {
        restoreFocusWindow()
        test_window.Destroy()
        other_window.Destroy()
    }
}

/* Verify dark Options button styles and the tray show/hide lifecycle without restarting.
*/
testTrayControls()
{
    previous_detect_hidden := A_DetectHiddenWindows
    DetectHiddenWindows(false)
    showOptions()
    try
    {
        assertEqual(DllCall("user32\GetMenuItemCount", "Ptr", A_TrayMenu.Handle, "Int"), 3, "tray contains exactly three commands")
        tray_label := Buffer(128, 0)
        DllCall("user32\GetMenuStringW", "Ptr", A_TrayMenu.Handle, "UInt", 2, "Ptr", tray_label, "Int", 64, "UInt", 0x400)
        assertEqual(StrGet(tray_label), "Exit", "Exit is the last tray command")
        assertEqual(options_dark_buttons.Count > 0, true, "Options has dark push buttons")
        for control_hwnd, control in options_dark_buttons
            assertEqual(WinGetStyle("ahk_id " control_hwnd) & 0xF, 0xB, "Options push button is owner-drawn")
        assertEqual(options_dark_controls.Has(options_sort.Hwnd), true, "sort dropdown uses dark colors")
        assertEqual(options_dark_controls.Has(options_startup.Hwnd), true, "Options checkbox uses dark colors")
        assertEqual(InStr(getRestartCommand(), project_dir "\Window-List-Manager.ahk") > 0, true, "restart uses root launcher")
        WinGetPos(&saved_x, &saved_y, &saved_width, &saved_height, "ahk_id " manager_gui.Hwnd)
        hideManager()
        assertEqual(manager_hidden, true, "tray hide records hidden state")
        assertEqual(DllCall("user32\IsWindow", "Ptr", manager_gui.Hwnd, "Int") != 0, true, "hidden panel HWND remains valid")
        assertEqual(DllCall("user32\IsWindowVisible", "Ptr", manager_gui.Hwnd, "Int"), 0, "tray hide removes visible panel")
        assertEqual(appbar_registered, false, "tray hide releases reserved space")
        enforceManagerDock()
        assertEqual(DllCall("user32\IsWindowVisible", "Ptr", manager_gui.Hwnd, "Int"), 0, "docking timer does not reveal hidden panel")
        toggleManager()
        assertEqual(manager_hidden, false, "tray click restores state")
        assertEqual(DllCall("user32\IsWindowVisible", "Ptr", manager_gui.Hwnd, "Int") != 0, true, "tray click shows UI")
        WinGetPos(&actual_x, &actual_y, &actual_width, &actual_height, "ahk_id " manager_gui.Hwnd)
        assertEqual(actual_width "," actual_height, saved_width "," saved_height, "tray restore preserves panel dimensions")
    }
    finally
    {
        openManager()
        closeOptions()
        DetectHiddenWindows(previous_detect_hidden)
    }
}


/* Exercise Shell callbacks while the manager GUI is unassigned during lifecycle changes.
*/
testAppbarCallbackLifecycle()
{
    global manager_gui, appbar_registered
    saved_gui := manager_gui
    saved_registration := appbar_registered
    try
    {
        appbar_registered := true
        manager_gui := unset
        assertEqual(isManagerWindow(saved_gui.Hwnd), false, "unassigned manager is not a callback target")
        onAppbarActivate(1, 0, 0x6, saved_gui.Hwnd)
        onAppbarWindowPosition(0, 0, 0x47, saved_gui.Hwnd)
        onAppbarNotification(2, 0, appbar_callback, saved_gui.Hwnd)
        onExplorerRestart(0, 0, explorer_restart_message, saved_gui.Hwnd)
        assertEqual(appbar_registered, true, "early callbacks leave registration untouched")
        manager_gui := ""
        assertEqual(isManagerWindow(saved_gui.Hwnd), false, "empty manager is not a callback target")
        onAppbarActivate(1, 0, 0x6, saved_gui.Hwnd)
        onAppbarWindowPosition(0, 0, 0x47, saved_gui.Hwnd)
    }
    finally
    {
        manager_gui := saved_gui
        appbar_registered := saved_registration
    }
    assertEqual(isManagerWindow(saved_gui.Hwnd), true, "live manager is a valid callback target")
    assertEqual(isManagerWindow(0), false, "zero HWND is rejected")
}

/* Verify single-click raises without changing keyboard focus; double-click activates and resizes.
*/
testListClickActivation()
{
    global row_handles, last_active_hwnd, pending_list_activation_hwnd, list_click_deadline
    saved_deadline := list_click_deadline
    saved_handles := row_handles
    saved_active := last_active_hwnd
    saved_pending := pending_list_activation_hwnd
    original_window := Gui("+ToolWindow +AlwaysOnTop", "Original Focus Test")
    original_edit := original_window.AddEdit("w180", "Keep typing here")
    test_window := Gui("+ToolWindow +Resize -DPIScale", "List Click Test")
    try
    {
        original_window.Show("w220 h100")
        test_window.Show("w360 h260 NA")
        original_target := "ahk_id " original_window.Hwnd
        WinActivate(original_target)
        if !WinWaitActive(original_target, , 2)
            throw Error("Original test window could not be activated.")
        original_edit.Focus()
        focused_control := ControlGetFocus(original_target)
        target := "ahk_id " test_window.Hwnd
        app_name := StrLower(WinGetProcessName(target))
        saved_setting := IniRead(settings_file, "FocusResize", app_name, "")
        IniWrite("1", settings_file, "FocusResize", app_name)
        row_handles := Map(1, test_window.Hwnd)
        last_active_hwnd := original_window.Hwnd
        pending_list_activation_hwnd := 0
        WinGetPos(&x, &y, &width, &height, target)
        assertEqual(onListMouseActivate(0, (0x201 << 16) | 1, 0x21, window_list.Hwnd), 3, "list click prevents panel activation without eating click")
        onWindowClick(window_list, 0)
        onWindowClick(window_list, 1)
        assertEqual(WinActive(original_target) != 0, true, "single click retains original foreground window")
        assertEqual(ControlGetFocus(original_target), focused_control, "single click retains original keyboard focus")
        next_hwnd := test_window.Hwnd
        found_original_below := false
        Loop 1000
        {
            next_hwnd := DllCall("user32\GetWindow", "Ptr", next_hwnd, "UInt", 2, "Ptr")
            if !next_hwnd
                break
            if (next_hwnd = original_window.Hwnd)
            {
                found_original_below := true
                break
            }
        }
        assertEqual(found_original_below, true, "raised target is above original window in z-order")
        WinGetPos(&actual_x, &actual_y, &actual_width, &actual_height, target)
        assertEqual(actual_x "," actual_y "," actual_width "," actual_height, x "," y "," width "," height, "single click preserves window rectangle")
        assertEqual(IsObject(focus_resize_state), false, "single click skips focus resizing")
        assertEqual(IsObject(raised_preview_state), true, "single click records temporary raise")
        refreshWindows(true)
        assertEqual(row_handles.Count, 1, "refresh defers rebuilding during double-click interval")
        assertEqual(row_handles.Get(1, 0), test_window.Hwnd, "clicked window survives intervening refresh")

        assertEqual((WinGetExStyle(target) & 0x8) != 0, true, "preview rises above topmost original")
        assertEqual(last_active_hwnd, original_window.Hwnd, "single click retains original active highlight")
        assertEqual(pending_list_activation_hwnd, 0, "single click does not defer a Recent activation")
        WinMinimize(target)
        onWindowClick(window_list, 1)
        assertEqual(WinGetMinMax(target) != -1, true, "single click restores minimized window")
        assertEqual(WinActive(original_target) != 0, true, "minimized restore retains original focus")
        onWindowDoubleClick(window_list, 1)
        assertEqual(WinActive(target) != 0, true, "double click activates and focuses target")
        assertEqual(IsObject(raised_preview_state), false, "double click ends temporary preview")
        assertEqual((WinGetExStyle(target) & 0x8) != 0, false, "double click restores target topmost setting")
        assertEqual(IsObject(focus_resize_state), true, "double click retains focus resizing")
        restoreFocusWindow()
        WinGetPos(&actual_x, &actual_y, &actual_width, &actual_height, target)
        assertEqual(actual_x "," actual_y "," actual_width "," actual_height, x "," y "," width "," height, "double click still restores original rectangle")
        WinActivate(original_target)
        if !WinWaitActive(original_target, , 2)
            throw Error("Original focus could not be restored for preview cleanup test.")
        onWindowClick(window_list, 1)
        WinActivate(target)
        if !WinWaitActive(target, , 2)
            throw Error("Target focus could not be changed for preview cleanup test.")
        checkRaisedPreview()
        assertEqual(IsObject(raised_preview_state), false, "focus change clears preview")
        assertEqual((WinGetExStyle(target) & 0x8) != 0, false, "focus change restores non-topmost setting")
        WinSetAlwaysOnTop(1, target)
        onWindowClick(window_list, 1)
        restoreRaisedPreview()
        assertEqual((WinGetExStyle(target) & 0x8) != 0, true, "existing topmost setting remains enabled")

    }
    finally
    {
        restoreFocusWindow()
        row_handles := saved_handles
        last_active_hwnd := saved_active
        pending_list_activation_hwnd := saved_pending
        list_click_deadline := saved_deadline
        if IsSet(saved_setting)
        {
            if (saved_setting = "")
                IniDelete(settings_file, "FocusResize", app_name)
            else
                IniWrite(saved_setting, settings_file, "FocusResize", app_name)
        }
        restoreRaisedPreview()
        test_window.Destroy()
        original_window.Destroy()
    }
}

#Include Chrome-History-Cases.ahk
