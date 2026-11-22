#!/usr/bin/env node
// Guardião offline. Só lê arquivos; sem dependências npm nem acesso ao cofre.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

// Preserva linhas para os diagnósticos e ignora exemplos em blocos de código.
export function semBlocos(texto) {
  let bloco = null;
  return texto.split('\n').map(linha => {
    const cerca = linha.match(/^\s{0,3}(`{3,}|~{3,})(.*)$/);
    if (!bloco && cerca) {
      bloco = cerca[1];
      return '';
    }
    if (bloco) {
      if (cerca && cerca[1][0] === bloco[0] && cerca[1].length >= bloco.length && !cerca[2].trim()) bloco = null;
      return '';
    }
    return linha;
  }).join('\n');
}

function semCodigo(texto) {
  return semBlocos(texto).replace(/(`+)(.*?)\1(?!`)/g, m => ' '.repeat(m.length));
}

function links(texto) {
  // Inline; <destino> permite espaços e parênteses arbitrariamente aninhados.
  const limpo = semCodigo(texto);
  return [...limpo.matchAll(/!?\[[^\]\n]*\]\((?:<([^>\n]+)>|((?:[^()\s]|\([^()\n]*\))+))(?:\s+"[^"\n]*")?\)/g)]
    .map(m => ({ destino: m[1] ?? m[2], linha: limpo.slice(0, m.index).split('\n').length }));
}

function ancora(titulo) {
  return titulo.toLowerCase().replace(/!?\[([^\]]*)\]\([^)]*\)/g, '$1').replace(/<[^>]*>/g, '').replace(/[^\p{L}\p{N}\p{M}_\s-]/gu, '').replace(/\s/g, '-');
}

function ancoras(texto) {
  const resultado = new Set();
  for (const m of semBlocos(texto).matchAll(/^ {0,3}#{1,6}[ \t]+(.+?)(?:[ \t]+#+)?[ \t]*$/gm)) {
    const base = ancora(m[1]);
    let id = base;
    let sufixo = 0;
    while (resultado.has(id)) id = `${base}-${++sufixo}`;
    resultado.add(id);
  }
  return resultado;
}

const numero = v => v.split('.').map(Number).concat([0, 0]).slice(0, 3);
function comparar(a, b) {
  const aa = numero(a), bb = numero(b);
  for (let i = 0; i < 3; i++) if (aa[i] !== bb[i]) return aa[i] - bb[i];
  return 0;
}

export function verificar(arquivos, caminhos) {
  const erros = [];
  const erro = (regra, arquivo, linha, mensagem) => erros.push({ regra, arquivo, linha, mensagem });
  const ler = arquivo => {
    if (!arquivos.has(arquivo)) erro('OBRIGATORIO', arquivo, 1, 'arquivo obrigatório ausente');
    return arquivos.get(arquivo) ?? '';
  };
  const linhaDe = (texto, trecho) => texto.slice(0, Math.max(0, texto.indexOf(trecho))).split('\n').length;

  for (const [arquivo, texto] of arquivos) {
    if (!arquivo.endsWith('.md')) continue;
    for (const { destino, linha } of links(texto)) {
      if (/^(?:[a-z][a-z\d+.-]*:|\/\/)/i.test(destino)) continue;
      let alvo, fragmento;
      try {
        const [nome, ...partes] = destino.split('#');
        alvo = nome ? path.posix.normalize(path.posix.join(path.posix.dirname(arquivo), decodeURIComponent(nome))).replace(/\/$/, '') : arquivo;
        fragmento = decodeURIComponent(partes.join('#'));
      } catch {
        erro('LINK', arquivo, linha, `URL local malformada: ${destino}`);
        continue;
      }
      if (!caminhos.has(alvo)) {
        erro('LINK', arquivo, linha, `destino local ausente: ${destino}`);
      } else if (fragmento && alvo.endsWith('.md') && arquivos.has(alvo) && !ancoras(arquivos.get(alvo)).has(fragmento)) {
        erro('ANCORA', arquivo, linha, `seção ausente: ${destino}`);
      }
    }
  }

  const h = 'docs/HISTORICO.md', historico = semBlocos(ler(h));
  if (!historico.startsWith('# Histórico\n') || (historico.match(/^# Histórico$/gm) ?? []).length !== 1) {
    erro('HISTORICO', h, 1, 'deve começar com um único título # Histórico');
  }
  const versoes = [];
  for (const m of historico.matchAll(/^##[ \t]+.*$/gm)) {
    const titulo = m[0].match(/^## v(\d+\.\d+\.\d+) — .+ \(\d{4}-\d{2}-\d{2}\)$/);
    if (!titulo) erro('VERSAO', h, linhaDe(historico, m[0]), 'cabeçalho inválido; use ## vX.Y.Z — título (AAAA-MM-DD)');
    else versoes.push(titulo[1]);
  }
  if (!versoes.length) erro('VERSAO', h, 1, 'histórico sem versão válida');
  for (let i = 1; i < versoes.length; i++) {
    if (comparar(versoes[i - 1], versoes[i]) <= 0) erro('VERSAO', h, 1, `versões repetidas ou fora de ordem: ${versoes[i - 1]} / ${versoes[i]}`);
  }
  const residuos = semBlocos(ler('docs/RESIDUOS.md'));
  const registradas = [...residuos.matchAll(/^\| v(\d+\.\d+\.\d+) \|/gm)].map(m => m[1]);
  if (versoes.length && !registradas.includes(versoes[0])) erro('RESIDUOS', 'docs/RESIDUOS.md', 1, `falta registro da versão atual v${versoes[0]}`);

  const fila = 'docs/PEDIDOS-EM-ESPERA.md', pedidos = semBlocos(ler(fila));
  const indice = [...pedidos.matchAll(/^\| (P\d+) \|/gm)].map(m => m[1]);
  const secoes = [...pedidos.matchAll(/^## (P\d+) — /gm)].map(m => m[1]);
  if (!indice.length) erro('PACOTES', fila, 1, 'índice de pacotes ausente');
  for (const [origem, lista, outra] of [['índice', indice, secoes], ['seção', secoes, indice]]) {
    for (const id of new Set(lista)) {
      if (lista.filter(x => x === id).length !== 1 || !outra.includes(id)) erro('PACOTES', fila, 1, `${id}: ${origem} duplicado ou sem correspondente`);
    }
  }

  const contrato = 'AGENTS.md', agentes = ler(contrato);
  const mapa = semBlocos(agentes).match(/^### Mapa documental\n([\s\S]*?)(?=^#{1,3} |$(?![\s\S]))/m)?.[1] ?? '';
  if (!mapa) erro('MAPA', contrato, 1, 'seção ### Mapa documental ausente');
  const listados = links(mapa).map(l => {
    try { return path.posix.normalize(decodeURIComponent(l.destino.split('#')[0])); }
    catch { return l.destino; } // A regra LINK já explica o escape malformado.
  });
  // As referências externas vendorizadas têm inventário próprio no catálogo.
  const docs = [...arquivos.keys()].filter(f => f.startsWith('docs/') && f.endsWith('.md') && !f.startsWith('docs/pixellab/recursos/'));
  for (const arquivo of docs) {
    if (listados.filter(x => x === arquivo).length !== 1) erro('MAPA', contrato, 1, `${arquivo}: deve aparecer uma única vez no mapa documental`);
  }
  for (const arquivo of listados.filter(f => f.endsWith('.md'))) {
    if (!docs.includes(arquivo)) erro('MAPA', contrato, 1, `entrada não pertence ao inventário: ${arquivo}`);
  }
  const claude = ler('CLAUDE.md');
  if (!links(claude).some(l => l.destino === 'AGENTS.md')) erro('PONTEIRO', 'CLAUDE.md', 1, 'deve apontar para AGENTS.md');

  const g = 'docs/gdd/gestos-e-acoes.md', gdd = semCodigo(ler(g));
  const revisao = gdd.split('\n').slice(0, 6).join('\n').match(/\*\*v(\d+\.\d+\.\d+)\.\*\*/)?.[1];
  const mencoes = [...gdd.matchAll(/\bv(\d+\.\d+(?:\.\d+)?)/g)].map(m => m[1]);
  if (!revisao || !versoes.includes(revisao) || mencoes.some(v => comparar(v, revisao) > 0)) {
    erro('REVISAO', g, 1, 'marcador de revisão ausente, desconhecido ou anterior às versões descritas');
  }
  let gestos;
  try { gestos = JSON.parse(ler('dados/gestos.json')).mapa; } catch { /* diagnóstico abaixo */ }
  const conceito = semCodigo(ler('docs/CONCEITO.md')).replace(/[*`]/g, '');
  const tabela = gdd.replace(/[*`]/g, '');
  for (const [id, nome] of [['toque', 'toque simples'], ['toque_duplo', 'toque duplo']]) {
    const acao = gestos?.[id];
    if (typeof acao !== 'string' || !acao) {
      erro('GESTOS', 'dados/gestos.json', 1, `mapa.${id} ausente ou inválido`);
      continue;
    }
    const esperado = acao === 'pular' ? 'pulo' : acao;
    const resumo = [...conceito.matchAll(new RegExp(`${nome}\\s*=\\s*(\\p{L}+)`, 'giu'))];
    const linhas = [...tabela.matchAll(new RegExp(`^\\| ${nome} \\| (\\p{L}+)`, 'gimu'))];
    for (const [arquivo, resultados] of [['docs/CONCEITO.md', resumo], [g, linhas]]) {
      if (resultados.length !== 1 || resultados[0][1].toLowerCase() !== esperado) erro('GESTOS', arquivo, 1, `${nome} deve corresponder a dados/gestos.json: ${esperado}`);
    }
  }
  return erros;
}

export function carregar(raiz) {
  const nomes = execFileSync('git', ['ls-files', '--cached', '--others', '--exclude-standard', '-z'], { cwd: raiz, encoding: 'utf8' }).split('\0').filter(Boolean);
  const arquivos = new Map(), caminhos = new Set();
  for (const nome of new Set(nomes)) {
    if (!fs.existsSync(path.join(raiz, nome))) continue;
    caminhos.add(nome);
    for (let pai = path.posix.dirname(nome); pai !== '.'; pai = path.posix.dirname(pai)) caminhos.add(pai);
    if (nome.endsWith('.md') || nome === 'dados/gestos.json') arquivos.set(nome, fs.readFileSync(path.join(raiz, nome), 'utf8'));
  }
  return { arquivos, caminhos };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const raiz = fileURLToPath(new URL('../', import.meta.url));
    const { arquivos, caminhos } = carregar(raiz);
    const erros = verificar(arquivos, caminhos);
    for (const e of erros) console.error(`${e.arquivo}:${e.linha}: [${e.regra}] ${e.mensagem}`);
    console.log(`docs: ${[...arquivos.keys()].filter(f => f.endsWith('.md')).length} Markdown, ${erros.length} erro(s)`);
    process.exitCode = erros.length ? 1 : 0;
  } catch (e) {
    console.error(`docs: não foi possível verificar: ${e.message}`);
    process.exitCode = 1;
  }
}
