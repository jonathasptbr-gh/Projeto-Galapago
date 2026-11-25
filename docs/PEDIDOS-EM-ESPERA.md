# Pedidos em espera — a fila de pacotes

> **Nada aqui está autorizado por estar na fila: pergunte ao operador qual
> pacote seguir.** Lê-se só o pacote escolhido. Um pacote cabe numa sessão; se
> não couber, divide-se antes de começar.

> **Manutenção registrada (2026-11-24):** a faxina documental A (v0.14.1) e o
> guardião offline B (v0.14.2) já foram feitos; o protocolo de agentes e o
> multi-sessão (P21) ficaram na v0.14.3; o P22 (fila enxuta) foi entregue na
> v0.14.4 e o registro dele fechado na v0.15.0; o P23 (oráculo com baseline)
> ficou na v0.16.0. Os pacotes feitos moram em
> [`PEDIDOS-FEITOS.md`](PEDIDOS-FEITOS.md), não aqui. **Nada na fila está
> autorizado** — restam os pacotes de conteúdo (P5–P8), à escolha do operador;
> P9 e P10 estão congelados.

> **Decisões do operador (2026-11-25):**
> - **P9 e P10 congelados:** a fundação do rig será reestruturada; nada novo
>   nem retoque até lá (os resíduos de rig estão como `congelado (rig)` em
>   [`RESIDUOS.md`](RESIDUOS.md)).
> - **Controles e gestos maduros e estáveis:** não mexer sem pedido do
>   operador.
> - **P24 — Fundação 3D autorizado** (mesma data): o mundo vira 3D, com
>   Pixel Pass opcional; a câmera gira 360°. Ele autoriza mexer na conversão
>   tela→chão e na câmera; o vocabulário de gestos continua o mesmo.

| pacote | o quê | depende de | estado |
|---|---|---|---|
| P5 | Vivência → evolução (sim) + simulação em massa | P4 ✔ | **próximo do núcleo** |
| P6 | Âncora de arte: paleta-mestra, câmera, base canina | P1 | na fila |
| P7 | Fatia vertical: arena + cão + gestos + 1 evolução | P2–P6 | na fila |
| P8 | GDD do loop diário no laboratório/ilha | — | na fila (design, conversa) |
| P9 | Camadas de pixel art sobre o esqueleto 3D (fase B) | A: v0.29.0 ✔ | **congelado** (2026-11-25) |
| P10 | Esqueleto 3D paramétrico por arquétipo e locomoção | — | **congelado** (2026-11-25) |
| P24 | Fundação 3D: mundo 3D, Pixel Pass opcional, câmera orbital 360° | — | **entregue na v0.35.0**, aguardando o operador no aparelho |

---

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

## P9 — Camadas de pixel art sobre o esqueleto 3D (fase B)

- **Estado: congelado (2026-11-25):** a fundação do rig será reestruturada;
  nada novo nem retoque até lá.

- **Decisão do operador (2026-11-23):** o alvo final é a fase B — o esqueleto
  3D da v0.29.0 recebe as camadas de pixel art por osso, com vistas
  lateral/frontal/costas trocadas por ângulo; câmera **low top-down (20°)**.
- **Arte:** peças por osso (cabeça, focinho, orelhas, tronco, pernas, cauda)
  com pivô e vistas por ângulo; medir o custo antes de gerar.
- **Contrato:** o campo `pecas` do `dados/rig/canino3d.json` já valida; falta
  o desenho ordenado (pintor) e o pipeline de arte.

## P10 — Esqueleto 3D paramétrico por arquétipo e locomoção

- **Estado: congelado (2026-11-25):** a fundação do rig será reestruturada;
  nada novo nem retoque até lá. Antes disso: núcleo entregue na v0.33.0 (voo
  1,97:1, giro 4/4, 272 testes/0).
- **O que já existe:** `sim/topologia3d.gd` (schema 3 adaptado e schema 4 com
  papéis; quadrupede/bípede/ave/serpente; membros e pole), `sim/locomocao3d.gd`
  (fase por distância e apoios ancorados no mundo), mudanças em
  `sim/esqueleto3d.gd`, `jogo/criatura.gd` e `jogo/rigs3d.gd`, preset
  `dados/rig/equino3d.json` e `testes/test_parametrico3d.gd`.
