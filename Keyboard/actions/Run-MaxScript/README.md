# Run-MaxScript

**Shortcut:** `Win+R`  
**Type:** External wrapper  
**Entry point:** [`Run-MaxScript.ahk`](Run-MaxScript.ahk) (AutoHotkey v1.1)

## What it does

Send the current MAXScript from Komodo or Notepad++ to 3ds Max through the existing editor-to-MAXScript-Listener helper.

## Dependencies

`C:\Users\vilbur\AppData\Local\ActiveState\KomodoIDE\12.0\tools\Scripts\3Ds Max\runMaxScript\run-maxscript-via-notepad-komodo.ahk`; compatible editor and 3ds Max Listener.

## Test

Open a harmless test `.ms` in your editor, activate 3ds Max and press Win+R. Confirm execution in the Listener.

## Editing

Edit [`Run-MaxScript.ahk`](Run-MaxScript.ahk) to change this action only. The wrapper delegates to an original external tool; change that original script for its behavior. Shared dispatch utilities are in [`../../src/Keyboard-Setup-Toolkit-Actions.ahk`](../../src/Keyboard-Setup-Toolkit-Actions.ahk). Changes to this action file take effect the next time its shortcut runs; editing the shortcut registration itself requires a resident restart. A configured `FILE TO RUN` override can take priority over this file.

See the [project README](../../README.md) and [shortcut reference](../../docs/SHORTCUTS.md).
