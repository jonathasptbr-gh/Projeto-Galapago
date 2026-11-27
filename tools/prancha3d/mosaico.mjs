#!/usr/bin/env node
// Mosaico de candidatos: um quadro de cada GLB de uma pasta, lado a lado, com o
// nome do arquivo no relatório (docs/MODELOS-3D.md). Serve para o operador
// comparar silhuetas antes de escolher; a prancha (render.mjs) vem depois.
//
//   node tools/prancha3d/mosaico.mjs <pasta-com-glb> <saida.png> [clipe preferido...]
//
// Clipe de cada modelo: o primeiro que existir entre os pedidos e, depois,
// Gallop, Run, Walk, Swim_Fast, Swim, Flying, Fly, Jump; sem nenhum, a pose de
// repouso. Quadro a 35% do clipe, 5 colunas, ordem alfabética dos arquivos.
import fs from 'node:fs';
import path from 'node:path';
import { PNG } from 'pngjs';
import { THREE, carregar, acharClipe, triangulos, rasterizar, fundo } from './glb.mjs';

const [pasta, saida, ...pedidos] = process.argv.slice(2);
if (!pasta || pasta === '--help' || pasta === '-h' || !saida) {
  console.log(fs.readFileSync(new URL(import.meta.url), 'utf8').split('\n').slice(1)
    .filter((l) => l.startsWith('//')).map((l) => l.replace(/^\/\/ ?/, '')).join('\n'));
  process.exit(pasta && pasta !== '--help' && pasta !== '-h' ? 2 : 0);
}
const arquivos = fs.readdirSync(pasta).filter((f) => f.toLowerCase().endsWith('.glb')).sort();
const W = 200, H = 150, COLS = 5, linhas = Math.ceil(arquivos.length / COLS);
const png = new PNG({ width: W * COLS, height: H * linhas });
png.data.fill(255);
const preferidos = [...pedidos, 'Gallop', 'Run', 'Walk', 'Swim_Fast', 'Swim', 'Flying', 'Fly', 'Jump'];

for (let t = 0; t < arquivos.length; t++) {
  const gltf = await carregar(path.join(pasta, arquivos[t]));
  const modelo = gltf.scene;
  const clipe = acharClipe(gltf.animations, preferidos);
  if (clipe) {
    const mixer = new THREE.AnimationMixer(modelo);
    const a = mixer.clipAction(clipe); a.play(); a.time = clipe.duration * 0.35; mixer.update(0);
  }
  const tris = triangulos(modelo);
  const pts = tris.flatMap(([a, b, c]) => [a, b, c]);
  const caixa = new THREE.Box3().setFromPoints(pts);
  const tam = caixa.getSize(new THREE.Vector3()), ctr = caixa.getCenter(new THREE.Vector3());
  const emX = tam.x >= tam.z;
  const sc = Math.min((W * 0.85) / Math.max(emX ? tam.x : tam.z, 1e-6), (H * 0.68) / Math.max(tam.y, 1e-6));
  const ox = (t % COLS) * W, oy = Math.floor(t / COLS) * H;
  fundo(png, ox, oy, W, H, [238, 240, 244, 255]);
  rasterizar(png, tris, ox, oy, W, H, (q) => [W / 2 + (emX ? q.x - ctr.x : -(q.z - ctr.z)) * sc, H * 0.5 - (q.y - ctr.y) * sc + 8, emX ? q.z : q.x]);
  console.log(`${t + 1}. ${arquivos[t]}: ${clipe ? clipe.name : '(repouso)'}`);
}
fs.writeFileSync(saida, PNG.sync.write(png));
console.log(`${saida}: ${arquivos.length} modelos`);
