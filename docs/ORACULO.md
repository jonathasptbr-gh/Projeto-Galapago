# O oráculo de quadros — como o agente VÊ o jogo

O agente não tem GPU nem tela. Ele vê o jogo assim:

```
tools/quadros.sh [N=60] [saída=~/tmp/galapago-quadros]
```

roda a cena principal com o argumento de usuário `--demo` sob Xvfb + Mesa
por software, grava N quadros PNG (Movie Maker do Godot, `--write-movie`,
30 fps fixos) e depois o agente abre os PNG (ferramenta de leitura de imagem).

`DEMO_ARGS` passa argumentos extras para a demo. A cena do **inimigo hostil**
(v0.14) é `DEMO_ARGS="--hostil" tools/quadros.sh 240 ~/tmp/galapago-hostil`:
começa com a criatura perto do bicho, liga o botão, mostra os ataques e um
golpe roteirizado no fim (o estado ESCONDIDO precisa aparecer; um caminho
desenhado erraria o alvo móvel). O demo normal continua igual.

## Fatos medidos (2026-11-20, Godot 4.7.2)

- **Neste celular (proot, aarch64):** o driver `llvmpipe` inicializa o OpenGL
  4.5 e o processo morre com **SIGILL** (JIT do LLVM). O `softpipe` (sem JIT)
  funciona: OpenGL 3.3 Core. O script já usa `softpipe` por padrão. Tempo: 60
  quadros 320×180 em ~22 s (v0.1); 60 quadros 1280×720 com a ilha em ~40 s
  (v0.3); **v0.6 em retrato: 60 quadros 720×1280 em ~1 min 46 s** (cena nova,
  demo com âncora e tempo lento); **v0.7: 96 quadros em ~2,5 s/quadro** (traço
  ao vivo, véu e rampa).
- **`opengl3_es` não carrega aqui** (sem EGL).
- **No CI (x86_64)** o workflow usa `llvmpipe` e publica os quadros como
  artefato `quadros` (7 dias).

## Diff automático contra o baseline

`testes/baseline/` guarda os 60 quadros do CI #38 (commit `5846789`, mesmo
ambiente `llvmpipe` do workflow). O CI compara cada rodada com eles **depois**
de gerar os quadros e **antes** do artefato; o upload é `if: always()`, então
os quadros de uma rodada reprovada continuam disponíveis para diagnóstico.

```
node tools/quadros-diff.mjs [pasta=quadros] [--baseline=testes/baseline] [--canal=6] [--px=0.001] [--atualizar]
```

- Compara os `q*.png` dos dois lados em ordem numérica. **Quadro faltando ou
  sobrando reprova** e lista os nomes.
- Por quadro, conta os pixels em que **qualquer canal** difere por mais de
  `--canal`; reprova se essa fração passar de `--px` (0,001 = 0,1% da
  imagem). A falha diz o quadro, quantos pixels (e %), o maior delta e a caixa
  `x0,y0,x1,y1` (inclusive).
- Defaults: **canal 6** (ruído de rasterização do mesmo driver) e **0,1% de
  pixels** (921 pixels em 720×1280 — um pixel isolado não reprova, um bloco
  sim). Não afrouxe a tolerância para fazer um lote passar.
- Código de saída: `0` ok · `1` divergência/quadro faltando · `2` uso ou erro
  de leitura (baseline ausente/vazio também é `2`, com a instrução abaixo).
- `--atualizar` copia a pasta inteira para o baseline (cria o diretório e
  remove do baseline os `q*.png` que não existem mais) e **não compara**. É o
  caminho explícito de quem muda o visível de propósito.
- O baseline é do `llvmpipe` do CI; neste celular o driver é `softpipe`, então
  o diff local pode acusar diferença legítima de renderizador — e **não** se
  gera baseline confiável aqui. A prova é o CI.

**Regra:** o baseline do lote visível é **gerado pelo CI antes do commit** e
entra no MESMO commit, com a linha "baseline dos quadros atualizado: …" no
`docs/HISTORICO.md`. O branch precisa estar no remoto antes de disparar:

```bash
git push -u origin lote/vX.Y.Z
gh workflow run ci.yml -f ref=lote/vX.Y.Z     # job `baseline` (llvmpipe)
node tools/quadros-baseline.mjs --run <run>   # aplica o artefato em testes/baseline
git add testes/baseline                       # junto com a mudança visível
```

Sem esse caminho o lote visível gasta dois pushes e deixa `main` vermelha entre
eles — era o que acontecia até a v0.26.0. Procedimento completo em
[`BUILD.md`](BUILD.md).

## Limites

- Não é interativo: é uma gravação. Toque se roteiriza na cena (o modo
  `--demo` hoje; `Input.parse_input_event` para gestos roteirizados quando o
  pacote de gestos chegar).
- Software: **720×1280 é viável (~1,8 s por quadro aqui em 2026-11-20)**;
  evite gravar centenas de quadros — 60 bastam para conferir movimento. A demo
  completa (~16 s de jogo) pede ~480 quadros e leva ~15 min neste celular; rode
  em segundo plano ou use só os 60 do CI.
- Ver o quadro confere layout, cor, posição e quebra grosseira; **juízo fino
  de pixel art** (contorno, leitura da silhueta) é do operador, e regras
  objetivas (paleta, tamanho, transparência) viram script em `tools/`.
