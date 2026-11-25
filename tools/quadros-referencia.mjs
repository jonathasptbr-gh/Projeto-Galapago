#!/usr/bin/env node
// Oráculo de quadros contra a ÚLTIMA PUBLICAÇÃO — sem PNG no git.
// A referência é o artefato `quadros` da última execução bem-sucedida do
// ci.yml em `main` disparada por push de commit `vX.Y.Z: …` (publicação).
// Ver docs/ORACULO.md.
//
//   node tools/quadros-referencia.mjs [pasta=quadros]   compara (o CI chama)
//   node tools/quadros-referencia.mjs --baixar          só baixa a referência
//   opções: --dest <dir> (padrão testes/baseline, fora do git) · --run <id>
//           (força um run) · --min <n> (quadros mínimos na pasta, padrão 50)
//
// Saída: 0 ok, aviso de diferença visual ou referência ausente · 1 quadros
// faltando (menos que --min, ou menos que a referência) · 2 uso.
// No CI escreve o resultado em $GITHUB_STEP_SUMMARY. O token (GITHUB_TOKEN no
// CI; cofre do harness aqui) nunca é impresso.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const REPO = process.env.GITHUB_REPOSITORY || 'jonathasptbr-gh/Projeto-Galapago';
const PUBLICACAO = /^v\d+\.\d+\.\d+:/;
const args = process.argv.slice(2);
const opt = (nome, padrao) => {
  const i = args.indexOf(nome);
  return i >= 0 && args[i + 1] ? args[i + 1] : padrao;
};
const comValor = new Set(['--dest', '--run', '--min']);
const posicionais = args.filter((a, i) => !a.startsWith('--') && !comValor.has(args[i - 1]));
const BAIXAR = args.includes('--baixar');
const PASTA = path.resolve(RAIZ, posicionais[0] || 'quadros');
const DEST = path.resolve(RAIZ, opt('--dest', 'testes/baseline'));
const RUN = opt('--run', '').replace(/\D/g, '');
const MIN = Number(opt('--min', '50'));
if (!Number.isFinite(MIN) || MIN < 0) { console.error('--min inválido'); process.exit(2); }
if (DEST === RAIZ || DEST === path.parse(DEST).root || DEST === PASTA) { console.error(`destino perigoso: ${DEST}`); process.exit(2); }

const linhas = [];
const diga = (texto) => { console.log(texto); linhas.push(texto); };
function resumo() {
  const arq = process.env.GITHUB_STEP_SUMMARY;
  if (arq) fs.appendFileSync(arq, ['### Oráculo de quadros', '', ...linhas, ''].join('\n') + '\n');
}

function token() {
  if (process.env.GITHUB_TOKEN) return process.env.GITHUB_TOKEN;
  if (process.env.GH_TOKEN) return process.env.GH_TOKEN;
  try {
    const y = fs.readFileSync(path.join(os.homedir(), '.dsh', '.credentials.yaml'), 'utf8');
    const m = y.match(/^\s+GITHUB_TOKEN:\s*["']?([^"'\s]+)/m);
    if (m) return m[1];
  } catch { /* cai para o arquivo antigo */ }
  try { return fs.readFileSync(path.join(os.homedir(), '.dsh-github', 'token'), 'utf8').trim(); } catch { return ''; }
}

const T = token();
const H = { 'User-Agent': 'galapago-oraculo', Accept: 'application/vnd.github+json', ...(T ? { Authorization: 'Bearer ' + T } : {}) };
async function api(caminho) {
  const r = await fetch(`https://api.github.com/repos/${REPO}/${caminho}`, { headers: H, signal: AbortSignal.timeout(60000) });
  if (!r.ok) throw new Error(`${caminho.split('?')[0]}: HTTP ${r.status}`);
  return r.json();
}

// Primeiro run de publicação (mais novo) cujo artefato `quadros` ainda existe.
async function acharReferencia() {
  const atual = process.env.GITHUB_RUN_ID || '';
  const candidatos = [];
  if (RUN) {
    candidatos.push(await api(`actions/runs/${RUN}`));
  } else {
    for (let pagina = 1; pagina <= 3 && candidatos.length < 10; pagina++) {
      const j = await api(`actions/workflows/ci.yml/runs?branch=main&event=push&status=success&per_page=100&page=${pagina}`);
      const runs = j.workflow_runs || [];
      for (const r of runs) {
        if (String(r.id) !== atual && PUBLICACAO.test(r.head_commit?.message || '')) candidatos.push(r);
      }
      if (runs.length < 100) break;
    }
  }
  for (const r of candidatos.slice(0, 10)) {
    const a = await api(`actions/runs/${r.id}/artifacts?per_page=100`);
    const art = (a.artifacts || []).find((x) => x.name === 'quadros' && !x.expired);
    if (art) return { run: r, art };
  }
  return null;
}

async function baixarZip(art, id) {
  const tmp = process.env.RUNNER_TEMP || path.join(os.homedir(), 'tmp');
  fs.mkdirSync(tmp, { recursive: true });
  const alvo = path.join(tmp, `galapago-referencia-${id}.zip`);
  let ultimo = null;
  for (let tentativa = 1; tentativa <= 2; tentativa++) {
    try {
      const b = await fetch(art.archive_download_url, { headers: H, signal: AbortSignal.timeout(180000) });
      if (!b.ok) throw new Error(`HTTP ${b.status}`);
      fs.writeFileSync(alvo, Buffer.from(await b.arrayBuffer()));
      return alvo;
    } catch (e) {
      ultimo = e;
      console.warn(`download tentativa ${tentativa}/2 falhou: ${e.message || e}`);
    }
  }
  throw new Error(`download do artefato falhou 2× (${ultimo?.message || ultimo})`);
}

function pngsDe(dir) {
  const achados = [];
  const anda = (d) => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) anda(p);
      else if (/^q.*\.png$/.test(e.name)) achados.push(p);
    }
  };
  anda(dir);
  return achados;
}

