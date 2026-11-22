# Pedidos em espera — a fila de pacotes

> **Nada aqui está autorizado por estar na fila: pergunte ao operador qual
> pacote seguir.** Lê-se só o pacote escolhido. Um pacote cabe numa sessão; se
> não couber, divide-se antes de começar.

> **Manutenção registrada (2026-11-22):** a faxina documental A (v0.14.1) e o
> guardião offline B (v0.14.2) já foram feitos; o protocolo de agentes e o
> multi-sessão (P21) ficaram na v0.14.3. Os pacotes feitos moram em
> [`PEDIDOS-FEITOS.md`](PEDIDOS-FEITOS.md), não aqui. **Nada na fila está
> autorizado** — P22 e P23 esperam escolha do operador.

| pacote | o quê | depende de | estado |
|---|---|---|---|
| P4 | Afinidade e personalidade (sim) | P3 ✔ | **próximo do núcleo** |
| P5 | Vivência → evolução (sim) + simulação em massa | P4 | depois do P4 |
| P6 | Âncora de arte: paleta-mestra, câmera, base canina | P1 | na fila |
| P7 | Fatia vertical: arena + cão + gestos + 1 evolução | P2–P6 | na fila |
| P8 | GDD do loop diário no laboratório/ilha | — | na fila (design, conversa) |
| P22 | Fila enxuta, índice separado dos feitos e resíduos com `estado` | — | na fila (manutenção) |
| P23 | Oráculo com baseline de quadros e diff tolerante | — | na fila (manutenção) |

---

## P4 — Afinidade e personalidade

- Modelo: temperamento (traços estáveis) + humor (estado) + afinidade
  (vínculo). Comando → intenção → decisão {obedece, hesita, reinterpreta,
  desobedece}, com semente. Sincronia/Autonomia como modos.
- Testes de propriedade: afinidade alta ⇒ obediência alta; mesma semente ⇒
  mesma decisão.

## P5 — Vivência → evolução

- Contadores de vivência (calor, saltos, estudo, …) → perfil de traços →
  regras de limiar → ramo. Ramos em dados.
- `tools/simular.sh`: N vidas com sementes → distribuição de ramos (tabela).
  Ramo inalcançável ou dominante demais = falha de design visível.

## P6 — Âncora de arte

- Paleta-mestra, câmera única, tamanho de sprite; base canina aprovada pelo
  operador; validador de assets em `tools/`. Ver `docs/ARTE.md`.

## P7 — Fatia vertical

- Uma arena, o cão-base, trajetória + 4 gestos, afinidade baixa × alta
  visível, uma evolução (raposa alada de fogo). APK para o operador.

## P8 — GDD do loop diário

- Conversa de design com o operador → `docs/gdd/loop-diario.md`.

## P22 — Fila enxuta e resíduos com estado

- **O quê:** separar no índice o que está **na fila** do que já foi **feito**
  (P1–P21: só P4–P8 seguem vivos); enxugar o índice para uma linha por pacote
  vivo; `RESIDUOS.md` ganha a coluna **`estado`** (`aberto`, `decidido`,
  `resolvido`) e as linhas resolvidas saem — a v0.14.1 "sem `tools/docs.sh` no
  CI" já está resolvida pela v0.14.2 e é a primeira a sair; por fim, atualizar
  o "próximo natural" do núcleo à luz do que P1–P21 entregaram.
- **Por quê:** o índice de mais de 20 pacotes, quase todos feitos, empurra o
  que importa para baixo; resíduo sem estado é lido como pendência para sempre.
- **Pronto quando:** o índice lista só pacotes vivos; `RESIDUOS.md` tem a
  coluna `estado` preenchida e nenhuma linha já resolvida; `tools/docs.sh`
  continua verde com a fila nova.

## P23 — Oráculo com baseline e diff tolerante

- **O quê:** `tools/quadros-diff.mjs` compara os quadros com um baseline
  versionado em `testes/baseline/`, com tolerância (px/canal) para ruído de
  renderização; o lote que muda o visível **atualiza o baseline** de forma
  explícita no mesmo commit; o CI roda o diff **depois** de gerar os quadros
  (`tools/quadros.sh`), antes do APK.
- **Por quê:** hoje o CI só confere que os quadros saíram; uma regressão visual
  passa verde se o PNG é gerado. Baseline + tolerância transforma "abri o PNG"
  em prova automática, sem o falso alarme de 1 px.
- **Pronto quando:** um lote que apaga o botão da HUD reprova o job; dentro da
  tolerância passa; a falha diz qual quadro e quanto saiu da faixa.
