const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const code = fs.readFileSync('data/Keyboard-Setup-Modifier-Colors.js', 'utf8');
const c = vm.createContext({Math, Number, String});
vm.runInContext(code, c);
const keys = ['Ctrl','Shift','Win','Alt'];
const expected = [
  '#000000','#FF0000','#00FF00','#FFFF00',
  '#0000FF','#FF00FF','#00FFFF','#FFFFFF',
  '#000000','#590000','#005900','#595900',
  '#000059','#590059','#005959','#595959'
];
assert.equal(c.keyboard_modifier_alt_darkness, .65, 'default Alt darkness is 65%');
for (let mask=0; mask<16; mask++)
{
  const mods = keys.filter((_, bit) => !!(mask & (1<<bit)));
  const color = c.keyboardModifierColor(mods);
  assert.equal(color, expected[mask], `${mods.join('+') || 'None'} => ${expected[mask]}`);
  // Every permutation of the same pressed keys must give the same result.
  function checkOrders(prefix, remainder)
  {
    if (!remainder.length)
    {
      assert.equal(c.keyboardModifierColor(prefix), expected[mask], `order ${prefix.join(' > ')}`);
      return;
    }
    for (let i=0; i<remainder.length; i++)
    {
      checkOrders([...prefix,remainder[i]], remainder.filter((_,j)=>i!==j));
    }
  }
  checkOrders([], mods);
}
assert.equal(c.keyboardModifierColor(['Ctrl','Alt'],0), '#FF0000', 'internally configurable darkness zero');
assert.equal(c.keyboardModifierColor(['Ctrl','Alt'],1), '#000000', 'internally configurable darkness 100%');
assert.equal(c.keyboardModifierColor(['Alt']), '#000000', 'Alt alone is black');
assert.equal(c.keyboardModifierColor([]), '#000000', 'none is black');
assert.equal(c.keyboardModifierRgbColor(true,false,false,true), '#590000', 'direct four-boolean pure function');

// Press/release and activation order preserve exact colour at each transition.
const states = {};
keys.forEach(k=>states[k]=false);
function step(key, pressed)
{
  states[key]=pressed;
  const mods=keys.filter(k=>states[k]);
  const mask=keys.reduce((n,k,i)=>n|(states[k]?(1<<i):0),0);
  assert.equal(c.keyboardModifierColor(mods), expected[mask], `${key} ${pressed?'down':'up'}`);
}
step('Ctrl',true);step('Win',true);step('Alt',true);step('Shift',true);
step('Ctrl',false);step('Alt',false);step('Shift',false);step('Win',false);
step('Alt',true);step('Shift',true);step('Win',true);step('Ctrl',true);
step('Win',false);step('Shift',false);step('Ctrl',false);step('Alt',false);
console.log('PASS: 16 exact RGB values, all modifier activation permutations, configurable Alt darkness, and press/release transitions.');
