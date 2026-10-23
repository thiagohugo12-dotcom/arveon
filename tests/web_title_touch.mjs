// Real Godot Web export, CDP browser Touch/Mouse events. No handler invocation.
import {readFile,writeFile,mkdir,mkdtemp} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {tmpdir} from 'node:os';
import path from 'node:path';
import http from 'node:http';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
const root=path.resolve(process.env.TITLE_WEB_DIR||'build/web');
const out=path.resolve(process.env.TITLE_QA_DIR||'build/title-touch-qa');
await mkdir(out,{recursive:true});
const server=http.createServer(async(req,res)=>{
 try{const name=decodeURIComponent(new URL(req.url,'http://localhost').pathname).slice(1)||'index.html';
 if(name.includes('..'))throw Error('path');
 const data=await readFile(path.join(root,name));
 res.writeHead(200,{'Content-Type':({'.html':'text/html','.js':'application/javascript','.css':'text/css','.wasm':'application/wasm','.png':'image/png','.json':'application/json'})[path.extname(name)]||'application/octet-stream','Cache-Control':'no-store'});res.end(data);
 }catch{res.writeHead(404);res.end();}
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const origin=process.env.TITLE_WEB_URL||`http://127.0.0.1:${server.address().port}`;
const delay=ms=>new Promise(r=>setTimeout(r,ms));
let checks=0;
const results=[];
function check(value,label){assert.ok(value,label);checks++;console.log('TITLE_WEB_PASS: '+label);}
async function session(mode,url,baselineButtons){
 const mobile=mode!=='desktop', width=mobile?360:1280,height=mobile?800:720;
 const profile=await mkdtemp(path.join(tmpdir(),'arveon-title-'));
 const browser=spawn(process.env.CHROME_BIN||'google-chrome',['--headless=new','--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--remote-debugging-port=0','--user-data-dir='+profile,'about:blank'],{stdio:['ignore','ignore','pipe']});
 let diagnostics='';browser.stderr.on('data',b=>diagnostics=(diagnostics+b).slice(-3000));
 let target,socket,id=0;const pending=new Map(),states=[],started=[],errors=[];
 for(let n=0;n<200;n++){try{const port=(await readFile(path.join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0];target=(await(await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find(t=>t.type==='page');if(target)break;}catch{}await delay(100);}
 if(!target)throw Error('Chromium startup: '+diagnostics);
 socket=new WebSocket(target.webSocketDebuggerUrl);await new Promise(r=>socket.addEventListener('open',r,{once:true}));
 socket.addEventListener('message',e=>{const m=JSON.parse(e.data);if(m.id){const p=pending.get(m.id);pending.delete(m.id);if(p)m.error?p.reject(Error(JSON.stringify(m.error))):p.resolve(m.result);}
 if(m.method==='Runtime.exceptionThrown')errors.push(JSON.stringify(m.params.exceptionDetails));
 if(m.method==='Runtime.consoleAPICalled')for(const arg of m.params.args){const s=arg.value;if(typeof s!=='string')continue;if(s.startsWith('ARVEON_TITLE_STATE '))states.push(JSON.parse(s.slice(19)));if(s.startsWith('ARVEON_TITLE_STARTED '))started.push(JSON.parse(s.slice(21)));if(/SCRIPT ERROR|Parse Error|Invalid call/.test(s))errors.push(s);}
 });
 const call=(method,params={})=>new Promise((resolve,reject)=>{const n=++id;pending.set(n,{resolve,reject});socket.send(JSON.stringify({id:n,method,params}));});
 const evaluate=async expression=>{const r=await call('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true});if(r.exceptionDetails)throw Error(JSON.stringify(r.exceptionDetails));return r.result?.value;};
 const until=async(predicate,label,timeout=45000)=>{const begin=Date.now();while(Date.now()-begin<timeout){if(await predicate())return;await delay(100);}throw Error(`${mode} timeout ${label}; states=${JSON.stringify(states)} errors=${errors.join('\n')}`);};
 const shot=async name=>{await delay(250);const r=await call('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});await writeFile(path.join(out,mode+'-'+name+'.png'),Buffer.from(r.data,'base64'));return r.data;};
 const touch=async(type,points)=>call('Input.dispatchTouchEvent',{type,touchPoints:points});
 const point=b=>({x:b.x,y:b.y,id:1,radiusX:4,radiusY:4,force:1});
 const click=async b=>{if(mobile){await touch('touchStart',[point(b)]);await delay(70);await touch('touchEnd',[]);}else{await call('Input.dispatchMouseEvent',{type:'mouseMoved',x:b.x,y:b.y});await call('Input.dispatchMouseEvent',{type:'mousePressed',x:b.x,y:b.y,button:'left',clickCount:1});await call('Input.dispatchMouseEvent',{type:'mouseReleased',x:b.x,y:b.y,button:'left',clickCount:1});}};
 const state=()=>states.at(-1);
 const button=text=>{const b=state().buttons.find(b=>b.text===text);assert.ok(b&&!b.disabled,'button available '+text);return b;};
 try{
 await call('Page.enable');await call('Runtime.enable');
 await call('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile});
 await call('Emulation.setTouchEmulationEnabled',{enabled:mobile,maxTouchPoints:5});
 await call('Page.addScriptToEvaluateOnNewDocument',{source:`window.titleBrowserEvents=[];for(const type of ['touchstart','touchend','touchmove','mousedown'])document.addEventListener(type,e=>titleBrowserEvents.push({type,trusted:e.isTrusted,target:e.target.id}),true);`});
 await call('Page.navigate',{url:url.replace(/\/$/,'')+'/index.html'});
 await until(()=>evaluate('document.readyState==="complete" && !!document.querySelector("canvas") && !document.getElementById("status")'),'loader removed',60000);
 await delay(600);
 const html=await evaluate(`(()=>{const c=document.querySelector('canvas'),r=c.getBoundingClientRect();return {status:!!document.getElementById('status'),viewport:[innerWidth,innerHeight],canvas:r.toJSON(),hit:document.elementFromPoint(innerWidth/2,innerHeight/2)?.id,pointer:getComputedStyle(c).pointerEvents};})()`);
 check(!html.status&&html.hit==='canvas'&&html.pointer!=='none',mode+': HTML loader removed; canvas receives hit testing');
 check(html.viewport[0]===width&&html.viewport[1]===height,mode+': exact viewport');
 if(mode==='baseline'){
  const before=await shot('before');await click(baselineButtons.settings);await delay(600);const after=await shot('settings-touch');
  const same=before===after;console.log('TITLE_BASELINE: '+JSON.stringify({sameImage:same,html}));
  await click(baselineButtons.play);await delay(1200);
  const save=await evaluate('!!localStorage.getItem("grande-arvore-rpg.save.v6")');
  await shot('play-touch');results.push({mode,sameImage:same,saveCreated:save,html});
  check(same&&!save,'previous deployed build reproduces ignored touch');return;
 }
 await until(()=>states.length>0,'title ready');
 const initial=structuredClone(state()),settings=button('Configurações'),play=button('Jogar · novo jogo');
 for(const b of [settings,play])check(b.x>0&&b.x<width&&b.y>0&&b.y<height,mode+': '+b.text+' coordinates inside canvas');
 await shot('before');
 if(mobile){
  const count=states.length;
  await touch('touchStart',[point(settings)]);await touch('touchMove',[point({...settings,x:settings.x+45})]);await touch('touchMove',[point(settings)]);await touch('touchEnd',[]);await delay(500);
  check(states.length===count&&!state().settings,'mobile: drag away and back does not activate');
  await touch('touchStart',[point({...settings,y:settings.y+90})]);await touch('touchMove',[point(settings)]);await touch('touchEnd',[]);await delay(350);
  check(states.length===count,'mobile: gesture beginning outside button does not activate');
 }
 await click(settings);await until(()=>state().settings,'settings open');
 await shot('settings-open');
 check(states.filter(s=>s.settings).length===1,mode+': settings opens once');
 if(mobile){
  await click(play);await delay(400);check(started.length===0&&state().settings,'mobile: title buttons behind modal cannot start game');
  const sound=button('Som: ligado');await click(sound);await until(()=>state().buttons.some(b=>b.text==='Som: desligado'),'single audio toggle');
  await delay(300);check(state().buttons.some(b=>b.text==='Som: desligado'),'mobile: touch does not double-toggle audio');
 }
 await click(button('Voltar'));await until(()=>!state().settings,'settings closed');await shot('settings-closed');
 check(!state().settings,mode+': Voltar closes panel');
 await click(button('Jogar · novo jogo'));
 await until(()=>started.length===1,'new game transition');
 await until(()=>evaluate('!!localStorage.getItem("grande-arvore-rpg.save.v6")'),'new save');
 const save=await evaluate('JSON.parse(JSON.parse(localStorage.getItem("grande-arvore-rpg.save.v6")).payload)');
 check(save.ascension.current_floor===1&&started[0].floor===1&&started[0].player,mode+': new game instantiates player on Floor 1 and persists save');
 await shot('floor1');await delay(400);check(started.length===1,mode+': game starts exactly once');
 const events=await evaluate('titleBrowserEvents');
 check(events.some(e=>e.trusted&&e.target==='canvas'&&e.type===(mobile?'touchstart':'mousedown')),mode+': trusted browser input reached canvas');
 check(errors.length===0,mode+': no runtime script errors');
 results.push({mode,html,initial,states,started,events,saveFloor:save.ascension.current_floor});
 return {settings,play};
 }catch(error){await shot('failure').catch(()=>{});throw error;
 }finally{await writeFile(path.join(out,mode+'-diagnostics.json'),JSON.stringify({html:await evaluate('({status:!!document.getElementById("status")})').catch(()=>null),states,started,errors},null,2));try{await call('Browser.close');}catch{}socket.close();if(browser.exitCode===null)browser.kill('SIGKILL');}
}
try{
 const buttons=await session('mobile',origin);
 await session('desktop',origin);
 if(process.env.TITLE_BASELINE_URL)await session('baseline',process.env.TITLE_BASELINE_URL,buttons);
 const pck=await readFile(path.join(root,'index.pck'));
 await writeFile(path.join(out,'result.json'),JSON.stringify({checks,failures:0,pckSha256:createHash('sha256').update(pck).digest('hex'),results},null,2));
 console.log(`TITLE_WEB_RESULT: ${checks} checks, 0 failures`);
}finally{server.close();}
