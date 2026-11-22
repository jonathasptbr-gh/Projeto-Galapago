# Conceito — Projeto Galápago

> Fonte: relatório de conceito trazido pelo operador (2026-11-20). Este é o
> norte de design; as decisões detalhadas vão para `docs/gdd/` (um arquivo por
> sistema) à medida que os pacotes da fila as tomam.

## Premissa

- Jogo indie comercial, **mobile primeiro** (tela tátil nativa; porte futuro
  não descartado).
- O jogador é o próprio personagem num mundo de criaturas (gênero *creature
  collector*), com **evolução ramificada por vivência**, não fixa por espécie.
  Ex.: base canina + convívio com calor + muitos saltos em combate +
  desenvolvimento de inteligência → **raposa alada de fogo**.
- **Convivência e envelhecimento:** jogador e criatura envelhecem juntos; a
  criatura tem personalidade real e decide por si — inclusive de forma
  impulsiva, teimosa ou infeliz.
- **Escopo contido:** uma ilha / laboratório de testes com microambientes, não
  mundo aberto.

## Combate 2,5D e controle tátil

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
  amarelo que anda com ele); **toque simples** = **TIRO** híbrido — mirado no
  alvo marcado, ou na direção do toque quando não há marca (recarga de 1 s, o
  animal para e segue); **toque duplo** = **PULO** (desde a v0.13, com o
  **PULO AUTO** ligado, sobe sozinho degrau de 1 nível quando o caminho
  continua); **segurar parado** ativa uma **habilidade em si mesmo** (cavar).
  Com alvo marcado o animal **persegue e só bate ao chegar** (sem a freada
  final). **Não há gesto de dois dedos**, nem defesa, nem efeito de esquiva —
  **esquivar é andar** com o tempo lento do desenho. O detalhe fica em
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
- **Quarta parede:** o jogador sabe e diz que está num jogo; a equipe finge
  tratar isso como delírio, mas sempre soube.
- **Reviravolta:** o objeto do teste é o jogador — empatia, postura diante da
  dureza do mundo, capacidade de laço genuíno. O vínculo com a criatura decide
  se ele termina visto como ameaça ou como aliado daquele mundo.

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
