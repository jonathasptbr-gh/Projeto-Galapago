# O oráculo de quadros — como o agente VÊ o jogo

O agente não tem GPU nem tela. Ele vê o jogo assim:

```
tools/quadros.sh [N=60] [saída=~/tmp/galapago-quadros]
```

roda a cena principal com o argumento de usuário `--demo` sob Xvfb + Mesa
por software, grava N quadros PNG (Movie Maker do Godot, `--write-movie`,
30 fps fixos) e depois o agente abre os PNG (ferramenta de leitura de imagem).

## Dois modos: prévia local × verdade no CI (P24, 2026-11-25)

O jogo roda em **Mobile (Vulkan)**, com fallback para Compatibility (OpenGL 3)
— ver [`GODOT`](GODOT.md#1-onde-o-godot-roda). O oráculo escolhe o renderizador
pela linha de comando, com `QUADROS_RENDER`:

| modo | flags | driver | onde |
|---|---|---|---|
| `previa` (padrão) | `--rendering-method gl_compatibility --rendering-driver opengl3` | Mesa por software, `GALLIUM_DRIVER` (`softpipe` por padrão) | celular do agente: olhar rápido de layout e movimento |
| `vulkan` | `--rendering-method mobile --rendering-driver vulkan` | lavapipe (`mesa-vulkan-drivers`); `VK_ICD_FILENAMES` = `/usr/share/vulkan/icd.d/lvp_icd.json` se existir e não vier definido | o CI (x86_64): a **verdade**, o renderizador do APK |

```
tools/quadros.sh 60 ~/tmp/q                               # prévia
QUADROS_RENDER=vulkan GALLIUM_DRIVER=llvmpipe tools/quadros.sh 60 quadros   # CI
```

A 1ª linha do `log.txt` diz o modo, as flags e os drivers; a linha do Godot
confirma o que subiu (`OpenGL API 3.3 … - Compatibility - … softpipe` ou
`Vulkan 1.x - Forward Mobile - … llvmpipe`). Reprova: sem quadros, com
`handle_crash` ou `SCRIPT ERROR` no log e, **no modo `vulkan`, se o log tiver
`OpenGL API`** (o fallback teria trocado o renderizador calado). Modo
desconhecido sai com código 2 antes de apagar a saída.

Prévia e verdade são renderizadores diferentes: diferença de borda, de
antialiasing e de mistura de cor entre os dois é esperada. Juízo final de cor e
efeito é sobre os quadros do CI (artefato `quadros`).

`DEMO_ARGS` passa argumentos extras para a demo. A cena do **inimigo hostil**
(v0.14) é `DEMO_ARGS="--hostil" tools/quadros.sh 240 ~/tmp/galapago-hostil`:
começa com a criatura perto do bicho, liga o botão, mostra os ataques e um
golpe roteirizado no fim (o estado ESCONDIDO precisa aparecer; um caminho
desenhado erraria o alvo móvel). O demo normal continua igual.

`QUADROS_CENA` filma outra cena (`--scene`; padrão: a principal), com os mesmos
argumentos. O Pixel Pass na cena principal: `QUADROS_FPS=10 DEMO_ARGS="--pixel"
tools/quadros.sh 30 ~/tmp/pixel` (o CI faz o mesmo em Vulkan, artefato
`pixel`). A vitrine 3D da Fundação (`jogo/mundo3d/vitrine.tscn`, com
`--sob-arvore`/`--quinas` do contorno de tela) saiu com a Fundação em
2026-11-27. A prévia roda a janela em 720×1280, então o liso sai na mesma
resolução do canvas — a resolução física só aparece no aparelho.

## Fatos medidos (2026-11-20, Godot 4.7.2)

- **Neste celular (proot, aarch64):** o driver `llvmpipe` inicializa o OpenGL
  4.5 e o processo morre com **SIGILL** (JIT do LLVM). O `softpipe` (sem JIT)
  funciona: OpenGL 3.3 Core. O script já usa `softpipe` por padrão. Tempo: 60
  quadros 320×180 em ~22 s (v0.1); 60 quadros 1280×720 com a ilha em ~40 s
  (v0.3); **v0.6 em retrato: 60 quadros 720×1280 em ~1 min 46 s** (cena nova,
  demo com âncora e tempo lento); **v0.7: 96 quadros em ~2,5 s/quadro** (traço
  ao vivo, véu e rampa).
- **`opengl3_es` não carrega aqui** (sem EGL).
- **Vulkan neste celular (2026-11-25):** com `mesa-vulkan-drivers` instalado,
  o lavapipe sobe (`Vulkan 1.4.318 - Forward Mobile - Using Device #0: … llvmpipe
  (LLVM 20.1.2)`) e o processo **cai com sinal 4** antes do 1º quadro (mesmo
  JIT do LLVM). Modo `vulkan` só no CI.
- **No CI (x86_64)** o workflow roda `QUADROS_RENDER=vulkan` (lavapipe; até o
  P24 era OpenGL com `llvmpipe`) e publica os quadros como artefato `quadros`
  (7 dias; 90 nas publicações, que servem de referência). O resumo do run
  traz a linha do Godot que diz o renderizador.

## Comparação com a última publicação (CI)

Nenhum PNG de referência mora no git. A **referência** é o artefato `quadros`
da última execução bem-sucedida do `ci.yml` em `main` disparada por um commit
de publicação (`vX.Y.Z: …`); a primeira foi a do CI #104 (v0.34.3). Em todo
run, depois de gravar os quadros, o job `testes` roda:

```
node tools/quadros-referencia.mjs [pasta=quadros] [--dest <dir>] [--min 50]
```

- Acha a referência pela API do GitHub (`GITHUB_TOKEN`, permissão
  `actions: read`), baixa, compara com `tools/quadros-diff.mjs --aviso` e
  escreve o resultado no **resumo do run** (referência, resultado e a saída do
  diff).
- **Diferença visual é AVISO, não reprova**: mudar o visível é o normal de um
  lote; quem julga é o agente abrindo os quadros e o operador no chat.
  **Reprova só** crash (o `tools/quadros.sh` já falha) e **quadros faltando**
  (menos que `--min`, ou menos que a referência).
- Sem referência (nenhuma publicação com artefato válido, API fora do ar) →
  aviso no resumo e segue.
- Tolerância do diff: **canal 6** (ruído do mesmo driver) e **0,1% dos
  pixels** por quadro (921 em 720×1280); a saída diz o quadro, quantos pixels,
  o maior delta e a caixa `x0,y0,x1,y1`. `--atualizar` do `quadros-diff.mjs`
  copia uma pasta para outra (uso local).

**Localmente** o modo é `previa` (Compatibility/softpipe ≠ Mobile/lavapipe
do CI): o agente usa `tools/quadros.sh` e **abre** os PNG. Para olhar a referência,
`node tools/quadros-referencia.mjs --baixar` a põe em `testes/baseline/`
(ignorado pelo git, com `.gdignore`); comparar a prévia com ela acusa
diferença legítima de renderizador. **A 1ª publicação depois do P24** compara
Vulkan com uma referência ainda OpenGL: o aviso de diferença nesse run é
esperado e some na publicação seguinte.

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

## Mapa de testes NATUREZA (3D)

> **2026-11-26:** a cena piloto standalone (`jogo/mundo3d/natureza/piloto.tscn`)
> e o ensaio da água de grade (P27, `agua_ensaio.tscn`) foram **removidos**
> por decisão do operador; os comandos deles estão no histórico do git (o
> ensaio no commit `64f0d2f`). A mata segue viva como mapa jogável.

Desde a v0.36.0 a mata é mapa jogável e, desde 2026-11-27, o **ÚNICO mapa do
jogo** (a Fundação saiu). A cena principal roda a demo de sempre nela
(caminho, giro pela barra, tiro, pulo, perseguição, cavar na clareira):
`tools/quadros.sh 40 ~/tmp/natureza-jogo` (some `DEMO_ARGS="--pixel"` para o
Pixel Pass). O CI filma a Natureza (o argumento antigo `--natureza` não
existe mais). A referência do CI é a última publicação: até a próxima, a
comparação aponta diferença em todos os quadros (eram da Fundação). A [direção e
orçamento](ARTE.md#mata-3d--direção-em-avaliação-2026-11-26) estão no guia de
arte.

### Vulkan local: workaround medido, não portátil

Em **2026-11-26**, neste host aarch64/proot, o shim `LD_PRELOAD` abaixo permitiu
renderizar a mata (então na cena piloto, hoje removida) em **Vulkan / Forward
Mobile / llvmpipe**, confirmado no cabeçalho do log. O shim força uma CPU LLVM
compatível; desligar SVE/SVE2 e o cache foi necessário para evitar SIGILL. A
fonte é [`tools/lvpshim.c`](../tools/lvpshim.c) (o cabeçalho explica o porquê);
o binário é local, **fora do git**, e não é requisito do jogo nem do CI.
Compila-se uma vez por host:

```bash
mkdir -p ~/tmp/lvpshim && gcc -shared -fPIC -O2 -o ~/tmp/lvpshim/shim.so tools/lvpshim.c -ldl
```

Depois (não reconferido na cena principal):

```bash
LD_PRELOAD=/root/tmp/lvpshim/shim.so SHIM_FEATS='-sve,-sve2' MESA_SHADER_CACHE_DISABLE=true \
QUADROS_RENDER=vulkan GALLIUM_DRIVER=llvmpipe \
tools/quadros.sh 2 ~/tmp/natureza-vulkan
```

**Não rodar imports/renderizações concorrentes neste clone**. Sem o shim, usar
a prévia Compatibility/softpipe padrão, sem `LD_PRELOAD`, ou renderizar Vulkan
no CI compatível. A captura Vulkan de revisão teve 2 quadros em 14 s de
gravação; isso **não é benchmark mobile**. A prévia é útil para composição,
mas não deve ser apresentada como imagem idêntica à do APK: **não foi
validada a equivalência de cor e sombra no Compatibility**. Sempre abrir o PNG
e conferir o renderizador real no log antes de concluir.
