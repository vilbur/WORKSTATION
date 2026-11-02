# Cycle-Naming-Convention

**Shortcut:** `Ctrl+Shift+U`  
**Type:** Built-in  
**Entry point:** [`Cycle-Naming-Convention.ahk`](Cycle-Naming-Convention.ahk) (AutoHotkey v1.1)

## What it does

Convert selected text or the word at the caret through eight naming conventions, including PascalCase, camelCase and snake_case. Preserves line breaks.

## Dependencies

An editable text field that supports standard selection and paste.

## Test

In Notepad, select `hello world`, press Ctrl+Shift+U and check the converted text and restored clipboard.

## Editing

Edit [`Cycle-Naming-Convention.ahk`](Cycle-Naming-Convention.ahk) to change this action only. Shared utilities are in [`../../src/Keyboard-Setup-Action-Common.ahk`](../../src/Keyboard-Setup-Action-Common.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
