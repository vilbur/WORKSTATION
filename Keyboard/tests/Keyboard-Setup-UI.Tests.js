const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");

function makeElement(label)
{
  const attributes = {};
  const children = [];
  return {
    innerText: label || "",
    className: "",
    style: {},
    value: "",
    disabled: false,
    onclick: null,
    children,
    getAttribute(name) { return attributes[name] || null; },
    setAttribute(name, value) { attributes[name] = String(value); },
    appendChild(child) { children.push(child); },
    removeChild(child) { const index = children.indexOf(child); if (index >= 0) children.splice(index, 1); },
    get firstChild() { return children[0] || null; }
  };
}

const hta = fs.readFileSync("Keyboard-Setup-Design-Options.hta", "utf8");
assert.match(hta, /BORDER="dialog"/, "fixed dialog uses a non-resizable Windows border");
assert.match(hta, /MAXIMIZEBUTTON="no"/, "dialog does not offer maximize while dimensions are locked");
assert.match(hta, /\.keyboard-card\s*\{[^}]*width:\s*1444px;[^}]*height:\s*592px;/, "keyboard section keeps screenshot dimensions");
assert.match(hta, /\.keyboard-stage\s*\{[^}]*height:\s*375px;/, "keyboard viewport keeps screenshot height");
assert.match(hta, /\.key\s*\{[^}]*height:\s*32px;[^}]*background:\s*linear-gradient\(#303c4b,#222d3a\);[^}]*box-shadow:\s*0 2px #10151c;/, "original textured keys return without changing key dimensions");
assert.match(hta, /background:\s*linear-gradient/, "original key shading has been restored");
assert.match(hta, /id="keyboardScale"[^>]*value="150"/, "keyboard layout opens at 150 percent");
assert.match(hta, /class="key enter-horizontal">Enter/, "main Enter is horizontal and two standard key widths");
assert.match(hta, /\.key\.enter-horizontal\s*\{[^}]*width:\s*75px;[^}]*height:\s*32px;/, "main Enter measures 2x1");
assert.match(hta, /class="key rshift">Shift/, "right Shift has a dedicated width for Enter alignment");
assert.match(hta, /\.key\.rshift\s*\{[^}]*width:\s*96px;[^}]*min-width:\s*96px;/, "right Shift ends with Enter");
assert.match(hta, /\.key\.backspace-align\s*\{[^}]*width:\s*67px;[^}]*min-width:\s*67px;/, "Backspace ends with Enter");
assert.match(hta, /class="key backspace-align">Backspace<\/button>/, "Backspace uses independent alignment width");
assert.match(hta, /\.key\.backslash-align\s*\{[^}]*width:\s*54px;[^}]*min-width:\s*54px;/, "backslash ends with Enter");
assert.match(hta, /class="key backslash-align">\\<\/button>/, "backslash uses independent alignment width");
assert.match(hta, /\.key\.nav-print-screen \.key-bottom-left\s*\{[^}]*position:\s*absolute;[^}]*left:\s*2px;[^}]*bottom:\s*2px;/, "Print Screen label anchored bottom-left");
assert.match(hta, /class="key main-tab">Tab<\/button>/, "Tab has its own narrower width");
assert.match(hta, /\.key\.main-tab\s*\{[^}]*width:\s*49px;[^}]*min-width:\s*49px;/, "Tab is about one standard key narrower than old 85px");
assert.match(hta, /class="key caps-lock">Caps<\/button>/, "Caps Lock has an independent shorter width");
assert.match(hta, /\.key\.caps-lock\s*\{[^}]*width:\s*67px;[^}]*min-width:\s*67px;/, "Caps Lock is about half a standard key narrower than old 85px");
assert.match(hta, /class="key right-ctrl">Ctrl<\/button>/, "right Ctrl is independently adjustable");
assert.match(hta, /\.key\.right-ctrl\s*\{[^}]*width:\s*52px;[^}]*min-width:\s*52px;/, "right Ctrl aligns with the main Enter edge");

