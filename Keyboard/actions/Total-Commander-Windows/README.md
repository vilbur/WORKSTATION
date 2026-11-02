# Total-Commander-Windows

**Shortcut:** `Win+C`  
**Type:** Built-in  
**Entry point:** [`Total-Commander-Windows.ahk`](Total-Commander-Windows.ahk) (AutoHotkey v1.1)

## What it does

Cycle open Total Commander windows in stable window-handle order, or start Total Commander if no window exists.

## Dependencies

Total Commander `TOTALCMD64.EXE` or `TOTALCMD.EXE`.

## Test

Open two Total Commander windows and press Win+C repeatedly; verify cycling.

## Editing

Edit [`Total-Commander-Windows.ahk`](Total-Commander-Windows.ahk) to change this action only. Shared utilities are in [`../../src/Keyboard-Setup-Action-Common.ahk`](../../src/Keyboard-Setup-Action-Common.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
