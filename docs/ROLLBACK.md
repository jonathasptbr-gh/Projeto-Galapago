# Rollback — voltar um lote

> **O aparelho não desce de versão.** O Android só instala por cima um APK com
> a MESMA assinatura e `versionCode` MAIOR. Não existe "instalar a versão
> anterior": rollback é **publicar um lote novo com o código anterior** — o
> `versao_codigo` sobe e o app aceita. Ver [`BUILD.md`](BUILD.md).

## Quando usar

- O lote publicado quebrou o jogo no aparelho do operador (tela preta, toque
  morto, arte errada) e não há conserto em minutos.
- O `versao.json` da Release `dev` aponta para um APK que não instala.

## O procedimento (ensaio antes, sempre)

1. **Ensaie o revert num branch** — não mexa em `main` para descobrir se o
   revert conflita:
   ```bash
   git switch -c ensaio/rollback-<versao> main
   git revert --no-commit <sha-do-lote>     # um commit por lote; vários se preciso
   tools/testes.sh                          # suíte inteira, sem atalho
   git switch main
   ```
   Conflito no revert: pare e leve ao operador com o arquivo e o trecho; não
   escolha um lado sozinho.
2. **Lote de rollback em `main`**: revert aplicado, `docs/HISTORICO.md` ganha a
   seção `## vX.Y.(Z+1) — rollback de <versão> (data)` explicando o porquê, e o
   rito normal segue (resíduos, `git add <caminhos>`, commit, push).
3. **CI verde** (`tools/estado.sh --ci`): a Release `dev` é refeita com
   `versionCode` maior; o app do operador oferece a atualização e volta ao
   código anterior.
4. **Confirme no aparelho**: o app abre, o toque responde, a versão em
   `CONFIG`/`versao.json` é a do lote de rollback.

## Se o APK novo não instala

- `versao.json` traz `bytes` e `sha256`: confira o tamanho baixado
  (`node tools/baixar-apk.mjs`) antes de acusar o build.
- Assinatura diferente = o aparelho recusa. A chave é a do cofre
  (`GALAPAGO_KEYSTORE_B64`); restaurá-la é decisão do operador — sem ela, a
  saída é desinstalar e reinstalar (perde os dados locais).
- Release `dev` apagada/errada: o job `apk` a recria no próximo push em `main`;
  não apague a Release à mão.

## Marco público

`git tag vX.Y.Z && git push origin vX.Y.Z` guarda o APK de um marco. É a única
cópia de uma versão antiga: a `dev` é sobrescrita a cada push. Por isso, antes
de um lote grande, um marco vale mais que um plano de rollback.
