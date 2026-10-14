// CI's visual-review branch never invokes the fixed TESTE alias publisher.
import {readFile,mkdtemp,unlink} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {execFile} from 'node:child_process';
import {promisify} from 'node:util';
import {tmpdir} from 'node:os';
import {join,dirname} from 'node:path';
const review=JSON.parse(await readFile(new URL('./sword-review.json',import.meta.url),'utf8'));
if(review.fixedTestAlias!==false || review.status!=='awaiting-visual-approval' || review.entry!=='amostra-espada/index.html')throw Error('Unexpected review policy; fixed alias remains blocked');
const url=new URL(process.env.PREVIEW_URL);
if(url.protocol!=='https:' || !url.hostname.endsWith('.vercel.app') || url.hostname==='grande-arvore-rpg-teste.vercel.app' || url.hostname==='grande-arvore-rpg.vercel.app')throw Error('Expected unique preview URL');
const hash=b=>createHash('sha256').update(b).digest('hex');
const temporary=await mkdtemp(join(tmpdir(),'sword-preview-'));
for(const name of [review.entry,'index.pck','sword-review.json']){
  const destination=join(temporary,name.replaceAll('/','-'));
  // Use CI's existing Vercel identity. No public alias/protection-setting changes.
  // CLI handles authentication internally; neither tokens nor headers are logged.
  try{
    const args=['--yes','vercel@62.7.0','curl',new URL(name,url).href,'--scope',process.env.VERCEL_ORG_ID,'--yes','--','--fail','--silent','--show-error','--max-time','60','--output',destination];
    const windows=process.platform==='win32';
    const npmCli=join(dirname(process.execPath),'node_modules','npm','bin','npx-cli.js');
    await promisify(execFile)(windows?process.execPath:'npx',windows?[npmCli,...args]:args,{timeout:90000});
  }catch{throw Error('Authenticated preview verification failed: '+name);}
  const actual=await readFile(destination);
  const expected=await readFile(name);
  await unlink(destination);
  if(name.endsWith('.html')){
    // Vercel appends its feedback toolbar to protected preview HTML. Accept only
    // that exact external suffix; every byte of the Godot shell must still match.
    const a=actual.toString('utf8'),e=expected.toString('utf8');
    const suffix=a.slice(e.length);
    if(!a.startsWith(e) || !/^(?:\n?<script async data-explicit-opt-in="true" data-deployment-id="dpl_[A-Za-z0-9]+" src="https:\/\/vercel\.live\/_next-live\/feedback\/feedback\.js"><\/script>)?\s*$/.test(suffix))throw Error('Preview HTML mismatch');
  }else if(hash(actual)!==hash(expected))throw Error('Preview mismatch: '+name);
  console.log('SWORD_PREVIEW_MATCH: '+name);
}
console.log('SWORD_REVIEW_URL: '+new URL(review.entry,url));
console.log('FIXED_TEST_ALIAS: preserved; waiting for visual approval');
