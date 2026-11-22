import assert from 'node:assert/strict';
import { test } from 'node:test';
import { verificar, carregar } from './docs.mjs';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

// Fixtures em memória: nenhum teste altera o clone, lê segredos ou usa rede.
function base() {
  const arquivos = new Map([
    ['docs/HISTORICO.md', '# Histórico\n\n## v0.2.0 — Atual (2026-11-22)\n\n## v0.1.0 — Início (2026-11-20)\n'],
    ['docs/RESIDUOS.md', '# Resíduos\n\n| v0.2.0 | docs | nenhum | — |\n'],
    ['docs/PEDIDOS-EM-ESPERA.md', '# Pedidos\n\n| P1 | feito |\n\n## P1 — Primeiro\n'],
    ['docs/CONCEITO.md', '# Conceito\n\n**toque simples** = **TIRO**; **toque duplo** = **PULO**.\n'],
    ['docs/gdd/gestos-e-acoes.md', '# Gestos\n\n> **v0.2.0.**\n\n| **toque simples** | **TIRO** |\n| **toque duplo** | **PULO** |\n'],
    ['CLAUDE.md', 'Leia [AGENTS](AGENTS.md).\n'],
    ['dados/gestos.json', JSON.stringify({ mapa: { toque: 'tiro', toque_duplo: 'pular' } })],
  ]);
  arquivos.set('AGENTS.md', '# Contrato\n\n### Mapa documental\n\n' + [...arquivos.keys()].filter(f => f.startsWith('docs/')).map(f => `- [${f}](${f})`).join('\n') + '\n');
  return { arquivos, caminhos: new Set(arquivos.keys()) };
}
function resultados(modificar) {
  const estado = base();
  modificar(estado.arquivos, estado.caminhos);
  return verificar(estado.arquivos, estado.caminhos);
}
function trocar(arquivos, arquivo, antes, depois) {
  assert.ok(arquivos.get(arquivo).includes(antes), `fixture mudou: ${arquivo}: ${antes}`);
  arquivos.set(arquivo, arquivos.get(arquivo).replace(antes, depois));
}
const rejeita = (nome, regra, modificar) => test(nome, () => {
  const erros = resultados(modificar);
  assert.ok(erros.some(e => e.regra === regra), JSON.stringify(erros));
});
const aceita = (nome, modificar) => test(nome, () => assert.deepEqual(resultados(modificar), []));

