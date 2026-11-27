# Pedidos feitos — o registro dos pacotes

> Este arquivo é **registro**, não fila: uma seção por pacote já entregue
> (P1 a P21), lida por `grep` ou pela âncora do título. **Nada aqui está
> autorizado** — o que falta mora em
> [`PEDIDOS-EM-ESPERA.md`](PEDIDOS-EM-ESPERA.md).
> O texto de cada seção é o que a fila registrava quando o pacote foi feito e
> não foi reescrito neste lote.

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
  `export_presets.cfg` com preset Android (arm64-v8a; na época em paisagem — hoje retrato pela P12).
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
- **Feito em v0.15.0:** `sim/afinidade.gd` + `dados/afinidade.json` +
  `testes/test_afinidade.gd` (12 testes de propriedade). Em Sincronia, acima
  do limiar, obedece na hora; em Autonomia, temperamento e humor decidem sem
  sorteio global. **Sem ligação no `jogo/`** (a criatura continua obedecendo
  no aparelho) — a ligação é P7; traços, pesos e ganhos são pontos de
  partida. Detalhe no [`HISTORICO`](HISTORICO.md).

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

## P9 — Atualização automática do app (v0.3.1)

- Método do Áudio Visual IASD, com o repositório público: o CI assina o APK
  (keystore nos *secrets*) e publica na Release `dev` dois assets —
  `projeto-galapago-dev.apk` e `versao.json`. O app lê o manifesto, baixa
  dentro do próprio app, confere o tamanho e entrega ao instalador por
  `OS.shell_open(arquivo)`; o Android só aceita por cima um APK com a MESMA
  assinatura. `sim/atualizacao.gd`: host travado, teto de 300 MB.
- **Feito em v0.3.1:** históricos auditados antes de abrir o repositório;
  keystore de dev trocada por uma nova, só nos *secrets* e no cofre do
  operador. O canal separado da v0.3.0 foi desmontado.
- **Pendente do operador:** reinstalar o APK manualmente uma vez (o
  verificador só passou a funcionar a partir da v0.5.0) e confirmar que o
  aviso de atualização aparece sozinho.

## P10 — Mapa de cima com profundidade + tela em alta resolução (v0.4.0)

- Mundo em camadas lógicas (`sim/mundo.gd` + `dados/terrenos.json` +
  `dados/mapas/fundacao.json`): superfície (terreno por célula, `altura`,
  `andavel`, `escavavel`, rampa 1,5) e subsolo de túneis; andar vence 0,5
  nível, pulo sobe 1, escavação desce/sobe. Apresentação em mockup de xadrez
  com parallax, y-sort pela base e copas; tela 720×1280 em retrato.
- **Feito em v0.4.0:** validado por 43 testes (mundo, gestos, comandos, corpo,
  visibilidade) e demo de 450 quadros sem erro de script.

## P11 — Movimento por rota + overlays, alvos, adversário e autonomia (v0.5.0)

- **Regra do operador:** rota e ações andam juntas — ataque, esquiva e pulo são
  OVERLAYS que não cancelam a rota; a defesa paralisa sem apagar; só uma rota
  nova substitui. Arrasto perto = rota; longe = gesto de ação.
- Alvos com mira re-resolvida (alvo móvel), autonomia semeada ao fim da rota e
  adversário de teste determinístico que não entra na água.
- **Feito em v0.5.0:** `sim/corpo.gd` reescrito; `sim/alvos.gd` e
  `sim/adversario.gd` novos; 49 testes verdes.

## P12 — Retrato e caminho por âncora

- **Operador (2026-11-20):** gestos relativos à TELA (cima = ataque físico,
  lados = especiais, baixo = esquiva; baixo + segurar = defesa); tela em
  retrato; caminho desenhado a partir de uma **âncora** segurada longe da
  criatura (o dedo não tapa a visão), com **tempo lento** durante o desenho;
  **desconto inicial** do vai-e-volta; caminho como pontos de referência com
  **pequenos desvios de objetos**; barreira sem pulo = para, com pulo = segue.
