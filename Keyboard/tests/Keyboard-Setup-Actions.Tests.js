const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const project_dir = path.join(__dirname, '..');
const launcher = fs.readFileSync(path.join(project_dir, 'Keyboard-Setup-Launcher.ahk'), 'utf8');
const catalog_context = {};
require('node:vm').runInNewContext(fs.readFileSync(path.join(project_dir, 'data/Keyboard-Setup-Catalog.js'), 'utf8'), catalog_context);
const catalog = catalog_context.keyboard_shortcut_catalog;

const actions = [
  ['Ctrl+U', '^u', 'Cycle-Text-Case', 'keyboardApplyTextTransform(Func("keyboardToggleThreeCase"))'],
  ['Ctrl+Shift+U', '^+u', 'Cycle-Naming-Convention', 'keyboardApplyTextTransform(Func("keyboardCycleConvention"), true)'],
  ["Ctrl+Shift+'", '^+SC028', 'Toggle-Quotes', 'keyboardApplyTextTransform(Func("keyboardToggleQuotes"))'],
  ['Win+Y', '#y', 'YouTube', 'activateYouTube()'],
  ['Win+C', '#c', 'Total-Commander-Windows', 'cycleTotalCommander()'],
  ['Win+G', '#g', 'Google-Search', 'searchOrCycleChrome()'],
  ['Win+I', '#i', 'IrfanView-Image', 'keyboardOpenClipboardImageInIrfanView()'],
  ['Win+F', '#f', 'FocusMe-Window', null],
  ['Ctrl+Win+N', '^#n', 'Notepad-Clipboard-File', null],
  ['Ctrl+Win+F4', '^#F4', 'Kill-All-Active-Processes', null],
  ['Win+Space', '#Space', 'ChatGPT-Dictation', null],
  ['Shift+Win+H', '+#h', 'Open-Hotstrings', null],
  ['Win+T', '#t', 'Total-Commander-Activate', null],
  ['Win+F4', '#F4', 'Kill-Active-Process', null],
  ['Ctrl+Win+H', '^#h', 'Hibernate-Windows', null],
  ['Win+Pause', '#Pause', 'Temporary-Mute', null],
  ['Win+M', '#m', 'Suspend-Key', null],
  ['Ctrl+Shift+Win+F', '^+#f', 'FocusMe-Window-Alternate', null],
  ['Ctrl+Win+C', '^#c', 'Go-To-Path', null],
  ['Win+Enter', '#Enter', 'MediaMonkey-Activate', null],
  ['Win+R', '#r', 'Run-MaxScript', null]
];

