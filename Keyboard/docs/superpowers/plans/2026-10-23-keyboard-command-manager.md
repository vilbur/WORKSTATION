# Keyboard Command Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Windows keyboard command manager with a keyboard-layout HTA editor and an AutoHotkey v1 tray runtime for Win+G, Ctrl+Shift+U, and Ctrl+U.

**Architecture:** Keep the existing `Keyboard-Assistant_0.11.ahk` unchanged. The new AHK v1 resident script reads a small INI configuration when each shortcut fires and runs its action; the HTA editor writes that same configuration. Shared pure helpers live in a small include file so their case conversion, URL encoding, path validation, and configuration parsing can be tested without launching the editor.

**Tech Stack:** AutoHotkey v1, HTA/HTML/CSS/JavaScript, Windows INI configuration, no third-party dependencies.

**Spec:** `design.md` in `Google Drive\Workstation\Keyboard`; codebase copy in `G:\CODEBASE\AHK\Utilities\Keyboard-Setup`.

## Global Constraints

- Store project files in `Google Drive\Workstation\Keyboard`.
- Keep the runnable AHK utility project in `G:\CODEBASE\AHK\Utilities\Keyboard-Setup`.
- Use AutoHotkey v1 for the new runtime; preserve `Keyboard-Assistant_0.11.ahk` and its existing behavior.
- Target the Microsoft Wireless Comfort Keyboard 5050 standard full-size layout.
- Display English QWERTY key legends only and allow the keyboard illustration to scale from 100% to 200%.
- Organize bindings around input/trigger context and execution/action context.
- Win+G priority: selected text → valid selected Google Drive item in Total Commander → open or activate Chrome.
- Ctrl+Shift+U: selected text with all letters uppercase becomes lowercase; otherwise letters become uppercase; no letters means no change.
- Ctrl+U: detect the selected string's naming convention and cycle it to the next style, replacing the selection; if there is no selection, use the word under the cursor. Cycle lowercase -> Capital -> UPPERCASE -> PascalCase -> camelCase -> snake_case_low -> Snake_Case_Capital -> SNAKE_CASE_UPPER -> lowercase; unrecognized input starts at lowercase.
- The first implementation assigns commands to shortcut combinations; it does not replace individual key outputs.
- Do not add arbitrary shell-command execution to the HTA editor.
- Use `D:\GoogleDrive` as the default Google Drive sync root, but let the user change it in the editor.
- Do not add the app to Windows startup by default; the editor may offer an opt-in setting.

## Review Focus

- Empty or unavailable selection: each command must safely do nothing or use the documented Chrome fallback.
- Text-command clipboard transfer: preserve clipboard contents and avoid replacing text if copy/selection retrieval fails.
- Ctrl+U conversion: test each convention in the cycle, unknown input, selection replacement, word-under-cursor fallback, line breaks, and separators.
- Mixed case and non-letter characters: test mixed strings, all-uppercase strings, punctuation-only strings, and non-ASCII letters.
- Google Drive path validation: accept files beneath the configured root and reject similarly prefixed paths outside it.
- Shortcut conflicts: test Win+G against Xbox Game Bar and both Ctrl+U combinations in applications that already use them; show conflicts or allow the user to disable a binding.

---

## File Structure

- `Keyboard-Setup.ahk` — resident v1 runtime, tray menu, global shortcuts, focused-window and selected-item detection.
- `Keyboard-Setup-Core.ahk` — pure transformation, URL, path, and INI helpers shared with runtime tests.
- `Keyboard-Setup.hta` — keyboard canvas, binding list, trigger/action editor, and configuration save UI.
- `Keyboard-Setup.ini` — initial binding configuration and Google Drive root setting.
- `README.md` — install, run, configuration, shortcut behavior, and known conflicts.
- `tests/Keyboard-Setup-Tests.ahk` — dependency-free v1 assertions for pure helper behavior.

### Task 1: Pure command helpers and test harness

**Files:**
- Create: `Keyboard-Setup-Core.ahk`
- Create: `tests/Keyboard-Setup-Tests.ahk`

**Interfaces:**
- Produces: `toggleSelectionCase(text)`, `cycleNamingConvention(text)`, `encodeUrlComponent(text)`, `isPathUnderRoot(path, root)`, `resolveWinGAction(has_selected_text, tc_active, selected_path, drive_root, selected_count)`, and `loadKeyboardSettings(ini_path)` returning an object with `google_drive_root`, `enabled`, and `start_with_windows`.
- `toggleSelectionCase(text)` returns lowercase only when all letters are uppercase; otherwise it returns uppercase. Strings with no letters are returned unchanged. This is bound to Ctrl+Shift+U.
- `cycleNamingConvention(text)` follows the eight-style cycle in the design doc and is bound to Ctrl+U; conversion replaces the selection or current word under the cursor.
- `isPathUnderRoot(path, root)` compares normalized Windows paths on a directory boundary, case-insensitively.
- `resolveWinGAction(...)` returns `google`, `drive`, or `chrome` using the approved priority order; the `has_selected_text` input excludes Total Commander file-list selections, and a multiple-item file selection is treated as invalid and returns `chrome`.

