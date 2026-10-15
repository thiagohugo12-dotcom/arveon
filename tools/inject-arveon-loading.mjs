// Post-export presentation only: preserve Godot bootstrap, canvas and save code.
import {readFile,writeFile,mkdir,readdir,rm} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import path from 'node:path';
const root=path.resolve(process.argv[2]||'build/web');
const hash=b=>createHash('sha256').update(b).digest('hex');
let html=await readFile(path.join(root,'index.html'),'utf8');
for(const marker of ['id="status"','id="status-progress"','id="status-notice"','id="canvas"'])
  if(!html.includes(marker))throw Error('Godot shell missing '+marker);
if(!html.includes('</head>'))throw Error('Invalid Godot HTML');
html=html.replace(/<!-- ARVEON_LOADING_START -->[\s\S]*?<!-- ARVEON_LOADING_END -->\s*/g,'')
 .replace(/<(?:link|script)\b[^>]*(?:href|src)=["'][^"']*arveon-(?:loader[^"']*|icon\.svg)["'][^>]*>(?:<\/script>)?\s*/g,'');
for(const name of await readdir(root))
  if(/^arveon-(?:desktop|mobile|loader)(?:[.-][a-z0-9-]+)*\.(?:avif|png|webp|css|js)$/.test(name))await rm(path.join(root,name));
const approvals=JSON.parse(await readFile('assets/loading/approved-artwork.json','utf8'));
const folder='loading-artwork';await rm(path.join(root,folder),{recursive:true,force:true});await mkdir(path.join(root,folder),{recursive:true});
const manifest={version:'approved-20261015',desktop:null,mobile:null,resources:[]};
for(const [kind,width,height,original] of [['desktop',1536,864,'77010.png'],['mobile',864,1536,'77011.png']]){
  const bytes=await readFile('assets/loading/arveon-'+kind+'-approved.png');
  if(hash(bytes)!==approvals[kind].png_sha256)throw Error('Approved artwork checksum mismatch '+kind);
  if(bytes.subarray(0,8).toString('hex')!=='89504e470d0a1a0a'||bytes.readUInt32BE(16)!==width||bytes.readUInt32BE(20)!==height)throw Error('Wrong approved artwork '+kind);
  const sha256=hash(bytes),basename='arveon-'+kind+'-'+sha256.slice(0,16)+'.png';
  const file=folder+'/'+basename;await writeFile(path.join(root,file),bytes);
  manifest[kind]={file,sha256,width,height,original,size:bytes.length};
}
const style=await readFile('tools/arveon-loader.css','utf8');
let code=await readFile('tools/arveon-loader.js','utf8');
code=code.replace('__ARVEON_DESKTOP__',path.basename(manifest.desktop.file)).replace('__ARVEON_MOBILE__',path.basename(manifest.mobile.file));
for(const [kind,bytes] of [['css',Buffer.from(style)],['js',Buffer.from(code)]]){
  const sha256=hash(bytes),file=folder+'/arveon-loader-'+sha256.slice(0,16)+'.'+kind;
  await writeFile(path.join(root,file),bytes);manifest.resources.push({file,sha256,size:bytes.length});
}
const css=manifest.resources.find(x=>x.file.endsWith('.css')).file;
const js=manifest.resources.find(x=>x.file.endsWith('.js')).file;
const block='<!-- ARVEON_LOADING_START -->\n<link rel="icon" type="image/svg+xml" href="/arveon-icon.svg">\n<link rel="stylesheet" href="/'+css+'">\n<script src="/'+js+'" defer></script>\n<!-- ARVEON_LOADING_END -->\n';
await writeFile(path.join(root,'index.html'),html.replace('</head>',block+'</head>'));
await writeFile(path.join(root,'arveon-icon.svg'),await readFile('tools/arveon-icon.svg'));
await writeFile(path.join(root,'arveon-loading.json'),JSON.stringify(manifest,null,2)+'\n');
console.log('ARVEON_LOADER_READY: approved PNG bytes, native progress, whole composition, content-addressed assets');
