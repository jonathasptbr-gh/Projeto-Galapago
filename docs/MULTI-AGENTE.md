# Duas sessões no mesmo clone — o protocolo

> **2026-11-22 · regra de interação.** Dois agentes no MESMO clone compartilham
> o working tree, o HEAD e o índice; **não** compartilham contexto nem fila. A
> regra-mãe: **o working tree é de todos; o commit é de quem editou.**

## Medir antes de tocar

```bash
git -c safe.directory='*' status --short
git -c safe.directory='*' log --oneline -3
stat -c '%y %n' <os arquivos que vai editar>
```

O `-c safe.directory='*'` evita o "dubious ownership" quando o clone é de outro
dono. Arquivo sujo que não é seu: você não é o dono do commit dele.

## As regras

- **`git add <caminho>`** — nunca `-A`, nunca `git add .`, nunca
  `git commit -a`. O commit é a fronteira: o que está fora dele não é seu.
- **Proibidos** `git checkout -- <arq>`, `git reset --hard`, `git stash`,
  `git clean` e `git restore` sem pedido do operador: apagam o lote do outro em
  silêncio.
- **Quem editou commita.** O commit leva só os arquivos da própria sessão; não
  se commita arquivo de outra sessão nem se aproveita a carona.
- **Antes do `push`:** `git status` conferido; se há arquivo alheio, avisar o
  operador em uma linha — e nunca empacotar o alheio no mesmo commit.
- **O rito é de UM lote por vez** ([`BUILD`](BUILD.md)): um commit, um
  `push`, um CI de cada vez. Duas sessões não publicam o mesmo `vX.Y.Z`.
- **Conflito de `pull`/`merge`/`push`:** parar, dizer arquivo e trecho, deixar
  o operador decidir — não resolver escolhendo um lado.

## Os clones desta máquina

| clone | repositório | uso |
|---|---|---|
| `~/workspaces/Projeto-Galapago` | Galápago (Godot, público) | jogo, docs, CI |
| `~/workspaces/Audio-Visual-IASD` | Áudio Visual IASD | referência de atualização e multi-sessão |

São clones separados: um agente não edita o clone do outro. Caminho absoluto no
briefing e `cd` no clone certo antes de qualquer comando.

## Como saber que funcionou

- `git show --stat` de cada commit: nenhum arquivo que a sessão não editou.
- Nenhum trabalho sumiu: o que a outra sessão deixou no tree continua lá.
- O operador não precisou arbitrar: se ele teve de dizer "não mexe nisso", o
  protocolo falhou antes.
