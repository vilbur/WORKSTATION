const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");

function makeElement(label)
{
  const attrs = {};
  const children = [];
  return {
    innerText: label || "", className: "key", style: {}, value: "", disabled: false, children,
    getAttribute(name) { return attrs[name] || null; },
    setAttribute(name, value) { attrs[name] = String(value); },
    appendChild(item) { children.push(item); },
    removeChild(item) { const i = children.indexOf(item); if (i >= 0) children.splice(i,1); },
    get firstChild() { return children[0] || null; }
  };
}
const html = fs.readFileSync("Keyboard-Setup-Design-Options.hta", "utf8");
const body = html.match(/<script language="javascript">([\s\S]*?)<\/script>/);
assert.ok(body, "keyboard script present");
const keys = ["Ctrl", "Shift", "Win", "Alt", "G", "U", "Y", "I"].map(makeElement);
const controls = {};
["selectedKey","activeModifiers","editorStatus","shortcutField","commandName","actionType","deleteBindingButton","saveBindingButton","bindingOverview","bindingSearch","bindingPageStatus","bindingPagePrev","bindingPageNext","keyboardShell","keyboardStage","projectVersion","bindingFilePath","fileBrowseInput","sourceProfile","importStatus","editorPanel","actionDescription","shortcutMonitor","shortcutMonitorShortcut","shortcutMonitorAction","shortcutMonitorDescription","legendCtrl","legendShift","legendWin","legendAlt","activeModifierSwatch","activeModifierHex"].forEach(name => controls[name] = makeElement());
controls.actionType.value="custom";
const doc = {
  title:"", getElementsByClassName(name) {return name === "key" ? keys : [];},
  getElementById(name) {return controls[name];},createElement() {return makeElement();}
};
const ctx={document:doc,window:{resizeTo(){},alert(message){throw Error(message);}},Array,String,RegExp};
vm.createContext(ctx);
vm.runInContext(fs.readFileSync("data/Keyboard-Setup-Catalog.js", "utf8"),ctx);
vm.runInContext(fs.readFileSync("data/Keyboard-Setup-Windows.js", "utf8"),ctx);
vm.runInContext(body[1],ctx);
ctx.initializeKeyboard();

const exact = [
  [[],"#000000"],
  [["Ctrl"],"#FF0000"],[["Shift"],"#00FF00"],[["Win"],"#0000FF"],[["Alt"],"#000000"],
  [["Ctrl","Shift"],"#FFFF00"],[["Ctrl","Win"],"#FF00FF"],[["Ctrl","Alt"],"#590000"],
  [["Shift","Win"],"#00FFFF"],[["Shift","Alt"],"#005900"],[["Win","Alt"],"#000059"],
  [["Ctrl","Shift","Win"],"#FFFFFF"],[["Ctrl","Shift","Alt"],"#595900"],
  [["Ctrl","Win","Alt"],"#590059"],[["Shift","Win","Alt"],"#005959"],
  [["Ctrl","Shift","Win","Alt"],"#595959"]
];
assert.equal(ctx.keyboard_alt_darkness,0.65);
for (const [mods,expected] of exact)
{
  assert.equal(ctx.keyboardModifierColor(mods),expected,`list ${mods.join('+') || 'none'}`);
  const state={Ctrl:false,Shift:false,Win:false,Alt:false};
  for (const m of mods) state[m]=true;
  assert.equal(ctx.keyboardModifierColor(state),expected,`state object ${mods.join('+') || 'none'}`);
  for(const order of [mods.slice().reverse(),mods.slice().sort()])
  {
    assert.equal(ctx.keyboardModifierColor(order),expected,`permutation ${order.join('+')}`);
  }
}
assert.equal(exact.length,16);
assert.equal(ctx.keyboardModifierColor(["Ctrl","Alt"],0),"#FF0000","zero darkness");
assert.equal(ctx.keyboardModifierColor(["Ctrl","Alt"],1),"#000000","complete darkness");
assert.equal(ctx.keyboardModifierColor(["Ctrl","Alt"],0.5),"#800000","internal darkness parameter is configurable");

const codes={Ctrl:17,Shift:16,Win:91,Alt:18};
for (const order of [
 ["Ctrl","Shift","Alt","Win"], ["Win","Alt","Shift","Ctrl"],
 ["Alt","Ctrl","Win","Shift"], ["Shift","Win","Ctrl","Alt"]])
{
  ctx.resetPhysicalModifiers();
  const held=[];
  for(const m of order)
  {
    ctx.handleModifierKeyDown({keyCode:codes[m]});
    held.push(m);
    assert.equal(controls.activeModifierHex.innerText,ctx.keyboardModifierColor(held),"live colour after keydown");
    assert.equal(controls.activeModifierSwatch.style.backgroundColor,ctx.keyboardModifierColor(held));
  }
  for(const m of order.slice().reverse())
  {
    ctx.handleModifierKeyUp({keyCode:codes[m]});
    held.splice(held.indexOf(m),1);
    assert.equal(controls.activeModifierHex.innerText,ctx.keyboardModifierColor(held),"live colour after keyup");
  }
  assert.equal(controls.activeModifierHex.innerText,"#000000","released all keys");
}
ctx.resetPhysicalModifiers();
for(const [m,expected] of [["Ctrl","#FF0000"],["Shift","#FFFF00"],["Win","#FFFFFF"],["Alt","#595959"]])
{
  ctx.handleKeyboardKeyClick(keys.find(k=>k.innerText===m));
  assert.equal(controls.activeModifierHex.innerText,expected,"latched modifiers update immediately");
}
for(const m of ["Ctrl","Shift","Win","Alt"]) ctx.handleKeyboardKeyClick(keys.find(k=>k.innerText===m));
assert.equal(controls.activeModifierHex.innerText,"#000000","unlatched all");
ctx.handleModifierKeyDown({keyCode:18});
assert.equal(controls.activeModifierHex.innerText,"#000000","Alt alone is black");
assert.match(controls.activeModifiers.innerText,/Alt/,"Alt is identified in text despite black swatch");
ctx.handleModifierKeyUp({keyCode:18});
assert.match(controls.activeModifiers.innerText,/None/,"unmodified black is distinguishable by text");

// Windows/PowerKeys assignments: idle bands show each true modifier combination,
// and during a chord only active-compatible bindings are coloured.
ctx.resetPhysicalModifiers();
const win_g=keys.find(k=>k.innerText==="G");
assert.equal(win_g.keyboard_rgb_strip.style.backgroundColor,"#0000FF");
const key_u=keys.find(k=>k.innerText==="U");
assert.match(key_u.keyboard_rgb_strip.style.backgroundImage,/#FF0000/);
assert.match(key_u.keyboard_rgb_strip.style.backgroundImage,/#FFFF00/);
ctx.handleModifierKeyDown({keyCode:17});
assert.equal(key_u.keyboard_rgb_strip.style.backgroundColor,"#FF0000");
ctx.handleModifierKeyDown({keyCode:16});
assert.equal(key_u.keyboard_rgb_strip.style.backgroundColor,"#FFFF00");
ctx.handleModifierKeyUp({keyCode:16});
assert.equal(key_u.keyboard_rgb_strip.style.backgroundColor,"#FF0000");
ctx.handleModifierKeyUp({keyCode:17});
assert.match(key_u.keyboard_rgb_strip.style.backgroundImage,/#FFFF00/);

assert.doesNotMatch(html,/binding-mod-count-[1234]/,"obsolete count-based CSS removed");
console.log("PASS: all 16 RGB states, exact hex channels, Alt darkness, activation orders, key press/release/latch, and multi-binding segments.");