- **Medido na v0.33.0:** 176 apoios alcançáveis com erro máximo de 0,002 px;
  voo 1,97:1 (era 0,93); reancoragem 4/4 (era 3/4).
- **Próximo:** (1) revisar o cão nas 8 direções e o canvas no aparelho;
  (2) as chaves do voo no equino (hoje herdam default e o teste de voo só roda
  no cão); (3) as interfaces de bípede, ave e serpente. O método está escrito
  em [`RIG.md`](RIG.md); o motor ainda não o segue (ordem de trabalho, itens 1–2).
- **Ordem de trabalho:** em [`RIG.md`](RIG.md) — item (1), porte × quadro,
  feito na v0.33.2; item (2), marcha por contato, feito na v0.33.3 (walk e
  galope em dados, trote provado só em dados). Item (3), **feito** em duas
  partes: a reconciliação `passada = duty × ciclo` na v0.33.4 e as
  proporções do cão (L2, tronco +25%) na v0.34.0, junto com a locomoção por
  modo de câmera. O próximo é o item (4): curva e despacho por arquétipo.
- **Decisões do operador (2026-11-24):** 1C — teto de juntas por arquétipo
  (quadrúpede 24); 2A — quadro por animal, não por clipe; 3B — patinagem
  < 1 px também em curva e diagonal.
- **Aceite:** segundo quadrúpede sem editar o solver; menos de 1 px de
  patinação por apoio em reta; voo entre 1,8 e 2,0; testes verdes; imagens
  revisadas no chat.

## P24 — Fundação 3D

- **Decisões do operador (2026-11-25):** o cenário passa a ser **3D real**,
  com materiais estilizados (luz em faixas + contorno) e o **Pixel Pass como
  camada final desligável** (baixa resolução interna, quantização, dither
  Bayer ancorado no mundo, ampliação *nearest*). Personagens em **3D** (não
  sprite 2D), para não travar a escolha estética. **Câmera ortográfica
  orbital, giro livre 360°** em volta do foco, pela **barra tátil no topo da
  tela** (retrato): deslizar de um lado ao outro gira. **Vista alta é a
  padrão**; a vista íntima (baixa/perto) é extra bem-vindo, não requisito.
  Compatibilidade com o build 2D atual **não** é requisito; alvo = celular
  médio (otimização fica para depois). Arquitetura definitiva, não protótipo.
- **Medido antes (2026-11-25, cena de teste fora do repo):** 3D + SubViewport
  362×642 + pós + toon + casca + sombra roda no oráculo local (Compatibility,
  softpipe): 120 quadros em 309 s. Vulkan (Mobile e Forward+) com lavapipe
  **cai com sinal 4** neste celular (o mesmo JIT do llvmpipe).
- **Renderizador (decisão do gerente, delegada pelo operador):** **Mobile**
  (Vulkan) como alvo, com *fallback* para OpenGL; shaders escritos para rodar
  também no Compatibility, que vira a **prévia local** do oráculo
  (`--rendering-method gl_compatibility`); a verdade visual é o CI com
  lavapipe. Se o CI não renderizar Vulkan, fica o Compatibility.
- **Fatias (um escritor por vez):**
  1. Renderizador + oráculo + CI (prova: quadros Vulkan no CI verde).
  2. `sim/camera3d.gd` puro: foco, yaw, vistas, snap de texel + resto,
     chão⇄tela como `Transform2D` (ortográfica ⇒ afim). Testes.
  3. `jogo/mundo3d/`: SubViewport, Pixel Pass liga/desliga, shaders toon e
     casca, ilha e objetos a partir de `sim/mundo.gd`, criatura e adversário
     provisórios em 3D.
  4. Integração no `jogo/main.gd`: mundo 3D no lugar das camadas 2D, overlays
     (trilha, mira, perigos, efeitos) na tela pela transformação afim, toque
     pela câmera nova, barra de giro, chave do Pixel Pass, demo girando.
  5. Docs + publicação + APK.
- **Aceite:** no APK, a ilha aparece em 3D, gira 360° pela barra do topo sem
  atrapalhar o desenho do caminho, o caminho cai no chão certo em qualquer
  ângulo e a chave troca pixel art ⇄ 3D liso; testes e CI verdes; quadros
  revisados no chat.
