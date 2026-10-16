// Verify exactly the compiled Godot Web export behind the dedicated
// publicly reachable training alias, never the stable TESTE/PRODUÇÃO domains.
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
const base = 'https://grande-arvore-rpg-treino.vercel.app/';
const hash = buffer => createHash('sha256').update(buffer).digest('hex');
for (const name of ['index.html','index.pck']) {
  const expected = hash(await readFile(name));
  let valid = false;
  for (let attempt = 0; attempt < 3; attempt++) {
    const response = await fetch(new URL(name,base),{cache:'no-store',signal:AbortSignal.timeout(30000)});
    const bytes = Buffer.from(await response.arrayBuffer());
    if(response.ok && hash(bytes)===expected && (response.headers.get('cache-control')||'').includes('no-store')){
      valid = true;
      console.log('TRAINING_BUILD_MATCH: '+name+' '+expected);
      break;
    }
    await new Promise(resolve=>setTimeout(resolve,2000));
  }
  if(!valid) throw Error('Published training alias does not match tested Web artifact: '+name);
}
