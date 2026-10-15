// Real exported Godot: pause the PCK network response, never invent progress.
import {readFile,writeFile,mkdir,mkdtemp} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {spawn} from 'node:child_process';
import {tmpdir} from 'node:os';
import http from 'node:http';
import path from 'node:path';
import assert from 'node:assert/strict';
const web=path.resolve(process.env.LOADING_WEB_DIR||'build/web'),out=path.resolve(process.env.QA_LOADING_CAPTURE_DIR||'build/loading-qa');
await mkdir(out,{recursive:true});
const manifest=JSON.parse(await readFile(path.join(web,'arveon-loading.json'),'utf8'));
const profile=await mkdtemp(path.join(tmpdir(),'arveon-loading-'));
let browser,socket,id=0,checks=0,hold=true,pendingPack=[],errors=[],requests=[];
const pending=new Map(),delay=ms=>new Promise(r=>setTimeout(r,ms));
const sha=b=>createHash('sha256').update(b).digest('hex');
const server=http.createServer(async(req,res)=>{
  try{
    const name=decodeURIComponent(new URL(req.url,'http://localhost').pathname).slice(1)||'index.html';
    if(name.includes('..'))throw Error('path');
    const bytes=await readFile(path.join(web,name));
    const type={'.html':'text/html','.js':'application/javascript','.css':'text/css','.png':'image/png','.json':'application/json','.svg':'image/svg+xml','.wasm':'application/wasm'}[path.extname(name)]||'application/octet-stream';
    res.writeHead(200,{'Content-Type':type,'Content-Length':bytes.length,'Cache-Control':name.startsWith('loading-artwork/')?'public,max-age=31536000,immutable':'no-store'});
    if(hold&&name==='index.pck'){res.write(bytes.subarray(0,65536));pendingPack.push(()=>res.end(bytes.subarray(65536)));}
    else res.end(bytes);
  }catch{res.writeHead(404);res.end();}
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const origin=process.env.LOADING_TEST_BASE_URL||'http://127.0.0.1:'+server.address().port;
const remote=!!process.env.LOADING_TEST_BASE_URL;
let intercepted=[];
function check(value,message){assert.ok(value,message);checks++;console.log('LOADING_BROWSER_PASS: '+message);}
async function call(method,params={}){const n=++id;return new Promise((resolve,reject)=>{pending.set(n,{resolve,reject});socket.send(JSON.stringify({id:n,method,params}));});}
async function evaluate(expression){
 const r=await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});
 if(r.exceptionDetails)throw Error(JSON.stringify(r.exceptionDetails));
 return r.result?.value;
}
async function until(expression,timeout=45000){const start=Date.now();while(Date.now()-start<timeout){if(await evaluate(expression))return;await delay(100);}throw Error('Timeout '+expression+' '+errors.slice(-3).join('\n'));}
async function start(){
 browser=spawn(process.env.CHROME_BIN||'google-chrome',['--headless=new','--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--remote-debugging-port=0','--user-data-dir='+profile,'about:blank'],{stdio:['ignore','ignore','pipe']});
 let diagnostics='';browser.stderr.on('data',b=>diagnostics=(diagnostics+b).slice(-4000));browser.on('error',e=>diagnostics+=String(e));
 let target;
 for(let i=0;i<300;i++){try{const port=(await readFile(path.join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0];target=(await(await fetch('http://127.0.0.1:'+port+'/json/list')).json()).find(t=>t.type==='page');if(target)break;}catch{}await delay(100);}
 if(!target)throw Error('Chromium unavailable '+diagnostics);
 socket=new WebSocket(target.webSocketDebuggerUrl);
 await new Promise(r=>socket.addEventListener('open',r,{once:true}));
 socket.addEventListener('message',event=>{
  const m=JSON.parse(event.data);
  if(m.id){const p=pending.get(m.id);pending.delete(m.id);if(p)m.error?p.reject(Error(JSON.stringify(m.error))):p.resolve(m.result);}
  if(m.method==='Runtime.exceptionThrown')errors.push(JSON.stringify(m.params.exceptionDetails));
  if(m.method==='Network.requestWillBeSent')requests.push(m.params.request.url);
  if(m.method==='Fetch.requestPaused'){
   if(hold&&m.params.request.url.includes('index.pck'))intercepted.push(m.params.requestId);
   else call('Fetch.continueRequest',{requestId:m.params.requestId}).catch(e=>errors.push(String(e)));
  }
 });
 await call('Page.enable');await call('Runtime.enable');await call('Network.enable');
 if(remote)await call('Fetch.enable',{patterns:[{urlPattern:'*index.pck*',requestStage:'Request'}]});
}
try{
 await start();
 await call('Emulation.setDeviceMetricsOverride',{width:1920,height:1080,deviceScaleFactor:1,mobile:false});
 await call('Page.navigate',{url:origin+'/'});
 await until('document.querySelector(".arveon-art img")?.complete && document.querySelector(".arveon-art img")?.naturalWidth>0 && document.querySelector("#status.arveon-loading")?.dataset.artworkVersion==="approved-20261015"');
 await delay(1500);
 const initialTip=await evaluate('document.querySelector(".arveon-tip-text").textContent');
 const progressRef=await evaluate('(window.qaOriginalProgress=document.querySelector("#status-progress"),true)');
 check(progressRef,'native engine progress node exists');
 for(const [width,height,mobile]of [[1920,1080,false],[1366,768,false],[390,844,true],[360,800,true]]){
  await call('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile});
  const artwork=manifest[mobile?'mobile':'desktop'];
  await until('document.querySelector(".arveon-art img").complete && document.querySelector(".arveon-art img").currentSrc.includes('+JSON.stringify(path.basename(artwork.file))+')');
  await delay(250);
  const actual=await evaluate(`(()=>{
   const image=document.querySelector('.arveon-art img'),stage=document.querySelector('.arveon-scene'),tip=document.querySelector('.arveon-tip-text'),meter=document.querySelector('.arveon-meter'),bar=document.querySelector('#status-progress');
   const rect=n=>{const r=n.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,right:r.right,bottom:r.bottom};};
   return {src:image.currentSrc,natural:[image.naturalWidth,image.naturalHeight],image:rect(image),stage:rect(stage),tip:rect(tip),meter:rect(meter),bar:rect(bar),ratio:bar.value/bar.max,same:bar===window.qaOriginalProgress,count:document.querySelectorAll('#status-progress').length,tipFits:tip.scrollHeight<=tip.clientHeight,fit:getComputedStyle(image).objectFit,filter:getComputedStyle(image).filter,caption:getComputedStyle(document.querySelector('.arveon-loading-caption')).clipPath,width:innerWidth,height:innerHeight};
  })()`);
  check(actual.natural[0]===artwork.width&&actual.natural[1]===artwork.height,'correct original orientation '+width+'x'+height);
  check(actual.width===width&&actual.height===height&&actual.image.x>=-1&&actual.image.y>=-1&&actual.image.right<=width+1&&actual.image.bottom<=height+1,'whole composition fits viewport '+width+'x'+height);
  check(Math.abs(actual.image.width/actual.image.height-artwork.width/artwork.height)<0.002&&actual.fit==='contain'&&actual.filter==='none','no cropping stretching or blur '+width+'x'+height);
  check(actual.same&&actual.count===1&&actual.ratio>=0&&actual.ratio<=1,'one original engine-controlled bar '+width+'x'+height);
  check(actual.tipFits&&actual.meter.x>=actual.stage.x&&actual.meter.right<=actual.stage.right&&actual.meter.bottom<=actual.stage.bottom,'replacement controls fit original artwork '+width+'x'+height);
  check(actual.caption.includes('inset'),'no additional visible loading caption '+width+'x'+height);
  const png=await call('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});
  await writeFile(path.join(out,'loading-'+width+'x'+height+'.png'),Buffer.from(png.data,'base64'));
  await writeFile(path.join(out,'loading-'+width+'x'+height+'.json'),JSON.stringify(actual,null,2));
 }
 await until('document.querySelector(".arveon-tip-text").textContent!=='+JSON.stringify(initialTip),10000);
 check(true,'tips rotate during actual pending download');
 check(!requests.some(url=>/arveon-(desktop|mobile)\.avif/.test(url)),'no obsolete artwork URL requested');
 hold=false;for(const release of pendingPack)release();
 for(const requestId of intercepted)await call('Fetch.continueRequest',{requestId});intercepted=[];
 await until('!document.getElementById("status") && !!window.GrandeArvoreSave && !!localStorage.getItem("grande-arvore-rpg.save.v6")',90000);
 check(true,'full Godot initialization removes the loading screen');
 const before=await evaluate('JSON.parse(JSON.parse(localStorage.getItem("grande-arvore-rpg.save.v6")).payload)');
 check(before.version===11,'current save remains v11');
 const persisted=structuredClone(before);persisted.gold=47;persisted.bag.Madeira=3;
 const raw=JSON.stringify(persisted),archive=JSON.stringify({format:'grande-arvore-rpg-save',archive_version:1,payload:raw,sha256:sha(raw)});
 await evaluate('GrandeArvoreSave.write('+JSON.stringify(archive)+',true)');
 await call('Page.reload');
 await until('!document.getElementById("status") && !!window.GrandeArvoreSave && !!localStorage.getItem("grande-arvore-rpg.save.v6")',90000);
 await delay(1800);
 const after=await evaluate('JSON.parse(JSON.parse(localStorage.getItem("grande-arvore-rpg.save.v6")).payload)');
 check(after.version===11&&after.gold===47&&after.bag.Madeira===3&&JSON.stringify(after.rpg)===JSON.stringify(before.rpg),'existing v11 equipment attributes and inventory persist across reload');
 check(!errors.some(x=>/SCRIPT ERROR|Parse Error|Invalid call/.test(x)),'no runtime script error');
 for(const artwork of [manifest.desktop,manifest.mobile,...manifest.resources]){
  const response=await fetch(new URL('/'+artwork.file,origin));
  check(response.ok&&sha(Buffer.from(await response.arrayBuffer()))===artwork.sha256,'served bytes match '+artwork.file);
 }
 await writeFile(path.join(out,'result.json'),JSON.stringify({checks,failures:0,viewports:4,manifest,remote},null,2));
 console.log('LOADING_BROWSER_RESULT: '+checks+' checks, 0 failures');
}finally{
 for(const release of pendingPack)release();
 if(socket?.readyState===1){try{await call('Browser.close');}catch{}socket.close();}
 if(browser?.exitCode===null)browser.kill('SIGKILL');
 server.close();
}
