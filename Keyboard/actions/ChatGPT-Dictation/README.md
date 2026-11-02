# ChatGPT-Dictation

**Shortcut:** `Win+Space`  
**Type:** External wrapper  
**Entry point:** [`ChatGPT-Dictation.ahk`](ChatGPT-Dictation.ahk) (AutoHotkey v1.1)

## What it does

Open ChatGPT and toggle its dictation mode using the existing external script.

## Dependencies

`C:\GoogleDrive\ProgramsData\Core\ChatGPT\ahk\run-chat-and-start-or-stop-dictate-mode.ahk`

## Test

With ChatGPT installed, press Win+Space and verify the expected dictation toggle.

## Editing

Edit [`ChatGPT-Dictation.ahk`](ChatGPT-Dictation.ahk) to change this action only. The wrapper delegates to an original external tool; change that original script for its behavior. Shared dispatch utilities are in [`../../src/Keyboard-Setup-Toolkit-Actions.ahk`](../../src/Keyboard-Setup-Toolkit-Actions.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
