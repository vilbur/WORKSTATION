# Keyboard Manager — version history

## Win+Y action update — 2026-11-01 (v0.34 resident unchanged)

- The independent `actions/YouTube/YouTube.ahk` action now opens `https://www.youtube.com/` with Chrome's `--new-window` option on every `Win+Y` press, never activating an existing YouTube window or tab.
- Chrome launch failure produces a tray warning; it no longer falls back to a different browser.
- Updated the UI catalogue description, action reference and regression tests. The resident launcher itself is unchanged, so this action edit takes effect on the next press without rebuilding the EXE or restarting the resident.


## v0.34 — one isolated launch file per action

- Kept all **21 resident shortcuts** and action event reporting, but the root AHK resident now dispatches each shortcut to its own `actions/<Action>/<Action>.ahk` file via an explicit AutoHotkey v1 interpreter.
- Extracted all seven built-in actions (including text transformation algorithms, Chrome/YouTube/Total Commander and IrfanView) into standalone launch files; only reusable helpers stay under `src`.
- Added fourteen local Toolkit wrapper files. Each wrapper declares its original external target, retains configured override/Browse precedence, and calls the existing external tool rather than copying it.
- An action file can be edited independently and is reloaded on its next shortcut press. Missing/failed child launch is reported in the tray without ending the resident process.
- Preserved IrfanView window-cycle state between separate action processes via a temporary INI file, without adding project sync noise.
- Added `tests/Keyboard-Setup-Actions.Tests.js` and updated the resident, hotkey and Toolkit source tests to match the relocated action code. The UI remains v0.32; the source resident tooltip reads v0.34. Compiled EXE rebuild and live Windows validation remain necessary.
- The Windows build now validates all 21 action paths from the resident's mapping before compiling, so a partially synced `actions/` directory is diagnosed. The Toolkit helper keeps a legacy one-argument fallback during staggered Drive updates.


This file preserves the release notes previously stored in `README.md`. Newest versions appear first in the summary; the historical entries below retain their original wording (including older design decisions that may have been superseded).

## v0.32 — navigation header and arrow-block geometry

- Aligned Print Screen, Scroll Lock and Pause directly above Insert, Home and Page Up.
- Kept approximately half a standard key of space on either side of the navigation/arrow-key cluster, between the typing block and numpad.
- No changes to shortcuts, key colours or resident launcher. Reopen the main HTA after syncing the update.

## v0.31 — keyboard row alignment and Print Screen placement

- Aligned the right edges of the five typing rows with Enter by adjusting Backspace, backslash, right Shift and right Ctrl.
- Positioned the Print Screen key caption at the bottom-left of its keycap.
- Kept resident hotkeys and the other keyboard layout elements unchanged.

---

## Archived original release notes (v0.16–v0.30)

## v0.16 — strict single-instance lifecycle

- **One resident process in the Windows user session:** the root `Keyboard-Setup-Launcher.ahk` and a *newly rebuilt* `Keyboard-Setup-Launcher.exe` share the same Win32 named mutex (`Local\KeyboardSetup_Resident_8A2DE942`). The lock is acquired before tray/hotkey initialization, lives with the resident process and is released automatically on exit. A duplicate exits silently; if a Keyboard Manager UI is open, it is restored and activated. No process is killed or force-replaced.
- **One main editor and one independent Hotkey Index:** each HTA has `SINGLEINSTANCE=yes` and a stable distinct `APPLICATIONNAME`. Tray menu actions both use a single AHK open/restore/launch controller, which finds an existing `mshta.exe` HTA window (with a native HTA class fallback), tracks pending launch PIDs, and debounces the initial handoff. Repeated clicks never intentionally start a second window of the same type. Navigation between the two HTAs also tries `WScript.Shell.AppActivate` first.
- **Activation:** close old versions in the tray, then run the updated root `.ahk` with AutoHotkey v1.1. The old pre-rebuild `.exe` is **not** protected by new source changes until `build/Build-Keyboard-Setup.cmd` recompiles it on Windows. Native Win11/mshta behaviour still needs on-machine verification.


## v0.17 — imported AutoHotkey Toolkit actions (14 hotkeys)