- **Feito em v0.6.0:** `sim/gestos.gd` (âncora, setores de tela, defesa por
  baixo+segurar), `sim/trajetoria.gd` (desconto + Douglas-Peucker),
  `sim/corpo.gd` (waypoints, desvio local, barreira/pulo), `jogo/` (prévia
  transladada, tempo lento, HUD retrato), `project.godot` 720×1280 orientação 1.
- **v0.6.1:** conserto do aviso de atualização (o `Atualizador` ficava 0×0 e
  jogava o botão `ATUALIZAR` para fora da tela; agora o painel abre sozinho).
  A v0.5.0 instalada precisa do APK manual uma vez.
- **Pendente de design:** o que cada **especial** faz (hoje é um golpe lateral
  genérico) e o ajuste fino de `escala_tempo`/`desconto_raio_px` pelo operador.

## P13 — Caminho ao vivo, sem espera (v0.7)

- **Operador (2026-11-20):** tirar o atraso do toque longo — o arrasto contínuo
  vira caminho **direto**; a linha **não se move com o animal** (o ponto de
  partida é a posição no INÍCIO do gesto, e se ele se mexeu no meio ela volta
  para começar por lá); manter **ataques e afins em paralelo** com esse
  controle, sem atraso; **escurecer a tela** durante o desenho e uma **rampa de
  aceleração** na saída (tempo para a próxima ação); **aumentar a
  sensibilidade** do desenho (dedo menor cobrindo mais tela).
- **Decisões do operador:** caminho **AO VIVO** (a criatura já anda atrás do
  dedo) e ação disparada **no meio do risco**, ao cruzar o limiar.
- **Feito em v0.7.0:** `sim/gestos.gd` (caminho sem espera, RISCO `flick_*`,
  defesa/escavar mantidos); `sim/corpo.gd` (`tracar` ao vivo, origem
  congelada, progresso que não volta, volta ao começo); `jogo/main.gd`
  (origem+mundo congelados na descida, ganho de sensibilidade, véu, rampa);
  `jogo/trilha.gd`, `jogo/hud.gd`, `jogo/demo.gd` (sem `hold`) e
  `dados/gestos.json` (`desenho.ganho` 1,6, `planejamento` 0,35×/0,45 s/0,22,
  `flick_*`). Testes: `test_gestos` reescrito, `test_corpo` com traço ao vivo.

### v0.7.1 — a correção do "em paralelo"

- **Operador (2026-11-20, depois da v0.7.0):** "em paralelo" era poder **fazer
  um ataque durante a caminhada**, não durante o desenho — o gesto de ataque
  **não** deve virar passo.
- **Feito:** o risco cancela o traço (`sim/gestos.gd`) e `sim/corpo.gd` ganhou
  `guardar_rota`/`voltar_rota`: o instantâneo da rota é tirado na descida do
  dedo e devolvido quando o gesto vira ação, então o golpe acontece por cima
  da caminhada. Defesa idem. Um gesto = uma intenção.

## P14 — Gestos de ação com dois dedos (v0.8)

- **Operador (2026-11-20):** os gestos de ação conflitavam com o movimento
  contínuo. Trocar para: **mover = 1 dedo** (arrasto contínuo, sem delay);
  **ataque = 2 dedos ↑**; **defesa = 2 dedos ↓**; **especial = 2 dedos
  abrindo** (zoom). O dedo que desenha o caminho **desconta**: com o segundo
  dedo dá para atacar **durante** o desenho.
- **Feito em v0.8.0:** `sim/gestos.gd` multitouch (dedo do caminho + ponteiro
  dos dedos extras; `desenho_min_ms` cancela o traço quando os dois dedos descem
  juntos), `sim/comandos.gd` (evento `especial`), `jogo/main.gd` (dedos por
  índice, `caminho_cancelar`, tempo volta na hora numa ação, véu corrigido),
  `jogo/demo.gd` (trilhas por dedo), `jogo/hud.gd`, `dados/gestos.json`.
  **Pendente de design:** a `esquiva` ficou sem gesto (o "para baixo" virou
  defesa) e o espalhamento vertical é lido como ataque/defesa.

## P15 — O ataque nasce do DESENHO (v0.9)

