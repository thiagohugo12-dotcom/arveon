// New isolated entry. Neither main HTML nor the approved sword entry is replaced.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
const review=JSON.parse(await readFile('tools/melee-review.json','utf8'));
const valid=(review.status==='awaiting-visual-approval'&&review.fixedTestAlias===false)||(review.status==='approved-in-game'&&review.fixedTestAlias===true);
if(!valid||review.entry!=='amostra-machado/index.html')throw Error('Invalid melee review policy');
const source=await readFile('build/web/index.html','utf8');
const match=source.match(/const GODOT_CONFIG = (.*);/);
if(!match)throw Error('Godot shell configuration missing');
for(const [entry,scene] of [['amostra-machado/index.html','axe'],['amostra-lanca/index.html','spear']]) {
const config=JSON.parse(match[1]);
config.args=[`res://scenes/demos/${scene}_attack_demo.tscn`];
config.executable='../index';
config.fileSizes=Object.fromEntries(Object.entries(config.fileSizes).map(([p,n])=>['../'+p,n]));
const html=source.replace(match[0],'const GODOT_CONFIG = '+JSON.stringify(config)+';').replace('src="index.js"','src="../index.js"');
await mkdir('build/web/'+entry.split('/')[0],{recursive:true});
await writeFile('build/web/'+entry,html);
}
await writeFile('build/web/melee-review.json',JSON.stringify(review,null,2)+'\n');
console.log('MELEE_DEMO_WEB: isolated scene, existing sword and main entries preserved');
