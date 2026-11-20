# Build e entrega — o rito

## O rito de entrega (direto em `main`)

1. `tools/testes.sh` verde (testes + parser de todos os `.gd`).
2. Mudou algo visível? `tools/quadros.sh` e **abrir** os PNG.
3. `docs/HISTORICO.md`: seção `## vX.Y.Z — título (data)` no TOPO — o
   `exportar.sh` tira a versão do APK dela.
4. `docs/RESIDUOS.md`: uma linha por coisa vista e não consertada (ou "nenhum").
5. Segredo nenhum no diff: `rg -n "pixl_[0-9a-f]{8}|ghp_[A-Za-z0-9]{8}|github_pat_[A-Za-z0-9]{8}" .`
   vazio (o padrão exige caracteres de chave, então esta linha não casa consigo).
6. `git add <caminhos>` (nunca `-A`) → `git commit -m "vX.Y.Z: …"` →
   `git push origin main`.
7. CI: `tools/estado.sh --ci` até `completed`; vermelho → `node tools/ci-log.mjs`.
8. Verde → o APK novo está na Release `dev`:
   `node tools/baixar-apk.mjs` o põe em `/sdcard/Download/DSH-Go/` (avisando o
   operador).

## Versão

`vX.Y.Z`: Z conserta, Y entrega pacote/sistema, X é marco público (demo).
APK: `versionName` = `X.Y.Z-b<run>`, `versionCode` = número do run do CI
(sempre cresce). Marco para guardar: `git tag vX.Y.Z && git push origin vX.Y.Z`
→ Release própria com o APK (a `dev` é sobrescrita a cada push).

## O que o CI faz

`.github/workflows/ci.yml` — job `testes` (testes + oráculo, artefato
`quadros`) → job `apk` (export Android + Release). Detalhes do export e das
armadilhas: [`GODOT.md`](GODOT.md#8-exportar-para-android-p2--como-funciona-e-o-que-quebra).
