// Actual exported scene in Chromium: mouse/touch, cadence, walking and no save writes.
import http from 'node:http';
import {readFile,mkdtemp,mkdir,writeFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,resolve,extname} from 'node:path';
import {spawn} from 'node:child_process';
import assert from 'node:assert/strict';
const profile=await mkdtemp(join(tmpdir(),'grande-arvore-bow-'));
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
function check(condition,message){assert.ok(condition,message);checks++;console.log('WEB_BOW_PASS: '+message);}
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
  await mkdir('build/bow-web-qa',{recursive:true});
  const r=await call('Page.captureScreenshot',{format:'png'});
  await writeFile(`build/bow-web-qa/${name}.png`,Buffer.from(r.data,'base64'));
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
  await evaluate('localStorage.setItem("grande-arvore-rpg.save.v6","bow-review-sentinel"); localStorage.setItem("grande-arvore-rpg.save.v6.previous","backup-sentinel")');
  await call('Page.navigate',{url:origin+'/amostra-arco/index.html'});
  await until('window.BowDemoReady && window.BowDemoState?.hits >= 2');
  check(await evaluate('!window.GrandeArvoreSave'),'isolated scene never initializes journal helper');
  const interval=await evaluate('window.BowDemoState.interval');
  check(Math.abs(interval-.8)<.001,'export uses original bow cadence');
  for(let i=0;i<4;i++){
    await click(16+(960-32)/4*(i+.5),419);
    await until(`window.BowDemoState.direction === ${i}`);
    check(true,'mouse selects direction '+i);
  }
  await call('Input.dispatchKeyEvent',{type:'keyDown',key:'1',code:'Digit1',windowsVirtualKeyCode:49});
  await call('Input.dispatchKeyEvent',{type:'keyUp',key:'1',code:'Digit1',windowsVirtualKeyCode:49});
  await until('window.BowDemoState.direction === 0');
  check(true,'keyboard selects direction');
  await call('Input.dispatchKeyEvent',{type:'keyDown',key:'r',code:'KeyR',windowsVirtualKeyCode:82});
  await call('Input.dispatchKeyEvent',{type:'keyUp',key:'r',code:'KeyR',windowsVirtualKeyCode:82});
  await until('window.BowDemoState.projectiles > 0');
  check(true,'repeat produces an actual travelling arrow');
  await capture('desktop');
  await viewport(390,844,true);
  await click(60,643,true);
  await until('window.BowDemoState.direction === 0');
  check(true,'portrait touch selects front');
  await click(100,725,true);
  await until('window.BowDemoState.interval < .75');
  check(true,'touch Dex button changes real cadence');
  await click(100,687,true);
  await until('window.BowDemoState.walking');
  check(true,'touch walking toggle drives original gait');
  await capture('portrait');
  await click(100,687,true);
  await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:84,y:791,id:0}]});
  await until('window.BowDemoState.walking');
  check(true,'touch analog moves real player');
  await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await viewport(844,390,true);
  await click(720,42,true);
  await until('window.BowDemoState.direction === 1');
  check(true,'short landscape keeps touch controls accessible');
  await capture('landscape');
  check(await evaluate('window.BowDemoState.writes === 0'),'no save writes in exported demo');
  check(await evaluate('localStorage.getItem("grande-arvore-rpg.save.v6") === "bow-review-sentinel" && localStorage.getItem("grande-arvore-rpg.save.v6.previous") === "backup-sentinel"'),'existing journal and backup untouched');
  check(errors.length===0,'no Web runtime errors: '+errors.join('\n'));
  console.log(`WEB_BOW_RESULT: ${checks} checks, 0 failures`);
}finally{
  if(socket?.readyState===1){try{await call('Browser.close');}catch{}socket.close();}
  if(chrome?.exitCode===null){await Promise.race([new Promise(r=>chrome.once('exit',r)),delay(3000)]);if(chrome.exitCode===null)chrome.kill();}
  server.close();
}
