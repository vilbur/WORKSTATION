/* Exact RGB state, activation-order, physical-event, latch, and colour-use regression. */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const shared = fs.readFileSync('data/Keyboard-Setup-Modifier-Colors.js', 'utf8');
const ui = fs.readFileSync('Keyboard-Setup-Design-Options.hta', 'utf8');
const index = fs.readFileSync('src/Keyboard-Setup-Hotkey-Index.hta', 'utf8');
const c = {};
vm.createContext(c);
vm.runInContext(shared, c);
assert.match(shared, /Alt=white/, 'Alt is additive white');
const cases = [
  [[], '#000000'], [['Ctrl'], '#FF0000'], [['Shift'], '#00FF00'], [['Win'], '#0000FF'],
  [['Alt'], '#FFFFFF'], [['Ctrl','Shift'], '#FFFF00'], [['Ctrl','Win'], '#FF00FF'],
  [['Ctrl','Alt'], '#FFFFFF'], [['Shift','Win'], '#00FFFF'], [['Shift','Alt'], '#FFFFFF'],
  [['Alt','Win'], '#FFFFFF'], [['Ctrl','Shift','Win'], '#FFFFFF'],
  [['Ctrl','Shift','Alt'], '#FFFFFF'], [['Ctrl','Alt','Win'], '#FFFFFF'],
  [['Shift','Alt','Win'], '#FFFFFF'], [['Ctrl','Shift','Alt','Win'], '#FFFFFF']
];
assert.equal(cases.length, 16);
const muted_cases = [
  '#000000','#F16D77','#66DC76','#55B8F6','#FFFFFF','#E7D451','#D875E9',
  '#F16D77','#56DDE2','#66DC76','#55B8F6','#A779D8','#E7D451','#D875E9',
  '#56DDE2','#A779D8'
];
assert.equal(muted_cases.length, cases.length);

function permutations(arr) {
  if (arr.length < 2) return [arr];
  return arr.flatMap((x, i) => permutations(arr.filter((_, j) => i !== j)).map(p => [x, ...p]));
}
for (const [case_index, [modifiers, expected]] of cases.entries()) {
  assert.equal(c.keyboardModifierDisplayColor(modifiers), muted_cases[case_index], `soft colour ${modifiers}`);
  assert.equal(c.keyboardModifierColor(modifiers), expected, modifiers.join('+') || 'none');
  const flags = { Ctrl:false, Shift:false, Win:false, Alt:false };
  modifiers.forEach(m => flags[m] = true);
  assert.equal(c.keyboardModifierRgb(flags), expected, `object states ${modifiers}`);
  for (const order of permutations(modifiers)) {
    assert.equal(c.keyboardModifierColor(order), expected, `order ${order}`);
    assert.equal(c.keyboardModifierDisplayColor(order), muted_cases[case_index], `muted order ${order}`);
  }
}
assert.equal(c.keyboardModifierColor(['Ctrl','Alt']), '#FFFFFF', 'Alt white saturates every channel');
assert.notEqual(c.keyboardModifierColor(['Alt']), c.keyboardModifierColor([]), 'Alt is now distinguishable as white');
assert.equal(c.keyboardModifierUnionColor([['Ctrl'],['Shift']]), '#FFFF00', 'Ctrl+G and Shift+G union is yellow');
assert.equal(c.keyboardModifierUnionColor([['Shift'],['Ctrl']]), '#FFFF00', 'assignment order does not influence colour');
assert.equal(c.keyboardModifierUnionColor([['Win'],['Shift'],['Ctrl']]), '#FFFFFF', 'three assignments union to white');
assert.equal(c.keyboardModifierUnionColor([['Ctrl'],['Alt']]), '#FFFFFF', 'Alt union mixes white');
assert.equal(c.keyboardModifierColorForShortcut('Ctrl + "'), '#FFFF00', 'shifted US quote physically includes Shift');
assert.equal(c.keyboardModifierColorForShortcut('Win + Ctrl + F4'), '#FF00FF', 'modifier order of displayed chord irrelevant');
assert.match(ui, /data\/Keyboard-Setup-Modifier-Colors\.js/, 'editor imports common function');
assert.match(index, /\.\.\/data\/Keyboard-Setup-Modifier-Colors\.js/, 'index imports exact same function');
assert.doesNotMatch(ui, /binding-mod-count-[1-4]/, 'deprecated count-based priorities removed');
assert.match(index, /keyboardModifierDisplayUnionColor\(\[item\.modifiers\]\)/, 'index swatches use nonwhite shared display calculator');

