# Window List Manager — design

Source version: 0.243. Stable baseline: v0.236 (original MVP v0.11).

## Intent

A narrow desktop window switcher that keeps open application windows easy to find.
The interface emphasizes titles, readable colors and one-click activation.

## Emergency recovery

`Library/Kill-Window-List-Manager.cmd` launches a standalone PowerShell process
enumerator. It force-terminates only exact `Window-List-Manager.exe` processes
and recognized AutoHotkey interpreters whose first `.ahk` command argument is
the unversioned manager launcher or a numeric manager implementation. It does
not depend on a responsive manager GUI or a working tray icon. This is distinct
from normal WinClose behavior and intentionally bypasses application save prompts.
PowerShell `-ListOnly` previews matching processes without stopping them;
insufficient permissions are reported instead of killing other programs.
The utility and its matcher tests do not alter the main app version (0.238).

## Interface and ordering

The main panel is dark, has no standard caption, and shows one title column.
A narrow top strip starts native dragging. Group labels stay internal.
Windows sort by app priority (positive whole numbers, no upper limit), application, Chrome domain when known,
then Recent activation order or alphabetical title. Total Commander defaults to priority 1.
Recent history covers activations observed in the current run.

Single-click restores and raises a window without activating it or taking focus
from the original application. Double-click activates it and applies optional focus sizing. The selected row follows
the last active external window. Hover exposes a square close control at the
right edge of the row, with width equal to its visible height.
Closing uses the application's normal close request and allows save prompts.

## Position and reserved space

Align Left / Align Right persist the desired side. Docking preserves the current
outer width and user-selected height, including dimensions supplied by FancyZones. Native dragging remains free; docking
resumes within the next 300 ms tick after release on the destination monitor.

Reserve screen space is a persisted Options switch, off by default.
If enabled before choosing a side, it selects Right. Windows Shell appbar
registration reserves a strip on the panel's current monitor only.
ABM_QUERYPOS negotiates with taskbars and other appbars; ABM_SETPOS commits
the rectangle. The reserved strip uses the final approved rectangle; the panel keeps its current dimensions.
Query bounds come from the full monitor, not the already reduced work area,
so the reservation does not repeatedly shrink itself.

Before dragging, release the old reservation. Re-register at the destination
after release. Disabling and exiting release it as well. The docking timer
reconciles geometry, resolution and other appbar changes; Explorer restart
invalidates registration so the next tick can register again.
Activation and position changes are reported to the Shell.

Reserved mode suppresses main-panel Always on Top while retaining its saved
preference for normal mode. Fullscreen applications may cover the panel.
Maximized windows normally respect the reserved work area; arbitrary floating
windows are not forcibly moved or resized.

## Settings

The adjacent INI stores position, outer size, dock side, sort mode, width lock,
topmost preference, ReserveSpace, app priorities, colors and app/title ignore rules.
Individual-window exclusions and Recent history are session-only.
Start with Windows uses the current-user Run key and the current script/EXE path.
Lock Width constrains manual outer width resizing; docking preserves height and adopts external width changes.

## Domain colors

Exact domain color takes precedence over the closest saved parent-domain color.
A rule for example.com also applies to www.example.com and deeper subdomains;
a specific subdomain rule overrides it. Matching respects dot-separated hostname
boundaries. Domain colors take precedence over explicit app color, followed by
the configurable default font color. Domains require the optional Chrome extension and
local PowerShell bridge. Without domain data, use app grouping and app colors.
The bridge does not change browser focus or use the clipboard.

## Chrome domain color matching — v0.241

The previous matcher accepted a Chrome record whenever its title appeared
anywhere inside the native window title. A short title such as "Project" could
therefore match "Project Settings" and lend the wrong domain color. A saved
manual domain override also remained attached to the HWND when the active
Chrome tab changed.

The new pure geometry matcher first strips only the native Google Chrome
suffix, then requires an exact case-insensitive active-tab title. It chooses
the closest record by the sum of outer rectangle coordinate differences,
accepting at most 128 px total difference, and rejects a match when the next
candidate is within 32 px of the best (indistinguishable stacked windows).
Unknown/ambiguous rows inherit app/default color instead of another domain's
color. Live Chrome records clear stale manual domain overrides, including for
non-web tabs whose domain is empty; cached or missing records can still use a
manual override. Explicit manual-domain assignments for non-Chrome windows
retain their previous behavior.

AHK tests exercise exact title, unrelated titles, ambiguous same-title
windows, and stale geometry. A Node contract test can check source structure
in a non-Windows environment; actual GUI color and multi-DPI matching must be
checked on Windows.

## Implementation choices

Keep the existing AHK v2 application and native controls. Use Shell appbar
reservation rather than continuously resizing unrelated application windows.
That delegates work-area management to Windows and avoids changing floating
window layouts. Always on Top remains available in normal mode.

