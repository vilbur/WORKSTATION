# Go-To-Path

**Shortcut:** `Ctrl+Win+C`  
**Type:** External wrapper  
**Entry point:** [`Go-To-Path.ahk`](Go-To-Path.ahk) (AutoHotkey v1.1)

## What it does

Invoke the existing go-to-path helper for Total Commander.

## Dependencies

`D:\GoogleDrive\TotalCommander\_TC-commands\file\go_to_path.ahk`

## Test

With Total Commander available, press Ctrl+Win+C in a harmless folder context and inspect the navigation.

## Editing

Edit [`Go-To-Path.ahk`](Go-To-Path.ahk) to change this action only. The wrapper delegates to an original external tool; change that original script for its behavior. Shared dispatch utilities are in [`../../src/Keyboard-Setup-Toolkit-Actions.ahk`](../../src/Keyboard-Setup-Toolkit-Actions.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
