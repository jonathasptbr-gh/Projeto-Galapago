#!/usr/bin/env bash
# Oráculo visual: roda a cena principal em modo --demo e grava N quadros PNG,
# sem GPU (Xvfb + Mesa por software). Ver docs/ORACULO.md.
#   tools/quadros.sh [N=60] [saída=~/tmp/galapago-quadros]   (QUADROS_FPS=30 por padrão)
#   DEMO_ARGS="--hostil" tools/quadros.sh 180 ...  → cena de inimigo hostil
#   QUADROS_RENDER=previa|vulkan (padrão previa):
#     previa → Compatibility/OpenGL 3 por software (GALLIUM_DRIVER, softpipe
#              por padrão: neste celular o llvmpipe morre com SIGILL no JIT);
#     vulkan → Mobile/Vulkan por software (lavapipe; VK_ICD_FILENAMES aponta o
#              lvp_icd.json se existir). É o modo do CI (x86_64); neste
#              celular o lavapipe cai com sinal 4.
set -euo pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-$(command -v godot || echo "$HOME/.local/bin/godot")}"
N="${1:-60}"
SAIDA="${2:-$HOME/tmp/galapago-quadros}"
# argumentos extras da demo (ex.: --hostil); a expansão SEM quotes é intencional
DEMO_ARGS="${DEMO_ARGS:-}"
case "$SAIDA" in ""|/|"$HOME"|.) echo "saída perigosa: '$SAIDA'" >&2; exit 2;; esac

MODO="${QUADROS_RENDER:-previa}"
case "$MODO" in
  previa) RENDER=(--rendering-method gl_compatibility --rendering-driver opengl3) ;;
  vulkan)
    RENDER=(--rendering-method mobile --rendering-driver vulkan)
    LVP=/usr/share/vulkan/icd.d/lvp_icd.json
    if [ -z "${VK_ICD_FILENAMES:-}" ] && [ -f "$LVP" ]; then export VK_ICD_FILENAMES="$LVP"; fi ;;
  *) echo "QUADROS_RENDER inválido: '$MODO' (previa|vulkan)" >&2; exit 2 ;;
esac

rm -rf "${SAIDA:?}"; mkdir -p "$SAIDA"
export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER="${GALLIUM_DRIVER:-softpipe}" GODOT_SILENCE_ROOT_WARNING=1
"$G" --headless --path . --import >/dev/null 2>&1 || true
{
  echo "quadros.sh: modo=$MODO render=${RENDER[*]} GALLIUM_DRIVER=$GALLIUM_DRIVER VK_ICD_FILENAMES=${VK_ICD_FILENAMES:-}"
  xvfb-run -a -s "-screen 0 720x1280x24" "$G" --path . "${RENDER[@]}" \
    --audio-driver Dummy --resolution 720x1280 --write-movie "$SAIDA/q.png" \
    --fixed-fps "${QUADROS_FPS:-30}" --quit-after "$N" -- --demo $DEMO_ARGS 2>&1 || true
} >"$SAIDA/log.txt"
rm -f "$SAIDA"/q*.wav

n=$(find "$SAIDA" -name 'q*.png' | wc -l)
if [ "$n" -eq 0 ] || grep -q -E 'handle_crash|SCRIPT ERROR' "$SAIDA/log.txt"; then
  echo "REPROVADO: $n quadros; log em $SAIDA/log.txt" >&2
  grep -E 'handle_crash|ERROR' "$SAIDA/log.txt" | head -5 >&2 || true
  exit 1
fi
# fallback_to_opengl3 está ligado: sem Vulkan utilizável o Godot cai calado para
# OpenGL 3 e os quadros sairiam do renderizador errado — no modo vulkan, reprova.
if [ "$MODO" = vulkan ] && grep -q '^OpenGL API' "$SAIDA/log.txt"; then
  echo "REPROVADO: modo vulkan caiu para OpenGL (fallback); log em $SAIDA/log.txt" >&2
  grep -m3 -i -E 'vulkan|^OpenGL API' "$SAIDA/log.txt" >&2 || true
  exit 1
fi
echo "$n quadros em $SAIDA [modo $MODO] (último: $(find "$SAIDA" -name 'q*.png' | sort | tail -1))"
