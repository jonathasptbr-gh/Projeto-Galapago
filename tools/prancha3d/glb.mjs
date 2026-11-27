// Comum à prancha e ao mosaico: carregar um GLB no node (sem navegador, sem GPU)
// e rasterizar triângulos já deformados pelo esqueleto num PNG, por CPU.
import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import fs from 'node:fs';

export { THREE };

// O node não decodifica imagens: tira as texturas do JSON do GLB e pinta o que
// era texturizado de cinza-azulado. Cor de material sem textura fica como está.
function semTextura(b) {
  const len = b.readUInt32LE(12);
  const j = JSON.parse(b.subarray(20, 20 + len));
  if (!j.textures) return b;
  for (const m of j.materials || []) {
    const p = m.pbrMetallicRoughness || {};
    if (p.baseColorTexture) p.baseColorFactor = [0.55, 0.6, 0.65, 1];
    for (const k of ['baseColorTexture', 'metallicRoughnessTexture']) delete p[k];
    for (const k of ['normalTexture', 'occlusionTexture', 'emissiveTexture']) delete m[k];
    delete m.extensions;
  }
  delete j.textures; delete j.images; delete j.samplers;
  let js = Buffer.from(JSON.stringify(j));
  js = Buffer.concat([js, Buffer.alloc((4 - (js.length % 4)) % 4, 0x20)]);
  const h = Buffer.alloc(20); b.copy(h, 0, 0, 12);
  h.writeUInt32LE(js.length, 12); h.writeUInt32LE(0x4e4f534a, 16);
  const out = Buffer.concat([h, js, b.subarray(20 + len)]);
  out.writeUInt32LE(out.length, 8);
  return out;
}

export async function carregar(arquivo) {
  const b = semTextura(fs.readFileSync(arquivo));
  const ab = b.buffer.slice(b.byteOffset, b.byteOffset + b.length);
  return new Promise((ok, no) => new GLTFLoader().parse(ab, '', ok, no));
}

// Nome curto do clipe: "AnimalArmature|Gallop" → "Gallop", "Armature|TRex_Run" → "Run".
export const curto = (n) => n.split('|').pop().replace(/^.*_(?=(Run|Walk|Jump|Flying|Fly|Swim|Swim_Fast)$)/, '');

export function acharClipe(animacoes, pedidos) {
  for (const p of pedidos) {
    const c = animacoes.find((a) => a.name === p) || animacoes.find((a) => curto(a.name) === p)
      || animacoes.find((a) => a.name.includes(p));
    if (c) return c;
  }
  return null;
}

// Vértices deformados (skinning aplicado) de todas as malhas, em coordenadas do mundo.
export function triangulos(modelo) {
  modelo.updateMatrixWorld(true);
  const tris = [];
  modelo.traverse((m) => {
    if (!m.isMesh) return;
    const g = m.geometry, pos = g.attributes.position, idx = g.index, v = [];
    for (let i = 0; i < pos.count; i++) {
      const p = new THREE.Vector3().fromBufferAttribute(pos, i);
      if (m.isSkinnedMesh) m.applyBoneTransform(i, p);
      v.push(p.applyMatrix4(m.matrixWorld));
    }
    const mats = Array.isArray(m.material) ? m.material : [m.material];
    const grupos = g.groups.length ? g.groups : [{ start: 0, count: idx ? idx.count : pos.count, materialIndex: 0 }];
    for (const gr of grupos) {
      const cor = (mats[gr.materialIndex] || mats[0])?.color || new THREE.Color(0.6, 0.6, 0.6);
      for (let k = gr.start; k + 2 < gr.start + gr.count; k += 3) {
        const at = (n) => v[idx ? idx.getX(n) : n];
        tris.push([at(k), at(k + 1), at(k + 2), cor]);
      }
    }
  });
  return tris;
}

const LUZ = new THREE.Vector3(0.4, 0.8, 0.45).normalize();

// Desenha `tris` numa célula (ox, oy, W, H) do PNG, vista lateral: o eixo mais
// comprido do animal na horizontal. `proj` converte ponto → [x, y, profundidade].
export function rasterizar(png, tris, ox, oy, W, H, proj) {
  const zb = new Float32Array(W * H).fill(-Infinity);
  const larg = png.width;
  const s = (c, sh) => Math.round(255 * Math.min(1, Math.pow(c * sh, 1 / 2.2)));
  for (const [a, b, c, cor] of tris) {
    const n = new THREE.Vector3().subVectors(b, a).cross(new THREE.Vector3().subVectors(c, a)).normalize();
    const sh = 0.45 + 0.55 * Math.abs(n.dot(LUZ));
    const [A, B, C] = [proj(a), proj(b), proj(c)];
    const d = (B[0] - A[0]) * (C[1] - A[1]) - (C[0] - A[0]) * (B[1] - A[1]);
    if (!d) continue;
    const x0 = Math.max(0, Math.floor(Math.min(A[0], B[0], C[0]))), x1 = Math.min(W - 1, Math.ceil(Math.max(A[0], B[0], C[0])));
    const y0 = Math.max(0, Math.floor(Math.min(A[1], B[1], C[1]))), y1 = Math.min(H - 1, Math.ceil(Math.max(A[1], B[1], C[1])));
    for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) {
      const w1 = ((x + 0.5 - A[0]) * (C[1] - A[1]) - (C[0] - A[0]) * (y + 0.5 - A[1])) / d;
      const w2 = ((B[0] - A[0]) * (y + 0.5 - A[1]) - (x + 0.5 - A[0]) * (B[1] - A[1])) / d;
      const w0 = 1 - w1 - w2;
      if (w0 < 0 || w1 < 0 || w2 < 0) continue;
      const z = w0 * A[2] + w1 * B[2] + w2 * C[2], zi = y * W + x;
      if (z <= zb[zi]) continue;
      zb[zi] = z;
      png.data.set([s(cor.r, sh), s(cor.g, sh), s(cor.b, sh), 255], ((oy + y) * larg + ox + x) * 4);
    }
  }
}

export function fundo(png, ox, oy, W, H, rgba = [236, 238, 242, 255]) {
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) png.data.set(rgba, ((oy + y) * png.width + ox + x) * 4);
}
