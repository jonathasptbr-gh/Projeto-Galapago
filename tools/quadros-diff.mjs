#!/usr/bin/env node
// Diff dos quadros do oráculo (tools/quadros.sh) contra uma referência
// (pasta fora do git; o CI usa os quadros da última publicação, baixados por
// tools/quadros-referencia.mjs). Sem dependência: o PNG é decodificado aqui
// mesmo (zlib.inflateSync + desfiltro 0–4), só 8 bits, RGB ou RGBA, sem
// entrelaçamento. Ver docs/ORACULO.md.
//
// Uso: node tools/quadros-diff.mjs [pasta=quadros] [--baseline=testes/baseline]
//        [--canal=6] [--px=0.001] [--aviso] [--atualizar]
// Saída: 0 ok · 1 divergência/quadro faltando · 2 uso ou erro de leitura.
// --aviso: diferença de pixel, dimensão ou quadro sobrando vira AVISO (saída
// 0); só quadro FALTANDO reprova.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';

// A raiz vem do próprio arquivo (tools/..), nunca do cwd: o CI e o celular
// podem chamar de qualquer diretório.
const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const USO =
  'uso: node tools/quadros-diff.mjs [pasta=quadros] [--baseline=testes/baseline] ' +
  '[--canal=6] [--px=0.001] [--aviso] [--atualizar]';

class ErroUso extends Error {}
class ErroLeitura extends Error {}

// ---------------------------------------------------------------- argumentos

function numero(nome, texto, minimo) {
  const n = Number(texto);
  if (!Number.isFinite(n) || n < minimo) throw new ErroUso(`${nome} inválido: ${texto}`);
  return n;
}

function opcoes(argv) {
  const o = { pasta: 'quadros', baseline: 'testes/baseline', canal: 6, px: 0.001, atualizar: false, aviso: false };
  const posicionais = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--atualizar') { o.atualizar = true; continue; }
    if (a === '--aviso') { o.aviso = true; continue; }
    if (a === '-h' || a === '--ajuda' || a === '--help') { console.log(USO); process.exit(0); }
    if (a === '--baseline' || a === '--canal' || a === '--px') {
      const valor = argv[++i];
      if (valor === undefined) throw new ErroUso(`${a} precisa de um valor`);
      if (a === '--baseline') o.baseline = valor;
      else if (a === '--canal') o.canal = numero(a, valor, 0);
      else o.px = numero(a, valor, 0);
      continue;
    }
    if (a.startsWith('--baseline=')) { o.baseline = a.slice('--baseline='.length); continue; }
    if (a.startsWith('--canal=')) { o.canal = numero('--canal', a.slice('--canal='.length), 0); continue; }
    if (a.startsWith('--px=')) { o.px = numero('--px', a.slice('--px='.length), 0); continue; }
    if (a.startsWith('-')) throw new ErroUso(`opção desconhecida: ${a}`);
    posicionais.push(a);
  }
  if (posicionais.length > 1) throw new ErroUso(`sobra argumento: ${posicionais.slice(1).join(' ')}`);
  if (posicionais.length === 1) o.pasta = posicionais[0];
  if (o.px > 1) throw new ErroUso(`--px é fração de 0 a 1 (0,001 = 0,1% da imagem): ${o.px}`);
  if (o.canal > 255) throw new ErroUso(`--canal é delta por canal de 0 a 255: ${o.canal}`);
  return o;
}

// "~/tmp/x" não é expandido pelo bash depois de "="; expandimos aqui para o
// teste manual e o CI terem o mesmo comportamento.
function expandir(p) {
  if (p === '~') return os.homedir();
  if (p.startsWith('~/')) return path.join(os.homedir(), p.slice(2));
  return p;
}

function resolver(p) {
  return path.resolve(RAIZ, expandir(p));
}

// -------------------------------------------------------------- lista de PNG

function chaveNumerica(nome) {
  const m = nome.match(/\d+/);
  return m ? Number(m[0]) : Number.POSITIVE_INFINITY;
}

function ordenarQuadros(a, b) {
  return chaveNumerica(a) - chaveNumerica(b) || a.localeCompare(b);
}

