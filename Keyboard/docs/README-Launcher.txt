Keyboard Setup — archived launcher notes (v0.10 repository layout)
============================================================
For the current v0.34 layout, use README.md in the project root.
The resident entrypoint is Keyboard-Setup-Launcher.ahk in the project root.
Every registered hotkey dispatches to its own actions\<Action>\<Action>.ahk
via the AutoHotkey v1.1 interpreter, while Toolkit wrappers call original
external scripts. The historical notes below are not the current layout.

Historical v0.10 information follows:
The root has only Keyboard-Setup-Launcher.exe, Keyboard-Setup-Design-Options.hta,
README.md, and design.md. Sources and resources have moved as follows:
  src\Keyboard-Setup-Launcher.ahk / Keyboard-Setup-Core.ahk
  data\Keyboard-Setup-Max-Preset.js / Keyboard-Setup-Max-Defaults.js
  assets\Keyboard-Setup.ico / Keyboard-Setup-Icon.png
  build\Build-Keyboard-Setup.cmd / Build-Keyboard-Setup.ps1
  config\Keyboard-Setup-File-Bindings.ini (created on first save)
  import\3DsMax\... (unchanged)
To rebuild, run build\Build-Keyboard-Setup.cmd from the project root.
The older EXE on Google Drive has NOT yet been rebuilt with this layout.

Original instructions retained below for history; old root-relative paths
in these instructions are superseded by the layout above.

Keyboard Setup launcher
=======================

Create the taskbar launcher
---------------------------
1. Keep these files together in the Google Drive Workstation\Keyboard folder:
   - Keyboard-Setup-Design-Options.hta
   - Keyboard-Setup-Launcher.ahk
   - Keyboard-Setup-Core.ahk
   - Keyboard-Setup-Max-Preset.js
   - Keyboard-Setup-Max-Defaults.js
   - import\3DsMax\3DsMax-Importer.js
   - import\3DsMax\3DsMax-Importer.ahk
   - import\3DsMax\3DsMax-Export.ms
   - Keyboard-Setup.ico
   - Build-Keyboard-Setup.cmd
   - Build-Keyboard-Setup.ps1
2. Exit any running Keyboard Setup instance from its tray menu, then double-click Build-Keyboard-Setup.cmd.
3. The script recompiles Keyboard-Setup-Launcher.exe with Keyboard-Setup.ico and creates Keyboard-Setup.lnk beside it. Rebuild after any launcher source change.
4. Right-click Keyboard-Setup-Launcher.exe or Keyboard-Setup.lnk and choose Pin to taskbar.
5. Optional check: run Test-Keyboard-Setup-Launcher.ps1 to verify the launcher and icon.

The launcher now stays running in the Windows notification area. Starting the
launcher does not open the settings window. Left-click its tray icon once to
open the HTA; left-click again to activate the existing window. Right-click
the tray icon for AutoHotkey's normal context menu (including Exit), plus
Open Keyboard Setup. Closing the HTA does not stop the background launcher.

On first run, the launcher creates Keyboard-Setup.lnk in the current user's
Windows Startup folder. It refreshes that shortcut on subsequent runs. To
disable automatic startup, remove that Startup-folder shortcut. Exit from
the tray menu to stop the launcher for the current Windows session.

Keep the HTA beside the EXE, so it continues to work if the Google Drive
folder is moved. AutoHotkey v1 and its Ahk2Exe compiler must be installed
to rebuild the EXE. The launcher source may also run directly under AHK v1.

Runtime hotkeys (AHK v1 source, requires an EXE rebuild)
--------------------------------------------------------
- Ctrl+U: selected text cycles UPPERCASE -> lowercase -> Capital -> UPPERCASE.
- Ctrl+Shift+U: selected text cycles eight naming conventions; if nothing is
  selected, tries the word under the cursor.
- Ctrl+double quote: wrap or unwrap selected text in double quotes. This uses
  Ctrl+Shift+the physical apostrophe key (SC028) on English QWERTY.
