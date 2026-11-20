#!/usr/bin/env node
// Catálogo do PixelLab gerado DA FONTE: pergunta ao servidor MCP (tools/list e
// resources/list) e escreve docs/pixellab/CATALOGO.md + ferramentas.json.
// Rode de novo quando o PixelLab mudar: `node tools/pixellab-catalogo.mjs`.
// A chave vem do cofre do harness (refs.PIXELLAB_TOKEN) e NUNCA é impressa.
import fs from 'node:fs';
import path from 'node:path';

const RAIZ = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const SAIDA = path.join(RAIZ, 'docs', 'pixellab');
const URL_MCP = 'https://api.pixellab.ai/mcp';

function chave() {
  const y = fs.readFileSync(path.join(process.env.HOME, '.dsh', '.credentials.yaml'), 'utf8');
  const m = y.match(/^\s+PIXELLAB_TOKEN:\s*["']?([^"'\s]+)/m);
  if (!m) throw new Error('refs.PIXELLAB_TOKEN ausente no cofre');
  return m[1];
}

const T = chave();
let sessao = null;
let seq = 0;
async function rpc(method, params, notificacao = false) {
  const h = { Authorization: 'Bearer ' + T, 'Content-Type': 'application/json',
    Accept: 'application/json, text/event-stream' };
  if (sessao) h['Mcp-Session-Id'] = sessao;
  const corpo = { jsonrpc: '2.0', method, ...(params ? { params } : {}), ...(notificacao ? {} : { id: ++seq }) };
  const r = await fetch(URL_MCP, { method: 'POST', headers: h, body: JSON.stringify(corpo) });
  sessao = r.headers.get('mcp-session-id') || sessao;
  if (notificacao) return null;
  const t = await r.text();
  const linha = t.split('\n').filter((l) => l.startsWith('data:')).pop();
  const j = JSON.parse(linha ? linha.slice(5) : t);
  if (j.error) throw new Error(`${method}: ${j.error.message}`);
  return j.result;
}

async function todos(method, chaveLista) {
  const itens = [];
  let cursor;
  do {
    const r = await rpc(method, cursor ? { cursor } : {});
    itens.push(...r[chaveLista]);
    cursor = r.nextCursor;
  } while (cursor);
  return itens;
}

// Categorias por nome — a ordem importa (a primeira que casar vence).
const CATEGORIAS = [
  ['Retrato e fala', /portrait|vocal|talking|lip_sync/],
  ['Personagens, estados e animação', /character|^animate_(character|with_skeleton)|skeleton|mirror_animation|delete_animation/],
  ['Imagem: criar', /^create_image/],
  ['Imagem: editar, animar e corrigir', /^edit_(?!map)|^inpaint_image|^animate_image|transfer_outfit|reduce_colors|correct_pixelart|unzoom|image_to_pixelart|remove_background|normal_map|save_to_asset/],
  ['Ferramentas exatas (grátis): workbench e VFX', /workbench/],
  ['Tiles, tilesets, mapas e salas', /tile|map|room|building_kit|path_tiles/],
  ['Objetos', /object|dismiss_review/],
  ['Áudio', /music|sound/],
  ['Interface e fontes', /ui_|font/],
  ['Projetos, sandbox e Game Builder (não usamos)', /project|sandbox|chat_|agent_|deploy|knowledge/],
  ['Conta, jobs, ajuda e exportação', /.*/],
];

function categoria(nome) {
  return CATEGORIAS.find(([, re]) => re.test(nome))[0];
}

function primeiraFrase(d) {
  return (d || '').trim().split('\n')[0].trim();
}

function custo(d) {
  const m = (d || '').match(/Cost:([^\n]*(?:\n(?!\s*\n)[^\n]*)?)/);
  if (m) return m[1].replace(/\s+/g, ' ').trim().slice(0, 160);
  if (/\bfree\b|Free[.,]|FREE/.test(d || '')) return 'grátis';
  return '—';
}

const ferramentas = (await todos('tools/list', 'tools')).sort((a, b) => a.name.localeCompare(b.name));
let recursos = [];
try { recursos = await todos('resources/list', 'resources'); } catch { /* opcional */ }

fs.mkdirSync(SAIDA, { recursive: true });
fs.writeFileSync(path.join(SAIDA, 'ferramentas.json'),
  JSON.stringify({ gerado: new Date().toISOString(), total: ferramentas.length, ferramentas, recursos }, null, 1) + '\n');

const porCat = new Map(CATEGORIAS.map(([c]) => [c, []]));
for (const f of ferramentas) porCat.get(categoria(f.name)).push(f);

const md = [];
md.push('# PixelLab — catálogo completo das ferramentas MCP', '');
md.push(`> **Gerado da fonte** por \`node tools/pixellab-catalogo.mjs\` em ${new Date().toISOString().slice(0, 10)}`);
md.push('> (`tools/list` do servidor `https://api.pixellab.ai/mcp`). Não edite à mão:');
md.push('> rode o script de novo. Esquemas completos (todos os parâmetros) em');
md.push('> [`ferramentas.json`](ferramentas.json); referência oficial de uma ferramenta,');
md.push('> grátis: `mcp__pixellab__search_help(tool="<nome>")`. O guia de USO é o');
md.push('> [`../PIXELLAB.md`](../PIXELLAB.md).', '');
md.push(`**Total: ${ferramentas.length} ferramentas** · ${recursos.length} recursos de documentação. No DSH cada uma se chama \`mcp__pixellab__<nome>\`.`, '');
md.push('| categoria | qtd |', '|---|---|');
for (const [c, fs_] of porCat) if (fs_.length) md.push(`| ${c} | ${fs_.length} |`);
md.push('');
for (const [c, lista] of porCat) {
  if (!lista.length) continue;
  md.push(`## ${c}`, '', '| ferramenta | o que faz | custo (da doc) | obrigatórios |', '|---|---|---|---|');
  for (const f of lista) {
    const req = (f.inputSchema?.required || []).map((r) => `\`${r}\``).join(', ') || '—';
    const desc = primeiraFrase(f.description).replace(/\|/g, '\\|');
    md.push(`| \`${f.name}\` | ${desc} | ${custo(f.description).replace(/\|/g, '\\|')} | ${req} |`);
  }
  md.push('');
}
if (recursos.length) {
  md.push('## Recursos de documentação (MCP resources)', '', 'Ler com `read_mcp_resource(server="pixellab", uri=...)`.', '');
  md.push('| uri | descrição |', '|---|---|');
  for (const r of recursos) md.push(`| \`${r.uri}\` | ${(r.description || '').replace(/\s+/g, ' ').replace(/\|/g, '\\|')} |`);
  md.push('');
}
fs.writeFileSync(path.join(SAIDA, 'CATALOGO.md'), md.join('\n'));

// Cópia local dos recursos de documentação (Godot, Wang, isométrico, visão geral).
const dirRec = path.join(SAIDA, 'recursos');
fs.mkdirSync(dirRec, { recursive: true });
for (const r of recursos) {
  const conteudo = await rpc('resources/read', { uri: r.uri });
  const texto = (conteudo.contents || []).map((c) => c.text || '').join('\n');
  const nome = r.uri.replace('pixellab://docs/', '').replace(/\//g, '-') + '.md';
  fs.writeFileSync(path.join(dirRec, nome), `<!-- ${r.uri} — copiado por tools/pixellab-catalogo.mjs; não editar -->\n\n${texto}\n`);
}
console.log(`ferramentas: ${ferramentas.length} · recursos: ${recursos.length}`);
for (const [c, l] of porCat) if (l.length) console.log(`  ${l.length.toString().padStart(3)}  ${c}`);
