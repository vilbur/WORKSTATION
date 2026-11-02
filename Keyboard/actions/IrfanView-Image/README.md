# IrfanView-Image

**Shortcut:** `Win+I`  
**Type:** Built-in  
**Entry point:** [`IrfanView-Image.ahk`](IrfanView-Image.ahk) (AutoHotkey v1.1)

## What it does

Open an image or image-file path from the clipboard in IrfanView. Without either, cycle existing IrfanView windows.

## Dependencies

IrfanView 32-bit or 64-bit; optional remembered executable in `config/Keyboard-Setup-Applications.ini`.

## Test

Copy an image file in Explorer and press Win+I. Then clear the clipboard and test cycling two IrfanView windows.

## Editing

Edit [`IrfanView-Image.ahk`](IrfanView-Image.ahk) to change this action only. Shared utilities are in [`../../src/Keyboard-Setup-Action-Common.ahk`](../../src/Keyboard-Setup-Action-Common.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
