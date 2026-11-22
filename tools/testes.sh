#!/usr/bin/env bash
# Guardião documental + testes headless da camada sim/ (e de tudo em
# testes/test_*.gd). Reprova também erro de script/parse na saída: em GDScript
# ele não derruba o processo, só imprime — e um teste que nem rodou não pode
# passar calado.
set -uo pipefail
cd "$(dirname "$0")/.."
# Falha documental interrompe antes de importar/rodar o Godot (local e CI).
tools/docs.sh || exit "$?"
G="${GODOT:-$(command -v godot || echo "$HOME/.local/bin/godot")}"
export GODOT_SILENCE_ROOT_WARNING=1

"$G" --headless --path . --import >/dev/null 2>&1
saida=$("$G" --headless --path . -s res://testes/run.gd 2>&1); rc=$?
printf '%s\n' "$saida" | grep -v -E '^Godot Engine v' || true
if printf '%s\n' "$saida" | grep -q -E 'SCRIPT ERROR|Parse Error|Failed to load script'; then
  echo "REPROVADO: erro de script na saída (acima)." >&2
  rc=1
fi

# Todo .gd do projeto passa pelo parser (--check-only), inclusive os que nenhum
# teste carrega (jogo/). Pastas com .gdignore ficam de fora, como no Godot.
ruins=0
while IFS= read -r f; do
  if ! out=$("$G" --headless --path . --check-only -s "res://${f#./}" 2>&1); then
    printf '  PARSE  %s\n%s\n' "$f" "$(printf '%s\n' "$out" | grep -E 'ERROR' | head -3)" >&2
    ruins=$((ruins + 1))
  fi
done < <(find . -name '*.gd' -not -path './.godot/*' -not -path './arte/fonte/*' | sort)
echo "parser: $(find . -name '*.gd' -not -path './.godot/*' -not -path './arte/fonte/*' | wc -l) scripts, $ruins com erro"
[ "$ruins" -eq 0 ] || rc=1
exit "$rc"
