#!/usr/bin/env node
// Preview do lote para o celular. Duas metades:
//   --site       monta `_site/` (página + GIF + quadros-chave) para o Pages
//   --comentar   comenta no commit/PR com o link e as imagens inline
//   --dry        ensaio: corpo do comentário + site em ~/tmp, sem API
//
// O Pages serve `https://<owner>.github.io/<repo>/`; os arquivos ficam em
// `_site/<run>/` (nome único por run) para o cache de imagem não servir lote
// velho. Ver docs/BUILD.md ("Preview do lote").
//
// Variáveis: GH_TOKEN, GITHUB_REPOSITORY, GITHUB_SHA, GITHUB_RUN_ID, PR_NUMBER,
//            PREVIEW_URL, PREVIEW_TAG (ensaio local).
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const REPO = process.env.GITHUB_REPOSITORY || 'jonathasptbr-gh/Projeto-Galapago';
const [OWNER, NOME] = REPO.split('/');
const SHA = process.env.GITHUB_SHA || '';
const RUN = process.env.GITHUB_RUN_ID || 'local';
const PR = (process.env.PR_NUMBER || '').trim();
const PAGINA = (process.env.PREVIEW_URL || `https://${OWNER}.github.io/${NOME}/`).replace(/\/?$/, '/');
const MARCA = '<!-- galapago-preview -->';
const DRY = process.argv.includes('--dry');
const SO_SITE = process.argv.includes('--site');
const SO_COMENTAR = process.argv.includes('--comentar');
const dirQuadros = (() => {
  const i = process.argv.indexOf('--quadros');
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : 'quadros';
})();
const dirSite = DRY
  ? path.join(os.homedir(), 'tmp', 'preview-site')
  : (() => { const i = process.argv.indexOf('--site-dir'); return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : '_site'; })();

