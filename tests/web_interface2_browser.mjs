// End-to-end browser test: real CDP touch/mouse input on the exported Godot game.
import {readFile,writeFile,mkdir,mkdtemp} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {tmpdir} from 'node:os';
import path from 'node:path';
import http from 'node:http';
import assert from 'node:assert/strict';

const root=path.resolve(process.env.UI2_WEB_DIR||'build/web');
const out=path.resolve(process.env.UI2_QA_DIR||'build/interface2-browser-qa');
await mkdir(out,{recursive:true});
const server=http.createServer(async(req,res)=>{
 try{const name=decodeURIComponent(new URL(req.url,'http://localhost').pathname).slice(1)||'index.html';if(name.includes('..'))throw Error('path');const data=await readFile(path.join(root,name));res.writeHead(200,{'Content-Type':({'.html':'text/html','.js':'application/javascript','.css':'text/css','.wasm':'application/wasm','.png':'image/png','.json':'application/json'})[path.extname(name)]||'application/octet-stream','Cache-Control':'no-store'});res.end(data);}catch{res.writeHead(404);res.end();}
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const origin=(process.env.UI2_WEB_URL||`http://127.0.0.1:${server.address().port}`).replace(/\/+$/,'');
const delay=ms=>new Promise(r=>setTimeout(r,ms));
let checks=0;
function check(value,label){assert.ok(value,label);checks++;console.log('INTERFACE2_BROWSER_PASS: '+label);}

async function session(mode){
 const mobile=mode==='mobile',width=mobile?360:1280,height=mobile?800:720;
 const profile=await mkdtemp(path.join(tmpdir(),'arveon-ui2-'));
 const browser=spawn(process.env.CHROME_BIN||'google-chrome',['--headless=new','--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--remote-debugging-port=0','--user-data-dir='+profile,'about:blank'],{stdio:['ignore','ignore','pipe']});
 let diagnostics='';browser.stderr.on('data',b=>diagnostics=(diagnostics+b).slice(-4000));
 let target,socket,id=0;const pending=new Map(),titles=[],ui=[],moves=[],touchDiagnostics=[],errors=[];
 let canvasRect;
 for(let n=0;n<200;n++){try{const port=(await readFile(path.join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0];target=(await(await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find(t=>t.type==='page');if(target)break;}catch{}await delay(100);}
 if(!target)throw Error('Chromium startup: '+diagnostics);
 socket=new WebSocket(target.webSocketDebuggerUrl);await new Promise(r=>socket.addEventListener('open',r,{once:true}));
 socket.addEventListener('message',e=>{const m=JSON.parse(e.data);if(m.id){const p=pending.get(m.id);pending.delete(m.id);if(p)m.error?p.reject(Error(JSON.stringify(m.error))):p.resolve(m.result);}if(m.method==='Runtime.exceptionThrown')errors.push(JSON.stringify(m.params.exceptionDetails));if(m.method==='Runtime.consoleAPICalled')for(const arg of m.params.args){const s=arg.value;if(typeof s!=='string')continue;if(s.startsWith('ARVEON_TITLE_STATE '))titles.push(JSON.parse(s.slice(19)));if(s.startsWith('ARVEON_TITLE_STARTED '))titles.push({started:JSON.parse(s.slice(21))});if(s.startsWith('ARVEON_UI2_STATE '))ui.push(JSON.parse(s.slice(17)));if(s.startsWith('ARVEON_UI2_MOVE '))moves.push(JSON.parse(s.slice(16)));if(s.startsWith('ARVEON_UI2_TOUCH '))touchDiagnostics.push(JSON.parse(s.slice(17)));if(/SCRIPT ERROR|Parse Error|Invalid call|Invalid access/.test(s))errors.push(s);}});
 const call=(method,params={})=>new Promise((resolve,reject)=>{const n=++id;pending.set(n,{resolve,reject});socket.send(JSON.stringify({id:n,method,params}));});
 const evaluate=async expression=>{const r=await call('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true});if(r.exceptionDetails)throw Error(JSON.stringify(r.exceptionDetails));return r.result?.value;};
 const until=async(predicate,label,timeout=45000)=>{const begin=Date.now();while(Date.now()-begin<timeout){if(await predicate())return;await delay(100);}throw Error(`${mode} timeout ${label}; title=${JSON.stringify(titles.slice(-2))} ui=${JSON.stringify(ui.slice(-3))} movement=${JSON.stringify(moves.slice(-3))} touch=${JSON.stringify(touchDiagnostics.slice(-5))} errors=${errors.join('\n')}`);};
 const shot=async name=>{await delay(250);const r=await call('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});await writeFile(path.join(out,mode+'-'+name+'.png'),Buffer.from(r.data,'base64'));return r.data;};
 const current=screen=>[...ui].reverse().find(s=>s.screen===screen&&s.panel_visible);
 const button=(screen,predicate)=>{const b=current(screen)?.buttons.find(x=>!x.disabled&&predicate(x));assert.ok(b,`${screen} button not found`);return b;};
 const screenPoint=(state,x,y)=>({x:canvasRect.left+x*canvasRect.width/state.viewport[0],y:canvasRect.top+y*canvasRect.height/state.viewport[1]});
 const point=b=>{const s=current(b.screen)||{viewport:[width,height]};if(b.screen==='blacksmith'&&b.text==='Escolher primeira arma')return screenPoint(s,s.viewport[0]/2,s.viewport[1]*0.33);if(b.screen==='blacksmith'&&b.text==='Escolher Espada')return screenPoint(s,s.viewport[0]/2,s.viewport[1]*0.43);if(b.screen==='blacksmith'&&b.text==='Confirmar')return screenPoint(s,s.viewport[0]/2,s.viewport[1]*0.30);if(b.screen==='death'&&b.text==='Ver detalhes')return screenPoint(s,s.viewport[0]/2,s.viewport[1]*0.84);if(b.screen==='death'&&b.text.includes('Voltar ao acampamento'))return screenPoint(s,s.viewport[0]/2,s.viewport[1]*0.91);if(Number.isFinite(b.touch_x)&&Number.isFinite(b.touch_y))return screenPoint(s,b.touch_x,b.touch_y);return screenPoint(s,b.x+b.w/2,b.y+b.h/2);};
 const input=async(p,kind)=>{if(mobile){await call('Input.dispatchTouchEvent',{type:kind==='down'?'touchStart':'touchEnd',touchPoints:kind==='down'?[{...p,id:1,radiusX:4,radiusY:4,force:1}]:[]});}else{await call('Input.dispatchMouseEvent',{type:kind==='down'?'mousePressed':'mouseReleased',x:p.x,y:p.y,button:'left',clickCount:1});}};
 const tap=async b=>{canvasRect=await evaluate('(()=>{const r=document.querySelector("canvas").getBoundingClientRect();return {width:r.width,height:r.height,left:r.left,top:r.top}})()');const p=point(b);await input(p,'down');await delay(70);await input(p,'up');};
 try{
  await call('Page.enable');await call('Runtime.enable');
  await call('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile});
  await call('Emulation.setTouchEmulationEnabled',{enabled:mobile,maxTouchPoints:5});
  await call('Page.addScriptToEvaluateOnNewDocument',{source:'window.__ARVEON_UI2_TEST__=true;window.ui2BrowserEvents=[];for(const t of ["touchstart","touchend","mousedown"])document.addEventListener(t,e=>ui2BrowserEvents.push({type:t,trusted:e.isTrusted,target:e.target.id}),true);'});
  await call('Page.navigate',{url:origin+'/index.html'});
  await until(()=>evaluate('document.readyState==="complete"&&!!document.querySelector("canvas")&&!document.getElementById("status")'),'canvas ready');
  await until(()=>titles.some(s=>s.buttons),'title buttons ready');
  const titleButton=text=>{const b=titles.filter(s=>s.buttons).at(-1).buttons.find(x=>x.text===text);assert.ok(b,'title '+text);return b;};
  const titleState=titles.filter(s=>s.buttons).at(-1);const play=titleButton('Jogar · novo jogo');
  canvasRect=await evaluate('(()=>{const r=document.querySelector("canvas").getBoundingClientRect();return {width:r.width,height:r.height,left:r.left,top:r.top}})()');
  await shot('title-before');
  const p={x:canvasRect.left+play.x*canvasRect.width/titleState.viewport[0],y:canvasRect.top+play.y*canvasRect.height/titleState.viewport[1]};await input(p,'down');await delay(70);await input(p,'up');
  await until(()=>titles.some(s=>s.started),'new game starts');
  check(titles.filter(s=>s.started).at(-1).started.floor===1,mode+': new game enters Andar 1');
  await until(()=>ui.some(s=>s.screen==='hud'),'game HUD state');
  await until(()=>evaluate('!!localStorage.getItem("grande-arvore-rpg.save.v6")'),'save initialized');
  await shot('floor1');
  const hud=[...ui].reverse().find(s=>s.screen==='hud');
  const evolution={...hud.buttons.find(b=>b.tooltip.includes('Ficha do personagem')),screen:'hud'};
  check(!!evolution.tooltip,mode+': real browser event starts new game and reports character button geometry');
  await tap(evolution);
  await until(()=>current('evolution'),'Evolution opens through browser input');
  await shot('evolution');
  const evo=current('evolution');check(evo.buttons.length>12&&evo.viewport[0]>0&&evo.viewport[1]>0,mode+': Evolution renders a scrollable real game panel');
  const close={...button('evolution',b=>b.text==='×'),screen:'evolution'};const beforeClose=ui.length;await tap(close);
  await until(()=>ui.length>beforeClose&&[...ui].reverse()[0]?.screen==='hud','Evolution closes back to the HUD');
  // Fresh characters spawn a short walk from the smith. Use the on-screen
  // joystick itself so the mobile path stays an actual touch interaction.
  const camp=[...ui].reverse().find(s=>s.screen==='hud');
  if(mobile){
   const joy=camp.joystick,start=screenPoint(camp,joy.x+joy.w/2,joy.y+joy.h/2);
   await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{...start,id:2,radiusX:4,radiusY:4,force:1}]});
   for(let i=1;i<=8;i++){await call('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:start.x-38,y:start.y-12,id:2,radiusX:4,radiusY:4,force:1}]});await delay(100);}
   await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  }else{
   await call('Input.dispatchKeyEvent',{type:'keyDown',key:'a',code:'KeyA',windowsVirtualKeyCode:65});await delay(850);await call('Input.dispatchKeyEvent',{type:'keyUp',key:'a',code:'KeyA',windowsVirtualKeyCode:65});
  }
  await until(()=>{const h=[...ui].reverse().find(s=>s.screen==='hud');return h?.interact.visible&&h.interact.caption.includes('Ferreiro');},'Ferreiro interaction becomes available at camp');
  await tap({...([...ui].reverse().find(s=>s.screen==='hud').interact),screen:'hud'});
  await until(()=>current('blacksmith'),'Blacksmith appears');
  if(current('blacksmith').buttons.some(b=>b.text==='Escolher primeira arma')){
   await tap({...button('blacksmith',b=>b.text==='Escolher primeira arma'),screen:'blacksmith'});
   await until(()=>current('blacksmith')?.buttons.some(b=>b.text==='Escolher Espada'),'starter weapon choices appear');
   await tap({...button('blacksmith',b=>b.text==='Escolher Espada'),screen:'blacksmith'});
   await until(()=>current('blacksmith')?.buttons.some(b=>b.text==='Confirmar'),'starter weapon confirmation appears');
   await tap({...button('blacksmith',b=>b.text==='Confirmar'),screen:'blacksmith'});
   await until(()=>current('blacksmith')?.buttons.some(b=>b.text==='Forjar'),'starter choice unlocks regular Blacksmith tabs');
  }
  await shot('blacksmith-forjar');
  for(const name of ['Forjar','Aprimorar','Evoluir'])check(!!current('blacksmith').buttons.find(b=>b.text===name),mode+': Blacksmith tab '+name+' exists');
  let prior=ui.length;
  await tap({...button('blacksmith',b=>b.text==='Aprimorar'),screen:'blacksmith'});
  await until(()=>ui.length>prior,'enhance tab refreshes after real input');
  await shot('blacksmith-aprimorar');
  prior=ui.length;
  await tap({...button('blacksmith',b=>b.text==='Evoluir'),screen:'blacksmith'});
  await until(()=>ui.length>prior,'evolution tab refreshes after real input');
  await delay(250);await shot('blacksmith-evoluir');
  prior=ui.length;
  await tap({...button('blacksmith',b=>b.text==='×'),screen:'blacksmith'});
  await until(()=>ui.length>prior,'Blacksmith closes');
  if(mobile){
   const world=[...ui].reverse().find(s=>s.screen==='hud'),joy=world.joystick,start=screenPoint(world,joy.x+joy.w/2,joy.y+joy.h/2);
   await call('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{...start,id:2,radiusX:4,radiusY:4,force:1}]});
   for(let i=1;i<=130;i++){const offset=Math.min(52,i*2);await call('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:start.x-offset,y:start.y-offset,id:2,radiusX:4,radiusY:4,force:1}]});await delay(100);}
   await shot('joystick-held');await call('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
   check(moves.some(m=>Math.hypot(...m.direction)>0.2&&!m.blocked),'mobile joystick delivers movement after menu close');
   check(new Set(moves.filter(m=>Math.hypot(...m.direction)>0.2).map(m=>m.position.join(','))).size>1,'player moves in the world after menu close');
   await shot('after-forge-walk');
  }
  // Invoke the real Health.died signal through a QA-only browser callback. This
  // keeps this integration test deterministic while the visible controls below
  // still receive trusted CDP Touch/Mouse events on the exported canvas.
  await until(()=>evaluate('typeof window.ui2TriggerDeath==="function"'),'QA death bridge is installed');
  await evaluate('window.ui2TriggerDeath()');
  await until(()=>current('death'),'real Health death displays the result panel');
  await shot('death');
  const death=current('death'),outcome=death.death_result;
  check(death.labels.includes('Derrotado por: '+outcome.enemy)&&outcome.enemy==='Inimigo de teste',mode+': death panel reports the source recorded by the real death transaction');
  check(death.labels.includes('Ouro perdido: '+outcome.gold_lost)&&death.labels.includes('XP perdido: '+outcome.xp_lost),mode+': death panel displays the exact gold and XP deltas returned by the death transaction');
  check(outcome.item_count>0?death.labels.includes(`Item perdido: ${outcome.item_lost} × ${outcome.item_count}`):death.labels.includes('Nenhum item perdido'),mode+': death panel displays the exact item loss or no-loss message');
  const details={...button('death',b=>b.text==='Ver detalhes'),screen:'death'};await tap(details);
  await until(()=>current('death')?.buttons.some(b=>b.text==='Ocultar detalhes'),'death details open from touch/mouse');
  await shot('death-details');
  const back={...button('death',b=>b.text.includes('Voltar ao acampamento')),screen:'death'};const beforeReturn=ui.length;await tap(back);
  await until(()=>ui.length>beforeReturn&&[...ui].reverse()[0]?.screen==='hud','death return reloads the game HUD into the camp');
  const returned=[...ui].reverse().find(s=>s.screen==='hud');
  check(returned.labels.some(s=>s==='100 / 100'),mode+': death return restores a live player');
  check(death.death_result.floor===1&&returned.screen==='hud',mode+': death return restores the Andar 1 camp HUD');
  const trusted=await evaluate('ui2BrowserEvents.some(e=>e.trusted&&e.target==="canvas"&&e.type==="'+(mobile?'touchstart':'mousedown')+'")');
  check(trusted,mode+': trusted Touch/Mouse browser events reached the exported canvas');
  check(errors.length===0,mode+': no runtime script errors');
  return {mode,viewport:[width,height],events:await evaluate('ui2BrowserEvents'),states:ui,movement:moves,started:titles.filter(s=>s.started),errors};
 }catch(error){await shot('failure').catch(()=>{});throw error;}
 finally{try{await call('Browser.close');}catch{}socket.close();if(browser.exitCode===null)browser.kill('SIGKILL');}
}

try{
 const results=[];results.push(await session('mobile'));results.push(await session('desktop'));
 await writeFile(path.join(out,'result.json'),JSON.stringify({checks,failures:0,results},null,2));
 console.log(`INTERFACE2_BROWSER_RESULT: ${checks} checks, 0 failures`);
}finally{server.close();}
