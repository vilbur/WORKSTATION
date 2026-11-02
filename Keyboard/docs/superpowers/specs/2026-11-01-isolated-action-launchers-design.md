# Isolated action launchers — design

## Intent

Keyboard Manager currently contains seven built-in action implementations in the resident AHK v1 launcher, while fourteen Toolkit actions are launched directly from paths held in a shared library. Make every one of the 21 resident shortcut actions independently inspectable and editable, without changing the hotkey registration code or risking the resident process when an action fails.

## Requirements

- Preserve the currently registered 21 chords and the event notification sent by the resident.
- Give each chord one named project-local `actions/<Action>/<Action>.ahk` entrypoint. The file is invoked in a separate AutoHotkey v1.1 process on every activation; editing it takes effect on the next press.
- Move built-in behavior into the appropriate action script; keep truly shared helpers in `src` and pure transformation functions in the existing `Keyboard-Setup-Core.ahk`.
- For the fourteen external Toolkit actions, keep their external scripts as the source of truth; wrappers provide individually editable paths and call the current shared resolver for user overrides, remembered paths, missing-file Browse, and interpreter selection.
- The resident retains mutex/tray/UI/3ds Max importer, event publishing, hotkey definitions, and configuration dispatch. A bad or missing action file emits a diagnostic but does not crash or exit the resident.
- Retain the existing UI's editable file bindings, including override priority for built-in and Toolkit actions.
- Do not change the physical keyboard UI, palette, or 3ds Max importer.
- No executable rebuild in this Linux environment; Windows AutoHotkey v1.1 and native integration tests remain necessary.

## Approaches

1. **Chosen: independent processes with one `.ahk` per action.** Safest for incremental edits, straightforward to inspect, and changes take effect without resident restart; each launch has small process startup overhead.
2. Include separate action `.ahk` files in the resident. Fast dispatch, but a syntax/runtime error could destabilize all shortcuts and edits need a resident restart.
3. Copy all original Toolkit scripts into this project. Self-contained, but duplicate copies would diverge from existing tools; rejected in favor of wrappers.

## Implementation outline

- Resident maps a canonical chord to an action-relative path, applies the existing explicit user file override if present, then launches the local action with the explicit AHK v1 interpreter. The internal hotkey declarations become one call to `keyboardLaunchAction(chord)` each.
- Wrapper entrypoints for external actions declare the chord and default target and use shared Toolkit action resolution/launch logic. Missing targets are handled in the wrapper process; cancellation does not alter hotkey bindings.
- Built-in action entrypoints use their original algorithms and selectively include shared `src/Keyboard-Setup-Core.ahk` or common routines. Clipboard handling and modifier release must remain functionally equivalent.
- Node.js source-regression tests verify all 21 dispatch entries, one file per chord, valid paths, preserved overrides, an isolated process launch, and absence of action logic in the resident. Existing tests must continue to pass or be updated to assert the equivalent new architecture.

## Risks and mitigations

- AutoHotkey v2 may be the default association: launch every action via resolved v1 interpreter rather than shell file association.
- Compiled resident has no AHK interpreter built in for external scripts: use the existing resolver and prompt if necessary; do not run an `.ahk` with the compiled EXE.
- A held Ctrl/Shift/Win key can affect actions using `Send`: preserve modifier-release waiting in the action scripts.
- A missing action entrypoint should show a tray diagnostic; it must not silently invoke a different action.
- Per-action wrappers do not sandbox inherently destructive external scripts; keep their confirmation and original external behavior intact.

