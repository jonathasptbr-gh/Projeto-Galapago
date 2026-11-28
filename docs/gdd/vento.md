# Vento na mata

> O vento da mata é a **primeira etapa do ar no [P27](../PEDIDOS-EM-ESPERA.md)**
> ("os quatro elementos no cenário"): hoje ele é só **VISUAL** — balança as
> folhas da mata. O **campo** é lógica pura em `sim/vento.gd` e é o MESMO que as
> habilidades de ar e a água vão ler; **a água ainda não reage**. Fonte única
> dos números: `dados/vento.json`; do desenho:
> `jogo/mundo3d/natureza/folha.gdshader` + `mapa.gd`. Mapa:
> [`mapa`](mapa.md). Camadas: [`arquitetura`](../ARQUITETURA.md).

## O que é e o que já existe

- O **campo** não depende do desenho: é `RefCounted`, sem nó, sem `Input`, sem
  `_process` e sem sorteio global. O estado é `(tempo, posição)`; só
  `avancar(dt)` move o relógio.
- O **desenho** lê o campo e balança **vértices** das folhas (copas,
  samambaias, sub-bosque e capim). Madeira, solo e pedra não balançam.
- As **habilidades de ar** (P27) já podem empurrar o campo por
  `adicionar_fonte(...)`; o balanço visual delas ainda não existe (ver
  "Aproximação consciente").
- A **água** ainda não reage; quando existir, lê `uniformizar()` sem precisar
  de campo novo.

## Camadas do campo

O vetor num ponto é `dir_base(p)·força_base(p) + Σ frentes + Σ fontes`, com
`força_base = brisa + vento_forte + turbulência` (nunca negativa). Valores de
`dados/vento.json` — o `PADRAO` de `sim/vento.gd` repete os mesmos números para
`cfg` ausente, parcial ou inválido:

| camada | o que faz | parâmetros (JSON) |
|---|---|---|
| **brisa** | direção que vaivém devagar; força com respiração lenta | `forca` 0,32 · `direcao_rad` 0,6 · `vaivem_rad` 0,55 · `giro_s` 61,0 |
| **rajadas** | bandas gaussianas que viajam na direção do vento, uma a cada período; nascem até 22 unidades a montante e morrem após `percurso` | `forca` 0,62 · `periodo_s` 6,4 · `largura` 7,5 · `velocidade` 4,2 · `percurso` 90,0 |
| **vento forte** | envelope lento (seno) no começo de cada período | `forca` 0,55 · `periodo_s` 43,0 · `duracao_s` 7,0 |
| **turbulência** | duas ondas espaciais desencontradas no espaço e no tempo | `forca` 0,18 · `escala` 2,6 · `velocidade` 1,9 |
| **fonte** | empurrão de habilidade, com raio e tempo de vida | `duracao_s` 1,6 · `raio` 4,0 · `teto` 8 |

O que o código fixa em cada camada:

- **brisa:** `força = 0,32·(0,86 + 0,14·sin(0,37·t))`; o ângulo é
  `0,6 + 0,55·sin(2π·t/61)` e cada ponto recebe um desvio local de até
  ±0,22 rad. A direção **ambiente** (sem o desvio) é a que as frentes seguem.
- **rajada:** o peso em `p` é `exp(-(d/largura)²)`, com `d` a distância
  assinada perpendicular à direção da frente. A frente automática `k` nasce em
  `-dir·min(percurso/2, 22)` com força `0,62·(0,7 + 0,3·sin(k·2,39))`; no
  máximo **6** bandas vivas, a mais antiga sai.
- **vento forte:** entra nos primeiros `duracao_s` de cada `periodo_s`, com
  `0,55·sin(π·t_local/7)`.
- **turbulência:** `0,18·(0,6·sin(1,9·t + 1,43·x) + 0,4·sin(3,1·t − 1,82·z))`.
- **fonte:** decai linearmente com a idade e cai com a distância por
  `smoothstep` até o raio; o teto de 8 fontes vivas descarta a mais antiga.

## Espaço e unidades

- Plano **local do mapa** `(x, z)`; `y` não entra no campo.
- **1 unidade = 1 célula da sim = 32 px** (a mesma escala de
  `jogo/mundo3d/espaco.gd`).
