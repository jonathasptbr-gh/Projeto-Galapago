# Pedidos em espera — a fila de pacotes

> **Nada aqui está autorizado por estar na fila: pergunte ao operador qual
> pacote seguir.** Lê-se só o pacote escolhido. Um pacote cabe numa sessão; se
> não couber, divide-se antes de começar.

> **Manutenção registrada (2026-11-24):** a faxina documental A (v0.14.1) e o
> guardião offline B (v0.14.2) já foram feitos; o protocolo de agentes e o
> multi-sessão (P21) ficaram na v0.14.3; o P22 (fila enxuta) foi entregue na
> v0.14.4 e o registro dele fechado na v0.15.0; o P23 (oráculo com baseline)
> ficou na v0.16.0. Os pacotes feitos moram em
> [`PEDIDOS-FEITOS.md`](PEDIDOS-FEITOS.md), não aqui. **Nada na fila está
> autorizado** — restam os pacotes de conteúdo (P5–P9) e o P10 em andamento,
> à escolha do operador.

| pacote | o quê | depende de | estado |
|---|---|---|---|
| P5 | Vivência → evolução (sim) + simulação em massa | P4 ✔ | **próximo do núcleo** |
| P6 | Âncora de arte: paleta-mestra, câmera, base canina | P1 | na fila |
| P7 | Fatia vertical: arena + cão + gestos + 1 evolução | P2–P6 | na fila |
| P8 | GDD do loop diário no laboratório/ilha | — | na fila (design, conversa) |
| P9 | Camadas de pixel art sobre o esqueleto 3D (fase B) | A: v0.29.0 ✔ | alvo declarado (2026-11-23) |
| P10 | Esqueleto 3D paramétrico por arquétipo e locomoção | — | **núcleo entregue (v0.33.0)**; resta interface e decisões |

---

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

## P9 — Camadas de pixel art sobre o esqueleto 3D (fase B)

- **Decisão do operador (2026-11-23):** o alvo final é a fase B — o esqueleto
  3D da v0.29.0 recebe as camadas de pixel art por osso, com vistas
  lateral/frontal/costas trocadas por ângulo; câmera **low top-down (20°)**.
- **Arte:** peças por osso (cabeça, focinho, orelhas, tronco, pernas, cauda)
  com pivô e vistas por ângulo; medir o custo antes de gerar.
- **Contrato:** o campo `pecas` do `dados/rig/canino3d.json` já valida; falta
  o desenho ordenado (pintor) e o pipeline de arte.

## P10 — Esqueleto 3D paramétrico por arquétipo e locomoção

- **Estado:** núcleo ENTREGUE na `main` na v0.33.0 — voo 1,97:1, giro 4/4,
  272 testes/0. O que resta é interface e decisão, não conserto.
- **O que já existe:** `sim/topologia3d.gd` (schema 3 adaptado e schema 4 com
  papéis; quadrupede/bípede/ave/serpente; membros e pole), `sim/locomocao3d.gd`
  (fase por distância e apoios ancorados no mundo), mudanças em
  `sim/esqueleto3d.gd`, `jogo/criatura.gd` e `jogo/rigs3d.gd`, preset
  `dados/rig/equino3d.json` e `testes/test_parametrico3d.gd`.
- **Medido na v0.33.0:** 176 apoios alcançáveis com erro máximo de 0,002 px;
  voo 1,97:1 (era 0,93); reancoragem 4/4 (era 3/4).
- **Próximo:** (1) revisar o cão nas 8 direções e o canvas no aparelho;
  (2) as chaves do voo no equino (hoje herdam default e o teste de voo só roda
  no cão); (3) as interfaces de bípede, ave e serpente; (4) escrever o método
  (`docs/RIG.md`), hoje só existe em código.
- **Decisões pendentes do operador:** teto de 20 juntas (o cão tem 24), caixa
  por clipe × por animal, qualidade da patinagem (âncora real).
- **Aceite:** segundo quadrúpede sem editar o solver; menos de 1 px de
  patinação por apoio em reta; voo entre 1,8 e 2,0; testes verdes; imagens
  revisadas no chat.
