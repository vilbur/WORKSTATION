/* Shared additive RGB colour system. Ctrl=red, Shift=green, Win=blue.
   Alt=white and contributes all three channels; there is no modifier priority.
   All Alt-containing mixtures are therefore white under saturated RGB addition. */
function keyboardModifierRgb(states)
{
  var red = (states.Ctrl || states.Alt) ? 255 : 0;
  var green = (states.Shift || states.Alt) ? 255 : 0;
  var blue = (states.Win || states.Alt) ? 255 : 0;
  function toHex(value)
  {
    var result = value.toString(16).toUpperCase();
    return result.length < 2 ? "0" + result : result;
  }
  return "#" + toHex(red) + toHex(green) + toHex(blue);
}

/* Resolve a set of modifier names or a state object to its exact RGB colour. */
function keyboardModifierColor(modifiers)
{
  var states = { Ctrl:false, Shift:false, Win:false, Alt:false };
  if (modifiers && typeof modifiers.length === "number")
  {
    for (var i = 0; i < modifiers.length; i++)
    {
      if (states.hasOwnProperty(modifiers[i])) { states[modifiers[i]] = true; }
    }
  }
  else if (modifiers)
  {
    states.Ctrl = !!modifiers.Ctrl;
    states.Shift = !!modifiers.Shift;
    states.Win = !!modifiers.Win;
    states.Alt = !!modifiers.Alt;
  }
  return keyboardModifierRgb(states);
}

/* Union the modifier states of all shortcut assignments for one physical key. */
function keyboardModifierUnionColor(modifier_sets)
{
  var states = { Ctrl:false, Shift:false, Win:false, Alt:false };
  for (var i = 0; i < modifier_sets.length; i++)
  {
    var modifiers = modifier_sets[i] || [];
    for (var j = 0; j < modifiers.length; j++)
    {
      if (states.hasOwnProperty(modifiers[j])) { states[modifiers[j]] = true; }
    }
  }
  return keyboardModifierRgb(states);
}

/* Shortcut display text may hide the physical Shift key for Ctrl+". */
function keyboardModifierColorForShortcut(shortcut)
{
  var parts = String(shortcut || "").split("+");
  var mods = [];
  for (var i = 0; i < parts.length - 1; i++)
  {
    var name = parts[i].replace(/^\s+|\s+$/g, "");
    if (name === "Ctrl" || name === "Shift" || name === "Win" || name === "Alt") { mods.push(name); }
  }
  if (/\"/.test(parts[parts.length - 1]) && mods.indexOf("Ctrl") >= 0 && mods.indexOf("Shift") < 0)
  { mods.push("Shift"); }
  return keyboardModifierColor(mods);
}

/* v0.26 display palette: saturated accent colours; the raw RGB calculator
   above is unchanged. Alt is white only when used by itself. Other keys
   accumulate Ctrl/Shift/Win colours without Alt washing them out. */
var keyboard_modifier_display_palette_version = 26;

function keyboardModifierSoftenColor(raw_hex)
{
  var palette = {
    "#000000":"#000000",
    "#FF0000":"#F16D77",
    "#00FF00":"#66DC76",
    "#0000FF":"#55B8F6",
    "#FFFF00":"#E7D451",
    "#FF00FF":"#D875E9",
    "#00FFFF":"#56DDE2",
    "#FFFFFF":"#A779D8"
  };
  return palette[String(raw_hex || "").toUpperCase()] || "#000000";
}

/* Resolve Alt to white ONLY when Alt is the sole modifier in a status/swatch.
   For combined shortcuts, preserve the visible Ctrl/Shift/Win mixture. */
function keyboardModifierDisplayColor(modifiers)
{
  var states = { Ctrl:false, Shift:false, Win:false, Alt:false };
  if (modifiers && typeof modifiers.length === "number")
  {
    for (var i=0; i<modifiers.length; i++)
    {
      if (states.hasOwnProperty(modifiers[i])) { states[modifiers[i]] = true; }
    }
  }
  else if (modifiers)
  {
    states.Ctrl = !!modifiers.Ctrl;
    states.Shift = !!modifiers.Shift;
    states.Win = !!modifiers.Win;
    states.Alt = !!modifiers.Alt;
  }
  if (states.Alt && !states.Ctrl && !states.Shift && !states.Win)
  { return "#FFFFFF"; }
  return keyboardModifierSoftenColor(keyboardModifierRgb({
    Ctrl:states.Ctrl, Shift:states.Shift, Win:states.Win, Alt:false
  }));
}

/* Keycaps never receive a white overlay merely because an assignment uses Alt.
   An Alt-only binding keeps the neutral assigned-key styling. */
function keyboardModifierDisplayUnionColor(modifier_sets)
{
  var active = { Ctrl:false, Shift:false, Win:false };
  var found_alt = false;
  for (var i=0; i<modifier_sets.length; i++)
  {
    var mods = modifier_sets[i] || [];
    for (var j=0; j<mods.length; j++)
    {
      if (mods[j] === "Alt") { found_alt = true; }
      else if (active.hasOwnProperty(mods[j])) { active[mods[j]] = true; }
    }
  }
  if (found_alt && !active.Ctrl && !active.Shift && !active.Win)
  { return ""; }
  return keyboardModifierDisplayColor(active);
}

function keyboardModifierDisplayColorForShortcut(shortcut)
{
  var parts = String(shortcut || "").split("+");
  var mods = [];
  for (var i=0; i<parts.length-1; i++)
  {
    var name = parts[i].replace(/^\s+|\s+$/g, "");
    if (name === "Ctrl" || name === "Shift" || name === "Win" || name === "Alt")
    { mods.push(name); }
  }
  if (/"/.test(parts[parts.length-1]) && mods.indexOf("Ctrl") >= 0 && mods.indexOf("Shift") < 0)
  { mods.push("Shift"); }
  return keyboardModifierDisplayColor(mods);
}
