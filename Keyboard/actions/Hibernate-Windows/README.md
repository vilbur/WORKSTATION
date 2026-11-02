# Hibernate-Windows

**Shortcut:** `Ctrl+Win+H`  
**Type:** External wrapper  
**Entry point:** [`Hibernate-Windows.ahk`](Hibernate-Windows.ahk) (AutoHotkey v1.1)

## What it does

Run the existing Windows hibernation batch file.

## Dependencies

`C:\GoogleDrive\ProgramsData\Core\Windows\_AhkScripts\Hibernate-Windows.bat`; Windows hibernation must be enabled.

## Test

SYSTEM STATE CHANGE: Save all work; validate the referenced batch file before an intentional hibernation test.

## Editing

Edit [`Hibernate-Windows.ahk`](Hibernate-Windows.ahk) to change this action only. The wrapper delegates to an original external tool; change that original script for its behavior. Shared dispatch utilities are in [`../../src/Keyboard-Setup-Toolkit-Actions.ahk`](../../src/Keyboard-Setup-Toolkit-Actions.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
