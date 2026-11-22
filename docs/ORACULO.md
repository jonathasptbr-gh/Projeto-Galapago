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
