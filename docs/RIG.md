# Método do esqueleto (RIG)

> **Este documento é o método**, não o código: diz como o rig é pensado, o que
> já existe e o que falta. Cada afirmação cita `arquivo:linha` — quem discordar
> confere na fonte. Arte e pele estão em [`ARTE.md`](ARTE.md); o estado do
> lote, no §P10 de
> [`PEDIDOS-EM-ESPERA.md`](PEDIDOS-EM-ESPERA.md#p10--esqueleto-3d-paramétrico-por-arquétipo-e-locomoção).
> Escopo do método: o **quadrúpede**. Os outros arquétipos aparecem aqui como
> interface e conceito, não como marcha pronta.

## Duas grandezas que não se misturam

| grandeza | o que é | o que não é |
|---|---|---|
| **densidade de arte** | quantos px de tela cada px de arte ocupa, **fixado pelo cenário** (escala inteira). A tela não é a grade — a grade é a arte. | zoom da câmera; resolução do aparelho |
| **porte** | quantos px de arte o animal ocupa na grade. O cão é **68**. A régua é **por arquétipo**. | multiplicador aplicado na hora de desenhar |
| **quadro** (*frame*) | caixa que contém **todas as poses** do rig. Pode ser **maior que o porte** — a medição atual do cão deu **92×76**. | recorte; escala; área de jogo |
| **pivô** | um só por rig, no chão, igual em **todos** os clipes. | centro do quadro; origem da arte |

Densidade e porte são as duas grandezas; quadro e pivô são geometria derivada
das poses.

- **Densidade:** nenhum animal muda de densidade. Aumentar o bicho em px de
  arte quebra a relação com o cenário; o porte é propriedade do arquétipo, não
  uma escala escolhida por cena.
- **Quadro:** `calcular_canvas` ([`sim/esqueleto3d.gd`](../sim/esqueleto3d.gd))
  refaz a caixa a partir das poses — 16 yaws × 32 fases por clipe, mais o
  alcance analítico das patas — e **cresce** além de `canvas_px` quando a pose
  exige. O contrato está no comentário: *canvas é metadado, nunca recorte
  físico nem escala*. `pivot_px` sai junto; o teste nomeia a regra
  (`pivô global imutável entre clipes`,
  [`testes/test_parametrico3d.gd`](../testes/test_parametrico3d.gd):103).
- **Porte × quadro:** o JSON declara o porte em `canvas_px`; `calcular_canvas`
  devolve o quadro no mesmo campo, maior. Quem desenha usa o pivô — a pele
  geométrica posiciona por `pivot_px` e não recorta no canvas
  ([`jogo/pele_geometrica3d.gd`](../jogo/pele_geometrica3d.gd):25). Separá-los
  com teste é o item (1) da ordem de trabalho.

## Método: contato primeiro, ângulo depois

1. O autor declara, **no espaço do corpo**, **onde o pé encosta**, **para onde
   vai** e **quando sai**.
2. A IK resolve as juntas (comprimento do osso, polo). O ângulo não é escolhido
   à mão: é consequência do alvo.
3. **Deslizamento zero por construção**: o apoio é um ponto de chão do mundo e
   a pose sai dele — nunca o contrário.
4. **A âncora no mundo é verificação, não conserto.** O teste compara a pata
   com o apoio e mede o erro
   ([`testes/test_parametrico3d.gd`](../testes/test_parametrico3d.gd):128).
5. **A fase aérea não é caso especial.** No galope ela é só o trecho do ciclo
   sem contato: a mesma marcha, com a pata fora do chão. O teste do voo mede
   comprimento ÷ altura e a direção anatômica das patas
   ([`testes/test_parametrico3d.gd`](../testes/test_parametrico3d.gd):106).

O motor de hoje anda meio caminho: [`sim/locomocao3d.gd`](../sim/locomocao3d.gd)
avança a fase por distância e ancora os apoios no mundo, mas o apoio nasce da
pose e volta como alvo de IK. O método quer o inverso: o contato nasce
declarado e a pose segue dele. E `_patas` ainda decide a trajetória por clipe,
com defasagens cravadas no código (`te` 0, `fe` 0.25, `td` 0.5, `fd` 0.75,
[`sim/esqueleto3d.gd`](../sim/esqueleto3d.gd):706).

## As cinco primitivas de locomoção

| primitiva | status | o que falta / por quê |
|---|---|---|
| **quadrúpede** | **implementada** | contato em plano, 4 patas. É a única em escopo hoje. |
| **inseto** | **planejada** | a mesma matemática com 6 patas. Bloqueio concreto: o schema aceita no máximo 2 membros dianteiros + 2 traseiros e não existe arquétipo "inseto" ([`sim/topologia3d.gd`](../sim/topologia3d.gd):4,59). |
| **bípede** | **conceito** | dois contatos + equilíbrio. Não é "quadrúpede com duas pernas". |
| **ave** | **conceito** | as pernas são marcha; a asa é outro sistema (bater, decolar, pousar). |
| **serpente** | **conceito** | não há pé: o contato é ao longo do corpo, com onda viajando pela coluna. |

As interfaces de bípede, ave e serpente já compilam, mas `locomocao_suportada`
só é verdadeiro no quadrúpede
([`sim/topologia3d.gd`](../sim/topologia3d.gd):103); o teste compila as três e
exige que **não** prometam marcha
(`test_interfaces_bipede_ave_serpente_sem_promessa_de_gait`). Nada aqui finge
primitiva resolvida: só a primeira anda.

## Autoridade por arquétipo, não por clipe

- `if clipe == ...` no motor é **dívida**: cada família nova viraria mais um
  remendo dentro de `_patas`. A marcha é do arquétipo; o clipe entra como dado
  (duração, loop), não como regra de pata.
- O contrato de juntas também é por arquétipo. Hoje o compilador só sinaliza
  `> 20` como recomendação genérica
  ([`sim/topologia3d.gd`](../sim/topologia3d.gd):102), e o cão, com 24, aparece
  marcado. A decisão 1C corrige o eixo: teto **por arquétipo**.
- O membro de um quadrúpede não é opcional: o schema exige exatamente 4
  ([`sim/topologia3d.gd`](../sim/topologia3d.gd):73,99) — o que também é o
  bloqueio do inseto.

## Decisões registradas do operador (2026-11-24)

- **1C — teto de juntas por arquétipo:** quadrúpede **24**. Não é um teto
  global de 20; o aviso de `> 20` é provisório.
- **2A — quadro por animal, não por clipe:** uma caixa só por animal;
  `bounds_clipes` existe para conferência, não para recortar.
- **3B — patinagem < 1 px** por apoio, **também em curva e diagonal**, não só
  em reta. O teste atual mede reta
  ([`testes/test_parametrico3d.gd`](../testes/test_parametrico3d.gd):128).

## Ordem de trabalho

Sem promessa de prazo; cada item começa com o anterior provado.

0. Este documento.
1. Separar **porte** de **quadro**, com teste.
2. **Marcha por contato** no lugar do `if clipe`.
3. **Proporções e passada do cão**.
4. **Curva + despacho por arquétipo**.
5. **Inseto de 6 patas** como prova (opcional).

## Prova

- `tools/testes.sh` roda [`testes/test_parametrico3d.gd`](../testes/test_parametrico3d.gd):
  compilador legado e segunda espécie, interfaces sem marcha, IK com polo,
  quadro/pivô, voo e apoios.
- No lote v0.33.0: 176 apoios alcançáveis, erro máximo 0,002 px; voo 1,97:1;
  giro 4/4 (§P10).

## O que este documento não cobre

- **Arte e pele:** peças por osso, vistas por ângulo, pintor e pipeline —
  [`ARTE.md`](ARTE.md).
- **Os arquétipos fora do quadrúpede:** bípede, ave, serpente e inseto ficam
  como interface e conceito até a ordem de trabalho chegar neles.