aceita('documentação coerente passa', () => {});
rejeita('link local ausente reprova', 'LINK', a => a.set('README.md', '[não](sumiu.md)'));
rejeita('seção local ausente reprova', 'ANCORA', a => a.set('README.md', '[não](docs/CONCEITO.md#sumiu)'));
rejeita('URL com escape inválido reprova', 'LINK', a => a.set('README.md', '[não](%ZZ.md)'));
aceita('links externos não exigem rede', a => a.set('README.md', '[web](https://exemplo.invalid/a#b) [email](mailto:x@exemplo.invalid)'));
aceita('cerca de código não cria links nem títulos', a => a.set('README.md', '```md\n[não](sumiu.md)\n# Fantasma\n```\n~~~md\n[não](outro.md)\n~~~\n'));
aceita('links Unicode, espaços, subpastas e headings repetidos', (a, c) => {
  const nome = 'docs/pixellab/recursos/referência teste.md';
  a.set(nome, '# Ação — título\n\n## Igual\n## Igual\n[local](#igual-1)\n[volta](../../CONCEITO.md#conceito)\n');
  c.add(nome);
  a.set('README.md', '[ref](<docs/pixellab/recursos/refer%C3%AAncia%20teste.md#a%C3%A7%C3%A3o--t%C3%ADtulo>)');
});
aceita('link a diretório existente passa', (a, c) => { c.add('docs'); a.set('README.md', '[docs](docs/)'); });
test('linha do link continua correta depois de um bloco', () => {
  const erros = resultados(a => a.set('README.md', '```\ntexto longo descartado\n```\n[não](sumiu.md)\n'));
  assert.ok(erros.some(e => e.regra === 'LINK' && e.linha === 4));
});
rejeita('título do histórico fora do topo reprova', 'HISTORICO', a => trocar(a, 'docs/HISTORICO.md', '# Histórico\n', '\n# Histórico\n'));
rejeita('título do histórico duplicado reprova', 'HISTORICO', a => a.set('docs/HISTORICO.md', a.get('docs/HISTORICO.md') + '# Histórico\n'));
rejeita('cabeçalho de versão duplicado na mesma linha reprova', 'VERSAO', a => trocar(a, 'docs/HISTORICO.md', '## v0.1.0 —', '## v0.1.0## v0.1.0 —'));
rejeita('versão mais nova enterrada reprova', 'VERSAO', a => a.set('docs/HISTORICO.md', a.get('docs/HISTORICO.md') + '\n## v0.3.0 — Nova (2026-11-22)\n'));
rejeita('versão repetida reprova', 'VERSAO', a => a.set('docs/HISTORICO.md', a.get('docs/HISTORICO.md') + '\n## v0.1.0 — Outra (2026-11-20)\n'));
rejeita('versão sem resíduos reprova', 'RESIDUOS', a => a.set('docs/RESIDUOS.md', '# Resíduos\n'));
rejeita('pacote do índice sem seção reprova', 'PACOTES', a => trocar(a, 'docs/PEDIDOS-EM-ESPERA.md', '## P1 — Primeiro', '## P2 — Outro'));
rejeita('pacote com seção duplicada reprova', 'PACOTES', a => a.set('docs/PEDIDOS-EM-ESPERA.md', a.get('docs/PEDIDOS-EM-ESPERA.md') + '\n## P1 — Duplicado\n'));
rejeita('pacote com índice duplicado reprova', 'PACOTES', a => trocar(a, 'docs/PEDIDOS-EM-ESPERA.md', '| P1 | feito |', '| P1 | feito |\n| P1 | repetido |'));
rejeita('guia novo fora do mapa reprova', 'MAPA', (a, c) => { a.set('docs/NOVO.md', '# Novo\n'); c.add('docs/NOVO.md'); });
rejeita('guia duplicado no mapa reprova', 'MAPA', a => a.set('AGENTS.md', a.get('AGENTS.md') + '\n[Conceito](docs/CONCEITO.md)\n'));
rejeita('mapa ausente reprova', 'MAPA', a => trocar(a, 'AGENTS.md', '### Mapa documental', '### Outro'));
rejeita('ponteiro do Claude removido reprova', 'PONTEIRO', a => a.set('CLAUDE.md', '# Outro\n'));
rejeita('arquivo obrigatório ausente reprova', 'OBRIGATORIO', (a, c) => { a.delete('CLAUDE.md'); c.delete('CLAUDE.md'); });
rejeita('GDD descreve versão posterior ao marcador', 'REVISAO', a => a.set('docs/gdd/gestos-e-acoes.md', a.get('docs/gdd/gestos-e-acoes.md') + '\n## Novidade v0.3\n'));
rejeita('GDD com revisão inexistente reprova', 'REVISAO', a => trocar(a, 'docs/gdd/gestos-e-acoes.md', 'v0.2.0.', 'v9.9.9.'));
aceita('patch documental não obriga atualizar a revisão de design', a => {
  a.set('docs/HISTORICO.md', a.get('docs/HISTORICO.md').replace('\n## v0.2.0', '\n## v0.2.1 — Documentação (2026-11-22)\n\n## v0.2.0'));
  a.set('docs/RESIDUOS.md', a.get('docs/RESIDUOS.md') + '\n| v0.2.1 | docs | nenhum | — |\n');
});
rejeita('inverter toques no CONCEITO reprova', 'GESTOS', a => trocar(a, 'docs/CONCEITO.md', '= **TIRO**', '= **PULO**'));
rejeita('inverter toques no GDD reprova', 'GESTOS', a => trocar(a, 'docs/gdd/gestos-e-acoes.md', '| **TIRO**', '| **PULO**'));
rejeita('mudança na tabela real exige atualizar docs', 'GESTOS', a => a.set('dados/gestos.json', JSON.stringify({ mapa: { toque: 'pular', toque_duplo: 'tiro' } })));
rejeita('JSON de gestos inválido reprova', 'GESTOS', a => a.set('dados/gestos.json', '{'));
rejeita('descrição duplicada do gesto reprova', 'GESTOS', a => a.set('docs/CONCEITO.md', a.get('docs/CONCEITO.md') + '\ntoque simples = tiro\n'));
aceita('exemplo de link em código inline não é navegação', a => a.set('README.md', 'Sintaxe: `[texto](sumiu.md)`.\n'));
aceita('título com link usa só o texto visível na âncora', a => {
  a.set('docs/CONCEITO.md', a.get('docs/CONCEITO.md') + '\n## [Primeiro](#conceito)\n  ## Extra\n');
  a.set('README.md', '[um](docs/CONCEITO.md#primeiro) [dois](docs/CONCEITO.md#extra)');
});
aceita('parênteses balanceados no destino', (a, c) => {
  const nome = 'docs/pixellab/recursos/guia(teste).md';
  a.set(nome, '# Guia\n'); c.add(nome);
  a.set('README.md', '[guia](docs/pixellab/recursos/guia(teste).md)');
});
aceita('versão de exemplo em bloco não vira release', a => a.set('docs/HISTORICO.md', a.get('docs/HISTORICO.md') + '\n```md\n## v9.0.0 — Exemplo (2026-11-22)\n```\n'));
rejeita('resíduos de exemplo não contam como registro', 'RESIDUOS', a => a.set('docs/RESIDUOS.md', '# Resíduos\n```md\n| v0.2.0 | docs | nenhum | — |\n```\n'));
rejeita('gestos de exemplo não contam como resumo real', 'GESTOS', a => a.set('docs/CONCEITO.md', '```md\n' + a.get('docs/CONCEITO.md') + '```\n'));
rejeita('mapa de exemplo não conta como seção real', 'MAPA', a => a.set('AGENTS.md', '```md\n' + a.get('AGENTS.md') + '```\n'));
aceita('versão futura de exemplo não envelhece o GDD', a => a.set('docs/gdd/gestos-e-acoes.md', a.get('docs/gdd/gestos-e-acoes.md') + '\n```md\n## Proposta v9.0\n```\n'));
rejeita('release sem prefixo v reprova', 'VERSAO', a => trocar(a, 'docs/HISTORICO.md', '## v0.2.0', '## 0.2.0'));
aceita('inventário normaliza caminhos relativos e escapes', (a, c) => {
  trocar(a, 'AGENTS.md', '(docs/CONCEITO.md)', '(./docs/CONCEITO.md)');
  a.set('docs/ação nova.md', '# Ação\n'); c.add('docs/ação nova.md');
  a.set('AGENTS.md', a.get('AGENTS.md') + '\n[ação](docs/a%C3%A7%C3%A3o%20nova.md)\n');
});