- **Força adimensional, 0–2** nos valores de projeto; uma fonte de habilidade
  pode somar mais que isso localmente, mas o campo nunca fica negativo.
- **Direção unitária** aponta para onde o vento **sopra** (não de onde vem).

## A sim (`sim/vento.gd`)

| chamada | contrato |
|---|---|
| `_init(cfg := {})` | mescla `cfg` parcial sobre `PADRAO`, seção a seção; cria a primeira rajada em `t = 0`. |
| `avancar(dt)` | move o relógio e o estado; `dt <= 0` é ignorado; frentes andam e fontes envelhecem. |
| `direcao(p)` | direção unitária em `p`; sem vento, cai na direção da brisa. |
| `forca(p)` | módulo do vetor em `p` (`>= 0`). |
| `vetor(p)` | vetor do vento em `p` = base + frentes + fontes. |
| `campo(p)` | dicionário para quem desenha: `direcao`, `forca`, `vetor`, `rajada` (0–1). |
| `rajada(p)` | soma das bandas naquele ponto (0–1), sem a brisa. |
| `criar_frente(pos, forca := 1.0)` | rajada manual (demo/habilidade) que nasce em `pos` e segue o vento ambiente. |
| `adicionar_fonte(pos, dir, forca, raio, duracao_s)` | empurrão de habilidade; `raio`/`duracao_s` 0 usam o JSON; devolve id crescente. |
| `limpar_fontes()` | apaga todas as fontes; o campo volta ao de antes. |
| `frentes_vivas()` | quantas bandas de rajada estão vivas (diagnóstico e teste). |
| `uniformizar()` | pacote de largo alcance para o desenho: `direcao`, `forca`, `frente`, `frente_forca`, `frente_largura`, `turbulencia`, `tempo`. |

Determinismo: mesmo `cfg` + mesmos `avancar(dt)` dão o mesmo vetor — não há
sorteio global nem relógio real na sim. Configuração absurda (zero, negativo,
NaN, infinito ou tipo errado) não quebra nada: cai na reserva e o campo
continua finito. O `campo` é sempre a **soma** base + frentes + fontes;
`uniformizar()` é o recorte de largo alcance que o desenho consome.

## O desenho

`folha.gdshader` ganha **balanço de vértice** — barato e sem textura, loop ou
compute shader; compila no Mobile e no Compatibility. O `mapa.gd` define, por
material, `vento_amplitude` (> 0 só nas folhas) e `vento_altura` (altura da
família) e, a cada quadro, entrega o pacote de `uniformizar()`:

- **Peso por altura:** `pow(clamp(VERTEX.y / max(vento_altura, 0,01), 0, 1), 1,6)`
  — a base da planta fica parada e o topo anda.
- **Fase por instância:** hash do XZ da origem em `MODEL_MATRIX[3]`
  (`fract(sin(dot(p, vec2(12.9898, 78.233)))·43758.5453)·2π`) tira as plantas
  da sincronia, sem buffer nem textura.
- **Banda da rajada:** gaussiana
  `vento_frente_forca·exp(-(d/vento_frente_largura)²)`, com
  `d = dot(origem.xz − vento_frente, vento_direcao)`; a frente chega em
  coordenadas de **MUNDO**.
- **Respiração e tremor:** `respira = 0,8 + 0,2·sin(1,13·t + fase)` e
  `tremor = vento_turbulencia·sin(2,7·t + 1,7·fase)`; um travesso perpendicular
  (`0,35·balanco·sin(1,9·t + 2,3·fase)`) abre e fecha a folha.
- **Deslocamento em metros** (unidades do mundo): o vetor montado no mundo é
  projetado nos eixos da instância e dividido pela escala uniforme — a
  instância só gira em Y e escala igual.

Famílias registradas em `mapa.gd` (`vento_altura`, `vento_amplitude`):

| família | material | `vento_altura` | `vento_amplitude` |
|---|---|---|---|
| copa das árvores | `folha_arvore` | 9,0 m | 0,30 m |
| samambaia e sub-bosque (arbusto) | `folha` | 0,7 m | 0,13 m |
| capim (gramíneas) | `folha_capim` | 0,30 m | 0,09 m |

