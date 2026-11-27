#!/usr/bin/env node
// Kit Sketchfab do padrão de modelos 3D (guia: docs/MODELOS-3D.md).
//
//   node tools/sketchfab.mjs buscar <termo...> [--todas]   busca pública (sem chave):
//        modelos baixáveis E animados; mostra uid, nome, autor, licença, clipes,
//        faces e o veredito da licença (--todas inclui os recusados)
//   node tools/sketchfab.mjs info <uid>                    ficha pública + veredito
//   node tools/sketchfab.mjs baixar <uid> <destino.glb>    baixa o GLB (com chave) e
//        grava <destino>.credito.txt; recusa licença fora do padrão
//   node tools/sketchfab.mjs --help
//
// A chave mora SÓ no cofre do harness: ~/.dsh/.credentials.yaml, refs.SKETCHFAB_TOKEN.
// Lida em tempo de execução, nunca impressa nem gravada. O repositório é público.
// O destino do download é cache passageiro (~/tmp/...): modelo só entra no
// repositório quando escolhido para o jogo, com o crédito junto.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const API = 'https://api.sketchfab.com/v3';

// Licenças do padrão (decisão do operador, 2026-11-26). Sketchfab rotula assim
// (`license.label`): "CC0 Public Domain", "CC Attribution", "Free Standard",
// "CC Attribution-ShareAlike", "CC Attribution-NoDerivs",
// "CC Attribution-NonCommercial[-ShareAlike|-NoDerivs]", "Standard", "Editorial".
export function avaliarLicenca(modelo) {
  const rotulo = modelo?.license?.label || modelo?.license || '';
  const tags = (modelo?.tags || []).map((t) => (typeof t === 'string' ? t : t.slug || t.name || '').toLowerCase());
  const texto = `${modelo?.name || ''} ${modelo?.description || ''}`;
  if (tags.some((t) => /^(ai-?generated|generative-?ai|ai-?model|ai-?3d)$/.test(t)) || /\bAI[- ]?generated\b/i.test(texto)) {
    return { aceita: false, credito: false, motivo: 'marcado como gerado por IA' };
  }
  if (/NonCommercial/i.test(rotulo)) return { aceita: false, credito: false, motivo: 'NC (não comercial)' };
  if (/NoDerivs/i.test(rotulo)) return { aceita: false, credito: false, motivo: 'ND (não permite ajuste)' };
  if (/ShareAlike/i.test(rotulo)) return { aceita: false, credito: false, motivo: 'SA (contamina a licença)' };
  if (/^CC0\b/i.test(rotulo)) return { aceita: true, credito: false, motivo: 'CC0' };
  if (/^CC Attribution$/i.test(rotulo)) return { aceita: true, credito: true, motivo: 'CC-BY: crédito obrigatório' };
  if (/^Free Standard$/i.test(rotulo)) return { aceita: true, credito: false, motivo: 'Free Standard' };
  return { aceita: false, credito: false, motivo: `licença fora do padrão: ${rotulo || '(sem rótulo)'}` };
}

// Primeira linha = o texto do crédito como vai aparecer no jogo; a segunda é rastreio.
export function linhaCredito(modelo, data = new Date().toLocaleDateString('sv-SE')) {
  const autor = modelo.user?.username || modelo.user?.displayName || '?';
  const link = modelo.viewerUrl || `https://sketchfab.com/3d-models/${modelo.uid}`;
  return `"${modelo.name}" por ${autor} — ${modelo.license?.label || '?'} — ${link}\n` +
    `fonte: sketchfab ${modelo.uid} · baixado em ${data}\n`;
}