function cofre() {
  try {
    const y = fs.readFileSync(path.join(os.homedir(), '.dsh', '.credentials.yaml'), 'utf8');
    const m = y.match(/GITHUB_TOKEN:\s*['"]?([^'"\s]+)/);
    if (m) return m[1];
  } catch { /* cai para o arquivo antigo */ }
  try { return fs.readFileSync(path.join(os.homedir(), '.dsh-github', 'token'), 'utf8').trim(); } catch { return ''; }
}
const TOKEN = process.env.GH_TOKEN || process.env.GITHUB_TOKEN || cofre();

const versao = (() => {
  try {
    return (fs.readFileSync('docs/HISTORICO.md', 'utf8').match(/^## (v\d+\.\d+\.\d+)/m) || [])[1] || 'lote';
  } catch { return 'lote'; }
})();
const git = (args, padrao = '') => {
  try { return execFileSync('git', args, { encoding: 'utf8' }).trim(); } catch { return padrao; }
};
const assunto = git(['log', '-1', '--format=%s'], `lote ${RUN}`);
const resumo = git(['diff', '--shortstat', 'HEAD^', 'HEAD'], '');
const tocados = git(['diff', '--name-only', 'HEAD^', 'HEAD'], '').split('\n').filter(Boolean);

let todos = [];
try {
  todos = fs.readdirSync(dirQuadros).filter((f) => /^q\d{8}\.png$/.test(f)).sort();
} catch { /* sem quadros: tratado abaixo */ }
const escolhas = todos.length ? [...new Set([todos[0], todos[Math.floor(todos.length / 2)], todos[todos.length - 1]])] : [];

function gif() {
  if (todos.length < 2) return '';
  const saida = path.join(dirSite, RUN, 'lote.gif');
  fs.mkdirSync(path.dirname(saida), { recursive: true });
  const py = `
import sys, os
from PIL import Image
d, out = sys.argv[1], sys.argv[2]
fs = sorted(f for f in os.listdir(d) if f.startswith('q') and f.endswith('.png'))
passo = max(1, len(fs) // 40)
ims = []
for f in fs[::passo]:
    im = Image.open(os.path.join(d, f)).convert('RGB')
    w = 320
    im = im.resize((w, max(1, round(im.height * w / im.width))), Image.LANCZOS)
    ims.append(im)
ims[0].save(out, save_all=True, append_images=ims[1:], duration=66, loop=0, optimize=True)
print(out)
`;
  try {
    execFileSync('python3', ['-c', py, dirQuadros, saida], { stdio: 'pipe' });
    return fs.statSync(saida).size > 0 ? true : false;
  } catch {
    console.warn('preview: GIF não gerado (Pillow ausente?) — seguindo sem ele');
    return false;
  }
}

const esc = (t) => String(t).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

function montarSite() {
  if (todos.length === 0) {
    console.warn(`preview: nenhum quadro em ${dirQuadros} — site não montado`);
    return false;
  }
  const destino = path.join(dirSite, RUN);
  fs.mkdirSync(destino, { recursive: true });
  for (const nome of escolhas) fs.copyFileSync(path.join(dirQuadros, nome), path.join(destino, nome));
  const temGif = gif();
  const arquivos = tocados.length
    ? tocados.slice(0, 12).map((f) => `<li><code>${esc(f)}</code></li>`).join('')
    : '<li>(sem diff — primeiro push?)</li>';
  const html = `<!doctype html>
<html lang="pt-BR"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(versao)} — ${esc(assunto)}</title>
<style>
  :root { color-scheme: dark; }
  body { margin:0; padding:16px; background:#12141a; color:#e8e8ee; font:15px/1.45 system-ui,sans-serif; }
  h1 { font-size:18px; margin:0 0 4px; } h2 { font-size:13px; margin:22px 0 6px; color:#9aa0b0; text-transform:uppercase; letter-spacing:.04em; }
  .meta { color:#9aa0b0; font-size:13px; } a { color:#7cc4ff; }
  img { display:block; width:100%; max-width:420px; height:auto; border-radius:8px; margin:0 auto 10px; background:#000; }
  ul { padding-left:18px; margin:6px 0; } code { font-size:12px; color:#c8cdd9; }
  .caixa { background:#1b1e26; border:1px solid #2a2f3a; border-radius:10px; padding:12px; margin:14px 0; }
  .ok { color:#7ddc9a; font-weight:600; }
</style></head><body>
<h1>${esc(versao)} — ${esc(assunto)}</h1>
<div class="meta">${esc(SHA.slice(0, 7))} · run ${esc(RUN)} · ${esc(new Date().toISOString().slice(0, 16).replace('T', ' '))} UTC</div>
${temGif ? `<h2>Movimento</h2><img src="${RUN}/lote.gif" alt="GIF do lote">` : ''}
<h2>Quadros-chave</h2>
${escolhas.map((n) => `<img src="${RUN}/${n}" alt="${n}">`).join('\n')}
<div class="caixa">
  <div><strong>Diff:</strong> ${esc(resumo || 'sem resumo')}</div>
  <h2>Arquivos</h2><ul>${arquivos}</ul>
</div>
<div class="caixa">
  <p class="ok">Aceite: preview vermelho? Recusar dizendo o quadro e o que está errado.</p>
  <p><a href="https://github.com/${REPO}/actions/runs/${RUN}">run do CI</a> ·
     <a href="https://github.com/${REPO}/releases/download/dev/projeto-galapago-dev.apk">APK de teste</a> ·
     <a href="https://github.com/${REPO}/blob/main/docs/ROLLBACK.md">rollback</a> ·
     <a href="https://github.com/${REPO}/commit/${SHA}">commit</a></p>
</div>
</body></html>`;
  fs.writeFileSync(path.join(dirSite, 'index.html'), html);
  console.log(`site: ${dirSite} (${escolhas.length} quadros, GIF ${temGif ? 'ok' : 'ausente'}, ${todos.length} quadros no run)`);
  return true;
}

function corpo() {
  const img = (nome) => `![quadro](${PAGINA}${RUN}/${nome})`;
  return `${MARCA}
## ${versao} — ${assunto}

**[Abrir o preview no celular](${PAGINA})** — GIF e quadros-chave, uma página só.

${escolhas.map(img).join(' ')}

${resumo || 'sem resumo de diff'} · ${tocados.length} arquivo(s)

- CI: [run ${RUN}](https://github.com/${REPO}/actions/runs/${RUN})
- APK de teste: [projeto-galapago-dev.apk](https://github.com/${REPO}/releases/download/dev/projeto-galapago-dev.apk)
- Rollback: [docs/ROLLBACK.md](https://github.com/${REPO}/blob/main/docs/ROLLBACK.md)

**Aceite:** página com GIF + quadros + diff resumido. Aprovar = seguir; recusar = dizer o quadro e o que está errado.`;
}

async function api(caminho, opcoes = {}, tentar = true) {
  const r = await fetch(`https://api.github.com${caminho}`, {
    ...opcoes,
    headers: {
      Authorization: 'Bearer ' + TOKEN,
      'User-Agent': 'galapago-preview',
      Accept: 'application/vnd.github+json',
      ...(opcoes.headers || {}),
    },
  });
  if (!r.ok && tentar) throw new Error(`${opcoes.method || 'GET'} ${caminho}: ${r.status} ${await r.text()}`);
  return r;
}

async function comentar(texto) {
  if (!TOKEN) throw new Error('sem GH_TOKEN (e sem cofre local)');
  if (!SHA) throw new Error('sem GITHUB_SHA');
  const alvo = PR ? `/repos/${REPO}/issues/${PR}/comments` : `/repos/${REPO}/commits/${SHA}/comments`;
  const lista = await (await api(alvo + '?per_page=100')).json();
  const meu = (Array.isArray(lista) ? lista : []).find((c) => (c.body || '').includes(MARCA));
  const editar = PR ? `/repos/${REPO}/issues/comments/` : `/repos/${REPO}/comments/`;
  if (meu) {
    await api(editar + meu.id, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ body: texto }) });
    return 'comentário atualizado';
  }
  await api(alvo, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ body: texto }) });
  return 'comentário criado';
}

if (DRY) {
  fs.mkdirSync(dirSite, { recursive: true });
  if (todos.length) montarSite();
  const p = path.join(os.homedir(), 'tmp', 'preview.md');
  fs.writeFileSync(p, corpo());
  console.log(`ensaio: ${todos.length} quadros, ${escolhas.length} escolhidos · corpo em ${p}`);
  process.exit(0);
}

if (SO_SITE || !SO_COMENTAR) {
  if (!montarSite()) process.exit(1);
}
if (SO_COMENTAR) {
  console.log(await comentar(corpo()));
}
