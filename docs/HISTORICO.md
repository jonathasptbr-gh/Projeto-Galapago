# Histórico

> Apêndice: a entrada mais nova em cima. Uma seção por versão, escrita uma vez
> no lote. Lê-se por `grep`, nunca inteiro.

## v0.1.1 — PixelLab conectado, P1 (2026-11-20)

- Chave do operador (chegou pelo chat) → cofre `refs.PIXELLAB_TOKEN`; validada
  antes de configurar (MCP `initialize` + `tools/list` = 140 ferramentas +
  `get_balance`: trial, 40 gerações).
- Entrada `mcp-pixellab` no `cordis.patch.yml` do perfil web (backup em
  `~/tmp/cordis.patch.yml.bak-20261120-1552`); cabeçalho por `!!js` que lê o
  cofre. Conferida por `dsh web --dump-config` e pela avaliação do `!!js` fora
  do motor. Recarga a quente: as ferramentas vieram na mesma sessão.
- Prova: `create_image_pixen` 64×64, vista lateral, seed 20261120 →
  `arte/fonte/p1-cao-base-pixen.png` (64 cores, fundo transparente). 1 geração.
- `docs/ARTE.md`: como a conexão é feita, como trocar a chave, tabela de custo.
- Ambiente: Pillow instalado por pip (inspeção de PNG em script).

## v0.1.0 — esqueleto (2026-11-20)

- Repositório privado `jonathasptbr-gh/Projeto-Galapago` criado; motor
  **Godot 4.7.2** (renderizador de compatibilidade, 320×180 inteiro) e arte
  via **PixelLab MCP** — decisões do operador.
- Viabilidade medida antes de decidir: Godot arm64 renderiza neste celular sob
  Xvfb com Mesa **softpipe** (llvmpipe: SIGILL no JIT do proot; GLES sem EGL).
  Daí o oráculo `tools/quadros.sh` (Movie Maker, `--write-movie`).
- `sim/trajetoria.gd` (amostrar, comprimento, ponto_em) + 4 testes;
  executor `testes/run.gd` + `tools/testes.sh` (reprova também SCRIPT ERROR —
  controle negativo feito: falha proposital e erro de script reprovaram).
- Cena viva `jogo/main.tscn`: risca → a criatura provisória segue; `--demo`
  roteiriza o traço para o oráculo.
- CI `ci.yml`: Godot x86_64, testes, quadros como artefato. APK fica para P2.
- Docs: `AGENTS.md` (contrato), `CONCEITO`, `ARQUITETURA`, `ORACULO`, `ARTE`,
  `AMBIENTE`, fila `PEDIDOS-EM-ESPERA` (P1–P8), `RESIDUOS`.
