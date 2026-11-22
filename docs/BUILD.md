# Build e entrega — o rito

## O rito de entrega (direto em `main`)

1. `tools/testes.sh` verde (guardião documental + testes + parser de todos
   os `.gd`). Só documentação: `tools/docs.sh` é a checagem rápida offline;
   o rito completo continua exigindo a suíte. Escopo e limites:
   [`DOCUMENTACAO.md`](DOCUMENTACAO.md).
2. Mudou algo visível? `tools/quadros.sh` e **abrir** os PNG.
3. `docs/HISTORICO.md`: seção `## vX.Y.Z — título (data)` no TOPO — o
   `exportar.sh` tira a versão do APK dela.
4. `docs/RESIDUOS.md`: uma linha por coisa vista e não consertada (ou "nenhum").
5. Segredo nenhum no diff: `rg -n "pixl_[0-9a-f]{8}|ghp_[A-Za-z0-9]{8}|github_pat_[A-Za-z0-9]{8}" .`
   vazio (o padrão exige caracteres de chave, então esta linha não casa consigo).
6. `git add <caminhos>` (nunca `-A`) → `git commit -m "vX.Y.Z: …"` →
   `git push origin main`.
7. CI: `tools/estado.sh --ci` até `completed`; vermelho → `node tools/ci-log.mjs`.
8. Verde → o APK novo e o `versao.json` estão na Release `dev`: o app do
   operador oferece a atualização ao abrir. Primeira instalação (ou chave
   trocada): `node tools/baixar-apk.mjs` põe o APK em `/sdcard/Download/DSH-Go/`
   (avisando o operador).

## Versão

`vX.Y.Z`: Z conserta, Y entrega pacote/sistema, X é marco público (demo).
APK: `versionName` = `X.Y.Z-b<run>`, `versionCode` = número do run do CI
(sempre cresce). Marco para guardar: `git tag vX.Y.Z && git push origin vX.Y.Z`
→ Release própria com o APK (a `dev` é sobrescrita a cada push).

## O que o CI faz

`.github/workflows/ci.yml` — job `testes` (testes + oráculo, artefato
`quadros`) → job `apk` (export Android + Release). Detalhes do export e das
armadilhas: [`GODOT.md`](GODOT.md#8-exportar-para-android-p2--como-funciona-e-o-que-quebra).

## Atualização automática do app

**O método do Áudio Visual IASD** (decisão do operador, 2026-11-20, v0.3.1 —
substituiu o canal separado da v0.3.0). O repositório é PÚBLICO.

```
push em main → CI: APK assinado (keystore dos secrets)
             → Release `dev` com DOIS assets: projeto-galapago-dev.apk + versao.json
app abre → jogo/atualizador.gd lê
           github.com/jonathasptbr-gh/Projeto-Galapago/releases/download/dev/versao.json
         → sim/atualizacao.gd: versao_codigo > galapago/build deste APK?
         → "Nova versão X disponível (25,3 MB)  [Atualizar] [Depois]"
         → Atualizar: baixa DENTRO do app, com barra, para user://atualizacao/
         → confere o tamanho (bytes do manifesto) → OS.shell_open(arquivo)
         → o Godot entrega por content:// (FileProvider) ao instalador do Android
         → o operador confirma; na 1ª vez o Android pede "permitir instalar apps"
```

- `versao.json`: `versao_codigo` (= nº do run = versionCode), `versao_nome`,
  `apk` (link do asset), `bytes`, `sha256`, `commit`, `publicado_em`.
- **Segurança (a mesma do IASD):** o Android só instala por cima um APK com a
  MESMA assinatura — é isso que protege. Ao lado: `apk` só `https` em
  `github.com` (host travado), teto de 300 MB, e o download só vai ao
  instalador com o tamanho EXATO do manifesto (corpo truncado não passa).
- `releases/download/...` não usa a API (sem limite, sem login) e não tem o
  cache de 5 min do `raw.githubusercontent.com` (medido na v0.3.0).
- O build local (fora do CI) tem `galapago/build=0` e nunca pergunta.
- Permissão `android.permission.REQUEST_INSTALL_PACKAGES` em
  `permissions/custom_permissions` do preset (não está na lista pronta do
  Godot 4.7). `OS.shell_open` com caminho de arquivo: conferido no
  `GodotIO.java` da tag 4.7.2-stable; o `FileProvider` (`<pacote>.fileprovider`,
  `files-path "/"`) vem no manifesto da biblioteca do Godot.

## O keystore (assinatura)

- **Nunca no repositório** (ele é público). No CI: secrets
  `ANDROID_KEYSTORE_B64` (o arquivo PKCS12 em base64) e
  `ANDROID_KEYSTORE_SENHA`; o job grava em `$RUNNER_TEMP` e apaga depois.
- **Cópia de segurança do operador:** cofre do DSH, refs
  `GALAPAGO_KEYSTORE_B64` e `GALAPAGO_KEYSTORE_SENHA`. Perder a chave = o app
  instalado não aceita mais atualização (é preciso desinstalar).
- Alias `galapago`, RSA 3072, SHA-256 do certificado
  `A0:D4:A9:90:B0:0E:2E:BF:3E:73:3E:4B:DE:DA:EB:C6:45:3C:63:90:7D:A8:ED:81:E5:01:79:53:89:1B:41:D0`.
- A chave de desenvolvimento da v0.2.0 (`galapago-dev.keystore`, senha no
  script) continua no HISTÓRICO do git, que ficou público: ela está REVOGADA na
  prática — o aparelho do operador passa a confiar só na nova (reinstalação
  única na v0.3.1). Nunca reutilizá-la.