assert.match(hta, /<button class="key">Esc<\/button>/, "Escape is normal 1x1 size");
assert.doesNotMatch(hta, /class="key wide">Esc/, "Escape no longer spans multiple keys");
assert.match(hta, /class="key nav-print-screen"[^>]*><span class="key-bottom-left">PrntScrn<\/span><\/button>.*ScrLK.*Pause/, "Print Screen / Scroll Lock / Pause occupy navigation header");
assert.match(hta, /<div class="navpad">\s*<div class="nav-header">/, "print-screen group belongs to navigation block so it follows Insert alignment");
assert.doesNotMatch(hta, /<div class="header-side">/, "no separate, misaligned print-screen header cell");
assert.match(hta, /\.navpad \.nav-header \{[^}]*position: absolute;[^}]*top: -37px;[^}]*left: 2\.6px;/, "print screen header is a row above Insert, with precise key alignment");
assert.match(hta, /\.navpad \{[^}]*left: -25px;[^}]*width: 122px;[^}]*margin-right: 11px;/, "middle navigation cluster uses symmetric half-key visual margins");
assert.match(hta, /\.numpad \{[^}]*left: -25px;[^}]*width: 156px;/, "numpad follows the half-key gap without resizing its keys");
assert.match(hta, /\.navpad \.arrow-top\s*\{[^}]*margin-top:\s*42px;/, "arrow block moves to Space row");
assert.doesNotMatch(hta, /class="key enter-tall"/, "old vertical main Enter has been removed");
assert.match(hta, /class="key return-tall">Return/, "numpad Return key is one key wide and two rows tall");
assert.match(hta, /class="tab-icon"/, "right Windows key uses a tab-style icon");
const first_script = hta.match(/<script language="javascript">([\s\S]*?)<\/script>/);
assert.ok(first_script, "HTA main script exists");

const key_labels = ["Ctrl", "Shift", "Alt", "Win", "G", "U", "A", "K", "B", "Y", "C", "'", "I"];
const key_buttons = key_labels.map(label => {
  const button = makeElement(label);
  button.className = "key";
  return button;
});
const ids = {};
["selectedKey", "activeModifiers", "editorStatus", "shortcutField", "commandName", "actionType", "deleteBindingButton", "saveBindingButton", "bindingOverview", "bindingSearch", "bindingPageStatus", "bindingPagePrev", "bindingPageNext", "keyboardShell", "keyboardStage", "projectVersion", "bindingFilePath", "fileBrowseInput", "sourceProfile", "importStatus", "editorPanel", "actionDescription", "windowsOverrideNotice", "shortcutMonitor", "shortcutMonitorShortcut", "shortcutMonitorAction", "shortcutMonitorDescription", "activeModifierSwatch", "activeModifierHex", "legendCtrl", "legendShift", "legendWin", "legendAlt", "legendCtrlShift", "legendCtrlWin", "legendShiftWin", "legendCtrlShiftWin"].forEach(id => {
  ids[id] = makeElement("");
});
ids.actionType.value = "custom";
const document_stub = {
  title: "Keyboard Setup - Design Options",
  onkeydown: null,
  onkeyup: null,
  getElementsByClassName(name) { return name === "key" ? key_buttons : []; },
  getElementById(id) { return ids[id]; },
  createElement() { return makeElement(""); }
};
const resize_calls = [];
const context = {
  document: document_stub,
  window: {
    alert(message) { throw new Error(message); },
    resizeTo(width, height) { resize_calls.push([width, height]); }
  },
  RegExp,
  String,
  Array
};
vm.runInNewContext(fs.readFileSync("data/Keyboard-Setup-Modifier-Colors.js", "utf8"), context);
vm.runInNewContext(fs.readFileSync("data/Keyboard-Setup-Catalog.js", "utf8"), context);
vm.runInNewContext(fs.readFileSync("data/Keyboard-Setup-Windows.js", "utf8"), context);
vm.runInNewContext(first_script[1], context);
context.initializeKeyboard();
assert.doesNotMatch(hta, /legend-dot match/, 'unused Match legend removed');
for (const id of ['legendCtrlShift','legendCtrlWin','legendShiftWin','legendCtrlShiftWin'])
{ assert.match(hta, new RegExp('id="' + id + '"'), 'modifier mix legend ' + id); }

assert.deepEqual(resize_calls[0], [2220, 1050], "opening the HTA uses a larger no-scroll desktop layout");

assert.equal(ids.projectVersion.innerText, "v0.32", "project version is visible in the HTA window");
assert.match(document_stub.title, /v0\.32/, "project version is included in the window title");
assert.match(hta, /\.canvas-grid > div:last-child\s*\{[^}]*height:\s*820px;[^}]*overflow:\s*hidden;/, "editor is tall and no longer independently scrolls");
assert.match(hta, /\.keyboard-stage\s*\{[^}]*overflow:\s*hidden;[^}]*padding:\s*4px 3px;/, "keyboard is scrollbar-free at 150% zoom");
assert.match(hta, /SINGLEINSTANCE="yes"/, "HTA declares one UI instance");
assert.match(hta, /onchange="updateActionDescription\(\)"/, "action descriptions change with dropdown");
assert.match(hta, /id="actionDescription"/, "action help appears beneath dropdown");
assert.match(hta, /<option value="youtube">YouTube window<\/option>/, "YouTube action dropdown shows name without shortcut");
assert.doesNotMatch(hta, /<option[^>]*>Win\+Y/, "action option labels never begin with shortcut chords");
assert.equal(context.shortcut_bindings.find(x => x.action === "youtube").name, "YouTube window", "overview uses only action name");
assert.match(context.shortcut_bindings.find(x => x.action === "youtube").summary, /new Chrome window/, "YouTube action description specifies a new window");
assert.deepEqual(Array.from(context.shortcut_bindings.find(x => x.action === "youtube").modifiers), ["Win"], "real shortcut modifiers remain unchanged");

