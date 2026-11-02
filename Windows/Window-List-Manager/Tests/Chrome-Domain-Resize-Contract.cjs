/* Verify that Chrome domain list activation retains the domain used for sizing. */
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const library = path.join(root, 'Lib');
const versions = fs.readdirSync(library)
    .filter(name => /^Window-List-Manager-0\.\d{3}\.ahk$/.test(name))
    .sort((left, right) => Number(right.match(/0\.(\d{3})/)[1]) - Number(left.match(/0\.(\d{3})/)[1]));
const source = fs.readFileSync(path.join(library, versions[0]), 'utf8');
const ahk_tests = fs.readFileSync(path.join(root, 'Tests', 'Window-List-Manager-Test.ahk'), 'utf8');

assert.match(source, /onWindowDoubleClick\(control, row\)[\s\S]*?row_domains\.Get\(row, ""\)[\s\S]*?activateListedWindowByHwnd\(target_hwnd, true, [a-z_]+\)/,
    'double-click must carry the domain associated with the clicked row');
assert.match(source, /activateListedWindowByHwnd\(hwnd, resize_on_focus, [a-z_]+ := ""\)[\s\S]*?applyFocusResize\(hwnd, [a-z_]+\)/,
    'confirmed activation must forward the listed domain to focus sizing');
assert.match(source, /applyFocusResize\(hwnd, [a-z_]+ := ""\)[\s\S]*?resolveFocusResizeDomain\(app_name, hwnd, [a-z_]+\)/,
    'focus sizing must resolve domain using the selected row as its first choice');
assert.match(ahk_tests, /listed Chrome domain survives missing fresh bridge match/,
    'native test must verify the selected Chrome domain survives a missing bridge match');

console.log('Chrome domain resize activation contract: PASS');
