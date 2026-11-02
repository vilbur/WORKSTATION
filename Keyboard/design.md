# Keyboard Setup

## v0.34 architecture: independent action processes

The root `Keyboard-Setup-Launcher.ahk` owns the cross-build mutex, tray/UI lifecycle, 3ds Max importer, 21 hotkey definitions, action event reporting, and a fixed map from canonical chords to `actions/<Action>/<Action>.ahk` files. Every key press launches the mapped file with an explicit AutoHotkey v1.1 interpreter. These child processes are independent: changing an action file takes effect on the next press and a syntax/runtime failure in one child cannot terminate the resident.

The seven previously built-in actions now contain their own behavior in named action files. Shared clipboard selection and window activation helpers live in `src/Keyboard-Setup-Action-Common.ahk`; the old `Keyboard-Setup-Core.ahk` is retained for compatibility only. The fourteen external-tool wrappers contain individual default target paths and use `src/Keyboard-Setup-Toolkit-Actions.ahk` for user override, Browse and explicit interpreter handling. The original external tools remain in their original locations.

No new shortcuts are auto-registered by editing HTA entries. The UI remains v0.32, while the resident source version is v0.34; compiled EXE builds must be rebuilt on Windows. State that previously lived in the resident (IrfanView's last active HWND) is persisted under `%TEMP%` to preserve cycling across child processes.


## Purpose

Create a Windows keyboard command manager using AutoHotkey. Its UI should make it straightforward to assign custom commands to keyboard shortcuts and should visually follow the user's keyboard layout. Organize each binding as an **input/trigger context** followed by an **execution/action context**.

## Hardware and platform

- Windows desktop. The user's PC baseline is Windows 10 Enterprise 22H2.
- Microsoft Wireless Comfort Keyboard 5050, standard full-size keyboard.
- Show English QWERTY legends only; do not add Czech key legends or a layout selector.
- AutoHotkey is the chosen automation tool. AutoHotkey v1 and v2 are installed. The existing `Keyboard-Assistant_0.11.ahk` is a working AutoHotkey v1 baseline; keep it intact and use v1 for this new project unless implementation review finds a blocker.
- Runnable utility location: `G:\CODEBASE\AHK\Utilities\Keyboard-Setup`.
- Design and planning documents: `Google Drive\Workstation\Keyboard`.

## Recommended implementation shape

- A standalone AutoHotkey v1 tray process stays resident and handles the seven resident hotkeys.
- An HTA settings window edits bindings and saves file targets for the seven resident hotkeys to a project-local INI file. Newly created shortcuts and changes to non-file actions remain a design preview.
- The keyboard canvas is the primary view, with a binding list available for quick review. The key-remapper view is retained in the design spike for comparison; the first implementation focuses on assigning commands to shortcut combinations, not replacing individual key outputs.
- Each binding is edited in two parts: input/trigger context (shortcut, active program, text/file selection) and execution/action context (search, case conversion, or another command).
- The launcher begins with Windows after its first run by creating a shortcut in the current user's Startup folder; shortcut enable/disable UI remains future work.
- Starting the taskbar launcher starts the resident tool, without opening the HTA. Left-clicking its notification-area tray icon opens or activates the HTA; right-clicking retains AutoHotkey's standard tray menu with an added Open Keyboard Setup item. Closing the HTA leaves the resident process running.

## Browser and window commands

- **Win+G:** If text is selected, search it with Google in Chrome. Otherwise activate the next Chrome window in a stable cycle, or open Chrome if none is running. The former Total Commander Drive-item search is removed from this shortcut.
- **Win+Y:** Always launch a new Google Chrome window using `chrome.exe --new-window "https://www.youtube.com/"`, without looking for or activating existing YouTube windows or tabs. Show a tray warning if Chrome cannot be launched.
- **Win+C:** Cycle visible Total Commander windows (class `TTOTAL_CMD`) in stable window-handle order. If none exists, try to launch `TOTALCMD64.EXE`, then `TOTALCMD.EXE`.

## Text commands

### Ctrl+U: cycle uppercase, lowercase and Capital

- Apply to selected text.
- `UPPERCASE` -> `lowercase` -> `Capital` -> `UPPERCASE`. Mixed styles convert to uppercase.
- Text without letters stays unchanged.

### Ctrl+Shift+U: cycle naming convention

- Apply to selected text; when there is no selection, use the word under the cursor, following the supplied Komodo macro behavior.
- Detect the current convention and convert to the next convention, replacing the selected string.
- Cycle order: `lowercase` -> `Capital` -> `UPPERCASE` -> `PascalCase` -> `camelCase` -> `snake_case_low` -> `Snake_Case_Capital` -> `SNAKE_CASE_UPPER` -> `lowercase`.
- If the input convention is not recognized, start at `lowercase`.
- Preserve line breaks; conversion operates on words and uses spaces, underscores, or no separator according to the destination convention.
- The supplied JavaScript is a Komodo macro and depends on Komodo APIs (`ko`, `scimoz`, clipboard commands). Treat its conversion rules as the behavioral reference; the global AutoHotkey command needs a compatible implementation and must not execute the Komodo-only API calls.

### Ctrl+double quote: wrap / unwrap

- Use the English QWERTY apostrophe key with Ctrl+Shift (`^+SC028` in AutoHotkey v1).
- If the selected text has matching outer double quotes, remove those two characters; otherwise wrap the exact selected text in double quotes.

## UI design options

The HTA spike presents three alternatives:

- **Keyboard canvas:** select a key on a full-size keyboard illustration and configure its shortcut/action in a side panel.
- **Binding list:** manage shortcuts in a compact table, with an edit action for each row.
- **Key remapper:** map a physical key or shortcut to an output/command, with room for profiles.
- The v0.05 prototype lists all six requested shortcuts; actual execution lives in `Keyboard-Setup-Launcher.ahk` with pure helpers in `Keyboard-Setup-Core.ahk`.
- Shortcut editor includes a file path input and Browse button. Nonempty file paths saved for the six resident shortcuts override their built-in commands at runtime. The generated UTF-16 `Keyboard-Setup-File-Bindings.ini` lives alongside the HTA and executable.
- Source switch: Global AHK, 3ds Max effective, or 3ds Max factory. The bundled `Default.hsxb` contains 532 real factory `<MaxHotkeys><Hotkey ...>` definitions despite its binary-looking extension; `Keyboard-Setup-Max-Defaults.js` is a read-only import of them. The bundled `vilbur.hsx` XML contains 90 assignments and 55 removals. Its transformations are merged by action Id + Shortcut, retaining distinct application contexts and annotating effective entries as Default or Custom.
- The factory plus the overlay currently produces 575 effective assignments. Of 55 removals, 47 matched entries in the factory file; eight target entries absent from this source and remain preserved as removal records.
- The editor can browse both `.hsxb` factory and `.hsx` customization XML files through MSXML and recalculate the layered result. It never registers imported 3ds Max shortcuts as global AutoHotkey hotkeys.
- The v0.06 dedicated 3ds Max importer is an isolated `import/3DsMax` module (HTA JS, AHK v1 runtime, MAXScript exporter). It discovers the newest `Program Files\Autodesk\3ds Max YYYY\3dsmax.exe`, then `UI_LN\CUI\Default.hsxb`, and a matching `.hsx` in `%LOCALAPPDATA%\Autodesk\3dsMax\YYYY - 64bit\ENU\en-US\UI\Workspaces\usersave`. Every detected source requires confirmation; missing sources allow Browse.
- After import, the HTA queues an explicit request consumed by the resident AHK launcher. For an already running matching 3ds Max process, AHK sends `fileIn` directly to a `MXS_Scintilla` mini-listener control, without restarting, closing, or modifying the scene. Otherwise AHK installs a unique temporary `.ms` in the corresponding user startup directory, launches the version, waits for export, cleans up the temporary script, and closes *only* the process it launched. Timeouts never force-kill Max.
- The read-only MAXScript scans `actionMan.numActionTables`, each table's `numActionItems`, and extracts Action Table ID, Action Item ID, Category, Description, table name and context. Exported TSV columns are merged by ID into factory/effective references; unsigned HSXB table IDs above 2^31-1 normalize to signed ActionMan IDs. Named macro action IDs may remain unclassified until a separate resolver is provided.
- Version 0.06 also uses flat 32px keyboard key styling as requested. Live Windows HTA and MaxScript runtime execution remain unverified. The resident `.exe` must be rebuilt on Windows for AHK changes. Any one-shot Max startup script must be generated, used, and removed only for the matching running import request.

The keyboard canvas is the recommended primary view because the user asked for the UI to follow the keyboard layout. Keep the binding list as an alternate view. Provide a keyboard-only scale control from 100% through 200%, defaulting to 150%. The keyboard illustration uses English QWERTY legends.

The v0.02 HTA dialog is fixed at 2048 × 838 outer pixels with resizing/maximize disabled. The keyboard card keeps a 1444 × 592-pixel footprint; its scrollable keyboard viewport is 375 pixels tall. These dimensions follow the user's supplied reference screenshot, while keyboard zoom still ranges from 100% to 200% inside the fixed section.

Physical layout corrections: open the keyboard at 150% scale. Place Insert/Home/Page Up and Delete/End/Page Down in a three-column, two-row navigation block; center Up above Down and align the navigation block's right edge. Make the main Enter and numpad Return keys one key wide and two key rows tall. Let Space expand to use the available bottom-row width. Show a tab-arrow icon on the right Windows key while keeping it associated with the Win modifier.

### Interactive keyboard behavior

- Track physical Ctrl, Shift, Alt, and Win keydown/keyup while the HTA has focus.
- Modifier keys on the on-screen keyboard can also be clicked to latch or unlatch them. This gives Win a usable mouse fallback if Windows intercepts the physical key.
- Always mark keys with assigned shortcuts. While modifiers are active, highlight only shortcuts that include every active modifier; shortcuts may also require additional modifiers. For example, Ctrl highlights Ctrl+U and Ctrl+Shift+U, but not Win+G. Keep the stronger match glow for these compatible keys.
- When no modifier is active, color each unselected assigned key by the highest modifier count among its bindings: 1 green, 2 blue, 3 orange, 4 red. A selected key keeps its selection color; shortcuts compatible with active modifiers use the stronger match glow.
- Clicking a non-modifier key opens the editor with the active modifier combination. If that exact shortcut exists, edit it; otherwise, prepare a new binding.
- Keep a live assigned-shortcuts overview beside the keyboard. Clicking an overview entry opens that binding for editing and selects its key on the layout.
- Saving a resident shortcut's file target updates `Keyboard-Setup-File-Bindings.ini`. Other edited attributes and newly added chords still affect only the preview, and are not registered at runtime.

The controls use ASCII labels and the HTA declares UTF-8 so tab/control labels render reliably.

## Remaining work

- Only file targets for seven resident shortcuts persist and execute; other binding attributes are not yet synchronized with runtime.
- The resident AHK v1 source registers all seven hotkeys, but the compiled EXE must be rebuilt on Windows. Live Windows interaction testing and application-specific shortcut conflict detection remain outstanding.
- 3ds Max import remains read-only and for shortcut discovery; if a future 3ds Max version stores further defaults in additional files, those would need additional import sources.

## Decisions to document next

- Choose between shortcut commands only and remapping individual keys as well.
- Confirm the preferred interface among keyboard canvas, binding list, and key remapper.
- Confirm whether the user wants any additional scale steps beyond the 100%-200% range.
- Confirm whether the recommended shortcut-manager design and standalone AHK v1 + HTA structure are acceptable.
- Add a UI control for managing the already enabled start-with-Windows behavior, and set hotkey enabled/disabled defaults when the runtime is implemented.
- Test Win+G against the Windows Game Bar shortcut, Win+Y against any Windows shortcut conflicts, and the Ctrl+U combinations against application-specific shortcuts; expose conflicts clearly in the UI.


### v0.07 window sizing and catalogue paging

The previous 2048 x 838 layout produced unwanted scrollbars once the 3ds Max
importer and imported shortcut catalogue were included. The new HTA opens
with a 2220 x 1050 window where the monitor allows it; on a smaller monitor it
scales the fixed-width shell to the available work area. The keyboard section
remains 1444 x 592, with minimal stage padding to fit the default 150% zoom
without visible bars. Explicit keyboard zoom >150% may scroll. The right
editor is wider/taller (470 x 820) and no longer scrolls; instead, the
assigned shortcut list provides search and four-entry pages with Prev/Next.
The 3ds Max importer dialog widens to 1010 px (max 94% of the viewport).
No changes to runtime hotkeys or MaxScript export logic.

## v0.08: preserve layout, repair tray and numpad

- Keep v0.07 full-size layout and no-scroll fit logic unchanged, with shaded original key texture reintroduced while preserving 32 px normal key size.
- Move only arrow cluster down exactly one 37 px key pitch; numpad `+` spans rows 7/4, `Return` continues spanning rows 1/0, and `0` spans two columns.
- Resident launcher scans existing `mshta.exe` windows for versioned or legacy `Keyboard Setup` titles and activates/restores the existing window. Debounce rapid opens and use `#SingleInstance Force`. Requires recompiling EXE and closing the old launcher; HTA-only edits do not update compiled launcher.
- Native Windows runtime behaviour still requires verification.


### v0.09 keyboard geometry

Preserve the v0.08 shaded keys and established physical positions. Main Enter is
2x1 horizontal, right-aligned with an extended right Shift; Esc is 1x1. The arrow
Left/Down/Right row aligns with Space (Up above). PrntScrn / ScrLK / Pause occupy
a separate aligned header row immediately above Ins / Home / PgUp.
Existing numpad + (2 rows) and numpad 0 (2 columns) are unchanged.

## v0.10 — lifecycle and action reference

- Do not start another resident when any copy of the tool (interpreted AHK v1
  or compiled EXE) owns `Local\KeyboardSetup_Resident_8A2DE942`. The OS mutex is
  process-scoped, released automatically on process exit, and guards all tray
  and timer initialisation. Duplicate launches may activate the running HTA.
- Keep `HTA:APPLICATION SINGLEINSTANCE=yes` and a stable application name. Tray
  clicks search for an existing HTA window before launching; track a pending
  `mshta.exe` PID to avoid racing initial window creation.
- Show short help immediately under the Action dropdown, updating on change or
  when editing a saved preview shortcut. Imported 3ds Max references show a
  read-only explanation.
- `README.md` is the human-facing reference for actions, with complete
  subaction / fallback flows, importer steps and current preview limitations.
- UI keyboard geometry/texture remains exactly as in v0.09.


### Repository cleanup (post v0.10)

Root contains only the primary runnable `Keyboard-Setup-Launcher.exe` and `Keyboard-Setup-Design-Options.hta`, plus `README.md` and `design.md`. Move AHK sources to `src/`, JS snapshots to `data/`, icons to `assets/`, build and diagnostic scripts to `build/`, old launcher reference text to `docs/`, preserve `import/3DsMax/` and `tests/`. GUI loads snapshots using `data/` relative paths; both compiled launcher and interpreted source resolve the same project root; build script compiles `src/` source to root EXE, and user configuration persists in `config/`. Legacy root INI is read for compatibility. The currently uploaded EXE is stale and must be rebuilt locally on Windows.

## v0.11 — action names without key prefixes

Action names in the UI and README are labels only (e.g. **YouTube window**, not **Win+Y — YouTube window**). Show the assigned shortcut separately in the Shortcut field / README metadata; do not modify actual triggers or execution handlers.


### v0.12 root AHK fallback

The executable on Drive is stale and cannot be verified on Windows in this environment. `Keyboard-Setup-Launcher.ahk` is the direct runnable fallback in the repository root (AutoHotkey v1.1, `#Requires AutoHotkey v1.1`); source references to `src/Keyboard-Setup-Core.ahk` and `import/3DsMax/3DsMax-Importer.ahk` must resolve from the root. The root AHK and compiled EXE continue to use the same named mutex and root UI/INI/import configuration. Compile from the root launcher source via `build/Build-Keyboard-Setup.cmd`; do not claim the existing EXE is fixed.


## v0.12 — Win+I IrfanView image action

- New resident hotkey `#i`; action label **IrfanView image** without hotkey prefix in UI.
- Preserve clipboard contents; for CF_BITMAP / CF_DIB / CF_DIBV5 / CF_ENHMETAFILE / PNG use IrfanView `/clippaste`. For a single copied image-file path (text or Explorer CF_HDROP), open the file directly. No temporary image files.
- Resolve IrfanView from `config/Keyboard-Setup-Applications.ini`, registered App Paths, or common 32-bit/64-bit Program Files paths. When unavailable, prompt FileSelectFile for i_view32.exe/i_view64.exe and persist selected executable. Cancel safely.
- Unsupported clipboard contents show a brief tray notice. The action intentionally replaces Windows Settings `Win+I` while the resident is active. Keep previous six actions and singleton architecture unchanged.
- Runtime source `.ahk` is effective after resident restart, but old root `.exe` is stale until recompiled on Windows.


## v0.13 — Win+I IrfanView window cycling fallback

Preserve priority of clipboard image and image-file-path operations. Only when
neither source exists, enumerate visible `i_view64.exe` and `i_view32.exe` top-level
windows, ignoring owned dialogs. Activate the sole window, or cycle multiple
windows by a stable HWND order; restore a minimized target, track the previously
selected HWND to continue when another app has focus. If no IrfanView window
exists, retain the brief tray notification. The no-image branch must not browse
for an executable, start IrfanView, or change clipboard contents.


## v0.14 — standalone Hotkey Index

- Create a separate single-instance `src/Keyboard-Setup-Hotkey-Index.hta` reference window. Add **Hotkey Index** to the existing tray menu and main GUI sidebar; do not launch another resident or change the tray default (Open Keyboard Setup). Existing index windows are restored/activated.
- Move the seven global action labels and concise workflows to shared `data/Keyboard-Setup-Catalog.js`; consume them in the main keyboard editor and the index rather than maintaining separate conflicting lists. The actual hotkeys remain implemented by root AHK v1.
- Show separate Shortcut, Action, Context, Status columns; choose a row to show the subaction flow. Read the optional bound-file INI to identify action overrides, not to execute them.
- Add `Global AHK`, `3ds Max effective`, and `3ds Max factory` profiles. Max data remains a read-only imported snapshot, never registered globally. Limit the index to 12 rows per page with search instead of unnecessary scrollbars.
- Preserve the v0.13 keyboard geometry and IrfanView handler, root cleanup convention, and one resident/mutex. Index source tests validate the two Max record counts and global consistency. Windows MSHTA runtime requires machine validation.


### v0.15 — 3ds Max context-aware Hotkey Index

Hotkey Index reads the existing ActionTables.tsv export from the project's `import/3DsMax` folder, using the TEMP export as fallback. It matches ActionMan Action Table + action IDs, normalizing unsigned HSXB IDs to signed MaxScript values. Offer a second filter dropdown only on 3ds Max profiles, populated with **actual** Context, Action Table and Category field values. Include an Edit Poly quick filter only if exported metadata contains a matching label, combining matches across those three fields; search also includes them. Display Context/Action Table/Category in action details and show Unclassified when the ID has no metadata. Never infer contextual classification from action names or pretend factory/overlay files alone expose this information. Keep 12-row pagination, existing singleton UI, and all runtime hotkeys unchanged.


## v0.16 — single-instance lifecycle

Use a process-owned Win32 named mutex for one resident process across interpreted AHK and rebuilt EXE. The second launch exits and optionally activates the existing settings/index window; never force-kill the first resident. Centralize both tray UI handlers through one `keyboardOpenSingleUi(kind)` function with native window lookup, restore/activate, pending mshta PID and debounce. Keep distinct HTA `APPLICATIONNAME` values with `SINGLEINSTANCE=yes` so direct file launches are independently guarded. Before one HTA opens the other, attempt `WScript.Shell.AppActivate` by stable title prefix. Keep the editor and index each at most one window; neither window's closure stops the resident. Current shipped EXE remains stale pending rebuild and must not be reported as updated.


### v0.17 — AutoHotkey Toolkit imported actions

Register 14 external script shortcuts from Toolkit screenshot in the existing single resident (total 21). Maintain one shared index/editor catalogue. Keep execution by reference to original script paths; prompt Browse when missing and persist the user-selected locations in `config/Keyboard-Setup-Toolkit-Paths.ini`. File binding overrides have priority. AHK script targets require v1, especially for compiled mode. The three user-supplied scripts clarify mute timing, Komodo MAXScript listener routing, and kill-all confirmation/Max-only relaunch; do not alter or silently replace these external files. The Toolkit's original hotkey owner must be disabled to prevent conflicts. Do not modify the default keyboard geometry or 3ds Max contexts.


## v0.18 — bottom-centred shortcut action monitor

Put the fixed-height action monitor below the 1444×592 keyboard card in the blank left-column space. Recognised shortcuts update chord, name and one-sentence description; geometry of the keyboard and editor stays unchanged. HTA keydown can preview matched references when focused. AHK writes only chord and serial to `%TEMP%\KeyboardSetupActionEvent.txt` with an atomic replacement, HTA polls every 300 ms. Skip events left from earlier sessions on UI startup. 3ds Max actions are reference previews and are not globally monitored. Do not add windows or global hooks or steal keyboard focus.


### v0.19 merged source design

Use **Default** and **User defined** origins, not separate factory/effective profiles. The merged Max reference applies user removals and additions on top of factory, retaining shared key combinations in different Max action contexts. Use a combined Windows 11 + resident PowerKeys/AHK shortcut list (Windows references read-only, resident action file targets editable), show overrides instead of presenting Windows defaults as active, and retain original default action explanations. Windows entries come from a documented static reference (not live Windows registry). No distinct PowerKeys application configuration was provided, so do not claim to import it or make shortcuts executable from this view. Keep the 21 resident actions as the only live global actions.


### v0.20 — program-specific effective lists and lifecycle

Two frontend program sources: Windows (50 Windows native references overlaid by 21 resident actions, 60 effective entries after modifier-order normalization), and 3ds Max (factory HSXB overlaid by the user's HSX). No split view for imported Toolkit, factory or user-defined actions; provenance is shown as Default or User defined in one list. In the Windows source, selecting an actual resident action retains file-target editing, while Windows reference shortcuts stay read-only. A resident-only OnExit callback closes both owned HTA windows on tray Exit without killing unrelated applications. The previous standard tray menu remains available.


### v0.21 — native Windows shortcut override clarity

For Windows effective shortcuts, show one active user-defined action per
normalized chord. When it overrides a Windows system default, display the
default action by name in the index row, metadata, main editor and action
monitor. Never dispatch the Windows default as a fallback for a registered
resident shortcut. Native OS-reserved shortcuts may not be intercepted;
communicate this limitation and do not use a `~` AHK pass-through prefix.


## v0.22 — strict modifier RGB system

Modifier colours use one shared `data/Keyboard-Setup-Modifier-Colors.js` function in both HTAs. Ctrl enables red, Shift green and Win blue; Alt attenuates enabled channels by 65% (internal default `keyboard_modifier_alt_darkness = 0.65`). Enabled channels are FF normally, or 59 when Alt is held; disabled channels always remain 00. Alt only and no modifiers are both `#000000`, intentionally. The active modifier name and HEX chip distinguish these states without altering their RGB value.

Keys at rest retain their original dark keycap texture, with a 5px ribbon of calculated RGB colour. Keys with multiple shortcuts show equal-width, hard-edged bands in that ribbon of the distinct calculated colours (sorted solely for deterministic visual layout, never assigning priority). When modifiers are held or latched, compatible keys show the current combination's exact RGB colour. The index and editor use the same calculator for swatches and shortcut borders. Physical keydown, keyup, blur/reset, latch clicks and source changes already call the keyboard highlight updater, so colours follow state changes immediately. Preserves keyboard geometry and all existing runtime hotkeys. Only reopen the HTAs; no EXE rebuild.

Regression: `node tests/Keyboard-Setup-Modifier-RGB.Tests.js` checks the exact 16-state table, Alt darkness override, modifier order independence, press/release, latch/physical combination and the editor/index shared rendering.

### v0.23 — union of modifiers per physical key; original key highlight restored

Remove the v0.22 split colour ribbons. Keep the original shaded full-key highlight shape (coloured border, dark gradient tinted by calculated RGB, and stronger glow on compatible matches). Calculate one colour from the union of all modifiers across all current-program shortcuts assigned to that physical key, rather than displaying separate shortcut colours or using a priority rule. Press/release controls filtering and glow intensity, not the physical key's accumulated colour. Example: Ctrl+G + Shift+G → yellow; a third Win+G → white. Selection remains the original blue state.

Change Alt from 65%-black attenuation to additive **white** (RGB channels all enabled, 255); Alt-containing combinations therefore all render `#FFFFFF`. The complete 16-state calculator, colour swatches, and index reuse the shared `Keyboard-Setup-Modifier-Colors.js`. Preserve no-modifier colour `#000000`, the ordinary key texture, layout, actions, and shortcuts. Add test fixtures for mixed assignments and differing declaration order. No AHK launcher changes.


## v0.24 — resilience to module sync order

The UI checks for all four shared RGB functions at load time. If the shared module
is absent or from before the key-union API, the editor installs equivalent
additive RGB functions locally, ensuring keyboard initialisation never calls an
undefined union function. The shared data module remains the preferred source
when present. Keyboard layout, shading, shortcut bindings and tray launcher
are unchanged. Regression tests cover latest, stale and absent module states.


## v0.25 — softer shared display colours and combination legend

Keep exact binary additive modifier RGB calculation for data/state tests, but
render a muted variant on keycaps, borders, glows, editor swatches, index swatches,
and feedback strip. Win blue shifts towards a sky hue using a green-channel
contribution only in the visual transform. Alt and the full RGB union are pale
white. The transform is identical in the shared module and the HTA sync fallback.
The informational strip shows eight representative combinations (four single modifier
labels plus three 2-key mixes and Ctrl+Shift+Win), with Alt (+any) meaning all
Alt-containing combinations have the same white outcome. Remove the decorative
Match item but preserve match logic, full-key shading and keyboard geometry.


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


### v0.27 — exclusive active modifier filter

Replace the previous active-modifier *subset* filter with exact set equality.
When active modifiers are present, keycaps, tooltips, glow and the assigned
shortcut overview show only bindings with exactly those modifiers (order
independent). Colors are accumulated only from the visible exact subset.
No modifiers means the original full catalogue and accumulated idle colors.
Support physical and latched modifiers together. Source data, layout and
resident hotkeys are unchanged.


### v0.28 — selective keyboard geometry refinement

Narrow the main Tab by one standard key unit (85 -> 49 CSS px), Caps Lock
by approximately half a unit (85 -> 67px), and independently size the
right Ctrl (85 -> 68px) to line up with the right Shift
edge of the typing block. Keep the rest of the existing keyboard geometry and RGB styles.


### v0.29 — tray Restart grouping and tooltip paragraphs

Preserve the v0.26 mutex restart and standard Exit command while separating Restart visually in the tray menu. Show the source version in the tray tip to expose an out-of-date EXE. Key hover tooltips show one `Shortcut - Action` per paragraph, separated by `\r\n\r\n`, and respect exact modifier filtering (Ctrl versus Ctrl+Win versus Ctrl+Shift). Do not alter layout, colour calculations, shortcuts, or Hotkey Index data. A new compiled EXE requires rebuilding on Windows.


### v0.30 — readable interface without keyboard geometry changes

Increase every text font outside the rendered physical keyboard by two CSS pixels across the main editor and Hotkey Index. Keep `.key`, `.key.return-tall`, `.key.nav-print-screen`, button heights, widths, key rows and keyboard zoom fixed. Enlarge modifier swatches in the keyboard status strip and the index. Define a simple deterministic AHK v1 tray menu with Open Keyboard Setup / Hotkey Index / Restart / Exit, ensuring keyboardRestartResident uses the established safe mutex handoff; Exit still invokes the two-HTA cleanup. The old compiled binary cannot update itself from source and requires a local Windows rebuild or launch of the current AHK v1 file.


### v0.31 — typing-row right edges and Print Screen label

Keep main Enter at 75px (two normal key widths). Align the right ends of
Backspace, backslash, right Shift, and right Ctrl with that Enter edge by using
independent CSS widths (67, 54, 96, 52px respectively). Keep unchanged all
other keyboard keys, row starts, shortcuts, texture, and 150% scale. The
PrntScrn key remains in the top navigation header, but its caption is now
anchored to the bottom-left corner of its keycap. No resident AHK change.

### v0.32 — Print Screen alignment and balanced navigation spacing

Anchor Print Screen / Scroll Lock / Pause to the same navigation block as
Insert / Home / Page Up rather than using an independently sized top-header
column. Keep their keys one row above the corresponding navigation keys;
Print Screen stays bottom-left-labelled. Shift the navigation block and numpad
as a pair to leave visible gaps of about half a standard key (approximately
18 CSS px) on either side of the navigation keys, at the default 150% zoom.
Preserve all typing-row end alignment, key sizes, arrow alignment, modifier
colour logic, shortcut behaviour and resident launcher.


### v0.33 — Game Bar conflict on Win+G

The earlier `#g::` was a normal AHK hotkey, which can use the operating system's
`RegisterHotkey()` method. When Game Bar has already claimed the shortcut, it
may still launch before this action can fire. Force the Win-key resident hotkey
section through `#UseHook On` before `#y::`, and return to `#UseHook Off` after
`#r::`. This uses the low-level keyboard hook to intercept registered Win-key
overrides without a `~` pass-through prefix. Ctrl-only shortcuts are unaffected;
the Win+G dispatch remains `keyboardPublishShortcut("Win+G")` followed by
`searchOrCycleChrome()` or the existing configured file override.

Do not edit Xbox Game Bar settings, kill Xbox processes, or alter the registry
from Keyboard Manager. Verify the new resident using the versioned tray tip
`Keyboard Setup v0.33` and a separate Windows runtime smoke test. Test the
process hand-off and keyboard hook source with
`node tests/Keyboard-Setup-Resident.Tests.js`. Compile the EXE on Windows for
changes to take effect in compiled mode. Native Game Bar suppression cannot be
claimed as verified by source tests alone.
