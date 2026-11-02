# Notepad-Clipboard-File

**Shortcut:** `Ctrl+Win+N`  
**Type:** External wrapper  
**Entry point:** [`Notepad-Clipboard-File.ahk`](Notepad-Clipboard-File.ahk) (AutoHotkey v1.1)

## What it does

Call the existing script that opens supported file paths from the clipboard in Notepad++.

## Dependencies

`C:\GoogleDrive\ProgramsData\Core\Notepad++\AHK\Open-specific-file-types-from-clipboard-in-Notepad.ahk`

## Test

Copy a known text-file path, press Ctrl+Win+N and confirm it opens in Notepad++.

## Editing

Edit [`Notepad-Clipboard-File.ahk`](Notepad-Clipboard-File.ahk) to change this action only. The wrapper delegates to an original external tool; change that original script for its behavior. Shared dispatch utilities are in [`../../src/Keyboard-Setup-Toolkit-Actions.ahk`](../../src/Keyboard-Setup-Toolkit-Actions.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