These assignments were transcribed from the user's AutoHotkey Toolkit screenshot. They are **active resident hotkeys** after the root AHK launcher is restarted, not design-only chords. They execute the original external script/batch file without copying the files into Keyboard Manager. Source paths are defaults only: if a file has moved, the first use prompts Browse and saves the new location to `config/Keyboard-Setup-Toolkit-Paths.ini`. A `FILE TO RUN` override in the editor has first priority. AHK scripts run with an AutoHotkey v1 interpreter; compiled launcher mode locates or asks for v1 separately. The original Toolkit must release its bindings to avoid two resident applications competing for the same hotkeys.

| Hotkey | Action | Default executed file |
|---|---|---|
| `Win+F` | FocusMe window toggle | `C:\GoogleDrive\ProgramsData\Core\FocusMe\Ahk\Focusme-Window-Toggle.ahk` |
| `Ctrl+Win+N` | Open clipboard file in Notepad++ | `C:\GoogleDrive\ProgramsData\Core\Notepad++\AHK\Open-specific-file-types-from-clipboard-in-Notepad.ahk` |
| `Ctrl+Win+F4` | Kill all active-window processes | `C:\GoogleDrive\ProgramsData\Core\Windows\_AhkScripts\kill-ALL-PROCESESES-of-active-window.ahk` |
| `Win+Space` | ChatGPT dictate mode | `C:\GoogleDrive\ProgramsData\Core\ChatGPT\ahk\run-chat-and-start-or-stop-dictate-mode.ahk` |
| `Shift+Win+H` | Open hotstrings file | `C:\GoogleDrive\ProgramsData\Core\AutoHotkey\Hotstrings\open-hotstrings-file.ahk` |
| `Win+T` | Total Commander activate | `D:\GoogleDrive\TotalCommander\_TC-commands\TC-Acivate.ahk` |
| `Win+F4` | Kill active-window process | `C:\GoogleDrive\ProgramsData\Core\Windows\_AhkScripts\kill-process-of-active-window.ahk` |
| `Ctrl+Win+H` | Hibernate Windows | `C:\GoogleDrive\ProgramsData\Core\Windows\_AhkScripts\Hibernate-Windows.bat` |
| `Win+Pause` | Mute launcher | `M:\MediaMonkey\Ahk\Mute-Temporary\Mute-Launcher.ahk` |
| `Win+M` | Suspend key (no action) | `C:\GoogleDrive\ProgramsData\Core\AutoHotkey\Lib\Window\SuspendKey-DoNothing.ahk` |
| `Ctrl+Shift+Win+F` | FocusMe window toggle | `C:\GoogleDrive\ProgramsData\Core\FocusMe\Ahk\Focusme-Window-Toggle.ahk` |
| `Ctrl+Win+C` | Go to path | `D:\GoogleDrive\TotalCommander\_TC-commands\file\go_to_path.ahk` |
| `Win+Enter` | Activate MediaMonkey | `M:\MediaMonkey\Ahk\Activate-mediamonkey.ahk` |
| `Win+R` | Run MAXScript from editor | `C:\Users\vilbur\AppData\Local\ActiveState\KomodoIDE\12.0\tools\Scripts\3Ds Max\runMaxScript\run-maxscript-via-notepad-komodo.ahk` |

The three supplied scripts establish additional, specific behaviour: **Mute launcher** calls a sibling `mute.ahk` with 30,000 ms initially or 120,000 ms for a rapid second launch; that sibling dependency was not attached, so keep the original directory. **Run MAXScript from editor** reads Notepad++ or Komodo editor titles and sends `fileIn` via `MXS_Scintilla2` in 3ds Max; those applications and listener must be available. **Kill all active-window processes** requests confirmation, terminates processes sharing the captured process name, and attempts an elevated restart only for 3ds Max after resolving its executable. Other external actions have only the behaviour suggested by their filenames until their source files are inspected.

These chords override Windows shortcuts such as Win+R, Win+Space, Win+M and Win+T while the new resident hotkeys are active. Both `Ctrl+Win+F4` and `Win+F4` are potentially destructive. The confirmation for the supplied kill-all script remains in that original script; do not remove it.

Smoke test: `node tests\Keyboard-Setup-Toolkit.Tests.js` plus the existing five JS suites. Native Windows AHK/HTA and external-script execution remain to be verified. The EXE on Drive predates v0.17 and must be rebuilt on Windows.

Since v0.20, the 14 Toolkit imports are listed inside the single **Windows** program source alongside built-in resident actions and Windows defaults.

