#!/usr/bin/env node
// Baseline dos quadros gerado pelo CI — para o lote visível entrar em UM
// commit só. O baseline é do llvmpipe (x86_64); neste celular o driver é
// softpipe, então o baseline NÃO se gera aqui: dispara-se o job `baseline`
// (workflow_dispatch) no branch do lote e este script aplica o artifact.
//
//   node tools/quadros-baseline.mjs --run 123456789        (run do Actions)
//   node tools/quadros-baseline.mjs --url https://github.com/.../actions/runs/123
//   node tools/quadros-baseline.mjs --zip ~/tmp/baseline.zip
//   node tools/quadros-baseline.mjs --pasta ~/tmp/quadros   (já extraído)
//   (--dest troca o destino; o padrão é testes/baseline)
//
// Depois: `git add testes/baseline` e o MESMO commit leva a mudança visível.
// Ver docs/ORACULO.md.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const REPO = process.env.GITHUB_REPOSITORY || 'jonathasptbr-gh/Projeto-Galapago';
const args = process.argv.slice(2);
const opt = (nome, padrao) => {
  const i = args.indexOf(nome);
  return i >= 0 && args[i + 1] ? args[i + 1] : padrao;
};
const DEST = opt('--dest', 'testes/baseline');
const run = opt('--run', '');
const url = opt('--url', '');
const zip = opt('--zip', '');
const pasta = opt('--pasta', '');
const min = Number(opt('--min', '50'));

function token() {
  try {
    const y = fs.readFileSync(path.join(os.homedir(), '.dsh', '.credentials.yaml'), 'utf8');
    const m = y.match(/^\s+GITHUB_TOKEN:\s*["']?([^"'\s]+)/m);
    if (m) return m[1];
  } catch { /* cai para o arquivo antigo */ }
  return fs.readFileSync(path.join(os.homedir(), '.dsh-github', 'token'), 'utf8').trim();
}

const idDoRun = () => {
  if (run) return run.replace(/\D/g, '');
  if (url) return (url.match(/runs\/(\d+)/) || [])[1];
  return '';
};

async function baixar() {
  const id = idDoRun();
  if (!id) throw new Error('informe --run, --url, --zip ou --pasta');
  const h = { Authorization: 'Bearer ' + token(), 'User-Agent': 'galapago', Accept: 'application/vnd.github+json' };
  const r = await fetch(`https://api.github.com/repos/${REPO}/actions/runs/${id}/artifacts`, { headers: h, signal: AbortSignal.timeout(60000) });
  if (!r.ok) throw new Error(`artifacts do run ${id}: ${r.status}`);
  const j = await r.json();
  const art = (j.artifacts || []).find((a) => a.name === 'baseline') || (j.artifacts || []).find((a) => a.name === 'quadros');
  if (!art) throw new Error(`run ${id} sem artifact 'baseline' (tem: ${(j.artifacts || []).map((a) => a.name).join(', ') || 'nenhum'})`);
  if (art.expired) throw new Error(`artifact '${art.name}' expirado — dispare o job \`baseline\` de novo`);
  // artifacts exigem o Accept do GitHub; ele redireciona para o blob assinado.
  // O blob às vezes engasga no meio do corpo (rede do celular): duas tentativas.
  const tmp = path.join(os.homedir(), 'tmp');
  fs.mkdirSync(tmp, { recursive: true });
  const alvo = path.join(tmp, `galapago-baseline-${id}.zip`);
  let ultimo = null;
  for (let tentativa = 1; tentativa <= 2; tentativa++) {
    try {
      const b = await fetch(art.archive_download_url, { headers: { ...h, Accept: 'application/vnd.github+json' }, signal: AbortSignal.timeout(120000) });
      if (!b.ok) throw new Error(`HTTP ${b.status}`);
      fs.writeFileSync(alvo, Buffer.from(await b.arrayBuffer()));
      console.log(`artifact '${art.name}' do run ${id} → ${alvo} (${art.size_in_bytes} bytes)`);
      return alvo;
    } catch (e) {
      ultimo = e;
      console.warn(`download tentativa ${tentativa}/2 falhou: ${e.name || ''} ${e.message || ''}`.trim());
    }
  }
  throw new Error(`download do artifact falhou 2× (${ultimo?.name || ultimo?.message}). Tente de novo; se persistir, baixe o zip pelo navegador (Actions → run → Artifacts) e use --zip <arquivo>.`);
}

function extrair(arquivo) {
  const dir = fs.mkdtempSync(path.join(os.homedir(), 'tmp', 'baseline-'));
  execFileSync('python3', ['-m', 'zipfile', '-e', arquivo, dir], { stdio: 'inherit' });
  return dir;
}

function quadrosDe(dir) {
  const achados = [];
  const anda = (d) => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) anda(p);
      else if (/^q\d{8}\.png$/.test(e.name)) achados.push(p);
    }
  };
  anda(dir);
  return achados.sort((a, b) => path.basename(a).localeCompare(path.basename(b)));
}

let fonte;
try {
  fonte = pasta || extrair(zip || (await baixar()));
} catch (e) {
  console.error(`quadros-baseline: ${e.message || e}`);
  process.exit(1);
}
const quadros = quadrosDe(fonte);
if (quadros.length < min) {
  console.error(`só ${quadros.length} quadros (< ${min}) em ${fonte} — baseline não tocado`);
  process.exit(1);
}
fs.mkdirSync(DEST, { recursive: true });
const antigos = new Set(fs.readdirSync(DEST).filter((f) => /^q\d{8}\.png$/.test(f)));
let novos = 0;
for (const q of quadros) {
  const nome = path.basename(q);
  fs.copyFileSync(q, path.join(DEST, nome));
  antigos.delete(nome);
  novos++;
}
for (const velho of antigos) fs.unlinkSync(path.join(DEST, velho));
console.log(`${novos} quadros → ${DEST} (removidos ${antigos.size} que não existem mais)`);
console.log('próximo: git add ' + DEST + ' — e o MESMO commit leva a mudança visível');
