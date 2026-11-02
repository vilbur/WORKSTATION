# YouTube

**Shortcut:** `Win+Y`  
**Type:** Built-in  
**Entry point:** [`YouTube.ahk`](YouTube.ahk) (AutoHotkey v1.1)

## What it does

Open `https://www.youtube.com/` in a new Google Chrome window on every invocation; existing YouTube windows are not reused.

## Dependencies

Google Chrome (`chrome.exe`) must be launchable.

## Test

Press Win+Y and verify a separate Chrome window opens, even if YouTube is already open.

## Editing

Edit [`YouTube.ahk`](YouTube.ahk) to change this action only. Shared utilities are in [`../../src/Keyboard-Setup-Action-Common.ahk`](../../src/Keyboard-Setup-Action-Common.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
