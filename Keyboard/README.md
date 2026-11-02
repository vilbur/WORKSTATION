# Keyboard Manager

**Current UI: v0.32 · Resident launcher: v0.34** · Windows 11 · AutoHotkey v1.1 · HTA interface

<!-- UI SCREENSHOT / GIF PLACEHOLDER: reserved location at the very top of the README. -->
> **UI preview — GIF / screenshot placeholder**  
> When the recording is ready, save it as `docs/keyboard-manager-ui.gif` and replace this block with:  
> `![Keyboard Manager UI](docs/keyboard-manager-ui.gif)`

Keyboard Manager is a Windows resident shortcut launcher with a visual keyboard, searchable hotkey index and a separate read-only **3ds Max** hotkey importer. It shows which shortcuts are active and provides editable file targets for existing resident actions.

## Main features

- **Visual keyboard:** shows assigned shortcuts using coloured key highlights. Hold Ctrl, Shift, Win and Alt (or click their keys to latch them) to show only shortcuts matching the **exact modifier combination**. Releasing all modifiers restores the complete view.
- **Key details:** hover over a key to see each shortcut and its action on a separate line, divided by a blank line. A bottom-centred action panel shows the last recognised action and a short description.
- **One source per application:** *Windows* combines native Windows shortcut references with 21 resident PowerKeys/AHK actions. *3ds Max* shows the effective factory-plus-user shortcut set, with context, Action Table, category and Edit Poly filtering in the Hotkey Index.
- **Individually editable actions:** each of the 21 registered shortcuts launches its own `actions/<Action>/<Action>.ahk` file in a separate AutoHotkey v1.1 process. The 14 imported Toolkit actions are wrappers around their existing external scripts; saved targets can still override actions. Editing a new shortcut in the UI **does not automatically register it globally**.
- **Colour hints:** Ctrl = red, Shift = green, Win = sky blue; Alt alone is white. Each key's accent comes from the modifiers associated with its currently visible shortcuts. The physical keyboard layout stays fixed.
- **Single instance and tray:** one resident process and one window of each UI type. Tray commands: **Open Keyboard Setup**, **Hotkey Index**, **Restart** and **Exit**. Exit closes both UI windows.

## Important shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl+U` | Cycle selected text: uppercase, lowercase and capitalised words |
| `Ctrl+Shift+U` | Cycle naming conventions (`camelCase`, `snake_case`, etc.) |
| `Ctrl+"` | Wrap or unwrap selected text in double quotes |
| `Win+G` | Google search for selected text; otherwise cycle/open Chrome windows |
| `Win+Y` | Open YouTube in a new Chrome window |
| `Win+C` | Cycle/open Total Commander windows |
| `Win+I` | Open a clipboard image/path in IrfanView, or cycle its windows |
| `Win+R` | Run MAXScript from Notepad++ or Komodo in 3ds Max (external script) |
| `Win+Space` | Open/toggle ChatGPT dictation (external script) |
| `Win+Enter` | Activate MediaMonkey (external script) |
| `Win+Pause` | Temporary mute via Mute launcher (external script) |
| `Ctrl+Win+N` | Open a clipboard file in Notepad++ (external script) |
| `Ctrl+Win+C` | Go to path / Total Commander helper (external script) |
| `Win+F` | FocusMe window toggle (external script) |
| `Ctrl+Win+F4` | **Kill all processes of the active app** — destructive; confirmation in supplied script |

The complete **21-hotkey list**, individual action flows and external dependencies are in [`docs/SHORTCUTS.md`](docs/SHORTCUTS.md). Some combinations replace native Windows shortcuts (such as Win+I, Win+R and Win+Space) while the resident launcher captures them. Windows-reserved combinations may not always be intercepted.

## Run and update

1. From the project root, run **`Keyboard-Setup-Launcher.ahk` with AutoHotkey v1.1** (use the v1 interpreter explicitly if v2 is the default). The fallback AHK source is preferable until a matching EXE is rebuilt.
2. Open the main UI from the tray, or run `Keyboard-Setup-Design-Options.hta` directly. Open **Hotkey Index** from the tray or the main UI.
3. For a compiled launcher, run `build\Build-Keyboard-Setup.cmd` on Windows and start the rebuilt `Keyboard-Setup-Launcher.exe`. The Drive EXE may be older than the current AHK source. **The main UI is v0.32; the tray launcher source identifies itself as v0.34.**
4. If a tray change doesn't appear, exit the old resident instance before starting the updated AHK or rebuilt EXE. Simply reopening the HTA cannot change an older resident tray menu.

## 3ds Max importer

From **Import 3ds Max…**, confirm the detected factory `Default.hsxb` and user `.hsx` shortcut files, or browse for them. User-defined assignments override factory defaults in the combined 3ds Max reference. The importer can obtain Action Table metadata through MAXScript using a running matching 3ds Max instance or a one-time startup exporter. Importing **does not register global Windows hotkeys** and does not change 3ds Max's assignments. The bundled snapshot has 575 effective records; actual installed configurations may differ.