- **Operador (2026-11-21):** (1) **laço** fechando/cruzando o caminho =
  **ataque em área** com centro no centro estimado do laço, ativado no **nó**
  (onde o laço fecha na primeira linha) quando o animal passa por ele — só um
  círculo em expansão, sem depender de ir ao centro; (2) **bico** (ida e volta
  brusca) durante o caminho = **tiro** na direção do bico, saindo do ponto do
  caminho ANTES dele (bico a partir da posição inicial dispara sem se mover);
  (3) **segurar parado** sem desenhar = **habilidade em si mesmo** com duração
  (efeito de teste: **cavar**, decidido na conversa); (4) dois toques pulam,
  parados ou em caminho, sem interromper a rota; (5) **cruzar a linha sobre**
  adversário/alvo = **batida ou empurrão**; (6) **terminar o caminho em cima**
  do adversário = alvo final de um **golpe físico**, com a marca **no inimigo**
  (perde-se se ele andar demais); (7) **esquiva é o próprio caminhar** (tempo
  lento do desenho), sem efeito especial.
- **Decisões do operador:** **nenhum gesto de dois dedos** (saem ataque ↑,
  defesa ↓, especial abrindo); golpe no adversário = **empurrão + piscada, sem
  vida**; a habilidade de teste é **cavar**, ativável **em qualquer lugar**.
- **Feito em v0.9.0:** `sim/formas.gd` (laço/bico), `sim/trajetoria.gd`
  (distância ao segmento preserva a ponta do bico), `sim/gestos.gd` (um dedo),
  `sim/comandos.gd` (tabela nova), `sim/corpo.gd` (marcas, onda, tiro, batida,
  alvo final, habilidade; sem esquiva/defesa/desvio), `sim/adversario.gd`
  (empurrão + piscada), `sim/alvos.gd` (`empurrar`/`reage`), `jogo/` (efeitos,
  mira do alvo final, HUD, demo), `dados/*.json`. Detalhe em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md).
- **Ajustes (v0.9.1, mesmo dia):** o laço acende em **qualquer parte da
  circunferência** (anel), não só no nó; o **bico no meio do caminho** (o "T")
  é reconhecido, o **beco não é andado** (sai da rota) e a criatura **para antes
  de disparar**; o caminho virou **ESTRADA** (o animal anda dentro da largura,
  com desvio orgânico) e ganhou **zona de freio** no fim.
- **Ajustes (v0.9.2):** a **linha do caminho** virou o **traço real do dedo**
  (pontos densos, contínua) em estilo **pontilhado, escuro e transparente**;
  os especiais (área/tiro) têm **1 s de recarga** (a marca fica pendente); e os
  golpes físicos **embalam** — curto na marcação, longo no empurrão.
- **Ajustes (v0.10.0):** sem **freio final** com alvo marcado e **perseguição
  final** (o animal vai atrás e bate ao chegar); **área pela distância ao
  centro** (~7× o corpo, sem esperar o anel); **marcação pelo fim do caminho**
  (a marca anda com o alvo e está ligada ao caminho), **tiro no toque duplo**
  (mira no alvo, 1 s de recarga, para para atirar, a marca fica) e **pulo no
  toque simples**; o bico não atira mais.
- **Ajustes (v0.11.0):** o **bico é andado** (nada é ignorado); **PULO no toque
  duplo** e **TIRO no toque simples**; o **SEGURAR ativa no limiar** — com
  caminho = **SPRINT** (barra de **energia**), sem caminho = habilidade
  (**cavar**).
- **Ajustes (v0.11.1):** a **ESTRADA** deixou de cortar caminho — a **projeção
  com continuidade** anda o **laço** e a **ponta do bico** (não pula de braço
  no cruzamento nem trava no retorno); o **alvo pela visão** contorna a curva
  em vez de cortar por dentro da **pedra/beira de mar**; o **desvio de tronco**
  troca de lado se o primeiro não passar; **AMONTOADOS** de até 24 px/100 px de
  arco são cortados da rota e **laços pequenos** (< 2200 px²) não acendem a
  área; a **frenagem virou INÉRCIA DEPOIS do fim** (16 px, ×1,6 no sprint) —
  o animal chega na velocidade normal; e o **TIRO ficou HÍBRIDO** — sem marca,
  na **direção do toque** (sem auto-mira); com marca, automirado no alvo.
