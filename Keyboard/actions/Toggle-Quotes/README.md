# Toggle-Quotes

**Shortcut:** `Ctrl+Shift+'`  
**Type:** Built-in  
**Entry point:** [`Toggle-Quotes.ahk`](Toggle-Quotes.ahk) (AutoHotkey v1.1)

## What it does

Wrap selected text with double quotes, or remove matching outer double quotes.

## Dependencies

English QWERTY apostrophe key (AHK `^+SC028`) and an editable text field.

## Test

Select `hello` in Notepad and press Ctrl+Shift+apostrophe twice; confirm quoted and unquoted results.

## Editing

Edit [`Toggle-Quotes.ahk`](Toggle-Quotes.ahk) to change this action only. Shared utilities are in [`../../src/Keyboard-Setup-Action-Common.ahk`](../../src/Keyboard-Setup-Action-Common.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
