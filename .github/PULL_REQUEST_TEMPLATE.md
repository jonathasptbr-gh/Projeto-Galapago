# Pull request — o lote para revisão no celular

> Um lote por PR. O merge é a aprovação do operador; o agente **não** faz o
> merge do próprio PR. Rito completo em [`docs/BUILD.md`](../docs/BUILD.md).

## O que muda

<!-- uma frase: o que o operador VÊ ou FAZ de diferente -->

## Critério de aceite

- [ ] <!-- observável: "o cão anda sem tremer", "o APK abre no aparelho" -->

## Revisão no celular

- [ ] Preview no comentário do CI (GIF + quadros-chave) abre no aparelho
- [ ] APK da Release `dev` instala por cima do atual
- [ ] Nada visível mudou **ou** o baseline entrou neste mesmo commit

## Risco e rollback

- Risco: <!-- baixo/médio/alto + o que pode quebrar -->
- Rollback: [`docs/ROLLBACK.md`](../docs/ROLLBACK.md) — revert + versão nova
- Chave/segredo no diff? [ ] não (o CI reprova sozinho)

## Custo

- Chamadas ao PixelLab: <!-- nenhuma / N gerações cotadas -->
- Rodadas de CI: <!-- 1, salvo baseline -->
