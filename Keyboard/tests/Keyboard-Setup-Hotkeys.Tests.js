const assert = require('node:assert/strict');
const fs = require('node:fs');

const launcher = fs.readFileSync('Keyboard-Setup-Launcher.ahk', 'utf8');
const core_path = 'src/Keyboard-Setup-Core.ahk';
const common = fs.readFileSync('src/Keyboard-Setup-Action-Common.ahk', 'utf8');
const irfan = fs.readFileSync('actions/IrfanView-Image/IrfanView-Image.ahk', 'utf8');

const expected_bindings = [
  ['^u', 'Ctrl+U', 'actions/Cycle-Text-Case/Cycle-Text-Case.ahk', 'keyboardApplyTextTransform(Func("keyboardToggleThreeCase"))'],
  ['^+u', 'Ctrl+Shift+U', 'actions/Cycle-Naming-Convention/Cycle-Naming-Convention.ahk', 'keyboardApplyTextTransform(Func("keyboardCycleConvention"), true)'],
  ['^+SC028', "Ctrl+Shift+'", 'actions/Toggle-Quotes/Toggle-Quotes.ahk', 'keyboardApplyTextTransform(Func("keyboardToggleQuotes"))'],
  ['#y', 'Win+Y', 'actions/YouTube/YouTube.ahk', 'activateYouTube()'],
  ['#c', 'Win+C', 'actions/Total-Commander-Windows/Total-Commander-Windows.ahk', 'cycleTotalCommander()'],
  ['#g', 'Win+G', 'actions/Google-Search/Google-Search.ahk', 'searchOrCycleChrome()'],
  ['#i', 'Win+I', 'actions/IrfanView-Image/IrfanView-Image.ahk', 'keyboardOpenClipboardImageInIrfanView()']
];

for (const [hotkey, chord, action_path, call] of expected_bindings)
{
  const escaped_hotkey = hotkey.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const block = launcher.match(new RegExp('^' + escaped_hotkey + '::([\\s\\S]*?)^return\\s*$', 'm'));
  assert.ok(block, `${hotkey} must be registered and terminate with return`);
  assert.ok(block[1].includes(`keyboardLaunchAction("${chord}")`), `${hotkey} must dispatch its action file`);
  assert.ok(fs.readFileSync(action_path, 'utf8').includes(call), `${hotkey} action owns ${call}`);
}

assert.match(fs.readFileSync('actions/Cycle-Text-Case/Cycle-Text-Case.ahk', 'utf8'), /^keyboardToggleThreeCase\(/m,
  'Each action must own its transformation algorithm');
assert.ok(fs.existsSync(core_path), 'Legacy core file is preserved for compatibility');
assert.ok(common.includes('keyboardRunBoundFile('), 'Actions should execute configured file paths');
assert.ok(common.includes('Keyboard-Setup-File-Bindings.ini'), 'Actions should load file bindings from INI');

console.log('PASS: seven runtime hotkeys are registered to the intended commands.');

assert.match(irfan, /keyboardClipboardHasImage\(\)/, "IrfanView action checks image formats");
assert.match(irfan, /keyboardClipboardImagePath\(\)/, "IrfanView action reads copied image paths");
assert.match(irfan, /\/clippaste/, "IrfanView receives native clipboard image command");
assert.match(irfan, /FileSelectFile, selected_path/, "missing IrfanView executable opens Browse");
assert.match(irfan, /Keyboard-Setup-Applications\.ini/, "IrfanView executable is persisted separately");

// Win+I falls back to existing IrfanView windows only for an empty image/path clipboard.
const irfan_action = irfan.match(/keyboardOpenClipboardImageInIrfanView\(\)\s*\{([\s\S]*?)\n\}/);
assert.ok(irfan_action, 'IrfanView image action exists');
assert.match(irfan_action[1], /if \(!has_image && image_path == ""\)\s*\{\s*;[^\n]*\n\s*;[^\n]*\n\s*if keyboardCycleIrfanViewWindows\(\)\s*return/,
  'when no image source exists, cycle open windows before displaying notification');
assert.match(irfan_action[1], /TrayTip, Keyboard Setup, No clipboard image or open IrfanView window/,
  'notification remains the last fallback');
assert.match(irfan, /keyboardCycleIrfanViewWindows\(\)/, 'IrfanView cycling function is provided');
const cycle = irfan.match(/keyboardCycleIrfanViewWindows\(\)\s*\{([\s\S]*?)\n\}/);
assert.ok(cycle, 'IrfanView cycling function is defined');
assert.match(cycle[1], /i_view64\.exe.*i_view32\.exe/, 'both 64-bit and 32-bit IrfanView windows are discovered');
assert.match(cycle[1], /GetWindow.*GW_OWNER/, 'exclude owned dialogs');
assert.match(cycle[1], /keyboard_last_irfan_hwnd/, 'retain last activated IrfanView window');
assert.match(cycle[1], /WinRestore/, 'minimised IrfanView windows are restored');
assert.match(cycle[1], /WinActivate/, 'selected IrfanView window is activated');
assert.match(cycle[1], /Mod\(anchor_index, window_total\) \+ 1/, 'cycle wraps to the first window');

// v0.18: report each global action before execution, without changing handlers.
assert.match(launcher, /keyboardPublishShortcut\(chord\)/, 'runtime has event publisher');
for (const [trigger, chord] of [['^u','Ctrl+U'],['#i','Win+I'],['#y','Win+Y']]) {
  const triggerLine = trigger.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  assert.ok(launcher.includes(trigger+'::\nkeyboardPublishShortcut("'+chord+'")'), trigger+' reports before action');
}
assert.match(launcher, /KeyboardSetupActionEvent\.txt/, 'event bridge in user temp');
assert.match(launcher, /FileMove, %temporary%, %target%, 1/, 'event file is atomically replaced');
