// Shared WASM/PCK; isolated scene, original main HTML never overwritten.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
const source=await readFile('build/web/index.html','utf8');
const match=source.match(/const GODOT_CONFIG = (.*);/);
if(!match)throw Error('Godot 4.5.1 shell configuration missing');
const config=JSON.parse(match[1]);
config.args=['res://scenes/demos/sword_attack_demo.tscn'];
config.executable='../index';
config.fileSizes=Object.fromEntries(Object.entries(config.fileSizes).map(([p,n])=>['../'+p,n]));
const html=source.replace(match[0],'const GODOT_CONFIG = '+JSON.stringify(config)+';').replace('src="index.js"','src="../index.js"');
await mkdir('build/web/amostra-espada',{recursive:true});
await writeFile('build/web/amostra-espada/index.html',html);
await writeFile('build/web/sword-review.json',await readFile('tools/sword-review.json'));
console.log('SWORD_DEMO_WEB: isolated scene, shared WASM/PCK, main HTML unchanged');