- Win+Y: activate a visible YouTube Chrome window, otherwise open YouTube.
- Win+C: activate/cycle Total Commander windows, or launch Total Commander.
- Win+G: Google-search selected text, otherwise activate/cycle Chrome windows
  or open Chrome if none exists.

The clipboard is restored after text commands. Only browser windows with a
YouTube title currently count as an existing YouTube window; a hidden tab
behind another active Chrome tab may cause a new YouTube tab to open.
Hotkey conflict detection and registration of newly added chords remain
future work.

File target bindings (v0.04)
----------------------------
- In the shortcut editor select one of the six resident hotkeys, then select
  FILE TO RUN with Browse... or enter an absolute Windows path.
- Save binding writes Keyboard-Setup-File-Bindings.ini next to the HTA. When
  a configured file exists, pressing that hotkey opens the file IN PLACE OF
  its built-in command. Clear the path to restore the built-in command.
- The six resident hotkeys read the INI on each press; source code changes
  still require recompiling the EXE. New shortcut combinations and action
  dropdown changes remain visual previews until the runtime is extended.
- A missing target file shows a tray warning and falls back to the built-in
  behavior. The INI is generated when the first file binding is saved.

Import 3ds Max shortcut references
---------------------------------
- Choose Source: 3ds Max factory to see 532 base assignments imported from
  WORKSTATION\Keyboard\import\3DsMax\Default.hsxb (XML content).
- Choose Source: 3ds Max effective to see the base with the vilbur.hsx
  customization overlay applied. This has 575 effective assignments.
- The vilbur.hsx file has 90 assignments and 55 removals. Exactly 47
  removals match this factory file; the other eight records are preserved
  in the overlay without removing unmatched factory entries.
- Click Import 3ds Max... to open the dedicated importer dialog. It detects
  the newest installed 3ds Max under Program Files\Autodesk, its Default.hsxb,
  and the matching .hsx user overlay under AppData\Local\Autodesk.
  It asks to confirm found paths and offers Browse when files are missing.
  The layered result is recalculated from the selected XML files.
- Import + export categories requests the resident AutoHotkey v1 tray process
  to run import\3DsMax\3DsMax-Export.ms inside 3ds Max. If the matching
  version is already running, the exporter is sent straight to its MAXScript
  mini-listener using MXS_Scintilla (without restarting or closing Max).
  Otherwise the tool creates a unique temporary startup .ms in that version
  of 3ds Max user Startup Scripts folder, starts Max, waits for export,
  removes only its temporary .ms, and closes only the Max instance it started.
  On startup/export timeout it leaves the instance open, and still removes
  the temporary script. It does not change the current scene or hotkeys.
- Exported metadata (numeric ID, Category, Description, Action Table, Context)
  is written to TEMP\KeyboardSetupMaxImport\ActionTables.tsv and copied to
  import\3DsMax\ActionTables.tsv for later viewing. Named macro IDs that
  are not discoverable by numeric ActionTable + ActionItem IDs remain without
  category until a later resolver covers them.
- Factory and Custom origins are labelled in the list. Imported records
  are read-only and remain scoped to 3ds Max.
  No global AutoHotkey hotkeys are registered from imported entries.

Try the interactive keyboard preview
------------------------------------
- Hold Ctrl, Shift, Alt, or Win while the HTA is focused. Assigned keys highlight when
  their shortcuts use every active modifier; extra shortcut modifiers are allowed.
- With no modifiers active, unselected assigned keys are colored by the highest modifier
  count used by that key: 1 green, 2 blue, 3 orange, 4 red.
- Click Ctrl, Shift, Alt, or Win on the on-screen keyboard to latch or unlatch it.
- Click a regular key to create a shortcut with the active modifiers, or edit that
  exact shortcut if it already exists.
- Use Assigned shortcuts to edit existing bindings. File targets save to INI;
  other preview edits are in memory only.
