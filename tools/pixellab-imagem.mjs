#!/usr/bin/env node
// Baixa o resultado de uma ferramenta de imagem do PixelLab (job) como PNG.
//   node tools/pixellab-imagem.mjs <job_id> <destino.png> [indice]
// O link não pede autenticação (o UUID é a chave); 423 = ainda gerando.
import fs from 'node:fs';
import path from 'node:path';
const [job, destino, indice] = process.argv.slice(2);
if (!job || !destino) { console.error('uso: pixellab-imagem.mjs <job_id> <destino.png> [indice]'); process.exit(2); }
const url = `https://api.pixellab.ai/mcp/images/${job}/download${indice ? `?index=${indice}` : ''}`;
for (let i = 0; i < 20; i++) {
  const r = await fetch(url);
  if (r.status === 423) { await new Promise((s) => setTimeout(s, 5000)); continue; }
  if (!r.ok) { console.error(`${url}: ${r.status}`); process.exit(1); }
  const b = Buffer.from(await r.arrayBuffer());
  fs.mkdirSync(path.dirname(destino), { recursive: true });
  fs.writeFileSync(destino, b);
  console.log(`${destino}: ${b.length} bytes`);
  process.exit(0);
}
console.error('ainda gerando'); process.exit(1);
