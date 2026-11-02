# Window List Manager

**Purpose:** a narrow, dark list for finding, switching to and closing open Windows application windows.

AutoHotkey **v2**, Windows 11. The current version appears in the Options window title. **Stable baseline: v0.236** (original MVP: v0.11). Keep v0.236 unchanged when developing newer releases.

![Window List Manager screenshot placeholder — replace with a screenshot](screenshot.png)

Replace Documents/screenshot.png with your screenshot using the same filename.

## Contents

- [Use](#use)
- [Options](#options)
- [Right-click actions](#right-click-actions)
- [Detach Chrome tab (v0.240)](#detach-chrome-tab-v0240)
- [Chrome extension installation](#chrome-extension-installation)
  - [1. Prepare the files](#1-prepare-the-files)
  - [2. Run the installer](#2-run-the-installer)
  - [3. Load the extension in Chrome](#3-load-the-extension-in-chrome)
  - [4. Start the manager and verify](#4-start-the-manager-and-verify)
  - [Updating the extension](#updating-the-extension)
  - [Troubleshooting](#troubleshooting)
- [Files and build](#files-and-build)
- [Emergency stop — frozen window or tray icon](#emergency-stop--frozen-window-or-tray-icon)
- [Test](#test)
- [Entry files and version selection](#entry-files-and-version-selection)
- [Domain color inheritance](#domain-color-inheritance)
- [Chrome domain color matching (v0.241)](#chrome-domain-color-matching-v0241)
- [Files to run](#files-to-run)
- [Plain Chrome windows](#plain-chrome-windows)
- [Default font color](#default-font-color)
- [Active window and Recent ordering](#active-window-and-recent-ordering)
- [Per-application focus sizing](#per-application-focus-sizing)
- [Version format](#version-format)
- [Domain color picker cells](#domain-color-picker-cells)
- [Application color picker cells (v0.242)](#application-color-picker-cells-v0242)
- [Tray controls and dark Options](#tray-controls-and-dark-options)
- [Domain focus sizing](#domain-focus-sizing)
- [Chrome history — v0.232 / extension 0.1.3](#chrome-history--v0232--extension-013)

## Use

Run Window-List-Manager.ahk with AutoHotkey v2.
Click a title once to restore and raise its window while keeping keyboard focus
on your original window.
Double-click activates and focuses the target, and applies optional focus sizing
when enabled for the app or domain.
Hover a row to reveal a square × button for normal window closure.
Drag the top strip to move the panel. Right-click the list to open settings and actions.

## Options

| Control | Purpose |
| --- | --- |
| Sort mode: Recent / Alphabetical | Order titles inside internal application/domain groups. Recent tracks this run's activations. |
| Set Priority | Set app group order: 1 first; larger positive whole numbers come later, with no upper limit. Total Commander defaults to 1; others to 5. |
| Application color picker / Assign / Reset Color to Program | Click the application's colored Choose... cell to set its title font color, or use the existing buttons. |
| Assign / Reset Color to Domain | Set or remove a Chrome domain's font color. Domain overrides program color. |
| Ignore List | Review and remove app, exact-title and temporary window exclusions. |
| Start with Windows | Enable current-user startup for this script or EXE at its current location. |
| Lock Width | Constrain manual width resizing. Docking preserves the chosen height and the current width, including external placement. |
| Hide from taskbar | Hide the main panel from the taskbar and Alt+Tab; apply immediately and remember the choice. |
| Reserve screen space | Reserve a strip beside the panel so maximized windows leave room for it. Off by default. |

Reserve screen space affects only the panel's monitor. Dragging releases the old
strip; after release the reservation follows the panel to the destination monitor.
Turning it off or exiting releases the strip. Main-panel Always on Top is
temporarily suppressed in this mode; its saved normal-mode preference is retained.
Floating windows can overlap the strip, and fullscreen applications can cover it.

## Right-click actions

- Detach tab: shown first for a Chrome window with at least two tabs; move its
  active tab into a separate Chrome window without navigating/reloading it.
- Align Left / Align Right: remember the side and dock after moving or resizing.
- Move Panel: start moving the panel.
- Always on Top On / Off: control the main panel in normal mode.
- Window: Always on Top On / Off: control the clicked application's window.
- Assign Color to Program / Domain and App Priority: edit the clicked row's group.
- Ignore This Window / App / Title: hide the window, application or exact title.
- Show Ignore List, Options, Exit.

The panel displays titles only. Grouping by app/domain stays internal.
Topmost windows have a lighter row background. Settings persist in the adjacent
INI; temporary window exclusions and Recent history last for the current run.
The program does not save or restore application sessions.

## Detach Chrome tab (v0.240)

Right-click the title of a Chrome window in Window List Manager. **Detach tab**
appears as the very first context-menu item only when the connected Chrome
extension reports two or more tabs in that window. It moves the **active tab
of that specific window** into its own Chrome window using the existing tab ID,
keeping its page state. The new Chrome window takes focus.

The command is sent only to the Chrome profile that owns the tab through the
local bridge. Closing the source window, changing the active tab, or reducing
the source to one tab before the command executes safely cancels the action.
With a disconnected or outdated extension, the menu item is hidden.

Requires **Window List Manager v0.240**, **Window List Manager Domains extension
v0.1.4**, and the updated `Library/Chrome-Domain-Bridge.ps1`. After syncing,
rerun the extension installer, click **Reload** in `chrome://extensions/` for
each Chrome profile, and restart Window List Manager.

## Chrome extension installation

The extension supplies the active tab's domain and tab count for each Chrome
window, including plain Chrome windows without an address bar. It enables
automatic domain grouping, domain font colors, and the Detach tab action.

### 1. Prepare the files

1. Let Google Drive finish syncing the Window-List-Manager folder.
2. Keep the existing folder structure: the root contains
   `Install-Chrome-Extension.exe`; Library contains
   `Install-Chrome-Extension.ps1` and either `Chrome-Extension.zip` or the
   `Chrome-Extension` folder with `manifest.json`.
3. If using Drive streaming, make these files available offline before installation.

### 2. Run the installer

1. Double-click `Install-Chrome-Extension.exe` in the main project folder.
2. The installer copies the extension to this permanent local folder:

   `%LOCALAPPDATA%\WindowListManager\Chrome-Extension`

3. It opens that folder in Explorer and tries to open Chrome's extensions page.
   The installer prepares the files; the next step enables them in Chrome.

### 3. Load the extension in Chrome

1. In the Chrome profile where you want domain detection, open
   `chrome://extensions/` in a normal Chrome window.
2. Turn on **Developer mode** in the upper-right corner.
3. Click **Load unpacked**.
4. In the folder picker, paste
   `%LOCALAPPDATA%\WindowListManager\Chrome-Extension` into its address bar and press Enter.
5. Select that folder. It must directly contain `manifest.json`.
   Select the folder, not the ZIP or the manifest file.
6. Confirm that the new extension appears and is enabled.
7. Keep the local extension folder in place. Chrome loads it from this location.

Repeat this step for each Chrome profile whose windows you want the manager to track.

### 4. Start the manager and verify

1. Restart Window List Manager. It automatically starts
   `LibraryChrome-Domain-Bridge.ps1`.
2. Open two ordinary web pages on different domains in separate Chrome windows.
3. Activate each window, change its active tab once, and allow a few seconds for updates.
4. Open the manager's **Options** and check its domain list.
5. Right-click a detected Chrome row and choose **Assign Color to Domain...**.
   Choose a color and confirm that the row changes color. Domain color takes
   precedence over program color.
6. Close and reopen Options to confirm that the saved domain color remains listed.

If the domain action asks for a hostname, automatic detection has not supplied a
domain for that row. Manual entry is a fallback, not proof that the extension works.

### Updating the extension

1. Sync the updated project files.
2. Run `Install-Chrome-Extension.exe` again to refresh the local copy.
3. Open `chrome://extensions/` and click **Reload** on the extension card.
4. Restart Window List Manager and repeat the verification steps.

Updating project files alone does not update the extension's local installed copy.

### Troubleshooting

- **Chrome did not open:** open `chrome://extensions/` manually.
- **Manifest missing:** choose the exact folder containing `manifest.json`,
  not its parent folder or the ZIP. Run the installer again if necessary.
- **No domains in Options:** check that the extension is enabled in the same Chrome
  profile as the target windows. Restart the manager and activate a normal web tab.
- **Domain bridge missing:** sync `LibraryChrome-Domain-Bridge.ps1` and restart
  the manager. If Windows blocks the helper, inspect the reported PowerShell error.
- **Extension shows errors:** open its **Errors** details on
  `chrome://extensions/`, reload it, and repeat the test.
- **Managed Chrome blocks Developer mode or Load unpacked:** installation requires
  permission from the browser administrator.
- **Ambiguous window match:** duplicate tab titles and near-identical window
  rectangles can make matching uncertain. Test with distinct page titles first.

Without the extension, app grouping and the other window controls still work.
The extension sends active-tab titles, domains and window rectangles to the local
listener at `127.0.0.1:18763`.

Chrome's official loading instructions:
[Load an unpacked extension](https://developer.chrome.com/docs/extensions/get-started/tutorial/hello-world#load-unpacked).

## Files and build

- Root: Window-List-Manager.ahk and Window-List-Manager.exe are the main launchers; user settings stay here.
- Lib: versioned tool implementations, named Window-List-Manager-<version>.ahk.
- AGENTS.md contains development rules.
- Library: runtime helpers, Chrome extension, icons and build scripts.
- Documents: this README, design.md and screenshot.png.
- Tests: Window-List-Manager-Test.ahk and the emergency-stop process matcher test.

Keep the folder structure intact. Run Build-EXE.exe on Windows with AutoHotkey v2
and Ahk2Exe installed to build the EXE launcher. Once built with the current build
script, both main entry points select the highest numbered implementation in Lib.
A new versioned implementation does not require rebuilding the EXE. Keep the generated Library/AutoHotkey-v2.exe runtime beside it.
Old compiled EXEs and ZIP packages can still contain older code. When switching from AHK to EXE, toggle Start with
Windows off and on to update the startup path.

## Emergency stop — frozen window or tray icon

Double-click **[Kill-Window-List-Manager.cmd](Library/Kill-Window-List-Manager.cmd)** in
the `Library` folder to forcibly stop all detected
Window List Manager instances. It matches the compiled `Window-List-Manager.exe`
and known AutoHotkey runners executing `Window-List-Manager.ahk` or a numeric
`Window-List-Manager-<version>.ahk` script. Other AHK tools are not targeted.
This is an emergency action: it bypasses the normal close/save workflow.
If access is denied, run the CMD file **as administrator**. Explorer may leave
a temporary ghost tray icon until you hover over the notification area.

For a safe preview or matcher test, run these from the project folder:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Library\Kill-Window-List-Manager.ps1 -ListOnly
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Tests\Kill-Window-List-Manager-Test.ps1
```

The utility is independent of the manager UI, so it remains usable when the
manager cannot process clicks or tray commands.

## Test

Run Tests/Window-List-Manager-Test.ahk with AutoHotkey v2. It temporarily changes
panel layout and work areas to test docking and reservation across connected monitors.

Then check manually:

1. Activate and close disposable windows through the list; confirm save prompts remain available.
2. Drag to each monitor and release. Check both dock sides, different DPI settings and width locking.
3. Enable Reserve screen space. Maximize a window on that monitor; confirm the panel has its own strip.
4. Move the panel to another monitor. Confirm the old monitor regains its space and the new one reserves it.
5. Disable the option and exit; confirm all reserved space is released. Restart with it enabled to check persistence.
6. Check fullscreen apps, Explorer restart and monitor disconnect/reconnect.
7. Set different app/domain colors; confirm the domain wins and resetting it restores the app color.
8. Check sorting, priority, ignore rules, active selection and Start with Windows.

Static checks and uploaded source contents were verified outside Windows.
AHK execution, appbar behavior and compilation still require Windows verification.

## Entry files and version selection

- Run **Window-List-Manager.ahk** with AHK v2, or run **Window-List-Manager.exe**.
- Both main entry points select the newest numeric version matching
  `Lib\Window-List-Manager-<version>.ahk`.
- Current implementation: `Lib\Window-List-Manager-0.243.ahk`.
- The versioned script runs the UI and declares its displayed version.
- Settings stay in the root `Window-List-Manager.ini`; helpers, icon, Chrome
  extension, and the packaged AHK runtime stay in `Library`.
- Build-EXE.exe compiles the root Window-List-Manager.ahk into the root EXE.
  Library/Window-List-Manager-Launcher.ahk from the previous layout is obsolete
  and is no longer used or generated.
- Sync all files before launching. Restart to load newly synced code; a running
  process does not switch implementations automatically.
- Start with Windows points to the main AHK entry. Toggle that option off/on once
  if Windows still points to an old versioned implementation.

Launcher tests on Windows, from the main project folder:

```powershell
& '.\Library\AutoHotkey-v2.exe' '.\Window-List-Manager.ahk' --test
& '.\Library\AutoHotkey-v2.exe' '.\Window-List-Manager.ahk' --check
```

Exit code 0 means success. --test checks numeric version ordering;
--check also checks that a versioned implementation and runtime can be found,
without opening the UI. Build-EXE.exe runs the EXE --check test after compilation.

## Domain color inheritance

A saved color for `example.com` applies to `www.example.com`, `app.example.com`,
and deeper subdomains. The closest explicit domain rule wins: a saved color for
`app.example.com` overrides `example.com` for that hostname and its descendants.
Resetting a child rule restores the parent color. Unrelated names such as
`notexample.com` do not match. Program color is used when no domain rule matches.

Activation of listed windows does not change the panel's docking monitor. To move
the panel to another display, drag its title strip there and release it.

Options → Hide from taskbar controls whether the panel appears in the Windows
taskbar and Alt+Tab. Enabled by default; changes apply immediately and are saved.
Its title strip, close button, dragging, and system tray icon remain available.

## Chrome domain color matching (v0.241)

The live Chrome extension provides the active tab title, domain, and window
rectangle. Manager v0.241 matches the **complete tab title**, not a substring,
then checks window position and size. Two equally plausible Chrome windows
with the same title do not borrow each other's domain color: the manager uses
the program/default font color until the match becomes unambiguous.

Current live extension data also clears a stale manual domain override for
that Chrome window, so switching tabs to a different domain updates its color.
Manual domains remain a fallback when automatic detection is unavailable.
Configured parent-domain color inheritance is unchanged.

To verify: open two Chrome windows with similar titles but different domains
and colors, then switch tabs, overlap or separate the windows, and reopen
Options. Check that an unknown or ambiguous match uses the fallback color
instead of a different website's color.


## Files to run

| Executable in the main folder | Action |
| --- | --- |
| Window-List-Manager.exe | Start the latest tool version from Lib. |
| Install-Chrome-Extension.exe | Prepare the local Chrome extension and open its installation page. |
| Build-EXE.exe | Rebuild all three executable entry points. |

The EXE entries run helpers from Library. Keep Library and Lib beside them.
Window-List-Manager.ahk remains the main editable launcher source and is compiled
into Window-List-Manager.exe. Other AHK and PowerShell files are implementation
or helper sources.

One-time migration: after syncing, run **Library\Build-EXE.cmd** once on Windows.
It generates the three EXE entries in the main folder. This requires AutoHotkey v2
and Ahk2Exe. Afterward use the EXE entries only. The old CMD launchers are retained
in Library as build/recovery helpers.

Verify the generated entries on Windows without starting operations:

```powershell
& '.\Window-List-Manager.exe' --check
& '.\Install-Chrome-Extension.exe' --check
& '.\Build-EXE.exe' --check
```

Each should exit with code 0. The build runs these checks automatically.
The EXE creation and Windows execution must still be performed on Windows.

## Plain Chrome windows

Extension v0.1.3 tracks both normal Chrome windows and popup windows without an
address/tab bar. After updating, run Install-Chrome-Extension.exe again, then
Reload Window List Manager Domains at chrome://extensions/. Activate or navigate
the plain window to refresh its domain. Install/load the extension in the same
Chrome profile used to open that window. No address-bar or clipboard access is used.

## Default font color

Options → Default Font Color opens a color picker for rows without a saved domain
or program color. The initial default is light grey (#D0D0D0). Reset to Grey restores
it. Changes apply immediately and persist in Panel/DefaultFontColor in the INI.
Explicit domain rules (including parent inheritance) and then program rules override
the default. Automatic green, Max blue and GPT purple fallbacks are replaced by this
single configurable default. Title-strip and close-button text stay white.

## Active window and Recent ordering

The active external window has a blue row background, including while the panel
is unfocused. Domain/program text colors remain unchanged. Single-click restores and raises the target without changing foreground focus,
active highlighting, Recent history or size.
Double-click additionally applies optional focus sizing. Recent ordering stays
stable after a list double-click until focus switches to a different external
window. The deferred target is then recorded before the newly focused window.

## Per-application focus sizing

In Options, select an application in the upper list, then enable **Selected app:
resize on activation; restore on blur**. It is off by default and saved per EXE
name. Double-click a window in the manager to apply the temporary size.

- Landscape monitor: 50% of the available width and 100% height, on its original left/right side.
- Portrait monitor: 100% of the available width and 50% height, on its original top/bottom side.
- Monitor work areas exclude the taskbar and reserved panels.
- When another window gains focus, restore the saved outer position and size without minimizing or activating it.
- Owned modal dialogs retain the temporary size. Closing the manager or disabling the app option also restores it.

The saved rectangle is session-only. Windows activated outside the list are not
automatically resized. Test with disposable windows first using the AHK test suite;
monitor layouts and individual applications' minimum sizes require Windows verification.

## Version format

Tool versions use one decimal point and exactly three fractional digits:
`0.236`, `0.237`, `0.238`. Increment by `0.001` for each new release.
The current implementation is `Lib/Window-List-Manager-0.243.ahk` (formerly
`0.22.0`). Older dotted filenames remain historical versions. The launcher
selects the current format correctly without an EXE rebuild.

## Domain color picker cells

In Options, each domain has a colored **Choose...** cell instead of a hexadecimal
code. Click that cell to open the Windows color picker for that domain. The swatch
shows the effective color, including inherited domain rules or the program/default
fallback. Cancel leaves the existing rule unchanged. Reset Domain Color removes
the explicit rule. The Assign Color to Domain button remains available for keyboard use.

## Application color picker cells (v0.242)

The Application list in Options now uses a colored **Choose...** cell in its
third column, matching the domain color picker behavior. Click the swatch to
choose the application font color; clicking the application name or priority
does not open the picker. The swatch displays the application's saved color or
the configured default font color when no application override exists.
The separate **Assign Color to Program** and **Reset Program Color** buttons
remain available. Changes are saved immediately, and resetting the color
restores the default swatch. Chrome domain overrides still take precedence
over the application color in the main window list.

## Tray controls and dark Options

The tray context menu contains **Open UI**, **Restart script** and **Exit**. Left-click
the tray icon to minimize the list manager to the tray; click again to restore it.
Hiding releases reserved monitor space and restoring reapplies it. Panel dimensions
are retained. Restart script runs the root launcher so the latest Lib implementation
is selected. Exit and the title-strip close button close the tool, save its position, restore any temporarily resized window and release reserved monitor space.

Options push buttons use a custom dark appearance; checkboxes, sort dropdown and
its popup list receive dark colors. Domain swatch colors and the default-font
preview retain their own selected colors.

Tray restoration operates directly on the GUI object and works with hidden-window
detection disabled. Minimization is checked with native IsIconic, so a hidden panel
is not searched by window-title criteria before it is shown.


## Domain focus sizing

In Options, each Chrome domain has a **Resize on focus** checkbox beside its color
picker. Click the checkbox cell, or select the row and press Space. The setting
is saved immediately and uses the same temporary size and restore-on-blur behavior
as the application option, after double-clicking a window in the manager.

Domain settings apply to subdomains; the closest explicit rule wins. An unchecked
domain explicitly disables sizing even if Chrome's application option is enabled.
Without a domain rule, Chrome uses its application setting. Disabling the effective
rule restores a currently resized window. Color and sizing settings are independent.

From v0.243, double-click activation uses the Chrome domain already associated
with that window's list row for its sizing rule. This avoids losing a domain-only
resize setting when a second bridge lookup temporarily cannot match the window.
New windows without a listed domain still use the live Chrome lookup and the
application fallback. Activation outside the list remains unchanged.

Restart safety: Shell callbacks ignore an unassigned, destroyed or unrelated manager GUI. Exit unregisters Shell message handlers before saving geometry and releasing reserved space.

Priorities support arbitrarily long positive whole numbers. Both Options and the right-click App Priority action save the full value; sorting compares all digits exactly. Zero, negative values and fractions are rejected.

Single-click uses non-activating window restoration and z-order changes. Clicking the list itself does not steal focus. Double-click remains the action for switching keyboard focus to the target.

Single-click brings the target visibly in front of other applications, including Always on Top windows, while the original application retains keyboard focus. This is a temporary topmost preview. Its original topmost setting returns on a focus change, another preview, double-click, or exit. The manager panel stays above the preview when its own Always on Top setting is enabled.

List refresh waits through the Windows double-click interval after a single click, so raising a preview cannot rebuild the list between clicks and interrupt double-click activation/expansion. Expansion still requires Resize on focus to be enabled for the application or domain.

## Chrome history — v0.232 / extension 0.1.3

The existing Window List Manager Domains extension is used; Chome-Window-Grid is separate.
Manager 0.233 additionally releases all history Options controls when that dialog
closes, so header sorting remains safe after repeated Options open/close cycles.
Manager 0.234 fixes the Chrome history right-click menu's AutoHotkey v2
case-insensitive variable collision (`menu` versus the built-in `Menu` class).
Manager 0.235 checks that the original Chrome extension profile is connected
before queuing a history URL. If unavailable (including after profile reinstall),
the URL opens through the system default browser. If the extension does not
acknowledge a queued URL within 12 seconds, the manager cancels the pending
request and opens the URL through the default browser instead.
Manager 0.236 replaces that command route for history opening: the saved URL
launches directly in a new Chrome window with `--new-window`, regardless of
the Windows default browser or extension connection. The newly detected Chrome
window is centered in the work area of the monitor containing Window List
Manager, retaining its normal dimensions when they fit the display.
**0.236 is the stable baseline.** Manager 0.237 fixes history URLs remaining
visible immediately after reopening: a queued launch hides its URL at once,
then the new Chrome HWND keeps it hidden while that window exists. This works
without a matching extension snapshot; closing the reopened window makes its
saved history entry visible again.
Manager 0.238 fixes an Options teardown error: native notifications can arrive
while the domain ListView is being destroyed. Its references are now cleared
before destroying the dialog, and native callbacks ignore destroyed controls.
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
When a saved URL is already open as the active page of a listed Chrome window,
it is hidden from the lower history list; it remains saved and becomes visible
again when no listed live window shows that URL. Double-click or right-click >
Open URL starts a new Chrome window centered on the manager's display. Chrome
chooses its current/default profile; the original history profile is not forced.
Incognito pages are excluded.

Update: sync all files, run **Install-Chrome-Extension.exe** again, open
chrome://extensions/ and Reload Window List Manager Domains in each used profile.
Restart Window-List-Manager.exe. No main launcher EXE rebuild is required.
The extension now polls the local API every two seconds while connected, so domain
colors initialize without needing a Chrome window activation. A domain-only cache
(no full URLs) supplies initial hints; fresh snapshots replace them. Native row
repaint occurs explicitly after color maps are computed, including the first paint.

The extension/API bridge and Library/Chrome-History.ahk remain separate modules.
The API carries versioned snapshots through loopback; old profile-targeted
commands remain supported for compatibility but the manager no longer uses them
to open history URLs. Old domain-only snapshots still support live grouping/colors;
collecting new URL history requires extension 0.1.3. Do not remove the Library/Chrome-History.ahk module.

Verification: Node protocol/transfer tests and static AHK inspection ran outside
Windows. Run Tests/Window-List-Manager-Test.ahk (including Chrome-History-Cases.ahk)
and Tests/Chrome-Domain-Bridge-Test.ps1 on Windows for GUI, persistence, work-area and
real local API integration checks. Windows/Chrome execution and EXE compilation
have not been verified in this environment.
