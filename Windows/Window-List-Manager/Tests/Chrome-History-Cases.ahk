/* Exercise actual persistence, domain retention, ordering, clear and API command data.
*/
testChromeHistory()
{
    global history_items, history_observed, domain_file, history_bridge_v2, history_live_urls, history_open_requests, history_reopened_windows
    saved_domain_file := domain_file
    saved_items := history_items
    saved_observed := history_observed
    saved_live_urls := history_live_urls
    saved_open_requests := history_open_requests
    saved_reopened_windows := history_reopened_windows
    history_items := Map()
    history_observed := Map()
    history_open_requests := []
    history_reopened_windows := Map()
    domain_file := A_Temp "\WindowListManager-Commands-Test-" A_TickCount
    try
    {
        assertEqual(IsObject(createHistoryContextMenu()), true, "history context menu constructs a Menu object")
        assertEqual(getHistoryLimit(), 20, "history defaults to twenty pages")
        assertEqual(getHistoryRuleDomain("example.com"), "", "history is opt-in")
        IniWrite("1", settings_file, "DomainHistory", "example.com")
        assertEqual(getHistoryRuleDomain("app.example.com"), "example.com", "history inherits enabled parent")
        IniWrite("0", settings_file, "DomainHistory", "private.example.com")
        assertEqual(getHistoryRuleDomain("private.example.com"), "", "disabled child blocks parent collection")
        records := []
        Loop 22
            records.Push({live: true, domain: "example.com", url: "https://example.com/page/" A_Index "?q=one%20two#part", title: Format("Page {:02}", A_Index), client: "profile-1", window_id: A_Index, tab_id: A_Index, visited_at: 1700000000000 + A_Index, visit_id: "visit-" A_Index})
        observeChromeHistory(records)
        assertEqual(history_items.Count, 20, "retention removes oldest two pages")
        key := "example.com`t" records[22].url
        assertEqual(history_items.Has("example.com`t" records[1].url), false, "oldest URL removed")
        seen := history_items[key].last_seen
        observeChromeHistory(records)
        assertEqual(history_items[key].last_seen, seen, "heartbeat does not advance recency")
        loadChromeHistory()
        assertEqual(history_items.Count, 20, "history survives disk reload")
        assertEqual(history_items[key].url, records[22].url, "full query and fragment persist")
        items := []
        for item_key, item in history_items
            items.Push(item)
        assertEqual(sortHistoryItems(items, "Recent")[1].title, "Page 22", "recent order is descending")
        assertEqual(sortHistoryItems(items, "Alphabetical")[1].title, "Page 03", "alphabetical order is independent")
        history_items.Clear()
        saveChromeHistory()
        loadChromeHistory()
        observeChromeHistory(records)
        assertEqual(history_items.Count, 0, "cleared pages stay cleared across heartbeat and reload")
        records[22].visit_id := "real-revisit"
        records[22].visited_at += 1000
        observeChromeHistory([records[22]])
        assertEqual(history_items.Count, 1, "real revisit is collected after clear")
        assertEqual(getVisibleHistoryItems([history_items[key]], Map()).Length, 1, "saved URL is visible while no live window shows it")
        assertEqual(getVisibleHistoryItems([history_items[key]], Map(records[22].url, true)).Length, 0, "live URL is hidden from history without deletion")
        assertEqual(history_items.Has(key), true, "live URL stays persisted for later history display")
        history_live_urls := Map(records[22].url, true)
        updateChromeHistoryList(true)
        assertEqual(history_list.GetCount(), 0, "rendered history list hides the page shown in live Chrome list")
        history_live_urls := Map()
        updateChromeHistoryList(true)
        assertEqual(history_list.GetCount(), 1, "closed live page becomes visible again in saved history")
        history_open_requests.Push({url: records[22].url})
        updateChromeHistoryList(true)
        assertEqual(history_list.GetCount(), 0, "a requested history URL disappears immediately, before the Chrome bridge sees it")
        history_open_requests := []
        reopened_gui := Gui(, "Reopened Chrome history test window")
        reopened_gui.Show("w150 h100")
        history_reopened_windows[reopened_gui.Hwnd] := {url: records[22].url, pid: WinGetPID("ahk_id " reopened_gui.Hwnd)}
        updateChromeHistoryList(true)
        assertEqual(history_list.GetCount(), 0, "reopened URL remains hidden while its HWND exists without bridge data")
        reopened_gui.Destroy()
        updateChromeHistoryList(true)
        assertEqual(history_list.GetCount(), 1, "history URL reappears after the reopened window closes")
        assertEqual(history_reopened_windows.Count, 0, "closed-window suppression is pruned")
        assertEqual(getCenteredChromeRect(800, 600, 0, 0, 1920, 1080).x, 560, "new Chrome window centers horizontally")
        assertEqual(getCenteredChromeRect(800, 600, 0, 0, 1920, 1080).y, 240, "new Chrome window centers vertically")
        assertEqual(getCenteredChromeRect(800, 600, -1920, 0, 0, 1080).x, -1360, "Chrome centers on negative-coordinate secondary monitor")
        command := buildChromeLaunchCommand("C:\Program Files\Google\Chrome\Application\chrome.exe", records[22].url)
        assertEqual(command, '"C:\Program Files\Google\Chrome\Application\chrome.exe" --new-window "' records[22].url '"', "history URL launches explicitly in a new Chrome window")
        FileAppend("broken record`n", chrome_history_file, "UTF-8-RAW")
        loadChromeHistory()
        assertEqual(history_items.Count, 1, "damaged line leaves valid history intact")
        IniWrite("1", settings_file, "History", "Limit")
        records[21].visit_id := "another-visit"
        records[21].visited_at += 2000
        observeChromeHistory([records[21]])
        assertEqual(history_items.Count, 1, "reduced limit is applied by recency")
        assertEqual(historyDomainFromUrl("javascript:alert(1)"), "", "nonweb URLs cannot be opened")
        rect := getHistoryLayout(220, 500, true, 0.5)
        assertEqual(rect.history_y + rect.history_height, 499, "history stays anchored to bottom")
        assertEqual(rect.splitter_y, 18 + rect.live_height, "top list meets divider")
        assertEqual(getHistoryLayout(220, 500, false, 0.5).live_height, 481, "hidden history returns full height")
    }
    finally
    {
        try reopened_gui.Destroy()
        domain_file := saved_domain_file
        history_items := saved_items
        history_observed := saved_observed
        history_live_urls := saved_live_urls
        history_open_requests := saved_open_requests
        history_reopened_windows := saved_reopened_windows
        IniDelete(settings_file, "DomainHistory")
        IniDelete(settings_file, "History")
    }
}