assert.match(ids.actionDescription.innerText, /Custom command/, "initial editor shows custom action help");
ids.actionType.value = "youtube";
context.updateActionDescription();
assert.match(ids.actionDescription.innerText, /YouTube/, "changing action updates inline help");
assert.match(ids.actionDescription.innerText, /new Chrome window/, "inline YouTube help describes the new-window behavior");
ids.actionType.value = "toggle_quotes";
context.updateActionDescription();
assert.match(ids.actionDescription.innerText, /outer quotes/, "quote action displays its flow");
context.setSourceProfile("max");
assert.match(ids.actionDescription.innerText, /read-only/i, "merged 3ds Max action has read-only help");
context.setSourceProfile("windows");
assert.match(hta, /id="bindingSearch"/, "shortcut overview has a search field");
assert.match(hta, /id="bindingPageNext"/, "shortcut overview has pagination");
assert.match(hta, /id="bindingFilePath"/, "shortcut editor has a file path field");
assert.match(hta, /id="fileBrowseInput"/, "file path can be selected with a browse control");
assert.match(hta, /id="maxHotkeyFile"/, "3ds Max hotkey preset has a file browse control");
assert.match(hta, /src="data\/Keyboard-Setup-Max-Preset\.js"/, "HTA includes a bundled 3ds Max preset snapshot");
assert.match(hta, /src="data\/Keyboard-Setup-Max-Defaults\.js"/, "HTA includes the 3ds Max factory base snapshot");
const preset_source = fs.readFileSync("data/Keyboard-Setup-Max-Preset.js", "utf8");
const preset_context = {};
vm.runInNewContext(preset_source, preset_context);
assert.equal(preset_context.bundled_max_hsx.assignments.length, 90, "3ds Max preset snapshot has 90 assignments");
assert.equal(preset_context.bundled_max_hsx.removals.length, 55, "3ds Max preset snapshot retains 55 removals");
vm.runInNewContext(fs.readFileSync("data/Keyboard-Setup-Max-Defaults.js", "utf8"), preset_context);
assert.equal(preset_context.bundled_max_defaults.defaults.length, 532, "3ds Max factory snapshot includes its complete 532 entries");

