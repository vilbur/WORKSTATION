/* Static contract for native-AHK domain matching; run the paired AHK tests on Windows. */
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const base_dir = path.resolve(__dirname, "..");
const src = fs.readFileSync(path.join(base_dir, "Lib", "Window-List-Manager-0.241.ahk"), "utf8");
const tests = fs.readFileSync(path.join(base_dir, "Tests", "Window-List-Manager-Test.ahk"), "utf8");
assert.match(src, /matchChromeRecordByRect\(/, "native matcher needs exact title and geometry implementation");
assert.match(src, /StrLower\(Trim\(RegExReplace\(title/, "must normalize real Chrome title");
assert.match(src, /StrLower\(Trim\(record\.title\)\)/, "must compare complete active-tab title");
assert.match(src, /second_distance/, "must reject ambiguous duplicate titles and overlapping rectangles");
assert.match(src, /window_domain_overrides\.Delete\(hwnd\)/, "live Chrome domain must clear stale manual override");
assert.match(tests, /ambiguous same-title overlapping Chrome windows use fallback color/, "native AHK regression cases must cover ambiguity");
console.log("Chrome domain color source contract: passed");
