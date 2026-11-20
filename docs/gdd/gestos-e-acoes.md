# Gestos e ações — a fundação do combate

> Como um dedo na tela vira a ação da criatura. Tudo o que é REGRA mora em
> `sim/` (testado) e nas tabelas `dados/gestos.json` + `dados/acoes.json`
> (editáveis); a apresentação em `jogo/` só desenha. Decidido em v0.4.0.

## O fluxo

```
dedo (toque real OU demo roteirizada — mesmo caminho)
  → sim/gestos.gd  : reconhece O GESTO (toque, toque_duplo, segurar, deslize, trajetória)
  → sim/comandos.gd: traduz em COMANDO (a ação pedida + direção + alvo)
  → sim/corpo.gd   : executa — e é AQUI que a afinidade vai agir depois (P4)
```

O tempo é **simulado** (`tempo_ms` acumulado na cena): teste, demo e oráculo são
determinísticos — o mesmo dedo dá sempre o mesmo resultado.

## Gestos reconhecidos (limiares em `dados/gestos.json`)

| gesto | como se faz | vira |
|---|---|---|
| **toque** | dedo desce e sobe, quase sem andar, rápido | a criatura olha para o ponto |
| **toque duplo** | dois toques perto, em menos de ~0,34 s | **pular** (em direção ao toque) |
| **segurar** | dedo parado ≥ ~0,38 s | **defender** (segura enquanto o dedo fica) |
| **segurar na criatura** | o mesmo, começando em cima dela | **escavar** (desce/sobe) |
| **deslize** | rápido, de qualquer lugar, ≥ ~44 px | ataque/investida/esquiva, pelo SETOR |
| **trajetória** | começa na criatura, mais lento e longo | **mover** pelo caminho riscado |

Ordem ao soltar: segurar → toque(duplo) → deslize → trajetória → (não
reconhecido). Um traço lento começando LONGE da criatura é "não reconhecido"
(a HUD mostra).

## Setores do deslize (relativos ao OLHAR da criatura)

O ângulo é medido em relação à direção que a criatura olha — **0 = frente,
positivo = a direita dela** (a tela tem y para baixo). Tabela em
`dados/gestos.json` → `mapa.deslize`:

| setor | ângulo | ação |
|---|---|---|
| frente-esquerda | −105° a −12° | `ataque_x` |
| frente | −12° a +12° | `investida` |
| frente-direita | +12° a +105° | `ataque_y` |
| trás | ±105° a ±180° | `esquiva` |

Olhando para o SUL, o que é "frente-esquerda" na tela vira sudeste — porque é
relativo ao olhar, não à tela.

## Ações (`dados/acoes.json`)

Cada ação tem `fases = [antecipação, ativa, recuperação]` (segundos) e, quando
cabe: `deslocamento` (px de mundo), `alcance`/`arco` do golpe, `distancia`/
`altura` do pulo, `recarga`, `sustentada`, `vira`, `invulneravel`.

- **antecipação** = vento do golpe (nada vale ainda); **ativa** = o efeito
  (golpe acerta, pulo voa, deslocamento acontece); **recuperação** = não repete
  e aceita UM comando guardado (sai assim que termina).
- **recarga** impede repetir a mesma ação antes do tempo.
- **sustentada** (defender): fica na fase ativa enquanto o dedo segura; soltar
  manda `soltar` e ela entra em recuperação.

| ação | o que faz | parâmetros |
|---|---|---|
| `mover` | anda pelo caminho riscado (o mundo corta o que não dá para andar) | `velocidade` 110 |
| `olhar` | vira para o toque | — |
| `ataque_x` | golpe rápido para frente-esquerda | alcance 36, arco 110°, passinho 10 |
| `ataque_y` | golpe mais lento e maior para frente-direita | alcance 46, arco 60°, passinho 4 |
| `investida` | avança reto (para na parede) | deslocamento 64 |
| `esquiva` | pula para TRÁS, invulnerável na ativa | deslocamento 56 |
| `pular` | voa até ~84 px e pousa só onde dá | altura 26 |
| `defender` | sustentada, mostra escudo | — |
| `escavar` | no fim da ativa troca a camada | — |

## Como mudar sem tocar em código

- **Mudar qual setor faz o quê:** edite `mapa.deslize` em `dados/gestos.json`.
  A legenda da HUD e a demo seguem a tabela sozinhas.
- **Mudar o peso de uma ação** (alcance, vento, recarga): `dados/acoes.json`.
- **Mudar o quanto um gesto é tolerante:** `limiares` em `dados/gestos.json`.
- A demo (`jogo/demo.gd`) sintetiza DEDOS e passa pelo fluxo real — se a tabela
  mudar, ela continua exercitando o sistema de verdade.

## O que fica para depois

- **Afinidade** (P4): hoje a criatura obedece sempre; a decisão
  {obedece · hesita · reinterpreta · desobedece} entra em `sim/corpo.gd`, entre
  o comando e a execução — o ponto de entrada já é o `comandar()`.
- **Inimigos/alvos:** o golpe calcula alcance e arco, mas ainda não acerta nada.
- **Gestos de dois dedos** (pinça de zoom, por exemplo): o reconhecedor é de um
  dedo; o de dois entra quando houver design.
