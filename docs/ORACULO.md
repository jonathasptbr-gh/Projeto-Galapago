# O oráculo de quadros — como o agente VÊ o jogo

O agente não tem GPU nem tela. Ele vê o jogo assim:

```
tools/quadros.sh [N=60] [saída=~/tmp/galapago-quadros]
```

roda a cena principal com o argumento de usuário `--demo` sob Xvfb + Mesa
por software, grava N quadros PNG (Movie Maker do Godot, `--write-movie`,
30 fps fixos) e depois o agente abre os PNG (ferramenta de leitura de imagem).

## Fatos medidos (2026-11-20, Godot 4.7.2)

- **Neste celular (proot, aarch64):** o driver `llvmpipe` inicializa o OpenGL
  4.5 e o processo morre com **SIGILL** (JIT do LLVM). O `softpipe` (sem JIT)
  funciona: OpenGL 3.3 Core. 60 quadros 320×180 em ~22 s de relógio. O script
  já usa `softpipe` por padrão.
- **`opengl3_es` não carrega aqui** (sem EGL).
- **No CI (x86_64)** o workflow usa `llvmpipe` e publica os quadros como
  artefato `quadros` (7 dias).

## Limites

- Não é interativo: é uma gravação. Toque se roteiriza na cena (o modo
  `--demo` hoje; `Input.parse_input_event` para gestos roteirizados quando o
  pacote de gestos chegar).
- Software: lento para resoluções grandes — mantenha 320×180 interno.
- Ver o quadro confere layout, cor, posição e quebra grosseira; **juízo fino
  de pixel art** (contorno, leitura da silhueta) é do operador, e regras
  objetivas (paleta, tamanho, transparência) viram script em `tools/`.
