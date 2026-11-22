# Projeto Galápago — o contrato

> **O REPOSITÓRIO É PÚBLICO** (desde a v0.3.1, decisão do operador). Tudo que
> se commita fica visível para sempre, inclusive no histórico: segredo nenhum
> em arquivo, nunca — token, chave do PixelLab, keystore, senha.

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
  (`extends "res://testes/caso.gd"`). `tools/testes.sh` antes de commitar:
  começa pelo guardião documental (`tools/docs.sh`, offline); guia e limites
  no mapa documental abaixo.
- **Mudança visível passa pelo oráculo** ([`ORACULO`](docs/ORACULO.md)):
  `tools/quadros.sh` e **abrir** os PNG antes de dizer que ficou certo.
- **Arte** segue [`ARTE`](docs/ARTE.md): paleta-mestra, âncora de estilo,
  validação por script. Chamada ao PixelLab custa dinheiro do operador: cotar
  antes (`search_help`, `get_pro_flash_capabilities`), gerar o mínimo, nunca em
  laço sem teto. **Qual ferramenta para qual tarefa:**
  [`PIXELLAB`](docs/PIXELLAB.md); lista completa (140, gerada da fonte):
  [`pixellab/CATALOGO`](docs/pixellab/CATALOGO.md).
- **Godot:** [`GODOT`](docs/GODOT.md) (comandos, arquivos, convenções, pixel
  art, toque, export Android). API desta versão: `tools/godot-api.sh <Classe>`
  — não escreva API do Godot de memória.
- **Entrega direto em `main`**, pelo rito de [`BUILD`](docs/BUILD.md):
  `git add <caminhos>` (nunca `-A`), commit `vX.Y.Z: <resumo>`,
  `git push origin main`, CI verde (`tools/estado.sh --ci`; vermelho →
  `node tools/ci-log.mjs`), APK em `node tools/baixar-apk.mjs`.
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
project.godot         configuração (720x1280 canvas_items, arte nearest, RETRATO, ETC2/ASTC)
export_presets.cfg    preset Android (arm64, sem Gradle)
CLAUDE.md             ponteiro de uma linha para este arquivo (Claude Code)
sim/                  lógica pura: gestos (1 dedo: caminho, toque, toque duplo,
                       segurar=habilidade) · formas (laço/bico do desenho) ·
                       comandos · corpo (traço ao vivo+waypoints+overlays+
                       marcas de ataque+autonomia) · alvos · adversario
                       (passeio, hostilidade, preparo+área, esconder) · mundo ·
                       trajetoria (desconto+RDP) ·
                       visibilidade · atualizacao · mapa (Wang, parado)
jogo/                 main · criatura · adversario_mock · perigos (área no chão) ·
                       mira (mira+alvo final) · trilha · efeitos (onda/tiro) ·
                       hud · demo · mock ·
                       atualizador · camadas/ (chao, subsolo, copa, parallax,
                       objeto_mock)
dados/                gestos.json · acoes.json · adversario.json · terrenos.json · mapas/
testes/               run.gd (executor), caso.gd (base), test_*.gd
tools/                estado.sh · testes.sh · docs.sh (docs.mjs + docs.test.mjs) ·
                      quadros.sh · godot-api.sh · ci-log.mjs · baixar-apk.mjs ·
                      pixellab-catalogo.mjs · pixellab-tileset.mjs ·
                      pixellab-imagem.mjs · android/ (exportar.sh)
arte/                 README.md · fonte/ (bruto da IA, .gdignore) ·
                      criaturas/ · cenarios/ (tilesets/ PNG+JSON, objetos/)
docs/                 guias e design — inventário validado abaixo
.github/workflows/    ci.yml (testes + quadros → APK + versao.json na Release `dev`)
```

### Mapa documental

Consulta por tarefa; este inventário é validado por `tools/docs.sh` (cada guia
uma vez). Referências externas vendorizadas ficam no catálogo, não se repetem.

- Design: [conceito](docs/CONCEITO.md), [gestos e ações](docs/gdd/gestos-e-acoes.md), [mapa](docs/gdd/mapa.md).
- Código e ambiente: [arquitetura](docs/ARQUITETURA.md), [Godot](docs/GODOT.md), [ambiente](docs/AMBIENTE.md).
- Verificação e entrega: [oráculo](docs/ORACULO.md), [build](docs/BUILD.md), [guardião documental](docs/DOCUMENTACAO.md).
- Arte: [pipeline](docs/ARTE.md), [PixelLab](docs/PIXELLAB.md), [catálogo gerado](docs/pixellab/CATALOGO.md).
- Continuidade: [fila](docs/PEDIDOS-EM-ESPERA.md), [histórico](docs/HISTORICO.md), [resíduos](docs/RESIDUOS.md).
