const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const html = fs.readFileSync('src/Keyboard-Setup-Hotkey-Index.hta', 'utf8');
const scripts = [...html.matchAll(/<script language="javascript">([\s\S]*?)<\/script>/g)];
assert.equal(scripts.length, 2, 'index has its main script and a final startup script');
assert.match(html, /APPLICATIONNAME="Keyboard Hotkey Index"/, 'stable unique HTA application identity');
assert.match(html, /SINGLEINSTANCE="yes"/, 'index opens only once');
assert.match(html, /SCROLL="no"/, 'index prevents full-window scrollbars');
assert.match(html, /id="indexSearch"/, 'search field exists');
assert.match(html, /id="indexProfile"/, 'profile selector exists');
assert.match(html, /onclick="hotkeyIndexPage\(1\)"/, 'paging avoids scrolling hundreds of Max shortcuts');
assert.match(html, /\.\.\/data\/Keyboard-Setup-Catalog\.js/, 'index uses shared catalog');

const context = { Array, String, RegExp };
vm.createContext(context);
vm.runInContext(fs.readFileSync('data/Keyboard-Setup-Modifier-Colors.js', 'utf8'), context);
vm.runInContext(fs.readFileSync('data/Keyboard-Setup-Catalog.js', 'utf8'), context);
vm.runInContext(fs.readFileSync('data/Keyboard-Setup-Windows.js', 'utf8'), context);
vm.runInContext(fs.readFileSync('data/Keyboard-Setup-Max-Defaults.js', 'utf8'), context);
vm.runInContext(fs.readFileSync('data/Keyboard-Setup-Max-Preset.js', 'utf8'), context);
vm.runInContext(scripts[0][1], context);
const windows = context.hotkeyIndexRecords('windows');
assert.ok(windows.length > 50, 'Windows combines native and 21 resident bindings');
assert.equal(windows.filter(x => x.status === 'User defined').length, 21, 'all resident PowerKeys / AHK and Toolkit bindings are merged');
assert.equal(windows.filter(x => x.status === 'Default').length, 39, 'unoverridden Windows shortcuts remain after modifier-order normalization');
assert.equal(windows.find(x => x.name === 'IrfanView image').shortcut, 'Win + I');
assert.equal(windows.find(x => x.name === 'Wrap / unwrap double quotes').shortcut, 'Ctrl + "');
assert.deepEqual(Array.from(windows, x => x.id), [...new Set(Array.from(windows, x => x.id))], 'Windows shortcut identities are unique');
assert.equal(windows.find(x => x.shortcut === 'Win + Pause').name, 'Mute launcher');
assert.match(windows.find(x => x.shortcut === 'Ctrl + Win + F4').flow, /confirmation|Ask before/i);
assert.doesNotMatch(html, /<option value="(?:global|toolkit|max_default)">/, 'no split subprofiles in the index');
assert.equal((html.match(/<option value="(?:windows|max)">/g) || []).length, 2, 'one index profile per program');

const effective = context.hotkeyIndexRecords('max');
assert.equal(context.bundled_max_defaults.defaults.length, 532, 'source contains 532 factory records');
assert.doesNotMatch(html, /<option value="max_default">/, 'factory and effective are merged into one source');
assert.equal(effective.length, 575, 'Max overlay produces 575 effective shortcut references');
assert.ok(effective.some(x => x.status === 'User defined'), 'user changes are labelled as User defined');
assert.ok(effective.some(x => x.status === 'Default'), 'untouched factory changes are labelled Default');
assert.ok(effective.every(x => x.flow.includes('not a global Windows hotkey')), 'Max hotkeys are not represented as Windows-wide');
assert.equal(context.hotkey_index_page_size, 12, 'limited rows per page, no long scroll');
assert.match(fs.readFileSync('Keyboard-Setup-Launcher.ahk', 'utf8'), /Menu, Tray, Add, Hotkey Index, openHotkeyIndex/);
assert.match(fs.readFileSync('Keyboard-Setup-Design-Options.hta', 'utf8'), /onclick="openHotkeyIndex\(\)"/);
console.log('PASS: standalone index, shared catalog, hotkey flows, profiles, paging, and singleton.');