export function token() {
  const s = fs.readFileSync(path.join(os.homedir(), '.dsh', '.credentials.yaml'), 'utf8');
  const m = s.match(/^\s+SKETCHFAB_TOKEN:\s*['"]?([^'"\s]+)/m);
  if (!m) throw new Error('refs.SKETCHFAB_TOKEN ausente no cofre (~/.dsh/.credentials.yaml)');
  return m[1];
}

export async function api(caminho, auth = false) {
  const r = await fetch(API + caminho, {
    headers: auth ? { Authorization: 'Token ' + token() } : {},
    signal: AbortSignal.timeout(60000),
  });
  const txt = await r.text();
  let j; try { j = JSON.parse(txt); } catch { j = { bruto: txt.slice(0, 200) }; }
  return { status: r.status, j };
}

// Baixa o GLB com novas tentativas (o S3 do Sketchfab às vezes demora a conectar).
export async function baixar(uid, arquivo) {
  for (let i = 0; i < 4; i++) {
    try {
      const d = (await api(`/models/${uid}/download`, true)).j;
      if (!d.glb) throw new Error('sem glb: ' + (d.detail || JSON.stringify(d).slice(0, 120)));
      const r = await fetch(d.glb.url, { signal: AbortSignal.timeout(180000) });
      if (!r.ok) throw new Error('HTTP ' + r.status);
      const b = Buffer.from(await r.arrayBuffer());
      fs.mkdirSync(path.dirname(path.resolve(arquivo)), { recursive: true });
      fs.writeFileSync(arquivo, b);
      return b;
    } catch (e) {
      if (i === 3) throw e;
      await new Promise((s) => setTimeout(s, 3000));
    }
  }
}

function linha(m) {
  const v = avaliarLicenca(m);
  return [m.uid, m.name.slice(0, 40), m.user?.username, m.license?.label, `${m.animationCount} clipes`,
    `${m.faceCount} faces`, v.aceita ? `ACEITA (${v.motivo})` : `recusada (${v.motivo})`].join(' | ');
}

const AJUDA = fs.readFileSync(fileURLToPath(import.meta.url), 'utf8').split('\n')
  .slice(1).filter((l) => l.startsWith('//')).map((l) => l.replace(/^\/\/ ?/, '')).join('\n');

async function main(args) {
  const [cmd, ...resto] = args;
  if (!cmd || cmd === '--help' || cmd === '-h') { console.log(AJUDA); return 0; }
  if (cmd === 'buscar') {
    const todas = resto.includes('--todas');
    const q = resto.filter((a) => a !== '--todas').join(' ');
    if (!q) { console.error('uso: buscar <termo...> [--todas]'); return 2; }
    const { status, j } = await api(`/search?type=models&downloadable=true&animated=true&count=24&q=${encodeURIComponent(q)}`);
    if (status !== 200) { console.error(`busca: HTTP ${status}`); return 1; }
    const lista = (j.results || []).filter((m) => todas || avaliarLicenca(m).aceita);
    for (const m of lista) console.log(linha(m));
    console.log(`(${lista.length} de ${(j.results || []).length} na primeira página; fan-art de marca se confere à mão)`);
    return 0;
  }
  if (cmd === 'info') {
    if (!resto[0]) { console.error('uso: info <uid>'); return 2; }
    const { status, j } = await api(`/models/${resto[0]}`);
    if (status !== 200) { console.error(`info: HTTP ${status}`); return 1; }
    console.log(linha(j));
    console.log(j.viewerUrl);
    return 0;
  }
  if (cmd === 'baixar') {
    const [uid, destino] = resto;
    if (!uid || !destino) { console.error('uso: baixar <uid> <destino.glb>'); return 2; }
    const { status, j } = await api(`/models/${uid}`);
    if (status !== 200) { console.error(`info: HTTP ${status}`); return 1; }
    const v = avaliarLicenca(j);
    if (!v.aceita) { console.error(`RECUSADO: ${v.motivo}`); return 1; }
    const b = await baixar(uid, destino);
    const cred = destino.replace(/\.glb$/i, '') + '.credito.txt';
    fs.writeFileSync(cred, linhaCredito(j));
    console.log(`${destino}: ${b.length} bytes · ${cred}`);
    return 0;
  }
  console.error(`comando desconhecido: ${cmd} (veja --help)`);
  return 2;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  process.exitCode = await main(process.argv.slice(2));
}
