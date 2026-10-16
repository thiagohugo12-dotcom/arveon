// Dedicated, public QA alias for the isolated training branch only.
// The stable TESTE alias and production alias are NEVER read or mutated.
const { VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID, PREVIEW_URL, PREVIEW_BRANCH } = process.env;
const ALIAS = 'grande-arvore-rpg-treino.vercel.app';
if (!VERCEL_TOKEN || !VERCEL_ORG_ID || !VERCEL_PROJECT_ID) throw Error('Missing Vercel CI configuration');
if (PREVIEW_BRANCH !== 'feat/modo-treino-livre-20261015') throw Error('Training alias cannot be used from another branch');
const preview = new URL(PREVIEW_URL);
if (preview.protocol !== 'https:' || preview.origin !== PREVIEW_URL || !preview.hostname.endsWith('.vercel.app')) {
  throw Error('Expected canonical HTTPS Vercel Preview');
}
async function api(path, method='GET', body, missing=false) {
  const url = new URL(path,'https://api.vercel.com');
  url.searchParams.set('teamId', VERCEL_ORG_ID);
  const response = await fetch(url, {
    method,
    headers: { Authorization: `Bearer ${VERCEL_TOKEN}`, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(30000),
  });
  if(missing && response.status===404) return null;
  if(!response.ok) throw Error(`Vercel ${method} ${path} HTTP ${response.status}`);
  return response.json();
}
const deploy = await api(`/v13/deployments/${encodeURIComponent(preview.hostname)}`);
if(deploy.projectId !== VERCEL_PROJECT_ID || deploy.target === 'production' || deploy.readyState !== 'READY'){
  throw Error('Only tested READY Preview deployment of the correct project can receive training alias');
}
const prior = await api(`/v4/aliases/${ALIAS}`,'GET',undefined,true);
if(prior && prior.projectId !== VERCEL_PROJECT_ID) throw Error('Training alias belongs to another project');
const attached = await api(`/v2/deployments/${deploy.id}/aliases`,'POST',{alias:ALIAS});
if(attached.alias !== ALIAS || !attached.uid) throw Error('Vercel did not assign training alias');
const current = await api(`/v4/aliases/${ALIAS}`);
if(current.deploymentId !== deploy.id) throw Error('Training alias is not pointing to this validated build');
if(current.protectionBypass?.['*']?.scope !== 'alias-protection-override') {
  await api(`/aliases/${attached.uid}/protection-bypass`,'PATCH',{
    override:{action:'create',scope:'alias-protection-override'}
  });
}
const confirmed = await api(`/v4/aliases/${ALIAS}`);
if(confirmed.deploymentId !== deploy.id || confirmed.protectionBypass?.['*']?.scope !== 'alias-protection-override'){
  throw Error('Training alias is not publicly testable or points to a stale build');
}
console.log('TRAINING_ALIAS_READY: https://'+ALIAS);
console.log('TRAINING_ALIAS_SHA: '+process.env.PREVIEW_COMMIT_SHA);
