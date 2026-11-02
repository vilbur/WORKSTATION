const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source_path = path.join(__dirname, '..', 'Keyboard-Setup-Launcher.ahk');
const source = fs.readFileSync(source_path, 'utf8');

function testSingleResidentInstance()
{
  assert.match(source, /^#SingleInstance Off\s*$/m,
    'AHK built-in per-file guard is disabled in favor of cross-build named mutex');
  assert.match(source, /Local\\KeyboardSetup_Resident_8A2DE942/,
    'source and compiled EXE acquire the same OS mutex');
  assert.match(source, /kernel32\\CreateMutexW/, 'unicode named mutex uses kernel32 and remains alive for the resident lifetime');
  assert.match(source, /error_code == 183/, 'existing mutex is rejected');
  assert.match(source, /keyboard_resident_has_mutex := keyboardAcquireResidentMutex\(\)/,
    'mutex is acquired before setting up tray or global shortcuts');
  assert.match(source, /if \(!keyboard_resident_has_mutex\)/,
    'any non-owner leaves before registering hotkeys');
  assert.match(source, /^#Requires AutoHotkey v1\.1\s*$/m, 'force v1 runtime when both versions are installed');
  assert.match(source, /keyboard_project_dir := A_ScriptDir/, 'root launcher resolves UI and importer relative to project root');
  assert.doesNotMatch(source, /#Include %A_ScriptDir%\\src\\Keyboard-Setup-Core\.ahk/, 'text helpers belong to action processes');
  assert.match(source, /#Include %A_ScriptDir%\\import\\3DsMax\\3DsMax-Importer\.ahk/, 'root AHK resolves importer');
  assert.match(source, /^#Persistent\s*$/m,
    'The launcher must remain resident after startup');
  assert.match(source, /ExitApp/, 'duplicate launcher must terminate immediately');
}

function testTrayLeftClickOpensEditor()
{
  assert.match(source, /Menu, Tray, Click, 1/,
    'One left-click must activate the default tray command');
  assert.match(source, /Menu, Tray, Default, Open Keyboard Setup/,
    'Opening the editor must be the default tray command');
  assert.match(source, /Menu, Tray, Add, Open Keyboard Setup, openKeyboardSetup/,
    'Opening the editor must also be available in the standard context menu');
  assert.match(source, /Menu, Tray, NoStandard/,
    'The product tray is explicitly defined rather than relying on default AHK entries');
}

function testStartupShortcutTargetsResidentScript()
{
  assert.match(source, /A_Startup\s*\.\s*"\\Keyboard-Setup\.lnk"/,
    'Startup must be installed in the current user’s Windows Startup folder');
  assert.match(source, /A_IsCompiled/,
    'The compiled EXE and AHK source must both be supported');
  assert.match(source, /A_ScriptFullPath/,
    'Startup must target the launched manager, not mshta.exe');
  assert.match(source, /A_AhkPath/,
    'Source mode must explicitly use the v1 interpreter to avoid v2 associations');
  assert.doesNotMatch(source, /^\s*function\s+\w+\(/m,
    'AutoHotkey v1 function declarations do not use a function keyword');
  assert.match(source, /^ensureWindowsStartup\(\)\s*$/m,
    'The helper must use AutoHotkey v1 function declaration syntax');
}

function testEditorOpenKeepsResidentAlive()
{
  assert.match(source, /^openKeyboardSetup:\s*$/m);
  assert.match(source, /^openHotkeyIndex:\s*$/m);
  assert.match(source, /keyboardOpenSingleUi\("editor"\)/, 'tray routes editor through singleton controller');
  assert.match(source, /keyboardOpenSingleUi\("index"\)/, 'tray routes index through same controller');
  assert.match(source, /keyboardFindSetupWindow\(\)/, 'search existing editor before launching');
  assert.match(source, /keyboardFindHotkeyIndexWindow\(\)/, 'search existing index before launching');
  assert.match(source, /WinGet, window_count, List, ahk_exe mshta\.exe/, 'search mshta window titles');
  assert.match(source, /HTML Application Host Window Class/, 'fallback to HTA window class');
  assert.match(source, /keyboardIsUiTitle\(title, ui_kind\)/, 'native window matches each UI type separately');
  assert.match(source, /A_TickCount - last_start < 4000/, 'debounce mshta startup handoff');
  assert.match(source, /Process, Exist, %pending_pid%/, 'while launch host is alive, never start another');
  assert.match(source, /WinRestore/, 'activate minimised UI');
  assert.match(source, /WinActivate/, 'focus preexisting UI');
  assert.match(source, /Critical, On/, 'serialize tray clicks');
  assert.match(source, /if \(ui_kind == "index"\)/, 'index and editor use independent per-kind pending PID');
  assert.match(source, /ExitApp/, 'duplicate resident exits');
}

testSingleResidentInstance();
testTrayLeftClickOpensEditor();
testStartupShortcutTargetsResidentScript();
testEditorOpenKeepsResidentAlive();
console.log('PASS: resident instance, tray left/right click, Windows startup, editor activation');

assert.match(source, /Menu, Tray, Add, Hotkey Index, openHotkeyIndex/, "tray opens Hotkey Index");
assert.match(source, /^openHotkeyIndex:\s*$/m, "separate index launch handler");
assert.match(source, /keyboardFindHotkeyIndexWindow\(\)/, "reuse existing index UI");
assert.match(source, /keyboard_last_index_pid/, "debounce index launches");
assert.match(source, /keyboardActivateUiWindow\(already_open_hwnd\)/, 'duplicate process restores an existing editor or index');

// AHK v1 requires block-comment delimiters on their own lines.
// A malformed `/* Description ... */` may swallow following functions/hotkeys
// without showing a syntax error, leading to "Call to nonexistent function".
function visibleAhkSource(filename) {
  const content = fs.readFileSync(filename, 'utf8');
  let inBlock = false;
  const visible = [];
  content.split(/\r?\n/).forEach((line, i) => {
    const trimmed = line.trim();
    if (trimmed.startsWith('/*')) {
      assert.equal(trimmed, '/*', `${filename}:${i + 1}: block comment opener must be alone`);
      assert.equal(inBlock, false, `${filename}:${i + 1}: nested comment`);
      inBlock = true;
    } else if (trimmed.startsWith('*/')) {
      assert.equal(trimmed, '*/', `${filename}:${i + 1}: block comment closer must be alone`);
      assert.equal(inBlock, true, `${filename}:${i + 1}: stray closer`);
      inBlock = false;
    } else if (!inBlock) {
      visible.push(line);
    }
  });
  assert.equal(inBlock, false, `${filename}: unterminated block comment`);
  return visible.join('\n');
}

const residentVisible = visibleAhkSource(source_path);
const toolkitVisible = visibleAhkSource(path.join(__dirname, '..', 'src', 'Keyboard-Setup-Toolkit-Actions.ahk'));
visibleAhkSource(path.join(__dirname, '..', 'src', 'Keyboard-Setup-Core.ahk'));
visibleAhkSource(path.join(__dirname, '..', 'src', 'Keyboard-Setup-Action-Common.ahk'));
visibleAhkSource(path.join(__dirname, '..', 'import', '3DsMax', '3DsMax-Importer.ahk'));
for (const functionName of ['keyboardFindUiWindow', 'keyboardIsUiTitle', 'keyboardFindHotkeyIndexWindow', 'keyboardFindSetupWindow', 'keyboardLaunchAction', 'keyboardActionRelativePath']) {
  assert.match(residentVisible, new RegExp('^' + functionName + '\\([^\\n]*\\)\\s*\\n\\{', 'm'), `Function ${functionName} must be visible to AHK v1`);
}
const irfanVisible = visibleAhkSource(path.join(__dirname, '..', 'actions', 'IrfanView-Image', 'IrfanView-Image.ahk'));
for (const functionName of ['keyboardClipboardHasImage', 'keyboardClipboardImagePath', 'keyboardBrowseIrfanView']) {
  assert.match(irfanVisible, new RegExp('^' + functionName + '\\([^\\n]*\\)\\s*\\n\\{', 'm'), `Action function ${functionName} must be visible to AHK v1`);
}
for (const functionName of ['keyboardRunToolkitAction', 'keyboardToolkitV1Interpreter']) {
  assert.match(toolkitVisible, new RegExp('^' + functionName + '\\([^\\n]*\\)\\s*\\n\\{', 'm'), `Toolkit function ${functionName} must be visible to AHK v1`);
}
const action_dirs = fs.readdirSync(path.join(__dirname, '..', 'actions'), { withFileTypes: true }).filter(x => x.isDirectory());
for (const action_dir of action_dirs) visibleAhkSource(path.join(__dirname, '..', 'actions', action_dir.name, action_dir.name + '.ahk'));
for (const chord of ['#f', '^#n', '^#F4', '#Space', '+#h', '#t', '#F4', '^#h', '#Pause', '#m', '^+#f', '^#c', '#Enter', '#r']) {
  assert.ok(residentVisible.includes('\n' + chord + '::'), `${chord} must not be in a block comment`);
}
console.log('PASS: AHK v1 block-comment validity, resident UI and standalone action functions.');

// v0.21: AHK should swallow captured user-defined Windows chords and never pass them through.
// Do not change resident handlers into ~hotkeys, which would fire the native Windows action too.
for (const line of residentVisible.split(/\r?\n/)) {
  if (/^\s*[~][^;]*::/.test(line)) {
    assert.fail('Passthrough hotkey would also dispatch native Windows shortcut: ' + line);
  }
}
for (const chord of ['#i', '#r', '#Space', '#t', '#m', '#Pause', '#g', '#c', '#y', '^#F4']) {
  assert.ok(residentVisible.split(/\r?\n/).some(line => line.trim() === chord + '::'), chord + ' must remain handled without passthrough');
}
console.log('PASS: Win+I / Win+R / Win+Space and other intercepted chords do not explicitly pass through to Windows.');

// v0.26: safe restart hand-off and canonical script/EXE launch.
assert.match(residentVisible, /Menu, Tray, Add, Restart, restartKeyboardSetup/, 'restart item in tray');
assert.match(residentVisible, /^restartKeyboardSetup:\s*$/m, 'restart menu handler exists');
assert.match(residentVisible, /^keyboardRestartResident\(\)\s*\n\{/m, 'restart function remains visible to AHK v1');
assert.match(residentVisible, /A_IsCompiled[\s\S]*A_AhkPath[\s\S]*A_ScriptFullPath/, 'restart supports EXE and interpreted AHK');
assert.match(residentVisible, /--keyboard-restart/, 'child receives restart handoff marker');
assert.match(residentVisible, /keyboard_resident_has_mutex := keyboardAcquireResidentMutex\(\)[\s\S]*Sleep, 250[\s\S]*keyboard_resident_has_mutex := keyboardAcquireResidentMutex\(\)/, 'new process waits for old mutex release');
assert.match(residentVisible, /keyboardRestartResident\(\)[\s\S]*?ExitApp/, 'old process exits gracefully after spawning child');
assert.match(residentVisible, /OnExit\("keyboardCloseUiOnExit"\)/, 'restart closes both owned UIs through existing exit handler');
console.log('PASS: tray Restart handoff, cross-build re-execution, mutex release wait, and UI cleanup.');

// v0.30: make Restart visible in a separate group and identify stale EXE builds.
assert.match(residentVisible, /Menu, Tray, Add, Hotkey Index, openHotkeyIndex\s*\nMenu, Tray, Add\s*\nMenu, Tray, Add, Restart, restartKeyboardSetup/,
  'tray Restart appears in a distinct menu section');
assert.match(residentVisible, /Menu, Tray, Tip, Keyboard Setup v0\.34/,
  'versioned tray tooltip reveals whether the launcher has been updated');
console.log('PASS: grouped Restart menu command and source-version tray tip.');


/* v0.30: deterministic tray menu, explicitly not the implicit AutoHotkey default. */
assert.match(residentVisible, /Menu, Tray, NoStandard/, 'standard menu is disabled to avoid hidden Restart');
assert.match(residentVisible, /Menu, Tray, DeleteAll/, 'stale menu entries cleared first');
assert.match(residentVisible, /Menu, Tray, Add, Restart, restartKeyboardSetup\s*\nMenu, Tray, Add\s*\nMenu, Tray, Add, Exit, keyboardExitResident/, 'Restart and Exit are explicit commands');
assert.match(residentVisible, /^keyboardExitResident:\s*\nExitApp\s*\nreturn/m, 'Exit uses standard AHK exit lifecycle');
assert.match(residentVisible, /Menu, Tray, Tip, Keyboard Setup v0\.34/, 'tray tooltip identifies the current resident build');
console.log('PASS: deterministic Restart and Exit tray menu, versioned runtime indicator and singleton hand-off.');


/* v0.33: hotkey conflicts with Game Bar must be handled by the keyboard hook,
   rather than RegisterHotkey(), without allowing native Windows pass-through. */
const win_hotkeys = residentVisible.split(/^#UseHook On\s*$/m)[1]?.split(/^#UseHook Off\s*$/m)[0];
assert.ok(win_hotkeys, 'Win hotkey section is enclosed by #UseHook On/Off');
assert.match(residentVisible, /#UseHook On\s*\n#y::/, 'Win hook starts before the first resident Win shortcut');
assert.match(residentVisible, /#r::[\s\S]*?return\s*\n#UseHook Off/, 'Win hook stays enabled through the last resident Win shortcut');
for (const chord of ['#y', '#c', '#g', '#i', '#f', '#Space', '#t', '#m', '#r', '#Pause', '^#F4'])
{
  assert.match(win_hotkeys, new RegExp('^' + chord.replace(/[\^$.*+?()[\]{}|]/g, '\\$&') + '::', 'm'), chord + ' uses keyboard hook');
}
assert.match(win_hotkeys, /^#g::\s*\nkeyboardPublishShortcut\("Win\+G"\)/m, 'Win+G reports its activation for runtime test');
assert.match(win_hotkeys, /#g::[\s\S]*?keyboardLaunchAction\("Win\+G"\)[\s\S]*?return/, 'Win+G dispatches to separate Chrome action');
assert.match(fs.readFileSync(path.join(__dirname, '..', 'actions', 'Google-Search', 'Google-Search.ahk'), 'utf8'), /searchOrCycleChrome\(\)/, 'Win+G action retains Chrome behavior');
assert.doesNotMatch(win_hotkeys, /^~[^\r\n]*::/m, 'no Windows hotkey is configured to pass through');
assert.match(residentVisible, /Menu, Tray, Tip, Keyboard Setup v0\.34/, 'running tray identifies isolated-action build');
console.log('PASS: all resident Win hotkeys use non-pass-through keyboard hook; Win+G routes to Chrome, not Game Bar.');
