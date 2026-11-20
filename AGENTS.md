# Projeto Galápago — o contrato

Jogo indie mobile de criaturas com evolução por vivência, em **Godot 4.7.2**,
arte via **PixelLab** (MCP). O conceito está em
[`docs/CONCEITO.md`](docs/CONCEITO.md). Este arquivo é o que se decide antes de
tocar em nada; o resto é consulta por âncora.

## Antes de trabalhar, nesta ordem

1. `tools/estado.sh --ci` — versão, HEAD, Godot, último CI. Número que ele não
   imprimiu nesta sessão não se cita.
2. Este arquivo, inteiro (é curto de propósito).
3. A fila: [`docs/PEDIDOS-EM-ESPERA.md`](docs/PEDIDOS-EM-ESPERA.md) — lê-se o
   índice e **só o pacote escolhido**. Nada está autorizado por estar na fila:
   **pergunte qual pacote seguir.**

## A conversa com o operador

Quem lê o chat **não programa**; decide o jogo. Fala-se para **perguntar** o
que não dá para decidir sozinho e para **entregar**. O relatório de entrega é
de leigo, curto, pelo que ele VÊ ou FAZ — e nunca omite:

- **o que ele precisa fazer** (instalar, testar, aprovar uma arte — ou nada);
- **o que não deu certo** (falha dita, escopo cortado dito com o porquê).

Isso vale para o CHAT. `AGENTS.md`, `docs/` e commits são técnicos e densos:
quem os lê é o agente seguinte.

Decisão de **design** (como a criatura se comporta, o que a história diz, como
a arte fica) é do operador: o agente propõe com opções, não decide calado.

## Regras de desenvolvimento

- **Duas camadas** ([`ARQUITETURA`](docs/ARQUITETURA.md)): `sim/` é lógica pura
  e testável (sem nó, sem `Input`, sem sorteio global); `jogo/` lê toque e
  desenha. Regra de jogo fora da `sim/` é regressão.
- **Todo código da `sim/` nasce com teste** em `testes/test_*.gd`
  (`extends "res://testes/caso.gd"`). `tools/testes.sh` antes de commitar.
- **Mudança visível passa pelo oráculo** ([`ORACULO`](docs/ORACULO.md)):
  `tools/quadros.sh` e **abrir** os PNG antes de dizer que ficou certo.
- **Arte** segue [`ARTE`](docs/ARTE.md): paleta-mestra, âncora de estilo,
  validação por script. Chamada ao PixelLab custa dinheiro do operador: cotar
  antes (`get_*_capabilities`), gerar o mínimo, nunca em laço sem teto.
- **Entrega direto em `main`.** `git add <caminhos>` (nunca `-A`), commit
  `vX.Y.Z: <resumo>`, `git push origin main`, depois conferir o CI
  (`tools/estado.sh --ci`).
- **Versão** em três casas: a 3ª conserta, a 2ª entrega sistema/pacote, a 1ª é
  marco público (demo). A nota do lote mora em
  [`docs/HISTORICO.md`](docs/HISTORICO.md) (seção `## vX.Y.Z` no topo).
- **O lote declara o que deixou para trás** em
  [`docs/RESIDUOS.md`](docs/RESIDUOS.md), mesmo que seja "nenhum".
- Versões do Godot local e do CI andam juntas ([`AMBIENTE`](docs/AMBIENTE.md)).
- **Segredos** (token GitHub, chave PixelLab, keystore): só no cofre do harness
  ou em *secret* do GitHub — nunca em chat, commit ou documento.
- `/sdcard`: criar, mover ou apagar só avisando o operador; entregas visuais
  vão para `/sdcard/Download/DSH-Go/`.

## Estrutura

```
project.godot         configuração (320x180, gl_compatibility, paisagem)
sim/                  lógica pura (trajetória, depois gestos, afinidade, evolução)
jogo/                 cenas e apresentação
testes/               run.gd (executor), caso.gd (base), test_*.gd
tools/                estado.sh · testes.sh · quadros.sh
arte/                 fonte/ (bruto da IA) · criaturas/ · cenarios/
docs/                 CONCEITO · ARQUITETURA · ORACULO · ARTE · AMBIENTE ·
                      PEDIDOS-EM-ESPERA · HISTORICO · RESIDUOS · gdd/
.github/workflows/    ci.yml (testes + quadros; APK no pacote P2)
```
