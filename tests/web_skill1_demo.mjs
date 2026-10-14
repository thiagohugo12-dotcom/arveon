// Actual exported scene in Chromium: mouse/touch, cadence, walking and no save writes.
import http from 'node:http';
import {readFile,mkdtemp,mkdir,writeFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,resolve,extname} from 'node:path';
import {spawn} from 'node:child_process';
import assert from 'node:assert/strict';
const category='skill1';
const profile=await mkdtemp(join(tmpdir(),'grande-arvore-melee-'));
const delay=ms=>new Promise(r=>setTimeout(r,ms));
let chrome,socket,seq=0,checks=0;
const pending=new Map(),errors=[];
const server=http.createServer(async(req,res)=>{
  try{
    const name=new URL(req.url,'http://local').pathname.slice(1);
    if(name==='seed.html'){res.end('<!doctype html><title>Sword QA</title>');return;}
    if(name.includes('..'))throw Error('path');
    const data=await readFile(join(resolve('build/web'),name));
    res.setHeader('Content-Type',({'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'})[extname(name)]||'application/octet-stream');
    res.end(data);
  }catch{res.writeHead(404);res.end();}
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const origin=`http://127.0.0.1:${server.address().port}`;
function call(method,params={}){
  const id=++seq;
  return new Promise((resolve,reject)=>{pending.set(id,{resolve,reject});socket.send(JSON.stringify({id,method,params}));});
}
async function evaluate(expression){
  const r=await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});
  if(r.exceptionDetails)throw Error(JSON.stringify(r.exceptionDetails));
  return r.result?.value;
}
async function until(expression){
  for(let i=0;i<300;i++){if(await evaluate(expression))return;await delay(100);}
  throw Error('Timeout: '+expression+'; '+errors.join('\n'));
}
function check(condition,message){assert.ok(condition,message);checks++;console.log('WEB_SKILL1_PASS: '+message);}
async function click(x,y,touch=false){
  if(touch){
    await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x,y,id:0}]});
    await delay(70);
    await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  }else{
    await call('Input.dispatchMouseEvent',{type:'mousePressed',x,y,button:'left',clickCount:1});
    await call('Input.dispatchMouseEvent',{type:'mouseReleased',x,y,button:'left',clickCount:1});
  }
  await delay(350);
}
async function viewport(width,height,mobile=false){
  await call('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile});
  await call('Emulation.setTouchEmulationEnabled',{enabled:mobile,maxTouchPoints:5});
  await delay(600);
}
async function capture(name){
  await mkdir(`build/${category}-web-qa`,{recursive:true});
  const r=await call('Page.captureScreenshot',{format:'png'});
  await writeFile(`build/${category}-web-qa/${name}.png`,Buffer.from(r.data,'base64'));
}
try{
  chrome=spawn(process.env.CHROME_BIN||'google-chrome',['--headless=new','--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--remote-debugging-port=0',`--user-data-dir=${profile}`,'about:blank'],{stdio:['ignore','ignore','pipe']});
  chrome.on('error',e=>errors.push(String(e)));
  let startup='';chrome.stderr.on('data',b=>startup=(startup+b).slice(-4000));
  let target;
  for(let i=0;i<150;i++){
    try{
      const port=Number((await readFile(join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0]);
      target=(await(await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find(t=>t.type==='page');
      if(target)break;
    }catch{}
    await delay(100);
  }
  if(!target)throw Error('Chromium unavailable: '+startup);
  socket=new WebSocket(target.webSocketDebuggerUrl);
  await new Promise(r=>socket.addEventListener('open',r,{once:true}));
  socket.addEventListener('message',e=>{
    const d=JSON.parse(e.data);
    if(d.id){const p=pending.get(d.id);pending.delete(d.id);d.error?p.reject(Error(JSON.stringify(d.error))):p.resolve(d.result);}
    if(d.method==='Runtime.exceptionThrown')errors.push(JSON.stringify(d.params.exceptionDetails));
    if(d.method==='Runtime.consoleAPICalled' && d.params.type==='error')errors.push(d.params.args.map(x=>x.value||'').join(' '));
  });
  await call('Runtime.enable');await call('Page.enable');
  await viewport(960,620);
  await call('Page.navigate',{url:origin+'/seed.html'});
  await until('document.readyState === "complete" && location.pathname === "/seed.html"');
  await evaluate('localStorage.setItem("grande-arvore-rpg.save.v6","skill1-review-sentinel"); localStorage.setItem("grande-arvore-rpg.save.v6.previous","backup-sentinel")');
  await call('Page.navigate',{url:origin+'/amostra-skills1/index.html'});
  await until('window.Skill1DemoReady && window.Skill1DemoState?.inspection');
  check(await evaluate('window.Skill1DemoState.speed === 1'),'default normal-speed visual inspection');
  const isolated=await evaluate('JSON.stringify([window.Skill1DemoState.casts,window.Skill1DemoState.hits,window.Skill1DemoState.projectiles,window.Skill1DemoState.cooldown])');
  for(let categoryIndex=0;categoryIndex<5;categoryIndex++){
    await click(16+(960-32)/5*(categoryIndex+.5),89);
    const atlas=['espada','machado','lanca','arco','cajado'][categoryIndex];
    for(let direction=0;direction<4;direction++){
      await click(16+(960-32)/4*(direction+.5),419);
      const replay=await evaluate('window.Skill1DemoState.visual_replays');
      await click(180,132);
      await until(`window.Skill1DemoState.visual_replays > ${replay} && window.Skill1DemoState.displayed_frame >= 0 && window.Skill1DemoState.displayed_atlas.endsWith('/${atlas}.png')`);
      check(true,`actual rendered special atlas ${atlas} direction ${direction}`);
    }
  }
  const replay=await evaluate('window.Skill1DemoState.visual_replays');
  for(let i=0;i<3;i++)await click(180,132);
  check(await evaluate(`window.Skill1DemoState.visual_replays >= ${replay+3}`),'manual repetitions do not wait for real cooldown');
  check(await evaluate('window.Skill1DemoState.casts === 0 && window.Skill1DemoState.hits === 0 && window.Skill1DemoState.projectiles === 0'),'visual mode creates no real casts, damage or projectiles');
  await click(200,501);
  await until('window.Skill1DemoState.speed === .5');
  check(true,'visual speed toggle does not change real combat');
  await click(700,463);
  await until('window.Skill1DemoState.automatic === false');
  check(true,'basic comparison can pause independently');
  await viewport(390,844,true);
  const touchReplay=await evaluate('window.Skill1DemoState.visual_replays');
  await click(180,132,true);
  await until(`window.Skill1DemoState.visual_replays > ${touchReplay}`);
  check(true,'highlighted inspection button works by touch');
  await capture('inspection-portrait');
  await viewport(960,620,false);
  await click(560,132); // Explicitly enter original real-combat mode for existing regression flow.
  await until('!window.Skill1DemoState.inspection');
  await click(16+(960-32)/5*.5,89);
  await until('window.Skill1DemoState.casts >= 1');
  check(await evaluate('!window.GrandeArvoreSave'),'isolated review never initializes journal');
  const names=['Talho Ágil','Racha-Chão','Impulso Perfurante','Flecha Certeira','Orbe Arcano'];
  const categories=['espada','machado','lanca','arco','cajado'];
  const cooldowns=[6,10,8,8,9];
  for(let categoryIndex=0;categoryIndex<5;categoryIndex++){
    const previous=await evaluate('window.Skill1DemoState.casts');
    if(categoryIndex>0)await click(16+(960-32)/5*(categoryIndex+.5),89);
    await until(`window.Skill1DemoState.category === ${JSON.stringify(categories[categoryIndex])}`);
    if(categoryIndex>0)await until(`window.Skill1DemoState.casts > ${previous}`);
    check(await evaluate(`window.Skill1DemoState.name === ${JSON.stringify(names[categoryIndex])}`),'selected skill name '+categories[categoryIndex]);
    const cd=await evaluate('window.Skill1DemoState.cooldown');
    check(cd>0 && cd<=cooldowns[categoryIndex],'original real cooldown '+categories[categoryIndex]);
    await capture(categories[categoryIndex]);
    const casts=await evaluate('window.Skill1DemoState.casts');
    await call('Input.dispatchKeyEvent',{type:'keyDown',key:'r',code:'KeyR',windowsVirtualKeyCode:82});
    await call('Input.dispatchKeyEvent',{type:'keyUp',key:'r',code:'KeyR',windowsVirtualKeyCode:82});
    await delay(250);
    check(await evaluate(`window.Skill1DemoState.casts === ${casts}`),'repeat cannot bypass cooldown '+categories[categoryIndex]);
    for(let direction=0;direction<4;direction++){
      await click(16+(960-32)/4*(direction+.5),419);
      await until(`window.Skill1DemoState.direction === ${direction}`);
      check(true,'desktop direction '+categories[categoryIndex]+' '+direction);
    }
  }
  await call('Input.dispatchKeyEvent',{type:'keyDown',key:'v',code:'KeyV',windowsVirtualKeyCode:86});
  await call('Input.dispatchKeyEvent',{type:'keyUp',key:'v',code:'KeyV',windowsVirtualKeyCode:86});
  await until('window.Skill1DemoState.walking');
  check(true,'keyboard walking keeps original gait');
  await viewport(390,844,true);
  await click(16+(390-32)/5*.5,89,true);
  await until('window.Skill1DemoState.category === "espada"');
  check(true,'portrait touch selects category');
  await click(60,643,true);
  await until('window.Skill1DemoState.direction === 0');
  check(true,'portrait touch selects front');
  await click(295,687,true);
  await until('window.Skill1DemoState.automatic === false');
  check(true,'touch pauses automatic comparison without changing cooldown');
  await click(100,687,true);
  await until('!window.Skill1DemoState.walking');
  await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:84,y:791,id:0}]});
  await until('window.Skill1DemoState.walking');
  check(true,'touch analog drives the original walking');
  await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await until('window.Skill1DemoState.cooldown <= .001');
  const oldCasts=await evaluate('window.Skill1DemoState.casts');
  const oldHits=await evaluate('window.Skill1DemoState.hits');
  await click(180,132,true);
  await until(`window.Skill1DemoState.casts > ${oldCasts} && window.Skill1DemoState.hits > ${oldHits}`);
  check(true,'manual touch Skill 1 executes actual combat after real cooldown');
  await capture('portrait');
  await viewport(844,390,true);
  await click(16+(844-352)/5*2.5,89,true);
  await until('window.Skill1DemoState.category === "lanca"');
  await click(720,42,true);
  await until('window.Skill1DemoState.direction === 1');
  check(true,'landscape touch category and direction stay accessible');
  await capture('landscape');
  check(await evaluate('window.Skill1DemoState.writes === 0'),'no save writes');
  check(await evaluate('localStorage.getItem("grande-arvore-rpg.save.v6") === "skill1-review-sentinel" && localStorage.getItem("grande-arvore-rpg.save.v6.previous") === "backup-sentinel"'),'existing journal and backup untouched');
  check(errors.length===0,'no Web runtime errors: '+errors.join('\n'));
  console.log(`WEB_SKILL1_RESULT: ${checks} checks, 0 failures`);
}finally{
  if(socket?.readyState===1){try{await call('Browser.close');}catch{}socket.close();}
  if(chrome?.exitCode===null){await Promise.race([new Promise(r=>chrome.once('exit',r)),delay(3000)]);if(chrome.exitCode===null)chrome.kill();}
  server.close();
}
