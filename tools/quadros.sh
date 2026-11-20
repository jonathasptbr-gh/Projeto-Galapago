#!/usr/bin/env bash
# Oráculo visual: roda a cena principal em modo --demo e grava N quadros PNG,
# sem GPU (Xvfb + Mesa por software). Ver docs/ORACULO.md.
#   tools/quadros.sh [N=60] [saída=~/tmp/galapago-quadros]
# Neste celular (proot, aarch64) o driver tem de ser softpipe: o llvmpipe morre
# com SIGILL no JIT. No CI (x86_64) o workflow passa GALLIUM_DRIVER=llvmpipe.
set -euo pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-$(command -v godot || echo "$HOME/.local/bin/godot")}"
N="${1:-60}"
SAIDA="${2:-$HOME/tmp/galapago-quadros}"
case "$SAIDA" in ""|/|"$HOME"|.) echo "saída perigosa: '$SAIDA'" >&2; exit 2;; esac

rm -rf "${SAIDA:?}"; mkdir -p "$SAIDA"
export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER="${GALLIUM_DRIVER:-softpipe}" GODOT_SILENCE_ROOT_WARNING=1
"$G" --headless --path . --import >/dev/null 2>&1 || true
xvfb-run -a -s "-screen 0 1280x720x24" "$G" --path . --rendering-driver opengl3 \
  --audio-driver Dummy --resolution 1280x720 --write-movie "$SAIDA/q.png" \
  --fixed-fps 30 --quit-after "$N" -- --demo >"$SAIDA/log.txt" 2>&1 || true
rm -f "$SAIDA"/q*.wav

n=$(find "$SAIDA" -name 'q*.png' | wc -l)
if [ "$n" -eq 0 ] || grep -q -E 'handle_crash|SCRIPT ERROR' "$SAIDA/log.txt"; then
  echo "REPROVADO: $n quadros; log em $SAIDA/log.txt" >&2
  grep -E 'handle_crash|ERROR' "$SAIDA/log.txt" | head -5 >&2 || true
  exit 1
fi
echo "$n quadros em $SAIDA (último: $(find "$SAIDA" -name 'q*.png' | sort | tail -1))"
