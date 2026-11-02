# Window List Manager — development rules

## Purpose

Keep open Windows applications easy to find and switch to in a narrow, dark panel.
Show titles only; keep application and Chrome-domain grouping internal.
Read Documents/design.md and Documents/README.md before changing behavior.

## Project

- AutoHotkey v2 only. Do not apply MaxScript syntax or AHK v1 syntax.
- Main entry: root Window-List-Manager.ahk, compiled directly to Window-List-Manager.exe. Both select the highest numeric Lib/Window-List-Manager-<version>.ahk.
- Implementations belong in Lib; resolve root paths explicitly. Tests: Tests/Window-List-Manager-Test.ahk; include the current implementation directly, not the launcher.
- Helpers, icon, extension and build tools belong in Library.
- Documentation and its screenshot belong in Documents.
- The original MVP baseline was v0.11. The current stable baseline is v0.236; keep Lib/Window-List-Manager-0.236.ahk unchanged when creating later versions. The current development source version is declared in the versioned implementation.
- Update existing Google Drive files in place, preserving their IDs. Fetch current contents before edits; do not overwrite concurrent changes from another session.

## Coding

- Use camelCase function names and snake_case variables. Put opening braces on a new line.
- Describe each new function with a block comment.
- Use actual AutoHotkey v2 APIs. AHK function declarations have no function keyword.
- Use WinExist("A") for foreground lookup and reject zero handles.
- Read and move outer window geometry with WinGetPos / WinMove. Do not feed outer dimensions back into DPI-scaled Gui.Show dimensions.
- Use monitor bounds to identify the panel's display; work areas exclude reserved strips.
- Build Win32 structures with correct 32-bit and 64-bit field offsets.

## Behavior to preserve

- Title-only dark UI; internal grouping; Recent and Alphabetical modes; app priorities.
- Domain font color overrides program font color; program color is the fallback.
- A square close overlay appears only on hover. Close through WinClose, preserving application save prompts; never kill the process.
- Docking stays suspended during native dragging. After release, dock on the destination monitor at the saved side.
- Reserve screen space is optional and persisted. It uses a Shell appbar on the panel's current monitor only.
- Release the reservation before dragging, on disable and on exit. Recover registration after Explorer restarts.
- Reserved-space mode disables main-panel topmost behavior temporarily; retain the user's preference for normal mode.
- Do not force-resize unrelated floating windows. Fullscreen applications may cover the panel.
- Preserve the optional Chrome bridge and its local-only communication.

## Verification and delivery

- Extend the AHK test with meaningful behavior checks for changes.
- Test appbar registration, both edges, transfer across monitors, release, restart and width changes on Windows.
- Preserve foreground-lookup and outer-geometry regression checks.
- Do not claim Windows tests or compilation passed unless executed successfully.
- Read back uploaded files and compare them with local contents.
- Keep README options and design.md consistent with shipped behavior.
- An old EXE or ZIP is not updated by changing the AHK source. Build or package explicitly, or report its status.

## Executable entry points

Keep user-facing launch actions as root EXEs: Window-List-Manager.exe,
Install-Chrome-Extension.exe, Build-EXE.exe. Build-EXE.ps1 compiles all three and
runs --check on generated outputs. Entry wrapper sources and CMD recovery
launchers live in Library; never rename scripts to .exe. Keep the root main AHK
as the editable source for the primary EXE.

## Version format

Use exactly three fractional digits and one decimal point: 0.220, 0.221, 0.222.
Increment by 0.001 for each new release. Do not use a second decimal point.
Keep implementation filename, app_version, test include/read paths and current
documentation consistent. Existing historical multi-dot versions need not be renamed.

