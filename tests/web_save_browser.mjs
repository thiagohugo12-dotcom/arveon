// Real Chromium + exported Godot Web test, using Node's built-in CDP WebSocket.
// No project/browser automation package dependency.
import http from 'node:http';
import {readFile, mkdtemp} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join, resolve, extname} from 'node:path';
import {spawn} from 'node:child_process';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
const profile = await mkdtemp(join(tmpdir(), 'grande-arvore-web-save-'));
const archive = await readFile('build/web-save-fixture.json', 'utf8');
const fixture = JSON.parse(archive);
const payload = JSON.parse(fixture.payload);
const campaignArchive = await readFile('build/campaign-save-fixture.json', 'utf8');
const campaignPayload = JSON.parse(JSON.parse(campaignArchive).payload);
const arsenalArchive = await readFile('build/arsenal-save-fixture.json', 'utf8');
const arsenalPayload = JSON.parse(JSON.parse(arsenalArchive).payload);
const progressionArchive = await readFile('build/progression-save-fixture.json', 'utf8');
const progressionPayload = JSON.parse(JSON.parse(progressionArchive).payload);
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
	// Avoid collisions with runner services; Chromium records its chosen port.
  process=spawn(processEnvChrome(),['--headless=new','--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--remote-debugging-port=0',`--user-data-dir=${profile}`,'about:blank'],{stdio:['ignore','ignore','pipe']});
  let startupDiagnostics='';
  process.stderr.on('data', chunk=>{startupDiagnostics=(startupDiagnostics+chunk).slice(-6000);});
  process.on('error', e=>errors.push(String(e)));
  let target;
  for(let i=0;i<300;i++){
    if(process.exitCode!==null) break;
    try{
      const port=Number((await readFile(join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0]);
      target=(await (await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find(x=>x.type==='page');
      if(target)break;
    }catch(_){}
    await delay(100);
  }
  if(!target)throw Error('Chromium unavailable (exit '+process.exitCode+'): '+errors.join('\n')+'\n'+startupDiagnostics);
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
  const introduction = await snapshot();
  check(introduction.version===11 && introduction.introduction.status==='active' && introduction.rpg.equipped.Arma==='' && Object.keys(introduction.rpg.equipment).length===0,'actual Web new character starts unarmed with introduction');
  await call('Page.reload'); await until('location.pathname === "/index.html" && !!window.GrandeArvoreSave'); await delay(1500);
  check((await snapshot()).introduction.status==='active' && Object.keys((await snapshot()).rpg.equipment).length===0,'actual Web pending choice survives reload without granting weapon');
  await stop(); await start(); await game();
  check((await snapshot()).introduction.status==='active' && Object.keys((await snapshot()).rpg.equipment).length===0,'browser close and reopen retains pending introduction');
  await seed();
  const chosen = structuredClone(introduction);
  chosen.introduction={status:'complete',met_smith:true,weapon:'arco'};
  chosen.rpg.equipment={arco:0}; chosen.rpg.equipped.Arma='arco';
  chosen.rpg.equipment_meta={arco:arsenalPayload.rpg.equipment_meta.arco};
  const chosenRaw=JSON.stringify(chosen);
  const chosenArchive=JSON.stringify({format:'grande-arvore-rpg-save',archive_version:1,payload:chosenRaw,sha256:createHash('sha256').update(chosenRaw).digest('hex')});
  await evaluate(`GrandeArvoreSave.write(${JSON.stringify(chosenArchive)},true)`);
  await game();
  check((await snapshot()).introduction.status==='complete' && (await snapshot()).rpg.equipped.Arma==='arco' && Object.keys((await snapshot()).rpg.equipment).length===1,'actual Web completed choice loads one equipped weapon');
  await call('Page.reload'); await until('location.pathname === "/index.html" && !!window.GrandeArvoreSave'); await delay(1500);
  check((await snapshot()).introduction.status==='complete' && (await snapshot()).xp===0 && (await snapshot()).gold===0 && Object.keys((await snapshot()).rpg.equipment).length===1,'completed reward never duplicates on reload and grants no XP or gold');
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
  await seed();
  await evaluate(`localStorage.setItem(${JSON.stringify(KEY)},${JSON.stringify(arsenalArchive)})`);
  await game();
  const arsenal = await snapshot();
  check(['espada','machado','lanca','arco','cajado'].every(id=>arsenal.rpg.equipment_meta[id].category===id),'actual exported engine accepts five stable weapon categories');
  check(arsenal.rpg.equipped.Arma==='cajado' && arsenal.rpg.equipment.cajado===2 && arsenal.rpg.equipment.arco===3 && arsenal.rpg.equipment.espada===0,'mobile exported engine preserves ranged upgrades and legacy equipment');
  await call('Page.reload'); await until('location.pathname === "/index.html" && !!window.GrandeArvoreSave'); await delay(1500);
  const arsenalReload = await snapshot();
  check(JSON.stringify(arsenalReload.rpg.equipment)===JSON.stringify(arsenalPayload.rpg.equipment) && JSON.stringify(arsenalReload.rpg.equipment_meta)===JSON.stringify(arsenalPayload.rpg.equipment_meta) && arsenalReload.rpg.equipped.Arma==='cajado','five weapon reload preserves rarity independently of enhancement without duplicate items');
  await seed();
  await evaluate(`localStorage.setItem(${JSON.stringify(KEY)},${JSON.stringify(progressionArchive)})`);
  await game();
  await until(`JSON.parse(JSON.parse(localStorage.getItem(${JSON.stringify(KEY)})).payload).version === 11`);
  const progression = await snapshot();
  check(progression.version===11 && Object.keys(progression.rpg.attributes).length===6 && !('Agilidade' in progression.rpg.attributes) && progression.rpg.attributes.Mobilidade===0 && progression.rpg.attributes.Destreza===0,'actual Web migrates old Agility into unspent six-attribute budget');
  check(progression.xp===progressionPayload.xp && progression.gold===777 && progression.rpg.attributes['Força']===3 && Object.keys(progression.rpg.skills).length===0 && progression.abilities.loadouts.espada.skills.length===2 && progression.rpg.equipment.cajado===2,'actual Web preserves level wallet attributes gear and replaces legacy abilities safely');
  check(progression.talents.xp.espada===1240 && progression.talents.xp.cajado===3480 && progression.talents.learned.espada.length===0 && progression.talents.mastery.espada.Dano===0,'actual Web migrates proficiency and refunds replaced tree without spending Domain');
  check(progression.ascension.campaign_completed && JSON.stringify(progression.floor_states)===JSON.stringify(progressionPayload.floor_states),'actual Web migration preserves all five conquered floors and exploration');
  await call('Page.reload'); await until('location.pathname === "/index.html" && !!window.GrandeArvoreSave'); await delay(1500);
  const progressionReload = await snapshot();
  check(JSON.stringify(progressionReload.rpg)===JSON.stringify(progression.rpg) && JSON.stringify(progressionReload.talents)===JSON.stringify(progression.talents) && progressionReload.xp===progression.xp,'actual Web reload cannot duplicate Agility refunds mastery or talent progress');
  check(await evaluate(`localStorage.getItem(${JSON.stringify(KEY + '.v7.original')})`) === progressionArchive,'browser migration keeps byte-exact original v7 independently of rotating mirror');
  const abilityFixture=structuredClone(progression);
  abilityFixture.abilities.loadouts.espada.skills=['danca_laminas','corte_crescente'];
  abilityFixture.abilities.loadouts.cajado.skills=['onda_arcana','tempestade_arcana'];
  abilityFixture.abilities.skill1_cooldowns.espada=4;
  abilityFixture.abilities.cooldowns.espada={corte_crescente:5.5};
  abilityFixture.abilities.charge.espada=42;
  abilityFixture.abilities.charge.cajado=89;
  const abilityPayload=JSON.stringify(abilityFixture);
  const abilityArchive=JSON.stringify({format:'grande-arvore-rpg-save',archive_version:1,payload:abilityPayload,sha256:createHash('sha256').update(abilityPayload).digest('hex')});
  await seed();
  await evaluate(`localStorage.setItem(${JSON.stringify(KEY)},${JSON.stringify(abilityArchive)})`);
  await game();
  const abilities=await snapshot();
  check(abilities.version===11 && abilities.abilities.charge.espada===42 && abilities.abilities.charge.cajado===89,'actual Web restores independent Ultimate bars and optional slots');
  check(abilities.abilities.skill1_cooldowns.espada===4 && abilities.abilities.cooldowns.espada.corte_crescente===5.5,'inactive category cooldowns do not advance during active gameplay');
  await call('Page.reload'); await until('location.pathname === "/index.html" && !!window.GrandeArvoreSave'); await delay(1500);
  const abilitiesReload=await snapshot();
  check(JSON.stringify(abilitiesReload.abilities)===JSON.stringify(abilities.abilities),'actual Web reload preserves paused cooldowns charges and builds without offline gains');
  const preservedJournal=await evaluate(`localStorage.getItem(${JSON.stringify(KEY)})`);
  await call('Page.navigate',{url:origin+'/amostra-mata/index.html'});
  await until('document.documentElement?.dataset.mataSample === "ready"',45000);
  check(await evaluate('document.title === "Mata — amostra artística"'),'separate exported art scene starts instead of Main');
  await delay(1500);
  check(await evaluate(`localStorage.getItem(${JSON.stringify(KEY)})`)==preservedJournal,'art sample does not modify the player save');
  await call('Emulation.setDeviceMetricsOverride',{width:640,height:360,deviceScaleFactor:1,mobile:true});
  await delay(500);
  check(await evaluate('document.documentElement.dataset.mataSample === "ready" && !window.GrandeArvoreSave'),'landscape sample remains isolated from save platform');
  check(!errors.some(e=>/SCRIPT ERROR|Parse Error|Invalid call/.test(e)),'actual exported runtime has no GDScript errors');
  console.log(`WEB_SAVE_RESULT: ${checks} checks, 0 failures`);
} finally {await stop();server.close();}
