#!/usr/bin/env bash
# Exporta o APK Android (template release, assinado com o keystore de DEV).
#   tools/android/exportar.sh [build=1]
# Precisa de: Godot 4.7.2, templates Android em
# ~/.local/share/godot/export_templates/4.7.2.stable/, JDK 17 (JAVA_HOME) e
# SDK Android (ANDROID_HOME, com platform-tools e build-tools). Neste celular
# não há SDK: o APK nasce no CI (job `apk` do ci.yml). Ver docs/GODOT.md.
set -euo pipefail
cd "$(dirname "$0")/../.."
G="${GODOT:-$(command -v godot || echo "$HOME/.local/bin/godot")}"
BUILD="${1:-1}"
VER=$(grep -m1 -oE '^## v[0-9]+\.[0-9]+\.[0-9]+' docs/HISTORICO.md | cut -c5-)
NOME="${VER}-b${BUILD}"
export GODOT_SILENCE_ROOT_WARNING=1
: "${JAVA_HOME:?defina JAVA_HOME (JDK 17)}"
ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
: "${ANDROID_HOME:?defina ANDROID_HOME (SDK Android)}"
# Keystore de DESENVOLVIMENTO (versionado de propósito: só assina builds de
# teste, para cada APK instalar por cima do anterior). A chave da LOJA é outra
# e nunca entra no repositório. O ambiente pode sobrepor as três.
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-$PWD/tools/android/galapago-dev.keystore}"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="${GODOT_ANDROID_KEYSTORE_RELEASE_USER:-galapago}"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:-galapago-dev}"

# 1. import (cria também as editor settings na 1ª execução)
"$G" --headless --path . --import >/dev/null 2>&1 || true

# 2. editor settings: no 4.7 os caminhos do JDK e do SDK moram AQUI, não em
#    variável de ambiente (o padrão gravado é /root/Android/Sdk).
mkdir -p "$HOME/.config/godot"
ES="$HOME/.config/godot/editor_settings-4.7.tres"
[ -f "$ES" ] || printf '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n' > "$ES"
python3 - "$ES" "$JAVA_HOME" "$ANDROID_HOME" <<'EOF'
import re, sys
p, java, sdk = sys.argv[1:]
s = open(p, encoding="utf-8").read()
for k, v in (("export/android/java_sdk_path", java), ("export/android/android_sdk_path", sdk)):
    linha = f'{k} = "{v}"'
    if re.search(rf"^{re.escape(k)} = ", s, re.M):
        s = re.sub(rf"^{re.escape(k)} = .*$", linha, s, flags=re.M)
    else:
        s = s.rstrip("\n") + "\n" + linha + "\n"
open(p, "w", encoding="utf-8").write(s)
EOF

# 3. versão do build num preset temporário (o arquivo versionado não muda)
cp export_presets.cfg export_presets.cfg.orig
trap 'mv -f export_presets.cfg.orig export_presets.cfg' EXIT
sed -i -E "s/^version\/code=.*/version\/code=${BUILD}/; s/^version\/name=.*/version\/name=\"${NOME}\"/" export_presets.cfg

# 4. exportar
mkdir -p exportar
APK="exportar/projeto-galapago.apk"
rm -f "$APK"
"$G" --headless --path . --export-release "Android" "$APK" 2>&1 | grep -v -E '^\s*$|first_scan_filesystem' | tee exportar/log.txt || true
if [ ! -s "$APK" ]; then
  echo "REPROVADO: APK não gerado (log acima e em exportar/log.txt)" >&2
  exit 1
fi

# 5. conferir: pacote, versão e assinatura
BT=$(ls -d "$ANDROID_HOME"/build-tools/* 2>/dev/null | sort -V | tail -1)
if [ -n "$BT" ]; then
  "$BT/aapt" dump badging "$APK" 2>/dev/null | grep -E "^package:|^launchable-activity:|^sdkVersion|^targetSdkVersion" || true
  "$BT/apksigner" verify --print-certs "$APK" | grep -E "Signer #1 certificate DN|Verified" || true
fi
echo "APK: $APK · versão $NOME · $(du -h "$APK" | cut -f1)"
echo "versao=$NOME" >> "${GITHUB_OUTPUT:-/dev/null}"
