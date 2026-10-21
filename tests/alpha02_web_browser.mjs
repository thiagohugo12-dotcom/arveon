import http from 'node:http';
import {readFile, writeFile, mkdtemp} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join, resolve, extname} from 'node:path';
import {spawn} from 'node:child_process';
import assert from 'node:assert/strict';

const root = resolve(process.env.ARVEON_WEB_ROOT || 'build/alpha02/ARVEON_Alpha_0.2_Web');
const profile = await mkdtemp(join(tmpdir(), 'arveon-alpha02-'));
const types = {'.js':'application/javascript','.wasm':'application/wasm','.html':'text/html','.png':'image/png','.json':'application/json','.pck':'application/octet-stream'};
const server = http.createServer(async (req,res)=>{
  try {
    const path = decodeURIComponent(new URL(req.url,'http://localhost').pathname).replace(/^\//,'') || 'index.html';
    if (path.includes('..')) throw Error('path');
    const data = await readFile(join(root,path));
    res.setHeader('Content-Type',types[extname(path)] || 'application/octet-stream');
    res.end(data);
  } catch (_) { res.writeHead(404); res.end(); }
});
const remoteOrigin = process.env.ARVEON_WEB_URL;
if (!remoteOrigin) await new Promise(r=>server.listen(0,'127.0.0.1',r));
const origin = remoteOrigin || `http://127.0.0.1:${server.address().port}`;
const chrome = process.env.CHROME_BIN || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const browser = spawn(chrome,['--headless=new','--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--remote-debugging-port=0',`--user-data-dir=${profile}`,'about:blank'],{stdio:['ignore','ignore','pipe']});
let diagnostics=''; browser.stderr.on('data',d=>diagnostics=(diagnostics+d).slice(-5000));
const wait = ms=>new Promise(r=>setTimeout(r,ms));
let target;
for(let i=0;i<250;i++){
  try {
    const port=Number((await readFile(join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0]);
    target=(await (await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find(x=>x.type==='page');
    if(target) break;
  } catch (_) {}
  await wait(100);
}
if(!target) throw Error('Chromium indisponível: '+diagnostics);
const socket=new WebSocket(target.webSocketDebuggerUrl);
await new Promise(r=>socket.addEventListener('open',r,{once:true}));
let next=0; const pending=new Map(); const errors=[];
socket.addEventListener('message',event=>{
  const data=JSON.parse(event.data);
  if(data.id){const p=pending.get(data.id);pending.delete(data.id);data.error?p.reject(Error(JSON.stringify(data.error))):p.resolve(data.result);}
  if(data.method==='Runtime.exceptionThrown') errors.push(JSON.stringify(data.params.exceptionDetails));
  if(data.method==='Runtime.consoleAPICalled' && data.params.type==='error') errors.push(data.params.args.map(x=>x.value||'').join(' '));
});
function call(method,params={}){const id=++next;return new Promise((resolve,reject)=>{pending.set(id,{resolve,reject});socket.send(JSON.stringify({id,method,params}));});}
async function evalJs(expression){const value=await call('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true});if(value.exceptionDetails)throw Error(JSON.stringify(value.exceptionDetails));return value.result?.value;}
async function until(expression,timeout=30000){const start=Date.now();while(Date.now()-start<timeout){if(await evalJs(expression))return;await wait(150);}throw Error('Timeout: '+expression+'\n'+errors.slice(-4).join('\n'));}
function check(value,label){assert.ok(value,label);console.log('ALPHA02_WEB OK: '+label);}

try {
  await call('Runtime.enable'); await call('Page.enable'); await call('ServiceWorker.enable');
  await call('Emulation.setDeviceMetricsOverride',{width:390,height:844,deviceScaleFactor:1,mobile:true});
  await call('Page.navigate',{url:origin+'/index.html'});
  await until('document.readyState === "complete" && !!document.querySelector("canvas")');
  check(await evalJs('document.title.includes("Alpha 0.2")'),'título da Alpha aparece no navegador');
  check(await evalJs('!!document.querySelector(\'link[rel="manifest"]\')'),'manifesto PWA está ligado à página');
  check(await evalJs('!!document.createElement("canvas").getContext("webgl2")'),'WebGL2 disponível no navegador de teste');
  // The Godot bootstrap overlay receives input while the engine is loading.
  // Wait until it is removed before exercising the real Control buttons.
  await until('!document.getElementById("status")',60000);
  await wait(300);
  console.log('ALPHA02_WEB INFO: '+JSON.stringify(await evalJs('({canvas:document.querySelector("canvas").getBoundingClientRect().toJSON(),inner:[innerWidth,innerHeight]})')));
  const shot=await call('Page.captureScreenshot',{format:'png'});
  await writeFile('build/alpha02/capturas/alpha02-web-menu.png',Buffer.from(shot.data,'base64'));
  await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:195,y:443,id:1,radiusX:4,radiusY:4,force:1}]});
  await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await until('!!localStorage.getItem("grande-arvore-rpg.save.v6")');
  const save=await evalJs('JSON.parse(JSON.parse(localStorage.getItem("grande-arvore-rpg.save.v6")).payload)');
  check(save.version===12 && save.ascension.current_floor===1,'novo jogo grava save v12 no Andar 1');
  check(save.introduction.status==='active','novo jogo preserva a introdução inicial');
  await wait(800);
  const gameShot=await call('Page.captureScreenshot',{format:'png'});
  await writeFile('build/alpha02/capturas/alpha02-web-andar1.png',Buffer.from(gameShot.data,'base64'));
  await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:250,y:38,id:2,radiusX:4,radiusY:4,force:1}]});
  await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await wait(300);
  const diaryShot=await call('Page.captureScreenshot',{format:'png'});
  await writeFile('build/alpha02/capturas/alpha02-web-ficha.png',Buffer.from(diaryShot.data,'base64'));
  await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:299,y:153,id:3,radiusX:4,radiusY:4,force:1}]});
  await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await wait(300);
  const skillShot=await call('Page.captureScreenshot',{format:'png'});
  await writeFile('build/alpha02/capturas/alpha02-web-habilidades.png',Buffer.from(skillShot.data,'base64'));
  await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:196,y:449,id:4,radiusX:4,radiusY:4,force:1}]});
  await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await wait(250);
  const passiveShot=await call('Page.captureScreenshot',{format:'png'});
  await writeFile('build/alpha02/capturas/alpha02-web-passivas.png',Buffer.from(passiveShot.data,'base64'));
  await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:192,y:124,id:5,radiusX:4,radiusY:4,force:1}]});
  await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await wait(250);
  const talentShot=await call('Page.captureScreenshot',{format:'png'});
  await writeFile('build/alpha02/capturas/alpha02-web-proficiencias.png',Buffer.from(talentShot.data,'base64'));
  await call('Page.reload');
  await until('document.readyState === "complete" && !!document.querySelector("canvas")');
  await wait(1800);
  check(await evalJs('!!localStorage.getItem("grande-arvore-rpg.save.v6")'),'save permanece após recarregar a PWA');
  check(errors.length===0,'sem erros JavaScript relevantes');
} finally {
  try { await call('Browser.close'); } catch (_) {}
  socket.close(); if (server.listening) server.close();
  await Promise.race([new Promise(r=>browser.once('exit',r)),wait(3000)]);
  if(browser.exitCode===null) browser.kill('SIGKILL');
}
