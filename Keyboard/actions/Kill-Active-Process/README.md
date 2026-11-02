# Kill-Active-Process

**Shortcut:** `Win+F4`  
**Type:** External wrapper  
**Entry point:** [`Kill-Active-Process.ahk`](Kill-Active-Process.ahk) (AutoHotkey v1.1)

## What it does

Launch the external script intended to terminate the process owning the active window. Its actual safeguards are defined by that script.

## Dependencies

`C:\GoogleDrive\ProgramsData\Core\Windows\_AhkScripts\kill-process-of-active-window.ahk`

## Test

DANGEROUS: Do not run against active work. Inspect the source and test only with a disposable application.

## Editing

Edit [`Kill-Active-Process.ahk`](Kill-Active-Process.ahk) to change this action only. The wrapper delegates to an original external tool; change that original script for its behavior. Shared dispatch utilities are in [`../../src/Keyboard-Setup-Toolkit-Actions.ahk`](../../src/Keyboard-Setup-Toolkit-Actions.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
