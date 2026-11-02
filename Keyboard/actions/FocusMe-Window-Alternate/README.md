# FocusMe-Window-Alternate

**Shortcut:** `Ctrl+Shift+Win+F`  
**Type:** External wrapper  
**Entry point:** [`FocusMe-Window-Alternate.ahk`](FocusMe-Window-Alternate.ahk) (AutoHotkey v1.1)

## What it does

Alternative shortcut for the same FocusMe window-toggle script used by Win+F.

## Dependencies

`C:\GoogleDrive\ProgramsData\Core\FocusMe\Ahk\Focusme-Window-Toggle.ahk`

## Test

With FocusMe installed, press Ctrl+Shift+Win+F and verify its window toggles.

## Editing

Edit [`FocusMe-Window-Alternate.ahk`](FocusMe-Window-Alternate.ahk) to change this action only. The wrapper delegates to an original external tool; change that original script for its behavior. Shared dispatch utilities are in [`../../src/Keyboard-Setup-Toolkit-Actions.ahk`](../../src/Keyboard-Setup-Toolkit-Actions.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
