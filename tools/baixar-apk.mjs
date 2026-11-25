#!/usr/bin/env node
// Baixa o APK de uma Release para o celular do operador — só para a 1ª
// instalação; depois o próprio app se atualiza (jogo/atualizador.gd). Uso: node tools/baixar-apk.mjs [tag=dev] [destino=/sdcard/Download/DSH-Go]
// A Release `dev` é refeita a cada publicação (commit `vX.Y.Z:` em main) pelo job `apk` do CI.
// Credencial: cofre do harness (refs.GITHUB_TOKEN), fallback ~/.dsh-github/token.
import fs from 'node:fs';
import path from 'node:path';

const REPO = 'jonathasptbr-gh/Projeto-Galapago';
const tag = process.argv[2] || 'dev';
const destino = process.argv[3] || '/sdcard/Download/DSH-Go';

function token() {
  try {
    const y = fs.readFileSync(path.join(process.env.HOME, '.dsh', '.credentials.yaml'), 'utf8');
    const m = y.match(/^\s+GITHUB_TOKEN:\s*["']?([^"'\s]+)/m);
    if (m) return m[1];
  } catch { /* cai para o arquivo antigo */ }
  return fs.readFileSync(path.join(process.env.HOME, '.dsh-github', 'token'), 'utf8').trim();
}

const h = { Authorization: 'Bearer ' + token(), 'User-Agent': 'galapago', Accept: 'application/vnd.github+json' };
const r = await fetch(`https://api.github.com/repos/${REPO}/releases/tags/${tag}`, { headers: h });
if (!r.ok) { console.error(`Release '${tag}': ${r.status}`); process.exit(1); }
const rel = await r.json();
const asset = rel.assets.find((a) => a.name.endsWith('.apk'));
if (!asset) { console.error(`Release '${tag}' sem APK`); process.exit(1); }
// Accept octet-stream → redireciona ao armazenamento; o fetch descarta o
// Authorization no redirecionamento entre origens.
const b = await fetch(asset.url, { headers: { ...h, Accept: 'application/octet-stream' } });
if (!b.ok) { console.error(`download: ${b.status}`); process.exit(1); }
const buf = Buffer.from(await b.arrayBuffer());
if (buf.length !== asset.size) { console.error(`tamanho ${buf.length} ≠ ${asset.size}`); process.exit(1); }
fs.mkdirSync(destino, { recursive: true });
const alvo = path.join(destino, asset.name);
fs.writeFileSync(alvo, buf);
console.log(`${rel.name} → ${alvo} (${(buf.length / 1048576).toFixed(1)} MB, commit ${rel.target_commitish.slice(0, 7)})`);