/* v0.15: context-specific 3ds Max filtering uses exported ActionMan metadata. */
assert.match(html, /id="indexContextFilter"/, '3ds Max context selector exists');
assert.match(html, /id="indexMetadataStatus"/, 'metadata availability is disclosed');
assert.match(html, /indexDetailMetadata/, 'action details show Context, Action Table and Category');
assert.match(html, /ActionTables\.tsv/, 'context information reads the real ActionMan TSV');
assert.match(html, /hotkeyIndexMatchesContext\(r, context_filter\)/, 'the selected context filters rendered results');
assert.match(html, /r\.action_table/, 'search also includes action tables');
assert.equal(context.hotkey_index_version, '0.30');
assert.equal(context.hotkeyIndexNormalId('3000000000-42'), '-1294967296-42', 'unsigned table IDs map to signed ActionMan IDs');
assert.equal(context.hotkeyIndexNormalId('135018555-32900'), '135018555-32900', 'regular IDs retain their value');
const referenceId = context.bundled_max_defaults.defaults[0].id;
const sampleMetadata = {};
sampleMetadata[referenceId] = {context:'Editable Poly', action_table:'Edit Poly', category:'Polygon Editing', description:'Example from exporter'};
const contextAwareRecords = context.hotkeyIndexRecords('max', sampleMetadata);
assert.equal(contextAwareRecords.length, 575, 'metadata enrichment does not change the number of hotkeys');
assert.equal(contextAwareRecords[0].context, 'Editable Poly');
assert.equal(contextAwareRecords[0].action_table, 'Edit Poly');
assert.equal(contextAwareRecords[0].category, 'Polygon Editing');
assert.equal(contextAwareRecords[0].when, 'Edit Poly', 'Action Table is displayed instead of generic 3ds Max');
assert.match(contextAwareRecords[0].metadata, /Context: Editable Poly.*Action table: Edit Poly.*Category: Polygon Editing/);
assert.equal(context.hotkeyIndexMatchesContext(contextAwareRecords[0], 'related:edit-poly'), true, 'Edit Poly quick filter matches exported Action Table and Context');
assert.equal(context.hotkeyIndexMatchesContext(contextAwareRecords[0], 'context:Editable Poly'), true, 'exact context filter works');
assert.equal(context.hotkeyIndexMatchesContext(contextAwareRecords[0], 'action_table:Edit Poly'), true, 'exact action table filter works');
assert.equal(context.hotkeyIndexMatchesContext(contextAwareRecords[0], 'category:Polygon Editing'), true, 'exact category filter works');
assert.equal(context.hotkeyIndexMatchesContext(contextAwareRecords[0], 'context:Edit Poly'), false, 'context and action table must not be conflated');
assert.equal(context.hotkeyIndexMatchesContext(contextAwareRecords[1], 'related:edit-poly'), false, 'unclassified actions must not be guessed to be Edit Poly');
const contextOptions = context.hotkeyIndexContextOptions(contextAwareRecords);
assert.ok(contextOptions.some(x => x.value === 'related:edit-poly'), 'Edit Poly option appears only when supported by metadata');
assert.ok(contextOptions.some(x => x.value === 'context:Editable Poly'), 'Context dropdown values are derived from real record fields');
assert.ok(contextOptions.some(x => x.value === 'action_table:Edit Poly'), 'Action Table dropdown values are derived from real record fields');
assert.ok(contextOptions.some(x => x.value === 'category:Polygon Editing'), 'Category dropdown values are derived from real record fields');
assert.equal(context.hotkeyIndexContextOptions(context.hotkeyIndexRecords('max', {})).length, 1,
  'without an export no context is invented');