function quadros(dir) {
  let entradas;
  try {
    entradas = fs.readdirSync(dir, { withFileTypes: true });
  } catch (e) {
    throw new ErroLeitura(`não consegui ler ${dir}: ${e.message}`);
  }
  return entradas
    .filter((d) => d.isFile() && /^q.*\.png$/.test(d.name))
    .map((d) => d.name)
    .sort(ordenarQuadros);
}

// --------------------------------------------------------------- PNG 8 bits

const ASSINATURA = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

// Desfiltro de linha (spec PNG): 0 None, 1 Sub, 2 Up, 3 Average, 4 Paeth.
function desfiltrar(bruto, largura, altura, canais) {
  const bpp = canais;
  const linha = largura * bpp;
  const esperado = altura * (linha + 1);
  if (bruto.length !== esperado) {
    return null;
  }
  for (let y = 0; y < altura; y++) {
    const inicio = y * (linha + 1);
    const filtro = bruto[inicio];
    const atual = inicio + 1;
    const anterior = y > 0 ? inicio - linha : -1;
    switch (filtro) {
      case 0:
        break;
      case 1:
        for (let i = bpp; i < linha; i++) bruto[atual + i] = (bruto[atual + i] + bruto[atual + i - bpp]) & 0xff;
        break;
      case 2:
        if (anterior >= 0) for (let i = 0; i < linha; i++) bruto[atual + i] = (bruto[atual + i] + bruto[anterior + i]) & 0xff;
        break;
      case 3:
        for (let i = 0; i < linha; i++) {
          const esq = i >= bpp ? bruto[atual + i - bpp] : 0;
          const cima = anterior >= 0 ? bruto[anterior + i] : 0;
          bruto[atual + i] = (bruto[atual + i] + ((esq + cima) >> 1)) & 0xff;
        }
        break;
      case 4:
        for (let i = 0; i < linha; i++) {
          const esq = i >= bpp ? bruto[atual + i - bpp] : 0;
          const cima = anterior >= 0 ? bruto[anterior + i] : 0;
          const diag = i >= bpp && anterior >= 0 ? bruto[anterior + i - bpp] : 0;
          const p = esq + cima - diag;
          const pa = Math.abs(p - esq);
          const pb = Math.abs(p - cima);
          const pc = Math.abs(p - diag);
          const pred = pa <= pb && pa <= pc ? esq : pb <= pc ? cima : diag;
          bruto[atual + i] = (bruto[atual + i] + pred) & 0xff;
        }
        break;
      default:
        throw new ErroLeitura(`filtro PNG ${filtro} desconhecido (só 0–4)`);
    }
  }
  return bruto;
}

