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

## Atualização automática do app

Decisão do operador (2026-11-20): **tudo privado** — público só o número da
versão.

```
push em main → CI: APK → Release `dev` (privada)
             → tools/android/publicar-canal.sh grava canal.json no repositório
               PÚBLICO jonathasptbr-gh/Projeto-Galapago-canal
app abre → jogo/atualizador.gd lê canal.json pela API do GitHub
           (reserva: raw.githubusercontent.com, com cache de até 5 min)
         → sim/atualizacao.gd: versao_codigo do canal > galapago/build local?
         → aviso "Nova versão X disponível · Atualizar · Depois"
         → Atualizar = OS.shell_open(link do APK da Release `dev`)
         → o navegador baixa (precisa estar LOGADO no GitHub: repo privado)
         → o Android pede a confirmação da instalação (sempre; ninguém contorna)
```

- `canal.json`: `canal`, `versao_codigo` (= nº do run = versionCode),
  `versao_nome`, `publicado_em`, `apk`. Nada além disso fica público.
- O build local (fora do CI) tem `galapago/build=0` e nunca pergunta; o
  `exportar.sh` grava o build real num `project.godot` temporário.
- **Escrita no canal:** deploy key **só daquele repositório** (com escrita),
  guardada como secret `CANAL_DEPLOY_KEY` no repositório privado. A chave
  privada não existe em mais lugar nenhum. **Trocar:** gerar novo par ed25519
  (Python `cryptography`, formato OpenSSH), registrar a pública como deploy key
  do canal (`POST /repos/…/Projeto-Galapago-canal/keys`, `read_only:false`),
  apagar a antiga, e regravar o secret (PyNaCl `SealedBox` com a
  `actions/secrets/public-key` do repositório privado).
- **Cache (medido, v0.3.0):** o `raw.githubusercontent.com` guarda o arquivo
  até 5 min (`max-age=300`) e IGNORA query string (`x-cache: HIT` com parâmetro
  aleatório) — o `?t=` não fura. Por isso o app consulta primeiro a API
  (`api.github.com/repos/…/contents/canal.json` com
  `Accept: application/vnd.github.raw+json`: fresca; sem login, 60/hora por IP)
  e cai no `raw` se a API falhar. Testado com o `HTTPRequest` do próprio Godot.
- **Tags `v*`** geram Release própria, mas o canal acompanha só a `dev`.