assert.equal(actions.length, 21);
assert.equal(catalog.length, 21);
assert.match(launcher, /^keyboardLaunchAction\(chord\)\s*\n\{/m, 'resident dispatcher exists');
assert.match(launcher, /keyboardToolkitV1Interpreter\(\)/, 'dispatcher selects explicit AHK v1 runtime');
assert.match(launcher, /if !FileExist\(action_path\)/, 'missing action is diagnosed');
assert.match(launcher, /Run, %command%, %keyboard_project_dir%, UseErrorLevel/, 'action is launched in a separate process');

for (const [chord, hotkey, action_name, built_in_call] of actions)
{
  const escaped = hotkey.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const block = launcher.match(new RegExp('^' + escaped + '::([\\s\\S]*?)^return\\s*$', 'm'));
  assert.ok(block, `${chord} hotkey is still registered`);
  assert.ok(block[1].includes(`keyboardPublishShortcut("${chord}")`), `${chord} publishes its event`);
  assert.ok(block[1].includes(`keyboardLaunchAction("${chord}")`), `${chord} dispatches its own file`);
  const relative = path.join('actions', action_name, `${action_name}.ahk`);
  assert.ok(launcher.includes(relative.replace(/\//g, '\\').replace(/\\/g, '\\')), `${chord} is mapped to ${relative}`);
  const absolute = path.join(project_dir, relative);
  assert.ok(fs.existsSync(absolute), `${chord} action file exists`);
  const content = fs.readFileSync(absolute, 'utf8');
  assert.match(content, /^#Requires AutoHotkey v1\.1\s*$/m, `${chord} action requires AHK v1`);
  assert.match(content, /ExitApp/, `${chord} action finishes as a separate launch`);
  if (built_in_call)
  {
    assert.ok(content.includes(built_in_call), `${chord} owns its action`);
  }
  else
  {
    const record = catalog.find(item => [...item.modifiers, item.key].join('+') === chord);
    assert.ok(record && record.source === 'AutoHotkey Toolkit', `${chord} is an imported action`);
    assert.ok(content.includes(record.default_file), `${chord} wrapper retains its original file path`);
    assert.ok(content.includes(`keyboardRunToolkitAction("${chord}"`), `${chord} delegates to shared external runner`);
  }
}

assert.doesNotMatch(launcher, /^handleTextCommand\(/m, 'text action implementation is no longer in resident');
assert.doesNotMatch(launcher, /^keyboardOpenClipboardImageInIrfanView\(/m, 'IrfanView action is no longer in resident');
assert.doesNotMatch(launcher, /^searchOrCycleChrome\(/m, 'Chrome action is no longer in resident');
const irfan = fs.readFileSync(path.join(project_dir, 'actions/IrfanView-Image/IrfanView-Image.ahk'), 'utf8');
const action_common = fs.readFileSync(path.join(project_dir, 'src/Keyboard-Setup-Action-Common.ahk'), 'utf8');
assert.match(action_common, /keyboardApplyTextTransform\(transform_function, select_word := false\)/, 'shared clipboard helper accepts one independent action callback');
assert.doesNotMatch(action_common, /keyboardToggleThreeCase\(selected_text\)|keyboardCycleConvention\(selected_text\)|keyboardToggleQuotes\(selected_text\)/, 'shared helper does not statically reference absent action-specific algorithms');
assert.match(irfan, /keyboardReadIrfanCycleAnchor\(\)/, 'IrfanView action restores last cycle HWND across separate processes');
assert.match(irfan, /keyboardSaveIrfanCycleAnchor\(target_hwnd\)/, 'IrfanView action persists last cycle HWND');
assert.match(irfan, /A_Temp/, 'runtime cycle state stays outside the Drive project');
const youtube = fs.readFileSync(path.join(project_dir, 'actions/YouTube/YouTube.ahk'), 'utf8');
assert.match(youtube, /chrome\.exe --new-window/, 'Win+Y always requests a new Chrome window');
assert.match(youtube, /https:\/\/www\.youtube\.com\//, 'Win+Y opens the YouTube homepage');
assert.doesNotMatch(youtube, /IfWinExist|WinActivate|keyboardOpenChromeUrl/, 'Win+Y never activates an old window or opens a new tab');
const build_script = fs.readFileSync(path.join(project_dir, 'build/Build-Keyboard-Setup.ps1'), 'utf8');
assert.match(build_script, /\[regex\]::Matches/, 'Windows build derives expected actions from resident map');
assert.match(build_script, /action_paths\.Count -ne 21/, 'Windows build requires exactly 21 mapped actions');
assert.match(build_script, /Test-Path -LiteralPath \$action_file/, 'Windows build checks each mapped launch file exists');
for (const [file, function_names] of [
  ['Cycle-Text-Case', ['keyboardToggleThreeCase']],
  ['Cycle-Naming-Convention', ['keyboardCycleConvention', 'keyboardCycleConventionLine', 'keyboardComposeConvention']],
  ['Toggle-Quotes', ['keyboardToggleQuotes']],
  ['Google-Search', ['keyboardUrlEncode']]
])
{
  const content = fs.readFileSync(path.join(project_dir, 'actions', file, `${file}.ahk`), 'utf8');
  assert.doesNotMatch(content, /src\\Keyboard-Setup-Core\.ahk/, `${file} has no shared action algorithm dependency`);
  for (const function_name of function_names)
    assert.match(content, new RegExp('^' + function_name + '\\([^\\n]*\\)\\s*\\n\\{', 'm'), `${file} contains its editable algorithm`);
}
console.log('PASS: 21 isolated action entrypoints, resident event/dispatch and external defaults');