- **Madeira, solo e pedra não balançam:** o material deles não liga
  `vento_amplitude` (fica no padrão 0,0 e o `vertex()` sai cedo).
- **Sombra acompanha:** o `vertex()` roda também no passe de sombra; a sombra
  das folhas balança junto com a malha.
- **Frente local → mundo:** `aplicar_vento()` soma a posição do nó
  (`global_position.xz`) à frente local antes de mandar ao shader; o teste
  `test_vento_balanca_as_folhas` cobre essa conversão.

## Aproximação consciente (o limite)

O shader desenha **UMA** banda, não todas: `uniformizar()` escolhe a frente
mais **percebida** na origem do mapa por `força·e^-(d/largura)²`, com `d` a
distância da frente à origem — não a mais forte, e sim a que cruza a área
visível.

- O shader reimplementa uma versão de **desenho** da mesma lógica (gaussiana
  da banda + respiração/tremor), com constantes próprias; quem manda no
  **JOGO** é `sim/vento.gd`.
- As **fontes** de habilidade entram em `vetor`/`campo`, mas **ainda não** no
  balanço visual: `uniformizar()` não carrega fontes. É o próximo passo da
  habilidade de ar.
- Várias bandas ao mesmo tempo no shader também não existem: a segunda frente
  mais percebida não é desenhada.

## Reuso (P27: ar e água)

- **Habilidade de ar:** chama
  `main.vento.adicionar_fonte(pos, dir, forca, raio, duracao_s)` no MESMO
  objeto `main.vento` — sem criar campo nem duplicar relógio. O empurrão entra
  em `vetor`/`campo` e decai sozinho.
- **Água (quando existir):** lê `uniformizar()` — direção, força, frente,
  turbulência e tempo — e reage sem campo novo.
- **O que falta:** o balanço visual das fontes, a reação da água, a rajada
  desenhada por habilidade e várias bandas no shader. Nada disso está no
  código hoje; o pedido é o [P27](../PEDIDOS-EM-ESPERA.md) (ar e água).

## Como ver e ajustar

- **Filmar a cena de vento:** `DEMO_ARGS="--vento" tools/quadros.sh 90 <saída>`.
  A demo fixa a câmera e solta uma rajada **8 unidades a montante** do foco;
  `--vento` não roda o roteiro normal.
- **Ajustar o campo:** `dados/vento.json` (brisa, rajadas, vento forte,
  turbulência, fonte) — o mesmo arquivo que o `main` carrega.
- **Ajustar o desenho:** o par `vento_altura`/`vento_amplitude` das três
  famílias em `mapa.gd` (tabela acima).
- **Renderizador:** a prévia local roda em **Compatibility/OpenGL 3**; a
  verdade do CI é **Mobile/Vulkan**, e o shader compila nos dois — ver
  [`oráculo`](../ORACULO.md).

## Verificação

- `testes/test_vento.gd` — **12 testes**: dados do JSON, determinismo,
  direção unitária e força não negativa, `avancar` (dt 0 e negativo), variação
  da brisa, envelope do vento forte, rajada automática em `t = 0`, rajada
  varrendo o mapa, frente andando no rumo do vento, fonte somando e decaindo,
  contrato de `uniformizar()` e cfg parcial/absurdo.
- `testes/test_mapa_natureza_jogo.gd::test_vento_balanca_as_folhas` — as três
  famílias no vento, o relógio e a força chegando ao material e a frente local
  → mundo.
- O campo é determinístico: os testes comparam dois `Vento.new(...)` passo a
  passo, sem tolerância para sorteio.

## Limites / ainda não existe

- Água reagindo ao vento (o campo já entrega o que ela vai ler).
- Folhas soltas e partículas levadas pelo vento.
- Som de vento.
- Colisão, dano ou empurrão de corpo pelo vento.
- Rajada desenhada por habilidade (as fontes ainda não chegam ao shader).
- Várias bandas no shader (hoje uma, a mais percebida).
- O vento não muda o movimento da criatura nem a jogabilidade.
