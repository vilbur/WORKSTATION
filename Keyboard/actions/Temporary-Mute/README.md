# Temporary-Mute

**Shortcut:** `Win+Pause`  
**Type:** External wrapper  
**Entry point:** [`Temporary-Mute.ahk`](Temporary-Mute.ahk) (AutoHotkey v1.1)

## What it does

Run the MediaMonkey mute launcher, which requests 30 seconds initially or 120 seconds after a quick second invocation.

## Dependencies

`M:\MediaMonkey\Ahk\Mute-Temporary\Mute-Launcher.ahk` and its sibling `mute.ahk`.

## Test

With audio playing, press Win+Pause and verify temporary mute and automatic recovery.

## Editing

Edit [`Temporary-Mute.ahk`](Temporary-Mute.ahk) to change this action only. The wrapper delegates to an original external tool; change that original script for its behavior. Shared dispatch utilities are in [`../../src/Keyboard-Setup-Toolkit-Actions.ahk`](../../src/Keyboard-Setup-Toolkit-Actions.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
