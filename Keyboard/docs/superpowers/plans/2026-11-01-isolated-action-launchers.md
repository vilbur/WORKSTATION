# Isolated Action Launchers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Execute all 21 Keyboard Manager shortcuts through individually editable action files, preserving existing behavior.

**Architecture:** The resident owns hotkeys, event reporting, and dispatch; each action entrypoint is a child AHK v1 process. Shared helpers remain available to the entrypoints, and external scripts continue to be called through one common resolver.

**Tech Stack:** AutoHotkey v1.1, HTA/JavaScript, Node.js source tests, Google Drive raw-file project.

**Spec:** `docs/superpowers/specs/2026-11-01-isolated-action-launchers-design.md`

## Execution record — 2026-11-01

- Implemented and published resident source v0.34, 21 isolated action entrypoints, shared action helpers, build validation, documentation, and source regression tests directly into the existing Google Drive project. Existing file identities were preserved for updates.
- Drive readback confirmed all 21 action folders each contain one matching `.ahk`, and the resident, helper, README, build script and changelog contain the new code/text.
- Local Node.js suite: **8 passed, 2 failed**. Both failures (`Keyboard-Setup-Modifier-Colors.Tests.js` and `Keyboard-Setup-RGB.Tests.js`) were present before this refactor and assert superseded Alt-darkness behavior. The current `Keyboard-Setup-Modifier-RGB.Tests.js` passes; color behavior was not changed.
- Native Windows AutoHotkey/HTA behavior, direct action execution, Win+G suppression, and compiled EXE build are not testable in this Linux environment. The Drive EXE remains old until rebuilt on Windows.
- Ruling: preserve the old pure `src/Keyboard-Setup-Core.ahk` file as a compatibility reference rather than deleting it, but move live action-specific algorithms into the action entrypoints.
- Ruling: preserve a legacy default mapping in `src/Keyboard-Setup-Toolkit-Actions.ahk` for its old one-argument caller during staggered Drive sync; v0.34 wrappers pass explicit targets and do not use that map.
- Review: self-review of source and Drive structure (no Git checkout or separate reviewer in this Drive-backed scratch environment).
- Review fix: the common text-selection helper now accepts a `Func(...)` callback rather than statically referencing all three action-specific algorithms. New assertion failed before this fix and passed afterward, along with the relevant hotkey/resident tests. The common helper and three text-action files were re-uploaded in place and read back from Drive.

## Global Constraints

- Work from Drive UI v0.32 / resident v0.33; preserve the existing Drive file IDs on updates.
- Do not alter 21 registered key chords, physical keyboard UI, 3ds Max import, or action-event file format.
- Windows/runtime behavior cannot be fully validated here; provide Windows test commands.
- Keep AutoHotkey v1.1 execution explicit even when v2 is associated with `.ahk`.

## Review Focus

- Missing action entrypoint: resident remains running and reports missing path.
- Absent external Toolkit default path: Browse/cancel behavior remains available.
- Compiled resident with AHK v2 as default: selected interpreter is v1 rather than file association.
- Held modifier during child launch: text and Chrome action remain usable after key release.
- User INI file binding: configured target still takes precedence over the default action.

---

### Task 1: Baseline and dispatch tests

**Files:** Existing Drive sources in local working copy; `tests/Keyboard-Setup-Actions.Tests.js`.

**Interfaces:** `keyboardLaunchAction(chord)` will accept the canonical chord; `keyboardActionRelativePath(chord)` returns path relative to project root.

- [ ] Copy the required current Drive text files into a scratch project tree without changing Drive.
- [ ] Run existing Node.js tests and record baseline results.
- [ ] Write source tests proving the 21 chord/path mappings, standalone action files, safe failure and event publishing.
- [ ] Run the new tests and confirm the intended RED failures.

### Task 2: Resident dispatcher and shared library

**Files:** `Keyboard-Setup-Launcher.ahk`, `src/Keyboard-Setup-Toolkit-Actions.ahk`, optional `src/Keyboard-Setup-Action-Common.ahk`.

**Interfaces:** `keyboardLaunchAction(chord)` and `keyboardRunToolkitAction(chord, default_target)`.

- [ ] Implement the resident path dispatch with explicit AHK v1 selection and missing-file error reporting.
- [ ] Preserve `keyboardRunBoundFile` override semantics (or make them part of dispatch).
- [ ] Move generic action helpers away from resident; retain tray, windows, mutex, importer, event publisher.
- [ ] Run new and existing source tests; correct expected architecture checks as needed.

### Task 3: Twenty-one independent action files

**Files:** `actions/<Action>/<Action>.ahk` for seven built-ins plus fourteen external wrappers.

**Interfaces:** Built-ins call existing pure core functions/shared selection helpers; external wrappers call `keyboardRunToolkitAction(chord, default_target)`.

- [ ] Write/complete each entrypoint, preserving each pre-refactor action's effect.
- [ ] Verify every dispatch path exists and all external targets remain their original exact paths.
- [ ] Run full Node.js source regression suite.

### Task 4: Documentation, publication, and verification

**Files:** `README.md`, `design.md`, `CHANGELOG.md`, `docs/SHORTCUTS.md`, tests and modified sources.

- [ ] Document independent action editing, AHK v1 requirements, and test/rebuild workflow.
- [ ] Run the full test suite and compare registered chord list with baseline.
- [ ] Upload new action files without replacing existing Drive originals; update existing source/docs files in place using their IDs.
- [ ] Read back changed files and verify Drive layout; report Windows-only validation honestly.

