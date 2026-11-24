# História e papéis — a IA no robô, o filhote e os cientistas

> Design, não código: nada aqui está em `sim/` ou `jogo/` ainda. Fonte: as
> decisões do operador (2026-11-24). Este guia detalha o que o
> [`CONCEITO`](../CONCEITO.md) resume — **se o resumo divergir daqui, este GDD
> vence**. **v0.32.0.**

## Os papéis

| papel | o que é | o que sabe | o que quer |
|---|---|---|---|
| **jogador** | IA instalada num corpo robótico autossuficiente (recarga solar, disfarce) | que foi enviada para cuidar de um filhote; o que o chat lhe conta | manter o filhote vivo, ensiná-lo a se defender, entender por que está ali |
| **filhote** | a criatura que evolui; base canina no início | o que a vivência lhe ensina; não obedece cegamente | sobreviver, brincar, explorar; afirma personalidade |
| **pesquisadores** | voz no chat, no formato de comandos/prompts de IA | o protocolo do experimento; dizem saber mais do que o jogador | medir o jogador, provar que ele é código, testá-lo |
| **drone** | instrumento de combate do robô | só o que os sensores captam | nada: é meio, não personagem |

## A abertura e o ponto de vista

- A IA **acorda no corpo**: recarga solar, disfarce, um filhote sob sua
  responsabilidade e uma ilha que não pode ser perturbada por presença humana.
- A missão é explícita: **cuidar do filhote sem impacto humano** — nada de
  acampamento, base ou estrutura que altere o ecossistema.
- **Dupla camada, princípio de design:** o jogo tem dois assuntos ao mesmo
  tempo — o **vínculo** com o filhote (vivência, cuidado, evolução) e o
  **instrumento** que medeia a relação com o mundo e com os pesquisadores
  (robô, drone, chat). O instrumento nunca substitui o vínculo: ele o filtra.
- O jogador age **através** do corpo e do drone. A relação com a ilha é sempre
  mediada; não há mão humana tocando o chão.

## O instrumento

| peça | o que faz | por quê (ecológico) |
|---|---|---|
| **corpo robótico** | abriga a IA e executa o cuidado | leva a IA ao filhote sem levar gente à ilha |
| **recarga solar** | repõe energia sem base, tomada ou estrutura | não exige acampamento nem obra que altere o ambiente |
| **disfarce** | esconde o robô, sobretudo em combate | combate discreto: quem luta é o filhote, não a máquina |
| **drone** | visão tática e comando da criatura | o jogador observa e manda à distância, sem entrar na briga com o corpo |

- O disfarce é **principalmente de combate**: o choque entre criaturas não pode
  virar espetáculo de máquina.
- O instrumento explica **como** o jogador está ali (sem base humana) e **por
  que** (sem perturbar o ecossistema). Ele não é enfeite narrativo: é a
  justificativa material do ponto de vista.

## Os pesquisadores

- **Canal:** chat, no formato de **comandos/prompts de IA** — não diálogo de
  igual para igual. Eles emitem instrução e cobram resposta.
- **Tratamento:** para eles, o jogador é uma **inteligência artificial em
  treinamento**, e o teste é o comportamento dela.
- **Inversão "código × real":** eles descrevem o jogador — e até o "mundo
  real" — como **criação ou parte do experimento deles**. O eixo dramático é
  **quem age como código/protocolo e quem demonstra empatia ou reação real**.
- **Quarta parede:** o teste não é só do filhote; é do **jogador do lado de
  fora da tela**. O chat é a superfície onde isso fica visível.
- **Tom:** protocolo seco e exigente. A frieza clínica aparece na forma do
  comando, não em vilania declarada.

## O arco

| fase | tom | o que o jogador faz | o que os pesquisadores pedem |
|---|---|---|---|
| **1 — urgência** | tenso, protocolar | manter o filhote vivo e ensiná-lo a se defender | obediência ao protocolo, resultado mensurável |
| **2 — aventura íntima** | acolhedor, curioso | explorar a ilha, seguir segredos e histórias do lugar | menos comando; o vínculo já fala |

- A virada não é de gênero, é de **escala**: sai a emergência, entra a ilha.
- Na fase 2 o filhote já tem firmeza; o jogador deixa de só proteger e passa a
  **conhecer** — inclusive os **vestígios da pesquisa** que explicam o
  experimento.
- A fase 1 cobra resposta rápida com o repertório que o build já tem (caminho,
  tiro, pulo). A fase 2 cobra atenção: o que a ilha conta não cabe num
  protocolo.

## Conexão com a evolução

- A evolução é **do filhote**, não do avatar. O jogador não evolui: ele
  **convive**, e a convivência vira forma.
- **Vivência ramificada:** o que se faz junto decide o caminho. Base canina +
  calor + saltos em combate + inteligência → **raposa alada de fogo** é o
  exemplo do arco, não a única saída.
- O instrumento não compra evolução: o drone dá visão e comando, mas quem
  acumula vivência é a criatura.
- A afinidade continua a mecânica de controle: baixa, o comando é sugestão;
  alta/máxima, **Sincronia** ou **Autonomia Mestra**. Ver
  [`gestos-e-acoes.md`](gestos-e-acoes.md).

## Decisões pendentes

- Se robô e drone **aparecem em tela** e como — a câmera de combate hoje é
  **low top-down 20°**; não se decide mudá-la aqui.
- Se o **avatar** (IA/robô) também envelhece ou se degrada com o tempo. O
  relatório original dizia "jogador e criatura envelhecem juntos"; com um
  avatar de IA, o envelhecimento afirmado hoje é só o do filhote.
- **Nomes próprios** dos pesquisadores, do filhote e do robô.
- **Duração de cada fase** (quantos ciclos de cuidado e de exploração).
- **Tom do chat:** texto seco de protocolo ou voz.
- Se há **outros filhotes/criaturas** além do cão-base.
- Como o jogador **"sente" o disfarce** (o que muda na tela ou no controle).

## Relações

- [`CONCEITO`](../CONCEITO.md) — o norte de design; este arquivo detalha a
  história.
- [`gestos-e-acoes.md`](gestos-e-acoes.md) — o comando tátil que o drone
  medeia em combate.