assert.equal(context.shortcut_bindings.length, 21, "seven built-in plus fourteen Toolkit shortcuts are loaded");
const binding_by_action = Object.fromEntries(context.shortcut_bindings.map(binding => [binding.action, binding]));
assert.deepEqual(Array.from(binding_by_action.toggle_case.modifiers), ["Ctrl"], "Ctrl+U cycles three text cases");
assert.deepEqual(Array.from(binding_by_action.cycle_convention.modifiers), ["Ctrl", "Shift"], "Ctrl+Shift+U cycles naming conventions");
assert.deepEqual(Array.from(binding_by_action.toggle_quotes.modifiers), ["Ctrl", "Shift"], "Ctrl+double quote uses the US quote key with Shift");
assert.equal(binding_by_action.toggle_quotes.key, "'", "double quote shortcut is mapped to the physical apostrophe key");
assert.equal(binding_by_action.youtube.key, "Y", "Win+Y opens YouTube in a new Chrome window");
assert.equal(binding_by_action.cycle_totalcmd.key, "C", "Win+C cycles Total Commander windows");
assert.equal(binding_by_action.cycle_chrome.key, "G", "Win+G cycles Chrome or searches selected text");
assert.equal(context.formatShortcut("'", ["Ctrl", "Shift"]), 'Ctrl + "', "the US quote-key chord displays as Ctrl+double quote");
assert.equal(key_buttons[4].style.borderColor, '#55B8F6', 'Win+G has blue full-key highlight');
assert.equal(key_buttons[5].style.borderColor, '#A779D8', 'U combines Ctrl, Shift and Win from three effective Windows shortcuts');
assert.match(key_buttons[5].style.background, /linear-gradient\(rgba/, 'original shaded keycap style is restored');
context.shortcut_bindings.push(
  { key: "A", modifiers: ["Ctrl", "Shift", "Alt"], name: "three modifier test", action: "custom" },
  { key: "K", modifiers: ["Ctrl", "Shift", "Alt", "Win"], name: "four modifier test", action: "custom" },
  { key: "B", modifiers: ["Shift", "Alt", "Win"], name: "other three modifier test", action: "custom" }
);
context.physical_modifiers.Ctrl = true;
context.updateKeyboardHighlights();
assert.match(key_buttons[6].className, /shortcut-match/, "Ctrl+A Windows default remains visible, but Ctrl+Shift+Alt+A is excluded");
assert.doesNotMatch(key_buttons[7].className, /shortcut-match/, "Ctrl alone excludes Ctrl+Shift+Alt+Win");
assert.doesNotMatch(key_buttons[4].className, /shortcut-match/, "active Ctrl leaves a Win-only shortcut unhighlighted");
assert.doesNotMatch(key_buttons[8].className, /shortcut-match/, "active Ctrl leaves a shortcut without Ctrl unhighlighted");
assert.equal(key_buttons[8].style.background, "", "active Ctrl leaves incompatible B shortcuts uncoloured");
assert.doesNotMatch(key_buttons[8].className, /assigned/, "active Ctrl removes the amber border from a shortcut that does not use Ctrl");
assert.doesNotMatch(key_buttons[4].className, /assigned/, "active Ctrl removes assigned styling from Win-only G");
assert.match(key_buttons[6].className, /assigned/, "Ctrl+A default stays visible on A");
assert.equal(key_buttons[4].title, "", "a Win-only shortcut does not appear as a Ctrl-compatible key tooltip");
assert.match(key_buttons[6].title, /Ctrl \+ A - Select all/, "Ctrl+A default is shown on A");
assert.doesNotMatch(key_buttons[6].title, /Ctrl \+ Shift \+ Alt/, "Ctrl+Shift+Alt+A is hidden from Ctrl-only tooltips");
context.physical_modifiers.Ctrl = false;
context.updateKeyboardHighlights();
assert.equal(key_buttons[6].style.borderColor, '#A779D8', 'A combines Ctrl+Shift+Alt and Windows Win+A, so RGB triple is lavender');
assert.equal(key_buttons[7].style.borderColor, '#A779D8', 'all RGB channels use lavender instead of white');
assert.equal(key_buttons[8].style.borderColor, '#56DDE2', 'Shift+Alt+Win stays cyan, not white');
context.shortcut_bindings.splice(21, 3);
context.updateKeyboardHighlights();

context.physical_modifiers.Ctrl = true;
context.updateKeyboardHighlights();
assert.match(key_buttons[5].className, /shortcut-match/, "Ctrl highlights the assigned Ctrl+U key");
assert.doesNotMatch(key_buttons[4].className, /shortcut-match/, "Ctrl does not highlight Win+G");
assert.equal(key_buttons[5].style.borderColor, '#F16D77', 'Ctrl held shows only Ctrl+U, colored red');
assert.match(key_buttons[5].style.boxShadow, /0 0 16px/, 'matching keys keep previous strong glow style');

context.physical_modifiers.Shift = true;
context.updateKeyboardHighlights();
assert.match(key_buttons[5].className, /shortcut-match/, "Ctrl+Shift highlights the assigned Ctrl+Shift+U key");
assert.equal(key_buttons[5].style.borderColor, '#E7D451', 'Ctrl+Shift shows the exact yellow binding only');
assert.ok(key_buttons[5].title.includes('Ctrl + Shift + U') && !key_buttons[5].title.includes('Ctrl + U -'), 'tooltip displays only exact Ctrl+Shift binding');
assert.equal(context.usesActiveModifiers(['Win','Ctrl'],['Ctrl','Win']), true, 'order-independent exact Ctrl+Win');
assert.equal(context.usesActiveModifiers(['Ctrl','Shift'],['Ctrl']), false, 'Ctrl alone excludes Ctrl+Shift');
assert.equal(context.usesActiveModifiers(['Ctrl'],['Ctrl','Win']), false, 'Ctrl+Win excludes Ctrl alone');
assert.equal(context.usesActiveModifiers(['Ctrl','Win','Shift'],['Win','Ctrl']), false, 'Ctrl+Win excludes Ctrl+Shift+Win');
assert.equal(context.usesActiveModifiers([],['Alt']), false, 'Alt excludes unmodified actions');
assert.equal(context.usesActiveModifiers(['Ctrl'],[]), false, 'idle retains all catalogue entries separately');
assert.equal(context.getVisibleBindings().length, 60, 'reference set is unchanged by modifiers');
assert.doesNotMatch(key_buttons[4].className, /assigned/, "Ctrl+Shift does not color the Win-only shortcut");
assert.doesNotMatch(key_buttons[8].className, /assigned/, "Ctrl+Shift does not color the Shift+Alt+Win shortcut");
var exact_rows = context.getVisibleBindings().filter(b => context.usesActiveModifiers(b.modifiers || [], ['Ctrl','Shift']));
assert.match(ids.bindingPageStatus.innerText, new RegExp('^' + exact_rows.length + ' matches'), 'overview contains only exact Ctrl+Shift shortcuts');
context.physical_modifiers.Shift = false;
context.physical_modifiers.Win = true;
context.updateKeyboardHighlights();
exact_rows = context.getVisibleBindings().filter(b => context.usesActiveModifiers(b.modifiers || [], ['Ctrl','Win']));
assert.match(ids.bindingPageStatus.innerText, new RegExp('^' + exact_rows.length + ' matches'), 'Ctrl+Win overview excludes Ctrl-only and Ctrl+Shift shortcuts');
assert.doesNotMatch(key_buttons[5].className, /shortcut-match/, 'Ctrl+Win hides U without that exact combination');
context.physical_modifiers.Win = false;
context.physical_modifiers.Shift = true;
context.updateKeyboardHighlights();

context.physical_modifiers.Ctrl = false;
context.physical_modifiers.Shift = false;
context.openKeyEditor(key_buttons[5]);
assert.equal(ids.shortcutField.value, "U", "clicking a key opens an unmodified shortcut draft");
context.selectKey(key_buttons[5]);
context.updateKeyboardHighlights();
assert.equal(key_buttons[5].style.background, '', 'selected U uses original selection styling, not an RGB band');
context.editBinding(1);
assert.equal(ids.shortcutField.value, "Ctrl + Shift + U", "overview editing opens the assigned shortcut");
assert.match(key_buttons[5].className, /shortcut-match/, "overview editing activates the matching layout highlight");
ids.bindingFilePath.value = "C:\\Tools\\NameCase.ahk";
context.saveBinding();
assert.equal(context.shortcut_bindings[1].file_path, "C:\\Tools\\NameCase.ahk", "file target saved to shortcut record");
assert.match(context.buildFileBindingIni(), /Ctrl\+Shift\+U=C:\\Tools\\NameCase\.ahk/, "file target serialized for AutoHotkey runtime");

const fake_max_xml = {
  getElementsByTagName(tag) {
    const rows = tag === "Assign_Hotkey" ? [
      { Shortcut: "Ctrl+G", Description: "Grow Selection", Id: "123-test" },
      { Shortcut: "Shift+Y", Description: "Another action", Id: "124-test" }
    ] : [{ Shortcut: "G", Description: "Old action", Id: "125-test" }];
    return rows.map(row => ({ getAttribute(attr) { return row[attr]; } }));
  }
};
const imported = context.parseMaxHotkeys(fake_max_xml);
assert.equal(imported.assignments.length, 2, "3ds Max assignments imported from HSX XML");
assert.equal(imported.removals.length, 1, "3ds Max unassignments are retained separately");
assert.equal(imported.assignments[0].key, "G", "shortcut key extracted correctly");
assert.deepEqual(Array.from(imported.assignments[0].modifiers), ["Ctrl"], "shortcut modifier extracted correctly");
assert.equal(imported.assignments[0].id, "123-test", "original 3ds Max action ID preserved");
const fake_default_xml = {
  getElementsByTagName(tag) {
    if (tag !== "Hotkey") { return []; }
    return [
      { Shortcut: "Ctrl+G", Description: "Original grow", Id: "123-test" },
      { Shortcut: "Shift+S", Description: "Save A", Id: "200-A" },
      { Shortcut: "Shift+S", Description: "Save B", Id: "201-B" }
    ].map(row => ({ getAttribute(attr) { return row[attr]; } }));
  }
};
const factory = context.parseMaxDefaultHotkeys(fake_default_xml);
assert.equal(factory.length, 3, "factory Hotkey nodes are parsed");
assert.equal(factory[0].origin, "Default", "factory entries retain provenance");
const changes = {
  removals: [{ id: "123-test", shortcut: "Ctrl+G" }, { id: "does-not-exist", shortcut: "Z" }],
  assignments: [{ id: "123-test", shortcut: "Alt+G", key: "G", modifiers: ["Alt"], name: "Remapped grow" }]
};
const merged = context.applyMaxOverlay(factory, changes);
assert.equal(merged.length, 3, "overlay removes exact action/shortcut before adding custom action");
assert.ok(!merged.some(binding => binding.id === "123-test" && binding.shortcut === "Ctrl+G"), "old factory shortcut removed by exact action identity");
assert.ok(merged.some(binding => binding.id === "123-test" && binding.shortcut === "Alt+G" && binding.origin === "Custom"), "custom replacement takes effect");
assert.equal(merged.filter(binding => binding.shortcut === "Shift+S").length, 2, "different 3ds Max action contexts can share a shortcut");
const real_effective = context.applyMaxOverlay(preset_context.bundled_max_defaults.defaults, preset_context.bundled_max_hsx);
assert.equal(real_effective.length, 575, "factory defaults and actual vilbur overlay produce 575 effective bindings");
context.imported_max_bindings = real_effective;
context.setSourceProfile("max");
assert.equal(ids.bindingOverview.children.length, 4, "large 3ds Max catalogs show four rows at a time");
assert.match(ids.bindingPageStatus.innerText, /575 matches \| Page 1\/144/, "imported catalog displays page count");
context.changeOverviewPage(1);
assert.match(ids.bindingPageStatus.innerText, /Page 2\/144/, "next page changes the visible page");
ids.bindingSearch.value = "Save File As";
context.filterBindingOverview();
assert.ok(ids.bindingOverview.children.length <= 4, "search results remain bounded to one page");
assert.match(ids.bindingPageStatus.innerText, /Page 1\//, "search resets to the first page");
ids.bindingSearch.value = "";
context.filterBindingOverview();
context.screen = { availWidth: 1920, availHeight: 900 };
context.sizeKeyboardWindow();
assert.deepEqual(resize_calls.at(-1), [1920, 900], "window size respects the available monitor work area");
assert.ok(ids.keyboardShell.style.zoom > 0 && ids.keyboardShell.style.zoom < 1, "layout scales down on smaller monitors instead of showing scrollbars");

context.imported_max_bindings = imported.assignments;
context.setSourceProfile("max");
assert.equal(key_buttons[4].style.borderColor, '#F16D77', 'imported Ctrl+G has red full-key border');
context.setSourceProfile("windows");

context.latched_modifiers.Ctrl = false;
context.latched_modifiers.Shift = false;
context.latched_modifiers.Alt = true;
context.editing_binding_index = -1;
context.openKeyEditor(key_buttons[6]);
assert.equal(ids.shortcutField.value, "Alt + A", "active modifiers are captured for a new shortcut");
ids.commandName.value = "Alt A test";
ids.actionType.value = "custom";
context.saveBinding();
assert.equal(context.shortcut_bindings.length, 22, "saving adds a new shortcut");
assert.match(key_buttons[6].className, /shortcut-match/, "new binding highlights its assigned key");
context.deleteBinding();
assert.equal(context.shortcut_bindings.length, 21, "delete removes the selected shortcut");

console.log("PASS: accumulated modifier colours, original highlights, filtering, key editing, add, and delete.");


assert.match(hta, /\.navpad \.arrow-top \{[^}]*margin-top:\s*42px;/, "arrow group aligns with the Space row");
assert.match(hta, /class="key num-plus">\+<\/button>/, "numpad plus has distinct two-row class");
assert.match(hta, /\.numpad \.key\.num-plus \{[^}]*height:\s*69px;[^}]*vertical-align:\s*top;/, "numpad plus spans two rows without shifting other keys");
assert.match(hta, /class="keyrow plus-following-row"/, "numpad second row stays aligned under tall plus");
assert.match(hta, /class="key num-zero">0<\/button>/, "numpad zero has separate double-width class");
assert.match(hta, /\.numpad \.key\.num-zero \{[^}]*width:\s*75px;/, "numpad zero spans two key widths");

assert.match(hta, /<option value="irfanview_image">IrfanView image<\/option>/, "new action is shown without hotkey prefix");
assert.ok(context.shortcut_bindings.some(x => x.action === "irfanview_image" && x.key === "I" && x.modifiers.length === 1 && x.modifiers[0] === "Win"), "Win+I action is in UI binding set");
ids.actionType.value = "irfanview_image";
context.updateActionDescription();
assert.match(ids.actionDescription.innerText, /clipboard image or open its file path/, "IrfanView action has short UI help");

// IrfanView inline help describes the window-cycling fallback.
assert.match(hta, /If neither is available, cycle open IrfanView windows/, 'IrfanView helper documents no-clipboard fallback');

assert.match(hta, /onclick="openHotkeyIndex\(\)"/, "main editor opens standalone Hotkey Index");
assert.match(hta, /src="data\/Keyboard-Setup-Catalog\.js"/, "editor uses shared runtime action catalogue");
assert.equal(context.keyboard_shortcut_catalog.length, 21, "index and editor share 21 runtime hotkeys");

assert.match(hta, /windows_shell\.AppActivate\("Keyboard Hotkey Index"\)/, "main UI activates existing index before launching");

// v0.19 action monitor: action name and description below the keyboard.
assert.match(hta, /id="shortcutMonitor"/, 'bottom-centred action monitor exists');
assert.match(hta, /\.shortcut-monitor\s*\{[^}]*text-align:\s*center/, 'action monitor is horizontally centred');
assert.equal(context.keyboardShowShortcutByParts('Y', ['Win']), true, 'registered YouTube action is recognised');
assert.equal(ids.shortcutMonitorAction.innerText, 'YouTube window', 'action name is displayed');
assert.match(ids.shortcutMonitorDescription.innerText, /new Chrome window/, 'action summary is displayed');
assert.equal(context.keyboardShowShortcutByParts('F4', ['Ctrl', 'Win']), true, 'Toolkit shortcut is recognised');
assert.equal(ids.shortcutMonitorAction.innerText, 'Kill all active-window processes', 'Toolkit action is displayed');
assert.equal(context.keyboardShowShortcutByParts('F5', []), false, 'unassigned chord does not replace current message');
assert.equal(ids.shortcutMonitorAction.innerText, 'Kill all active-window processes');
const previous = context.keyboard_action_last_serial;
assert.equal(context.keyboardConsumeRuntimeActionText('Shortcut=Win+I\r\nSerial=123-1\r\n', true), false, 'stale event on editor open is ignored');
assert.equal(context.keyboardConsumeRuntimeActionText('Shortcut=Win+I\r\nSerial=123-2\r\n', false), true, 'new runtime event updates the monitor');
assert.equal(ids.shortcutMonitorAction.innerText, 'IrfanView image');
assert.equal(context.keyboardConsumeRuntimeActionText('Shortcut=Win+I\r\nSerial=123-2\r\n', false), false, 'already seen event does not repeat');
context.setSourceProfile('max');
assert.equal(context.keyboardConsumeRuntimeActionText('Shortcut=Win+Y\r\nSerial=123-3\r\n', false), false, 'global hotkey event does not masquerade as Max execution');
context.setSourceProfile('windows');
assert.equal(context.keyboardShortcutKeyDown({keyCode:89,metaKey:true,ctrlKey:false,shiftKey:false,altKey:false}), true, 'focused keydown previews registered shortcut');
assert.equal(ids.shortcutMonitorAction.innerText, 'YouTube window');
console.log('PASS: bottom shortcut monitor, AHK event parsing, preview, and source scoping.');

assert.doesNotMatch(hta, /<option value="max_default">/, 'single 3ds Max source replaces effective/factory profiles');
assert.match(hta, /3ds Max \(Default \+ User defined\)/, 'single Max source displays new origin terms');
const windowsUi = context.keyboardMergedWindowsBindings();
assert.ok(windowsUi.length > 50, 'Windows shortcut references share the keyboard with resident actions');
assert.equal(windowsUi.filter(x => x.origin === 'User defined').length, 21, 'PowerKeys / AHK actions override Windows defaults');
assert.equal(windowsUi.filter(x => x.key === 'I' && x.modifiers.join('+') === 'Win').length, 1, 'Win+I has only its user-defined IrfanView action');
assert.equal(windowsUi.filter(x => context.keyboardNormalizeShortcut(x.shortcut) === 'ctrl+win+f4').length, 1, 'same modifiers in different order are not duplicate actions');
assert.equal(windowsUi.length, 60, 'Windows program contains only effective shortcuts');
context.setSourceProfile('windows');
assert.match(ids.actionDescription.innerText, /Custom command|IrfanView|Windows default/, 'Windows list supports both editable resident actions and reference defaults');
assert.equal(context.keyboardConsumeRuntimeActionText('Shortcut=Win+I\r\nSerial=456-1\r\n', false), true, 'runtime resident event remains visible in combined Windows view');
assert.equal(ids.shortcutMonitorAction.innerText, 'IrfanView image');
context.setSourceProfile('windows');
assert.equal((hta.match(/<option value="(?:windows|max)">/g) || []).length, 2, 'two frontend program sources, no split defaults or toolkit');
context.setSourceProfile('windows');
const ref_pos = context.keyboardMergedWindowsBindings().findIndex(x => x.name === 'File Explorer');
context.editBinding(ref_pos);
assert.equal(ids.saveBindingButton.disabled, true, 'Windows native default remains read-only');
const custom_pos = context.keyboardMergedWindowsBindings().findIndex(x => x.action === undefined && x.name === 'YouTube window');
context.editBinding(custom_pos);
assert.equal(ids.saveBindingButton.disabled, false, 'resident user action can still be edited from the combined program view');
console.log('PASS: merged Max and Windows sources, read-only native bindings and editable resident actions.');

// v0.24: registered PowerKeys actions visually identify suppressed Windows defaults.
const originalSettings = context.keyboardWindowsOverrideForChord('Win+I');
assert.equal(originalSettings.name, 'Settings', 'Win+I has Windows Settings as its original default');
assert.equal(context.keyboardWindowsOverrideForChord('Ctrl+Win+F4').name, 'Close virtual desktop', 'modifier order does not break override detection');
assert.equal(context.keyboardWindowsOverrideForChord('Win+E').name, 'File Explorer', 'unoverridden Windows default is available as reference');
assert.equal(context.keyboardMergedWindowsBindings().find(x => x.name === 'IrfanView image').windows_override, 'Settings', 'merged Windows list includes the overridden default as a visible note');
const winIpos = context.keyboardMergedWindowsBindings().findIndex(x => x.name === 'IrfanView image');
context.editBinding(winIpos);
assert.equal(ids.windowsOverrideNotice.style.display, 'block', 'editor shows override warning for assigned Windows chord');
assert.match(ids.windowsOverrideNotice.innerText, /Overrides Windows default: Settings/, 'editor identifies the overridden native action');
assert.equal(context.keyboardShowShortcutByParts('I', ['Win']), true, 'bottom action display recognises Win+I');
assert.match(ids.shortcutMonitorDescription.innerText, /Overrides Windows default: Settings/, 'action monitor also identifies overridden Windows action');
const ctrlWinF4 = context.keyboardMergedWindowsBindings().find(x => x.name === 'Kill all active-window processes');
assert.equal(ctrlWinF4.windows_override, 'Close virtual desktop', 'Ctrl+Win+F4 overrides Windows desktop closing');
const winEpos = context.keyboardMergedWindowsBindings().findIndex(x => x.name === 'File Explorer');
context.editBinding(winEpos);
assert.equal(ids.windowsOverrideNotice.style.display, 'none', 'read-only native Windows shortcut has no override note');
console.log('PASS: editor override notice, action monitor, normalised shortcut collision and untouched native defaults.');

assert.match(hta, /keyboardModifierDisplayUnionColor\(\[current\.modifiers \|\| \[\]\]\)/, 'binding overview uses non-white keycap colours');
console.log('PASS: shortcut overview matches keyboard display colours.');

/* v0.30: every shortcut becomes a separate paragraph in a native Windows tooltip. */
assert.equal(context.keyboardFormatKeyTooltip([]), '', 'unassigned keys have no tooltip');
assert.equal(context.keyboardFormatKeyTooltip(['Ctrl + U - Case']), 'Ctrl + U - Case', 'single shortcut has no extra lines');
assert.equal(context.keyboardFormatKeyTooltip(['Ctrl + U - Case', 'Ctrl + Shift + U - Convention']),
  'Ctrl + U - Case\r\n\r\nCtrl + Shift + U - Convention', 'two assignments have one blank line');
assert.equal(context.keyboardFormatKeyTooltip(['A', 'B', 'C']), 'A\r\n\r\nB\r\n\r\nC',
  'three shortcuts are divided by exactly one blank line, with no trailing blank line');
context.setSourceProfile('windows');
context.physical_modifiers.Ctrl = false;
context.physical_modifiers.Shift = false;
context.physical_modifiers.Win = false;
context.physical_modifiers.Alt = false;
context.latched_modifiers.Ctrl = false;
context.latched_modifiers.Shift = false;
context.latched_modifiers.Win = false;
context.latched_modifiers.Alt = false;
context.updateKeyboardHighlights();
assert.match(key_buttons[5].title, /\r\n\r\n/, 'U tooltip separates multiple actual Windows shortcuts by a blank line');
assert.doesNotMatch(key_buttons[5].title, / \| /, 'key tooltip no longer uses inline pipe separators');
context.physical_modifiers.Ctrl = true;
context.updateKeyboardHighlights();
assert.match(key_buttons[5].title, /Ctrl \+ U - /, 'Ctrl tooltip includes only Ctrl+U action');
assert.doesNotMatch(key_buttons[5].title, /\r\n\r\n|Ctrl \+ Shift \+ U/, 'Ctrl-only tooltip has no unrelated or surplus-modifier entries');
context.physical_modifiers.Shift = true;
context.updateKeyboardHighlights();
assert.match(key_buttons[5].title, /Ctrl \+ Shift \+ U - /, 'exact Ctrl+Shift tooltip contains the correct assignment');
assert.doesNotMatch(key_buttons[5].title, /\r\n\r\n/, 'single exact match has no blank separator');
context.physical_modifiers.Ctrl = false;
context.physical_modifiers.Shift = false;
context.updateKeyboardHighlights();
console.log('PASS: key hover tooltips use blank lines and preserve exact-modifier filtering.');


/* v0.30: enlarge every UI font, but leave actual keyboard key geometry/labels untouched. */
assert.match(hta, /html, body \{[^}]*font: 16px "Segoe UI"/, 'main UI body text increased from 14 to 16 px');
assert.match(hta, /\.modifier-legend \{[^}]*font-size: 12px;/, 'modifier legend text 10 -> 12');
assert.match(hta, /\.modifier-status \{[^}]*font-size: 12px;/, 'modifier status text 10 -> 12');
assert.match(hta, /\.legend-dot \{[^}]*width:18px; height:18px;/, 'modifier colour markers enlarged 11 -> 18');
assert.match(hta, /\.editor label \{[^}]*font-size: 13px;/, 'editor form labels enlarged by 2 px');
assert.match(hta, /\.shortcut-monitor \.monitor-action \{[^}]*font-size: 23px;/, 'bottom monitor action enlarged by 2');
assert.match(hta, /\.key \{[^}]*height: 32px;[^}]*font-size: 10px;/, 'keyboard keys remain 10px and 32px tall');
assert.match(hta, /\.key\.main-tab \{[^}]*width: 49px;/, 'narrow Tab preserved');
assert.match(hta, /\.key\.caps-lock \{[^}]*width: 67px;/, 'Caps width preserved');
assert.match(hta, /\.key\.right-ctrl \{[^}]*width: 52px;/, 'right Ctrl aligned with Enter');
console.log('PASS: main UI text increased by 2 px, swatches enlarged, keyboard geometry and labels unchanged.');
