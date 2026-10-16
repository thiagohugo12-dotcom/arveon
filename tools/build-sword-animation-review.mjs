// Standalone visual review: no Godot state, save access, or game entry changes.
import {copyFile,mkdir,readFile,stat,writeFile} from 'node:fs/promises';
import {join} from 'node:path';
const out='build/web/amostra-animacoes-espada';
await mkdir(out,{recursive:true});
const assets=[
  ['assets/art/sword_techniques/estocada_precisa.png','estocada_precisa.png'],
  ['assets/art/sword_techniques/guarda_reativa.png','guarda_reativa.png'],
  ['assets/art/sword_techniques/kamusari.png','kamusari.png'],
  ['tools/review_refs/estocada.png','ref-estocada.png'],
  ['tools/review_refs/guarda.png','ref-guarda.png'],
  ['tools/review_refs/kamusari.png','ref-kamusari.png']
];
for(const [source,dest] of assets){if((await stat(source)).size<100000)throw Error('Review image missing or incomplete: '+source);await copyFile(source,join(out,dest))}
const html=await readFile('tools/sword-animation-review.html','utf8');
for(const [,name] of assets)if(!html.includes(name))throw Error('Review page does not reference '+name);
await writeFile(join(out,'index.html'),html);
console.log('SWORD_ANIMATION_REVIEW: 3 six-frame atlases and 3 original reference boards; game entry unchanged');
