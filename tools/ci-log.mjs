#!/usr/bin/env node
// Mostra os jobs/passos de um run do CI e o fim do log dos jobs que falharam.
// Uso: node tools/ci-log.mjs [run_id=último] [linhas=60]
import fs from 'node:fs';
import path from 'node:path';

const REPO = 'jonathasptbr-gh/Projeto-Galapago';
function token() {
  try {
    const y = fs.readFileSync(path.join(process.env.HOME, '.dsh', '.credentials.yaml'), 'utf8');
    const m = y.match(/^\s+GITHUB_TOKEN:\s*["']?([^"'\s]+)/m);
    if (m) return m[1];
  } catch { /* fallback */ }
  return fs.readFileSync(path.join(process.env.HOME, '.dsh-github', 'token'), 'utf8').trim();
}
const h = { Authorization: 'Bearer ' + token(), 'User-Agent': 'galapago', Accept: 'application/vnd.github+json' };
const api = async (u) => (await fetch(`https://api.github.com/repos/${REPO}/${u}`, { headers: h })).json();

let run = process.argv[2];
const linhas = Number(process.argv[3] || 60);
if (!run) run = (await api('actions/runs?per_page=1')).workflow_runs[0].id;
const { jobs } = await api(`actions/runs/${run}/jobs`);
for (const j of jobs) {
  console.log(`== job ${j.name}: ${j.status}/${j.conclusion}`);
  for (const s of j.steps || []) if (s.conclusion !== 'success' && s.conclusion !== 'skipped') console.log(`   passo ${s.number} "${s.name}": ${s.conclusion}`);
  if (j.conclusion === 'failure') {
    const r = await fetch(`https://api.github.com/repos/${REPO}/actions/jobs/${j.id}/logs`, { headers: h });
    const t = (await r.text()).split('\n').map((l) => l.replace(/^\S+Z /, ''));
    console.log(t.slice(-linhas).join('\n'));
  }
}