### v0.17 launcher hotfix — AutoHotkey v1 comment compatibility

A previous source update used inline C-style block comments, e.g. `/* explanation */`, and multi-line comment markers with text on the same line. **AutoHotkey v1 requires `/*` and `*/` as standalone lines** for this comment form. The malformed comments hid the `keyboardFindUiWindow()` and other functions from the interpreter, causing `Call to nonexistent function`, and also hid some imported Toolkit hotkeys. Both `Keyboard-Setup-Launcher.ahk` and `src/Keyboard-Setup-Toolkit-Actions.ahk` now use proper AHK `;` line comments in those places; no hotkey/action execution logic was changed. The resident-source test now scans all four AHK source modules for malformed block comments and checks that the UI helpers, IrfanView functions, Toolkit functions and all 14 Toolkit trigger declarations remain visible. Run `node tests\Keyboard-Setup-Resident.Tests.js`. The still-old EXE must be rebuilt on Windows.


## v0.18 — live shortcut action monitor

The keyboard canvas has a centred display below the keyboard illustration, occupying its previously unused bottom area. When an assigned key combination is pressed, the display shows the shortcut, action name and short description from the active Source catalogue. No extra UI windows appear; the notification persists until the next recognised shortcut.

- **Global AHK:** the resident AHK v1 launcher writes the last registered activation to a small user-local `%TEMP%\KeyboardSetupActionEvent.txt` file using atomic replacement. The open HTA polls it about every 300 ms without stealing focus. Both seven built-in and fourteen Toolkit hotkeys publish an event before the original action executes. The file contains only the key combination and a short serial, no clipboard text or passwords. Opening the UI skips an old event.
- **While the editor has focus:** keydown previews matched shortcuts in Global AHK or 3ds Max Factory/Effective. If multiple Max actions share the chord in different contexts, show the ambiguity instead of claiming that a particular action ran.
- **3ds Max:** the imported Max source selector shows read-only references. Keyboard Manager does not monitor shortcut execution in the 3ds Max viewport when that application has focus.
- **Overrides and editing:** the panel uses the selected source and shows a configured file override where present. Unassigned chords leave the last action unchanged. No shortcut action behaviour is changed.

Exit and restart the resident root `Keyboard-Setup-Launcher.ahk` with AutoHotkey v1.1 for global action reporting. The old compiled EXE still requires rebuilding. Reopen the main HTA to use the new bottom display. Live Windows behaviour is pending on-machine verification.


## v0.19 — merged shortcut sources

**3ds Max** is now one source in the main keyboard editor and in the standalone Hotkey Index. Factory assignments from `Default.hsxb` are loaded first. User `.hsx` removals and assignments are then applied; the resulting reference retains *Default* assignments not removed and labels the overriding/new entries *User defined*. The supplied snapshot includes 532 factory entries and 575 merged active reference entries. Contexts remain distinct: the same chord may legitimately invoke separate actions under different Max Action Tables/contexts. The Edit Poly and exported context/category filters still apply. Importing either the factory or user file returns to the single 3ds Max view; the source dropdown no longer has two Max choices.

