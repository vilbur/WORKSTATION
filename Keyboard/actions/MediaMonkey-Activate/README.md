# MediaMonkey-Activate

**Shortcut:** `Win+Enter`  
**Type:** External wrapper  
**Entry point:** [`MediaMonkey-Activate.ahk`](MediaMonkey-Activate.ahk) (AutoHotkey v1.1)

## What it does

Activate MediaMonkey using the existing standalone script.

## Dependencies

`M:\MediaMonkey\Ahk\Activate-mediamonkey.ahk`

## Test

Run MediaMonkey, press Win+Enter and confirm its window is activated.

## Editing

Edit [`MediaMonkey-Activate.ahk`](MediaMonkey-Activate.ahk) to change this action only. The wrapper delegates to an original external tool; change that original script for its behavior. Shared dispatch utilities are in [`../../src/Keyboard-Setup-Toolkit-Actions.ahk`](../../src/Keyboard-Setup-Toolkit-Actions.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