// Lê um PNG e devolve { largura, altura, pixels } com pixels em RGBA 8 bits
// (alpha 255 quando o arquivo é RGB), pronto para comparar.
function lerPng(arquivo) {
  let buf;
  try {
    buf = fs.readFileSync(arquivo);
  } catch (e) {
    throw new ErroLeitura(`não consegui ler ${arquivo}: ${e.message}`);
  }
  if (buf.length < 8 || !buf.subarray(0, 8).equals(ASSINATURA)) {
    throw new ErroLeitura(`${arquivo}: não é um PNG`);
  }
  let pos = 8;
  let ihdr = null;
  const idat = [];
  while (pos + 8 <= buf.length) {
    const len = buf.readUInt32BE(pos);
    const tipo = buf.toString('latin1', pos + 4, pos + 8);
    const inicio = pos + 8;
    const fim = inicio + len;
    if (fim + 4 > buf.length) throw new ErroLeitura(`${arquivo}: chunk ${tipo} truncado`);
    if (tipo === 'IHDR') {
      if (len !== 13) throw new ErroLeitura(`${arquivo}: IHDR com ${len} bytes`);
      ihdr = {
        largura: buf.readUInt32BE(inicio),
        altura: buf.readUInt32BE(inicio + 4),
        bits: buf[inicio + 8],
        cor: buf[inicio + 9],
        compressao: buf[inicio + 10],
        filtro: buf[inicio + 11],
        entrelacado: buf[inicio + 12],
      };
    } else if (tipo === 'IDAT') {
      idat.push(buf.subarray(inicio, fim));
    } else if (tipo === 'IEND') {
      break;
    }
    pos = fim + 4;
  }
  if (!ihdr) throw new ErroLeitura(`${arquivo}: PNG sem IHDR`);
  if (ihdr.bits !== 8) throw new ErroLeitura(`${arquivo}: bit depth ${ihdr.bits} não suportado (só 8 bits)`);
  if (ihdr.cor !== 6 && ihdr.cor !== 2) {
    throw new ErroLeitura(`${arquivo}: color type ${ihdr.cor} não suportado (só 6/RGBA e 2/RGB)`);
  }
  if (ihdr.entrelacado !== 0) throw new ErroLeitura(`${arquivo}: PNG entrelaçado não suportado`);
  if (ihdr.compressao !== 0 || ihdr.filtro !== 0) {
    throw new ErroLeitura(`${arquivo}: compressão/filtro PNG ${ihdr.compressao}/${ihdr.filtro} não suportado`);
  }
  if (!idat.length) throw new ErroLeitura(`${arquivo}: PNG sem IDAT`);
  const canais = ihdr.cor === 6 ? 4 : 3;
  let bruto;
  try {
    bruto = zlib.inflateSync(Buffer.concat(idat));
  } catch (e) {
    throw new ErroLeitura(`${arquivo}: dados zlib inválidos: ${e.message}`);
  }
  const linhas = desfiltrar(bruto, ihdr.largura, ihdr.altura, canais);
  if (!linhas) throw new ErroLeitura(`${arquivo}: dados descomprimidos com tamanho inesperado`);

  const total = ihdr.largura * ihdr.altura;
  const pixels = new Uint8Array(total * 4);
  const linha = ihdr.largura * canais;
  for (let y = 0; y < ihdr.altura; y++) {
    let src = y * (linha + 1) + 1;
    let dst = y * ihdr.largura * 4;
    for (let x = 0; x < ihdr.largura; x++) {
      pixels[dst] = linhas[src];
      pixels[dst + 1] = linhas[src + 1];
      pixels[dst + 2] = linhas[src + 2];
      pixels[dst + 3] = canais === 4 ? linhas[src + 3] : 255;
      src += canais;
      dst += 4;
    }
  }
  return { largura: ihdr.largura, altura: ihdr.altura, pixels };
}

// ---------------------------------------------------------------- comparação

function comparar(a, b, canal) {
  const total = a.largura * a.altura;
  let diferentes = 0;
  let maiorDelta = 0;
  let x0 = Number.POSITIVE_INFINITY;
  let y0 = Number.POSITIVE_INFINITY;
  let x1 = -1;
  let y1 = -1;
  for (let y = 0; y < a.altura; y++) {
    let i = y * a.largura * 4;
    for (let x = 0; x < a.largura; x++, i += 4) {
      const dr = Math.abs(a.pixels[i] - b.pixels[i]);
      const dg = Math.abs(a.pixels[i + 1] - b.pixels[i + 1]);
      const db = Math.abs(a.pixels[i + 2] - b.pixels[i + 2]);
      const da = Math.abs(a.pixels[i + 3] - b.pixels[i + 3]);
      const d = Math.max(dr, dg, db, da);
      if (d > canal) {
        diferentes++;
        if (d > maiorDelta) maiorDelta = d;
        if (x < x0) x0 = x;
        if (y < y0) y0 = y;
        if (x > x1) x1 = x;
        if (y > y1) y1 = y;
      }
    }
  }
  return { total, diferentes, fracao: diferentes / total, maiorDelta, x0, y0, x1, y1 };
}

function pct(n) {
  return n.toFixed(2).replace('.', ',') + '%';
}

function numeral(n) {
  return Number.isInteger(n) ? String(n) : String(n).replace('.', ',');
}

// ------------------------------------------------------------- modos de uso

function atualizar(pasta, baseline) {
  if (pasta === baseline) throw new ErroUso('a pasta dos quadros e o baseline são o mesmo diretório');
  if (baseline === RAIZ || baseline === path.parse(baseline).root) {
    throw new ErroUso(`baseline perigoso: ${baseline}`);
  }
  const nomes = quadros(pasta);
  if (!nomes.length) throw new ErroLeitura(`nenhum q*.png em ${pasta}; rode tools/quadros.sh antes`);
  fs.mkdirSync(baseline, { recursive: true });
  for (const nome of nomes) fs.copyFileSync(path.join(pasta, nome), path.join(baseline, nome));
  const antigos = quadros(baseline).filter((nome) => !nomes.includes(nome));
  for (const nome of antigos) fs.rmSync(path.join(baseline, nome));
  console.log(
    `${nomes.length} quadros copiados de ${pasta} para ${baseline}` +
      (antigos.length ? ` (${antigos.length} antigos removidos)` : ''),
  );
}