console.log('PASS: 3ds Max context/table/category metadata, Edit Poly filtering, unclassified actions, and ID normalization.');

assert.match(html, /windows_shell\.AppActivate\("Keyboard Setup"\)/, "index activates existing main editor rather than launching a duplicate");
const win = context.hotkeyIndexRecords('windows');
assert.ok(win.length > 50, 'Windows defaults and PowerKeys / AHK shortcuts share a catalog');
assert.equal(win.filter(x => x.status === 'User defined').length, 21, '21 user actions win priority');
assert.ok(win.some(x => x.name === 'File Explorer' && x.status === 'Default'), 'unmodified Win+E remains');
assert.equal(win.filter(x => x.shortcut === 'Win + I').length, 1, 'Win+I Windows Settings is replaced by IrfanView');
assert.match(win.find(x => x.shortcut === 'Win + I').metadata, /Overrides Windows default: Settings/, 'original Windows action explained in details');
assert.equal(win.filter(x => x.shortcut === 'Win + R').length, 1, 'Win+R original Run dialog is hidden behind user action');
assert.equal(win.filter(x => context.hotkeyIndexNormalChord(x.shortcut) === context.hotkeyIndexNormalChord('Win+Ctrl+F4')).length, 1, 'modifier order does not duplicate the Windows virtual desktop shortcut overridden by Ctrl+Win+F4');
assert.equal(win.length, 60, 'one effective Windows entry per shortcut, including 21 resident actions');
assert.ok(!win.some(x => x.name === 'Run dialog'), 'overridden Windows default is not presented as active');
assert.match(html, /Windows \(Default \+ User defined\)/, 'combined Windows program is visible');
assert.ok(!html.includes('AutoHotkey Toolkit (14)</option>'), 'Toolkit hotkeys appear only in the Windows list');
console.log('PASS: merged Windows + user actions with override precedence and 3ds Max Default/User defined statuses.');

// v0.21: one effective custom action, with the Windows default called out prominently.
const byShortcut = chord => win.find(x => context.hotkeyIndexNormalChord(x.shortcut) === context.hotkeyIndexNormalChord(chord));
assert.equal(byShortcut('Win+I').when, 'Overrides Windows: Settings', 'index table visibly names overridden Windows shortcut');
assert.equal(byShortcut('Win+I').windows_override, 'Settings', 'structured override metadata survives merging');
assert.match(byShortcut('Win+I').metadata, /native Windows action is not forwarded/i, 'details explain native action suppression condition');
assert.equal(byShortcut('Win+Ctrl+F4').windows_override, 'Close virtual desktop', 'Ctrl+Win+F4 matches OS default regardless of modifier order');
assert.equal(byShortcut('Win+E').name, 'File Explorer', 'unaltered Windows hotkey remains a default');
assert.equal(byShortcut('Win+E').windows_override, undefined, 'unaltered Windows hotkey has no spurious override note');
assert.match(html, /override-context/, 'index styles the override note distinctly in list');
console.log('PASS: visible Windows override notes, conditional native suppression and canonical chord matching.');

assert.match(html, /keyboardModifierDisplayUnionColor\(\[item\.modifiers\]\)/, 'index uses non-white keycap combination colour');
assert.match(html, /if \(!rgb\) \{rgb="#D7A94F";\}/, 'Alt-only shortcut uses a neutral/gold swatch instead of white');
console.log('PASS: Hotkey Index uses saturated keycap colours without white Alt overlays.');


/* v0.30: typography increases in the standalone Hotkey Index, too. */
assert.match(html, /var hotkey_index_version = "0\.30"/, 'index version is updated');
assert.match(html, /html,body \{[^}]*font:15px "Segoe UI"/, 'index base font 13 -> 15 px');
assert.match(html, /\.modifier-swatch \{[^}]*width:14px;height:17px;/, 'index swatches are larger');
console.log('PASS: Hotkey Index font sizes and modifier swatches enlarged.');
