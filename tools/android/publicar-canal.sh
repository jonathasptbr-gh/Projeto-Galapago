#!/usr/bin/env bash
# Publica no canal PÚBLICO (repositório Projeto-Galapago-canal) só o número da
# versão do build que acabou de sair na Release `dev`. Roda no CI, depois do
# `gh release create dev`. O APK continua no repositório privado.
#   CANAL_KEY (secret CANAL_DEPLOY_KEY: deploy key com escrita SÓ no canal)
#   BUILD (nº do run = versionCode)  VERSAO (versionName)
set -euo pipefail
: "${CANAL_KEY:?falta o secret CANAL_DEPLOY_KEY}" "${BUILD:?}" "${VERSAO:?}"
REPO_CANAL="git@github.com:jonathasptbr-gh/Projeto-Galapago-canal.git"
APK="https://github.com/jonathasptbr-gh/Projeto-Galapago/releases/download/dev/projeto-galapago-dev.apk"

D=$(mktemp -d)
trap 'rm -rf "$D"' EXIT
printf '%s\n' "$CANAL_KEY" > "$D/chave"
chmod 600 "$D/chave"
export GIT_SSH_COMMAND="ssh -i $D/chave -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

git clone -q --depth 1 "$REPO_CANAL" "$D/canal"
cat > "$D/canal/canal.json" <<EOF
{
 "canal": "dev",
 "versao_codigo": ${BUILD},
 "versao_nome": "${VERSAO}",
 "publicado_em": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
 "apk": "${APK}"
}
EOF
cd "$D/canal"
git -c user.name="galapago-ci" -c user.email="ci@projetogalapago.invalid" add canal.json
git -c user.name="galapago-ci" -c user.email="ci@projetogalapago.invalid" commit -q -m "canal dev: ${VERSAO}"
git push -q origin HEAD
echo "canal publicado: ${VERSAO} (código ${BUILD})"
