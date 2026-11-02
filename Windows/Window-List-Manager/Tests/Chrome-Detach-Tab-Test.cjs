/* Verify Chrome detach uses the original tab ID without cloning or navigating the tab. */
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const project_dir = path.resolve(__dirname, "..");
const extension_source = fs.readFileSync(path.join(project_dir, "Library", "Chrome-Extension", "background.js"), "utf8");
const bridge_source = fs.readFileSync(path.join(project_dir, "Library", "Chrome-Domain-Bridge.ps1"), "utf8");
const manager_source = fs.readFileSync(path.join(project_dir, "Lib", "Window-List-Manager-0.240.ahk"), "utf8");

function getDetachHandler(chrome)
{
    const source = extension_source.match(/async function detachChromeTabCommand\([^)]*\)\s*\{[\s\S]*?\n\}/);
    assert.ok(source, "Chrome extension must implement detachChromeTabCommand");
    return vm.runInNewContext(source[0] + "\ndetachChromeTabCommand", {chrome});
}

async function run()
{
    const calls = [];
    const tab = {id: 22, windowId: 9, active: true, pinned: false};
    const chrome = {
        tabs: {
            get: async function(tab_id) { assert.equal(tab_id, 22); return tab; },
            query: async function(query) { assert.equal(query.windowId, 9); return [tab, {id: 23}]; },
            update: async function(tab_id, update) { calls.push(["update", tab_id, update]); }
        },
        windows: {
            get: async function(window_id) { assert.equal(window_id, 9); return {id: 9, type: "normal"}; },
            create: async function(create_options)
            {
                calls.push(["create", create_options]);
                return {id: 50};
            }
        }
    };
    const detach = getDetachHandler(chrome);
    await detach({window_id: 9, tab_id: 22});
    assert.equal(calls.length, 1, "regular tab needs exactly one native window creation");
    assert.equal(calls[0][0], "create");
    assert.equal(calls[0][1].tabId, 22, "move existing tab, do not clone by URL");
    assert.equal(calls[0][1].focused, true, "new window becomes active");

    calls.length = 0;
    tab.windowId = 77;
    await detach({window_id: 9, tab_id: 22});
    assert.equal(calls.length, 0, "moved tab must not be detached twice");

    tab.windowId = 9;
    chrome.tabs.query = async function() { return [tab]; };
    await detach({window_id: 9, tab_id: 22});
    assert.equal(calls.length, 0, "single-tab window must remain intact");

    chrome.tabs.query = async function() { return [tab, {id: 23}]; };
    tab.active = false;
    await detach({window_id: 9, tab_id: 22});
    assert.equal(calls.length, 0, "no longer active tab must remain intact");

    tab.active = true;
    tab.pinned = true;
    await detach({window_id: 9, tab_id: 22});
    assert.equal(calls.length, 3, "pinned tab must be unpinned and restored around native detach");
    assert.deepEqual(calls.map(function(call) { return call[0]; }), ["update", "create", "update"]);
    assert.equal(calls[0][2].pinned, false);
    assert.equal(calls[2][2].pinned, true);

    assert.match(extension_source, /tab_count:\s*\(w\.tabs\s*\|\|\s*\[\]\)\.length/, "snapshot must include tab count");
    assert.match(bridge_source, /detach_tab/, "bridge must transport detach_tab command");
    assert.match(bridge_source, /tab_count/, "bridge must transport tab count");
    assert.match(bridge_source, /\$fields\.Count -eq 4/, "bridge must require four detach command fields");
    assert.match(bridge_source, /\$fields\[0\] -cne \$ClientId/, "bridge must reject wrong Chrome profile");
    assert.match(bridge_source, /\$domain -ne ''/, "Chrome internal pages with no domain must be eligible");
    assert.match(manager_source, /context_menu\.Add\("Detach tab"/, "context item must be first Chrome action");
    assert.match(manager_source, /canDetachChromeTab/, "manager must guard single-tab windows");
    assert.match(manager_source, /"0\.240"/, "new version must be 0.240");
    console.log("Chrome detach contract: passed");
}

run().catch(function(error)
{
    console.error(error);
    process.exitCode = 1;
});