## Verification status

Non-Windows static inspection and Drive readback are possible in this environment.
The AHK suite includes real Shell work-area checks for Windows; execution,
multi-monitor behavior, DPI transitions, fullscreen and EXE compilation require
Windows verification. Source edits do not rebuild an existing EXE or ZIP.

## Main entry and implementations

Root Window-List-Manager.ahk is the main launcher and is compiled directly to
Window-List-Manager.exe. It selects the highest numeric version from
Lib/Window-List-Manager-<version>.ahk and starts it with AHK v2.
The script entry uses its running AHK interpreter; the EXE uses Library/AutoHotkey-v2.exe.
Versioned implementations resolve the root directory explicitly. INI, Library helpers,
and Windows startup entries therefore remain independent of the selected version.
Library/Window-List-Manager-Launcher.ahk from the old layout is unused.

## Dock monitor stability

The chosen monitor is cached independently of panel activation and Shell position
notifications. Native move completion refreshes the monitor from the panel's new
location. If the monitor disappears, selection falls back to the nearest monitor.
The same monitor selection drives ordinary docking and AppBar reservation; monitor
selection occurs before AppBar registration so registration cannot change the target.

## Taskbar visibility

The Options checkbox Hide from taskbar controls +ToolWindow on the main GUI,
suppressing its taskbar and Alt+Tab entry when enabled. It defaults to enabled,
applies immediately without activation, and persists as Panel/HideFromTaskbar.
The script retains the system tray icon and the custom title strip controls.

## User-facing executable entries

The root user-facing actions are Window-List-Manager.exe,
Install-Chrome-Extension.exe and Build-EXE.exe. The latter two are compiled AHK v2
wrappers which execute their matching external PowerShell helpers in Library.
Build-EXE.ps1 builds and path-checks all entries. CMD launchers are recovery helpers
in Library. Source files keep their genuine AHK/PS1/CMD extensions; they are not
renamed to look like binaries. Existing entry EXEs need Windows compilation once.

## Plain Chrome domain tracking

The extension reports normal and popup Chrome windows, using the active tab URL
for both. Popup geometry and title are preserved for HWND matching. DevTools
windows remain excluded. Extension updates require reinstalling the local copy
and reloading the extension in Chrome; changing the project source alone is not enough.

## Default row font color

Color priority: nearest explicit domain rule, explicit program rule, then
Panel/DefaultFontColor (default D0D0D0). Invalid values fall back to light grey.
Options exposes a color picker, a hex preview and Reset to Grey; changes refresh
rows immediately without changing saved program/domain rules. Former automatic
category colors no longer override the fallback.

## Focus and deferred Recent ordering

Single-click has a separate non-activating raise path. Double-click uses the
existing confirmed activation path and optional focus sizing. A pending target is highlighted after
WinWaitActive confirms focus; list-induced focus does not immediately update its
Recent rank. The pending activation is committed when a different external window
becomes active. Manager/Options/Ignore focus does not commit it. Custom draw uses
a blue background for the last active external HWND even when the list is unfocused;
text colors retain domain/program precedence.

## Opt-in focus sizing

FocusResize/<lowercase EXE name> controls temporary geometry per application group.
Capture HWND, PID and the original outer rectangle only after list activation
confirms focus. Use the target monitor's work area, not the manager's monitor.
Landscape targets a left/right half; portrait targets a top/bottom half according
to original center position. A 150 ms focus monitor restores the original rectangle
on blur using non-activating WinMove. Owned dialogs are excluded. Restoration also
runs on disable and clean exit; closed/reused HWNDs are checked against PID.
Unrelated windows and outside-list activations are unchanged. This option is off
by default; it is an explicit exception to the rule against unsolicited resizing.

## Version numbering

Use a single decimal point with exactly three fractional digits. Current release:
0.243; next release: 0.244. Each release increments by 0.001. Version strings,
implementation filenames, title labels, test includes and documentation must agree.
Legacy multi-dot files remain historical and must not take precedence over the
current version. Launcher tests cover the new format and migration ordering.

## Domain color picker cells

The Options domain ListView displays Choose... in column two and custom-draws
that cell with the effective row color and a contrasting black/white label.
LVM_SUBITEMHITTEST opens the existing native picker only on a click in that cell.
The selected domain is saved through the existing color workflow; reset and
parent-domain inheritance remain unchanged. Hexadecimal values remain internal.

## Application color picker cells — v0.242

The Application Options ListView's third column uses the same Choose... swatch
and native Windows color picker interaction as the Chrome domain ListView.
Only a click on the application's color subitem opens the existing
optionsSetColor workflow; selection and priority clicks do not. Custom draw
previews getGroupColor(app_name, "", ""), so an explicit program color or the
default font color appears consistently without applying Chrome domain color.
Reset Program Color refreshes the swatch and the live window list. The existing
Assign/Reset Color to Program buttons are retained, and v0.236 remains unchanged.

