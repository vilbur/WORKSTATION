# Suspend-Key

**Shortcut:** `Win+M`  
**Type:** External wrapper  
**Entry point:** [`Suspend-Key.ahk`](Suspend-Key.ahk) (AutoHotkey v1.1)

## What it does

Run the external no-op/suspend-key script instead of the Windows default minimize-all command.

## Dependencies

`C:\GoogleDrive\ProgramsData\Core\AutoHotkey\Lib\Window\SuspendKey-DoNothing.ahk`

## Test

Press Win+M and check that the expected suppression behavior occurs; actual internals belong to the external file.

## Editing

Edit [`Suspend-Key.ahk`](Suspend-Key.ahk) to change this action only. The wrapper delegates to an original external tool; change that original script for its behavior. Shared dispatch utilities are in [`../../src/Keyboard-Setup-Toolkit-Actions.ahk`](../../src/Keyboard-Setup-Toolkit-Actions.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