**Windows + PowerKeys / AHK** was introduced as a combined *reference* source in v0.19. It includes 50 commonly used Windows 11 shortcuts from [Microsoft's Windows shortcut reference](https://support.microsoft.com/en-us/accessibility/windows/keyboard-shortcuts-in-windows) alongside the **21 currently registered Keyboard Manager / AutoHotkey Toolkit resident hotkeys**. It does not register new shortcuts and does not inspect the entire Windows hotkey registry. When a resident hotkey uses a Windows chord (for example, `Win+I`, `Win+R`, `Win+G`, `Win+T` or `Win+Space`), its *User defined* action replaces the Windows *Default* row in the combined display; the original Windows behaviour is preserved in that action's details. Other Windows rows remain labelled *Default*. A separate **PowerKeys** application/configuration source has **not** been supplied or imported; the PowerKeys/AHK name here refers only to existing resident shortcuts until a separate PowerKeys data source becomes available.

In v0.19, the index displayed the combined Windows+resident view by default and the editor also offered a separate resident-only source. Since v0.20 these are consolidated into **Windows** and **3ds Max**, and existing resident actions remain editable. Imported Windows/Max defaults are reference-only; changing source does not modify active global hotkeys. AHK `.exe`/`.ahk` launcher and the tray process remain unchanged by this data/UI update. Open/reopen the HTAs to see it; no EXE rebuild is needed.


## v0.20 — one program list and tray Exit cleanup

- **Windows** is one effective list: Windows defaults and all 21 resident PowerKeys / AHK actions (including the 14 Toolkit imports), yielding **60 currently effective reference entries**. User defined shortcuts override Windows defaults; modifier-order equivalents such as Ctrl+Win+F4 and Win+Ctrl+F4 are treated as one shortcut. There is no separate Global AHK or Toolkit profile. The 21 resident actions retain file target editing; Windows default entries are read-only. New non-Windows shortcut chords remain preview-only, not newly registered AHK hotkeys.
- **3ds Max** is one read-only effective list: factory defaults with the user's HSX overlay applied. Entries are labelled **Default** or **User defined** and retain Action Table / Context filtering.
- The standard AutoHotkey tray menu's **Exit** now runs an `OnExit()` callback (registered only after the named resident mutex is acquired). The callback closes the Keyboard Setup editor and Hotkey Index, allowing up to one second each for a graceful shutdown before forcing a stuck, explicitly verified HTA window closed. It does not terminate unrelated `mshta.exe` windows. Closing an individual UI window still leaves the resident running.
- AutoHotkey v1 launcher changes require a resident restart; the existing EXE must be rebuilt on Windows using `build\Build-Keyboard-Setup.cmd`. Runtime Windows validation is still pending.


## v0.21 — visible Windows shortcut override notes

Windows and PowerKeys/AHK share one effective shortcut list. When a resident
PowerKeys/AHK shortcut matches a Windows default, the **custom action** remains
the sole displayed effective action. The original Windows command is identified
in an **Overrides Windows default: [action]** note in the Hotkey Index row,
selected action details, main editor, assigned-shortcut overview and the
bottom action monitor.

Native Windows shortcuts are not re-fired by the keyboard manager: its resident
AutoHotkey v1 hotkeys do **not** use the pass-through (`~`) prefix. Only the
user-defined action is executed when AHK successfully captures the chord.
Windows-reserved combinations and shortcuts handled at higher privilege may not
be interceptable in every environment; the UI must not claim that Windows
itself has been disabled. Windows defaults without a matching resident binding
remain untouched and are only displayed as read-only references.

Regression check: `node tests\Keyboard-Setup-Index.Tests.js` and
`node tests\Keyboard-Setup-UI.Tests.js`.


## v0.22 — strict modifier RGB system

Modifier colours use one shared `data/Keyboard-Setup-Modifier-Colors.js` function in both HTAs. Ctrl enables red, Shift green and Win blue; Alt attenuates enabled channels by 65% (internal default `keyboard_modifier_alt_darkness = 0.65`). Enabled channels are FF normally, or 59 when Alt is held; disabled channels always remain 00. Alt only and no modifiers are both `#000000`, intentionally. The active modifier name and HEX chip distinguish these states without altering their RGB value.

Keys at rest retain their original dark keycap texture, with a 5px ribbon of calculated RGB colour. Keys with multiple shortcuts show equal-width, hard-edged bands in that ribbon of the distinct calculated colours (sorted solely for deterministic visual layout, never assigning priority). When modifiers are held or latched, compatible keys show the current combination's exact RGB colour. The index and editor use the same calculator for swatches and shortcut borders. Physical keydown, keyup, blur/reset, latch clicks and source changes already call the keyboard highlight updater, so colours follow state changes immediately. Preserves keyboard geometry and all existing runtime hotkeys. Only reopen the HTAs; no EXE rebuild.

Regression: `node tests/Keyboard-Setup-Modifier-RGB.Tests.js` checks the exact 16-state table, Alt darkness override, modifier order independence, press/release, latch/physical combination and the editor/index shared rendering.

## v0.23 — accumulated per-key RGB and original highlight style

The coloured 5 px ribbons and split multi-shortcut colour bands from v0.22 are removed. The keyboard returns to the earlier shaded **full-key** highlight: coloured border, tinted dark keycap gradient, and a strong coloured glow for shortcuts matching held modifiers. The selected-key styling and full-size keyboard layout are unchanged.

Colour is accumulated from the **union of every modifier across all assignments for a physical key in the selected program**, independent of binding order or modifier activation order. `Ctrl+G` and `Shift+G` on a key **G** therefore make its keycap yellow (`#FFFF00`), including while either compatible modifier is held. If another assignment uses `Win+G`, the union becomes white (`#FFFFFF`). When modifiers are held, only shortcuts compatible with those held modifiers are highlighted; an unrelated key is not highlighted.

**Modifier channels:** Ctrl = red, Shift = green, Win = blue, Alt = **white**. The shared `data/Keyboard-Setup-Modifier-Colors.js` calculator uses strict saturated additive RGB: Alt supplies red, green and blue, so Alt alone and **every combination that includes Alt** is `#FFFFFF`; no modifiers is `#000000`. An unmodified assigned key retains a neutral assigned-key border so it remains legible on the dark keyboard. Legend swatches, index shortcut swatches, accumulated key colours, and the live modifier HEX indicator use the common calculator.

Run `node tests\Keyboard-Setup-Modifier-RGB.Tests.js` for all 16 modifier states, all 65 activation orders, physical press/release, latching, accumulated multi-binding colour, assignment-order independence, and full-key glow. `node tests\Keyboard-Setup-UI.Tests.js` also checks the unchanged keyboard layout and shortcut editing. This is an HTA and shared JavaScript change; reopen both windows after Drive synchronises, and no resident AHK/EXE rebuild is required. Native Windows MSHTML execution still requires validation.


## v0.24 — compatibility fix for partially synced modifier modules

The main HTA now detects an unavailable or older `data/Keyboard-Setup-Modifier-Colors.js`
and installs a compatible inline RGB fallback before initialising the keyboard. This
prevents `keyboardModifierUnionColor is undefined` when Google Drive updates the
main UI before its shared JavaScript file. Both the shared module and fallback
retain Ctrl=red, Shift=green, Win=blue, Alt=white, and one accumulated modifier
colour per physical key. When the latest module is available, it remains the
primary implementation. Reopen the HTA after Drive sync; no launcher rebuild.


## v0.25 — softer modifier colours and full combination legend

Visual highlights use a muted palette derived from the original strict additive
RGB states. The stored/raw RGB values and modifier-union logic are unchanged.
The colour transform maps primary shades to softer reds/greens, shifts Win blue
towards sky blue, and uses a pale neutral white for Alt and all-white unions.
Selected keys still use the previous full-key textured shading, border and glow.
A compatible fallback inside the HTA keeps these display colours available while
Google Drive syncs the updated shared module. The Hotkey Index uses the same
muted colour transform for shortcut swatches.

The keyboard feedback strip now includes Ctrl, Shift, Win, Alt (+ any),
Ctrl+Shift, Ctrl+Win, Shift+Win, and Ctrl+Shift+Win swatches. Alt-containing
combinations share the same white shade, so redundant swatches are intentionally
omitted. The decorative **Match** legend item was removed. This does not
change match filtering or shortcut execution.

Test: `node tests\Keyboard-Setup-Modifier-RGB.Tests.js`; run the existing UI
and Index tests as part of the full suite. No EXE rebuild is needed.


### v0.26 — tray Restart and saturated keyboard accents

The resident AHK v1 tray adds **Restart** without opening a second resident. It
spawns the same script/interpreter (or the compiled EXE), then runs its usual
OnExit window cleanup. The new process waits for the old named mutex to be
released before registering any hotkeys. Rebuild the EXE on Windows after this
AHK change; the root `.ahk` can run directly with AutoHotkey v1.1.

The visual palette has stronger red, green, sky blue and combined accents. Raw
strict additive RGB remains unchanged for compatibility. Only the standalone
**Alt modifier key** (and Alt-only status/legend swatch) uses pure white. Alt
in a shortcut does not turn the associated ordinary physical key white: its
Ctrl/Shift/Win modifier union still sets the accent; Alt-only bindings keep
the neutral assigned border. The three-channel Ctrl+Shift+Win display mixture
is a saturated lavender rather than white. Existing key texture, key geometry,
shortcut registration, and one-source-per-program behaviour are preserved.


## v0.27 — exact modifier combination filtering

When the keyboard editor has one or more physically held or mouse-latched modifier
keys, display **only shortcuts assigned to that exact modifier set**, independent
of order. Ctrl shows Ctrl-only shortcuts; Ctrl+Win shows Ctrl+Win-only shortcuts,
not Ctrl, Win, Ctrl+Shift+Win or any other combination. The keyboard keycaps,
tooltips and four-row assignment overview all follow this same strict filter.
Keys without exact assignments lose assigned styling until a matching modifier
state is selected. All combinations still render their normal colour and glow.
When all modifiers are released/unlatched, restore the full effective shortcut
list with the accumulated all-assignment key colour. No registered Windows
hotkeys, keyboard geometry or separate index data are changed.

Tests: `node tests\Keyboard-Setup-UI.Tests.js` and
`node tests\Keyboard-Setup-Modifier-RGB.Tests.js` verify strict combination
matching, keyboard tooltips, single and paired modifier transitions, and
colour changes. Reopen the HTA after Google Drive sync; no EXE rebuild.


## v0.28 — typing-block key widths

Adjust only three keyboard keycaps without disturbing the existing rows or color logic:
Tab is reduced from 85 to 49 CSS px (roughly one standard key width);
Caps Lock from 85 to 67 CSS px (roughly half a standard key);
and right Ctrl from 85 to 68 CSS px to align its right edge with the
right Shift edge of the alpha typing block.

The three keys have distinct CSS classes so changing one does not resize
Backspace or left Shift. Layout and keyboard behavior are regression-tested.
No resident AHK/EXE change; reopen the HTA after sync.


## v0.29 — tray Restart and readable key tooltips

- The resident tray menu puts **Restart** in its own group after **Open Keyboard Setup** and **Hotkey Index**, retaining AutoHotkey's standard Exit command. The tray tooltip includes v0.29 to distinguish the current source from an older compiled EXE. Restart uses the existing single-instance mutex hand-off and closes the tool's two UI windows; no changes to registered hotkeys.
- The tooltip for each physical key now lists `Shortcut - Action` entries as separate paragraphs divided by a blank line (Windows `\r\n\r\n`), rather than ` | `. It retains the selected program and exact modifier-combination filter; with no modifiers held it lists all assignments for the key.
- Test using `node tests\Keyboard-Setup-UI.Tests.js`, `node tests\Keyboard-Setup-Modifier-RGB.Tests.js`, and `node tests\Keyboard-Setup-Resident.Tests.js`.
- To see the new tray menu, restart `Keyboard-Setup-Launcher.ahk` with AutoHotkey v1.1, or rebuild and start `Keyboard-Setup-Launcher.exe` with `build\Build-Keyboard-Setup.cmd`. An older EXE will continue showing its old tray menu until rebuilt. Native Windows testing remains pending.


## v0.30 — larger UI typography, modifier hints, explicit tray menu

- Increase all user-interface fonts by **2 CSS px** in the main HTA and Hotkey Index, including text in headers, sidebar, forms, labels, lists and action monitor. Physical keyboard labels, 150% zoom, keyboard key dimensions/positions, key textures and key row geometry remain unchanged.
- Expand modifier-colour markers in the information strip from **11 × 11** to **18 × 18 CSS px**, and corresponding markers in the Hotkey Index from **9 × 13** to **14 × 17**.
- Define the Windows notification-area menu explicitly: **Open Keyboard Setup**, **Hotkey Index**, **Restart**, **Exit**. The default left-click still opens the editor. Restart retains the single-instance mutex hand-off; Exit still closes both owned UIs. Removing the default AHK menu avoids ambiguity with standard menu entries; the built-in script editing/debugging commands are no longer added to this product-specific menu.
- **Important:** The running EXE is not regenerated by updating AHK source on Google Drive. To display Restart, EXIT the existing resident (or stop `Keyboard-Setup-Launcher.exe`), then run the updated `Keyboard-Setup-Launcher.ahk` under AutoHotkey **v1.1**. Alternatively rebuild `Keyboard-Setup-Launcher.exe` with `build\Build-Keyboard-Setup.cmd`, exit the old process and start the fresh EXE. If the tray tip does not say `Keyboard Setup v0.30`, you are still running old code. A separate direct HTA launch never changes an older resident tray menu.
- Regression tests: `node tests\Keyboard-Setup-UI.Tests.js`, `node tests\Keyboard-Setup-Index.Tests.js`, `node tests\Keyboard-Setup-Resident.Tests.js`, plus the other four JavaScript tests. Native Windows tray execution must be verified on the user's machine.
