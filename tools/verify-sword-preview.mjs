// CI's visual-review branch never invokes the fixed TESTE alias publisher.
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const review=JSON.parse(await readFile(new URL('./sword-review.json',import.meta.url),'utf8'));
if(review.fixedTestAlias!==false || review.status!=='awaiting-visual-approval' || review.entry!=='amostra-espada/index.html')throw Error('Unexpected review policy; fixed alias remains blocked');
const url=new URL(process.env.PREVIEW_URL);
if(url.protocol!=='https:' || !url.hostname.endsWith('.vercel.app') || url.hostname==='grande-arvore-rpg-teste.vercel.app' || url.hostname==='grande-arvore-rpg.vercel.app')throw Error('Expected unique preview URL');
const hash=b=>createHash('sha256').update(b).digest('hex');
for(const name of [review.entry,'index.pck','sword-review.json']){
  const response=await fetch(new URL(name,url),{cache:'no-store',signal:AbortSignal.timeout(30000)});
  if(!response.ok || hash(Buffer.from(await response.arrayBuffer()))!==hash(await readFile(name)))throw Error('Preview mismatch: '+name);
  console.log('SWORD_PREVIEW_MATCH: '+name);
}
console.log('SWORD_REVIEW_URL: '+new URL(review.entry,url));
console.log('FIXED_TEST_ALIAS: preserved; waiting for visual approval');
