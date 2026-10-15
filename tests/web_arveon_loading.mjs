// Validate ARVÉON Web loading integration before deploy.
import {readFile,stat} from 'node:fs/promises';
import assert from 'node:assert/strict';
import path from 'node:path';
const root=path.resolve('build/web');
const html=await readFile(path.join(root,'index.html'),'utf8');
const code=await readFile(path.join(root,'arveon-loader.js'),'utf8');
const style=await readFile(path.join(root,'arveon-loader.css'),'utf8');
let checks=0;
function check(ok,msg){assert.ok(ok,msg);checks++;console.log('ARVEON_LOADING_PASS: '+msg);}
for(const marker of ['id="canvas"','id="status"','id="status-progress"','id="status-notice"'])
  check(html.includes(marker),`Godot retains ${marker}`);
check((html.match(/arveon-loader\.js/g)||[]).length===1,'exactly one script injection');
check((html.match(/arveon-loader\.css/g)||[]).length===1,'exactly one CSS injection');
check(html.includes('arveon-icon.svg'),'new branded favicon declared');
check(code.includes("progress = document.getElementById('status-progress')"),'uses actual engine progress');
check(code.includes('footer.append(box, dots, progress, caption, notice)'),'keeps original loader controls');
check(!/progress\.(value|max)\s*=/.test(code),'no simulated progress');
check(code.includes("'ARVÉON: Ascensão Ancestral'"),'browser-only name updated');
check(style.includes('arveon-mobile.avif')&&style.includes('arveon-desktop.avif'),'responsive background assets');
check(style.includes('#status-progress-inner'),'Godot 4 inner progress styled');
for(const name of ['arveon-mobile.avif','arveon-desktop.avif']){
  const {size}=await stat(path.join(root,name));
  check(size>=1000&&size<=250000,`optimized art ${name} (${size} bytes)`);
}
console.log(`ARVEON_LOADING_RESULT: ${checks} checks, 0 failures`);
