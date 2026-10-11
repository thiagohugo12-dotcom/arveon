// Verify the public fixed TESTE alias serves exactly the tested export.
// No credentials or production requests; build hashes are the source of truth.
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const base = 'https://grande-arvore-rpg-teste.vercel.app/';
const sha = value => createHash('sha256').update(value).digest('hex');
for (const name of ['index.html','index.pck']) {
  const expected = sha(await readFile(name));
  let matched = false;
  for (let attempt = 0; attempt < 3; attempt++) {
    const response = await fetch(new URL(name,base),{cache:'no-store',signal:AbortSignal.timeout(30000)});
    const actual = sha(Buffer.from(await response.arrayBuffer()));
    if (response.ok && actual === expected && /no-store/.test(response.headers.get('cache-control') || '')) {
      matched = true;
      console.log(`TESTE_BUILD_MATCH: ${name} ${actual}`);
      break;
    }
    await new Promise(resolve=>setTimeout(resolve,2000));
  }
  if (!matched) throw Error(`Fixed TESTE alias does not serve the tested ${name} with cache disabled`);
}
