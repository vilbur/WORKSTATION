# Total-Commander-Activate

**Shortcut:** `Win+T`  
**Type:** External wrapper  
**Entry point:** [`Total-Commander-Activate.ahk`](Total-Commander-Activate.ahk) (AutoHotkey v1.1)

## What it does

Activate Total Commander using the existing standalone activation script.

## Dependencies

`D:\GoogleDrive\TotalCommander\_TC-commands\TC-Acivate.ahk`

## Test

With Total Commander installed, press Win+T and confirm the expected window becomes active.

## Editing

Edit [`Total-Commander-Activate.ahk`](Total-Commander-Activate.ahk) to change this action only. The wrapper delegates to an original external tool; change that original script for its behavior. Shared dispatch utilities are in [`../../src/Keyboard-Setup-Toolkit-Actions.ahk`](../../src/Keyboard-Setup-Toolkit-Actions.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