## Dark Options and tray lifecycle

Owner-drawn push buttons avoid dependence on Windows' light button theme. Native
checkbox/combo color messages use a shared dark brush; combo child handles are
registered through GetComboBoxInfo. Domain custom-draw colors remain independent.
Tray items are Open UI, Restart script and Exit. Exit calls closeManager/ExitApp so the existing exit cleanup saves geometry, restores temporary focus sizing and releases AppBar space. The notification callback debounces
left-click selection, retaining native right-click behavior. Hidden state suspends
appbar registration/docking and hover overlays; restore reuses the saved size and
monitor. Restart runs the root launcher, not Reload on the versioned file.

## Hidden panel restoration

Open UI calls Gui.Show directly, then uses IsIconic and Gui.Restore if necessary.
Tray toggle uses IsWindowVisible/IsIconic without title-based hidden-window lookup.
The tray regression test explicitly disables DetectHiddenWindows before hide/restore.


## Domain focus-size checkbox

The domain ListView has three columns: hostname, color swatch and Resize on focus.
The third cell uses light checked/unchecked box glyphs on a dark background. A cell
click or Space on the selected row toggles the effective state and saves an explicit
DomainFocusResize/<normalized hostname> value (0 or 1). Auto-repeat is suppressed.
Saved resize-only domains remain listed even without a color rule or open window.

The list's captured row-domain identity is passed through double-click activation
to `applyFocusResize` before evaluating domain overrides. The live bridge lookup
remains the fallback when the list has no valid domain; a late or ambiguous bridge
match cannot silently turn a domain-only resize rule into the disabled Chrome app
fallback. This does not enable resizing on unrelated external activations.

For Chrome, closest domain override wins, then FocusResize/chrome.exe. A false
domain override takes precedence over a true app setting. Other apps use only their
app rule. Capture the resolved domain with the original rectangle at list activation;
disabling its effective rule restores the saved rectangle. App setting changes
refresh the domain checkboxes and preserve enabled domain overrides. Existing
list-only activation, half-screen sizing and restore-on-blur semantics are retained.

## Restart callback lifecycle

Shell activation, position, appbar and Explorer-restart callbacks validate the
manager through isManagerWindow before reading its HWND. The check short-circuits
unassigned/non-object globals and rejects invalid native windows. OnExit unregisters
these four message handlers before geometry/focus cleanup and AppBar release, so
teardown notifications cannot access a manager which is no longer available.
The regression suite calls these callbacks with an unassigned manager global,
then confirms normal live-window matching after restoring it.

## Unrestricted priority values

Both priority editors accept positive decimal whole numbers with no upper cap. Saved priorities stay as digit strings rather than native integers. Sort compares digit count, then lexicographic digits for equal lengths, preserving exact ordering beyond the native integer range. Defaults remain 1 for Total Commander and 5 for other apps. Invalid stored values retain the default fallback.

## Raise without activation

WM_MOUSEACTIVATE returns MA_NOACTIVATE for left clicks on the main ListView,
preserving the mouse message for click/double-click dispatch while keeping the
original application's keyboard focus. Other controls retain their normal behavior.
Single-click restores minimized targets with ShowWindow(SW_SHOWNOACTIVATE), then
raises them temporarily with SetWindowPos(HWND_TOPMOST, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW).
It does not set the active highlight, change Recent tracking, or apply focus sizing.
Double-click retains WinActivate/WinWaitActive and the existing resize-and-restore
behavior. Regression coverage checks original control focus, restored visibility,
z-order, unchanged rectangle/history, and double-click activation.

## Frontmost inactive preview

Single-click temporarily raises the target into the topmost band without activation
so an existing Always on Top foreground window cannot cover it. Capture HWND, PID,
original topmost flag and original foreground HWND. Restore the previous preview
before raising another; a 150 ms observer ends the preview when foreground changes.
Double-click, context menu and exit also restore its previous topmost setting.
Originally topmost targets stay topmost; reused HWNDs are rejected by PID.
The manager retains its position above the preview if it is already topmost.
Single-click never updates focus history or invokes the focus-sizing feature.

## Preserve double-click expansion through preview updates

Raising a preview changes the target's TOP signature. A timer-driven ListView
delete/rebuild between mouse clicks can invalidate native double-click recognition.
Record a deadline using the Windows GetDoubleClickTime setting plus 50 ms before
raising the preview. refreshWindows defers all rebuilds until that deadline passes,
and also while list_activation_in_progress is true. The following normal refresh
reconciles pending changes. Activation, per-app/domain resize preferences and
restore-on-blur behavior are retained. Regression coverage forces a refresh between
single- and double-click handlers and checks target stability and subsequent expansion.

