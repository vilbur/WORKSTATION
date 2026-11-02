'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.join(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'Lib', 'Window-List-Manager-0.242.ahk'), 'utf8');
const ahk_tests = fs.readFileSync(path.join(__dirname, 'Window-List-Manager-Test.ahk'), 'utf8');

assert.match(source, /global app_version := "0\.242"/, 'release version matches');
assert.match(source, /options_list\.OnEvent\("Click", onAppColorClick\)/, 'app cell receives click');
assert.match(source, /onAppColorClick\(control, row\)[\s\S]*?subitem = 2[\s\S]*?optionsSetColor\(\)/, 'only application color cell opens picker');
assert.match(source, /options_list\.Add\("", app_name, getAppPriority\(app_name\), "Choose\.\.\."\)/, 'application list uses a swatch label, not a raw hex value');
assert.match(source, /options_app_colors\[item\] := getGroupColor\(app_name, "", ""\)/, 'swatch previews effective application color');
assert.match(source, /onAppColorDraw\(l_param\)[\s\S]*?subitem != 2[\s\S]*?getColorLabelText\(color\)/, 'swatch uses contrasting text');
assert.match(source, /notify_hwnd = app_hwnd[\s\S]*?onAppColorDraw\(l_param\)/, 'custom draw is routed to app list');
assert.match(ahk_tests, /Window-List-Manager-0\.243\.ahk/, 'AHK tests use current implementation');
assert.match(ahk_tests, /app swatch previews effective program color/, 'AHK test verifies stored color');

console.log('Application Color Picker contract: PASS');
