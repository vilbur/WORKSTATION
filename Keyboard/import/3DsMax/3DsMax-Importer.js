/* 3ds Max-only import dialog.  HTA/MSHTML-compatible ES3 JavaScript. */
var max_import_timer = null;
var max_import_token = "";
var max_import_poll_count = 0;

function maxImporterFSO() { return new ActiveXObject("Scripting.FileSystemObject"); }
function maxImporterShell() { return new ActiveXObject("WScript.Shell"); }
function maxImporterPath(name) {
  var fs = maxImporterFSO();
  var config_dir = fs.GetParentFolderName(getConfigPath());
  var project_dir = fs.GetParentFolderName(config_dir);
  return fs.BuildPath(project_dir, "import\\3DsMax\\" + name);
}
function maxImporterTemp(name) { return maxImporterShell().ExpandEnvironmentStrings("%TEMP%") + "\\KeyboardSetupMaxImport\\" + name; }
function maxImporterStatus(message) { document.getElementById("maxImportMessage").innerText = message; }

function maxImporterDiscover()
{
  var fs = maxImporterFSO();
  var shell = maxImporterShell();
  var newest = 0;
  var max_path = "";
  var factory_path = "";
  var program_files = shell.ExpandEnvironmentStrings("%ProgramFiles%") + "\\Autodesk";
  if (fs.FolderExists(program_files))
  {
    var installed = new Enumerator(fs.GetFolder(program_files).SubFolders);
    for (; !installed.atEnd(); installed.moveNext())
    {
      var folder = installed.item();
      var match = /^3ds Max (\d{4})$/i.exec(folder.Name);
      if (!match || parseInt(match[1], 10) < newest) { continue; }
      var executable = fs.BuildPath(folder.Path, "3dsmax.exe");
      var candidate = fs.BuildPath(folder.Path, "UI_LN\\CUI\\Default.hsxb");
      if (fs.FileExists(executable))
      {
        newest = parseInt(match[1], 10);
        max_path = executable;
        factory_path = fs.FileExists(candidate) ? candidate : "";
      }
    }
  }
  var appdata = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") + "\\Autodesk\\3dsMax";
  var user_path = "";
  var preferred_time = 0;
  if (fs.FolderExists(appdata))
  {
    var versions = new Enumerator(fs.GetFolder(appdata).SubFolders);
    for (; !versions.atEnd(); versions.moveNext())
    {
      var version = versions.item();
      var matcher = /^(\d{4})\s*-\s*64bit$/i.exec(version.Name);
      if (!matcher || (newest && parseInt(matcher[1], 10) !== newest)) { continue; }
      var user_dir = fs.BuildPath(version.Path, "ENU\\en-US\\UI\\Workspaces\\usersave");
      if (!fs.FolderExists(user_dir)) { continue; }
      var items = new Enumerator(fs.GetFolder(user_dir).Files);
      for (; !items.atEnd(); items.moveNext())
      {
        var item = items.item();
        if (!/\.hsx$/i.test(item.Name)) { continue; }
        // Prefer actual user overlays to the empty 3dsmaxShortcuts.hsx preset.
        var priority = /vilbur/i.test(item.Name) ? 10000000000000 : (/3dsmaxShortcuts/i.test(item.Name) ? -10000000000000 : 0);
        var stamp = new Date(item.DateLastModified).getTime() + priority;
        if (!user_path || stamp > preferred_time) { user_path = item.Path; preferred_time = stamp; }
      }
    }
  }
  return { exe: max_path, factory: factory_path, user: user_path, year: newest };
}

function maxImporterOpen()
{
  document.getElementById("maxImporterBackdrop").style.display = "block";
  try
  {
    var found = maxImporterDiscover();
    var names = ["exe", "factory", "user"];
    var descriptions = ["3ds Max executable", "Default.hsxb", "User .hsx overlay"];
    for (var i = 0; i < names.length; i++)
    {
      var field = document.getElementById(names[i] === "exe" ? "maxImportExe" : (names[i] === "factory" ? "maxImportFactory" : "maxImportUser"));
      field.value = found[names[i]];
      if (found[names[i]])
      {
        if (!window.confirm("Use detected " + descriptions[i] + "?\n\n" + found[names[i]])) { field.value = ""; maxImporterBrowse(names[i]); }
      }
      else { maxImporterBrowse(names[i]); }
    }
    maxImporterStatus("3ds Max " + (found.year || "not detected") + ". Confirm paths, then click Import + export categories.");
  }
  catch (error) { maxImporterStatus("Detection failed: " + error.message + ". Browse for files manually."); }
}
function maxImporterClose() { document.getElementById("maxImporterBackdrop").style.display = "none"; }
function maxImporterBrowse(type)
{
  var field = type === "exe" ? "maxImportBrowseExe" : (type === "factory" ? "maxImportBrowseFactory" : "maxImportBrowseUser");
  document.getElementById(field).click();
}
function maxImporterBrowsed(type)
{
  var browse = type === "exe" ? "maxImportBrowseExe" : (type === "factory" ? "maxImportBrowseFactory" : "maxImportBrowseUser");
  var output = type === "exe" ? "maxImportExe" : (type === "factory" ? "maxImportFactory" : "maxImportUser");
  document.getElementById(output).value = document.getElementById(browse).value;
}
function maxImporterReadXml(path, root_name)
{
  var xml = new ActiveXObject("Msxml2.DOMDocument.6.0");
  xml.async = false;
  xml.setProperty("ProhibitDTD", true);
  if (!xml.load(path) || !xml.documentElement || xml.documentElement.nodeName !== root_name) { throw new Error("Invalid " + root_name + " XML: " + path); }
  return xml;
}
/*
Convert a DWORD table id into its signed MaxScript Int32 representation.
The MAXScript actionMan table.id value may be negative for unsigned IDs
higher than 2^31-1, even though HSXB writes the positive decimal value.
*/
function maxImporterNormalId(source_id)
{
  var match = /^(\d+)-(.*)$/.exec(source_id);
  if (!match) { return source_id; }
  var table_id = Number(match[1]);
  if (table_id > 2147483647 && table_id <= 4294967295) { table_id -= 4294967296; }
  return String(table_id) + "-" + match[2];
}

