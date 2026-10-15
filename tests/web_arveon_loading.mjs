// Approved originals and native Godot bootstrap must survive every export.
import {readFile,stat} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
import path from 'node:path';
const root=path.resolve('build/web'),sha=b=>createHash('sha256').update(b).digest('hex');
const html=await readFile(path.join(root,'index.html'),'utf8');
const manifest=JSON.parse(await readFile(path.join(root,'arveon-loading.json'),'utf8'));
const approved=JSON.parse(await readFile('assets/loading/approved-artwork.json','utf8'));
const code=await readFile(path.join(root,manifest.resources.find(r=>r.file.endsWith('.js')).file),'utf8');
const style=await readFile(path.join(root,manifest.resources.find(r=>r.file.endsWith('.css')).file),'utf8');
let checks=0;
function check(ok,msg){assert.ok(ok,msg);checks++;console.log('ARVEON_LOADING_PASS: '+msg);}
for(const marker of ['id="canvas"','id="status"','id="status-progress"','id="status-notice"'])check(html.includes(marker),'retains '+marker);
check((html.match(/arveon-loader-[a-f0-9]+\.js/g)||[]).length===1,'one versioned loader script');
check((html.match(/arveon-loader-[a-f0-9]+\.css/g)||[]).length===1,'one versioned loader stylesheet');
check(code.includes("document.getElementById('status-progress')")&&code.includes('meter.append(progress)'),'reuses original native progress');
check(!/progress\.(value|max)\s*=/.test(code),'loader never invents a percentage');
check(html.includes('statusProgress.value = current')&&html.includes('statusProgress.max = total'),'real engine onProgress remains intact');
check(style.includes('object-fit:contain')&&!style.includes('background-size:cover'),'whole composition without cover cropping');
check(code.includes("mobile.media='(max-width:767px)'")&&code.includes('picture.append(mobile,image)'),'separate responsive approved sources');
check(!/\.avif/.test(html+code+style),'obsolete art never referenced');
check(manifest.version==='approved-20261015','approved artwork version');
for(const kind of ['desktop','mobile']){
 const info=manifest[kind],bytes=await readFile(path.join(root,info.file));
 check(bytes.subarray(0,8).toString('hex')==='89504e470d0a1a0a','lossless PNG '+kind);
 check(sha(bytes)===approved[kind].png_sha256&&info.sha256===approved[kind].png_sha256,'approved original pixel-preserving asset '+kind);
 check(bytes.readUInt32BE(16)===info.width&&bytes.readUInt32BE(20)===info.height,'original resolution '+kind);
 check(bytes.length<2500000&&bytes.length>350000,'full-quality artwork '+kind);
}
for(const info of manifest.resources)check(sha(await readFile(path.join(root,info.file)))===info.sha256,'versioned resource '+info.file);
for(const old of ['arveon-desktop.avif','arveon-mobile.avif']){
 let found=true;try{await stat(path.join(root,old));}catch{found=false;}
 check(!found,'old exported artwork removed '+old);
}
console.log('ARVEON_LOADING_RESULT: '+checks+' checks, 0 failures');
