# Pedidos em espera — a fila de pacotes

> **Nada aqui está autorizado por estar na fila: pergunte ao operador qual
> pacote seguir.** Lê-se só o pacote escolhido. Um pacote cabe numa sessão; se
> não couber, divide-se antes de começar.

> **Esta é a LISTA ÚNICA de próximos planos** (reorganizada em 2026-11-26).
> Todo plano novo entra aqui como pacote `Pn`; o que mora em outro lugar está
> apontado em "Onde mais há pendência", no fim do índice.

> **Manutenção registrada (2026-11-24):** a faxina documental A (v0.14.1) e o
> guardião offline B (v0.14.2) já foram feitos; o protocolo de agentes e o
> multi-sessão (P21) ficaram na v0.14.3; o P22 (fila enxuta) foi entregue na
> v0.14.4 e o registro dele fechado na v0.15.0; o P23 (oráculo com baseline)
> ficou na v0.16.0; o P28 (triagem dos resíduos) foi um commit comum em
> 2026-11-26, e o fechamento com as decisões do operador outro, em 2026-11-27. Os pacotes feitos moram em
> [`PEDIDOS-FEITOS.md`](PEDIDOS-FEITOS.md), não aqui.

> **Decisões do operador (2026-11-26) — faxina:** o padrão de criatura passa a
> ser **modelo 3D pronto importado do Sketchfab, com pequenos ajustes**. O rig
> próprio (2D e 3D), o mapa Wang 2D, o ensaio da água e o piloto da natureza
> saíram do repositório; **P6, P9 e P10 foram descartados** (registro em
> [`PEDIDOS-FEITOS.md`](PEDIDOS-FEITOS.md#p6-p9-e-p10--descartados-commit-comum-2026-11-26)).
> Os resíduos de rig viraram `descartado (rig removido)` em
> [`RESIDUOS.md`](RESIDUOS.md).

> **Decisões do operador (2026-11-25):**
> - **P9 e P10 congelados** (superada em 2026-11-26: descartados, acima).
> - **Controles e gestos maduros e estáveis:** não mexer sem pedido do
>   operador.
> - **P24 — Fundação 3D autorizado** (mesma data): o mundo vira 3D, com
>   Pixel Pass opcional; a câmera gira 360°. Ele autoriza mexer na conversão
>   tela→chão e na câmera; o vocabulário de gestos continua o mesmo.

> **Pedidos diretos do operador (2026-11-26), fora de pacote:** piloto de
> natureza 3D (commit 1842ba3; a cena saiu em 2026-11-26) e o mapa de testes NATUREZA jogável com cores
> vivas (v0.36.0). Os desdobramentos que ele pediu — otimizar o cenário,
> cenário destrutível e os quatro elementos no cenário — viraram P25–P27.

### Frentes (os temas, na ordem em que dependem um do outro)

| frente | pacotes | situação |
|---|---|---|
| Núcleo de jogo | P5 → P8 · P30 | P5 é o próximo do núcleo; P8 é conversa de design; P30 (vida, dano e morte) vai ter, mas não agora |
| Cenário 3D e arena | P24 ✔ → P25 → P26 → P27 | P24 entregue; P25 mede antes de P26/P27 crescerem o custo |
| Personagem e arte | P29 | P6, P9 e P10 descartados (2026-11-26): padrão novo = modelo 3D pronto + ajustes ([MODELOS-3D](MODELOS-3D.md)); P29 escolhe o modelo do cão/lobo; contorno do ator pendente (em P24) |
| Fatia vertical | P7 | junta núcleo + cenário + personagem |
| Manutenção | P28 ✔ | triagem dos resíduos feita (commit comum, 2026-11-26): 25 `obsoleto (3D)`, 20 `resolvido`; registro em [`PEDIDOS-FEITOS.md`](PEDIDOS-FEITOS.md#p28--triagem-dos-resíduos-commit-comum-2026-11-26); decisões do operador aplicadas em 2026-11-27 (104 linhas fechadas) |

### Índice

| pacote | o quê | depende de | estado |
|---|---|---|---|
| P5 | Vivência → evolução (sim) + simulação em massa | P4 ✔ | **próximo do núcleo** |
| P7 | Fatia vertical: arena + cão + gestos + 1 evolução | P2–P5 | na fila |
| P8 | GDD do loop diário no laboratório/ilha | — | na fila (design, conversa) |
| P24 | Fundação 3D: mundo 3D, Pixel Pass opcional, câmera orbital 360° | — | **entregue na v0.35.0**; mapa NATUREZA na v0.36.0; contorno do ator pendente |
| P25 | Cenário 3D: medir e otimizar o custo gráfico | v0.36.0 ✔ | na fila (pedido 2026-11-26) |
| P26 | Cenário destrutível: vegetação, árvores que caem, arena que se abre | P25 | na fila (pedido 2026-11-26) |
| P27 | Os quatro elementos no cenário (fogo, terra, ar, água) | P26 · P5 (porte) | na fila (design + sim; pedido 2026-11-26) |
| P29 | Modelo do lobo/cão: o Wolf.glb é o melhor disponível? | — | na fila (pedido 2026-11-26) |
| P30 | Vida, dano e morte | design com o operador | na fila — vai ter, **não agora** (decisão 2026-11-27) |

### Onde mais há pendência (apontada daqui, não copiada)

- [`RESIDUOS.md`](RESIDUOS.md): o que cada publicação deixou para trás (52
  linhas `aberto` depois das decisões do operador de 2026-11-27).
- [`gdd/historia.md`](gdd/historia.md#decisões-pendentes): decisões de
  história à espera do operador.

---

## P5 — Vivência → evolução

- Contadores de vivência (calor, saltos, estudo, …) → perfil de traços →
  regras de limiar → ramo. Ramos em dados.
- `tools/simular.sh`: N vidas com sementes → distribuição de ramos (tabela).
  Ramo inalcançável ou dominante demais = falha de design visível.

## P7 — Fatia vertical

- Uma arena, o cão-base, trajetória + 4 gestos, afinidade baixa × alta
  visível, uma evolução (raposa alada de fogo). APK para o operador.
- **2026-11-26:** P6 (âncora de arte) saiu da dependência, descartado; o
  cão-base virá do padrão novo (modelo 3D do Sketchfab + ajustes).

## P8 — GDD do loop diário

- Conversa de design com o operador → `docs/gdd/loop-diario.md`.

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
- **Retorno do operador (2026-11-26, no aparelho):** o contorno do animal
  está **bem ruim** no pescoço, no bico/focinho e nos detalhes — mais
  precário que o do cenário. Código conferido: o contorno de tela vale para
  os atores (mesmo passe), mas a linha é por profundidade (afina perto do
  chão) e o vinco (>75°) ignora as formas redondas do ator provisório
  (`jogo/mundo3d/ator.gd`), então quase não há linha interna. Ver os
  resíduos do contorno da v0.35.2/v0.35.4 em [`RESIDUOS.md`](RESIDUOS.md).
  Não consertado; decidir com o operador (ajustar o passe ou esperar a pele
  3D).

## P25 — Cenário 3D: medir e otimizar o custo gráfico

- **Pedido do operador (2026-11-26):** mapas detalhados mais baratos de
  processar, para sobrar folga para destruição e elementos (P26/P27).
- **Antes de otimizar, medir:** contador de quadros por segundo na HUD e
  chaves de teste (sombra, detalhe, resolução do 3D) no APK; o operador anota
  o que muda no aparelho. Hoje: mapa NATUREZA ~691 mil triângulos
  instanciados, 341 MultiMeshes em setores 12×12, FPS não medido (resíduo da
  v0.36.0).
- **Candidatos, em ordem de ganho provável (a confirmar pela medição):**
  1. sombra por **sombra simples**: copas de poucos polígonos só para a
     sombra (`SHADOW_CASTING_SETTING_SHADOWS_ONLY`), as folhas reais sem
     sombra — hoje a mata é desenhada duas vezes;
  2. **árvore leve na vista alta** (a variante `simples` de
     `jogo/mundo3d/natureza/malhas.gd`, ~1/4 das folhas), a completa só na
     vista íntima;
  3. **escala de resolução** do 3D no liso (HUD continua nítida); o Pixel
     Pass já é o modo barato;
  4. densidade de capim/samambaia menor longe do centro da ação;
  5. a textura do mapa do chão redesenhada só quando muda (resíduo v0.35.1).
- **Aceite:** FPS medido no aparelho antes e depois; nenhuma perda visível na
  vista alta aprovada pelo operador; testes e CI verdes.

## P26 — Cenário destrutível

- **Pedido do operador (2026-11-26):** o mapa detalhado deve ser o mais
  destrutível possível no hardware atual — árvores caem quando uma criatura
  maior esbarra nelas durante um ataque, o tiro destrói vegetação e árvores,
  o fogo queima (fogo é P27). Objetivo: imersão e a **arena de combate**, uma
  área que se abre ao longo da batalha e favorece estratégia.
- **Princípio:** destruição **encenada, não física** — a regra é da `sim/`
  (grade de células, semente, testável); o `jogo/` só anima. Sem motor de
  física para lascas.
- **Fatias:**
  1. vegetação baixa (capim, samambaia, arbusto): o tiro a remove; partículas
     curtas e marca no mapa do chão;
  2. árvores com resistência: caem quando o golpe vence a resistência (porte
     da criatura × força do golpe; tiro forte também), tombando na direção do
     golpe numa animação de ~1 s; o tronco caído vira obstáculo nas células
     que ocupa e pode ser destruído depois;
  3. estado persistente durante a batalha (a arena "abre"); regenerar ou não
     entre batalhas é decisão de design.
- **Dependência:** "criatura maior" pede um **porte** por criatura (não existe
  ainda; rig próprio removido, evolução é P5) — começar com um porte provisório em
  dados.
- **Custo:** baixo a médio — trocar uma instância de MultiMesh por um nó
  animado e voltar a ela é barato; a destruição **reduz** o que se desenha.

## P27 — Os quatro elementos no cenário

- **Pedido do operador (2026-11-26):** fogo, terra, ar e água são os elementos
  do combate das criaturas e afetam o cenário. Análise registrada para a
  conversa de design:
  - **fogo:** empurra, destrói, derruba (um "objeto invisível" com área) e
    **espalha** por uma grade de combustível/umidade (perto do rio queima
    menos); árvore queimada vira tronco carbonizado; limite fixo de chamas
    visíveis (10–15), o resto é cor/cinza no chão;
  - **terra:** como o fogo no impacto, mas **permanente** — muda a grade
    (barreira, rampa, buraco), o que a sim já sabe representar por célula;
  - **ar:** empurra e derruba sem destruir; sacode copas e vegetação (vento
    visual barato), espalha ou apaga fogo e água;
  - **água:** **sem simulação de fluido** (cara demais para o celular e
    imprevisível). Proposta: água como **campo na grade** — cada célula guarda
    um nível de água que se espalha para as vizinhas mais baixas e evapora com
    o tempo (temporária), desenhada como superfície rasa e poças; efeitos de
    regra: apaga fogo, deixa o chão encharcado (mais lento, escorregadio),
    empurra no jato, enche buracos da terra. É "física mínima" barata:
    alguns milhares de células atualizadas poucas vezes por segundo.
- **Conceito escolhido para a água (decisão do operador, 2026-11-26):** o do
  ensaio do commit `64f0d2f` — **água de grade**: canos virtuais na sim (fluxo
  com embalo e atrito, conserva, não sobe parede, riacho com nível fixo,
  evaporação sobretudo da água parada, umidade do chão), desenhada como
  **lâmina suave com borda orgânica** (a grade vira textura suavizada; borda
  da poça por limiar com ruído, espuma e filetes no sentido do fluxo) e **chão
  úmido** que escurece onde molhou. Lição: o modelo só por diferença de nível
  era lento demais em encosta suave (a água virava película); os canos
  virtuais resolveram. O ensaio (`sim/agua.gd`, `testes/test_agua.gd`,
  `agua_ensaio.tscn`/`.gd`, `agua.gdshader`) saiu do repositório na faxina de
  2026-11-26 e é **recuperável por esse commit**; no jogo ficou só o
  `usar_umidade` (desligado) do `natural.gdshader`.
- **Referências de jogos (de memória, não conferidas):** superfícies de
  combate do *Divinity: Original Sin 2* (poças, combinações, temporárias),
  água por bloco/célula do *Minecraft* e do *Terraria* (barata, roda em
  celular), fogo pelo capim e vento do *Zelda: Breath of the Wild*. O caro é
  fluido de verdade (*From Dust*, *Noita*) — fora do escopo.
- **Combinações** dão a profundidade tática: água apaga fogo, terra represa
  água, ar espalha fogo, fogo seca lama.
- **Depende de:** P26 (estado destrutível na grade) e P5 (elemento/porte da
  criatura). Decisões do operador pendentes: duração dos efeitos, se a água
  sobe de nível em buracos, se o fogo pode sair do controle.

## P29 — Modelo do lobo/cão: o Wolf.glb é o melhor disponível?

- **Pedido do operador (2026-11-26), para o futuro:** analisar se o `Wolf.glb`
  (Quaternius, CC0 — candidato registrado em
  [MODELOS-3D](MODELOS-3D.md#candidatos-registrados-2026-11-26)) é o melhor
  modelo de lobo/cão disponível para a criatura-base.
- Comparar com os outros candidatos do arquétipo (husky, shiba, raposa) e com
  busca nova (`tools/sketchfab.mjs buscar wolf|dog`): licença do padrão,
  clipes que o jogo pede (andar, correr, pular, atacar, parado), faces, estilo
  ao lado da mata. Prancha por CPU de cada finalista, mostrada no chat.
- Entrega: recomendação com opções; a escolha é do operador. O escolhido entra
  em `arte/modelos/` com o `.credito.txt` (fluxo do guia).

## P30 — Vida, dano e morte

- **Decisão do operador (2026-11-27):** o jogo **vai ter** vida, dano e
  morte, **mas não agora**. Até lá vale o que está no código: os golpes
  empurram e atordoam, ninguém perde vida (`dados/adversario.json`, "NÃO há
  vida nem dano", v0.14; [`RESIDUOS.md`](RESIDUOS.md) v0.5.0 `combate`).
- Resíduos que fecham aqui (estado `movido para P30` em
  [`RESIDUOS.md`](RESIDUOS.md)): v0.23.1 `morte` (tomba e para, sem vida nem
  renascimento), v0.23.0 `vida/dano` (`hit`/`death` dormentes) e v0.21.0
  `combate` (`hit`/`death` no catálogo, sem regra de vida). Relacionado e
  ainda aberto: v0.25.0 `animação` (`shot`/`hit`/`death` sem acionar).
- A decidir com o operador antes de codar: quem tem vida (criatura, inimigo,
  ambos), o que tira vida (golpe, tiro, perigos, água), o que acontece na
  derrota (renascer onde, o que se perde) e como a vida aparece na tela.
- Regra na `sim/` com teste (`AGENTS.md`); os clipes `hit`/`death` vêm do
  modelo 3D escolhido (P29/P7).
