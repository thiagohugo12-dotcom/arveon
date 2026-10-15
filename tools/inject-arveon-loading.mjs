// Brand Godot 4 Web export after export without rewriting engine bootstrap,
// progress lifecycle, canvas or existing Web save behavior.
import {readFile,writeFile,copyFile,mkdir,stat} from 'node:fs/promises';
import path from 'node:path';

const exportDir=path.resolve(process.argv[2]||'build/web');
const file=path.join(exportDir,'index.html');
const html=await readFile(file,'utf8');
for(const marker of ['id="status"','id="status-progress"','id="status-notice"','id="canvas"']) {
  if(!html.includes(marker))throw Error(`Godot HTML changed: missing ${marker}; do not publish`);
}
if(!html.includes('</head>')||!html.includes('</body>'))throw Error('Invalid Godot Web HTML');
if(html.includes('arveon-loader.css')||html.includes('arveon-loader.js'))throw Error('ARVEON loading injection already exists');
const branded=html.replace('</head>',`<link rel="icon" type="image/svg+xml" href="./arveon-icon.svg">
<link rel="stylesheet" href="./arveon-loader.css">
<script src="./arveon-loader.js" defer></script>
</head>`);
await writeFile(file,branded,'utf8');
const resources=[
 ['tools/arveon-loader.css','arveon-loader.css'],
 ['tools/arveon-loader.js','arveon-loader.js'],
 ['tools/arveon-icon.svg','arveon-icon.svg'],
 ['assets/loading/arveon-mobile.avif','arveon-mobile.avif'],
 ['assets/loading/arveon-desktop.avif','arveon-desktop.avif']
];
await mkdir(exportDir,{recursive:true});
for(const [source,dest] of resources)await copyFile(source,path.join(exportDir,dest));
for(const name of ['arveon-mobile.avif','arveon-desktop.avif']){
  const {size}=await stat(path.join(exportDir,name));
  if(size<1000||size>250000)throw Error(`Invalid optimized art ${name}: ${size} bytes`);
}
console.log('ARVEON_LOADER_READY: real Godot progress retained and responsive art installed');