function element(label = '', attrs = {}) {
  const children = [];
  return {
    innerText:label, className:'key', style:{}, value:'', title:'', disabled:false, children,
    getAttribute(n) {return attrs[n] || null;}, setAttribute(n,v){attrs[n]=String(v);},
    appendChild(x){children.push(x);}, removeChild(x){const i=children.indexOf(x);if(i>=0)children.splice(i,1);},
    get firstChild(){return children[0] || null;}
  };
}
const buttons = [element('Ctrl', {'data-modifier':'Ctrl'}), element('Shift', {'data-modifier':'Shift'}),
  element('Win', {'data-modifier':'Win'}), element('Alt', {'data-modifier':'Alt'}), element('U')];
const ids = {};
for (const id of ['activeModifiers','activeModifierSwatch','activeModifierHex','legendCtrl','legendShift','legendWin','legendAlt',
  'legendCtrlShift','legendCtrlWin','legendShiftWin','legendCtrlShiftWin',
  'bindingOverview','bindingSearch','bindingPageStatus','bindingPagePrev','bindingPageNext']) ids[id]=element();
const context = { RegExp, String, Array,
  document:{getElementsByClassName(name){return name === 'key' ? buttons:[];}, getElementById(id){return ids[id];}, createElement(){return element();}}
};
vm.createContext(context);
vm.runInContext(shared,context);
vm.runInContext(fs.readFileSync('data/Keyboard-Setup-Catalog.js','utf8'),context);
vm.runInContext(fs.readFileSync('data/Keyboard-Setup-Windows.js','utf8'),context);
const script = ui.match(/<script language="javascript">([\s\S]*?)<\/script>/);
assert.ok(script);
vm.runInContext(script[1],context);
function assertState(modifiers, expected) {
  context.updateKeyboardHighlights();
  assert.equal(ids.activeModifierHex.innerText, c.keyboardModifierDisplayColor(modifiers), `screen state ${modifiers}`);
  assert.equal(ids.activeModifierSwatch.style.backgroundColor, c.keyboardModifierDisplayColor(modifiers), `swatch state ${modifiers}`);
  assert.equal(ids.activeModifiers.innerText, 'Active modifiers: ' + (modifiers.length ? ['Ctrl','Shift','Alt','Win'].filter(m=>modifiers.includes(m)).join(' + ') : 'None'));
}
const codes={Ctrl:17,Shift:16,Alt:18,Win:91};
function press(m){context.handleModifierKeyDown({keyCode:codes[m],which:codes[m]});}
function release(m){context.handleModifierKeyUp({keyCode:codes[m],which:codes[m]});}
assertState([], '#000000');
for (const [modifiers, expected] of cases) {
  for (const order of permutations(modifiers)) {
    context.resetPhysicalModifiers();
    for (const m of order) press(m);
    assertState(modifiers, expected);
    for (const m of [...order].reverse()) release(m);
    assertState([], '#000000');
  }
}
press('Ctrl'); assertState(['Ctrl'], '#FF0000');
assert.equal(buttons[4].style.borderColor, '#F16D77', 'Ctrl alone shows only exact Ctrl+U in red');
assert.match(buttons[4].style.background, /linear-gradient\(rgba/, 'old shaded full-key highlight is used');
press('Shift'); assertState(['Ctrl','Shift'], '#FFFF00');
assert.equal(buttons[4].style.borderColor, '#E7D451', 'Ctrl+Shift shows exact Ctrl+Shift+U in yellow');
assert.match(buttons[4].style.boxShadow, /0 0 16px/, 'compatible shortcut keeps strong glow');
press('Win'); assertState(['Ctrl','Shift','Win'], '#FFFFFF');
press('Alt'); assertState(['Ctrl','Shift','Win','Alt'], '#FFFFFF');
release('Alt'); assertState(['Ctrl','Shift','Win'], '#FFFFFF');
release('Win'); assertState(['Ctrl','Shift'], '#FFFF00');
release('Shift'); assertState(['Ctrl'], '#FF0000');
release('Ctrl'); assertState([], '#000000');
press('Alt'); assertState(['Alt'], '#FFFFFF');
assert.equal(ids.activeModifiers.innerText, 'Active modifiers: Alt', 'Alt-only displays active name');
release('Alt'); assertState([], '#000000');
context.handleKeyboardKeyClick(buttons[2]); assertState(['Win'], '#0000FF');
press('Ctrl'); assertState(['Ctrl','Win'], '#FF00FF');
release('Ctrl'); assertState(['Win'], '#0000FF');
context.handleKeyboardKeyClick(buttons[2]); assertState([], '#000000');
assert.equal(ids.legendCtrl.style.backgroundColor, '#F16D77');
assert.equal(ids.legendShift.style.backgroundColor, '#66DC76');
assert.equal(ids.legendWin.style.backgroundColor, '#55B8F6');
assert.equal(ids.legendAlt.style.backgroundColor, '#FFFFFF');
/* Test a real physical key with multiple independent assignments. */
context.shortcut_bindings = [];
context.keyboard_windows_shortcuts = [];
context.shortcut_bindings.push({key:'G',modifiers:['Ctrl'],name:'Ctrl G',action:'custom'},
  {key:'G',modifiers:['Shift'],name:'Shift G',action:'custom'});
buttons.push(element('G'));
context.resetPhysicalModifiers();
context.updateKeyboardHighlights();
assert.equal(buttons[5].style.borderColor, '#E7D451', 'G union Ctrl+Shift is yellow in idle');
assert.match(buttons[5].style.background, /linear-gradient\(rgba/, 'G uses old shaded keycap not ribbon');
press('Ctrl');
assert.equal(buttons[5].style.borderColor, '#F16D77', 'Ctrl alone shows only Ctrl+G in red');
assert.match(buttons[5].className, /shortcut-match/, 'Ctrl+G matches Ctrl press');
release('Ctrl'); press('Shift');
assert.equal(buttons[5].style.borderColor, '#66DC76', 'Shift alone shows only Shift+G in green');
assert.match(buttons[5].className, /shortcut-match/, 'Shift+G matches Shift press');
release('Shift');
press('Ctrl'); press('Shift');
assert.equal(buttons[5].style.background, '', 'Ctrl+Shift hides G when only Ctrl+G and Shift+G exist');
assert.doesNotMatch(buttons[5].className, /shortcut-match/, 'no combined G binding is highlighted');
release('Shift'); release('Ctrl');
context.shortcut_bindings.push({key:'G',modifiers:['Win','Ctrl'],name:'Ctrl Win G',action:'custom'});
press('Ctrl'); press('Win');
assert.equal(buttons[5].style.borderColor, '#D875E9', 'Ctrl+Win shows exact magenta G');
assert.ok(buttons[5].title.includes('Ctrl + Win + G') && !buttons[5].title.includes('Ctrl + G -'), 'tooltip excludes subset shortcuts');
release('Ctrl'); release('Win');
context.shortcut_bindings.pop();
context.shortcut_bindings.reverse(); context.updateKeyboardHighlights();
assert.equal(buttons[5].style.borderColor, '#E7D451', 'reversing binding order keeps same yellow');
assert.doesNotMatch(ui, /keyboardModifierBands/, 'old multi-colour ribbon function removed');
assert.match(ui, /keyboardModifierDisplayUnionColor\(matching_modifiers_for_key\)/, 'keyboard accumulates only visible exact matches');
assert.match(ui, /0 0 16px/, 'matching strong-glow style restored');
assert.doesNotMatch(ui, /legend-dot match/, 'unused Match decoration removed');
assert.ok(ui.includes('legendCtrlShiftWin'), 'mixed modifier legend available');
assert.equal(ids.legendCtrlShift.style.backgroundColor, '#E7D451');
assert.equal(ids.legendCtrlWin.style.backgroundColor, '#D875E9');
assert.equal(ids.legendShiftWin.style.backgroundColor, '#56DDE2');
assert.equal(ids.legendCtrlShiftWin.style.backgroundColor, '#A779D8');
assert.equal(c.keyboardModifierDisplayUnionColor([['Ctrl'],['Shift']]), '#E7D451', 'union uses saturated shade');
assert.equal(c.keyboardModifierDisplayColorForShortcut('Win+G'), '#55B8F6', 'Win retains saturated sky blue');
/* Every one of the 16 modifier combinations is an exclusive display filter. */
context.shortcut_bindings = cases.map(([mods], i) => ({
  key:'G', modifiers:mods, name:'Exclusive ' + i, action:'custom'
}));
context.keyboard_windows_shortcuts = [];
for (const [i, [mods]] of cases.entries())
{
  context.resetPhysicalModifiers();
  for (const mod of ['Ctrl','Shift','Alt','Win'])
  {
    context.physical_modifiers[mod] = mods.includes(mod);
  }
  context.updateKeyboardHighlights();
  const expected_count = mods.length ? 1 : cases.length;
  assert.equal(context.getVisibleBindings().length, 16, 'data records remain intact');
  assert.match(ids.bindingPageStatus.innerText, new RegExp('^' + expected_count + ' match' + (expected_count === 1 ? '' : 'es')), 'overview is exclusive for state ' + mods.join('+'));
  assert.equal(buttons[5].title.split('\r\n\r\n').length, expected_count, 'G tooltip uses blank-line-separated exact matches for ' + mods.join('+'));
  if (mods.length)
  {
    assert.ok(buttons[5].title.includes('Exclusive ' + i), 'correct exact action for ' + mods.join('+'));
    assert.match(buttons[5].className, /shortcut-match/, 'exact G is highlighted for ' + mods.join('+'));
  }
}
context.resetPhysicalModifiers();
context.shortcut_bindings = [
  {key:'G',modifiers:['Ctrl'],name:'Ctrl only',action:'custom'},
  {key:'G',modifiers:['Ctrl','Win'],name:'Ctrl Win only',action:'custom'},
  {key:'G',modifiers:['Ctrl','Shift','Win'],name:'Triple only',action:'custom'}
];
press('Ctrl'); press('Win');
assert.match(buttons[5].title, /Ctrl Win only/, 'Ctrl+Win has its own hotkey');
assert.doesNotMatch(buttons[5].title, /Ctrl only|Triple only/, 'Ctrl+Win excludes strict subsets and supersets');
release('Ctrl'); release('Win');
context.handleKeyboardKeyClick(buttons[2]);
press('Ctrl');
assert.match(buttons[5].title, /Ctrl Win only/, 'mouse-latched Win plus physical Ctrl filters exactly');
release('Ctrl');
context.handleKeyboardKeyClick(buttons[2]);
console.log('PASS: exclusive filtering for all 16 states, Ctrl+Win transitions and mixed physical/mouse modifiers.');
console.log(`PASS: 16 exact RGB states, all ${cases.reduce((sum,[m])=>sum+permutations(m).length,0)} activation orders, additive Alt white, union per key, press/release and full-key glow.`);

/* HTA must survive sync-order skew: shared JS current, from v0.22 or absent. */
const embedded_ui = ui.match(/<script language="javascript">([\s\S]*?)<\/script>/)[1];
function testColorModuleCompatibility(label, setup)
{
  const env = {Array, String, RegExp, keyboard_shortcut_catalog:[], keyboard_windows_shortcuts:[]};
  vm.createContext(env);
  if (setup) {vm.runInContext(setup,env);}
  const prior_union = env.keyboardModifierUnionColor;
  vm.runInContext(embedded_ui,env);
  assert.equal(env.keyboardModifierColor(['Alt']), '#FFFFFF', label + ': Alt stays white');
  assert.equal(env.keyboardModifierColor(['Ctrl', 'Win']), '#FF00FF', label + ': RGB mixing correct');
  assert.equal(env.keyboardModifierUnionColor([['Shift'],['Ctrl']]), '#FFFF00', label + ': union exists and is yellow');
  assert.equal(env.keyboardModifierColorForShortcut('Ctrl + "'), '#FFFF00', label + ': quote Shift handled');
  assert.equal(env.keyboardModifierDisplayColor(['Win']), '#55B8F6', label + ': sky blue display works');
  assert.equal(env.keyboardModifierDisplayUnionColor([['Ctrl'],['Shift']]), '#E7D451', label + ': pastel union works');
  if (prior_union) {assert.equal(env.keyboardModifierUnionColor,prior_union,label + ': current shared module keeps authority');}
}
testColorModuleCompatibility('missing shared module', '');
testColorModuleCompatibility('legacy shared module',
  'function keyboardModifierRgb(){return "#000000";}' +
  'function keyboardModifierColor(){return "#000000";}' +
  'function keyboardModifierColorForShortcut(){return "#000000";}');
testColorModuleCompatibility('current shared module',shared);
console.log('PASS: partial-sync recovery with missing or legacy shared RGB module, and current-module reuse.');

// White belongs only to the standalone Alt modifier; no ordinary key gains a white overlay.
assert.equal(c.keyboardModifierDisplayColor(['Alt']), '#FFFFFF', 'Alt-only legend is white');
assert.equal(c.keyboardModifierDisplayColor(['Ctrl','Alt']), '#F16D77', 'Alt + Ctrl is red, not white');
assert.equal(c.keyboardModifierDisplayColor(['Ctrl','Shift','Win']), '#A779D8', 'three RGB channels use coloured lavender');
assert.equal(c.keyboardModifierDisplayColor(['Ctrl','Shift','Win','Alt']), '#A779D8', 'Alt does not wash a combined colour out');
assert.equal(c.keyboardModifierDisplayUnionColor([['Alt']]), '', 'Alt-only ordinary key uses neutral assigned styling');
assert.equal(c.keyboardModifierDisplayUnionColor([['Alt'],['Ctrl']]), '#F16D77', 'Alt assignment cannot whiten a Ctrl key');
assert.equal(c.keyboardModifierDisplayUnionColor([['Ctrl'],['Shift'],['Win']]), '#A779D8', 'all three shortcuts stay coloured');
context.shortcut_bindings = [{key:'G',modifiers:['Alt'],name:'Alt G',action:'custom'}];
context.resetPhysicalModifiers();
context.updateKeyboardHighlights();
assert.notEqual(buttons[5].style.borderColor, '#FFFFFF', 'Alt+G is not white');
assert.equal(buttons[5].style.background, '', 'Alt-only G has no white overlay');
press('Alt');
assert.equal(buttons[3].style.borderColor, '#FFFFFF', 'physical Alt modifier itself is white');
assert.notEqual(buttons[5].style.borderColor, '#FFFFFF', 'pressing Alt does not whiten G');
release('Alt');
console.log('PASS: white restricted to Alt modifier key; ordinary keys are saturated and never white.');
