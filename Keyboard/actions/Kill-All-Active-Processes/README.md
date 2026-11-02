# Kill-All-Active-Processes

**Shortcut:** `Ctrl+Win+F4`  
**Type:** External wrapper  
**Entry point:** [`Kill-All-Active-Processes.ahk`](Kill-All-Active-Processes.ahk) (AutoHotkey v1.1)

## What it does

Launch the existing confirmation-driven tool for terminating processes with the same executable name as the active window. It has special 3ds Max restart logic.

## Dependencies

`C:\GoogleDrive\ProgramsData\Core\Windows\_AhkScripts\kill-ALL-PROCESESES-of-active-window.ahk`

## Test

DANGEROUS: Do not run as a casual smoke test. Inspect the original script and test with a disposable process only, after backing up work.

## Editing

Edit [`Kill-All-Active-Processes.ahk`](Kill-All-Active-Processes.ahk) to change this action only. The wrapper delegates to an original external tool; change that original script for its behavior. Shared dispatch utilities are in [`../../src/Keyboard-Setup-Toolkit-Actions.ahk`](../../src/Keyboard-Setup-Toolkit-Actions.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
