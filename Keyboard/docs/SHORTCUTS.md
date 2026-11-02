# Keyboard Manager — shortcut reference

**Source:** current `data/Keyboard-Setup-Catalog.js` (21 registered resident shortcuts: 7 built-in and 14 external Toolkit actions). This file documents the currently registered shortcuts, not every standard Windows shortcut. File overrides can change the action actually executed.

**v0.34 execution layout:** each row below has a separate `actions/<Action>/<Action>.ahk` launch file. All 21 files are directly editable, and the next shortcut press starts a fresh AHK v1 process. For built-ins, the action file contains its behavior; for external rows, the action file is an individually editable wrapper around the original target script. The resident handles only shortcut registration and launch dispatch.

## All registered shortcuts

| Shortcut | Action | What it does | Handler |
|---|---|---|---|
| `Win+G` | Google search / Chrome windows | Search selected text with Google; otherwise cycle Chrome windows or start Chrome. | Built-in |
| `Ctrl+Shift+U` | Cycle naming convention | Cycle eight naming styles for selected text or the word at the caret. | Built-in |
| `Ctrl+U` | Upper / lower / Capital | Change selected text between uppercase, lowercase and capitalised words. | Built-in |
| `Ctrl+Shift+'` | Wrap / unwrap double quotes | Wrap selected text in double quotes or remove matching outer quotes. | Built-in |
| `Win+Y` | YouTube window | Always open the YouTube homepage in a new Google Chrome window. | Built-in |
| `Win+I` | IrfanView image | Open a clipboard image or image path; otherwise cycle IrfanView windows. | Built-in |
| `Win+C` | Total Commander windows | Cycle Total Commander windows or start the application. | Built-in |
| `Win+F` | FocusMe window toggle | Run the existing FocusMe window toggle script. | External script |
| `Ctrl+Win+N` | Open clipboard file in Notepad++ | Run the existing script for opening specific file types from the clipboard in Notepad++. | External script |
| `Ctrl+Win+F4` | Kill all active-window processes | Ask before terminating every process with the active window process name. For 3dsmax.exe, resolve its executable and optionally restart it elevated after successful termination. This destructive operation is implemented by the original script, which requires confirmation. | External script |
| `Win+Space` | ChatGPT dictate mode | Run the existing ChatGPT launcher / dictation toggle script. | External script |
| `Shift+Win+H` | Open hotstrings file | Run the existing hotstrings file opener. | External script |
| `Win+T` | Total Commander activate | Run the existing Total Commander activation script. | External script |
| `Win+F4` | Kill active-window process | Run the existing script for ending the active window process. Confirm its actual safeguards in the external file. | External script |
| `Ctrl+Win+H` | Hibernate Windows | Run the existing Windows hibernation batch file. | External script |
| `Win+Pause` | Mute launcher | Run Mute-Launcher.ahk: first press starts 30-second mute; a second launch within about two seconds requests 120 seconds. That script calls its adjacent mute.ahk dependency. | External script |
| `Win+M` | Suspend key (no action) | Run the existing SuspendKey-DoNothing script. The script internals were not supplied. | External script |
| `Ctrl+Shift+Win+F` | FocusMe window toggle | Run the same FocusMe window toggle script as Win+F. | External script |
| `Ctrl+Win+C` | Go to path | Run the existing go_to_path script. | External script |
| `Win+Enter` | Activate MediaMonkey | Run the existing MediaMonkey activation script. | External script |
| `Win+R` | Run MAXScript from editor | Find the current .ms/.mcr in Notepad++ or .ms in Komodo, save modified Komodo content and send fileIn to the 3ds Max MAXScript Listener. Original script requires the appropriate editor and Listener control. | External script |

**Important:** `Ctrl+Win+F4` and `Win+F4` can terminate processes; `Ctrl+Win+H` hibernates Windows. External scripts may require installed applications or valid paths. Several resident Win-key shortcuts replace Windows defaults while the launcher is running.

## Built-in action details

An existing *FILE TO RUN* assignment for the matching built-in hotkey takes precedence. For each hotkey below, the first steps are:

1. Read `[Files]` in `config/Keyboard-Setup-File-Bindings.ini` for this exact shortcut.
2. If a nonempty target exists on disk, execute that target **instead of** the built-in action; stop.
3. If the target is missing or cannot be launched, display a tray warning and execute the built-in fallback below.

### Upper / lower / Capital

**Shortcut:** `Ctrl+U`

1. Wait for shortcut modifiers to be released.
2. Back up the entire clipboard; copy highlighted text using Ctrl+C.
3. If no text is selected, make no edit. Otherwise:
   - If the selection is all uppercase, change to `lowercase`.
   - Else, if all lowercase, change to `Capital` (title case).
   - Else, change to `UPPERCASE`.
   - If there are no letters, leave the text untouched.
4. Paste the result only when changed; restore the original clipboard.

