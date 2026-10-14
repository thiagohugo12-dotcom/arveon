// New isolated entry. Neither main HTML nor the approved sword entry is replaced.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
const review=JSON.parse(await readFile('tools/bow-review.json','utf8'));
const valid=(review.status==='awaiting-visual-approval'&&review.fixedTestAlias===false)||(review.status==='approved-in-game'&&review.fixedTestAlias===true);
if(!valid||review.entry!=='amostra-arco/index.html')throw Error('Invalid bow review policy');
const source=await readFile('build/web/index.html','utf8');
const match=source.match(/const GODOT_CONFIG = (.*);/);
if(!match)throw Error('Godot shell configuration missing');
const config=JSON.parse(match[1]);
config.args=['res://scenes/demos/bow_attack_demo.tscn'];
config.executable='../index';
config.fileSizes=Object.fromEntries(Object.entries(config.fileSizes).map(([p,n])=>['../'+p,n]));
const html=source.replace(match[0],'const GODOT_CONFIG = '+JSON.stringify(config)+';').replace('src="index.js"','src="../index.js"');
await mkdir('build/web/amostra-arco',{recursive:true});
await writeFile('build/web/'+review.entry,html);
await writeFile('build/web/bow-review.json',JSON.stringify(review,null,2)+'\n');
console.log('BOW_DEMO_WEB: isolated scene, existing sword and main entries preserved');
