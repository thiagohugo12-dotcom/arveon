// Deployment-scoped, expiring review access. Never updates a public/fixed alias
// or project-wide protection settings. Tokens/cookies remain in memory only.
import {readFile,mkdtemp,writeFile,unlink} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {execFile} from 'node:child_process';
import {promisify} from 'node:util';
import {tmpdir} from 'node:os';
import {join,dirname} from 'node:path';
const review=JSON.parse(await readFile(new URL('./bow-review.json',import.meta.url),'utf8'));
if(review.fixedTestAlias!==false || review.status!=='awaiting-visual-approval' || review.entry!=='amostra-arco/index.html')throw Error('Unexpected review policy; fixed alias remains blocked');
const url=new URL(process.env.PREVIEW_URL);
if(url.protocol!=='https:' || !url.hostname.endsWith('.vercel.app') || url.hostname==='arveon-teste.vercel.app' || url.hostname==='arveon.vercel.app')throw Error('Expected unique preview URL');
const team=process.env.VERCEL_ORG_ID,project=process.env.VERCEL_PROJECT_ID;
if(team!=='team_6XRzZ5HN4AOw2hWyIpf8McMU' || project!=='prj_gYKlx91MiswTmwj2PLiN5liQD0B7')throw Error('Unexpected review owner/project');
async function api(path,method='GET',body){
  if(process.env.VERCEL_TOKEN){
    const endpoint=new URL(path,'https://api.vercel.com');endpoint.searchParams.set('teamId',team);
    const response=await fetch(endpoint,{method,headers:{Authorization:`Bearer ${process.env.VERCEL_TOKEN}`,'Content-Type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(30000)});
    if(!response.ok)throw Error(`Review API ${method}: HTTP ${response.status}`);
    return response.json();
  }
  // Local verification uses the CLI's own identity, never reads stored secrets.
  const windows=process.platform==='win32';
  const args=['--yes','vercel@62.7.0','api',path,'--scope',team,'--method',method];
  let input;
  if(body!==undefined){
    input=join(await mkdtemp(join(tmpdir(),'bow-review-')),'request.json');
    await writeFile(input,JSON.stringify(body));args.push('--input',input);
  }
  try{
    const command=windows?process.execPath:'npx';
    const actualArgs=windows?[join(dirname(process.execPath),'node_modules','npm','bin','npx-cli.js'),...args]:args;
    const result=await promisify(execFile)(command,actualArgs,{timeout:90000});
    return JSON.parse(result.stdout);
  }finally{if(input)await unlink(input);}
}
const deployment=await api(`/v13/deployments/${url.hostname}`);
if(deployment.projectId!==project || deployment.target==='production' || deployment.readyState!=='READY')throw Error('Review must be a READY Preview in the expected project');
if(process.env.PREVIEW_COMMIT_SHA && deployment.meta?.githubCommitSha!==process.env.PREVIEW_COMMIT_SHA)throw Error('Preview commit mismatch');
// Same deployment-specific sharing mechanism as Vercel's temporary review links.
// The CI identity need not read/create a project-wide automation bypass token.
let access;
if(process.env.BOW_REVIEW_ACCESS_URL){
  // Reuse an already issued review link during local verification.
  access=new URL(process.env.BOW_REVIEW_ACCESS_URL);
  if(access.origin!==url.origin || access.pathname!=='/'+review.entry || !access.searchParams.has('_vercel_share'))throw Error('Review access URL mismatch');
}else{
  const sharing=await api(`/aliases/${deployment.id}/protection-bypass`,'PATCH',{ttl:82800});
  const entry=Object.entries(sharing.protectionBypass||{}).find(([,v])=>v.scope==='shareable-link' && v.expires>Date.now()/1000);
  if(!entry)throw Error('Expiring deployment review access was not returned');
  access=new URL(review.entry,url);access.searchParams.set('_vercel_share',entry[0]);
}
// Intended user deliverable, expiring after 23h. Never print API tokens/cookies.
console.log('BOW_REVIEW_SHARE_URL: '+access);
const cookies=new Map();
async function protectedGet(request){
  for(let hop=0;hop<8;hop++){
    const sso=request.origin==='https://vercel.com' && request.pathname==='/sso-api';
    if(request.origin!==url.origin && !sso)throw Error('Unexpected review authentication origin/path: '+request.origin+request.pathname);
    // Vercel's documented sharing flow uses its SSO endpoint before returning.
    // Keep a separate cookie jar per origin; never forward deployment cookies.
    const jar=cookies.get(request.origin)||new Map();cookies.set(request.origin,jar);
    const response=await fetch(request,{redirect:'manual',cache:'no-store',headers:jar.size?{Cookie:[...jar].map(([k,v])=>`${k}=${v}`).join('; ')}:{},signal:AbortSignal.timeout(60000)});
    for(const header of response.headers.getSetCookie()){
      const pair=header.split(';',1)[0],at=pair.indexOf('=');
      if(at>0)jar.set(pair.slice(0,at),pair.slice(at+1));
    }
    if([301,302,303,307,308].includes(response.status)){
      request=new URL(response.headers.get('location'),request);continue;
    }
    if(!response.ok)throw Error(`Protected review returned HTTP ${response.status}`);
    return Buffer.from(await response.arrayBuffer());
  }
  throw Error('Review authentication redirect limit');
}
const hash=b=>createHash('sha256').update(b).digest('hex');
for(const name of [review.entry,'index.pck','bow-review.json']){
  const actual=await protectedGet(name===review.entry?access:new URL(name,url));
  const expected=await readFile(name);
  if(name.endsWith('.html')){
    // Only Vercel's exact external feedback suffix may differ from the shell.
    const a=actual.toString('utf8'),e=expected.toString('utf8'),suffix=a.slice(e.length);
    if(!a.startsWith(e) || !/^(?:\n?<script async data-explicit-opt-in="true" data-deployment-id="dpl_[A-Za-z0-9]+" src="https:\/\/vercel\.live\/_next-live\/feedback\/feedback\.js"><\/script>)?\s*$/.test(suffix))throw Error('Preview HTML mismatch');
  }else if(hash(actual)!==hash(expected))throw Error('Preview mismatch: '+name);
  console.log('BOW_PREVIEW_MATCH: '+name);
}
console.log('BOW_REVIEW_URL: '+new URL(review.entry,url));
console.log('FIXED_TEST_ALIAS: preserved; waiting for visual approval');

for(const [name,expected] of Object.entries(review.fixedTestSha256||{})){
  if(!['index.html','index.pck'].includes(name)||!/^[0-9a-f]{64}$/.test(expected))throw Error('Invalid fixed TESTE baseline');
  const response=await fetch('https://arveon-teste.vercel.app/'+name,{cache:'no-store',signal:AbortSignal.timeout(30000)});
  if(!response.ok||hash(Buffer.from(await response.arrayBuffer()))!==expected)throw Error('Fixed TESTE changed during bow review: '+name);
  console.log('BOW_FIXED_TEST_PRESERVED: '+name);
}
if(Object.keys(review.fixedTestSha256||{}).length!==2)throw Error('Missing fixed TESTE baseline');
