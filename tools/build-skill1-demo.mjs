// New isolated entry. Neither main HTML nor the approved sword entry is replaced.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
const review=JSON.parse(await readFile('tools/skill1-review.json','utf8'));
const valid=review.status==='awaiting-visual-approval'&&review.fixedTestAlias===false;
if(!valid||review.entry!=='amostra-skills1/index.html')throw Error('Invalid staff review policy');
const source=await readFile('build/web/index.html','utf8');
const match=source.match(/const GODOT_CONFIG = (.*);/);
if(!match)throw Error('Godot shell configuration missing');
const config=JSON.parse(match[1]);
config.args=['res://scenes/demos/skill1_review.tscn'];
config.executable='../index';
config.fileSizes=Object.fromEntries(Object.entries(config.fileSizes).map(([p,n])=>['../'+p,n]));
const html=source.replace(match[0],'const GODOT_CONFIG = '+JSON.stringify(config)+';').replace('src="index.js"','src="../index.js"');
await mkdir('build/web/amostra-skills1',{recursive:true});
await writeFile('build/web/'+review.entry,html);
await writeFile('build/web/skill1-review.json',JSON.stringify(review,null,2)+'\n');
console.log('SKILL1_DEMO_WEB: isolated scene, existing sword and main entries preserved');
