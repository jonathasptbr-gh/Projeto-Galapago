#!/usr/bin/env node
// Baixa um tileset Wang do PixelLab (folha PNG + metadados) para o projeto.
//   node tools/pixellab-tileset.mjs <tileset_id> <nome> [destino=arte/cenarios/tilesets]
// Grava <destino>/<nome>.png e <nome>.json. Os links /mcp/tilesets/<id>/* não
// pedem autenticação (o UUID é a chave) e respondem 423 enquanto geram.
import fs from 'node:fs';
import path from 'node:path';

const [id, nome, destino = 'arte/cenarios/tilesets'] = process.argv.slice(2);
if (!id || !nome) { console.error('uso: pixellab-tileset.mjs <tileset_id> <nome> [destino]'); process.exit(2); }
const base = `https://api.pixellab.ai/mcp/tilesets/${id}`;

async function pegar(url) {
  for (let i = 0; i < 30; i++) {
    const r = await fetch(url);
    if (r.status === 423) { await new Promise((s) => setTimeout(s, 1000 * Number(r.headers.get('retry-after') || 5))); continue; }
    if (!r.ok) throw new Error(`${url}: ${r.status}`);
    return r;
  }
  throw new Error(`${url}: ainda gerando`);
}

fs.mkdirSync(destino, { recursive: true });
const meta = await (await pegar(`${base}/metadata`)).json();
const png = Buffer.from(await (await pegar(`${base}/image?inline=true`)).arrayBuffer());
fs.writeFileSync(path.join(destino, `${nome}.json`), JSON.stringify({ pixellab_id: id, ...meta }, null, 1) + '\n');
fs.writeFileSync(path.join(destino, `${nome}.png`), png);
const tiles = meta.tileset_data?.tiles ?? [];
console.log(`${nome}: ${tiles.length} tiles, ${png.length} bytes · terrenos: ${JSON.stringify(meta.metadata?.terrain_prompts ?? {})}`);