### Cycle naming convention

**Shortcut:** `Ctrl+Shift+U`

1. Back up the clipboard and copy selected text.
2. If nothing is selected, attempt to select the word under the caret with Ctrl+Left, Ctrl+Shift+Right and copy again.
3. For every nonempty line: recognise the existing convention, split it into words, advance to the next style, then rejoin. Preserve line breaks.
4. Cycle: `lowercase` → `Capital` → `UPPERCASE` → `PascalCase` → `camelCase` → `snake_case_low` → `Snake_Case_Capital` → `SNAKE_CASE_UPPER` → `lowercase`.
5. Unknown input styles start at lowercase. Paste only changed text; restore clipboard.

### Wrap / unwrap double quotes

**Shortcut:** `Ctrl+"`

*Physical key:* Ctrl+Shift+apostrophe (`^+SC028`) on English QWERTY.

1. Back up clipboard and copy the selected text. If nothing selected, do nothing.
2. If first and last characters are matching double quotes, remove them; otherwise enclose the text in double quotes.
3. Paste the result and restore clipboard.

### YouTube window

**Shortcut:** `Win+Y`

1. Start `chrome.exe` with `--new-window` and the URL `https://www.youtube.com/`.
2. Always request a new Chrome window, even if YouTube is already open in another window or tab.
3. If Chrome cannot start, display a tray warning. Do not switch to an existing browser window or open a tab in the default browser.

### Total Commander windows

**Shortcut:** `Win+C`

1. Find Total Commander top-level windows (`TTOTAL_CMD`).
2. If found, sort their window handles and activate the one after the active window; wrap to the first after the last.
3. If none found, try `TOTALCMD64.EXE`, then `TOTALCMD.EXE`.
4. If neither can start, show a tray warning.

### Google search / Chrome windows

**Shortcut:** `Win+G`

1. Back up clipboard and read highlighted text without permanently changing clipboard.
2. If nonblank text is selected, UTF-8 URL-encode it and open `https://www.google.com/search?q=...` in Chrome; fall back to the default browser if necessary.
3. Otherwise cycle Chrome windows by handle order, or launch Chrome if none exists; if Chrome is not found, open Google in the default browser.

### IrfanView image

**Shortcut:** `Win+I`

1. Inspect the clipboard **without replacing it**. If it contains a bitmap/DIB, enhanced metafile, or PNG image, treat it as an image.
2. Otherwise check for a single existing image path copied as text or as a file in Windows Explorer. Ignore non-image files, directories, and invalid paths.
3. **If neither clipboard image nor image path exists**, enumerate visible top-level IrfanView windows from both `i_view64.exe` and `i_view32.exe`. Ignore owned pop-up dialogs. If exactly one window exists, restore it if minimised and activate it. If multiple windows exist, cycle in stable window-handle order on successive Win+I presses, remembering the last window if focus moves elsewhere. The clipboard is untouched.
4. If there are **no** IrfanView windows to activate and nothing image-related is on the clipboard, show the original brief tray notification. Do not open a Browse dialog or launch an empty editor for this case.
5. **If an image or image path exists**, locate IrfanView using the previously chosen executable in `config/Keyboard-Setup-Applications.ini`, Windows App Paths registration, or standard `Program Files` locations (64-bit and 32-bit).
6. If IrfanView cannot be located in this image-opening case, show a **Browse** file-selection dialog for `i_view64.exe` or `i_view32.exe`. Save the valid chosen executable for future use; Cancel stops the action.
7. For clipboard image contents, open IrfanView with **`/clippaste`**. For an image-file path, open the file directly (no clipboard conversion). If launching fails, show an error.

**Note:** While Keyboard Manager runs, `Win+I` replaces the standard Windows Settings shortcut. The source launcher must be restarted to enable this action, and the older EXE must be rebuilt. Clipboard-path mode opens the file, rather than converting it to bitmap.


## External script actions and file targets

The 14 Toolkit entries launch existing scripts/batch files through named `.ahk` wrappers in `actions/`; their configured paths can be edited in Keyboard Manager. Each wrapper contains its own executable default path; `data/Keyboard-Setup-Catalog.js` retains the UI reference and summary. If a script is missing, Keyboard Manager asks you to browse to its location and saves it in `config/Keyboard-Setup-Toolkit-Paths.ini`.

The external script sources are not embedded in Keyboard Manager. For example, the MAXScript action requires a compatible editor and 3ds Max; the Mute launcher depends on its sibling `mute.ahk` file. Keep the external scripts in working folders and test them before relying on them.

## Execution priorities

1. A configured *FILE TO RUN* override for a registered shortcut takes precedence if the target is available.
2. Otherwise the registered built-in handler or Toolkit external-script handler runs.
3. Unregistered combinations displayed in the editor remain previews only, not new global hotkeys.

For releases and changes, see [`../CHANGELOG.md`](../CHANGELOG.md).