- **Ajustes (v0.11.2):** **água e rocha** ganharam o **mesmo desvio dos
  troncos** quando a rota **volta à terra** perto do animal (`contorno_*`): a
  linha pode entrar 100 px no lago e continuar na terra — o destino não é a
  água, ela contorna. Se a rota **termina** no bloqueio, para na fronteira e o
  **pulo** atravessa; o contorno desiste depois de 36 passos sem progresso
  (`desvio_teimoso_*`), em vez de ficar indo e voltando no muro.
- **Ajustes (v0.11.3):** o contorno vale também para **desnível/encosta** — a
  barreira é lida por `Mundo.caminho_livre` (não só `bloqueio`), e a
  continuação precisa ser de **nível alcançável** (o topo do barranco não
  conta). A direção ficou **estável**: `_dir_suave`/`_olhar_suave` com
  `giro_suavidade` 10 e `giro_max_graus_s` 720, e o ângulo do contorno é
  mantido (`_desvio_angulo`). A **linha do caminho apaga** o trecho já andado
  (`traco_t` + fade de 22 px em `jogo/trilha.gd`).

## P16 — Ajustes de sensação da v0.11 (21/11)

- **Operador (2026-11-21, quatro falas seguidas):** (1) "se o caminho passa,
  criando um ataque de empurrão, com o destino final longe do alvo, então não
  volte para dar o ataque de perseguição"; (2) "distancie um pouco mais a
  câmera, permitindo ver mais do mapa e do campo total"; (3) "verifique o delay
  de percepção de pulo — pode detectar o pulo ainda durante o primeiro pulo,
  mas só deixe ele pular após terminar a animação do primeiro pulo. Hoje existe
  muito delay entre dois pulos quando se tenta dar dois ou mais pulos
  seguidos"; (4) "para o modo acelerado, ao segurar durante uma caminhada…
  mantenha ele acelerado por um tempo mesmo após soltar o acelerador, assim é
  possível saltar ainda acelerado indo mais longe".
- **Feito em v0.11.4:** `_soltar_marca_longe_da_ponta` (a marca segue a PONTA;
  a batida da travessia fica), `Mock.ZOOM` 2,0 → 1,6 (mapa inteiro na vertical),
  `_pulo_fila_t` + `pular.buffer_s` (pulo pedido no ar sai no pouso; recarga de
  pouso 0,30 → 0,08) e `_sprint_cauda_t` + `sprint.cauda_s` (cauda de 0,60 s,
  queda linear). Detalhe no [`HISTORICO`](HISTORICO.md) e em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md).
- **Pendente de ajuste fino (no aparelho):** o quanto a câmera afasta (1,6 é
  ponto de partida; zoom fracionário — decisão de arte no P6), a duração da
  cauda do sprint e o `buffer_s` do pulo.

## P17 — Desligar o ataque em área do laço (v0.11.5)

- **Operador (2026-11-21):** "Vamos desativar o ataque em área feito por
  desenho de círculo do caminho."
- **Feito em v0.11.5:** `formas.laco_ataque` (falso) em `dados/acoes.json`;
  `sim/formas.gd` devolve `[]` sem ler o traço. O desenho de círculo continua
  sendo **caminho** (a rota é andada); o que sai é a **ONDA**. O código da
  onda fica **inteiro atrás do interruptor** (religar = trocar a chave e
  rebuildar). Sem a linha "laço perto → ataque em área" na HUD.
- **Pendente de design:** se o laço deve ganhar **outro** efeito (ou sumir de
  vez, com o código e os dados apagados), é decisão do operador.


## P18 — Extensão de parkour a leste (v0.12.0)

- **Operador (2026-11-21):** "Crie mais uma extensão para o mapa do projeto
  Galápago, focado em parkour, com desníveis, plataformas e trilhas para
  testar a movimentação."
- **Feito em v0.12.0:** `fundacao.json` de 40 para **64 colunas** (o resto do
  mapa não mudou); ligação pela ilha leste em `x = 38..39, y = 11..12`;
  peças novas `p` trilha, `b` passarela, `r` rampa alta e `q` plataforma em
  `dados/terrenos.json`; ida com pátio, vão de 1, passarela, vão de 2,
  plataforma de 3, pescoço com rampa alta e pátio final; volta em `y = 16`
  com degraus 1→2→3→2→1 e um vão de 2. Detalhe em
  [`gdd/mapa.md`](gdd/mapa.md) e no [`HISTORICO`](HISTORICO.md).
