# Pedidos em espera — a fila de pacotes

> **Nada aqui está autorizado por estar na fila: pergunte ao operador qual
> pacote seguir.** Lê-se só o pacote escolhido. Um pacote cabe numa sessão; se
> não couber, divide-se antes de começar.

| pacote | o quê | depende de | estado |
|---|---|---|---|
| P1 | Conectar o PixelLab (MCP) e gerar a 1ª prova | conta do operador | **feito (v0.1.1)** — falta o operador trocar a chave exposta no chat |
| P2 | APK no CI (export Android + Release) | — | **feito (v0.2.0)** — falta o operador instalar e riscar |
| P3 | Gestos: classificador de deslizes + trajetória na arena | — | **feito (v0.4.0)** — fundação de gestos, ações e camadas |
| P4 | Afinidade e personalidade (sim) | P3 ✔ | **próximo natural** |
| P5 | Vivência → evolução (sim) + simulação em massa | P4 | na fila |
| P6 | Âncora de arte: paleta-mestra, câmera, base canina | P1 | na fila |
| P7 | Fatia vertical: arena + cão + gestos + 1 evolução | P2–P6 | na fila |
| P8 | GDD do loop diário no laboratório/ilha | — | na fila (design, conversa) |
| P9 | Atualização automática do app (método do IASD, repo público) | P2 | **feito (v0.3.1)** — falta o operador reinstalar uma vez e confirmar |
| P10 | Mapa básico de cima com profundidade + tela em alta resolução | P1 | **feito (v0.4.0)** — camadas lógicas + mockup |
| P11 | Movimento por rota + overlays, alvos/mira, adversário e autonomia | P3 | **feito (v0.5.0)** |
| P12 | Retrato + gestos de tela + caminho por âncora (tempo lento, desconto, desvio de objetos) | P11 | **feito (v0.6.0)** |
| P13 | Caminho ao vivo (sem espera) + ações em paralelo + véu/rampa + sensibilidade | P12 | **feito (v0.7.0)** |

---

## P1 — Conectar o PixelLab

- **Operador:** criar conta em <https://api.pixellab.ai/mcp>, gerar a chave e
  pô-la no cofre do harness como `refs.PIXELLAB_TOKEN` (mesmo caminho do
  `GITHUB_TOKEN`). Não colar no chat.
- **Agente:** entrada `dsh-mcp-client` (`serverName: pixellab`,
  `transport: streamable-http`, URL `https://api.pixellab.ai/mcp`, cabeçalho
  Bearer lido do cofre) no patch do perfil; backup do patch antes
  (regra da máquina). Vale numa **sessão nova**.
- **Prova:** `get_balance`, depois UMA geração barata (`create_image_pro_flash`
  64×64 ~5 gerações) do cão-base; PNG em `arte/fonte/` e prévia em
  `/sdcard/Download/DSH-Go/` (avisando).
- **Pronto quando:** imagem gerada, salva, vista pelo agente e pelo operador.
- **Feito em v0.1.1:** a chave chegou PELO CHAT (fica no histórico da sessão) e
  foi posta no cofre pelo agente; a conexão leu o cofre e funcionou na mesma
  sessão (recarga a quente). A prova saiu por `create_image_pixen` (1 geração,
  não as 5 do Pro Flash). Pendente do operador: gerar chave nova e trocá-la no
  cofre (ver `docs/ARTE.md`, "Trocar a chave").

## P2 — APK no CI

- Job `apk` no `ci.yml`: Godot + export templates 4.7.2
  (`Godot_v4.7.2-stable_export_templates.tpz`), Java 17, Android SDK do runner,
  `export_presets.cfg` com preset Android (arm64-v8a; na época em paisagem — hoje retrato pela P12).
- Keystore de release em *secret* do repositório (gerar e guardar a senha fora
  do repositório); debug keystore no CI enquanto isso.
- Release por tag `v*` com o APK anexo.
- **Pronto quando:** o operador instala o APK e risca na tela do celular.

## P3 — Gestos

- `sim/gestos.gd`: classificar traço curto (ângulo, velocidade, duração) em
  {ataque X, ataque Y, salto, defesa/recuo}; traço longo = trajetória.
  Limiares em dados. Casos gravados como testes (incl. ambíguos).