// Extrai num temporário e copia só os q*.png para o destino (que perde antes
// os q*.png antigos — nada além deles é apagado).
function aplicar(zip) {
  const base = process.env.RUNNER_TEMP || path.join(os.homedir(), 'tmp');
  const dir = fs.mkdtempSync(path.join(base, 'referencia-'));
  try {
    execFileSync('python3', ['-m', 'zipfile', '-e', zip, dir], { stdio: 'inherit' });
    const pngs = pngsDe(dir);
    fs.mkdirSync(DEST, { recursive: true });
    // Dentro do projeto, o Godot não pode importar a referência como recurso.
    if (!path.relative(RAIZ, DEST).startsWith('..')) fs.writeFileSync(path.join(DEST, '.gdignore'), '');
    for (const velho of fs.readdirSync(DEST).filter((f) => /^q.*\.png$/.test(f))) fs.rmSync(path.join(DEST, velho));
    for (const p of pngs) fs.copyFileSync(p, path.join(DEST, path.basename(p)));
    return pngs.length;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
    fs.rmSync(zip, { force: true });
  }
}

function contar(dir) {
  try { return fs.readdirSync(dir).filter((f) => /^q.*\.png$/.test(f)).length; } catch { return 0; }
}

async function principal() {
  if (!BAIXAR) {
    const n = contar(PASTA);
    if (n < MIN) {
      diga(`REPROVADO: só ${n} quadros em ${path.relative(RAIZ, PASTA) || PASTA} (mínimo ${MIN}).`);
      return 1;
    }
  }
  let ref;
  try {
    ref = await acharReferencia();
  } catch (e) {
    diga(`AVISO: não consegui consultar a referência (${e.message}); comparação pulada.`);
    return BAIXAR ? 2 : 0;
  }
  if (!ref) {
    diga('AVISO: nenhuma publicação (`vX.Y.Z:`) com artefato `quadros` válido; comparação pulada.');
    return BAIXAR ? 2 : 0;
  }
  const { run, art } = ref;
  const titulo = (run.head_commit?.message || '').split('\n')[0];
  diga(`Referência: [CI #${run.run_number}](${run.html_url}) — \`${run.head_sha.slice(0, 7)}\` ${titulo}`);
  let n;
  try {
    n = aplicar(await baixarZip(art, run.id));
  } catch (e) {
    diga(`AVISO: referência indisponível (${e.message}); comparação pulada.`);
    return BAIXAR ? 2 : 0;
  }
  if (BAIXAR) {
    diga(`${n} quadros da referência em ${path.relative(RAIZ, DEST) || DEST}`);
    return 0;
  }
  const r = spawnSync(process.execPath, [path.join(RAIZ, 'tools', 'quadros-diff.mjs'), PASTA, '--baseline', DEST, '--aviso'], { encoding: 'utf8' });
  const saida = `${r.stdout || ''}${r.stderr || ''}`.trim();
  const ultima = saida.split('\n').pop() || '';
  if (r.status === 0) diga(/^AVISO/.test(ultima) ? `Resultado: ${ultima}` : `Resultado: OK — ${ultima}`);
  else if (r.status === 1) diga(`Resultado: ${ultima}`);
  else diga(`AVISO: o diff não conseguiu comparar (saída ${r.status}); ver abaixo.`);
  linhas.push('', '<details><summary>saída do quadros-diff</summary>', '', '```', saida, '```', '', '</details>');
  console.log(saida);
  return r.status === 1 ? 1 : 0;
}

let codigo;
try {
  codigo = await principal();
} catch (e) {
  diga(`AVISO: falha inesperada na comparação (${e.message || e}); comparação pulada.`);
  codigo = 0;
}
resumo();
process.exitCode = codigo;