- **Pendente de ajuste (no aparelho):** se o vão de 2 células está confortável
  com pulo emendado/sprint; se a área merece um atalho a partir do início.


## P19 — Pulo automático e pulo mais longo no sprint (v0.13.0)

- **Operador (2026-11-21):** "Faça uma opção para ativar e desativar um
  sistema de pulo automático, que pula quando houver um obstáculo de um nível
  de altura, e o caminho prosseguir sem o obstáculo do outro lado. Também
  aproveite para aumentar a distância dos pulos em velocidade aumentada
  ativa."
- **Feito em v0.13.0:** botão **PULO AUTO** na HUD (estado no corpo, padrão
  `pular.auto_padrao` falso); `sim/corpo.gd:_tentar_pulo_auto` decide quando a
  rota para num degrau de 1 nível (puro ou com vão curto de água antes) e o
  desenho continua, com **alcance** conferido; `pular.sprint_fator` 1,5
  alonga o avanço no ar com sprint (pulo de ~2,1 para ~3,1 células). Detalhe
  em [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md) e no
  [`HISTORICO`](HISTORICO.md).
- **Pendente de design/ajuste:** se o automático deve vir **ligado** por
  padrão; se vale persistir o botão entre partidas; se o automático deve
  também **descer** degrau de 1 nível (hoje só sobe).

## P20 — Inimigo hostil: botão, caçada e quatro ataques (v0.14.0)

- **Operador (2026-11-21):** "Elabore a dinâmica do inimigo, com um botão para
  ligar a hostilidade. Ele vai ficar mais dinâmico em questão de movimentos,
  mais rápido. Deve ter um ataque próximo, um de esbarrão, um de longa
  distância e um efeito especial, como se defender ou se esconder. Vamos usar
  o sistema de preparação de ataque e área de efeito demarcada no chão."
- **Decisões:** sem vida (só empurrão + atordoamento); especial = esconder;
  hostilidade fixa até desligar.
- **Feito em v0.14.0:** botão **HOSTILIDADE** na HUD; `sim/adversario.gd` com
  caçada (104 px/s, zigue-zague, órbita) e as quatro ações com preparo;
  `jogo/perigos.gd` desenha círculo/faixa/linha no chão e o projétil;
  `sim/corpo.gd: levar_golpe` (empurrão, atordoamento, invencibilidade 0,8 s);
  `dados/adversario.json`. Detalhe no [`HISTORICO`](HISTORICO.md).
- **Pendente de ajuste (no aparelho):** tempos de preparo e alcances; se o
  esconder deve também disparar quando o ataque **erra** (hoje só ao levar
  golpe); se o inimigo deve ter vida/level no futuro.

## P21 — Protocolo multi-sessão e trabalho por subagentes (v0.14.3)

- **Operador (2026-11-22):** registrar a fila de manutenção e criar o protocolo
  padrão de trabalho por agentes, inclusive o caso de duas sessões no mesmo
  clone.
- **Feito em v0.14.3:** [`PROTOCOLO-AGENTES.md`](PROTOCOLO-AGENTES.md) — a
  sessão é **GERENTE** que fatia em **briefings de contexto fresco** e confere
  **evidência** (hash/commit, saída de teste, CI); [`MULTI-AGENTE.md`](MULTI-AGENTE.md)
  — `git add <caminho>` nunca `-A`, proibição de `checkout`/`reset`/`stash`,
  quem editou commita, um lote por vez e a tabela dos clones da máquina.
  `AGENTS.md` ganhou o bullet e os dois guias no mapa documental.
- **Por quê:** a v0.14.1 e a v0.14.2 mostraram que dois lotes no mesmo tree se
  misturam; o protocolo separa quem lê, quem escreve e quem commita.
- **Pronto quando:** uma sessão executa a tarefa só com o briefing, sem o
  histórico do chat, e o clone continua com **um escritor por vez**.

## P22 — Fila enxuta e resíduos com estado (v0.14.4; registro fechado na v0.15.0)

