/*
  Shared modifier RGB mixer for the Keyboard Setup HTAs.
  Ctrl=R, Shift=G, Win=B; Alt reduces enabled channels by 65%.
  The function is pure: neither key order nor previous colour changes its result.
*/
var keyboard_modifier_alt_darkness = 0.65;

function keyboardModifierRgbColor(ctrl_active, shift_active, win_active, alt_active, alt_darkness)
{
  var darkness = typeof alt_darkness === "number" ? alt_darkness : keyboard_modifier_alt_darkness;
  darkness = Math.max(0, Math.min(1, darkness));
  var value = alt_active ? Math.round(255 * (1 - darkness)) : 255;
  var channels = [ctrl_active ? value : 0, shift_active ? value : 0, win_active ? value : 0];
  var output = "#";
  for (var i = 0; i < channels.length; i++)
  {
    var hex = channels[i].toString(16).toUpperCase();
    output += hex.length === 1 ? "0" + hex : hex;
  }
  return output;
}

function keyboardModifierColor(modifiers, alt_darkness)
{
  var list = modifiers || [];
  return keyboardModifierRgbColor(list.indexOf("Ctrl") >= 0, list.indexOf("Shift") >= 0,
    list.indexOf("Win") >= 0, list.indexOf("Alt") >= 0, alt_darkness);
}

function keyboardModifierMask(modifiers)
{
  var list = modifiers || [];
  return (list.indexOf("Ctrl") >= 0 ? 1 : 0) + (list.indexOf("Shift") >= 0 ? 2 : 0)
    + (list.indexOf("Win") >= 0 ? 4 : 0) + (list.indexOf("Alt") >= 0 ? 8 : 0);
}
