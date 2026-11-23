# Protocolo de agentes — gerente e trabalhadores

> **2026-11-22 · regra de trabalho, não estudo.** Toda sessão age como
> **GERENTE**: entende o problema, fatia o trabalho e terceiriza para
> subagentes de **contexto fresco**; o trabalhador não fala com o operador.

## O gerente

- Lê o contrato do repositório ([`AGENTS.md`](../AGENTS.md)) e a fila antes de
> fatiar: o briefing nasce do problema, não do histórico do chat.
- Divide em **briefings autocontidos**: cada um cabe numa janela e não depende
> de o trabalhador ter lido esta conversa.
- **Delega e confere EVIDÊNCIA**, não relato: hash/commit, saída de teste, URL
> do CI, `git diff --check`. "Ficou pronto" sem prova volta como pendência.
- Não reexplica o projeto a cada agente: o que os dois precisam saber está nos
> guias, e o briefing aponta o guia e o trecho.
- Trabalho pequeno o gerente **faz**: delegar custa fatia e retorno (adiante).

## O briefing do trabalhador

Todo briefing tem cinco campos, nesta ordem:

1. **Objetivo:** o resultado observável, em uma frase.
2. **Arquivos e caminhos:** o que ler e o que editar, pelo caminho completo.
3. **Restrições:** o que não tocar (jogo, dados, testes, CI, `.godot/`), o
   estilo do repositório e o rito ([`BUILD`](BUILD.md)).
4. **Verificação:** o comando exato que prova o trabalho (`tools/docs.sh`,
   `tools/testes.sh`) e a saída esperada.
5. **Resposta:** o formato do retorno e o que **não** fazer (commit, `-A`,
   `checkout`/`reset`/`stash` — ver [`MULTI-AGENTE`](MULTI-AGENTE.md)).

Contexto fresco é o ponto: o trabalhador recebe o briefing, não o chat. O que
falta no briefing é falha do gerente, não do trabalhador.

## Critério de aceite e teto de reparo

- Todo lote começa com **critério de aceite observável** — uma frase do que o
  operador vê ou faz de diferente. Ele abre o briefing e o PR (template em
  `.github/PULL_REQUEST_TEMPLATE.md`).
- **Iteração seletiva:** `tools/verificar.sh` (só as áreas tocadas); o commit
  é gated por `tools/testes.sh` inteiro. Rodar a suíte inteira a cada passo é
  caro e não prova mais.
- **Teto de auto-reparo: 3 tentativas ou 20 minutos** no mesmo erro → pare,
  diga o comando que falhou, a saída e o que já tentou. Laço mudando código no
  escuro não é progresso.
- **WIP:** um lote com PR aberto por vez no repositório; um escritor por clone
  ([`MULTI-AGENTE`](MULTI-AGENTE.md)).
- Falha de CI que não é do lote (runner, rede, artefato): `node tools/ci-log.mjs`
  e `tools/estado.sh --metricas` antes de repetir o push.

## Quando não delegar

- Correção de **uma linha** ou de um link: o custo de briefar é maior que o de
  fazer.
- Decisão que **depende do operador** (design, arte, dinheiro, autorização):
  é conversa, não tarefa.
- Tarefa que **precisa da conversa inteira**: o gerente faz e registra no `docs/`.

## Paralelismo

- **Leitura** pode ser paralela: N agentes leem N trechos e devolvem resumo.
- **Escrita:** UM escritor por repositório por vez; commits serializados. Dois
  agentes no mesmo clone só com o protocolo de
  [`MULTI-AGENTE`](MULTI-AGENTE.md) e um lote por vez.
- O gerente não entrega ao CI um lote que ainda pode mudar: merge antes do `push`.

## Orçamento de contexto

- Não colar log inteiro: citar `arquivo:linha` e as 3–5 linhas que importam.
- **Uma fatia por agente**; o gerente mantém a janela pequena e a evidência em
  arquivo (`git diff`, saída de teste), não em colagem.
- O briefing diz o que **não** ler também: varrer o repo é gasto sem retorno.

## Handoff de volta

O trabalhador devolve, no formato pedido:

- **o que fez** (arquivos tocados, caminhos);
- **como provou** (comandos e resultados — teste, hash, CI);
- **o que não fez** e por quê (bloqueio, corte de escopo, decisão pendente).

Gerente que não consegue repetir a prova no clone não aceita o handoff.

## Falha

- Falhou? **Fatiar de novo** — briefing menor, com o erro citado — em vez de
  reexplicar o projeto inteiro.
- **Condição bloqueante** é dita na primeira linha, com o comando que falhou e a
  saída; não se improvisa contorno que fura o rito.
- Trabalhador que descobre briefing errado **para** e pergunta; não decide design.

## O relatório ao operador

O gerente responde em **linguagem de leigo**, como manda o
[`AGENTS.md`](../AGENTS.md): o que o operador vê ou faz, o que não deu certo, o
que precisa aprovar; detalhe técnico fica no commit e no `docs/`.