- **O quê:** separar no índice o que está na fila do que já foi feito,
  enxugar o índice e dar **estado** a cada linha do `RESIDUOS.md`.
- **Feito em v0.14.4:** [`PEDIDOS-FEITOS.md`](PEDIDOS-FEITOS.md) novo (P1–P21);
  índice só com os pacotes vivos; coluna `estado` no `RESIDUOS.md`; as duas
  linhas resolvidas da v0.14.1 saíram.
- **Fechado na v0.15.0:** as 9 linhas riscadas que ainda diziam `aberto`
  (resolvidas pelas v0.7.1, v0.8.0 e v0.9.0) passaram a `resolvido em vX.Y.Z`;
  o P22 saiu de [`PEDIDOS-EM-ESPERA.md`](PEDIDOS-EM-ESPERA.md) e entrou neste
  registro.
- **Pronto quando:** o índice lista só pacotes vivos, nenhuma linha já
  resolvida fica marcada `aberto` e `tools/docs.sh` continua verde.

## P23 — Oráculo com baseline e diff tolerante (v0.16.0)

- **O quê:** `tools/quadros-diff.mjs` compara os quadros com um baseline
  versionado em `testes/baseline/`, com tolerância (canal e fração de pixels);
  o lote que muda o visível **atualiza o baseline** de forma explícita no mesmo
  commit; o CI roda o diff **depois** de gerar os quadros (`tools/quadros.sh`),
  antes do artefato e do APK.
- **Feito em v0.16.0:** tool Node sem dependência (PNG 8 bits RGBA/RGB, filtros
  0–4), baseline de 60 quadros do CI #38 com `.gdignore` (o Godot não importa e
  o APK já exclui `testes/*`), passo "Diff dos quadros (baseline)" no
  `ci.yml` (upload segue `if: always()`), rito no `docs/BUILD.md` e seção no
  `docs/ORACULO.md`.
- **Pronto quando:** um lote que apaga o botão da HUD reprova o job; dentro da
  tolerância passa; a falha diz qual quadro e quanto saiu da faixa. Provado
  com bloco de 200×200 (reprova, 4,33%), 1 pixel (passa) e quadro faltando
  (reprova); a rodada real do CI é o aceite final.

## P28 — Triagem dos resíduos (commit comum, 2026-11-26)

- **O quê:** [`RESIDUOS.md`](RESIDUOS.md) tinha 256 linhas `aberto`, muitas
  do mockup 2D e do rig 2D superados pela Fundação 3D (P24). Revisar linha a
  linha e mudar só a coluna **estado**; nada se apaga, "o quê" não muda.
- **Feito:** 45 linhas mudaram — **25 `obsoleto (3D)`** (o arquivo citado saiu
  no commit `7ee9d91` — `jogo/mock.gd`, `jogo/criatura.gd`, `jogo/camadas/` —
  ou não é mais referenciado pelo caminho de jogo, conferido com `rg`: pele
  geométrica 2D, `jogo/modulos.gd`, arte 2D de `arte/`, tempos e baseline do
  oráculo 2D)
  e **20 `resolvido vX.Y.Z (motivo)`** (conserto em linha posterior, no
  `HISTORICO.md` ou no código). Legenda nova de `obsoleto (3D)` no topo.
  Ficaram 211 `aberto`, 2 `aberto (design)` e 27 `congelado (rig)`.
- **Não tocado:** linhas `congelado (rig)`, as do rig/esqueleto 3D (v0.29–v0.34,
  inclusive as revisões no aparelho) e as de estado do operador, salvo as
  obsoletas cujo objeto saiu do jogo. Nenhum pacote novo criado.
- **Pronto quando:** nenhuma linha já resolvida ou sem objeto fica `aberto`
  sem evidência contrária, e `tools/docs.sh` segue verde.
- **Decisão do operador (2026-11-26, fechamento):** as 9 linhas do rig 2D
  marcadas `obsoleto (3D)` ficam assim (já superadas); as 5 candidatas a
  pacote (subsolo 3D, copa vazada na Fundação, CI filmar Natureza/hostil,
  salvar configurações de teste, LICENSE/proteção de `main`) foram
  descartadas — 9 linhas viraram `descartado (operador)`.