- The keyboard opens at 150% scale. Main Enter and numpad Return are each one key wide
  and two key rows tall. The right Windows key uses a tab-arrow icon while retaining its
  Win modifier behavior.
- Version 0.06 keeps the outer dialog 2048 x 838 and keyboard card 1444 x 592.
- To run the interaction test from this folder, use:
  node tests\Keyboard-Setup-UI.Tests.js

- To check the resident/tray/startup source contract, use:
  node tests\Keyboard-Setup-Resident.Tests.js

- To check the six registered hotkey declarations, use:
  node tests\Keyboard-Setup-Hotkeys.Tests.js

- To check the 3ds Max import pipeline and detection logic, use:
  node tests\Keyboard-Setup-Max-Importer.Tests.js

- To test the transformations on Windows with AutoHotkey v1, run:
  AutoHotkey.exe tests\Keyboard-Setup-Core.Tests.ahk


Keyboard Setup v0.07 — larger desktop window / no default scrollbars
-----------------------------------------------------------------
- Main UI grows to a 2220 x 1050 outer window on large displays. On smaller
  screens, the HTA scales its 2220 x 1050 layout to fit the available monitor
  work area without opening window-level scrollbars. The window is still
  non-resizable.
- The original keyboard card remains 1444 x 592. Keyboard stage padding is
  reduced so its 150% default zoom fits without horizontal/vertical bars.
  Deliberate zoom above 150% can use viewport scrollbars to navigate details.
- The shortcut editor is 470 px wide and 820 px high with no independent
  scrolling. The shortcut overview now shows four searchable entries per page
  with Prev/Next, including for the 575-record 3ds Max effective preset.
- 3ds Max importer popup is widened to 1010 px while respecting the viewport.
- The resident launcher and compiled EXE are unchanged; reopening the HTA
  picks up these UI changes without rebuilding the EXE.

Keyboard v0.08 appearance and tray fix
---------------------------------------
- Tray left-click first finds any existing Keyboard Setup HTA window, accepting
  legacy and versioned titles, and restores/activates it instead of launching
  new copies. Repeated rapid tray clicks are debounced while mshta starts.
- The resident launcher is #SingleInstance Force. EXIT OLD TRAY PROCESS and
  REBUILD Keyboard-Setup-Launcher.exe using Build-Keyboard-Setup.cmd on Windows;
  the existing compiled EXE will not gain these fixes automatically.
- Retains v0.07 full keyboard placement and no-scroll layout; restores earlier
  shaded/raised key texture without changing normal key dimensions.
- Arrow cluster is one row lower. Numpad + and Return span two rows, and
  numpad 0 spans the width of two keys. All other keys retain v0.07 sizing.
- UI changes need only closing and reopening the HTA; tray fix requires rebuild.


Keyboard layout adjustment (v0.09)
---------------------------------
- Main Enter is 2x1 horizontal, aligned with right Shift on its right edge.
- Left, Down and Right navigation arrows align with Space; Up is directly above.
- Esc is standard 1x1.
- PrntScrn, ScrLK and Pause are directly above Ins, Home and PgUp.
- Preserve the v0.08 shaded key texture, two-row numpad + and two-key numpad 0.
- HTA layout only: reopen Keyboard Setup; launcher EXE rebuild is not needed.

Keyboard Manager v0.10 — single-instance and action help
---------------------------------------------------
- Only one resident instance is allowed across interpreted AHK and compiled EXE.
  A shared named OS mutex prevents duplicates; extra instances exit immediately.
- Only one UI: the HTA uses SINGLEINSTANCE plus tray window detection, pending
  process guard and click serialization. Existing settings UI is reactivated.
- The Action selector shows a live description below the dropdown.
- See README.md for full flows and subactions for all six hotkeys and importer.
- IMPORTANT: exit all previous resident tray instances and rebuild the EXE
  with Build-Keyboard-Setup.cmd to activate the new process guard.
