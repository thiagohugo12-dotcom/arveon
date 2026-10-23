// Run only after a tested Preview is READY. Never change production aliases.
import { appendFileSync } from 'node:fs';

const { VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID, PREVIEW_URL, TEST_ALIAS } = process.env;
if (!VERCEL_TOKEN || !VERCEL_ORG_ID || !VERCEL_PROJECT_ID) throw new Error('Missing Vercel CI configuration');
if (TEST_ALIAS !== 'arveon-teste.vercel.app') throw new Error('Unexpected test alias');
const preview = new URL(PREVIEW_URL);
if (preview.protocol !== 'https:' || preview.origin !== PREVIEW_URL || !preview.hostname.endsWith('.vercel.app')) {
  throw new Error('Invalid Preview URL');
}

async function api(path, method = 'GET', body, allowMissing = false) {
  const url = new URL(path, 'https://api.vercel.com');
  url.searchParams.set('teamId', VERCEL_ORG_ID);
  const response = await fetch(url, {
    method,
    headers: { Authorization: `Bearer ${VERCEL_TOKEN}`, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(30_000),
  });
  if (allowMissing && response.status === 404) return null;
  if (!response.ok) throw new Error(`Vercel ${method} ${path}: HTTP ${response.status}`);
  return response.json();
}

const deployment = await api(`/v13/deployments/${encodeURIComponent(preview.hostname)}`);
if (deployment.projectId !== VERCEL_PROJECT_ID || deployment.target === 'production' || deployment.readyState !== 'READY') {
  throw new Error('Alias requires a READY Preview in the expected project');
}
const existing = await api(`/v4/aliases/${TEST_ALIAS}`, 'GET', undefined, true);
if (existing && existing.projectId !== VERCEL_PROJECT_ID) throw new Error('Test alias belongs to another project');
const alias = await api(`/v2/deployments/${deployment.id}/aliases`, 'POST', { alias: TEST_ALIAS });
if (alias.alias !== TEST_ALIAS || !alias.uid) throw new Error('Alias assignment was not confirmed');

// A fixed alias retains its protection override when reassigned. Creating it twice returns HTTP 400.
const assigned = await api(`/v4/aliases/${TEST_ALIAS}`);
if (assigned.deploymentId !== deployment.id) throw new Error('Test alias does not point to the tested build');
if (assigned.protectionBypass?.['*']?.scope !== 'alias-protection-override') {
  await api(`/aliases/${alias.uid}/protection-bypass`, 'PATCH', {
    override: { action: 'create', scope: 'alias-protection-override' },
  });
}
const confirmed = await api(`/v4/aliases/${TEST_ALIAS}`);
if (confirmed.deploymentId !== deployment.id || confirmed.protectionBypass?.['*']?.scope !== 'alias-protection-override') {
  throw new Error('Test alias is not assigned or lacks its public test override');
}
console.log(`TESTE: https://${TEST_ALIAS}`);
console.log(`Preview commit: ${process.env.PREVIEW_COMMIT_SHA}`);
if (process.env.GITHUB_STEP_SUMMARY) {
  appendFileSync(process.env.GITHUB_STEP_SUMMARY,
    `\n[TESTE — endereço fixo](https://${TEST_ALIAS})\n\n[Build desta execução](${PREVIEW_URL})\n`);
}
