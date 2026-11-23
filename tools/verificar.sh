#!/usr/bin/env bash
# Verificação SELETIVA do lote — o laço de iteração.
#   tools/verificar.sh                    → o que está alterado vs HEAD
#   tools/verificar.sh sim/gestos.gd ...  → áreas explícitas
#   tools/verificar.sh --base main        → alterado contra outra base
#   tools/verificar.sh --tudo             → tools/testes.sh (o gate do commit)
#
# Sempre roda o guardião documental; roda só os testes que tocam os arquivos
# alterados e só o parser dos scripts alterados. O gate (commit) continua
# sendo `tools/testes.sh` inteiro — ver docs/BUILD.md.
set -uo pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-$(command -v godot || echo "$HOME/.local/bin/godot")}"
export GODOT_SILENCE_ROOT_WARNING=1
BASE="HEAD"
declare -a PEDIDOS=()
TUDO=0
for arg in "$@"; do
  case "$arg" in
    --tudo) TUDO=1 ;;
    --base) BASE="__PROXIMO__" ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) if [ "$BASE" = "__PROXIMO__" ]; then BASE="$arg"; else PEDIDOS+=("$arg"); fi ;;
  esac
done
[ "$BASE" = "__PROXIMO__" ] && { echo "--base exige um ref" >&2; exit 2; }
if [ "$TUDO" -eq 1 ]; then exec tools/testes.sh; fi

if [ "${#PEDIDOS[@]}" -eq 0 ]; then
  mapfile -t PEDIDOS < <(
    { git -c safe.directory='*' diff --name-only --diff-filter=ACMR "$BASE" 2>/dev/null
      git -c safe.directory='*' ls-files --others --exclude-standard 2>/dev/null; } | awk 'NF' | sort -u
  )
fi

# Só arquivos que existem agora (deletado não tem o que verificar).
ARQUIVOS=()
for f in "${PEDIDOS[@]}"; do
  [ -f "$f" ] && ARQUIVOS+=("$f")
done
if [ "${#ARQUIVOS[@]}" -eq 0 ]; then
  echo "nada alterado — rodando o gate inteiro"; exec tools/testes.sh
fi

# 1) Guardião documental (offline, barato) — sempre.
tools/docs.sh || exit "$?"

# 2) Só documentação? O guardião acima já cobriu.
GD=()
JSON=0
for f in "${ARQUIVOS[@]}"; do
  case "$f" in
    *.gd) GD+=("$f") ;;
    dados/*.json) JSON=1 ;;
  esac
done
if [ "${#GD[@]}" -eq 0 ] && [ "$JSON" -eq 0 ]; then
  echo "verificar: só documentação/arte — nada a rodar além do guardião"; exit 0
fi

# 3) Mapa arquivo → testes. Um teste entra se referencia o arquivo
#    (`res://sim/x.gd`), se é o par pelo nome (`test_x.gd`) ou se o lote mexeu
#    em dados/ (que alimentam a simulação inteira).
declare -a TESTES=()
if [ "$JSON" -eq 1 ] || printf '%s\n' "${ARQUIVOS[@]}" | grep -q '^testes/'; then
  echo "verificar: dados/ ou testes/ mudou — todos os testes"
  while IFS= read -r t; do TESTES+=("${t##*/}"); done < <(find testes -name 'test_*.gd' | sort)
else
  for f in "${ARQUIVOS[@]}"; do
    case "$f" in sim/*.gd|jogo/*.gd) ;; *) continue ;; esac
    achou=0
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      TESTES+=("${t##*/}"); achou=1
    done < <(grep -l -F "res://$f" testes/test_*.gd 2>/dev/null || true)
    par="testes/test_$(basename "$f")"
    if [ -f "$par" ]; then TESTES+=("$(basename "$par")"); achou=1; fi
    if [ "$achou" -eq 0 ]; then
      echo "verificar: $f sem teste que o cite — rodando TODOS (regra fora de teste é risco)" >&2
      while IFS= read -r t; do TESTES+=("${t##*/}"); done < <(find testes -name 'test_*.gd' | sort)
    fi
  done
fi
# dedupe preservando ordem
if [ "${#TESTES[@]}" -gt 0 ]; then
  mapfile -t TESTES < <(printf '%s\n' "${TESTES[@]}" | awk 'NF && !visto[$0]++')
fi

# 4) Import (cache do .godot) e testes filtrados.
"$G" --headless --path . --import >/dev/null 2>&1 || true
rc=0
if [ "${#TESTES[@]}" -gt 0 ]; then
  filtro=$(IFS=,; echo "${TESTES[*]}")
  echo "verificar: ${#ARQUIVOS[@]} arquivo(s) · ${#TESTES[@]} teste(s): $filtro"
  saida=$(GALAPAGO_TESTES="$filtro" "$G" --headless --path . -s res://testes/run.gd 2>&1); r=$?
  printf '%s\n' "$saida" | grep -v -E '^Godot Engine v' | tail -20 || true
  if printf '%s\n' "$saida" | grep -q -E 'SCRIPT ERROR|Parse Error|Failed to load script'; then
    echo "REPROVADO: erro de script na saída (acima)." >&2; r=1
  fi
  [ "$r" -eq 0 ] || rc=1
else
  echo "verificar: nenhum teste mapeado"
fi

# 5) Parser só dos scripts alterados.
ruins=0
for f in "${GD[@]}"; do
  case "$f" in ./.godot/*|arte/fonte/*) continue ;; esac
  if ! out=$("$G" --headless --path . --check-only -s "res://${f#./}" 2>&1); then
    printf '  PARSE  %s\n%s\n' "$f" "$(printf '%s\n' "$out" | grep -E 'ERROR' | head -3)" >&2
    ruins=$((ruins + 1))
  fi
done
echo "parser: ${#GD[@]} script(s) alterado(s), $ruins com erro"
[ "$ruins" -eq 0 ] || rc=1
exit "$rc"
