# Open-Hotstrings

**Shortcut:** `Shift+Win+H`  
**Type:** External wrapper  
**Entry point:** [`Open-Hotstrings.ahk`](Open-Hotstrings.ahk) (AutoHotkey v1.1)

## What it does

Open the existing AutoHotkey hotstrings file via its original script.

## Dependencies

`C:\GoogleDrive\ProgramsData\Core\AutoHotkey\Hotstrings\open-hotstrings-file.ahk`

## Test

Press Shift+Win+H and check that the expected hotstrings file opens.

## Editing

Edit [`Open-Hotstrings.ahk`](Open-Hotstrings.ahk) to change this action only. The wrapper delegates to an original external tool; change that original script for its behavior. Shared dispatch utilities are in [`../../src/Keyboard-Setup-Toolkit-Actions.ahk`](../../src/Keyboard-Setup-Toolkit-Actions.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