test('Git, CLI e suíte: não ignorados entram; erro encerra antes do Godot', t => {
  const pai = path.join(os.homedir(), 'tmp');
  fs.mkdirSync(pai, { recursive: true });
  const raiz = fs.mkdtempSync(path.join(pai, 'galapago-docs-test-'));
  t.after(() => {
    assert.equal(path.dirname(raiz), pai);
    assert.ok(path.basename(raiz).startsWith('galapago-docs-test-'));
    fs.rmSync(raiz, { recursive: true, force: true });
  });
  const gravar = (nome, texto, modo = 0o644) => {
    fs.mkdirSync(path.dirname(path.join(raiz, nome)), { recursive: true });
    fs.writeFileSync(path.join(raiz, nome), texto, { mode: modo });
  };
  for (const [nome, texto] of base().arquivos) gravar(nome, texto);
  gravar('.gitignore', '*.ignorado.md\n');
  for (const nome of ['docs.mjs', 'docs.sh', 'testes.sh']) {
    gravar(`tools/${nome}`, fs.readFileSync(new URL(`./${nome}`, import.meta.url)), 0o755);
  }
  const executar = (comando, args, env = process.env) => {
    const r = spawnSync(comando, args, { cwd: raiz, encoding: 'utf8', env });
    assert.ifError(r.error);
    return r;
  };
  assert.equal(executar('git', ['init', '-q']).status, 0);
  assert.equal(executar('git', ['add', 'docs/CONCEITO.md']).status, 0);
  gravar('rascunho.ignorado.md', '[não](sumiu.md)');
  let carregados = carregar(raiz);
  assert.ok(carregados.arquivos.has('docs/CONCEITO.md')); // rastreado
  assert.ok(carregados.arquivos.has('CLAUDE.md')); // ainda não adicionado
  assert.ok(!carregados.arquivos.has('rascunho.ignorado.md'));
  assert.equal(executar(process.execPath, ['tools/docs.mjs']).status, 0);
  gravar('README.md', '[não](sumiu.md)');
  const falha = executar(process.execPath, ['tools/docs.mjs']);
  assert.equal(falha.status, 1);
  assert.match(falha.stderr, /README\.md:1: \[LINK\]/);
  const marcador = path.join(raiz, 'godot-foi-chamado');
  gravar('godot-falso', '#!/usr/bin/env bash\nprintf sim > "$MARCADOR"\nexit 0\n', 0o755);
  const suite = executar('bash', ['tools/testes.sh'], { ...process.env, GODOT: path.join(raiz, 'godot-falso'), MARCADOR: marcador });
  assert.equal(suite.status, 1);
  assert.ok(!fs.existsSync(marcador), 'Godot não pode rodar se a documentação reprovar');
});