- [ ] **Step 1: Write failing v1 assertions** in `tests/Keyboard-Setup-Tests.ahk` named `testToggleSelectionCase`, `testCycleNamingConvention`, `testEncodeUrlComponent`, `testIsPathUnderRoot`, `testResolveWinGAction`, and `testLoadKeyboardSettingsDefaults`. Assert Ctrl+Shift+U cases `HELLO` -> `hello`, `hello` -> `HELLO`, `Hello` -> `HELLO`, `123-!?` unchanged; assert Ctrl+U conversion through all eight naming styles, unknown style to lowercase, and multi-line selection replacement; `file name & more` -> `file%20name%20%26%20more`; `D:\GoogleDrive\Work\a.txt` under the root and `D:\GoogleDriveX\a.txt` outside; text -> `google`, one valid TC item -> `drive`, no selection or multiple items -> `chrome`; missing INI -> root `D:\GoogleDrive`, enabled `1`, startup `0`.
- [ ] **Step 2: Run the test script under AutoHotkey v1** and confirm the expected failures identify the missing helpers.
- [ ] **Step 3: Implement the six named helpers** in `Keyboard-Setup-Core.ahk` without external libraries; encode URL query data as UTF-8 before percent-encoding.
- [ ] **Step 4: Run the test script again** and confirm every assertion passes.

### Task 2: Resident AutoHotkey runtime

**Files:**
- Create: `Keyboard-Setup.ahk`
- Create: `Keyboard-Setup.ini`
- Modify: `Keyboard-Setup-Core.ahk`
- Test: `tests/Keyboard-Setup-Tests.ahk`

**Interfaces:**
- Consumes: the six helpers from Task 1 and the `[General]`, `[WinG]`, `[CtrlShiftU]`, and `[CtrlU]` INI sections.
- Produces: persistent tray runtime with configured `#g`, `^+u`, and `^u` handlers; each handler reads its current INI section before acting. The default INI sets `GoogleDriveRoot=D:\GoogleDrive`, global hotkeys enabled, and `StartWithWindows=0`.

- [ ] **Step 1: Add failing tests** for selection priority, Drive-root path acceptance/rejection, selected basename extraction, fallback action selection, case toggle, and naming-convention conversion.
- [ ] **Step 2: Run the tests** and confirm the new handler-selection cases fail before implementation.
- [ ] **Step 3: Implement `Keyboard-Setup.ahk`** with Win+G, Ctrl+Shift+U (`^+u`), and Ctrl+U (`^u`) handlers, tray enable/disable and exit items, safe clipboard snapshot/restore around text operations, Total Commander single-item retrieval by copying the file-panel selection and reading its full path, and Chrome activation/launch fallback. Treat zero or multiple TC file selections as invalid; then use selected text if available, else Chrome.
- [ ] **Step 4: Run helper and handler-selection tests** under AutoHotkey v1. Manually smoke-test selection copy/paste in Notepad, Chrome, and Total Commander.
- [ ] **Step 5: Test shortcut conflicts** with Windows Game Bar and Chrome's existing Ctrl+U and Ctrl+Shift+U behaviors; document any Windows setting needed to allow the configured bindings.

### Task 3: HTA configuration editor

**Files:**
- Modify: `Keyboard-Setup.hta`
- Modify: `Keyboard-Setup.ini`
- Test: manual Windows HTA checks and INI round-trip checks.

**Interfaces:**
- Consumes: `[General]`, `[WinG]`, `[CtrlShiftU]`, and `[CtrlU]` settings written by Task 2.
- Produces: saved shortcut, trigger, action, enabled state, and Drive-root values in the INI file.

- [ ] **Step 1: Add the editor test checklist** for the keyboard canvas, selection of Win+G/Ctrl+Shift+U/Ctrl+U, trigger/action controls, validation, and save/reopen persistence.
- [ ] **Step 2: Run the checklist against the current HTA** and record the controls that are only mockups.
- [ ] **Step 3: Implement the interactive keyboard canvas** with physical modifier key tracking, clickable latched Ctrl/Shift/Alt/Win keys, exact-combination highlights, and a click-to-add/edit shortcut form. In the idle state, color unselected keys by their highest assigned modifier count: 1 green, 2 blue, 3 orange, 4 red; preserve selection and active-match styles.
- [ ] **Step 4: Add the live shortcut overview**; clicking an overview row selects its key and opens the existing binding for editing.
- [ ] **Step 5: Implement the keyboard canvas and binding list** using the existing prototype's visual direction; label binding sections as input/trigger context and execution/action context; include bindings for Win+G, Ctrl+Shift+U, and Ctrl+U; include a keyboard-only 100%-200% zoom slider and English QWERTY legends.
- [ ] **Step 6: Implement configuration save/load** for the exact INI fields, including the configurable Google Drive root and opt-in start-with-Windows setting, and show a clear validation message for invalid values.
- [ ] **Step 7: Reopen the HTA and verify** saved values persist and are read by the AHK runtime without restarting the process.

### Task 4: Packaging and user verification

**Files:**
- Create: `README.md`
- Verify: design files in `Google Drive\Workstation\Keyboard` and runnable utility files in `G:\CODEBASE\AHK\Utilities\Keyboard-Setup`.

- [ ] **Step 1: Write the README** with AutoHotkey v1 launch instructions, HTA editor use, default shortcuts, Google Drive root configuration, and conflict notes.
- [ ] **Step 2: Run the complete AutoHotkey test script** and repeat the manual smoke-test matrix on Windows.
- [ ] **Step 3: Verify the Drive folder** contains the runtime, shared helper, editor, INI, README, and tests; open the HTA and confirm each view and save operation works.

## Plan Self-Review

- Every approved design requirement maps to a task: runtime/shortcuts and both case commands to Task 2; keyboard-layout editor and trigger/action contexts to Task 3; persistence to Tasks 2–3; tests and install guidance to Tasks 1–4.
- The highest-risk behavior is selection and clipboard handling across unrelated Windows apps; Task 2 includes manual tests and safe failure behavior.
- Windows-only execution cannot be verified in this workspace, so AHK and HTA runtime checks must be run on the user's Windows machine before claiming those behaviors work.
