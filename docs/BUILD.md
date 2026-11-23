# Build e entrega — o rito

## O rito de entrega (direto em `main`)

1. **Iteração:** `tools/verificar.sh` (seletivo: guardião + testes da área +
   parser dos arquivos tocados; ver `--tudo`). **Gate do commit:**
   `tools/testes.sh` inteiro — guardião + suíte + parser de todos os `.gd`.
   Só documentação: `tools/docs.sh`. Escopo e limites:
   [`DOCUMENTACAO.md`](DOCUMENTACAO.md).
2. Mudou algo visível? `tools/quadros.sh`, **abrir** os PNG e depois
   `node tools/quadros-diff.mjs quadros` contra `testes/baseline/`. O baseline
   deste celular é `softpipe` e o do CI é `llvmpipe`: o lote visível **gera o
   baseline pelo CI antes do commit** (ver "Baseline de um lote") e entra em
   UM commit com quadros verdes; o CI reprova o que sair da tolerância
   (canal 6, 0,1% dos pixels).
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

## Preview do lote (celular)

Todo push em `main` (e todo PR) ganha o job `preview`: pega o artefato
`quadros`, monta um **GIF** e três quadros-chave, publica no GitHub Pages
(`https://jonathasptbr-gh.github.io/Projeto-Galapago/`) e **comenta no
commit/PR** com o link da página e as três imagens inline.

- `_site/index.html` é a página do lote atual; as imagens ficam em
  `_site/<run>/` (nome único por run) para o cache de imagem não servir lote
  velho. A página é substituída a cada push — link de imagem de lote antigo
  morre; o comentário é atualizado no mesmo lugar (marcador
  `<!-- galapago-preview -->`).
- Pages está como **GitHub Actions** (`build_type=workflow`). O branch
  `gh-pages` existe só porque o Pages exigiu uma origem para ser criado; não é
  fonte do site.
- **Por que Pages e não asset de Release:** asset de Release sai como
  `application/octet-stream` e o proxy de imagem do GitHub não renderiza;
  o Pages serve `image/png` e `image/gif` de verdade.
- GIF depende de `python3-pil` no runner; se faltar, a página sai só com os
  quadros e o job **não** fica vermelho. O Pages pode falhar (ambiente,
  cota): o `continue-on-error` segura, e o APK não depende dele.
- O `deploy-pages` precisa do artefato já indexado: o job dá uma pausa de 8 s
  e tenta de novo se a primeira falhar ("Fetching artifact metadata failed").
  Falha dupla = site fica no lote anterior; o comentário aponta para a página
  mesmo assim.

## Baseline de um lote (antes do commit)

O baseline é do `llvmpipe` (x86_64) e este celular renderiza em `softpipe`:
**não** se gera baseline confiável aqui. O caminho é o CI gerar e o script
aplicar.

```bash
# 1. no branch do lote (ou no commit visível), dispare o job `baseline`
gh workflow run ci.yml -f ref=lote/vX.Y.Z
#    (ou Actions → CI → Run workflow → ref)

# 2. quando o run terminar, aplique o artefato `baseline`
node tools/quadros-baseline.mjs --run <numero-do-run>

# 3. o MESMO commit leva a mudança visível + testes/baseline
git add testes/baseline
```

O script também aceita `--url <link do run>`, `--zip <arquivo>` e
`--pasta <quadros já extraídos>`. Ele valida a contagem (mínimo 50 quadros) e
remove do baseline o que não existe mais. `--atualizar` do
`quadros-diff.mjs` continua valendo para quem estiver num driver igual ao do
CI — não é o caso deste aparelho.

## Lote visível: branch para o baseline, merge direto

Lote que muda o que o operador vê (arte, câmera, movimento, UI) continua
precisando do baseline do llvmpipe no MESMO commit. O branch `lote/vX.Y.Z`
existe só para o CI gerar o baseline; **não há PR obrigatório nem
dual-control** (decisão do operador, 2026-11-23):

- O agente faz o **merge direto em `main`** (autorização permanente) e dá
  `git push origin main`.
- A **aprovação visual é no chat do DSH**: o agente envia a imagem (quadro ou
  folha de contato) e o operador responde ali. Comentário de PR, issue e
  e-mail NÃO são lidos nem servem de aprovação.
- O job `preview` (GIF + quadros no Pages) é conveniência para o commit em
  `main`; falha de Pages não segura o lote nem pede aprovação.
- WIP: um lote por vez; nada de dois agentes no mesmo branch.

## Rollback

Revert + versão nova; o aparelho não desce de versão. Procedimento e ensaio em
[`ROLLBACK.md`](ROLLBACK.md).

## Métricas

`tools/estado.sh --metricas` imprime, medido no momento: commits, versões no
histórico, taxa de CI vermelho e mediana de duração dos últimos 20 runs. É o
que entra no digest de 5 linhas ao operador: feito · em andamento · bloqueado ·
custo · decisão pendente.

## Versão

`vX.Y.Z`: Z conserta, Y entrega pacote/sistema, X é marco público (demo).
APK: `versionName` = `X.Y.Z-b<run>`, `versionCode` = número do run do CI
(sempre cresce). Marco para guardar: `git tag vX.Y.Z && git push origin vX.Y.Z`
→ Release própria com o APK (a `dev` é sobrescrita a cada push).

## O que o CI faz

`.github/workflows/ci.yml` — job `testes` (segredos + testes + oráculo,
artefato `quadros`) → job `preview` (GIF + quadros-chave comentados no
commit/PR) → job `apk` (export Android + Release). O job `baseline` roda só
por `workflow_dispatch` (aba Actions → Run workflow → `ref` do lote) e entrega
o artefato `baseline`. Detalhes do export e das armadilhas:
[`GODOT.md`](GODOT.md#8-exportar-para-android-p2--como-funciona-e-o-que-quebra).

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