function compararPastas(pasta, baseline, canal, px, aviso) {
  if (!fs.existsSync(baseline)) {
    throw new ErroLeitura(
      `baseline ausente em ${baseline}; ` +
        'baixe a referência com node tools/quadros-referencia.mjs --baixar (ver docs/ORACULO.md)',
    );
  }
  const doBaseline = quadros(baseline);
  if (!doBaseline.length) {
    throw new ErroLeitura(
      `baseline vazio em ${baseline}; ` +
        'baixe a referência com node tools/quadros-referencia.mjs --baixar (ver docs/ORACULO.md)',
    );
  }
  const daPasta = quadros(pasta);
  const conjuntoBase = new Set(doBaseline);
  const conjuntoPasta = new Set(daPasta);
  const faltando = doBaseline.filter((nome) => !conjuntoPasta.has(nome));
  const sobrando = daPasta.filter((nome) => !conjuntoBase.has(nome));
  const comuns = daPasta.filter((nome) => conjuntoBase.has(nome));

  const falhas = [];
  let ok = 0;
  for (const nome of comuns) {
    const alvo = lerPng(path.join(pasta, nome));
    const base = lerPng(path.join(baseline, nome));
    if (alvo.largura !== base.largura || alvo.altura !== base.altura) {
      falhas.push(
        `${nome}: dimensões diferentes (baseline ${base.largura}x${base.altura}, pasta ${alvo.largura}x${alvo.altura})`,
      );
      continue;
    }
    const r = comparar(base, alvo, canal);
    if (r.fracao > px) {
      falhas.push(
        `${nome}: ${r.diferentes} pixels diferentes (${pct(r.fracao * 100)}), ` +
          `maior delta ${r.maiorDelta}, caixa ${r.x0},${r.y0},${r.x1},${r.y1}`,
      );
    } else {
      ok++;
    }
  }

  if (!falhas.length && !faltando.length && !sobrando.length) {
    console.log(
      `${ok}/${doBaseline.length} quadros dentro da tolerância ` +
        `(canal ≤ ${numeral(canal)}, pixels ≤ ${pct(px * 100)})`,
    );
    return true;
  }

  for (const f of falhas) console.log(f);
  if (faltando.length) console.log(`faltando na pasta (o baseline tem): ${faltando.join(', ')}`);
  if (sobrando.length) console.log(`sobrando na pasta (o baseline não tem): ${sobrando.join(', ')}`);
  if (aviso && !faltando.length) {
    console.log(
      `AVISO: ${falhas.length + sobrando.length} diferença(s) visual(is) em ${doBaseline.length} quadros ` +
        `(${ok} dentro da tolerância) — diferença visual não reprova; confira os quadros`,
    );
    return true;
  }
  console.log(
    `REPROVADO: ${falhas.length + faltando.length + sobrando.length} problema(s) ` +
      `em ${doBaseline.length} quadros do baseline`,
  );
  return false;
}

// ---------------------------------------------------------------------- main

function principal() {
  let o;
  try {
    o = opcoes(process.argv.slice(2));
  } catch (e) {
    if (!(e instanceof ErroUso)) throw e;
    console.error(`erro: ${e.message}`);
    console.error(USO);
    return 2;
  }
  const pasta = resolver(o.pasta);
  const baseline = resolver(o.baseline);
  try {
    if (o.atualizar) {
      atualizar(pasta, baseline);
      return 0;
    }
    return compararPastas(pasta, baseline, o.canal, o.px, o.aviso) ? 0 : 1;
  } catch (e) {
    if (e instanceof ErroLeitura) {
      console.error(`erro: ${e.message}`);
      return 2;
    }
    if (e instanceof ErroUso) {
      console.error(`erro: ${e.message}`);
      console.error(USO);
      return 2;
    }
    throw e;
  }
}

process.exitCode = principal();
