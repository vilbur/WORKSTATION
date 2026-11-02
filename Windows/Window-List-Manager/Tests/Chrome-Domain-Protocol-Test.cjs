const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const crypto = require('node:crypto');
const path = require('node:path');
const extension_dir = fs.existsSync(path.join(__dirname, '../Chrome-Extension/background.js')) ? path.join(__dirname, '../Chrome-Extension') : path.join(__dirname, '../Library/Chrome-Extension');
const source = fs.readFileSync(path.join(extension_dir, 'background.js'), 'utf8');
const event = () => ({ listeners: [], addListener(fn) { this.listeners.push(fn); }, fire(...args) { this.listeners.forEach(f => f(...args)); } });
const local = {}, session = {};
let wins = [{ id: 1, type: 'normal', tabs: [{id: 11, active: true, url: 'https://example.com/a?q=1#x', title: 'A'}] }, {id: 2, type: 'popup', tabs: [{id: 12, active: true, url: 'https://popup.example/a', title:'Popup'}]}, {id:3,type:'normal',incognito:true,tabs:[{id:13,active:true,url:'https://private.example'}]}];
let requests=[], commands=[], opened=[], offline=false, failOpen=false;
function boot() {
  const timers = new Map(); let tick=0;
  const chrome={storage:{}, windows:{getAll:async()=>structuredClone(wins),create:async o=>{if(failOpen)throw Error(); opened.push(o);}},tabs:{},runtime:{},alarms:{create(){}}};
  for(const [name,storage] of [['local',local],['session',session]])chrome.storage[name]={get:async k=>({[k]:structuredClone(storage[k])}),set:async o=>Object.assign(storage,structuredClone(o))};
  for(const key of ['onAttached','onDetached','onCreated','onActivated','onUpdated','onRemoved'])chrome.tabs[key]=event();
  for(const key of ['onCreated','onRemoved','onFocusChanged','onBoundsChanged'])chrome.windows[key]=event();
  for(const key of ['onStartup','onInstalled'])chrome.runtime[key]=event();chrome.alarms.onAlarm=event();
  const context=vm.createContext({chrome,crypto,URL,AbortController,Date,console,setTimeout:(fn,ms)=>{timers.set(++tick,{fn,ms});return tick;},clearTimeout:id=>timers.delete(id),fetch:async(_,o)=>{requests.push(JSON.parse(o.body));if(offline)throw Error();return{ok:true,json:async()=>({api_version:2,commands})};}});
  vm.runInContext(source,context);
  return {chrome,timers,send:()=>vm.runInContext('sendDomains()',context)};
}
(async()=>{
 let b=boot();await b.send();let first=requests.at(-1);assert.equal(first.api_version,2);assert.equal(first.windows.length,2);assert.equal(first.windows[0].url,'https://example.com/a?q=1#x');const id=first.client_id, visit=first.windows[0].visit_id;
 await b.send();assert.equal(requests.at(-1).windows[0].visit_id,visit);
 wins[0].tabs[0].title='Renamed';wins[0].left=100;await b.send();assert.equal(requests.at(-1).windows[0].visit_id,visit);assert.equal(requests.at(-1).windows[0].title,'Renamed');
 wins[0].tabs[0].url='https://example.com/b';await b.send();assert.notEqual(requests.at(-1).windows[0].visit_id,visit);
 wins[0].tabs[0].url='https://example.com/a?q=1#x';await b.send();const revisit=requests.at(-1).windows[0].visit_id;assert.notEqual(revisit,visit);
 b.chrome.tabs.onActivated.fire({windowId:1});await b.send();assert.notEqual(requests.at(-1).windows[0].visit_id,revisit);const active=requests.at(-1).windows[0].visit_id;
 b=boot();await b.send();assert.equal(requests.at(-1).client_id,id);assert.equal(requests.at(-1).windows[0].visit_id,active);
 wins.push({id:4,type:'normal',tabs:[]}); b.chrome.tabs.onDetached.fire(); b.chrome.tabs.onAttached.fire(); await b.send(); assert.equal(requests.at(-1).windows.find(w=>w.window_id===4).domain,'');
 wins[3].tabs=[{id:41,active:true,title:'Detached page',url:'https://transfer.example/path'}]; const transfer=[...b.timers.values()].find(t=>t.ms===1500); assert(transfer); await transfer.fn(); assert.equal(requests.at(-1).windows.find(w=>w.window_id===4).url,'https://transfer.example/path');
 commands=[{id:'good',type:'open_url',url:'https://example.com/exact?q=2#x'},{id:'bad',type:'open_url',url:'javascript:alert(1)'},{id:'wrong',type:'delete',url:'https://example.com'},{id:'../path',type:'open_url',url:'https://example.com'}];
 await b.send();assert.equal(opened.length,1);assert.deepEqual(JSON.parse(JSON.stringify(opened[0])),{url:'https://example.com/exact?q=2#x',type:'normal',focused:true});await b.send();assert.deepEqual(requests.at(-1).acks,['good']);assert.equal(opened.length,1);
 b=boot();await b.send();assert.equal(opened.length,1); // persisted command dedup
 commands=[{id:'retry',type:'open_url',url:'https://example.com/retry'}];failOpen=true;await b.send();assert(!session.domain_state.processed.includes('retry'));failOpen=false;await b.send();assert.equal(opened.length,2);
 offline=true;await b.send();assert([...b.timers.values()].some(t=>t.ms===5000));offline=false;await [...b.timers.values()].find(t=>t.ms===5000).fn();assert([...b.timers.values()].some(t=>t.ms===2000));
 wins[0].tabs[0].url='chrome://settings';await b.send();assert.equal(requests.at(-1).windows[0].url,'');assert.equal(requests.at(-1).windows[0].domain,'');
 const before=requests.length;await Promise.all([b.send(),b.send(),b.send()]);assert.equal(requests.length,before+1);
 assert.equal(JSON.parse(fs.readFileSync(path.join(extension_dir,'manifest.json'))).version,'0.1.3');
 console.log('PASS: protocol capture, visits, restart identity, privacy, commands, acknowledgments, retry, reconnect, overlap');
})().catch(e=>{console.error(e);process.exitCode=1});
