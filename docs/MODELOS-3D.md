# Modelos 3D prontos — o padrão das criaturas

> **Decisão do operador (2026-11-26):** criatura e modelo animado vêm de
> **modelo 3D pronto e animado, baixado com licença aceita, com pequenos
> ajustes**. O rig próprio saiu no commit `562c4bc`. A mata continua
> **autoral** (malhas geradas por código, sem download): ver
> [mata 3D](ARTE.md#mata-3d--direção-em-avaliação-2026-11-26). Pixel art 2D
> (PixelLab) é outro guia: [ARTE](ARTE.md).

## Fluxo, do achado à aprovação

1. **Buscar** (sem chave): `node tools/sketchfab.mjs buscar <termo>` — só
   modelos baixáveis **e** animados; mostra uid, autor, licença, nº de clipes,
   faces e o veredito da licença. `info <uid>` dá a ficha de um.
2. **Baixar** para cache passageiro:
   `node tools/sketchfab.mjs baixar <uid> ~/tmp/modelos/<Nome>.glb` — recusa
   licença fora do padrão e grava `<Nome>.credito.txt` ao lado.
3. **Prancha** para o operador (por CPU, roda no celular):
   `node tools/prancha3d/render.mjs <clipe> 8 <Nome>.glb ~/tmp/<nome>-<clipe>.png`
   (`--clipes <glb>` lista os clipes). Vários candidatos de uma vez:
   `node tools/prancha3d/mosaico.mjs <pasta> ~/tmp/mosaico.png`. Uma vez por
   clone: `cd tools/prancha3d && npm ci` (`node_modules` fica fora do git).
4. **Abrir o PNG** e mostrá-lo **neste chat** com a ficha (autor, licença,
   faces, clipes). A escolha é do operador; o agente propõe opções.
5. Só o **escolhido** entra no repositório (abaixo), com o crédito junto.

A prancha é vista lateral, sem textura (o node não decodifica imagem: o que
era textura sai cinza). Julga **silhueta e movimento**; cor e Pixel Pass se
julgam depois, no Godot, pelo [oráculo](ORACULO.md).

## Fontes

| fonte | como | observação |
|---|---|---|
| **Sketchfab** (principal) | `tools/sketchfab.mjs`; busca pública, download com chave | conta do operador, plano basic; chave só no cofre do harness, `refs.SKETCHFAB_TOKEN` (`~/.dsh/.credentials.yaml`) — nunca em chat, commit ou doc |
| **Poly Pizza** (Quaternius e outros) | página `https://poly.pizza/m/<id>` (licença e autor); GLB público em `https://static.poly.pizza/<arquivo>.glb`, sem chave | de onde vieram os candidatos de 2026-11-26; o kit não baixa daqui: o `.credito.txt` se escreve à mão, no mesmo formato |

Estudo mais largo de fontes (Smithsonian, Tripo, Truebones…) ficou fora do
repositório, como pesquisa; o que vale está nesta tabela.

## Licenças

- **Aceitas:** CC0 · CC Attribution (CC-BY, **crédito obrigatório**) ·
  Sketchfab *Free Standard*.
- **Recusadas:** NC (não comercial), ND (proíbe ajuste), SA (contamina a
  licença do jogo), licenças pagas (*Standard*, *Editorial*), modelo marcado
  como **gerado por IA** (procedência incerta) e **fan-art de marca**
  (Minecraft, Club Penguin, desenho animado… — direito de terceiro mesmo com
  CC-BY).
- O veredito automático (`avaliarLicenca` em
  [`sketchfab.mjs`](../tools/sketchfab.mjs), testado em
  [`sketchfab.test.mjs`](../tools/sketchfab.test.mjs), que roda no
  `tools/testes.sh`) cobre rótulo e marca de IA. **Fan-art se confere à
  mão**, olhando nome, descrição e imagem.

## Crédito (`<Nome>.credito.txt`)

Mora ao lado do `.glb`, sempre — mesmo em CC0, para rastrear a origem:

```text
"<título>" por <autor> — <licença> — <link>
fonte: sketchfab <uid> · baixado em AAAA-MM-DD
alterado: <o que mudou no arquivo>     (só se o .glb foi editado)
```

A 1ª linha é o texto do crédito no jogo. CC-BY exige crédito visível e
indicar alteração: **o jogo ainda não tem tela de créditos** — o primeiro
modelo CC-BY que entrar no jogo traz essa tela junto.

## Pequenos ajustes

Permitido, **sem tocar no `.glb`** (ele fica idêntico ao baixado, o crédito
continua verdadeiro e o download se refaz):

- escala, rotação, pivô e altura do chão;
- quais clipes entram, nome, laço, corte e velocidade de cada um;
- material: trocar pelo do projeto (toon, contorno, paleta) ou recolorir.

Isso vive no **import do Godot** (`<Nome>.glb.import`, commitado) e numa
cena que instancia o modelo em `jogo/`; o dado de jogo (velocidades, qual
clipe para qual ação) em `dados/`.

Editar o próprio `.glb` (reduzir polígonos, fundir malhas, consertar osso) só
**por script em `tools/`**, reprodutível, e com a linha `alterado:` no
crédito. Esculpir, trocar o esqueleto ou refazer a animação **não é pequeno
ajuste**: é outro modelo — volta ao operador. Licença ND nunca entra (ND
proíbe qualquer ajuste).

## Onde o modelo escolhido mora

`arte/modelos/<Nome>.glb` + `arte/modelos/<Nome>.credito.txt` (+ o `.import`
que o Godot gera). A pasta nasce com o primeiro escolhido. Candidato **não
entra no git**: peso, licença ainda não decidida e nada escolhido — fica em
`~/tmp/` (cache passageiro) e é registrado abaixo pelo link, que basta para
baixá-lo de novo.

## Candidatos registrados (2026-11-26)

Nenhum escolhido para o jogo. Licença conferida em 2026-11-26 na página
pública de cada um (Poly Pizza; Sketchfab pela API `/v3/models/<uid>`).
`arquivo` é o nome do GLB em `static.poly.pizza`.

| candidato | modelo · autor | fonte | licença | clipe da prancha |
|---|---|---|---|---|
| lobo | Wolf · Quaternius | [poly.pizza P1gU3Qkr9r](https://poly.pizza/m/P1gU3Qkr9r) · arquivo `f1d12388-e39b-4157-b32a-646a1d089fc4` | CC0 (conferida) | Gallop |
| pinguim | African penguin (Spheniscus demersus) Low poly · majorgalah | [sketchfab 9e59070815fe451d93398e2ebdb9bb92](https://sketchfab.com/3d-models/african-penguin-spheniscus-demersus-low-poly-9e59070815fe451d93398e2ebdb9bb92) | CC-BY 4.0 (conferida) | Walk |
| raposa | Fox · Quaternius | [poly.pizza Bc97C66HKi](https://poly.pizza/m/Bc97C66HKi) · `e18e86df-1692-48d8-ac6e-1e25ab4ad574` | CC0 (conferida) | Gallop |
| husky | Husky · Quaternius | [poly.pizza wcWiuEqwzq](https://poly.pizza/m/wcWiuEqwzq) · `611d25c7-430f-4bb5-ab2c-d8f5f3cb9712` | CC0 (conferida) | Gallop |
| shiba inu | Shiba Inu · Quaternius | [poly.pizza y4wdQpg767](https://poly.pizza/m/y4wdQpg767) · `ba6d0ee3-bcc0-4ef0-9d3c-a3e245b41c77` | CC0 (conferida) | Gallop |
| cavalo | Horse · Quaternius | [poly.pizza qvTrSG9pZF](https://poly.pizza/m/qvTrSG9pZF) · `d37dbc87-ca61-4b2c-a2da-d2f0c4240bef` | CC0 (conferida) | Gallop |
| cervo | Deer · Quaternius | [poly.pizza T6Cs7tmMHJ](https://poly.pizza/m/T6Cs7tmMHJ) · `4b6c2a41-43c7-404c-ae37-e8c4645ff93b` | CC0 (conferida) | Gallop |
| alpaca | Alpaca · Quaternius | [poly.pizza bCVFD48i2l](https://poly.pizza/m/bCVFD48i2l) · `444228bb-745d-49b2-89ef-cc12805deaa8` | CC0 (conferida) | Gallop |
| touro | Bull · Quaternius | [poly.pizza a8PIIYwF7r](https://poly.pizza/m/a8PIIYwF7r) · `5704ef69-2c27-4de8-a942-70a29458af21` | CC0 (conferida) | Gallop |
| gato | Cat · Quaternius | [poly.pizza qKICY6xla2](https://poly.pizza/m/qKICY6xla2) · `67f5e3fe-37ee-4c86-95c8-d269d8c9f8ba` | CC0 (conferida) | Run |
| porco | Pig · Quaternius | [poly.pizza u35l6uP5vj](https://poly.pizza/m/u35l6uP5vj) · `6277c120-ea5c-405d-9614-0d3d7e0b829d` | CC0 (conferida) | Run |
| ovelha | Sheep · Quaternius | [poly.pizza rgJXF570ZK](https://poly.pizza/m/rgJXF570ZK) · `d42145b6-ae20-48cd-ba36-63b03f901c32` | CC0 (conferida) | Run |
| T-Rex | T-Rex · Quaternius | [poly.pizza UYtneO5FpF](https://poly.pizza/m/UYtneO5FpF) · `34eed102-48f0-43dd-bc6f-ef7a6dfddfbb` | CC0 (conferida) | Run |
| velociraptor | Velociraptor · Quaternius | [poly.pizza cnlGH2UcDd](https://poly.pizza/m/cnlGH2UcDd) · `c1f0c4cb-c84f-415c-8323-d8cb871a2126` | CC0 (conferida) | Run |
| tricerátops | Triceratops · Quaternius | [poly.pizza IGvrUqGrRM](https://poly.pizza/m/IGvrUqGrRM) · `6aa1f3ff-b9b3-4bb5-9d85-b2ffa514f0cc` | CC0 (conferida) | Run |
| tubarão | Shark · Quaternius | [poly.pizza YYsK3gRCBZ](https://poly.pizza/m/YYsK3gRCBZ) · `840dac4f-e6b5-4015-88d7-ceb940a4b90e` | CC0 (conferida) | Swim_Fast |
| golfinho | Dolphin · Quaternius | [poly.pizza 3LzFgI3GLO](https://poly.pizza/m/3LzFgI3GLO) · `fcea284f-cafc-4be1-a701-2a0fd811ad5c` | CC0 (conferida) | Swim |
| cobra | Snake · Quaternius | [poly.pizza x9x0viZs8V](https://poly.pizza/m/x9x0viZs8V) · `0f3a551e-743e-48f5-936f-804c6c3b88bd` | CC0 (conferida) | Walk |
| sapo | Frog · Quaternius | [poly.pizza 9Z2V8fpazF](https://poly.pizza/m/9Z2V8fpazF) · `08416495-b056-4ed7-b23b-5a10e82277a0` | CC0 (conferida) | Jump |
| aranha | Spider · Quaternius | [poly.pizza yRYJiAJyiM](https://poly.pizza/m/yRYJiAJyiM) · `4259fbdb-afb5-4d40-9108-363625dd6b6e` | CC0 (conferida) | Walk |
| morcego | Bat · Quaternius | [poly.pizza hNO9XvjlKa](https://poly.pizza/m/hNO9XvjlKa) · `4ae13ae9-c257-41ed-86b5-1b4760924ebc` | CC0 (conferida) | Flying |
| gavião | Hawk Lp Rigged · Sherkiz | [poly.pizza RkN6MEbP6g](https://poly.pizza/m/RkN6MEbP6g) · `2a7aca61-a8f6-45f6-950e-003d4bfcab45` | CC-BY (conferida; versão 3.0 pela listagem, **a conferir** na página) | Fly |

Gato, porco e ovelha da Quaternius são de estilo blocado (outra série) e,
como o gavião, saem cinza na prancha (só textura). Qual é o melhor modelo de
cão/lobo está em [P29](PEDIDOS-EM-ESPERA.md#p29--modelo-do-lobocão-o-wolfglb-é-o-melhor-disponível).
