#!/usr/bin/env node
// Prancha de animação de um GLB para a revisão do operador (docs/MODELOS-3D.md).
// Renderiza por CPU (skinning do three + rasterização própria): roda no celular,
// sem GPU nem navegador. Vista lateral, quadros em 4 colunas, linha do chão.
//
//   cd tools/prancha3d && npm ci        (uma vez; node_modules fica fora do git)
//   node tools/prancha3d/render.mjs <clipe> <quadros> <modelo.glb> <saida.png>
//   node tools/prancha3d/render.mjs --clipes <modelo.glb>     lista os clipes
//
// <clipe> aceita o nome inteiro ("AnimalArmature|Gallop") ou o curto ("Gallop").
// Texturas não são lidas (o node não decodifica imagem): o que era textura sai
// cinza — a prancha julga silhueta e movimento, não cor.
import fs from 'node:fs';
import { PNG } from 'pngjs';
import { THREE, carregar, acharClipe, triangulos, rasterizar, fundo } from './glb.mjs';

const args = process.argv.slice(2);
if (!args.length || args[0] === '--help' || args[0] === '-h') {
  console.log(fs.readFileSync(new URL(import.meta.url), 'utf8').split('\n').slice(1)
    .filter((l) => l.startsWith('//')).map((l) => l.replace(/^\/\/ ?/, '')).join('\n'));
  process.exit(0);
}
if (args[0] === '--clipes') {
  const g = await carregar(args[1]);
  for (const a of g.animations) console.log(`${a.name} (${a.duration.toFixed(3)} s)`);
  process.exit(0);
}
const [nomeClipe, nQuadros, arquivo, saida] = args;
const N = Number(nQuadros);
if (!nomeClipe || !(N > 0) || !arquivo || !saida) {
  console.error('uso: render.mjs <clipe> <quadros> <modelo.glb> <saida.png> (veja --help)');
  process.exit(2);
}

const gltf = await carregar(arquivo);
const modelo = gltf.scene;
const clipe = acharClipe(gltf.animations, [nomeClipe]);
if (!clipe) {
  console.error(`clipe "${nomeClipe}" não existe; há: ${gltf.animations.map((a) => a.name).join(', ')}`);
  process.exit(1);
}
const mixer = new THREE.AnimationMixer(modelo);
const acao = mixer.clipAction(clipe);
acao.play();

const W = 240, H = 170, COLS = 4, linhas = Math.ceil(N / COLS);
const png = new PNG({ width: W * COLS, height: H * linhas });
fundo(png, 0, 0, W * COLS, H * linhas, [255, 255, 255, 255]);

// Enquadramento medido UMA vez, na pose de repouso: o bicho não "pula" de escala.
modelo.updateMatrixWorld(true);
const caixa = new THREE.Box3().setFromObject(modelo);
const tam = caixa.getSize(new THREE.Vector3()), ctr = caixa.getCenter(new THREE.Vector3());
const sc = Math.min((W * 0.8) / Math.max(tam.x, tam.z), (H * 0.75) / tam.y);
const emX = tam.x > tam.z; // eixo do comprimento na horizontal
const chao = Math.round(H * 0.88);
const proj = (q) => [W / 2 + (emX ? q.x - ctr.x : -(q.z - ctr.z)) * sc, chao - (q.y - caixa.min.y) * sc, emX ? q.z : q.x];

for (let f = 0; f < N; f++) {
  acao.time = (clipe.duration * f) / N;
  mixer.update(0);
  const ox = (f % COLS) * W, oy = Math.floor(f / COLS) * H;
  fundo(png, ox, oy, W, H);
  rasterizar(png, triangulos(modelo), ox, oy, W, H, proj);
  for (let x = 0; x < W; x++) png.data.set([150, 150, 160, 255], ((oy + chao) * png.width + ox + x) * 4);
}
fs.writeFileSync(saida, PNG.sync.write(png));
console.log(`${saida}: ${clipe.name}, ${clipe.duration.toFixed(3)} s, ${N} quadros`);