function maxImporterReadCategoryData(prefer_temp)
{
  var fs = maxImporterFSO();
  var path = prefer_temp ? maxImporterTemp("ActionTables.tsv") : maxImporterPath("ActionTables.tsv");
  if (!fs.FileExists(path)) { path = prefer_temp ? maxImporterPath("ActionTables.tsv") : maxImporterTemp("ActionTables.tsv"); }
  if (!fs.FileExists(path)) { return 0; }
  var input = new ActiveXObject("ADODB.Stream");
  input.Type = 2; input.Charset = "utf-8"; input.Open(); input.LoadFromFile(path);
  var lines = input.ReadText().split(/\r?\n/);
  input.Close();
  var lookup = {};
  for (var i = 1; i < lines.length; i++)
  {
    var fields = lines[i].split("\t");
    if (fields.length < 5 || !fields[0]) { continue; }
    lookup[fields[0]] = { category: fields[1], description: fields[2], action_table: fields[3], context: fields[4] };
  }
  var collections = [imported_max_defaults, imported_max_bindings];
  var count = 0;
  for (var a = 0; a < collections.length; a++)
  {
    for (var j = 0; j < collections[a].length; j++)
    {
      var binding = collections[a][j];
      var data = lookup[maxImporterNormalId(binding.id)];
      if (!data) { continue; }
      binding.category = data.category;
      binding.action_table = data.action_table;
      binding.context = data.context;
      if (data.description && !binding.name) { binding.name = data.description; }
      count++;
    }
  }
  return count;
}
function maxImporterStart()
{
  try
  {
    var fs = maxImporterFSO();
    var exe = document.getElementById("maxImportExe").value;
    var factory = document.getElementById("maxImportFactory").value;
    var overlay = document.getElementById("maxImportUser").value;
    if (!fs.FileExists(exe) || !/3dsmax\.exe$/i.test(exe)) { throw new Error("Choose the 3dsmax.exe executable."); }
    if (!fs.FileExists(factory) || !/\.hsxb$/i.test(factory)) { throw new Error("Choose an existing Default.hsxb file."); }
    if (!fs.FileExists(overlay) || !/\.hsx$/i.test(overlay)) { throw new Error("Choose an existing user .hsx file."); }
    imported_max_defaults = parseMaxDefaultHotkeys(maxImporterReadXml(factory, "MaxHotkeys"));
    imported_max_overlay = parseMaxHotkeys(maxImporterReadXml(overlay, "MaxHotkeyTransformations"));
    imported_max_removals = imported_max_overlay.removals;
    imported_max_bindings = applyMaxOverlay(imported_max_defaults, imported_max_overlay);
    updateMaxImportStatus();
    setSourceProfile("max");
    var dir = fs.GetParentFolderName(maxImporterTemp("request.ini"));
    if (!fs.FolderExists(dir)) { fs.CreateFolder(dir); }
    max_import_token = "KM" + new Date().getTime();
    max_import_poll_count = 0;
    var result = fs.CreateTextFile(maxImporterTemp("request.ini"), true, true);
    result.Write("[Request]\r\nState=queued\r\nToken=" + max_import_token + "\r\nMaxExe=" + exe + "\r\nFactory=" + factory + "\r\nOverlay=" + overlay + "\r\n");
    result.Close();
    maxImporterStatus("Imported shortcuts. Waiting for resident Keyboard Setup to send the category exporter to 3ds Max...");
    if (max_import_timer) { window.clearInterval(max_import_timer); }
    max_import_timer = window.setInterval(maxImporterPoll, 750);
  }
  catch (error) { maxImporterStatus("Import failed: " + error.message); }
}
function maxImporterPoll()
{
  try
  {
    max_import_poll_count++;
    if (max_import_poll_count > 256) // 192 seconds: cold 3ds Max startup can be slow
    {
      maxImporterStatus("Export timed out. Check the Keyboard Setup tray process and 3ds Max Listener. The selected sources have been loaded.");
      window.clearInterval(max_import_timer); max_import_timer = null;
      return;
    }
    var fs = maxImporterFSO();
    var file = maxImporterTemp("status.ini");
    if (!fs.FileExists(file)) { return; }
    var input = fs.OpenTextFile(file, 1, false, 0);
    var lines = input.ReadAll();
    input.Close();
    if (lines.indexOf("Token=" + max_import_token) < 0) { return; }
    if (lines.indexOf("State=done") >= 0)
    {
      var matched = maxImporterReadCategoryData(true);
      maxImporterStatus("3ds Max import complete. Category metadata matched to " + matched + " factory/effective records.");
      window.clearInterval(max_import_timer); max_import_timer = null;
      updateKeyboardHighlights();
    }
    else if (lines.indexOf("State=error") >= 0)
    {
      maxImporterStatus("3ds Max exporter error. " + lines.replace(/\r?\n/g, " "));
      window.clearInterval(max_import_timer); max_import_timer = null;
    }
    else if (lines.indexOf("State=running") >= 0) { maxImporterStatus("Exporting categories through 3ds Max..."); }
  }
  catch (error) { maxImporterStatus("Export status error: " + error.message); }
}