## Project files

| Path | Purpose |
|---|---|
| `Keyboard-Setup-Launcher.ahk` | Resident hotkeys and Windows tray menu |
| `actions/<Action>/<Action>.ahk` | One independently editable launch file per registered shortcut (21 total) |
| `Keyboard-Setup-Design-Options.hta` | Main visual keyboard and shortcut editor |
| `src/Keyboard-Setup-Hotkey-Index.hta` | Searchable combined hotkey index |
| `data/Keyboard-Setup-Catalog.js` | Reference names and descriptions for 21 resident actions |
| `data/Keyboard-Setup-Modifier-Colors.js` | Shared shortcut highlight palette |
| `config/` | Saved file overrides and external application paths |
| `import/3DsMax/` | Standalone 3ds Max importer and Action Table exporter |
| `build/` and `tests/` | Windows launcher build and regression tests |

## Edit and test an action (v0.34)

1. Find the matching named folder under `actions/`, e.g. `actions/Google-Search/Google-Search.ahk` for `Win+G`.
2. Edit **only that action file**. The next hotkey press runs its latest contents in a separate process, without restarting the resident launcher. Shared selection/file-launch helpers remain in `src/Keyboard-Setup-Action-Common.ahk` and `src/Keyboard-Setup-Toolkit-Actions.ahk`.
3. For external-tool wrappers, change the literal default file path in that action's `.ahk`. A saved user override in `config/Keyboard-Setup-File-Bindings.ini` still takes priority, followed by the remembered Browse path. The original external script is not copied.
4. Test harmless actions on Windows by running `node tests\Keyboard-Setup-Actions.Tests.js` and then pressing the relevant shortcut. **Do not directly run process-killing or hibernation wrappers as a casual smoke test.**
5. A missing action file produces a tray warning but does not stop the resident. The Windows build script also verifies that all 21 mapped entrypoints exist before compiling. Hotkeys remain defined in the root launcher; changing their keys or the 21 path mappings requires restarting the `.ahk` resident (or rebuilding and restarting the compiled EXE).

The older `src/Keyboard-Setup-Core.ahk` is kept as a compatibility reference; active action-specific transformation algorithms now live in their respective action files. IrfanView stores its last cycling HWND under the Windows temporary directory so its window cycle survives separate action launches.

## Documentation and tests

See [`CHANGELOG.md`](CHANGELOG.md) for version history, [`docs/SHORTCUTS.md`](docs/SHORTCUTS.md) for action details and [`design.md`](design.md) for technical design decisions.

Run the relevant regression tests from the project root:

```bat
node tests\Keyboard-Setup-UI.Tests.js
node tests\Keyboard-Setup-Modifier-RGB.Tests.js
node tests\Keyboard-Setup-Resident.Tests.js
node tests\Keyboard-Setup-Actions.Tests.js
```

Native Windows tray/HTA behaviour and 3ds Max integration should be checked locally; the JavaScript source tests alone do not validate those integrations.

## v0.32 keyboard geometry

The top Print Screen, Scroll Lock and Pause keys now align directly over
Insert, Home and Page Up. The middle navigation/arrow-key block has approximately
half a standard key of clear space on either side, between the typing block
and numpad. Key dimensions, colours, hotkeys and the resident launcher remain
unchanged. Reopen `Keyboard-Setup-Design-Options.hta` after Drive synchronises.

Test: `node tests\Keyboard-Setup-UI.Tests.js`.


## v0.33 — prevent Game Bar from receiving Win+G

The resident AutoHotkey **v1.1** launcher now forces **all of its Win-key
shortcuts** through `#UseHook On` / `#UseHook Off` rather than Windows'
`RegisterHotkey()` registration method. This avoids losing `Win+G` to the
Xbox Game Bar registration on systems where the OS shortcut has already
reserved the chord. No hotkey has a `~` pass-through prefix. The existing
`Win+G` action is unchanged: search the selected text in Chrome, otherwise
cycle/open Chrome. Other custom Win-key actions remain unchanged.

**Activation matters:** editing the HTA does not update a resident AHK process
or a compiled executable. Exit the **old** tray instance, run the updated
`Keyboard-Setup-Launcher.ahk` with AutoHotkey v1.1, then verify the tray tooltip
reads `Keyboard Setup v0.33`. Alternatively, rebuild the EXE on Windows using
`build\Build-Keyboard-Setup.cmd` and start the newly compiled binary.

Verify actual interception with `powershell -NoProfile -ExecutionPolicy Bypass
-File tests\Keyboard-Setup-WinG-Smoke.ps1`. It waits for a physical `Win+G`
press and checks the new event written by the resident. Test that Chrome runs
and the Xbox Game Bar **does not** open. This is a Windows-only manual/runtime
check; source tests cannot prove that the OS delivers the keystroke to AHK.
If Game Bar still opens, first check the tray version and whether another
AHK/Toolkit or keyboard remapper is handling the same chord. A Windows-reserved
shortcut may still take precedence; the tool does not change Game Bar or
registry settings automatically.