- `jogo/`: arena 2,5D provisória (chão em perspectiva, profundidade por y).
- Gestos roteirizados no oráculo (`Input.parse_input_event`).

## P4 — Afinidade e personalidade

- Modelo: temperamento (traços estáveis) + humor (estado) + afinidade
  (vínculo). Comando → intenção → decisão {obedece, hesita, reinterpreta,
  desobedece}, com semente. Sincronia/Autonomia como modos.
- Testes de propriedade: afinidade alta ⇒ obediência alta; mesma semente ⇒
  mesma decisão.

## P5 — Vivência → evolução

- Contadores de vivência (calor, saltos, estudo, …) → perfil de traços →
  regras de limiar → ramo. Ramos em dados.
- `tools/simular.sh`: N vidas com sementes → distribuição de ramos (tabela).
  Ramo inalcançável ou dominante demais = falha de design visível.

## P6 — Âncora de arte

- Paleta-mestra, câmera única, tamanho de sprite; base canina aprovada pelo
  operador; validador de assets em `tools/`. Ver `docs/ARTE.md`.

## P7 — Fatia vertical

- Uma arena, o cão-base, trajetória + 4 gestos, afinidade baixa × alta
  visível, uma evolução (raposa alada de fogo). APK para o operador.

## P8 — GDD do loop diário

- Conversa de design com o operador → `docs/gdd/loop-diario.md`.


## P12 — Retrato e caminho por âncora

- **Operador (2026-11-20):** gestos relativos à TELA (cima = ataque físico,
  lados = especiais, baixo = esquiva; baixo + segurar = defesa); tela em
  retrato; caminho desenhado a partir de uma **âncora** segurada longe da
  criatura (o dedo não tapa a visão), com **tempo lento** durante o desenho;
  **desconto inicial** do vai-e-volta; caminho como pontos de referência com
  **pequenos desvios de objetos**; barreira sem pulo = para, com pulo = segue.
- **Feito em v0.6.0:** `sim/gestos.gd` (âncora, setores de tela, defesa por
  baixo+segurar), `sim/trajetoria.gd` (desconto + Douglas-Peucker),
  `sim/corpo.gd` (waypoints, desvio local, barreira/pulo), `jogo/` (prévia
  transladada, tempo lento, HUD retrato), `project.godot` 720×1280 orientação 1.
- **v0.6.1:** conserto do aviso de atualização (o `Atualizador` ficava 0×0 e
  jogava o botão `ATUALIZAR` para fora da tela; agora o painel abre sozinho).
  A v0.5.0 instalada precisa do APK manual uma vez.
- **Pendente de design:** o que cada **especial** faz (hoje é um golpe lateral
  genérico) e o ajuste fino de `escala_tempo`/`desconto_raio_px` pelo operador.

## P13 — Caminho ao vivo, sem espera (v0.7)

- **Operador (2026-11-20):** tirar o atraso do toque longo — o arrasto contínuo
  vira caminho **direto**; a linha **não se move com o animal** (o ponto de
  partida é a posição no INÍCIO do gesto, e se ele se mexeu no meio ela volta
  para começar por lá); manter **ataques e afins em paralelo** com esse
  controle, sem atraso; **escurecer a tela** durante o desenho e uma **rampa de
  aceleração** na saída (tempo para a próxima ação); **aumentar a
  sensibilidade** do desenho (dedo menor cobrindo mais tela).
- **Decisões do operador:** caminho **AO VIVO** (a criatura já anda atrás do
  dedo) e ação disparada **no meio do risco**, ao cruzar o limiar.
- **Feito em v0.7.0:** `sim/gestos.gd` (caminho sem espera, RISCO `flick_*`,
  defesa/escavar mantidos); `sim/corpo.gd` (`tracar` ao vivo, origem
  congelada, progresso que não volta, volta ao começo); `jogo/main.gd`
  (origem+mundo congelados na descida, ganho de sensibilidade, véu, rampa);
  `jogo/trilha.gd`, `jogo/hud.gd`, `jogo/demo.gd` (sem `hold`) e
  `dados/gestos.json` (`desenho.ganho` 1,6, `planejamento` 0,35×/0,45 s/0,22,
  `flick_*`). Testes: `test_gestos` reescrito, `test_corpo` com traço ao vivo.
