# Google-Search

**Shortcut:** `Win+G`  
**Type:** Built-in  
**Entry point:** [`Google-Search.ahk`](Google-Search.ahk) (AutoHotkey v1.1)

## What it does

Search selected text using Google in Chrome. With no selection, cycle Chrome windows or open Chrome.

## Dependencies

Google Chrome (fallback: default browser).

## Test

Select a harmless phrase in Notepad and press Win+G; then clear the selection and press again.

## Editing

Edit [`Google-Search.ahk`](Google-Search.ahk) to change this action only. Shared utilities are in [`../../src/Keyboard-Setup-Action-Common.ahk`](../../src/Keyboard-Setup-Action-Common.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