## Chrome history — v0.232 / extension 0.1.3

The existing Window List Manager Domains extension is used; Chome-Window-Grid is separate.
Manager 0.233 clears destroyed history-control references during Options teardown,
so independent history sorting remains valid after the dialog closes.
Manager 0.234 constructs the history context menu without shadowing the
case-insensitive built-in `Menu` class, and tests menu construction without showing it.
In Options, click the **History** checkbox beside a domain to enable collection.
Parent-domain rules include subdomains; a disabled child rule overrides its parent.
The main dialog then contains open windows above and saved Chrome pages below, with
an adjustable divider. The lower list stays anchored to the bottom. Hide it with
Show Chrome history list. The default retention is **20 pages per enabled domain**;
Options accepts limits from 1 to 10000. Reducing the limit removes the oldest pages.
History has its own Recent / Alphabetical sort; click its header or use Options.

History records the active HTTP/HTTPS page observed in each normal/plain Chrome
window while the manager runs. It does not import Chrome's full browsing history.
Repeated heartbeats and title/geometry changes do not advance recency. Saved titles,
full URLs, profile identities and visit markers persist in
Window-List-Manager.chrome-history.tsv beside the launcher. Cleared/removed entries
stay removed through unchanged snapshots and restarts; a genuine revisit can record them again.
Disabled domains keep previously saved history. Right-click history to copy a URL,
remove an item or explicitly clear saved history. Hover shows the complete URL.
Manager 0.236 directly launches a new Chrome window via the installed Chrome
executable and `--new-window`, without the extension command queue or the
Windows default URL handler. After a new Chrome HWND appears, center its outer
rectangle in the work area of the monitor hosting the manager. The original
Chrome profile is not forced. The matching active URL in an actual listed Chrome
window suppresses the same URL from the history display without deleting its
saved record. Right-click > Open URL behaves the same way. Incognito pages are
excluded.
Manager 0.237 also suppresses a history URL immediately when its launch begins,
then retains that suppression against the newly detected Chrome HWND and PID
even if the extension has not matched the URL. A failed-to-materialize launch
is released at the pending request deadline; a reopened window's URL becomes
visible again after that window exits. Version 0.236 remains the stable source.
Manager 0.238 releases all Options control references before destroying the
Options GUI so reentrant WM_NOTIFY during child teardown cannot retrieve an
already-destroyed ListView HWND. The native notification and domain key handlers
also ignore controls whose HWND getter reports destruction.

## Chrome active-tab detachment — v0.240 / extension 0.1.4

The Window List Manager Domains extension sends the active tab's Chrome tab ID,
window ID and full tab count alongside existing active-title/domain records.
The bridge preserves six legacy snapshot columns and adds tab count as field 13
of the live per-profile record. Empty domains are accepted so a Chrome New Tab
page can also be detached.

On live Chrome window rows with two or more tabs, the context menu shows
**Detach tab** before the existing actions. The manager writes a validated
profile-scoped command to its local bridge queue using `detach_tab`, the
Chrome window ID and tab ID. The bridge responds only to that profile. The
extension checks that the tab still belongs to the source Chrome window with
two or more tabs, and uses `chrome.windows.create({tabId})` to move the
existing tab, keeping page state and pinning. Stale IDs are harmless.

The legacy `open_url` command protocol remains supported. Detachment is
hidden when the extension is not connected or does not provide tab count;
an old extension needs reinstallation/reload, not a browser automation fallback.

Update: sync all files, run **Install-Chrome-Extension.exe** again, open
chrome://extensions/ and Reload Window List Manager Domains in each used profile.
Restart Window-List-Manager.exe. No main launcher EXE rebuild is required.
The extension now polls the local API every two seconds while connected, so domain
colors initialize without needing a Chrome window activation. A domain-only cache
(no full URLs) supplies initial hints; fresh snapshots replace them. Native row
repaint occurs explicitly after color maps are computed, including the first paint.

The extension/API bridge and Library/Chrome-History.ahk remain separate modules.
The API carries versioned snapshots plus profile-targeted, acknowledged URL commands
through loopback only. Old domain-only snapshots still support live grouping/colors;
URL history requires extension 0.1.3. Do not remove the Library/Chrome-History.ahk module.

Verification: Node protocol/transfer tests and static AHK inspection ran outside
Windows. Run Tests/Window-List-Manager-Test.ahk (including Chrome-History-Cases.ahk)
and Tests/Chrome-Domain-Bridge-Test.ps1 on Windows for GUI, persistence, work-area and
real local API integration checks. Windows/Chrome execution and EXE compilation
have not been verified in this environment.
