// Separate entry point. The exported game's main HTML/configuration is untouched.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
const source=await readFile('build/web/index.html','utf8');
const match=source.match(/const GODOT_CONFIG = (.*);/);
if(!match)throw Error('Godot 4.5.1 shell configuration missing');
const config=JSON.parse(match[1]);
config.args=['res://scenes/demos/mata_art_sample.tscn'];
config.executable='../index';
config.fileSizes=Object.fromEntries(Object.entries(config.fileSizes).map(([p,n])=>['../'+p,n]));
const html=source.replace(match[0],'const GODOT_CONFIG = '+JSON.stringify(config)+';').replace('src="index.js"','src="../index.js"');
await mkdir('build/web/amostra-mata',{recursive:true});
await writeFile('build/web/amostra-mata/index.html',html);
console.log('ART_SAMPLE_WEB: separate scene entry, shared WASM/PCK, main HTML unchanged');
