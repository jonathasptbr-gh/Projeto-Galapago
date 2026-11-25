# Guardião da documentação

## Como rodar

- `tools/docs.sh`: verificação offline + testes do próprio guardião; só Bash,
  Git e Node.js (sem npm install, Godot, rede ou credenciais).
- `tools/testes.sh`: começa pelo comando acima; falha documental encerra a
  suíte com código não zero ANTES de importar o Godot. O CI já chama essa
  suíte; um erro impede o job de APK, que depende dela.
- Implementação: [`docs.mjs`](../tools/docs.mjs). Testes:
  [`docs.test.mjs`](../tools/docs.test.mjs): fixtures em memória e uma
  integração em clone sintético temporário sob `~/tmp/` (removido ao terminar).
  Não alteram a documentação real. A integração comprova o código de saída
  e que um Godot falso NÃO é invocado se a documentação reprovar. Saída:
  `arquivo:linha: [REGRA] motivo` e resumo.

## O que é verificado

1. **Links locais Markdown inline**, inclusive imagens: arquivo/diretório
   existente; fragmentos para títulos ATX (`# Título`) em Markdown. Respeita
   Unicode, caminhos relativos, escapes URL, destinos entre `< >`, títulos
   repetidos, código inline e blocos cercados por crases ou tils. Destinos com
   vários níveis de parênteses devem usar `< >`. Links externos não são
   consultados.
2. **Histórico:** um único `# Histórico` na primeira linha; títulos no formato
   `## vX.Y.Z — título (AAAA-MM-DD)`, versões únicas em ordem decrescente.
   Exceção: `## Não publicado` (notas dos commits comuns), só como a PRIMEIRA
   seção e uma vez. A primeira `## vX.Y.Z` é a versão publicada, fonte para
   estado/export/preview; não há outra versão fixa para manter em sincronia.
   O guardião não consulta o CI nem exige que o título do commit já exista.
3. **Resíduos:** existe registro da versão publicada atual (a primeira
   `## vX.Y.Z`), inclusive quando é "nenhum". Não decide se o resíduo está
   resolvido.
4. **Fila:** correspondência um a um entre `| Pn |` no índice e
   `## Pn — título` no corpo; sem IDs repetidos. Não escolhe o próximo pacote
   nem converte a fila em autorização.
5. **Mapa documental:** cada Markdown de `docs/` aparece uma única vez na
   seção `### Mapa documental` do [`AGENTS.md`](../AGENTS.md). Use links com
   caminho completo a partir da raiz do repo, sem abreviar nomes. As cópias
   externas em `docs/pixellab/recursos/` ficam fora desse inventário, pois o
   [`catálogo`](pixellab/CATALOGO.md) já as lista; seus links continuam sendo
   verificados. Novos arquivos não ignorados entram na verificação mesmo
   antes do `git add`; caches/ignorados não entram.
6. **Ponteiro:** [`CLAUDE.md`](../CLAUDE.md) contém link para o contrato.
7. **Revisão do GDD de gestos:** seu marcador `**vX.Y.Z.**` nas primeiras
   seis linhas pertence ao histórico e não é anterior às versões citadas
   no documento. Patch só de documentação não obriga revisar design.
8. **Toques simples/duplo:** o resumo `toque simples = TIRO` / `toque duplo =
   PULO` do [`CONCEITO`](CONCEITO.md) e as respectivas linhas da tabela do
   [`GDD`](gdd/gestos-e-acoes.md) devem acompanhar `mapa.toque` e
   `mapa.toque_duplo` de [`gestos.json`](../dados/gestos.json). `pular` é
   apresentado como `PULO`. Formato removido/duplicado também reprova.

## Limites deliberados

Não é um interpretador geral de Markdown: não valida links de referência
(`[texto][id]`), HTML, títulos Setext ou âncoras HTML manuais. Para navegação
local use links inline e títulos ATX, como os guias deste projeto. Não faz
checagem gramatical nem prova que toda frase de design corresponde ao código:
a verificação de significado é limitada aos dois toques. Não examina toda a
árvore de código a partir do desenho livre da seção Estrutura; o inventário
validado é o mapa documental explícito. API externa, assinatura do APK,
conflitos entre agentes e regressões visuais não são verificados aqui.

O guardião só lê o clone e devolve erro; nunca corrige, regrava o inventário,
commita ou publica por conta própria. Uma falha não autoriza mudar o design:
confira a fonte da regra e pergunte ao operador quando houver decisão nova.
