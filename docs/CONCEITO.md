# Conceito — Projeto Galápago

> Fonte: relatório de conceito trazido pelo operador (2026-11-20). Este é o
> norte de design; as decisões detalhadas vão para `docs/gdd/` (um arquivo por
> sistema) à medida que os pacotes da fila as tomam.

## Premissa

- Jogo indie comercial, **mobile primeiro** (tela tátil nativa; porte futuro
  não descartado).
- O jogador é uma **IA num corpo robótico autossuficiente**, enviada a uma ilha
  para **cuidar de um filhote** — a criatura que evolui — **sem impacto
  humano** no ecossistema. O robô **recarrega no sol** (sem base nem tomada) e
  se **disfarça**; em combate solta um **drone** de visão tática.
- A criatura tem **evolução ramificada por vivência**, não fixa por espécie.
  Ex.: base canina + convívio com calor + muitos saltos em combate +
  desenvolvimento de inteligência → **raposa alada de fogo**.
- **Convivência e envelhecimento:** o vínculo é vivido no tempo — o filhote
  cresce, envelhece e ganha personalidade real; decide por si, inclusive de
  forma impulsiva, teimosa ou infeliz.
- **Escopo contido:** uma ilha / laboratório de testes com microambientes, não
  mundo aberto.

## O instrumento no meio

- **Duas camadas:** o **vínculo** com o filhote (vivência, cuidado, evolução) e
  o **instrumento** que medeia o mundo — robô, drone e o chat dos
  pesquisadores. O instrumento não substitui o vínculo: filtra.
- Ele é o meio pelo qual o jogador age e pelo qual os pesquisadores o leem.
  Detalhe em [`gdd/historia.md`](gdd/historia.md).

## Combate 2,5D e controle tátil

- **O drone é o meio:** em combate, o drone dá **visão tática** e é por ele que
  o jogador **comanda a criatura**; o toque desenhado continua a linguagem de
  comando do build atual — gestos e câmera não mudam aqui.
- **Sem joystick nem botão virtual.** Interface limpa, toque direto e gestos
  (referência: Kingdom Two Crowns; sem automação excessiva).
- **Trajetória riscada** (referência: Inazuma Eleven DS): o jogador desenha o
  caminho da criatura na arena. Desde a v0.7 o arrasto **não espera**: passou
  da tolerância, já é caminho, desenhado **ao vivo** e partindo de onde a
  criatura estava quando o dedo desceu (a linha não anda com ela). O tempo
  desacelera e a tela escurece durante o desenho; ao soltar, uma rampa de
  aceleração devolve o ritmo. Desde a v0.9.1 a linha é o **eixo de uma estrada
  larga**: o animal anda **dentro da faixa** (mais à esquerda, à direita ou no
  centro), num percurso **orgânico**, e **freia** nos últimos passos para parar
  macio — ele não pisa exatamente na risca.
- **Um dedo faz tudo: o ataque nasce do DESENHO (v0.9/v0.10).** Arrastar
  desenha a rota; um **laço** virava **ataque em área** (onda que cresce do
  centro; acende pela **distância ao centro**, ~7× o corpo) — **desligado na
  v0.11.5**, hoje o círculo é só caminho; **passar por cima**
  de um alvo é **batida**; levar o **fim do caminho até o alvo** o **MARCA** (X
  amarelo que anda com ele); **toque simples** = **TIRO** carregado: o **tempo
  de preparo** vai de **0 a 1,5 s** num **slider da HUD** (padrão **0,5 s**) e o
  **tempo define o tamanho/força** do tiro — 0 s é o tiro base, instantâneo, e
  1,5 s é o máximo; o animal para e o disparo sai sozinho no **alvo marcado
  vivo** ou no **destino final do caminho**; **segurar** = **CORRER** (sprint
  contínuo que gasta a energia; a cauda mantém o embalo ao soltar); sem
  caminho, o segurar ativa uma **habilidade em si mesmo** (cavar);
  **toque duplo** = **PULO**
  (desde a v0.13, com o **PULO AUTO** ligado, sobe sozinho degrau de 1 nível
  quando o caminho continua). Toda caminhada **nova** começa com uma **rampa**
  de aceleração de **0,30 s** (`rota.rampa_s`, ~15% → 100%): **não há pausa de
  saída** — o animal anda enquanto o dedo desenha.
  Com alvo marcado o animal **persegue e só bate ao chegar** (sem a freada
  final). **Não há gesto de dois dedos**, nem defesa, nem efeito de esquiva —
  **esquivar é andar** com o tempo lento do desenho. O **botão CONFIG** da HUD
  **esconde/mostra a HUD de teste** (o próprio botão, o véu do desenho e o
  aviso de atualização ficam). O detalhe fica em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md) — **se este resumo divergir
  do GDD, o GDD vence**.
- **Afinidade como mecânica de controle:**
  - baixa: o comando é sugestão — a criatura hesita, reinterpreta ou desobedece
    por temperamento ou falta de sintonia;
  - alta/máxima: dois caminhos — **Sincronia** (controle direto, fluido,
    imediato) ou **Autonomia Mestra** (a criatura lê o campo e age bem sozinha,
    com pouca microgestão).

## Narrativa

- **Realismo ecológico × frieza clínica:** o laboratório parece frio porque
  trata o mundo com realismo biológico (cadeia alimentar, carne, risco físico,
  consequência natural) — o contraste com a fantasia asséptica do gênero.
- **Chat de comandos:** a comunicação com os pesquisadores é um **chat no
  formato de comandos/prompts de IA**; eles tratam o jogador como uma
  **inteligência artificial em treinamento**.
- **Inversão "código × real":** os pesquisadores descrevem o jogador e até o
  "mundo real" como **criação/parte do experimento deles**. O embate é **quem
  age como código/protocolo e quem demonstra empatia ou reação real** —
  inclusive testando o **próprio jogador do lado de fora da tela**.
- **Quarta parede:** o jogador sabe e diz que está num jogo; a equipe finge
  tratar isso como delírio, mas sempre soube.
- **Reviravolta:** o objeto do teste é o jogador — empatia, postura diante da
  dureza do mundo, capacidade de laço genuíno. O vínculo com a criatura decide
  se ele termina visto como ameaça ou como aliado daquele mundo.

O detalhe narrativo fica em [`gdd/historia.md`](gdd/historia.md) — **se este
resumo divergir do GDD, o GDD vence**.

## A jornada

- **Fase 1 — urgência:** manter o filhote vivo e ensiná-lo a se defender. Os
  comandos dos pesquisadores soam **protocolares e exigentes**; o tom é tenso.
- **Fase 2 — aventura íntima:** com o filhote firme e o vínculo crescido, a
  ilha abre: **exploração**, **segredos, curiosidades e histórias do lugar** e
  **vestígios da pesquisa**. O que o jogador faz muda de sobreviver para
  conhecer.

## Arte

- Pixel art detalhada e coesa (não presa a 16-bit), costa/ilha, florestas,
  microambientes de teste.
- Referências já exploradas: raposa alada de fogo (cabeça proporcional, não
  infantilizada); cervo pré-histórico de pelagem cinza-esbranquiçada envelhecida
  (sem musgo), faíscas de estática e **galhada feita de raios azuis** (sem osso
  por baixo); lobo de pedra de 6 patas; peixe longo de gelo com chifres de
  cristal; aves de folha ao longe.
- Produção: ver [`ARTE.md`](ARTE.md).

## Modelo comercial

Sem gacha agressivo. Proposta nativa de toque, replay por ramificações e
finais, modelo enxuto (demo + compra única; expansões de linhagens depois).
