# Pedidos em espera — a fila de pacotes

> **Nada aqui está autorizado por estar na fila: pergunte ao operador qual
> pacote seguir.** Lê-se só o pacote escolhido. Um pacote cabe numa sessão; se
> não couber, divide-se antes de começar.

| pacote | o quê | depende de | estado |
|---|---|---|---|
| P1 | Conectar o PixelLab (MCP) e gerar a 1ª prova | conta do operador | **feito (v0.1.1)** — falta o operador trocar a chave exposta no chat |
| P2 | APK no CI (export Android + Release) | — | **feito (v0.2.0)** — falta o operador instalar e riscar |
| P3 | Gestos: classificador de deslizes + trajetória na arena | — | na fila |
| P4 | Afinidade e personalidade (sim) | P3 | na fila |
| P5 | Vivência → evolução (sim) + simulação em massa | P4 | na fila |
| P6 | Âncora de arte: paleta-mestra, câmera, base canina | P1 | na fila |
| P7 | Fatia vertical: arena + cão + gestos + 1 evolução | P2–P6 | na fila |
| P8 | GDD do loop diário no laboratório/ilha | — | na fila (design, conversa) |

---

## P1 — Conectar o PixelLab

- **Operador:** criar conta em <https://api.pixellab.ai/mcp>, gerar a chave e
  pô-la no cofre do harness como `refs.PIXELLAB_TOKEN` (mesmo caminho do
  `GITHUB_TOKEN`). Não colar no chat.
- **Agente:** entrada `dsh-mcp-client` (`serverName: pixellab`,
  `transport: streamable-http`, URL `https://api.pixellab.ai/mcp`, cabeçalho
  Bearer lido do cofre) no patch do perfil; backup do patch antes
  (regra da máquina). Vale numa **sessão nova**.
- **Prova:** `get_balance`, depois UMA geração barata (`create_image_pro_flash`
  64×64 ~5 gerações) do cão-base; PNG em `arte/fonte/` e prévia em
  `/sdcard/Download/DSH-Go/` (avisando).
- **Pronto quando:** imagem gerada, salva, vista pelo agente e pelo operador.
- **Feito em v0.1.1:** a chave chegou PELO CHAT (fica no histórico da sessão) e
  foi posta no cofre pelo agente; a conexão leu o cofre e funcionou na mesma
  sessão (recarga a quente). A prova saiu por `create_image_pixen` (1 geração,
  não as 5 do Pro Flash). Pendente do operador: gerar chave nova e trocá-la no
  cofre (ver `docs/ARTE.md`, "Trocar a chave").

## P2 — APK no CI

- Job `apk` no `ci.yml`: Godot + export templates 4.7.2
  (`Godot_v4.7.2-stable_export_templates.tpz`), Java 17, Android SDK do runner,
  `export_presets.cfg` com preset Android (arm64-v8a, paisagem).
- Keystore de release em *secret* do repositório (gerar e guardar a senha fora
  do repositório); debug keystore no CI enquanto isso.
- Release por tag `v*` com o APK anexo.
- **Pronto quando:** o operador instala o APK e risca na tela do celular.

## P3 — Gestos

- `sim/gestos.gd`: classificar traço curto (ângulo, velocidade, duração) em
  {ataque X, ataque Y, salto, defesa/recuo}; traço longo = trajetória.
  Limiares em dados. Casos gravados como testes (incl. ambíguos).
- `jogo/`: arena 2,5D provisória (chão em perspectiva, profundidade por y).
- Gestos roteirizados no oráculo (`Input.parse_input_event`).

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
