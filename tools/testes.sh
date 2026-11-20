#!/usr/bin/env bash
# Testes headless da camada sim/ (e de tudo em testes/test_*.gd).
# Reprova também erro de script/parse na saída: em GDScript ele não derruba o
# processo, só imprime — e um teste que nem rodou não pode passar calado.
set -uo pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-$(command -v godot || echo "$HOME/.local/bin/godot")}"
export GODOT_SILENCE_ROOT_WARNING=1

"$G" --headless --path . --import >/dev/null 2>&1
saida=$("$G" --headless --path . -s res://testes/run.gd 2>&1); rc=$?
printf '%s\n' "$saida" | grep -v -E '^Godot Engine v' || true
if printf '%s\n' "$saida" | grep -q -E 'SCRIPT ERROR|Parse Error|Failed to load script'; then
  echo "REPROVADO: erro de script na saída (acima)." >&2
  rc=1
fi
exit "$rc"
