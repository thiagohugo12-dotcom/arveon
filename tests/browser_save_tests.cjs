const test = require('node:test');
const assert = require('node:assert/strict');
const {create, KEY, PREVIOUS} = require('../scripts/platform/browser_save.js');
function storage() {
  const values = new Map();
  return {getItem: key => values.get(key) ?? null, setItem: (key, value) => values.set(key, value), values};
}
test('new journal and synchronous durable snapshot', () => {
  const s = storage(), bridge = create(s);
  assert.equal(bridge.read(), '');
  assert.equal(bridge.available(), true);
  assert.equal(bridge.write('save1'), 'ok');
  assert.equal(s.getItem(KEY), 'save1');
  assert.equal(bridge.write('save2'), 'ok');
  assert.equal(s.getItem(PREVIOUS), 'save1');
});
test('reload and reopened tab read the durable snapshot', () => {
  const s = storage(), first = create(s); first.read(); first.write('progress');
  assert.equal(create(s).read(), 'progress');
  assert.equal(create(s).read(), 'progress');
});
test('stale tabs cannot overwrite newer progress', () => {
  const s = storage(), a = create(s), b = create(s);
  a.read(); b.read(); a.write('newer');
  assert.equal(b.write('older'), 'conflict');
  assert.equal(s.getItem(KEY), 'newer');
  b.read(); assert.equal(b.write('next'), 'ok');
});
test('explicit import replacement retains previous journal', () => {
  const s = storage(), a = create(s), b = create(s);
  a.read(); b.read(); a.write('newer');
  assert.equal(b.write('import', true), 'ok');
  assert.equal(s.getItem(PREVIOUS), 'newer');
  assert.equal(a.write('stale'), 'conflict');
});
test('unchanged snapshot avoids additional writes', () => {
  const s = storage(), b = create(s); let writes = 0;
  const original = s.setItem; s.setItem = (...args) => {writes++; original(...args);};
  b.read(); b.write('save'); b.write('save');
  assert.equal(writes, 1);
});
test('blocked storage reports failure and remains unavailable', () => {
  const b = create({getItem(){throw Error('blocked');}});
  assert.equal(b.read(), ''); assert.equal(b.available(), false);
  assert.equal(b.write('save'), 'storage');
});
test('quota failure never changes authoritative save', () => {
  const s = storage(), b = create(s); b.read(); b.write('good');
  s.setItem = () => {throw Error('quota');};
  assert.equal(b.write('new'), 'storage');
  assert.equal(s.getItem(KEY), 'good');
});
test('oversized and invalid journal writes rejected', () => {
  const b = create(storage()); b.read();
  assert.equal(b.write('x'.repeat(262145)), 'invalid');
  assert.equal(b.write(12), 'invalid');
});
test('visibility and pagehide listeners detach on scene reload', () => {
  const listeners = new Map();
  global.document = {visibilityState:'visible', addEventListener:(n,f)=>listeners.set(n,f), removeEventListener:n=>listeners.delete(n)};
  global.addEventListener = (n,f)=>listeners.set(n,f);
  global.removeEventListener = n=>listeners.delete(n);
  let saves = 0; const detach = create(storage()).onHidden(()=>saves++);
  listeners.get('visibilitychange')(); assert.equal(saves,0);
  document.visibilityState = 'hidden'; listeners.get('visibilitychange')();
  listeners.get('pagehide')(); assert.equal(saves,2);
  detach(); assert.equal(listeners.size,0);
});

test('migration preserves immutable original independently of rotating mirror', () => {
  const s = storage(), bridge = create(s);
  const old = JSON.stringify({format:'grande-arvore-rpg-save',payload:JSON.stringify({version:9,gold:77})});
  bridge.read(); bridge.write(old);
  bridge.write(JSON.stringify({payload:JSON.stringify({version:10,gold:77})}));
  bridge.write(JSON.stringify({payload:JSON.stringify({version:10,gold:99})}));
  assert.equal(s.getItem(KEY+'.v9.original'),old);
  assert.notEqual(s.getItem(PREVIOUS),old);
});
