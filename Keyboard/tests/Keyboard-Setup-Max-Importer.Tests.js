const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

const hta = fs.readFileSync('Keyboard-Setup-Design-Options.hta', 'utf8');
const launcher = fs.readFileSync('Keyboard-Setup-Launcher.ahk', 'utf8');
const moduleAHK = fs.readFileSync('import/3DsMax/3DsMax-Importer.ahk', 'utf8');
const exporter = fs.readFileSync('import/3DsMax/3DsMax-Export.ms', 'utf8');
const dialog = fs.readFileSync('import/3DsMax/3DsMax-Importer.js', 'utf8');

assert.match(hta, /src="import\/3DsMax\/3DsMax-Importer\.js"/, 'separate importer JS is included');
assert.match(hta, /id="maxImporterBackdrop"/, 'importer has its own dialog');
assert.match(hta, /onclick="maxImporterOpen\(\)"/, 'importer can be opened');
assert.match(launcher, /#Include %A_ScriptDir%\\import\\3DsMax\\3DsMax-Importer\.ahk/, 'resident includes importer runtime');
assert.match(launcher, /SetTimer, keyboardCheckMaxImportRequest, 500/, 'resident polls explicit import requests');
assert.match(moduleAHK, /keyboardImportFindRunningMax\(max_exe\)/, 'check already running selected Max');
assert.match(moduleAHK, /if \(running_pid\)/, 'existing process is reused');
assert.match(moduleAHK, /keyboardImportToRunningMax\(running_pid, script_path\)/, 'send exporter to MAXScript Listener');
assert.match(moduleAHK, /MXS_Scintilla/, 'target native MaxScript mini-listener control');
assert.match(moduleAHK, /WM_SETTEXT/, 'send the command directly without clipboard');
assert.match(moduleAHK, /PostMessage/, 'execute fileIn using native Enter message');
assert.doesNotMatch(moduleAHK, /ClipboardAll/, 'do not disturb user clipboard');
assert.match(moduleAHK, /FileCopy, %script_path%, %temporary_script%, 0/, 'create one-time startup script when Max not running');
assert.match(moduleAHK, /FileDelete, %temporary_script%/, 'remove only the startup script we created');
assert.match(moduleAHK, /keyboardImportCloseOwnMax\(started_pid\)/, 'only launched process is closed');
assert.match(exporter, /actionMan\.numActionTables/, 'export actual Action Tables');
assert.match(exporter, /getCategory &category_name/, 'export original supplied getHotkeyCategory semantics');
assert.match(exporter, /getDescription &description_text/, 'export action description');
assert.match(exporter, /action_table\.contextName/, 'retain Action Table context');
assert.match(exporter, /encoding:#utf8/, 'export uses unicode');
assert.ok(dialog.includes(String.raw`UI_LN\\CUI\\Default.hsxb`), "detector supports default installation");
assert.match(dialog, /Workspaces\\\\usersave/, 'detector supports workspaces usersave');
assert.match(dialog, /window\.confirm/, 'asks for confirmation');
assert.match(dialog, /maxImporterBrowse/, 'allows file fallback browse');
assert.match(dialog, /maxImporterReadCategoryData/, 'loads result and annotates bindings');
assert.match(dialog, /max_import_poll_count > 256/, 'status polling has an end timeout');

function dir(p) { return { Path: p, Name: p.split('\\').at(-1) }; }
const program = 'C:\\Program Files\\Autodesk';
const appData = 'C:\\Users\\user\\AppData\\Local\\Autodesk\\3dsMax';
const pf = [dir(program + '\\3ds Max 2025'), dir(program + '\\3ds Max 2026')];
const af = [dir(appData + '\\2025 - 64bit'), dir(appData + '\\2026 - 64bit')];
const userDir = appData + '\\2026 - 64bit\\ENU\\en-US\\UI\\Workspaces\\usersave';
const fsFolders = { [program]: {SubFolders: pf}, [appData]: {SubFolders: af}, [userDir]: {Files: [
  {Name:'3dsmaxShortcuts.hsx', Path:userDir+'\\3dsmaxShortcuts.hsx', DateLastModified: new Date('2026-10-22')},
  {Name:'vilbur.hsx', Path:userDir+'\\vilbur.hsx', DateLastModified: new Date('2026-10-01')}
]} };
const existing = new Set([
  program + '\\3ds Max 2025\\3dsmax.exe', program + '\\3ds Max 2026\\3dsmax.exe',
  program + '\\3ds Max 2026\\UI_LN\\CUI\\Default.hsxb'
]);
class EnumeratorMock {
  constructor(array) { this.items = array; this.index = 0; }
  atEnd() { return this.index >= this.items.length; }
  moveNext() { this.index += 1; }
  item() { return this.items[this.index]; }
}
const fsMock = {
  FolderExists(p) { return Object.hasOwn(fsFolders, p); },
  FileExists(p) { return existing.has(p); },
  GetFolder(p) { return fsFolders[p]; },
  BuildPath(a,b) { return a + '\\' + b; }
};
const shellMock = { ExpandEnvironmentStrings(str) {return str.replace('%ProgramFiles%', 'C:\\Program Files').replace('%LOCALAPPDATA%', 'C:\\Users\\user\\AppData\\Local'); } };
function ActiveXObjectMock(name) { return name === 'Scripting.FileSystemObject' ? fsMock : shellMock; }
const context = { Enumerator:EnumeratorMock, ActiveXObject:ActiveXObjectMock };
vm.runInNewContext(dialog, context);
const result = context.maxImporterDiscover();
assert.match(result.exe, /3ds Max 2026\\3dsmax\.exe$/, 'newest installed version wins');
assert.match(result.factory, /2026\\UI_LN\\CUI\\Default\.hsxb$/, 'matching factory source');
assert.match(result.user, /usersave\\vilbur\.hsx$/, 'user customisation is selected instead of empty preset');
assert.equal(result.year, 2026);
assert.equal(context.maxImporterNormalId('3450739058-12'), '-844228238-12', 'unsigned HSXB table ID matches signed MaxScript actionMan ID');
assert.equal(context.maxImporterNormalId('2077580866-40020'), '2077580866-40020', 'ordinary table IDs remain unchanged');
assert.equal(context.maxImporterNormalId('647394-macroName'), '647394-macroName', 'non-numeric action IDs are preserved');

console.log('PASS: 3ds Max importer dialog, newest-version discovery, MaxScript export wiring, runtime lifecycle.');
