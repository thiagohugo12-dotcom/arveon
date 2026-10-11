// Real Chromium + exported Godot Web test, using Node's built-in CDP WebSocket.
// No project/browser automation package dependency.
import http from 'node:http';
import {readFile, mkdtemp} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join, resolve, extname} from 'node:path';
import {spawn} from 'node:child_process';
import assert from 'node:assert/strict';
const profile = await mkdtemp(join(tmpdir(), 'grande-arvore-web-save-'));
const archive = await readFile('build/web-save-fixture.json', 'utf8');
const fixture = JSON.parse(archive);
const payload = JSON.parse(fixture.payload);
const campaignArchive = await readFile('build/campaign-save-fixture.json', 'utf8');
const campaignPayload = JSON.parse(JSON.parse(campaignArchive).payload);
const guardianArchive = await readFile('build/guardian-save-fixture.json', 'utf8');
const guardianPayload = JSON.parse(JSON.parse(guardianArchive).payload);
const helper = await readFile('scripts/platform/browser_save.js', 'utf8');
const KEY = 'grande-arvore-rpg.save.v6';
const server = http.createServer(async (req, res) => {
  if (req.url === '/seed.html') { res.end('<!doctype html><title>QA local save</title>'); return; }
  try {
    const name = decodeURIComponent(new URL(req.url, 'http://localhost').pathname).replace(/^\//,'') || 'index.html';
    if (name.includes('..')) throw Error('path');
    const data = await readFile(join(resolve('build/web'), name));
    res.setHeader('Content-Type', ({'.js':'application/javascript','.wasm':'application/wasm','.html':'text/html','.png':'image/png'})[extname(name)] || 'application/octet-stream');
    res.end(data);
  } catch (_) { res.writeHead(404); res.end(); }
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const origin = `http://127.0.0.1:${server.address().port}`;
const delay = ms=>new Promise(r=>setTimeout(r,ms));
let process, socket, count=0, checks=0, errors=[];
const pending = new Map();
async function call(method, params={}) {
  const id=++count;
  return new Promise((resolve,reject)=>{pending.set(id,{resolve,reject});socket.send(JSON.stringify({id,method,params}));});
}
async function evaluate(expression) {
  const r=await call('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true});
  if(r.exceptionDetails) throw Error(JSON.stringify(r.exceptionDetails));
  return r.result?.value;
}
function check(condition,name){assert.ok(condition,name); checks++; console.log('WEB_SAVE_PASS: '+name);}
async function until(expression, timeout=30000) {
  const start=Date.now();
  while(Date.now()-start<timeout) { if(await evaluate(expression)) return; await delay(150); }
  throw Error('Timeout: '+expression+'; '+errors.slice(-4).join('\n'));
}
async function start() {
  process=spawn(processEnvChrome(),['--headless=new','--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--remote-debugging-port=9333',`--user-data-dir=${profile}`,'about:blank'],{stdio:'ignore'});
  process.on('error', e=>errors.push(String(e)));
  let target;
  for(let i=0;i<100;i++){try{target=(await (await fetch('http://127.0.0.1:9333/json/list')).json()).find(x=>x.type==='page');if(target)break;}catch(_){} await delay(100);}
  if(!target)throw Error('Chromium unavailable: '+errors.join('\n'));
  socket=new WebSocket(target.webSocketDebuggerUrl);
  await new Promise(r=>socket.addEventListener('open',r,{once:true}));
  socket.addEventListener('message',e=>{
    const d=JSON.parse(e.data);
    if(d.id){const p=pending.get(d.id);pending.delete(d.id);d.error?p.reject(Error(JSON.stringify(d.error))):p.resolve(d.result);}
    if(d.method==='Runtime.exceptionThrown')errors.push(JSON.stringify(d.params.exceptionDetails));
    if(d.method==='Runtime.consoleAPICalled' && d.params.type==='error')errors.push(d.params.args.map(x=>x.value||'').join(' '));
  });
  await call('Runtime.enable'); await call('Page.enable');
  await call('Emulation.setDeviceMetricsOverride',{width:390,height:844,deviceScaleFactor:1,mobile:true});
}
function processEnvChrome(){return globalThis.process.env.CHROME_BIN||'google-chrome';}
async function seed() {await call('Page.navigate',{url:origin+'/seed.html'});await until('location.pathname === "/seed.html" && document.readyState === "complete"');await evaluate(helper);}
async function game() {
  await call('Page.navigate',{url:origin+'/index.html'});
  await until('location.pathname === "/index.html" && !!window.GrandeArvoreSave');
  await delay(1500); // GameProgress load + initial autosave in the actual engine.
}
async function snapshot(){return evaluate(`JSON.parse(JSON.parse(localStorage.getItem(${JSON.stringify(KEY)})).payload)`);}
async function stop(){
  if(socket?.readyState===1){try{await call('Browser.close');}catch(_){}socket.close();}
  if(process?.exitCode===null){await Promise.race([new Promise(r=>process.once('exit',r)),delay(5000)]);if(process.exitCode===null)process.kill('SIGKILL');}
}
try {
  await start(); await seed();
  check(await evaluate('!!document.createElement("canvas").getContext("webgl2")'),'Chromium has WebGL2 for actual exported game');
  await game(); await until(`!!localStorage.getItem(${JSON.stringify(KEY)})`);
  check((await snapshot()).xp===0,'new exported game initializes a permanent save');
  await seed();
  // Simulate the previous version's real IDBFS directory, without a journal.
  await evaluate(`localStorage.clear();(async()=>{
    const req=indexedDB.open('/userfs');
    const db=await new Promise((r,j)=>{req.onsuccess=()=>r(req.result);req.onerror=()=>j(req.error)});
    const tx=db.transaction('FILE_DATA','readwrite');const s=tx.objectStore('FILE_DATA');s.clear();
    const dirs=['/userfs/godot','/userfs/godot/app_userdata','/userfs/godot/app_userdata/Grande Árvore RPG — v0.5.1 — As Hordas da Torre'];
    for(const d of dirs)s.put({timestamp:new Date(),mode:16877},d);
    s.put({timestamp:new Date(),mode:33206,contents:new TextEncoder().encode(${JSON.stringify(fixture.payload)})},dirs[2]+'/andar1_progress.json');
    await new Promise((r,j)=>{tx.oncomplete=r;tx.onerror=()=>j(tx.error)});db.close();return true;
  })()`);
  await game();
  check((await snapshot()).gold===payload.gold,'old version directory migrates into stable Web location');
  check((await snapshot()).rpg.equipment.espada===3 && (await snapshot()).ascension.defeats['1']===50,'migration preserves equipment +3 and 50 kills');
  await call('Page.reload'); await until('location.pathname === "/index.html" && !!window.GrandeArvoreSave'); await delay(1500);
  check((await snapshot()).xp===payload.xp,'page reload retains XP without awarding rewards');
  // Remove the mirror only after the engine has synced the new stable file.
  await delay(1500); await evaluate(`localStorage.removeItem(${JSON.stringify(KEY)})`);
  await call('Page.reload'); await until('location.pathname === "/index.html" && !!window.GrandeArvoreSave'); await delay(1500);
  check((await snapshot()).gold===payload.gold,'IndexedDB alone restores permanent progress when mirror is absent');
  const before=await snapshot(); await stop(); await start(); await game();
  check(JSON.stringify(await snapshot())===JSON.stringify(before),'closing and reopening Chromium restores the complete save');
  await call('Emulation.setDeviceMetricsOverride',{width:960,height:540,deviceScaleFactor:1,mobile:false});
  await call('Page.reload'); await until('location.pathname === "/index.html" && !!window.GrandeArvoreSave'); await delay(1500);
  check((await snapshot()).chest['Essência']===3,'desktop orientation retains chest resources');
  await evaluate(`localStorage.setItem(${JSON.stringify(KEY)},'corrupt archive')`);
  await call('Page.reload'); await until('location.pathname === "/index.html" && !!window.GrandeArvoreSave'); await delay(1500);
  check(await evaluate(`localStorage.getItem(${JSON.stringify(KEY)}) === 'corrupt archive'`),'corrupt browser journal is never overwritten by new progress');
  await seed();
  await evaluate(`localStorage.setItem(${JSON.stringify(KEY)},${JSON.stringify(archive)});GrandeArvoreSave.read();localStorage.setItem(${JSON.stringify(KEY)},'newer tab');`);
  check(await evaluate(`GrandeArvoreSave.write('older tab') === 'conflict' && localStorage.getItem(${JSON.stringify(KEY)}) === 'newer tab'`),'real storage compare-and-swap rejects stale tab writes');
  await call('Page.setInterceptFileChooserDialog',{enabled:true});
  await evaluate('window.pickedSave=null;GrandeArvoreSave.pick(text=>window.pickedSave=text)');
  const doc=await call('DOM.getDocument');
  const node=await call('DOM.querySelector',{nodeId:doc.root.nodeId,selector:'input[type=file]'});
  await call('DOM.setFileInputFiles',{nodeId:node.nodeId,files:[resolve('build/web-save-fixture.json')]});
  await until('typeof window.pickedSave === "string"');
  check(await evaluate(`window.pickedSave === ${JSON.stringify(archive)}`),'browser file picker reads exact backup contents');
  await seed();
  await evaluate(`localStorage.setItem(${JSON.stringify(KEY)},${JSON.stringify(guardianArchive)})`);
  await game();
  const victory = await snapshot();
  check(victory.ascension.completed_trials['1'] && victory.ascension.forest_seal && JSON.stringify(victory.ascension.unlocked_floors)==='[1,2]' && victory.ascension.current_floor===1,'actual exported engine accepts completed ascension seal and data-only floor 2');
  await call('Page.reload'); await until('location.pathname === "/index.html" && !!window.GrandeArvoreSave'); await delay(1500);
  const victoryReload = await snapshot();
  check(victoryReload.xp===guardianPayload.xp && victoryReload.gold===guardianPayload.gold && !('trial' in victoryReload) && !('boss' in victoryReload),'Guardian victory reload preserves exact rewards without a checkpoint or duplicate grant');
  await call('Emulation.setDeviceMetricsOverride',{width:390,height:844,deviceScaleFactor:1,mobile:true});
  await call('Page.reload'); await until('location.pathname === "/index.html" && !!window.GrandeArvoreSave'); await delay(1500);
  check((await snapshot()).ascension.forest_seal && (await snapshot()).gold===guardianPayload.gold,'mobile orientation preserves Guardian seal and rewards');
  await seed();
  await evaluate(`localStorage.setItem(${JSON.stringify(KEY)},${JSON.stringify(campaignArchive)})`);
  await game();
  const campaign = await snapshot();
  check(campaign.ascension.current_floor===5 && campaign.ascension.campaign_completed && JSON.stringify(campaign.ascension.unlocked_floors)==='[1,2,3,4,5]','actual exported mobile engine loads completed five-floor campaign');
  await call('Page.reload'); await until('location.pathname === "/index.html" && !!window.GrandeArvoreSave'); await delay(1500);
  const campaignReload = await snapshot();
  check(campaignReload.xp===campaignPayload.xp && campaignReload.gold===campaignPayload.gold && !('trial' in campaignReload),'five-floor reload retains exact rewards without checkpoints or duplicate grants');
  check(JSON.stringify(campaignReload.floor_states)===JSON.stringify(campaignPayload.floor_states) && !campaignReload.ascension.unlocked_floors.includes(6),'actual engine retains independent exploration without a sixth floor');
  check(!errors.some(e=>/SCRIPT ERROR|Parse Error|Invalid call/.test(e)),'actual exported runtime has no GDScript errors');
  console.log(`WEB_SAVE_RESULT: ${checks} checks, 0 failures`);
} finally {await stop();server.close();}
