# Build e entrega — o rito

Processo enxuto (decisão do operador, 2026-11-25): o operador só tem o
celular, então **build só quando há algo que ele precise experimentar** e que
não dê para avaliar por meio mais barato (teste, quadro, imagem no chat).
Muitas mudanças acumuladas → junta-se num pacote e publica.

## Os dois tipos de entrega (direto em `main`)

| | commit comum | publicação |
|---|---|---|
| quando | código, doc, ferramenta, ajuste que o operador não precisa testar | algo para o operador testar no aparelho, ou pacote acumulado |
| mensagem | `<área>: <resumo>` (`docs: …`, `sim: …`, `ci: …`) — **sem versão** | `vX.Y.Z: <resumo>` |
| `docs/HISTORICO.md` | nota opcional em bullets na seção `## Não publicado` (logo abaixo de `# Histórico`) | `## Não publicado` vira `## vX.Y.Z — título (AAAA-MM-DD)` no topo; o `exportar.sh` tira a versão da primeira `## vX.Y.Z` |
| `docs/RESIDUOS.md` | nada | ao menos uma linha da versão (ou "nenhum") |
| CI | `testes` (testes + quadros + comparação com a última publicação) | `testes` + `preview` (Pages) + `apk` (Release `dev` + `versao.json`) |

O rito, nos dois casos:

1. **Iteração:** `tools/verificar.sh` (seletivo; `--tudo` = suíte). **Gate do
   commit:** `tools/testes.sh` inteiro (guardião + suíte + parser de todo
   `.gd`). Só documentação: `tools/docs.sh` ([`DOCUMENTACAO.md`](DOCUMENTACAO.md)).
2. Mudou algo visível? `tools/quadros.sh` e **abrir** os PNG
   ([`ORACULO.md`](ORACULO.md)). A comparação com a última publicação é do CI.
3. Segredo nenhum no diff: `rg -n "pixl_[0-9a-f]{8}|ghp_[A-Za-z0-9]{8}|github_pat_[A-Za-z0-9]{8}" .`
   vazio (o padrão exige caracteres de chave, então esta linha não casa consigo).
4. `git add <caminhos>` (nunca `-A`) → `git commit -m "…"` → `git push origin main`.
5. CI: `tools/estado.sh --ci` até `completed` (mostra os jobs; num commit comum
   `preview` e `apk` saem `skipped`); vermelho → `node tools/ci-log.mjs`.
6. **Só na publicação:** verde → APK e `versao.json` na Release `dev`; o app do
   operador oferece a atualização ao abrir. Primeira instalação (ou chave
   trocada): `node tools/baixar-apk.mjs` põe o APK em `/sdcard/Download/DSH-Go/`
   (avisando o operador).

Publicar sem commit novo (refazer o APK do `main` atual): Actions → CI → Run
workflow com `publicar` marcado (`workflow_dispatch`). Sem `publicar`, o
dispatch só roda os testes.

## Versão

`vX.Y.Z` conta **publicações**: Z conserta, Y entrega pacote/sistema, X é
marco público (demo). APK: `versionName` = `X.Y.Z-b<run>`, `versionCode` =
número do run do CI (sempre cresce). Marco para guardar:
`git tag vX.Y.Z && git push origin vX.Y.Z` → Release própria com o APK (a
`dev` é sobrescrita a cada publicação).

## O que o CI faz

`.github/workflows/ci.yml`:

- **`testes`** (sempre: push, PR, dispatch): decide `publicar` (push em `main`
  cujo commit casa `^vX.Y.Z:`, tag `v*`, ou dispatch com `publicar=true`),
  procura segredos, roda `tools/testes.sh`, grava 60 quadros (`llvmpipe`),
  compara com a última publicação (`tools/quadros-referencia.mjs`, resultado
  no resumo do run) e sobe o artefato `quadros` (7 dias; 90 nas publicações).
- **`preview`** (só publicação): GIF + quadros-chave no GitHub Pages
  (`https://jonathasptbr-gh.github.io/Projeto-Galapago/`), link no resumo do
  run, **sem comentar** no commit/PR (o comentário gerava e-mail). Falha de
  Pages não segura o APK (`continue-on-error`; pausa de 8 s e 2ª tentativa
  porque o `deploy-pages` precisa do artefato indexado). Sem `python3-pil` a
  página sai só com os quadros. Pages está como **GitHub Actions**; o branch
  `gh-pages` só existe porque o Pages exigiu uma origem. Pages e não asset de
  Release porque o asset sai `application/octet-stream` e não renderiza.
- **`apk`** (só publicação): export Android + Release. Detalhes e armadilhas:
  [`GODOT.md`](GODOT.md#8-exportar-para-android-p2--como-funciona-e-o-que-quebra).
- PR: só `testes`. E-mail de falha de workflow é configuração pessoal do
  GitHub; o canal de trabalho e de aprovação visual é o chat do DSH.

## Rollback

Revert + publicação nova; o aparelho não desce de versão. Procedimento e
ensaio em [`ROLLBACK.md`](ROLLBACK.md).

## Métricas

`tools/estado.sh --metricas` imprime, medido no momento: commits, versões no
histórico, taxa de CI vermelho e mediana de duração dos últimos 20 runs. É o
que entra no digest de 5 linhas ao operador: feito · em andamento · bloqueado ·
custo · decisão pendente.

## Atualização automática do app

**O método do Áudio Visual IASD** (decisão do operador, 2026-11-20, v0.3.1 —
substituiu o canal separado da v0.3.0). O repositório é PÚBLICO.

```
publicação  → CI: APK assinado (keystore dos secrets)
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
