# FocusMe-Window

**Shortcut:** `Win+F`  
**Type:** External wrapper  
**Entry point:** [`FocusMe-Window.ahk`](FocusMe-Window.ahk) (AutoHotkey v1.1)

## What it does

Toggle the FocusMe application window by calling the existing FocusMe script.

## Dependencies

`C:\GoogleDrive\ProgramsData\Core\FocusMe\Ahk\Focusme-Window-Toggle.ahk`

## Test

With FocusMe installed, press Win+F and verify its window toggles.

## Editing

Edit [`FocusMe-Window.ahk`](FocusMe-Window.ahk) to change this action only. The wrapper delegates to an original external tool; change that original script for its behavior. Shared dispatch utilities are in [`../../src/Keyboard-Setup-Toolkit-Actions.ahk`](../../src/Keyboard-Setup-Toolkit-Actions.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
