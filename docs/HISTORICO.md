# Histórico

> Apêndice: a entrada mais nova em cima. Uma seção por versão, escrita uma vez
> no lote. Lê-se por `grep`, nunca inteiro.

## v0.38.0 — diagnóstico opcional para a referência P25 (2026-11-27)

- **P25/1.2, instrumentação:** botão DIAGNÓSTICO desligado por padrão na HUD;
  FPS/intervalos reais por janela >=0,5 s, delta do motor separado, render/API e
  resoluções efetivas, calls/primitivas globais do último quadro disponível.
  CPU/GPU e contadores sem confirmação aparecem como `n/d`. Não guarda histórico,
  não intercepta gestos; CONFIG oculto e vista íntima suspendem a coleta.
- **P25/1.3 autorizado com UM agente:** validação completa, commit/push,
  publicação via CI e roteiro curto para a primeira coleta na vista ALTA.
  Código de 1.2 preservado; sem otimização, alteração de gráficos/defaults,
  controles/simulação ou novas dependências. Contrato/fila registram o plano,
  autorizações individuais e as evidências locais de 1.1/1.2.
- **Gate local:** `tools/testes.sh` inteiro, exit 0: guardião documental
  (34 Markdown, 49 testes), ferramentas Node offline, **191 testes GDScript,
  0 falhas**, parser de **51 scripts, 0 erros**. `git diff --check` limpo;
  busca de padrões de segredo sem ocorrências. Prévia local de 1.2 já revisada
  (3 quadros Compatibility/softpipe), sem repetir renderização nesta publicação.
- **Limites:** publicar o APK não conclui 1.3. Nenhum benchmark Android nem
  custo da instrumentação no aparelho foi medido. Movie Maker e oráculos por
  software só validam imagem; aguardam-se dados do operador na sessão, sem
  liberar 2.1. Nenhum novo resíduo de código ou documentação.

## v0.37.0 — Natureza como mapa único e faxina do legado (2026-11-27)

- **Publicação do pacote acumulado:** Natureza é o único mapa; saem Fundação,
  parkour, baú, travar, onda do laço e os sistemas antigos de rig/animação.
  Controles maduros preservados. A referência visual passa automaticamente
  aos quadros desta publicação após o CI verde; a diferença para a Fundação
  da v0.36.0 é intencional, sem relaxar os gates do oráculo.
- **Resíduos desta publicação:** nenhum novo de código ou documentação;
  as decisões e limpezas do lote estão registradas abaixo e em `RESIDUOS.md`.

- **Resíduos abertos limpos (2026-11-27, decisão do operador "pode limpar
  todos esses resíduos"):** `RESIDUOS.md` 38 → 0 `aberto` — 12 `descartado
  (regra b)` (legenda nova), 1 `movido para P25`, 15 `descartado (operador)`,
  5 `aceito (controles maduros)`, 2 `aceito (operador)`, 1 `removido`, 2
  `resolvido`. Saíram `sim/animacao.gd`, `dados/animacoes.json`,
  `testes/test_animacao.gd` e `mundo.limitar_caminho` (com o teste); entrou
  `tools/preview.test.mjs` no `tools/testes.sh` (200 → 186 testes GDScript).
  Sem versão.
- **Contrato: o que é resíduo e o que é pendência (2026-11-27, regra do
  operador):** `AGENTS.md` ganhou "Resíduos e pendências" — resíduo é só
  código/documentação a arrumar; teste e avaliação no aparelho não viram
  resíduo nem aviso (pergunta-se na sessão; silêncio = deu certo); conceito e
  conteúdo vão para a fila só confirmados, e só o operador adiciona ou remove
  pendências; o GDD não vira tarefa sozinho; decisões de história são
  respondidas quando o operador puxar o assunto. Linha-resumo no topo de
  `RESIDUOS.md` e `PEDIDOS-EM-ESPERA.md`. Ajustado o que contradizia: a fila
  dizia "todo plano novo entra aqui" (agora: confirmado pelo operador) e
  listava a história como pendência. A linha v0.32.0 `história` de
  `RESIDUOS.md` virou `descartado (operador)` (regra e). Abertos: 39 → 38.
  Sem versão.
- **Natureza vira o mapa único; Fundação, baú, `travar` e onda do laço saem
  (2026-11-27, decisão do operador):** "a ilha e afins não são mais
  necessários" e "o mapa principal agora é o Natureza". Saíram
  `dados/mapas/fundacao.json` (com a extensão de parkour),
  `jogo/mundo3d/ilha.gd`, a vitrine 3D (`vitrine.gd/.tscn`, e o passo dela no
  CI, trocado por `DEMO_ARGS=--pixel` na cena principal, artefato `pixel`),
  o botão MAPA e a troca de mapa do `main`/HUD, `sim/formas.gd` (o leitor do
  laço), a onda (`corpo`, `efeitos`, `formas` e `combate.onda_*` em
  `acoes.json`), o `travar`/`alvo_id`/mira vermelha com o aproximar/rondar da
  autonomia, o baú (`alvos.interativo`, `mais_proximo`) e os terrenos `b`/`r`
  do parkour. A escala px+níveis→3D foi para `jogo/mundo3d/espaco.gd`; o
  gatilho da batida virou `combate.batida_gatilho_px`. Testes: saíram
  `test_formas`, `test_ilha3d`, `test_ilha3d_aba` e os casos de laço, travar,
  baú e parkour; entrou `test_espaco3d`; ajustados `test_mundo`,
  `test_mapa_natureza_jogo`, `test_camera_integracao`, `test_contorno_tela`,
  `test_alvos_adversario` e `test_corpo` (223 → 200 testes). A demo do CI
  filma a Natureza (a comparação com a última publicação acusa diferença em
  tudo até a próxima). 13 resíduos `removido (2026-11-27: …)`. Sem versão.
- **Resíduos: decisões do operador (2026-11-27):** `docs/RESIDUOS.md`, só a
  coluna estado — 104 linhas fechadas: 68 `aceito (controles maduros)`, 7
  `descartado (operador)` (contorno do ator, linhas do caminho/paredes, chave
  do PixelLab, GIF do Pages), 6 `aceito (operador)` (atualizador, retrato,
  nome do pacote), 3 `movido para P30` (vida, dano e morte: pacote novo na
  fila, vai ter mas não agora), 1 `obsoleto (3D)` e 19 `resolvido` (evidência
  reconferida no código). Legendas novas no topo. Ficam 52 `aberto` (eram 156;
  o 211 da nota P28 abaixo era o número daquele dia). A ilha Fundação/parkour,
  o baú e a onda do laço ficam abertos até o lote que os tira do jogo. Sem
  versão.
- **Padrão de modelos 3D no repositório:** guia `docs/MODELOS-3D.md`
  (fontes, licenças aceitas/recusadas, `.credito.txt`, prancha para o
  operador, o que é "pequeno ajuste", onde o escolhido mora, 22 candidatos com
  licença conferida). Ferramentas: `tools/sketchfab.mjs` (busca/info/baixar,
  chave lida do cofre, veredito de licença testado offline em
  `tools/sketchfab.test.mjs`, que entrou no `tools/testes.sh`),
  `tools/prancha3d/` (prancha e mosaico de GLB por CPU; `npm ci`,
  `node_modules` fora do git) e `tools/lvpshim.c` (fonte do shim do oráculo
  Vulkan local, antes só em `~/tmp`). Nenhum `.glb` commitado. P29 na fila.
  Sem versão.
- **Faxina (decisão do operador, 2026-11-26):** o padrão de criatura passa a
  ser modelo 3D pronto do Sketchfab com pequenos ajustes. Saíram o rig próprio
  2D e 3D (`sim/esqueleto*.gd`, `topologia3d`, `locomocao3d`, `sim/modulos.gd`,
  `jogo/rigs*.gd`, `jogo/pele_geometrica*.gd`, `jogo/modulos.gd`, `dados/rig/`,
  `dados/modulos.json`, `tools/folha_canino*.gd`, `docs/RIG.md` e os testes
  deles), o mapa Wang 2D (`sim/mapa.gd`, `ilha_teste.json`, tilesets e objetos
  2D), a arte 2D de prova, o ensaio da água (P27; o conceito ficou escolhido,
  código no commit `64f0d2f`) e o piloto da natureza. `sim/animacao.gd` fica
  (sem `para_rig`). P6, P9 e P10 descartados (`PEDIDOS-FEITOS.md`); resíduos
  do rig viraram `descartado (rig removido)`. Recuperável pelo git até
  `f002dfb`. Sem versão.
- **Ensaio da água de grade (P27), fora do jogo:** `sim/agua.gd` (canos
  virtuais, testado) e a cena `jogo/mundo3d/natureza/agua_ensaio.tscn` — poça
  que nasce, escorre por uma vala, enche uma bacia, transborda até o riacho e
  seca; desenho suave (não cúbico) em `agua.gdshader` e chão úmido em
  `natural.gdshader` (`usar_umidade`, desligado no jogo). Sem versão.
- **Triagem dos resíduos (P28):** `docs/RESIDUOS.md` revisado linha a linha,
  só a coluna estado — 25 `obsoleto (3D)` (legenda nova no topo), 20
  `resolvido vX.Y.Z (motivo)`; ficam 211 `aberto`. Rig congelado intocado. Sem
  versão.

## v0.36.0 — mapa de testes NATUREZA jogável, cores vivas (2026-11-26)

- **Mapa de testes NATUREZA no jogo:** botão **MAPA** da HUD troca Fundação ⇄
  Natureza (recarrega a cena; Pixel Pass atravessa); `--natureza` começa nela.
  `sim/natureza.gd` (pura) é a fonte única: riacho, trilha, três vaus de
  cascalho, clareira de terra fofa, árvores e troncos caídos viram a grade da
  sim (46×62) e o desenho da mata nas MESMAS posições; água, troncos e árvores
  bloqueiam; as duas margens são alcançáveis a pé (teste por busca em largura).
  Chão andável plano (pés e toque alinhados); mapa do chão (trilha, mira,
  perigos) pintado na terra por um shader próprio (`natural.gdshader`).
- **Copa vazada:** folhas e madeira entre a câmera e a criatura somem por
  dither — a criatura não some sob a mata. Sem contorno de tela na mata.
- **Cores mais vivas** (pedido do operador): verdes saturados, água turquesa,
  terra quente, céu claro, tonemap linear e +12% de saturação; vale para o
  piloto e para o mapa. Fundação intacta.
- **Custo:** MultiMesh por família e setor 12×12 (descarte por câmera);
  moldura de mata distante com árvores simplificadas. Mapa inteiro ~691 mil
  triângulos instanciados; FPS no aparelho não medido.
- `vista.altura_relevo` (padrão 4, mata 15): a fatia near..far cabe árvores altas.
- **Piloto separado de natureza 3D:** mata úmida procedural (`jogo/mundo3d/natureza/piloto.tscn`)
  com biblioteca autoral de árvores ramificadas, folhas recortadas, samambaias,
  sub-bosque, raízes, troncos, rochas e riacho sinuoso; seed fixa e MultiMesh.
  Proposta visual low-poly de detalhe moderado, com vistas fixa próxima,
  ortográfica geral e Pixel Pass opcional. Sem custo/downloads externos, sem
  integração no jogo/mobile, navegação ou colisões; desempenho em aparelho e
  aprovação estética do operador continuam pendentes. Sem nova versão ou APK.

## v0.35.4 — contorno sem faixa clara no meio das quinas (2026-11-26)

- **Contorno: quina sem faixa clara no meio** (liso, MSAA 4×): conforme o
  ângulo, a linha de vinco de uma quina convexa clareava NO MEIO (a quina
  aparecia através do preto). Causa: o resolve da profundidade com MSAA
  (Vulkan Mobile: MAX; Forward+/OpenGL: média) chanfra o pixel em cima da
  quina, e o shader usava essa profundidade nas diferenças de 1 px da normal
  do centro (normal híbrida ⇒ ângulo < 75° dos dois lados). Agora, com
  `profundidade_msaa` (liso; o Pixel Pass segue no método antigo), o centro
  vem de braços de 1–2 px sem o próprio pixel, `zp` (plano no centro) entra
  na oclusão e no ponto do meio, e o ponto do meio tem folga de meio px de
  diferença de inclinação. Linha (1): a compensação de inclinação usa o
  offset inteiro do texel lido (filtro nearest) — silhuetas e base da copa
  mais uniformes, degraus duplos do Pixel Pass viram 1 px. Prova local em
  Vulkan/lavapipe (`vitrine --quinas`, q9: quina da tábua com coluna 98 entre
  pretos 16 antes, preta depois), possível aqui com um `LD_PRELOAD` que força
  `LLVMGetHostCPUName` = `cortex-a76` (o llvmpipe emitia SVE ⇒ sinal 4); o
  `--quinas` local saiu idêntico ao artefato do CI.

## v0.35.3 — contorno de vinco: linhas até o contato (2026-11-26)

- **Contorno de vinco** (S7): o contorno de tela soma uma linha onde a
  orientação da superfície muda bruscamente (parede×chão, topo×lateral,
  rampa×parede): a quina do planalto desce até o chão e encontra a linha do pé
  da parede, a rampa ganha linha onde encosta na parede; copa, tronco, ator,
  chão e sombra seguem sem linha interna. Vitrine `--quinas` (CI:
  `vitrine3d/quinas`).

## v0.35.2 — contorno pela profundidade (2026-11-26)

- **Contorno de tela** (S6): a linha escura vira pós 3D pela profundidade
  (`jogo/mundo3d/contorno_tela.gdshader`, quad de tela cheia da vista) no
  lugar da casca invertida e da aba: some no contato (pé do tronco, base do
  ator, quina de plataforma) e a copa por cima do ator ganha linha na borda.
  A casca fica de reserva (`Mat.MODO_CASCA`). Vitrine `--sob-arvore` (CI:
  `vitrine3d/sob-arvore`).

## v0.35.1 — 3D liso por padrão, nítido, e caminho no chão (2026-11-25)

- **Caminho no chão** (S5b): trilha, mira, perigos e a onda são desenhados
  num SubViewport 2D do mapa inteiro (`jogo/mundo3d/chao.gd`, 2046×806,
  31 texels/célula) que o toon do terreno amostra por XZ antes da luz (só em
  faces de cima). Árvores, paredes e a criatura passam por cima; a sombra cai
  sobre o caminho. Projéteis (tiro, cuspe) seguem no ar, na camada de tela.
- **3D liso por padrão e nítido** (S5a): o jogo e a vitrine abrem com o Pixel
  Pass DESLIGADO (`--pixel` liga; `--liso` aceito sem efeito; botão PIXEL ART
  segue ligando). Liso em **resolução física** (SubViewport = `Window.size`,
  desenhado 1/k), MSAA 4× sem FXAA; sombra com near/far justos (ortográfica
  ignora `max_distance`), `shadow_blur` 1 (blur 0 zerava o bias no Mobile:
  acne nas copas), atlas 4096 e filtro soft_low também no `.mobile`; casca
  fora do passe de sombra; faixas do toon com AA por `fwidth`; **aba** no
  contorno do terreno (fim do tracejado na borda vista de quina). CI grava 90
  quadros e a vitrine pixel passa `--pixel`.

## v0.35.0 — Fundação 3D: mundo 3D, Pixel Pass desligável, câmera 360° (2026-11-25)

- **Fundação 3D no jogo** (P24.3–4): `jogo/mundo3d/` (ilha toon+casca, Pixel
  Pass desligável, atores provisórios) + `sim/camera3d.gd`; `jogo/main.gd`
  troca camadas 2D e `Camera2D` pelo mundo 3D; toque e sobreposições pela afim
  chão⇄tela; **barra de giro** no topo (`jogo/barra_giro.gd`); botão PIXEL ART
  na HUD; a demo gira ~120° pela barra. Saíram `jogo/camadas/`, `criatura`,
  `mock`, `mapa`, `objeto`, `adversario_mock`, `animacoes`.
- **Renderizador Mobile/Vulkan** (P24, decisão do operador, 2026-11-25):
  `rendering_method="mobile"` + `fallback_to_opengl3`; o oráculo ganha
  `QUADROS_RENDER=previa|vulkan` — prévia local em Compatibility/softpipe,
  verdade no CI em Vulkan/lavapipe (`mesa-vulkan-drivers`). Ver `docs/ORACULO.md`.
- **Processo enxuto** (decisão do operador, 2026-11-25): commit comum
  (`<área>: …`, sem versão, só testes no CI) × publicação (`vX.Y.Z: …` →
  APK + Release `dev` + preview). A versão passa a contar publicações; esta
  seção junta as notas até a próxima. Rito em `docs/BUILD.md`.
- **Baseline fora do git:** `testes/baseline/` e `tools/quadros-baseline.mjs`
  removidos, job `baseline` extinto; a referência do oráculo é o artefato
  `quadros` da última publicação (`tools/quadros-referencia.mjs`), e diferença
  visual vira aviso no resumo do run.
- Ramos `lote/*` apagados (fica `lote/v0.31.1` no remoto, preservado).
- Trabalho de exportação do rig descartado (P9/P10 congelados até a
  reestruturação da fundação do rig).
- `git gc` local: `.git` de 188 MB para 68 MB.

## v0.34.3 — dobra sempre no polo e clamp de compressão (2026-11-24)

- **Polo fixo:** a dobra obedece ao polo do rig — o cotovelo **sempre para
  trás**. A troca de ramo por "menor violação" da v0.34.2 foi **removida**: era
  ela que virava o cotovelo para a frente.
- **Clamp de compressão:** antes da IK, se a pata chega mais perto do topo do
  que a cadeia permite, o alvo é **afastado** até `√(l2²−l1²) + 0,05`
  (9,76 px na dianteira; 12,44 na traseira). Só age no **balanço**: **0
  quadros de apoio** afetados e o **sha256 das patas em contato é idêntico**
  (1.280 amostras).
- **Números (galope, por perna × 24 fases × 8 direções):** cotovelo acima do
  ombro **10/24 → 6/24**; jarrete acima do joelho **13/24 → 2/24**; joelho
  acima da anca 3/24 (sem mudança); dobra fora do polo **0**. Voo 2,179 (na
  banda), 178 apoios, derrapagem 1,5e−5 px, descompasso 0, fluidez 2,61
  px/quadro (teto 3,5).
- **Custo assumido:** a pata do balanço desce até 5,0 px (média 2,57) e a
  passada aparente do `fe` sobe de 17,0 para 17,46 — o dado não mudou, a pose
  sim.
- **Verificação:** 285 testes/0, parser 67/0, docs 34/0.
- **Baseline:** refeito pelo CI no branch do lote.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.34.2 — dobra anatômica no IK das pernas (2026-11-24)

- **A dobra passou a obedecer à anatomia** nos clipes de marcha: cotovelo
  abaixo e atrás do ombro, joelho abaixo da anca e à frente, jarrete abaixo do
  joelho e atrás. **A pata não se move** — sha256 de 8 direções × 24 fases ×
  walk/run × 4 patas idêntico antes/depois (cão e equino); osso não estica.
- **Resultado medido (galope, por direção):** jarrete acima do joelho
  **13/24 → 4/24** no cão e **4/24 → 0** no equino; joelho acima da anca
  **4/24 → 3/24**; quadros com alguma violação **54 → 32**. Walk já era 0.
- **Limite honesto:** o cotovelo dianteiro continua acima do ombro em
  **10/24** — nessas fases as duas dobras violam **por geometria**
  (ombro→pata < 9,72 px com cadeia de 21 px). O conserto é de **alvo/pose**,
  não de solver.
- **Fluidez melhorou:** pico de **3,482 → 3,104 px/quadro** (teto 3,5).
- **Quadro** derivado do cão **92×76 → 96×78** (o jarrete gira mais para trás).
- **Teste novo:** 8 direções × 24 fases × walk/run reprovam cotovelo acima do
  ombro, joelho acima da anca e jarrete acima do joelho.
- **Verificação:** 285 testes/0, parser 67/0, docs 34/0; voo 2,2103; 178
  apoios; derrapagem sem âncora 0,000015 px; descompasso 0.
- **Baseline:** refeito pelo CI no branch do lote.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.34.1 — ossos do cão pela anatomia de referência (2026-11-24)

- **Omoplata de verdade:** a cernelha subiu 19,1 → **22,0** e a raiz do membro
  dianteiro desceu 18,0 → **15,4**; o osso `peito→ombro` (a omoplata) passou de
  **1,70 px para 8,56 px** (11,0 px de osso) a 62° — antes ela não aparecia.
- **Barras pela referência do operador:** úmero **8,25** / antebraço+metacarpo
  **12,75** (0,393:0,607) e tíbia **8,97** / metatarso **7,60** (razão 1,18) —
  o osso do meio encurtou e o último alongou, como pedido.
- **Alcance preservado:** somas dianteira 21,0 e traseira 27,57; **passadas
  13,8 / 17,0 mantidas** — walk 80,3% e galope 97,1% do alcance no ciclo.
- **Custo medido:** o pico do joelho traseiro subiu para **3,48 px/quadro** a
  60 fps (era 1,9); o teto do teste de fluidez foi de 2,5 para 3,5 com motivo
  (metatarso mais longo sobe o jarrete 1,3 px). **O pé não acelera.**
- **Prancha do galope (2ª referência):** a extensão do rig é 1,69 cernelhas
  (prancha 1,89) e +4,9° de tronco (prancha +9,6°); na compressão o rig não
  reúne as patas (0,67 contra 0,23) — é dívida de **pose**, não de osso.
- **Verificação:** 284 testes/0, parser 67/0; voo 2,2103 (banda 1,8–2,3);
  derrapagem sem âncora 0,000004 px; descompasso 0.
- **Baseline:** refeito pelo CI no branch do lote.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.34.0 — locomoção por câmera e cão comprido (L2) (2026-11-24)

- **O modo da câmera manda na locomoção** (decisão do operador): **perto**
  (pinça) = caminhada **analógica** — 90 px de dedo = curso inteiro = **88 px/s**
  (teto de 0,8 × 110) e **sem sprint**; **longe** (padrão) = **sem caminhada**:
  andando ela já está em corrida, e o segurar acelera (1,7× = 187 px/s). O
  modo é reavaliado a cada movimento da pinça, não só na entrada do toque.
- **Corpo L2:** tronco 17,6 → **21,9 px** (+25%), altura mantida (cernelha 18,
  orelha 32); comprimento total 37,0 → **42,5** (1,33× a altura). O cão deixa
  de ser "mais alto do que comprido".
- **Marcha:** walk com passada 12,0 → **13,8** (91% do alcance); galope com
  `duty` 0,25 → **0,20** e passada 15,0 → **17,0** (98% do teto): **voo de 60%**
  do ciclo e **25,5 px por salto** (era 15,0; +70%). A passada 20,0 foi
  recusada **por medição** — razão do voo 2,40 e alcance 101,6%.
- **Verificação:** 284 testes/0, parser 67/0, docs 34/0; razão do voo 2,2612
  (banda 1,8–2,3); 178 apoios; derrapagem sem âncora 0,000015 px; descompasso
  **0** em todas as marchas.
- **Fluidez:** com a passada maior, a transição walk→run subiu de 12,19 para
  13,89 px (teto 13→15) e o pico do run a 60 fps de 1,9 para 2,31 px/quadro
  (teto 2,0→2,5) — limites ajustados com o motivo declarado.
- **Baseline:** refeito pelo CI no branch do lote.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.33.4 — passada e ciclo reconciliados: apoio sem âncora (2026-11-24)

- **Decisão do operador (2026-11-24), candidato B:** a passada fica e o ciclo
  cede. O ciclo passou a ser **derivado** — `ciclo = passada ÷ duty` (walk
  21,82; galope 60,0 no cão) — então `passada == duty × ciclo` por construção.
  A chave `ciclo_px` saiu do JSON e a validação reprova quem declarar ciclo
  divergente do derivado.
- **A âncora deixou de ser o que segura o pé:** teste novo mede a pata no
  mundo a partir da pose **pura** (sem `alvos`) e exige variação < 0,01 px —
  medido **0,000008 px** no walk (158 apoios) e **0,000004 px** no galope (72).
- **Custo medido:** a cadência do walk sobe ~61% (0,198 s por ciclo aos
  110 px/s); o galope fica praticamente igual (razão do voo 1,966, idêntica).
  Julgar no aparelho.
- **Verificação:** 278 testes/0, parser 67/0, docs 34/0; 187 apoios
  alcançáveis com erro máximo de 0,000004 px; descompasso **0** nas quatro
  marchas do quadrúpede e no trote.
- **Baseline:** atualizado pelo CI no branch do lote.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.33.3 — marcha em dados: walk e galope fora do código (2026-11-24)

- **A pata deixou de ser decidida por clipe:** walk e galope saem da tabela
  `motion.marchas` do rig, ligada por `clipe_marcha`; `_patas` tem **um** ramo
  para qualquer clipe com marcha. `grep 'clipe == "run"'` no motor = 0.
- **O que virou dado:** duty, passada, altura, easings, defasagem por pata,
  curva por lado (dianteira ease-out, traseira ease-in), envelope de voo
  (expoente, afundar do tronco, pescoço), corpo (suspensão, bob, baixa, estica,
  flexão, pitch) e extras (cauda, orelha). `locomocao3d` tira ciclo, duty e
  defasagem da mesma tabela — as chaves soltas de `motion` saíram.
- **Prova de que nada se moveu:** dump de 39.360 poses (2 rigs × 15 clipes ×
  8 direções × 41 fases × salto × yaw) com **sha256 idêntico**
  (`9a4d759a…905`); métricas de voo e marcha bit a bit iguais.
- **Terceira marcha só em dados:** um **trote** declarado dentro do teste
  (duty 0,4, par diagonal) anda com 4 apoios e sem derrapagem, **sem edição no
  motor** — é a prova de que o mecanismo é geral, não canino.
- **Dívida medida, não escondida:** o teste imprime o **descompasso**
  (`passada` × `duty × ciclo`): −7,36 px no walk do cão, +1,90 px no galope.
  Reconciliar é o item (3) da ordem, com as proporções do cão.
- **Verificação:** 277 testes/0, parser 67/0, docs 34/0.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.33.2 — porte e quadro separados no rig (2026-11-24)

- **Duas grandezas:** o rig declara `porte_px` (o cão: 68×68), **imutável**, e
  o quadro calculado sai em `quadro_px` — hoje **92×76** no cão e **122×102**
  no equino, sempre ≥ o porte. `calcular_canvas` virou `calcular_quadro`;
  `canvas_px` deixa de existir no rig 3D e rig antigo reprova (fail-closed).
- **Nada se moveu:** dump de todas as poses (2 rigs × 15 clipes × 8 direções ×
  41 fases × salto × yaw) com sha256 idêntico antes e depois; métricas do voo
  e da marcha bit a bit iguais; 274 testes/0 — dois novos: porte imutável em
  todos os clipes/direções/fases, e quadro contém o porte (rig antigo
  reprovado).
- **Documento:** `RIG.md` marca o item (1) da ordem como feito e o **inseto
  passa a "conceito"** (decisão do operador: só o quadrúpede está em escopo).
- **Verificação:** docs 34/0, parser 67/0.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.33.1 — método do rig documentado (2026-11-24)

- **Novo `RIG.md`:** densidade de arte × porte × quadro × pivô;
  contato primeiro e ângulo depois; as cinco primitivas de locomoção com status
  honesto (quadrúpede implementada, inseto planejada, bípede/ave/serpente
  conceito); autoridade por arquétipo, não por clipe; decisões 1C/2A/3B; ordem
  de trabalho em seis itens.
- **Inventário:** o guia entra no mapa documental de `AGENTS.md`, uma vez.
- **Sem código:** nada de `sim/`, `jogo/`, `dados/` ou `testes/` mudou; o jogo
  continua com o comportamento da v0.33.0.
- **Verificação:** docs 34/0 e guardião 42/0.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.33.0 — esqueleto paramétrico no jogo: voo esticado e giro 4/4 (2026-11-24)

- **P10 entra na `main`:** `sim/topologia3d.gd` (schema 4 com papéis;
  quadrupede/bípede/ave/serpente), `sim/locomocao3d.gd` (fase por distância e
  apoios ancorados no mundo), preset `dados/rig/equino3d.json` (20 juntas) e
  `testes/test_parametrico3d.gd`. O cão continua no schema 3; o equino é a
  prova de "segundo quadrúpede sem editar o solver".
- **Voo do galope: 0,93 → 1,97.** O envelope deixou de ter a fase cravada:
  `_voo_galope(f, mo)` calcula a crista em `0,25 + duty/2` a partir do
  `duty_galope` do rig (com 0,25 o resultado é idêntico ao anterior). No voo o
  tronco afunda, as quatro patas recolhem 1,3×, o pescoço estende 40° e a
  cauda vai baixa em vez de subir. Medido no `canino3d`, fase 0,375: 31,17 ×
  15,85 px.
- **Giro reancora 4/4:** no quadro de reset (clipe novo, giro > 35° ou salto
  > 40 px) as quatro patas são replantadas na posição atual; fora do reset a
  pata no ar continua perdendo a âncora. A marcha segue com 176 apoios
  alcançáveis e erro máximo de 0,002 px.
- **Dados:** cinco chaves novas em `canino3d.json` (`run_voo_baixa_px`,
  `run_voo_pescoco_graus`, `run_easing_traseiro`, `run_voo_levanta`,
  `run_orelha_tras_px`); nenhuma constante antiga mudou.
- **Verificação:** 272 testes/0, parser 67/0, docs 33/0; 60 quadros revisados
  no oráculo.
- **Baseline:** gerado pelo CI no branch do lote e aplicado neste commit.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.32.0 — história: IA no robô solar, drone e chat dos cientistas (2026-11-24)

- **Avatar:** o jogador deixa de ser a criatura; é uma **IA num corpo robótico
  autossuficiente** que cuida de um **filhote** na ilha, **sem impacto
  humano**. O filhote é quem evolui.
- **Instrumento:** recarga **solar** sem base/tomada, **disfarce** sobretudo em
  combate e **drone** de visão tática e comando — o "porquê" é não perturbar o
  ecossistema. Dupla camada vínculo × instrumento virou princípio de design.
- **Pesquisadores:** chat no formato de **comandos/prompts de IA**, tratamento
  do jogador como **IA em treinamento** e inversão **"código × real"** — o
  jogador e o "mundo real" ditos como criação do experimento, com teste do
  jogador **fora da tela** (quarta parede).
- **Arco em duas fases:** urgência/proteção/defesa com comandos protocolares →
  aventura íntima, exploração e **segredos/vestígios da pesquisa**.
- **Alinhado:** evolução ramificada por vivência (raposa alada de fogo),
  realismo ecológico × frieza clínica, personalidade da criatura e reviravolta
  continuam; a afinidade e os gestos de combate não mudaram.
- **Sem mudança de código ou arte:** nada em `sim/`, `jogo/`, `dados/`,
  `testes/` ou `arte/` foi tocado.
- **Documentação:** novo [`docs/gdd/historia.md`](gdd/historia.md); premissa,
  instrumento, narrativa, jornada e uma frase de drone no
  [`CONCEITO`](CONCEITO.md); mapa do [`AGENTS.md`](../AGENTS.md); esta entrada
  e a linha em [`RESIDUOS`](RESIDUOS.md).
- **Verificação:** `tools/docs.sh` com **docs 33/0** e guardião **42/0**;
  nenhum teste de jogo rodado (o lote é só de documentação).
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.31.5 — preview sem comentário (2026-11-24)

- **Sem comentário automático:** o job `preview` deixa de comentar no
  commit/PR (o comentário gerava e-mail a cada push). O link do Pages passa a
  ficar no **resumo do run**; a aprovação continua no chat do DSH.
- **Permissões reduzidas:** `preview` fica com `contents: read`, `pages: write`
  e `id-token: write`; não precisa mais escrever em PR/commit.
- **Sem mudança de jogo:** nenhum código de `sim/`, `jogo/` ou dados mudou.
- **Documentação:** `docs/BUILD.md`, `docs/GODOT.md` e o template de PR
  descrevem o novo fluxo; `tools/preview.mjs --comentar` fica só manual.
- **Verificação:** docs 32/0; testes 265/0 e parser 64/0; YAML do workflow
  validado.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.31.4 — registro do P10 (2026-11-24)

- **Só documentação:** nenhum código de jogo mudou; o comportamento da v0.31.3
  continua.
- **P10 registrado** em `docs/PEDIDOS-EM-ESPERA.md`: objetivo, o que já existe,
  falhas medidas, próximos passos, decisões pendentes e critério de aceite.
- **WIP preservado:** branch `wip/rig-parametrico-3d`, commit `3f7843c`, fora
  da `main`. Estado medido: 272 testes, 2 falhas (voo 0,93:1 e reancoragem
  3/4); não entregar.
- **Verificação da main:** 265 testes/0 falhas e parser 64/0; docs 32/0.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.31.3 — passada longa e corrida baixa (2026-11-23)

- **Passada longa:** `passo_px` 5→12 px no walk e `galope_passo_px` 9,5→15 px
  no run, nos dois rigs; `duty_walk` 0,65→0,55 (apoio mais curto, mais tempo
  no ar).
- **Cadência:** `walk` 0,4→0,32 s e `run` 0,3→0,28 s em
  `dados/rig/canino.json` e `dados/rig/canino3d.json`.
- **Corrida baixa e esticada:** `run_baixa_px` 1,6 (o corpo desce),
  `run_estica_px` 2,5 (o tronco alonga), `galope_suspensao_px` 2,8→4,2,
  pitch +9/−6° e `run_flexao_px` 1,5→3,5; orelhas varridas 5 px para trás e
  cauda esticada (a base sobe sem empurrar a ponta para trás).
- **Silhueta:** o cão continua dentro de 68×68 px (bbox x 4,50–63,50,
  y 13,11–55,00).
- **Transição:** walk→run no primeiro quadro fica em 2,54 px a 60 fps com a
  mistura de 0,08 s; a distância CRUA na fronteira é 12,19 px porque as patas
  caem em pontos opostos do passo maior — o teste do cru passou de teto 9 para
  13 e o da transição de 2 para 3.
- **Teste 2D ajustado:** `testes/test_esqueleto.gd:27` lê `canino.json`; como a
  duração do `walk` caiu de 0,4 para 0,32 s, a expectativa acompanha.
- **Verificação:** 265 testes/0 falhas e parser 64/0; a folha
  `/root/tmp/galapago-passada-folha.png` e os recortes
  `/root/tmp/passada-{east,south,north}-{walk,run}.png` foram revisados.
- **Baseline dos quadros atualizado:** 60 PNG gerados com `llvmpipe` pelo
  [CI baseline run 45296670332](https://github.com/jonathasptbr-gh/Projeto-Galapago/actions/runs/45296670332)
  no commit provisório `ffa5ee8` do branch `lote/v0.31.3`, aplicados via
  `node tools/quadros-baseline.mjs --run 45296670332` no mesmo commit do lote.
  O diff local com `softpipe` continua não comparável com `llvmpipe`; a prova
  final é o CI no commit publicado.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.31.2 — jarrete e metatarso do cão (2026-11-23)

- **Rig canino:** 22 juntas/21 ossos (schema 2) passam a 24/23 (schema 3) —
  duas juntas novas (`jarrete_te`/`jarrete_td`) e dois ossos `jarrete→pata`
  nas pernas traseiras.
- **Repouso:** jarrete em (±6,5; 5; −12), com o joelho à frente da anca e o
  jarrete atrás do joelho e da pata; o metatarso mede ~6,73 px.
- **IK 3D:** o solver escolhe o jarrete no círculo rígido do metatarso,
  preserva a pata quando o alvo é alcançável e corrige o contato em alvo
  impossível sem esticar ossos. As dianteiras ficam intactas.
- **Verificação:** 263 testes/0 falhas e parser 64/0; `tools/quadros.sh` gerou
  60 quadros em `/root/tmp/galapago-jarrete-v0312` e a folha lateral
  `/root/tmp/galapago-jarrete-folha.png` foi ampliada e revisada.
- **Baseline dos quadros atualizado:** 60 PNG gerados com `llvmpipe` pelo
  [CI baseline run 45292419910](https://github.com/jonathasptbr-gh/Projeto-Galapago/actions/runs/45292419910)
  no commit provisório `93d57ad` do branch `lote/v0.31.2`, aplicados via
  `node tools/quadros-baseline.mjs --run 45292419910` no mesmo commit do lote.
  O diff local com `softpipe` continua não comparável com `llvmpipe`; a prova
  final é o CI no commit publicado.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.31.1 — dobras caninas e IK 3D (2026-11-23)

- **Dobras anatômicas:** inversão de cotovelos e joelhos corrigida no repouso
  (`rest`) e na IK; o rig mantém 22 juntas e 21 ossos.
- **IK 3D:** conserva os comprimentos dos segmentos e limita alvos impossíveis
  ao alcance da pata, sem prometer apoio em todo alvo inalcançável.
- **Verificação:** 260 testes/0 falhas, parser 64/0, docs 32/0;
  `tools/quadros.sh` gerou 60 quadros locais sem falhas. Folha de 8 direções ×
  7 clipes e quadro `q00000040.png` conferidos.
- **Baseline dos quadros atualizado:** 60 PNG gerados com `llvmpipe` pelo
  [CI baseline run 45286353241](https://github.com/jonathasptbr-gh/Projeto-Galapago/actions/runs/45286353241)
  no commit provisório `495f6dce`, aplicados via
  `node tools/quadros-baseline.mjs --run 45286353241` no mesmo commit do lote.
  O diff local com `softpipe` continua não comparável com `llvmpipe`; a prova
  final é o CI no commit publicado.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.31.0 — biomecânica e transições do cão (2026-11-23)

- **Parado relaxado (2,4 s):** respiração lenta, peso lateral ±0,8 px, cabeça
  varrendo ±4°, orelhas baixas e cauda com atraso; patas plantadas.
- **Caminhada (4 tempos):** peso para o lado do apoio, ombros/ancas em
  antifase, cabeça estabilizada, saída/pouso com easing e follow-through.
- **Galope:** flexão/extensão do tronco, pitch +6/−4°, cabeça contrapondo,
  cauda esticada com chicote, orelhas para trás; suspensão de 2,8 px.
- **Pulos:** agachar → estender → recolher dianteiras → traseiras → estender
  antes do pouso; o pulo correndo é mais baixo/horizontal, com derrapagem.
- **Mordida/esbarrão:** antecipação, impacto e assentamento (fases medidas).
- **Transições entre clipes:** `Esq3.misturar` e crossfade de 0,08 s só na
  apresentação (walk→run 7,25→1,51 px; run→jump_start 7,84→1,63 px no
  primeiro quadro a 60 fps).
- **Verificação:** 257 testes/0, parser 64/0, docs 32/0; GIFs e tira de
  transições conferidos; baseline dos quadros atualizado no CI #79.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.30.0 — giro contínuo do cão na apresentação (2026-11-23)

- **Rotação 0–360°:** o skin 3D usa o ângulo real do olhar (`yaw_graus` em
  `sim/esqueleto3d.gd`) em vez do yaw do setor; `sim/direcao.gd` continua
  mandando nas regras e nos sockets. Acabou o snap de 45° no desenho.
- **Amortecimento só visual:** curvas suaves giram a 18 rad/s; ataque/marca
  ou virada de mais de 90° num quadro vão direto ao alvo, para a âncora e o
  cone não atrasarem (teste dedicado).
- **Continuidade medida:** 0→1° desloca 0,16 px, 44→45° 0,27 px, 359→0°
  0,16 px — sem salto nas fronteiras de setor.
- **Ferramenta:** `tools/folha_canino3d.gd --giro` gera a folha de 24 ângulos
  (0–345°) × 3 fases e a tira do GIF de 360°.
- **Verificação:** 247 testes/0, parser 64/0, docs 32/0; GIF conferido;
  baseline dos quadros atualizado no CI #77.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.29.0 — cão com esqueleto 3D projetado em 2D (2026-11-23)

- **Fase A do plano 3D:** o cão passa a ser desenhado por 22 juntas e 21 ossos
  em 3D (`dados/rig/canino3d.json`), projetados ortograficamente na câmera
  **low top-down de 20°** (`sim/esqueleto3d.gd`). As oito direções saem da
  mesma geometria — acabam os quatro perfis 2D desenhados à mão.
- **Regras e módulos intactos:** a pose devolve o contrato 2D (`juntas`) e um
  adaptador para `sim/modulos.gd`; sockets (boca, coroa, base_cauda, dorso)
  continuam por nome; `sim/corpo.gd`, `dados/animacoes.json`, serpente e ave
  não mudaram.
- **Fallback:** `--canino-2d` força o rig antigo; rig 3D inválido cai para o
  2D (falha fechada).
- **Fase B (fila P9):** o campo `pecas` do rig 3D já valida o modelo de peças
  2D por osso; o desenho das camadas de pixel art ainda não existe.
- **Verificação:** 240 testes/0, parser 64/0, docs 32/0; folha 8×7×3 e
  comparação 2D×3D; baseline dos quadros atualizado no CI #75.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.28.0 — ombros e quarto traseiro separados da coluna (2026-11-23)

- **Anatomia:** o canino ganhou `ombro_e/ombro_d` e `anca_e/anca_d` fora da
  coluna, com clavícula (`peito→ombro`) e bacia (`quadril→anca`) próprias; as
  patas pendem dos ombros/ancas, não do peito/quadril. No perfil entram
  `ombro_f`/`anca_f` (escápula e quadril); nas diagonais há ombro e anca
  perto/longe com z-order.
- **Largura:** frontal com 16 px entre ombros e 9 px entre ancas recuadas (a
  perna dianteira passa por fora, sem encostar); dorsal com 16 px entre ancas
  (quarto perto) e 10 px entre ombros (tórax longe). De costas a profundidade
  foi corrigida: tórax em cima (longe), quarto embaixo (perto).
- **Marcha:** ombros/ancas entram no tronco do balanço (`_bob_corpo`) e na
  respiração; clavícula e bacia não esticam, e os joelhos novos absorvem o
  pouso do galope.
- **Verificação:** 226 testes/0, parser 59/0, docs 32/0; folha 8×7×3 e zoom 5×
  conferidos; baseline dos quadros atualizado no CI #73.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.27.1 — aprovação só no chat e merge direto do agente (2026-11-23)

- **Canal único:** o chat do DSH é o **único** meio de comunicação e
  aprovação do operador — e-mail, comentário de GitHub, issue e PR **não são
  lidos**. A revisão visual (arte, movimento, UI) acontece aqui, com a imagem
  enviada nesta conversa.
- **Fim do dual-control:** o agente tem autorização permanente para fazer o
  merge do próprio lote direto em `main`; o branch `lote/vX.Y.Z` fica só para
  o CI gerar o baseline do lote visível. O job `preview` vira conveniência,
  não gate.
- **Verificação:** `tools/docs.sh` ok; PR #1 (v0.27.0) mergeado por squash.

## v0.27.0 — cão em oito direções: juntas menores, salto com impulso e cadência ágil (2026-11-23)

- **Juntas menores:** a pele esquelética desenha os pontos vermelhos com raio
  1,4 px (eram 2,2 px) — o movimento das juntas fica legível sem encobrir o
  osso branco.
- **Oito direções reais:** `north` ganhou perfil `dorsal` próprio (sem rosto,
  cauda para baixo, orelhas nas laterais) e as duas diagonais de costas foram
  reorientadas. Andar, correr, morder e esbarrar seguem o vetor de cada setor:
  a mordida e o esbarrão ao norte agora avançam para CIMA, não para o sul.
- **Salto em corrida:** `salto_correndo` é capturado só na decolagem e herdado
  até o pouso; a pose aceita também o impulso FÍSICO da cauda do sprint
  (`_fator_sprint`), sem tocar a física nem inventar impulso fora da rota.
- **Cadência ágil só do canino:** walk 500→400 ms, run 380→300, bite 420→350,
  slam 450→340, aplicados por catálogo privado (`Anim.para_rig`); o catálogo
  comum (`dados/animacoes.json`) e as janelas de dano ficam intactos, e
  serpente/ave não aceleram.
- **Dorso de VFX:** o socket `dorso` (uso `vfx`) ancora o impacto do esbarrão;
  módulo cosmético não o usa como asa.
- **Oráculo auxiliar:** `tools/folha_canino.gd` gera a matriz 8 direções × 7
  clipes × 3 fases (e a variante `--sprint`) no desenho real da pele.
- **Verificação:** `tools/testes.sh` 221 testes/0 falhas, parser 59/0, docs
  32/0; `git diff --check` limpo; baseline dos quadros do llvmpipe atualizado
  no CI #68 (dispatch `baseline`, artefato aplicado em `testes/baseline`).
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.26.3 — estado.sh não confunde o baseline com o CI do main (2026-11-23)

- `tools/estado.sh --ci` mostra o último run de **push** (o CI do main) e, em
  linha separada, o `baseline:` quando um `workflow_dispatch` é o mais novo —
  antes o job de baseline escondia o estado do main.
- `tools/quadros-baseline.mjs`: o download do artifact ganhou **duas
  tentativas** com timeout e erro legível — o blob do GitHub às vezes engasga
  no meio do corpo na rede do celular; `--zip`/`--pasta` seguem de escape.
- **Verificação:** `tools/testes.sh` 213/0; dispatch do job `baseline` no main
  (run #66) gerou o artefato `baseline` de 60 quadros; `estado.sh --ci` mostra
  #65 verde + `baseline: #66`; o download do artefato do #66 não completou por
  rede (o caminho `--pasta` foi verificado).

## v0.26.2 — deploy do Pages com pausa e segunda tentativa (2026-11-23)

- O run #64 mostrou a corrida: o `deploy-pages` roda no mesmo segundo em que o
  `upload-pages-artifact` fecha o artefato e falha com "Fetching artifact
  metadata failed" — o `continue-on-error` segurava o job, mas o site ficava
  na versão anterior. Agora há uma pausa de 8 s e uma **segunda tentativa**
  automática quando a primeira falha; o comentário usa a URL da que deu certo.
- **Verificação:** CI #65 verde e o site do Pages passa a mostrar o lote novo
  (caminho `<run>/` no ar).

## v0.26.1 — preview mais leve e título sem repetir a versão (2026-11-23)

- O GIF do preview caiu de 40 quadros a 320 px (~2,7 MB) para 24 quadros a
  280 px (~1,1 MB): mesma leitura de movimento, menos dados no celular.
- A página e o comentário não repetem mais a versão no título — o assunto do
  commit já começa com `vX.Y.Z:`.
- **Verificação:** `tools/testes.sh` 213 testes/0 falhas; ensaio
  `node tools/preview.mjs --dry` com o GIF novo; CI #64 verde e o comentário
  do lote atualizado no mesmo lugar.

## v0.26.0 — revisão no celular, baseline pré-commit e rito com PR (2026-11-23)

- **Preview do lote no commit:** job `preview` baixa o artefato `quadros`,
  monta um GIF (Pillow; 40 quadros amostrados, 320 px) e três quadros-chave,
  publica no GitHub Pages (`jonathasptbr-gh.github.io/Projeto-Galapago/`) e
  comenta no commit/PR com o link da página e as imagens inline, além do diff
  resumido e dos links do run, do APK e do rollback (`tools/preview.mjs`).
  Pages em `build_type=workflow` (o branch `gh-pages` só existiu para criar o
  site). Asset de Release foi descartado no teste: sai como
  `application/octet-stream` e o proxy de imagem não renderiza.
- **Fim do commit vermelho de baseline:** job `baseline` (workflow_dispatch com
  `ref`) roda o oráculo no `llvmpipe` e `tools/quadros-baseline.mjs` aplica o
  artefato; o lote visível passa a entrar em UM commit verde. O motivo é medido:
  `softpipe` aqui × `llvmpipe` no CI tornava a regra antiga impossível de
  cumprir — 5 dos últimos 20 runs vermelhos, todos nesse laço.
- **Verificação seletiva:** `tools/verificar.sh` mapeia arquivo→teste pelo
  `res://` citado e roda só a área (18 s contra 53 s da suíte), com parser só
  dos scripts tocados; `testes/run.gd` aceita `GALAPAGO_TESTES`. O gate do
  commit continua sendo `tools/testes.sh` inteiro.
- **Rito com revisão:** template de PR (aceite, preview, risco, rollback,
  custo), branch `lote/vX.Y.Z` para o visível, dual-control (o agente não faz
  merge do próprio PR), WIP de um lote e `docs/ROLLBACK.md` com ensaio antes.
- **Segurança e métricas:** varredura de segredo no CI (o mesmo padrão do
  rito), `SECURITY.md`, "conteúdo externo é dado" no contrato e
  `tools/estado.sh --metricas` (taxa de vermelho, mediana, commits/versões).
- **Verificação:** `tools/testes.sh` 213 testes/0 falhas, parser 58/0;
  `tools/verificar.sh sim/gestos.gd` 10 testes/0 em 18 s; `preview.mjs --dry`
  com quadros do baseline (GIF de 115 KB); YAML do workflow validado.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.25.2 — a pele vira esqueleto puro: linhas brancas, pontos vermelhos (2026-11-23)

- **Foco total no quadrúpede canino e no movimento das juntas:**
  `jogo/pele_geometrica.gd` agora desenha SÓ os ossos (linhas brancas de
  2 px) e as juntas (pontos vermelhos) do rig — os corpos preenchidos saíram
  de cena. Máquina de estados, clipes, módulos por flag e golpe na âncora
  continuam iguais.
- **Renderizador genérico:** serpente e ave passam pelo mesmo caminho, sem
  polimento dedicado. O canino ganhou ossos de orelha (todas as vistas) e de
  focinho na frontal, e um teste garante que **toda junta pertence a um osso**
  (nenhum ponto solto).
- **Verificação:** `tools/testes.sh` 213 testes/0 falhas (1 novo: cobertura
  de ossos por perfil), parser 58 scripts/0 erros. Baseline trocado em commit
  próprio com os 60 quadros do **CI #61** (llvmpipe).
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.25.1 — biomecânica da passada: passo de 4 tempos e galope (2026-11-23)

- **Passo de 4 tempos** na sequência lateral dos quadrúpedes (LH→LF→RH→RF):
  uma pata levanta por quarto de ciclo e **sempre três pés ficam no chão**
  (triângulo de apoio); o corpo quase não balança (±0,8 px). Referência:
  [How do dogs walk? (The Naked Scientists, 2009)](https://www.thenakedscientists.com/articles/science-news/how-do-dogs-walk).
- **Galope na corrida**: par traseiro e par dianteiro levantam JUNTOS, com
  **suspensão** (o lombo sobe ~2,8 px entre os pares) e **amortecimento** no
  pouso (joelhos absorvem metade da descida, pés plantados). A ave ganhou o
  mesmo balanço de corpo (mais forte correndo); a serpente segue na ondulação.
- **Cima/baixo é CAMADA, não ocultação:** a vista frontal ganhou o par
  traseiro (`pata_te`/`pata_td`); de frente as dianteiras saem do peito e
  passam POR CIMA do tronco, as traseiras saem do quadril e ficam atrás — e de
  costas (norte) os pares trocam de lado.
- **Verificação:** `tools/testes.sh` 212 testes/0 falhas (3 novos: ordem do
  passo com 3 pés no chão, pares e bounce do galope, dois pares na vista
  frontal), parser 58 scripts/0 erros; folha de estudo do passo/galope
  gerada e conferida por medição de pixels (galope oscila 10 px na tela, passo
  3 px).
- **Baseline:** trocado em commit próprio pelos 60 quadros do **CI #59**
  (llvmpipe).
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.25.0 — a pele geométrica vira o corpo do jogo (2026-11-23)

- **O jogo normal sai do xadrez:** a criatura nasce com o rig `canino` em
  `jogo/criatura._ready`; `--mock` mantém o mock antigo para comparação e as
  flags de demo (`--geo-*`) continuam trocando a pele. É a versão para testar
  a movimentação no aparelho.
- **Movimento básico ligado ao corpo:** andar e **correr**
  (`corpo.correndo()` novo, só leitura), **saída do chão** (`jump_start`),
  **ar** (`jump_air`) e **pouso** (`jump_land`) — além de atordoado, golpe,
  esbarrão, carga, cavar e tiro. Um clipe de UMA VEZ de mesma prioridade agora
  corta loop (o pouso corta o ar).
- **Baseline dos quadros:** o visível mudou de propósito; o baseline foi
  trocado em commit próprio pelos 60 quadros do **CI #57** (`llvmpipe`), como
  manda o [oráculo](ORACULO.md).
- **Verificação:** `tools/testes.sh` 209 testes/0 falhas (1 novo cobrindo
  corrida e as transições de pulo), parser 56 scripts/0 erros; quadros locais
  de 60 abertos.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.24.0 — módulos e efeitos por socket (F4) (2026-11-23)

- **Módulo não sabe coordenada:** `dados/modulos.json` declara o socket por
  NOME (`coroa`, `dorso`, `base_cauda`) e `sim/modulos.gd` resolve posição/z no
  rig da direção e da pose. Socket ausente naquela direção = módulo **não
  desenhado** (fail-closed); `concede_habilidade` precisa ser falso.
- **Efeito por janela de tempo:** `sim/animacao.janela_ativa` lê as janelas do
  catálogo (ms, socket, evento) e `jogo/modulos.gd` desenha a faísca/onda no
  socket. Nada disso altera dano, alcance ou tempo.
- **Na pele:** `--geo-modulos=tufo,espinho_cauda` entra na demo — tufo na
  coroa, espinho na base da cauda e membrana no dorso (só onde o rig tem o
  socket). `--geo-estado=bite` mostra a faísca na janela de dano da mordida.
- **Verificação:** `tools/testes.sh` 208 testes/0 falhas (6 novos: socket por
  nome, ausência por direção, fail-closed de habilidade, janela por tempo e
  efeito), parser 56 scripts/0 erros; quadros com módulos no canino e na
  serpente e com a faísca da mordida, PNGs abertos.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.23.1 — clipes de mecânica que faltavam (F3b) (2026-11-23)

- **O T0 do catálogo está desenhado nos três rigs:** além de `idle`/`walk`,
  agora existem `run`, `jump_start`, `jump_air`, `jump_land`, `shot`, `slam`,
  `hit`, `death` e `get_up`.
- **Drivers:** correr abre mais o passo (1,35×); o pulo agacha, recolhe as
  patas e amortece no pouso; o tiro recua; o esbarrão avança baixo; o dano
  recua com a cabeça baixa; a morte tomba 80° em torno dos pés e `get_up`
  desfaz.
- **Correção de contrato:** fase de clipe de uma vez **para em 1** — antes o
  `wrapf` devolvia 0 no último instante e a morte nunca chegava ao chão.
- **Verificação:** `tools/testes.sh` 202 testes/0 falhas (2 novos: os 15
  clipes nos 3 rigs e o sentido de cada pose), parser 55 scripts/0 erros;
  quadros forçados de pulo, tiro, esbarrão e morte abertos.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.23.0 — máquina de estados da animação (F3) (2026-11-23)

- **Catálogo de 43 ações** em `dados/animacoes.json`: camada, loop, duração,
  prioridade, capacidade exigida (`requer`), interrupções e janelas de evento
  por **tempo** com o socket que ancora o VFX. Durações **provisórias**;
  `hit`/`death` ficam prontos e dormentes enquanto não existir vida.
- **Máquina pura** `sim/animacao.gd`: retrato do corpo (andando, atordoado,
  golpe, carga, escavando, pulo) → clipe, com prioridade (morte > atordoado >
  dano > ação > salto > base > overlay > expressão). Clipe de uma vez segura a
  cena; ameaça mais urgente corta; a base troca entre andar e parado.
- **A pele obedece:** `jogo/animacoes.gd` carrega o catálogo e
  `jogo/criatura.gd` desenha o clipe/fase escolhidos. Os três rigs ganharam
  `bite`, `stunned`, `dig` e `charge`, com drivers geométricos (o corpo avança
  sem arrastar os pés, treme e pende a cabeça, abaixa para cavar, encolhe na
  carga). `--geo-debug` mostra o clipe; `--geo-estado=<id>` congela um clipe
  na demo.
- **Verificação:** `tools/testes.sh` 200 testes/0 falhas (8 novos: catálogo,
  prioridades, clipe de uma vez, interrupção, fase loop/fim e retrato do
  corpo), parser 55 scripts/0 erros; quadros do oráculo com mordida,
  atordoado, cavar e carga — PNGs abertos; o mock padrão segue intacto.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.22.0 — pele geométrica no jogo (F2) (2026-11-23)

- **A criatura pode ser desenhada pelo esqueleto**, não pelo xadrez:
  `--demo --geo-canino|serpente|ave` liga `jogo/pele_geometrica.gd`, que
  desenha o rig de `dados/rig/` sem asset nenhum. O padrão continua o mock;
  sem a flag, nada muda na tela.
- **Direção e clipe vêm do corpo:** `sim/direcao.gd` (puro, testado) mapeia
  `corpo.olhar` em 8 setores; o clipe é `walk` quando a posição andou no quadro
  e `idle` quando não; a fase usa a duração do rig. O cone do golpe passa a
  sair da âncora `boca` quando ela existe (antes, do centro do corpo).
- **Três âncoras no mesmo caminho:** canino, serpente (rastejo) e ave
  (bípede) desenham com a mesma pele; `--geo-debug` mostra ossos, juntas e
  âncoras. `jogo/rigs.gd` carrega e cacheia o rig, fail-closed.
- **Verificação:** `tools/testes.sh` 192 testes/0 falhas (novos: oito setores
  de direção e o carregador de rigs), parser 52 scripts/0 erros; quadros do
  oráculo nas duas câmeras com os três rigs, PNGs abertos; o mock padrão
  continua idêntico, então baseline do oráculo não foi tocado.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.21.2 — rigs de serpente e ave (2026-11-23)

- **As três famílias-âncora têm rig.** `dados/rig/serpente.json` (11 juntas,
  sem pernas; `walk` é rastejo com onda que corre pela cadeia s0..s7) e
  `dados/rig/ave.json` (13 juntas; bípede, as duas pernas alternam e a asa
  fica dobrada). Os dois com **8 direções** e os mesmos quatro perfis de pose
  (frontal, lateral e duas de 3/4) + espelho.
- **Despacho por arquétipo:** `sim/esqueleto.gd` escolhe o driver —
  quadrupede (patas), serpente (`_rasteja`) e ave (`_bipede`); `motion.driver`
  é texto e o resto do `motion` continua numérico. `arquetipo` desconhecido
  falha fechado.
- **Sockets por família:** serpente `boca`/`dorso`/`base_cauda`; ave
  `boca`/`coroa`/`base_cauda`, com a mesma regra de ausência por direção e
  `null` explícito.
- **Verificação:** `tools/testes.sh` 203 testes/0 falhas (3 provas novas: os
  três rigs válidos nas 8 direções; serpente ondula sem inventar perna; ave
  alterna os pés e mantém um no chão), parser 56 scripts/0 erros. Ainda **sem
  desenho** (F2) e sem arte aprovada.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.21.1 — oito direções no esqueleto (2026-11-23)

- **O contrato passa a 8 direções** (S, SE, E, NE, N, NW, W, SW): o rig do
  canino ganha dois perfis de 3/4 — `diagonal` (frente-direita) e
  `diagonal_costas` (costas-direita), espelhados para oeste; cardinais
  continuam nos perfis `frontal` e `lateral`. `sim/esqueleto.gd` só passou a
  aceitar a lista e a tratar todo perfil não-frontal como marcha lateral.
- **Âncoras por direção:** `boca` some em norte/nordeste/noroeste,
  `base_cauda` some em sul/sudeste/sudoeste e `coroa` existe em todas — o
  mesmo `null` do E4, sem herdar posição.
- **Verificação:** `tools/testes.sh` 200 testes/0 falhas (os testes do
  esqueleto agora cobrem os pares de espelho das diagonais e a ausência de
  âncora nelas), parser 56 scripts/0 erros; `git diff --check` limpo. Sem
  mudança visível no jogo (o esqueleto ainda não é desenhado), baseline do
  oráculo intacto.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.21.0 — esqueleto: contrato de pose e âncoras (2026-11-23)

- **Camada nova, pura e sem desenho.** `sim/esqueleto.gd` lê um rig de dado
  (`dados/rig/<familia>.json`), valida fail-closed, avalia a pose por fase
  (`pose(direção, fase, clipe)`) e resolve âncora por NOME (`boca`, `coroa`,
  `base_cauda`) com `front/back` e ausência explícita — invisível não herda
  posição. Nada decide regra: dano, alcance e tempo seguem em `sim/corpo.gd`;
  socket **decora, não decide**.
- **Rig do canino (âncora):** 2 perfis (lateral/frontal), 4 direções por
  espelho em torno do pivô, clipes `idle` (1,0 s) e `walk` (0,5 s), envelope
  32×39×20 px e pivô nos pés (34,50) no canvas 68×68. Marcha provisória por
  parâmetros; a pele de arte futura substitui o driver sem tocar na mecânica.
- **Ainda NÃO ligado ao desenho:** o jogo normal continua no mock; a pele
  geométrica (F2) e a troca para sprite (F5) não foram feitas. Nenhuma mudança
  visível, então o baseline do oráculo não foi tocado.
- **Verificação:** `tools/testes.sh` 199 testes/0 falhas (11 novos em
  `test_esqueleto.gd`), parser 56 scripts/0 erros; `git diff --check` limpo.
- **Resíduos:** ver `docs/RESIDUOS.md`.

## v0.20.2 — caminho nascido do segurar começa na posição atual (2026-11-22)

- **Bug do operador:** correndo em sprint (segurar), mover o dedo sem levantar
  criava um caminho novo a partir da origem onde o dedo desceu, e a rota nova
  zerava a aceleração. Agora o traço RECOMEÇA na posição ATUAL da criatura
  (`sim/gestos.recomecar`) e a rota nova mantém o sprint e a rampa já vencida.
- O desenho nascido de um segurar é marcado em `jogo/main.gd`
  (`_desenho_de_segurar`): a origem tela→mundo é recongelada no ponto atual, o
  primeiro traço só é adotado quando aceito e, ao soltar, a trajetória encerra
  o segurar (`soltar_segurar`) — o sprint não fica preso. O desenho normal
  (sem segurar) continua com a origem congelada na descida e zera a rampa.
- Verificação: `tools/testes.sh` 169 testes/0 falhas, parser 45 scripts/0
  erros, 42 testes do guardião; teste de integração headless encenou
  rota→segurar→mover→soltar (origem e rota novas na posição atual, sprint e
  rampa mantidos, sprint encerrado com cauda). Oráculo de 60 quadros softpipe:
  q36/q37 divergem do baseline llvmpipe (0,75%), e o clone limpo do HEAD no
  mesmo softpipe diverge igual — sem baseline novo; o CI confirma. Sem teste
  no aparelho.
- Resíduos: ver `docs/RESIDUOS.md`.

## v0.20.1 — vista íntima um pouco mais baixa (2026-11-22)

- A inclinação mínima da vista íntima passa de 0,72 a 0,60; a vista superior,
  a pinça e o controle relativo permanecem. Relevo e detalhe continuam
  interpolando ao longo de toda a aproximação.
- Oráculo softpipe: vista íntima de planalto aberta; na vista superior, 2 de
  60 quadros divergiram do baseline llvmpipe (0,75% cada). O baseline não foi
  alterado; é preciso verificar o CI antes de entregar. Suíte: 167 testes,
  45 scripts sem erro de parser e 42 testes documentais.
- A confirmação visual e o teste de controles no aparelho dependem do operador;
  limitações anteriores de marcas e da pinça sobre a HUD permanecem.
- Resíduos: ver `docs/RESIDUOS.md`.

## v0.20.0 — câmera por pinça e controle relativo (2026-11-22)

- Pinça aproxima de 1,6 a 3,2 e inclina o plano; cancela o gesto corrente e
  bloqueia os contatos até todos saírem. Na vista íntima, um dedo movimenta
  relativamente; soltar, cancelar ou perder foco interrompe o movimento. Não
  foram inventados gestos de ataque ou salto para essa vista.
- HUD de teste oculta na vista íntima, com avisos de atualização preservados.
  A captura de segundo contato sobre a HUD é testada chamando os métodos, não
  por propagação real da GUI. A ordem inversa (primeiro na HUD, segundo no
  mundo) permanece pendente para não comprometer os botões.
- Marca, efeito, perigo e adversário em terreno alto transitam continuamente
  da posição histórica superior até o topo na aproximação máxima. Compromisso:
  nas inclinações intermediárias não coincidem exatamente com o topo do chão.
- Verificação: `tools/testes.sh` passou 167 testes, parser 45 scripts e 42
  testes do guardião; os quadros softpipe de planalto superior, intermediário e
  íntimo foram capturados e abertos. Essas imagens não exercitam marcas ou
  efeitos; a continuidade é verificada numericamente. Sem teste no aparelho.
  Não foi atualizado o baseline do CI neste trabalho.
- Resíduos: ver `docs/RESIDUOS.md`.

## v0.19.0 — tempo de carga do tiro ajustável (tamanho pelo tempo) e botão CONFIG (2026-11-22)

- **Autorizado pelo operador:** o tempo de carga do tiro (**1 s** da v0.18)
  ficou **longo**; o pedido foi deixá-lo **configurável** por um **slider de
  0 a 1,5 s** na HUD, com o **tempo escolhido definindo o TAMANHO/FORÇA** do
  tiro, e um **botão de configurações (`CONFIG`)** que **esconde/mostra toda a
  HUD de teste**. O padrão passou a **0,5 s**.
- **`dados/`:** `acoes.json` — `combate.tiro_carga_s` de 1,0 para **0,5**
  (padrão do slider) e **entra** `combate.tiro_carga_max_s` **1,5** (teto do
  slider e referência do tamanho); seguem `tiro_carga_raio_x` 1,5,
  `tiro_carga_alcance_x` 1,6, `tiro_carga_empurrao_x` 2,0, `tiro_raio` 9,
  `tiro_alcance` 280, `tiro_empurrao` 24, `tiro_velocidade` 420,
  `tiro_recarga_s` 1,0 e `tiro_pausa_s` 0,25. Nenhum valor antigo mudou de
  significado; as descrições `_leia` de `gestos.json` e `acoes.json` foram
  reescritas para a v0.19.0 (chaves e valores intactos).
- **`sim/` (API da carga):** `corpo.carga_tiro_s` é **público** (nasce de
  `combate.tiro_carga_s`, padrão 0,5 s; a HUD escreve) e
  `corpo.tiro_carga_max_s()` devolve o teto de `combate.tiro_carga_max_s`
  (1,5 s, nunca ≤ 0 porque é divisor do tamanho). `carga()` continua sendo o
  **PREPARO** (`_carga_t / _carga_max_s`, o preenchimento da barra/anel), não o
  tamanho. `_cmd_tiro` com `carga_tiro_s` = 0 dispara **na hora**
  (`"ok: tiro"`, sem estado de carga e sem "CARREGANDO"); com > 0 começa a
  carga, e `_iniciar_carga` **trava o teto no começo** (mudar o slider no meio
  não reinicia nem encurta o preparo). `_disparar_carga` passa ao projétil
  `carga_tiro_s / tiro_carga_max_s()` (0..1), que multiplica
  raio/alcance/empurrão — **o tamanho é lido no disparo**. A direção continua
  alvo marcado vivo → destino final do caminho (nunca o toque); sem rota/alvo é
  `"recusado: sem destino"`; o toque segue **pendente 280 ms** pela janela do
  duplo; a carga cancela por caminho novo ou segurar.
- **`jogo/`:** a HUD ganha o botão **`CONFIG`** (240×34, sempre visível; o texto
  alterna `CONFIG` ↔ `MOSTRAR`) e o **slider `CARGA DO TIRO`** (rótulo
  `CARGA DO TIRO: 0,50 s`, ou `instantâneo` em 0; `HSlider` 0–1,5 s, passo
  0,05, padrão 0,5, `FOCUS_NONE`; `value_changed` escreve
  `corpo.carga_tiro_s`). O CONFIG esconde/mostra os `Control` filhos da HUD —
  **ficam sempre** o próprio botão, o `atualizador` (prompt de atualização) e o
  `veu` (escurecimento do desenho, `ColorRect` de tela cheia no índice 0). A
  barra amarela de carga e o anel da criatura continuam mostrando o **preparo**
  e voltam só enquanto o corpo carrega; a **legenda** ganha a linha
  `CONFIG → esconde esta HUD` (11 linhas). O slider é **runtime-only** (a HUD de
  teste não salva configuração).
- **`testes/`:** entram os testes do tempo de carga configurável — padrão 0,5 s
  vindo do JSON, 1,5 s = tiro máximo (13,5/448/48), 0,75 s = meio
  (11,25/364/36), **0 s instantâneo** (`"ok: tiro"`, sem carga, tiro base
  9/280/24), `tiro_carga_max_s()` nunca ≤ 0 e **slider no meio da carga** sem
  quebrar o preparo em curso.
- **Verificação:** na **árvore compartilhada**, `tools/testes.sh` =
  **163 testes, 0 falhas** — inclui **4 testes da outra sessão**, fora deste
  lote —, `parser: 44 scripts, 0 com erro` (2 scripts daquela sessão) e
  `docs: 29 Markdown, 0 erro(s)`. O **lote isolado só deste commit** foi
  verificado num worktree limpo: **159 testes, 0 falhas** (parser 42, docs 29).
  O oráculo **local** (60 quadros e 240 da demo) rodou **sem SCRIPT ERROR**; o
  slider aparece em **0,50 s** e a barra amarela em **~33%** no quadro 112 da
  demo.
- **Outra sessão, fora deste lote:** o **working tree** também tem trabalho
  **não commitado de outra sessão** (câmera com pinça/zoom e joystick
  relativo), que **não** faz parte da v0.19.0 — o commit deste lote leva só os
  arquivos dele.
- **Oráculo/baseline:** o visível **mudou** (botão CONFIG, rótulo e slider da
  carga na HUD e a linha nova da legenda). O baseline `testes/baseline/` foi
  **atualizado neste lote** com os 60 quadros do **CI #45** (`llvmpipe`, commit
  `49b9810`) num commit seguinte do mesmo lote. A primeira rodada do CI (#45)
  **reprovou só no diff** (60 quadros fora da tolerância) — a prova de que a
  mudança era visível; a suíte e o parser passaram.
- **Resíduos:** o slider é **runtime-only** (não salva entre aberturas); o
  padrão 0,5 s e a faixa 0–1,5 s são **pontos de partida**; o tamanho é linear
  no tempo (0,5 s = 1/3 do ganho); o instantâneo (0) não tem "CARREGANDO"; o
  toque espera a janela do duplo (280 ms) antes de começar a carga; sem
  rota/alvo não atira; a barra/anel/CONFIG são **mockup**; os 60 quadros do CI
  cobrem só 2 s.

## v0.18.0 — toque atira carregado, segurar corre e rampa no início da caminhada (2026-11-22)

- **Autorizado pelo operador:** **reverter** a v0.17. O **toque simples volta a
  ser TIRO** (com o tempo de carga, mesmo num toque só), o **toque longo
  (segurar) volta a ser CORRER** (com caminho; sem caminho é a habilidade/
  cavar), a **pausa de saída** deixa de existir, e o delay é substituído por
  uma **rampa de aceleração** no começo de cada caminhada (0,30 s). A v0.17
  teve a pausa de saída, a arrancada curta do toque e o tiro no soltar do
  segurar; a v0.18 remove as três.
- **`dados/`:** `gestos.json` — `mapa.toque` de `"correr"` para `"tiro"`,
  `mapa.segurar` = `"segurar"`; **sai** `limiares.segurar_atraso_ms` (200).
  `acoes.json` — **sai** `sprint.dura_s` (0,6) e **sai** `rota.atraso_s`
  (0,35); **entra** `rota.rampa_s` 0,30; `combate.tiro_carga_s` 1,0 com
  `tiro_carga_raio_x` 1,5, `tiro_carga_alcance_x` 1,6 e
  `tiro_carga_empurrao_x` 2,0; a base do tiro segue `tiro_velocidade` 420,
  `tiro_alcance` 280, `tiro_raio` 9, `tiro_empurrao` 24, `tiro_recarga_s` 1,0
  e `tiro_pausa_s` 0,25 **depois** do disparo. Nenhum valor antigo mudou de
  significado.
- **`sim/gestos.gd`:** **sai** `definir_atraso` e todo o ramo da pausa (não há
  mais limiar curto de 200 ms nem toque sem pendência); o toque simples fica
  pendente **só** pela janela do duplo (280 ms), agora para não **atirar** no
  primeiro toque de um duplo; o segurar vale em `segurar_min_ms` (380 ms) em
  qualquer lugar.
- **`sim/comandos.gd`:** o `mapa` volta a mandar `toque` → `"tiro"`; sem pausa
  para avisar.
- **`sim/corpo.gd`:** `_cmd_tiro` **começa a CARGA** (o animal para; `_carga_t`
  cresce até `combate.tiro_carga_s` 1 s e `_disparar_carga` atira **sozinho**
  com carga **1,0**, no **alvo marcado vivo** → **destino final capturado** →
  `olhar`; **nunca** na direção do toque); sem rota e sem alvo é `"recusado:
  sem destino"` e a carga nem começa. `_cmd_segurar` vira o **SPRINT CONTÍNUO**
  com caminho (fator 1,7×, energia 0,45/s, recuperação 0,22/s) e a **HABILIDADE**
  sem caminho; `_cmd_soltar_segurar` só desliga o sprint e arma a cauda
  (`sprint.cauda_s` 0,6 s) — **não dispara tiro**. A carga é cancelada por um
  **caminho novo** (`_guardar_rota(reiniciar=true)`) ou por um **segurar**;
  soltar o dedo não dispara nem cancela. **RAMPA:** `_rampa_t`/`_fator_rampa`
  sobem de ~15% a 100% em `rota.rampa_s` (smoothstep); só um caminho **novo** a
  rearma — o traço ao vivo que cresce e a retomada depois de tiro/contorno
  **não** reiniciam. **Saem** `_cmd_correr`, `_cancelar_caminhada`,
  `em_atraso`/`atraso_restante_s` e o ramo da pausa no `passo`.
- **`jogo/`:** a HUD perde o `PAUSA`/`_decimal` e ganha `CARREGANDO %`; a barra
  amarela acima da energia e o anel na criatura aparecem **só enquanto carrega**
  (mockup). A **legenda** fica com **10 linhas** (toque → tiro carregado
  (alvo/fim); segurar no caminho → correr; segurar parado → habilidade).
  `main.gd` não pergunta mais `em_atraso()` nem chama `definir_atraso`. A
  **demo** (~16 s) mostra a **rampa** no caminho, o toque = carga+tiro, o
  segurar = sprint+cauda, o caminho no inimigo + toque = tiro no alvo vivo, o
  toque duplo = pulo, a perseguição/golpe e o cavar sem caminho.
- **`testes/`:** **7 a menos** (161 → 154): saem os testes da pausa de saída e
  da arrancada do toque; entram carga e disparo automático, `"recusado: sem
  destino"`, tiro no alvo vivo, sprint/energia/cauda, rampa e rearme só em rota
  nova, cancelamento da carga por caminho novo e por segurar, e o segurar sem
  caminho cavando. **Verificação:** `tools/testes.sh` **154 testes, 0 falhas**;
  `parser: 42 scripts, 0 com erro`; `docs: 29 Markdown, 0 erro(s)`; a execução
  **local** dos 60 quadros do oráculo e dos 480 da demo terminou **sem SCRIPT
  ERROR**.
- **Documentação:** GDD reescrito no toque carregado, no sprint do segurar e na
  rampa de início (a seção "A pausa de saída (v0.17)" foi **removida**);
  `CONCEITO`, `AGENTS` e as descrições `_leia` de `dados/gestos.json` e
  `dados/acoes.json` atualizados para o que o jogo faz agora.
- **Oráculo/baseline:** o visível **mudou** (legenda v0.18 e a demo nova com a
  rampa). O baseline `testes/baseline/` foi **atualizado neste lote** com os 60
  quadros do **CI #43** (`llvmpipe`, commit `0591201`) num commit seguinte do
  mesmo lote. A primeira rodada do CI (#43) **reprovou só no diff** (60 quadros
  fora da tolerância, pela legenda/demo novas) — a prova de que a mudança era
  visível; a suíte e o parser passaram.
- **Resíduos:** a rampa 0,30 s e a carga 1,0 s são **pontos de partida**; o
  toque espera a janela do duplo (280 ms); o tiro é sempre de carga cheia; sem
  rota/alvo o toque não atira; o segurar sem caminho cava; a HUD de carga é
  mockup; os 60 quadros do CI cobrem só 2 s.

## v0.17.0 — gestos: correr no toque, tiro carregado no segurar e pausa de saída (2026-11-22)

- **Autorizado pelo operador:** as quatro decisões de gesto da v0.17 —
  **toque = correr**, **segurar = tiro carregado**, **pausa de saída** de
  0,35 s (toque pula e corre; segurar cancela a caminhada e atira) e **tiro
  sem alvo marcado mirado no destino final do caminho**. O tiro deixa de sair
  no toque e passa a sair no **soltar do segurar**; o segurar sem caminho nem
  alvo continua sendo a **habilidade** (cavar).
- **`dados/`:** `gestos.json` — `mapa.toque` de `"tiro"` para `"correr"` e
  `limiares.segurar_atraso_ms` 200; `acoes.json` — `sprint.dura_s` 0,6,
  `rota.atraso_s` 0,35 e `combate.tiro_carga_s` 1,0 com
  `tiro_carga_raio_x` 1,5, `tiro_carga_alcance_x` 1,6 e
  `tiro_carga_empurrao_x` 2,0. Nenhum valor antigo mudou de significado.
- **`sim/gestos.gd`:** `definir_atraso` (o corpo avisa a pausa), limiar curto
  `segurar_atraso_ms` na pausa (200 ms; fora dela segue `segurar_min_ms`, 380),
  toque na pausa **sem pendência** e **sem detecção de duplo**, e um segurar
  ≥ 200 ms devolve `segurar_inicio` + `segurar_fim` no **mesmo soltar** (a
  carga e o disparo saem no mesmo quadro). O toque simples fora da pausa
  continua pendente pela janela do duplo (280 ms).
- **`sim/comandos.gd`:** o toque segue `mapa.toque` (`"correr"`);
  `segurar_inicio` → `"segurar"` e `segurar_fim` → `"soltar_segurar"`.
- **`sim/corpo.gd`:** `_cmd_correr` (arrancada de `sprint.dura_s` 0,6 s no
  fator 1,7×, energia 0,45/s, rearma por um novo toque e cauda de 0,6 s);
  `_cmd_segurar`/`_cmd_soltar_segurar` (carga até 1 s com o animal **parado**;
  tiro no **alvo marcado vivo** ou no **destino final capturado**;
  `"recusado: sem destino"` sem rota nem alvo); `_cancelar_caminhada` (rota
  **esvaziada**, `mira_final_id` **preservada**, autonomia `"parado"`);
  `_atirar(carga)` escalando raio, alcance e empurrão. A pausa é armada **só**
  em `finalizar_rota` (`em_atraso`/`atraso_restante_s`; `tracar` e o traço ao
  vivo **não** armam). O sprint deixa de terminar em `soltar_segurar` e passa a
  ter duração própria, com a cauda depois dela.
- **`jogo/`:** HUD com `PAUSA`/`CARREGANDO`, barra de carga **amarela** acima
  da energia, anel de carga na criatura e a **legenda de 11 linhas**;
  `main` avisa o reconhecedor da pausa (`definir_atraso`) na descida do dedo e
  a cada quadro; a demo encena o caminho de sempre, pausa+segurar,
  pausa+toque, tiro no alvo marcado, toque duplo, perseguição/golpe final e o
  segurar sem caminho (cavar) — **~15 s**.
- **`testes/`:** **12 a mais** (149 → 161), com 16 funções novas e 4
  substituídas: pausa e dois toques, limiar curto, dois dedos na pausa,
  cancelamento da caminhada, mira preservada, carga e teto de 1 s, tiro no fim
  do caminho, `"recusado: sem destino"`, arrancada/energia/rearma, cauda,
  arrancada sem caminho e pulo automático com a arrancada.
  **Verificação:** `tools/testes.sh` **161 testes, 0 falhas**;
  `parser: 42 scripts, 0 com erro`; `docs: 29 Markdown, 0 erro(s)`; a execução
  local do oráculo (60 quadros) termina **sem SCRIPT ERROR**.
- **Documentação:** GDD reescrito na pausa de saída, no tiro carregado e na
  arrancada do toque (e o valor da onda corrigido de 140 para **100 px/s**,
  lido do dado real); `CONCEITO`, `AGENTS` e as descrições `_leia` de
  `dados/gestos.json` e `dados/acoes.json` atualizados para o que o jogo faz
  agora.
- **Oráculo/baseline:** o visível **mudou** (a legenda de 11 linhas e a pausa
  no fim dos 60 quadros). O baseline `testes/baseline/` foi **atualizado neste
  lote** com os 60 quadros do **CI #41** (`llvmpipe`, commit `3b01634`; run
  45034751151) num commit seguinte do mesmo lote. A primeira rodada do CI
  **reprovou só no diff** (3,28% dos pixels por quadro na legenda e 6,14% no
  último, pela pausa) — a prova de que a mudança era visível; a suíte e o
  parser passaram.
- **Resíduos:** os tempos da v0.17 são **pontos de partida**; fora da pausa o
  toque espera a janela do duplo; a carga conta do **limiar**; o soltar em
  recarga cancela a caminhada e não dispara; a barra/anel de carga são
  **mockup**; os 60 quadros do CI cobrem só os 2 primeiros segundos.

## v0.16.1 — higiene de CI e tooling (2026-11-22)

- **Autorizado pelo operador:** fechar os resíduos pequenos de fundação.
  **Nenhum código de jogo, dado ou teste mudou.**
- **`ci.yml`:** `checkout@v7`, `setup-java@v6`, `cache@v6` e
  `upload-artifact@v7` — fim dos avisos de Node 20 nas actions antigas.
- **`tools/android/exportar.sh` (passo 5):** `apksigner verify --verbose
  --print-certs` com `2>&1`; se não houver linha, aviso explícito e conferência
  por `keytool -printcert -jarfile`. A assinatura deixa de sumir do log.
- **`tools/pixellab-tileset.mjs`:** a espera de 423 passou de 30 tentativas
  (~2,5 min) para um teto de **45 s**, com mensagem de "job pode ter falhado";
  a API não expõe endpoint de status, então o limite é por tempo.
- **Verificação:** `tools/testes.sh` 149/0, parser 42/0, docs 29/0; `bash -n`
  e `node --check` limpos. O CI #40 prova as actions novas e imprime a
  assinatura; o 423 real de job falho não é reproduzível sem um job falho.

## v0.16.0 — oráculo com baseline e diff tolerante (2026-11-22)

- **Autorizado pelo operador:** seguir o **P23** (fundação). O CI agora
  **reprova regressão visual**: gera os 60 quadros, compara com
  `testes/baseline/` e só então publica o artefato e libera o APK. **Nenhum
  código de jogo mudou.**
- **`tools/quadros-diff.mjs` (novo):** Node puro, sem dependência; decodifica
  o PNG (zlib + desfiltro 0–4, 8 bits, RGB/RGBA, sem entrelaçamento) e compara
  quadro a quadro. Reprova se a fração de pixels com delta de canal acima de
  `--canal` (padrão 6) passar de `--px` (0,001 = 0,1%); informa quadro, %,
  maior delta e caixa `x0,y0,x1,y1`. `--atualizar` grava o baseline de
  propósito. Saída 0/1/2.
- **`testes/baseline/` (novo):** 60 quadros do CI #38 (commit `5846789`,
  `llvmpipe`), 720×1280 RGBA, ~9,6 MB, com `.gdignore` para o Godot não
  importar (sem `.import` e fora do APK, que já exclui `testes/*`).
- **CI:** passo "Diff dos quadros (baseline)" entre a geração e o upload; o
  upload continua `if: always()` e o job `apk` depende do `testes`.
- **Documentação:** `docs/ORACULO.md` ganhou a seção do diff; `docs/BUILD.md`
  (rito 2) manda rodar o diff e atualizar o baseline **no mesmo commit**.
- **Verificação:** suíte 149/0, parser 42/0, docs 29/0; diff contra o baseline
  60/60; bloco 200×200 +20 **reprova** (4,33%, caixa 100,100,299,299), 1 pixel
  +50 passa, quadro faltando reprova; import sem `.import` no baseline.
- **Resíduos:** baseline versionado cresce a cada lote que muda o visível;
  baseline preso ao `llvmpipe` do runner.

## v0.15.0 — afinidade e personalidade (2026-11-22)

- **Autorizado pelo operador:** seguir o **P4** (núcleo do jogo). **Nenhum
  código de `jogo/` mudou** — no aparelho a criatura continua obedecendo; a
  ligação é P7. Testes: **149, 0 falhas**; parser 42 scripts, 0 erro.
- **`sim/afinidade.gd` (novo):** lógica pura. `temperamento` (traços 0..1) +
  `humor` + `afinidade` decidem {obedece, hesita, reinterpreta, desobedece};
  o sorteio vem do `RandomNumberGenerator` semeado recebido por argumento;
  `registrar` ensina o vínculo; `probabilidades()` expõe a soma para ajuste.
  Em **Sincronia** com afinidade ≥ `sincronia_limiar` obedece na hora, sem
  sorteio; **Autonomia** puxa reinterpretar/desobedecer. Nenhum número de
  balanceamento no código.
- **`dados/afinidade.json` (novo):** traços iniciais (docilidade 0,55,
  teimosia 0,35, curiosidade 0,6), pesos por decisão/traço, pesos de
  afinidade e humor, ajuste de modo, limiar 0,7, atraso de hesitar 0,55 s,
  desvio de reinterpretar 26 px e ganhos — **pontos de partida**, ajustar no
  aparelho.
- **`testes/test_afinidade.gd` (novo, 12 testes):** mesma semente ⇒ mesma
  decisão; afinidade alta ≥ 90% obedece (medido 94,5% em Autonomia e 100% em
  Sincronia); baixa ≤ 20% e desobedece; obediência não cai quando o vínculo
  sobe; estado preso em [0,1]; Sincronia × Autonomia; atraso, desvio e `{}`
  por decisão.
- **Registro do P22 fechado:** as 9 linhas riscadas do `RESIDUOS.md`
  passaram a `resolvido em vX.Y.Z` (v0.7.1, v0.8.0 e v0.9.0); o P22 saiu da
  fila e entrou em `PEDIDOS-FEITOS.md`. O **P4 também saiu da fila** para o
  registro; o **P5** passa a ser o próximo natural do núcleo — **nada
  autorizado** até o operador escolher.
- **Verificação:** `tools/testes.sh` — guardião documental, 149 testes e
  parser 42/0. Sem mudança visível: `tools/quadros.sh` não se aplica.
- **Resíduos:** a afinidade ainda não está ligada ao `jogo/` (P7); pesos,
  limiar e ganhos são pontos de partida.

## v0.14.4 — fila enxuta e resíduos com estado (2026-11-22)

- **Autorizado pelo operador:** separar a fila do registro dos pacotes feitos e
  dar **estado** aos resíduos. **Nenhum código de jogo, dado, teste ou CI
  mudou** — os 137 testes e o parser 40/0 seguem verdes.
- **`docs/PEDIDOS-FEITOS.md` (novo):** recebe as seções `## P1` a `## P21` sem
  reescrever o texto; é registro lido por `grep` ou pela âncora do título, não
  fila — nada ali está autorizado.
- **`docs/PEDIDOS-EM-ESPERA.md`:** índice só com os pendentes — **P4**
  (próximo do núcleo), **P5** (depois do P4), **P6/P7/P8** e **P22/P23**
  (manutenção); as seções P4–P8 foram movidas como estavam e nenhuma seção de
  pacote feito ficou no arquivo.
- **`docs/RESIDUOS.md`:** coluna **`estado`** (`aberto` ou `resolvido em
  vX.Y.Z`); saíram as duas linhas já resolvidas da v0.14.1 — a falta de
  `tools/docs.sh` no CI (resolvida na v0.14.2) e a fila misturando índice e
  detalhe (resolvida por este lote).
- **`AGENTS.md`:** `PEDIDOS-FEITOS.md` entra no mapa documental, uma vez.
- **Verificação:** `tools/docs.sh` sem erro e `tools/testes.sh` completo —
  lote só de documentação.
- **Resíduo novo:** o protocolo padrão ainda não foi replicado no repositório
  do Áudio Visual IASD.

## v0.14.3 — protocolo de agentes, multi-sessão e fila registrada (2026-11-22)

- **Autorizado pelo operador:** registrar a fila de manutenção e criar o
  protocolo padrão de trabalho por agentes. **Nenhum código de jogo, dado,
  teste ou CI mudou** — os 137 testes e o parser 40/0 seguem verdes.
- **`docs/PROTOCOLO-AGENTES.md` (novo):** toda sessão age como **GERENTE** que
  entende o problema, fatia em **briefings autocontidos** de contexto fresco e
  confere **evidência** (hash/commit, saída de teste, CI) em vez de relato.
  Cobre o que é do gerente e o que é do trabalhador, quando **não** delegar,
  paralelismo (leitura sim; escrita não — um escritor por repositório),
  orçamento de contexto, handoff e falha; o relatório ao operador continua em
  linguagem de leigo.
- **`docs/MULTI-AGENTE.md` (novo):** duas sessões no mesmo clone.
  `git add <caminho>` nunca `-A`; proibidos `checkout`/`reset`/`stash`; quem
  editou commita; não commitar arquivo alheio; `git status` antes do `push` com
  aviso; um lote por vez; `git -c safe.directory='*'`; tabela dos clones da
  máquina (Galápago e Áudio Visual IASD).
- **`docs/PEDIDOS-EM-ESPERA.md`:** nota no topo (manutenção A/B feitas; núcleo
  em P4/P5; nada autorizado); **P21 feito**, e **P22** (fila enxuta e resíduos
  com `estado`) e **P23** (oráculo com baseline e diff tolerante) **na fila**,
  no formato do P20.
- **`AGENTS.md`:** bullet nas "Regras de desenvolvimento" apontando os dois
  guias e ambos entrando no **mapa documental** (validado por `tools/docs.sh`).
- **Verificação:** `tools/docs.sh` sem erro e `tools/testes.sh` completo —
  lote só de documentação.

## v0.14.2 — guardião documental offline, antes dos testes (2026-11-22)

- **Pacote B autorizado pelo operador:** `tools/docs.sh` chama o verificador
  Node (`tools/docs.mjs`) e seus testes de regressão (`tools/docs.test.mjs`).
  Não usa rede, cofre, Godot nem dependências npm; não altera o clone.
- **Integração:** `tools/testes.sh` reprova documentação antes de importar o
  Godot. O CI já o executa e o APK depende desse job; não foi mudado o rito de
  publicar um APK por lote.
- **Verificações:** links inline locais e âncoras Markdown; cabeçalho, formato
  e ordem das versões do histórico; resíduos da versão atual; correspondência
  índice/seções de pacotes; mapa documental completo e sem duplicatas no
  AGENTS; ponteiro CLAUDE; revisão do GDD; toques simples/duplo no CONCEITO e
  no GDD confrontados com a tabela real `dados/gestos.json`.
- **Inventário:** o desenho livre da árvore não é interpretado como esquema;
  o AGENTS agora tem um mapa com links explícitos, validado pelo guardião.
  `docs/DOCUMENTACAO.md` registra formatos suportados e limites; só os dois
  toques têm comparação de significado, não toda a prosa de design.
- **Dívida encontrada pelo próprio guardião:** os títulos antigos v0.4.0 e
  v0.3.1 repetiam `## vX.Y.Z` na mesma linha. Corrigida só a formatação;
  decisões históricas e regras do jogo não mudaram.

## v0.14.1 — documentação alinhada ao jogo (2026-11-22)

- **Pacote A da faxina documental** (escolhido pelo operador em 2026-11-22):
  nenhuma mudança de código — os 137 testes seguem verdes.
- **CONCEITO (o norte lido primeiro):** o resumo de gestos dizia o INVERSO do
  jogo ("toque duplo = tiro, simples = pulo"). Corrigido para o real —
  **toque simples = TIRO, toque duplo = PULO** — com a regra de precedência:
  se o resumo divergir do GDD, o GDD vence.
- **`# Histórico` foi para o topo:** as entradas novas passam a nascer ABAIXO
  do título (antes o título ficava depois da entrada mais nova, na linha 54).
- **AGENTS.md, "Estrutura":** a lista de `docs/` repetia GODOT/BUILD/AMBIENTE
  e omitia `gdd/gestos-e-acoes.md`; agora bate com a árvore. `CLAUDE.md` entra
  como ponteiro para o `AGENTS.md` (Claude Code não lê `AGENTS.md`).
- **PEDIDOS-EM-ESPERA:** P9, P10 e P11 apareciam no índice sem seção
  detalhada; as três foram escritas a partir deste histórico.
- **GDD:** o marcador dizia v0.13.0 com a seção da v0.14 já dentro; agora
  v0.14.

## v0.14.0 — inimigo hostil: botão, caçada e quatro ataques com preparação (2026-11-21)

- **Pedido do operador (2026-11-21):** "Elabore a dinâmica do inimigo, com um
  botão para ligar a hostilidade. Ele vai ficar mais dinâmico em questão de
  movimentos, mais rápido. Deve ter um ataque próximo, um de esbarrão, um de
  longa distância e um efeito especial, como se defender ou se esconder.
  Vamos usar o sistema de preparação de ataque e área de efeito demarcada no
  chão."
- **Decisões do operador:** o golpe **não tira vida** (empurrão + atordoamento
  curto, como já era o combate físico); o especial é **ESCONDER**; a
  hostilidade fica **ligada até o botão desligar**.
- **O BOTÃO:** `HOSTILIDADE: LIGADA/DESLIGADA` na HUD, abaixo do PULO AUTO. O
  estado é do main (vale para todos os adversários) e a regra é da `sim/`; o
  toque no botão é consumido pelo Control e **não vira caminho**.
- **A CAÇADA (`sim/adversario.gd`):** com a hostilidade ligada ele persegue a
  **104 px/s** (o passeio era 26), aproxima em zigue-zague, **orbita** em
  volta do jogador (`ronda_px` 88) e abre espaço quando encosta. Mesma
  semente = mesma caçada; ele **não entra na água** (o mundo corta o passo).
- **A PREPARAÇÃO:** cada ataque tem `fases` = [preparo, ativo, recuperação],
  o mesmo formato de `dados/acoes.json`. Durante o preparo ele **para**, a
  área acende no chão, o miolo enche e a borda **pisca** perto do fim. Levar
  um golpe seu **cancela** o ataque em preparo.
- **AS QUATRO AÇÕES:**
  - **bote** (até 78 px): círculo de raio 30 no chão, no lugar onde o jogador
    estava; acerta quem fica dentro, empurra 70 px e atordoa 0,45 s;
  - **esbarrão** (80–240 px): faixa de 34 px de largura; ele corre a 380 px/s
    pela faixa e empurra 96 px / atordoa 0,65 s;
  - **cuspe** (150–460 px): linha fina; o projétil anda a 280 px/s, alcance
    340, empurra 40 px / atordoa 0,30 s;
  - **esconder** (especial): ao levar um golpe, afunda (0,35 s), fica
    **intocável** por 2 s e reaparece a ~110 px do jogador; recarga 7 s.
- **O CONTRA-GOLPE:** `sim/corpo.gd: levar_golpe` empurra (420 px/s), atordoa e
  abre **0,8 s de invencibilidade**; atordoada, a criatura **não obedece**
  (a rota fica guardada) e treme na tela. No subsolo o golpe não pega.
- **A DEMARCAÇÃO:** `jogo/perigos.gd` desenha as três formas (círculo, faixa,
  linha) e o projétil do cuspe; `jogo/adversario_mock.gd` põe aura/olhos
  vermelhos no hostil, "!" no preparo e **montinho de terra com bolhas** quando
  ele se esconde. Escondido, ele sai de `sim/alvos.gd` (não pode ser marcado
  nem atingido).
- **`dados/adversario.json`:** movimento (26/104/82), as quatro ações e a
  recarga do esconder — números de partida, ajustáveis no aparelho.
  `dados/acoes.json`: `reacao` (invencibilidade 0,8 s e 420 px/s do empurrão).
- **Testes novos (12, `testes/test_hostil.gd`):** perseguição mais rápida que o
  passeio; determinismo da caçada; não entra na água; bote acerta/erra; faixa
  do esbarrão acerta/erra; linha do cuspe acerta/erra; o esconder e a
  intocabilidade; desligar a hostilidade revela; o golpe real empurra,
  atordoa, recusa comando e respeita a invencibilidade/subsolo. **137 testes,
  0 falhas.**
- **Oráculo:** `DEMO_ARGS="--hostil" tools/quadros.sh 240` grava a cena de
  propósito (começa com a criatura perto do bicho, liga o botão, mostra os
  ataques e um golpe ROTEIRIZADO no fim para o estado ESCONDIDO aparecer nos
  quadros). O demo normal (60 quadros do CI) continua o mesmo.

## v0.13.0 — pulo automático com botão e pulo mais longo no sprint (2026-11-21)

- **Pedido do operador (2026-11-21):** "Faça uma opção para ativar e desativar
  um sistema de pulo automático, que pula quando houver um obstáculo de um
  nível de altura, e o caminho prosseguir sem o obstáculo do outro lado.
  Também aproveite para aumentar a distância dos pulos em velocidade aumentada
  ativa."
- **A OPÇÃO:** botão **PULO AUTO: LIGADO/DESLIGADO** no canto superior
  esquerdo da HUD (o toque nele é consumido pelo Control e **não vira
  caminho**). O estado é do corpo (`sim/corpo.gd: pulo_auto`) e o padrão vem de
  `pular.auto_padrao` (**falso**): o jogo continua como antes até o jogador
  ligar. Não há persistência entre partidas — cada abertura começa no padrão.
- **A REGRA (sim/corpo.gd, `_tentar_pulo_auto`):** quando a rota para na
  beirada e o desenho continua, o corpo pula sozinho pelo **mesmo
  `_iniciar_pulo` do toque duplo** (respeita a recarga; eventos `pulo:on` +
  `pulo:auto`). Dispara em dois formatos:
  1. a célula bloqueada já é um **degrau andável de 1 nível** (passarela/
     planalto);
  2. há um **vão de água curto** antes do degrau, com o pouso 1 nível acima
     **dentro do alcance** do pulo.
  **Não** dispara para água no mesmo nível, rocha/objeto, degrau de 2+ níveis,
  caminho que **acaba** na beirada, ou pouso longe demais (o alcance é medido
  com os fatores de sprint do momento ×0,9 — não pula para cair na água).
- **PULO MAIS LONGE NO SPRINT:** no ar, com o sprint (ou a cauda) ativo, o
  avanço horizontal ganha `pular.sprint_fator` (**1,5**) — o fator vale **só no
  ar**; a caminhada acelerada não mudou. Medido em teste (rota reta, cauda do
  sprint): **46,9 px** no pulo normal e **66,8 → 98,2 px** no acelerado, de
  ~2,1 para ~3,1 células. Com isso o vão de 2 células do parkour passa com
  sprint (antes era apertado) e o automático cruza esse mesmo vão quando o
  sprint está ativo.
- **`dados/acoes.json`:** `pular.auto_padrao: false` e `pular.sprint_fator:
  1.5` (idem na nota `_leia`, v0.13).
- **Testes novos (11, `testes/test_corpo.gd`):** padrão desligado + dado que
  liga; sobe o degrau de 1 e segue; desligado para no degrau; **não** pula 2
  níveis; **não** pula se o caminho acaba; cruza o vão curto e sobe; **não**
  pula vão de água no mesmo nível; **não** pula vão de 2 células sem sprint;
  **cruza** o mesmo vão com sprint; o fator alonga o pulo no sprint; o fator
  **não** muda o pulo normal. Suíte: **125 testes, 0 falhas**.
- **Oráculo:** quadros com o botão no canto superior esquerdo (desligado);
  a travessia automática foi conferida por simulação no `fundacao.json`
  (dispara no pátio, célula 43, e sobe a passarela).
- **O que NÃO mudou:** o toque duplo continua sendo o pulo manual (o automático
  só antecipa o degrau de 1 nível para cima); descer degrau, atravessar água no
  mesmo nível e vencer 2 níveis seguem no toque duplo.

## v0.12.0 — a extensão de parkour a leste (2026-11-21)

- **Pedido do operador (2026-11-21):** "Crie mais uma extensão para o mapa do
  projeto Galápago, focado em parkour, com desníveis, plataformas e trilhas
  para testar a movimentação."
- **O que é:** o `dados/mapas/fundacao.json` cresceu de **40 para 64 colunas**
  (24 a leste). O mapa antigo **não mudou** — a extensão é uma área nova,
  ligada à ilha leste por uma trilha de 2 células em `x = 38..39, y = 11..12`
  (antes era água). Não há código novo de movimento: a área só combina
  alturas e vãos com as regras de `sim/mundo.gd`.
- **Peças novas em `dados/terrenos.json`:** `p` **trilha** (altura 1), `b`
  **passarela** (2), `r` **rampa alta** (2,5 — liga 2 e 3 andando, como a `/`
  faz com 1 e 2) e `q` **plataforma** (3). Cores de mockup; a arte de verdade
  (P6) ainda não existe.
- **O percurso (ver `docs/gdd/mapa.md`):** pátio de trilha → vão de 1 célula →
  passarela (pulo de 1 nível, com rampa `/` ao lado para ir andando) →
  passarela estreita de 1 célula → vão de 2 células (pulo emendado ou sprint)
  → plataforma de 3 → pescoço com rampa alta e degrau de 2 → rampa `/` e pátio
  final. A **volta** em `y = 16` desce em degraus 1→2→3→2→1 com vãos de 1
  célula e um de 2, fechando o laço no pátio inicial.
- **O que testa:** andar em xadrez/ladeira, pulo simples (1 célula), pulo
  emendado/sprint (2 células), subir e descer 1 nível (andar não vence; o pulo
  sim), rampas no lugar do pulo, e caminhar em plataforma com a câmera
  acompanhando.
- **Testes novos (3, `testes/test_mundo.gd`):**
  `test_extensao_parkour_e_valida_e_ligada`,
  `test_extensao_parkour_rampas_ligam_os_niveis` e
  `test_extensao_parkour_vaos_e_pulos` — validam a legenda, a largura 64, a
  ligação pela ilha leste, as alturas 1/2/2,5/3, as duas rampas e os vãos de
  1 e 2 células (o pulo sobe 1 nível, não 2). Suíte: **114 testes, 0 falhas**.
- **Oráculo:** a área foi aberta em PNG com o início temporário em (42,11),
  (50,11), (55,16) e (61,12) e depois o `inicio` foi restaurado — os quadros
  mostram a trilha, a passarela, a plataforma e a volta.
- **Para voltar atrás:** apagar as 24 colunas de cada linha (voltar a 40) e as
  quatro peças `p/b/r/q` da legenda; nada mais depende delas.

## v0.11.5 — o ataque em área do laço desligado (2026-11-21)

- **Pedido do operador (2026-11-21):** "Vamos desativar o ataque em área feito
  por desenho de círculo do caminho."
- **Como foi feito (interruptor, não remoção):** `dados/acoes.json` ganhou
  `formas.laco_ataque: false`. `sim/formas.gd` (`analisar`) devolve `[]` quando
  a chave é falsa **antes de reduzir o traço** — o laço deixa de custar o RDP
  e a busca de cruzamentos a cada ~5 pontos. Consequência: nenhuma marca
  `laco` nasce, então `_checar_marcas`/`_disparar` (ramo `laco`) ficam
  **parados**; o código da ONDA continua **inteiro** atrás do interruptor.
- **O que NÃO mudou:** desenhar um círculo continua sendo **caminho** — a rota
  é simplificada/andada como qualquer traço (o teste
  `test_laco_e_andado_sem_cortar_a_volta` continua valendo), e a batida de
  travessia, a marca do alvo e o resto seguem iguais.
- **Para voltar:** `"laco_ataque": true` em `dados/acoes.json` (precisa de
  build novo — os dados vão dentro do APK). Os números do laço
  (`laco_arco_min` 160, `laco_area_min` 2200, `laco_raio_min` 28,
  `laco_raio_max` 120, `laco_dedupe_px` 26), `formas.gatilho_raio_px` e o
  `combate.onda_*`/`area_gatilho_px` seguem nos dados, **sem uso** enquanto
  está desligado.
- **`jogo/hud.gd`:** saiu a linha "laço perto → ataque em área" da legenda.
- **Comentários de topo** ajustados em `sim/corpo.gd`, `sim/formas.gd`,
  `sim/gestos.gd`, `sim/comandos.gd`, `jogo/main.gd` e `jogo/demo.gd` (o
  roteiro do demo não mudou, para os quadros continuarem comparáveis).
- **Testes:** novo `test_laco_desenhado_nao_vira_mais_ataque_em_area`
  (test_corpo: desenha o laço, **zero** marca de área, **nenhuma** onda, rota
  andada até o fim) e `test_laco_desligado_nos_dados_e_na_leitura`
  (test_formas: o dado diz `false` e `analisar` responde `[]`; com `true` a
  marca volta). Os quatro testes antigos da onda continuam rodando com
  `_acoes_com_laco(true)` — provam que a máquina está inteira.

## v0.11.4 — a marca segue a ponta, pulo emendado e cauda do sprint (2026-11-21)

- **Pedido do operador (2026-11-21, logo depois da v0.11.3, quatro ajustes):**
  (1) se o caminho **passa** por cima (empurrão) e o **destino final fica longe**
  do alvo, **não voltar** para dar o ataque de perseguição; (2) **afastar um
  pouco a câmera**, para ver mais do mapa e do campo total; (3) **delay do
  pulo**: pode perceber o pulo ainda durante o primeiro, mas só executá-lo
  quando a animação anterior terminar (hoje há muito atraso entre dois pulos
  seguidos); (4) no modo acelerado, **manter o embalo por um tempo depois de
  soltar** o segurar, para poder pular ainda acelerado e ir mais longe.
- **`sim/corpo.gd` — a MARCA acompanha a PONTA (1):** `_soltar_marca_longe_da_ponta`
  roda todo quadro de traço e **apaga** `mira_final_id` quando a ponta da rota
  se afasta mais de `combate.mira_final_raio` (34 px) do alvo marcado (evento
  `mira_final:` — vazio; `jogo/main.gd` mostra "marca solta"). A marca nasce
  só quando a ponta está no alvo, então **passar por cima e seguir longe não
  deixa marca** e o fim do caminho não persegue de volta. A **batida/empurrão
  da travessia continua** igual (`_marcas_de_travessia`). Depois de **soltar**
  o dedo a marca não é mais validada: ela viaja com o alvo, como antes (é o que
  permite perseguir um alvo que anda).
- **`jogo/mock.gd` — câmera mais distante (2):** `ZOOM` 2,0 → **1,6**. A tela
  passa a mostrar 450×800 px de arte (era 360×640): os **24 andares do mapa
  inteiros na vertical** (1280/1,6 = 800 < 832 dos limites da câmera — não
  aparece chão fora do mapa) e ~35% da largura. `jogo/demo.gd` lê
  `main.camera.zoom.x`, então demo e oráculo acompanham sozinhos. **Custo:**
  zoom fracionário (1 px de arte = 1–2 px de tela); no xadrez do mock não se
  nota — vira decisão de arte no P6 (ver RESIDUOS).
- **`sim/corpo.gd` — PULO NA FILA (3):** `_cmd_pular` no ar não recusa mais:
  guarda **um** pedido em `_pulo_fila_t` (`pular.buffer_s` 0,60 s) e devolve
  `ok: pulo na fila` (evento `pulo:fila`). `_atualizar_pulo` decrementa a fila
  e, no quadro em que o pulo anterior pousa (`pulo:off`), chama `_iniciar_pulo`
  — o mesmo `_iniciar_pulo` extraído do comando, com `pulo:on` no mesmo quadro.
  O **cooldown de pouso** caiu de `pular.recarga` **0,30 → 0,08 s**: ele também
  engolia o 2º pulo de quem toca de novo logo depois do pouso.
- **`sim/corpo.gd` — CAUDA do sprint (4):** `soltar_segurar` (e o fim da
  energia) marcam `_sprint_cauda_t = sprint.cauda_s` (0,60 s); `_fator_sprint`
  devolve o fator cheio (`sprint.fator` 1,7) enquanto segura e, na cauda,
  **1,7× → 1,0× em queda linear**. `_avancar_rota` e `_terminar_rota` (inércia
  e `freio_sprint_x`) usam o helper — antes olhavam `_sprint` direto e cortavam
  a velocidade no soltar. A **energia só é gasta segurando**; a cauda não gasta
  e a recarga continua. Saltar durante a cauda anda mais longe (o pulo é um
  overlay: a altura não muda, o **avanço horizontal** é que cresce).
- **`dados/acoes.json`:** `pular.recarga` 0,08, `pular.buffer_s` 0,60,
  `sprint.cauda_s` 0,60; `_leia` em v0.11.4 (idem em `dados/gestos.json`).
- **Testes novos (4):** `test_passar_por_cima_e_seguir_longe_nao_volta_para_bater`
  (marca sai, batida acontece, nenhum `golpe_final`), `test_pulo_pedido_no_ar_sai_ao_terminar_o_primeiro`
  (2º `pulo:on` sem comando novo), `test_cauda_do_sprint_mantem_o_embalo_depois_de_soltar`
  (>140 px/s logo após soltar, <125 px/s depois da cauda) e
  `test_pulo_com_cauda_do_sprint_vai_mais_longe` (>1,2× o pulo normal).

## v0.11.3 — contorno de encostas, direção estável e linha que apaga (2026-11-21)

- **Pedido do operador:** (1) o contorno de "não parada" não estava valendo
  para **desníveis**: o animal esbarra nas encostas e fica preso — aplicar a
  correção de rios/pedras a **encostas e barreiras no geral**; (2) o desvio de
  obstáculos funciona, mas está **muito reativo**: a direção pisca/treme
  enquanto ele dá pequenos passos — deixar caminho e direção mais **estáveis e
  fluídos**; (3) a **linha do caminho apagar** o trecho que o animal já passou.
- **`sim/corpo.gd` — barreira de ALTURA:** a varredura do contorno deixou de
  olhar `mundo.bloqueio(...) == "terreno"` e passou a testar
  `mundo.caminho_livre(p_antes, p_t)` entre as amostras de 4 px da rota —
  assim **água, rocha, degrau > 0,5 e canto diagonal** contam como barreira. A
  **continuação** precisa ser uma célula andável com **nível alcançável**
  (`altura(c) <= altura(base) + 0,5`, ou qualquer nível no subsolo); o **topo
  do barranco** (mais alto) não é continuação — é a volta por baixo/rampa que
  conta. O resto é o mesmo contorno do tronco/água (`contorno_*`,
  `desvio_teimoso_*`).
- **`sim/corpo.gd` — direção estável:** `_dir_suave` (direção de andar) e
  `_olhar_suave` (direção desenhada) passam por `_suavizar_direcao`
  (mistura exponencial `giro_suavidade` 10/s + teto `giro_max_graus_s`
  720°/s). O leque de desvio guarda o **ângulo** do quadro anterior
  (`_desvio_angulo`) e o tenta primeiro, então o contorno vira uma linha
  estável em vez de reescolher a cada quadro. O passo real não muda: a
  checagem de colisão continua no `_passo_com_desvio`.
- **`dados/acoes.json`:** `giro_suavidade` 10, `giro_max_graus_s` 720;
  `_leia` em v0.11.3.
- **Testes:** `test_rota_contorna_desnivel_quando_ha_continuacao` (rota por
  cima de um planalto, contorna pelas laterais, 0 quadros no nível alto, chega
  ao fim) e `test_direcao_estavel_ao_contornar` (giro por quadro ≤ 720°/30 +
  0,5°). Água, rocha, dip, laço, bico e inércia continuam verdes.
- **`sim/corpo.gd` / `jogo/trilha.gd` — a LINHA apaga o que já passou:**
  `traco_t` é o arco ANDADO do traço cru, atualizado por projeção com
  continuidade (nunca volta, teto de avanço por quadro) e resetado num caminho
  novo. `trilha.mostrar(pontos, corte)` desenha do corte para a frente, com
  fade de `APAGAR_PX` 22 px atrás; o pontinho do destino só aparece se ainda
  falta caminho.
- **Testes (105, 0 falhas; parser 38 scripts):** inclui
  `test_traco_vai_apagando_o_trecho_andado` (o corte avança, nunca volta e fica
  dentro do traço), além de `test_rota_contorna_desnivel_quando_ha_continuacao`
  e `test_direcao_estavel_ao_contornar`.
- **Sonda headless:** tronco/água/desnível com giro máximo por quadro de
  **24,0°** na direção desenhada; o passo real tem 1–2 viradas de ~80–100° no
  INÍCIO do contorno (uma vez), depois segue estável — não pisca a cada
  quadro.
- **Verificação visual:** oráculo de quadros (**45 quadros** 720×1280, PNG
  abertos): a linha aparece só **à frente** da criatura — o trecho andado já
  está apagado (fade de 22 px) — e o caminho à frente segue pontilhado; HUD e
  cena sem quebra.

## v0.11.2 — água e rocha contornadas quando a rota volta à terra (2026-11-21)

- **Pedido do operador:** aplicar o **mesmo desvio dos troncos** a **pedras e
  rios**. Se a linha entra 100 px na água e **logo continua na terra**, o
  destino não é a água: contornar e seguir. Se a rota **termina** no bloqueio
  (ou não há continuação próxima), **não tentar cruzar** — para na fronteira, e
  só o **pulo** atravessa (a menos que bata na fronteira do mapa pulando).
  Priorizar o destino quando há **continuação do caminho num raio x** perto do
  animal.
- **`sim/corpo.gd` — `_alvo_visivel`:** procura um trecho de **TERRENO**
  (água/rocha) na **rota** (não na corda) até `olhar_px` + 24 px. Se achar e a
  rota **voltar a uma célula andável** em até `contorno_alcance_px` 260 de arco
  e `contorno_raio_px` 128 de distância do animal, mira a **continuação** e
  devolve `contorno: true`. Sem continuação, `contorno: false` e o alvo é o de
  sempre.
- **`sim/corpo.gd` — `_passo_com_desvio(..., permitir_terreno)`:** o caso
  "terreno" deixa de ser sempre parada: com `permitir_terreno`, entra no
  **mesmo leque de desvios do tronco** (candidatos conferidos com
  `limitar_segmento`, então **nunca entra na água/rocha**); sem ele, para.
  O compromisso/histerese do contorno continua.
- **`sim/corpo.gd` — teimosia limitada:** `_desvio_inicio_s` guarda o arco onde
  o contorno começou; depois de `desvio_teimoso_apos` 36 passos sem a rota
  andar `desvio_teimoso_px` 6 px, para na fronteira (antes podia ficar indo e
  voltando no muro). Um pulo ou caminho novo reinicia.
- **`dados/acoes.json`:** `contorno_alcance_px` 260, `contorno_raio_px` 128,
  `desvio_teimoso_apos` 36, `desvio_teimoso_px` 6; `_leia` em v0.11.2.
- **Testes (102, 0 falhas; parser 38 scripts, 0 erros):**
  `test_rota_atravessa_agua_contornando_quando_ha_continuacao` (o antigo
  `test_mover_respeita_o_mundo` virou este: a rota atravessa o lago e segue;
  confere que ela **nunca entra na água**, 0 quadros),
  `test_rota_que_termina_na_agua_para_na_fronteira`,
  `test_rota_contorna_rocha_quando_ha_continuacao` e
  `test_linha_que_entra_na_agua_e_sai_na_terra_e_contornada` (o vai-e-volta
  dentro do lago). Os testes de pulo em canal de 1 linha continuam valendo
  (não há volta; para e o pulo atravessa).
- **Verificação:** `tools/testes.sh` verde (102 testes, 0 falhas; parser 38
  scripts); **oráculo de quadros** com **45 quadros** 720×1280, os PNG abertos
  (a cena/demo não tem lago no roteiro, então o contorno é medido pela sonda
  headless/testes: posição, tempo e **0 invasão de água**).

## v0.11.1 — estrada que anda o laço, contorna a barreira e freia depois do fim (2026-11-21)

- **Pedido do operador:** (1) não travar perto de **pedra/beira de mar** quando
  a rota desenhada tem caminho; **tronco** não bloqueia se dá para contornar;
  (2) o **retorno/bico** travava na **ponta** e o **laço** era **cortado** (não
  fazia a volta) — o laço deve ser **andado**; (3) ignorar **amontoados** de
  movimentos numa zona do tamanho do animal (vai-e-volta, cruzamento) e
  **laços pequenos** que acendem a área por engano; (4) **sem freio antes do
  fim**: chegar na velocidade normal e frear **depois**, numa **mini inércia**,
  um pouco maior no **sprint manual**; (5) **tiro híbrido**: sem marca, na
  direção do **toque em relação ao animal**; com marca, automirado no alvo.
- **`sim/corpo.gd` — projeção:** `_projetar` custa
  `distância + projecao_peso × |arco − esperado|` e varre a rota inteira (a
  busca local de ±12 segmentos saiu). No cruzamento do laço (e no bico, cujos
  braços são a mesma linha) ela continua o braço andado em vez de pular para a
  volta; um teto de avanço por quadro fecha a porta do "teleporte".
- **`sim/corpo.gd` — alvo:** `_alvo_visivel` mira o ponto mais longe do traço
  (horizonte `olhar_px` 22, amostras de 2 px) que a linha reta **alcança
  andando** e que está **à frente** no sentido atual. A corda de uma curva não
  entra mais na pedra/água; no bico, o braço de volta fica atrás e é rejeitado
  até cruzar a ponta. O desvio orgânico lateral só é aplicado se o ponto
  desviado também for alcançável. O desvio de tronco mantém o lado e **cai para
  o outro** se o primeiro não passar (antes ficava presa).
- **`sim/corpo.gd` — fim:** saiu a **zona de freio** antes do fim
  (`freio_px`/`freio_min`); o corpo chega na velocidade normal e
  `_terminar_rota` inicia a **INÉRCIA** (`_inercia_*`): desaceleração linear na
  tangente do último trecho, `freio_extra_px` 16 px fora da rota (~0,3 s),
  ×`freio_sprint_x` 1,6 no sprint. Sem alvo marcado, claro: com alvo, continua
  a perseguição final.
- **`sim/trajetoria.gd`:** `limpar_amontoados(pontos, raio, janela, livre)` —
  corta o trecho que **retorna** para dentro de 24 px em até 100 px de arco
  (laço minúsculo, cruzamento de passagem, vai-e-volta nervoso); o critério é
  `arco ≥ d·1,8 + 12` (reta/curva não são tocadas) e o atalho precisa ser
  andável (`mundo.caminho_livre`, via Callable). Remove também o **ponto de
  entrada** do amontoado (senão sobrava um espinho).
- **`sim/formas.gd` / `dados/acoes.json`:** tamanho MÍNIMO do laço para a área
  — `laco_area_min` 2200 px² (era 700), `laco_arco_min` 160 (era 90),
  `laco_raio_min` 28 (era 24). Bloco `rota` novo: `amontoado_raio_px` 24,
  `amontoado_janela_px` 100, `alvo_pulo_objeto_px` 56, `projecao_peso` 0,25,
  `freio_extra_px` 16, `freio_sprint_x` 1,6; saem `freio_px` e `freio_min`.
- **`sim/corpo.gd` — TIRO HÍBRIDO (v0.11.1):** `_cmd_tiro(cmd, alvos)` não
  exige mais marca. **Com** `mira_final_id` continua a automira da v0.10 (o
  toque não muda a direção); **sem marca**, a direção é `cmd.alvo − pos` — o
  ponto do **toque na tela convertido para mundo** pelo `jogo/main.gd`; toque
  em cima dela usa o `olhar`. Se o alvo marcado sumir, a marca cai
  (`mira_final:perde`) e o tiro sai livre. Recarga/pausa iguais nos dois.
  `jogo/main.gd`/`jogo/hud.gd`: a nota vira "TIRO" e a legenda explica as duas
  formas.
- **Testes (99, 0 falhas; parser 38 scripts, 0 erros):** novos —
  `test_limpar_amontoados_*` (corta o laço pequeno, preserva o bico grande, não
  mexe em curva, respeita o caminho livre), `test_laco_pequeno_nao_acende_a_area`
  e `test_laco_de_tamanho_util_acende_a_area`, `test_laco_e_andado_sem_cortar_a_volta`,
  `test_bico_e_andado_ate_a_ponta_e_continua`,
  `test_beira_de_agua_nao_trava_quando_a_rota_contorna`,
  `test_amontoado_curto_e_cortado_da_rota`,
  `test_laco_pequeno_nao_acende_a_area` (no corpo),
  `test_inercia_depois_do_fim_do_caminho` (substitui o antigo teste de freio) e
  `test_inercia_do_sprint_e_um_pouco_maior`,
  `test_toque_sem_marca_atira_na_direcao_do_toque` e
  `test_toque_com_alvo_marcado_mira_no_alvo` (o teste antigo "sem marca não
  atira" foi substituído). Sonda headless da rota desenhada
  AO VIVO (laço e bico em passos de 8 px, tempo lento 0,35×): o laço passa por
  baixo e pela direita e termina em (112, 16), em 5,8 s; o bico chega a y > 150
  e termina em (297, 47), em 4,4 s; 0 quadros `barrado`; inércia 17,9 px
  (normal) × 28,8 px (sprint). TIRO: sem marca, toque abaixo → `dir` (0, 1);
  com marca, toque ao lado oposto → `dir` (0,71, 0,71) (mirou no alvo).
- **Verificação visual:** oráculo de quadros (`tools/quadros.sh`, **75
  quadros** 720×1280, ~103 s de render) — os PNG foram abertos: a HUD mostra a
  legenda nova ("toque → tiro (no alvo marcado ou na direção do toque)"), a
  linha pontilhada do laço aparece inteira e o evento `laco:onda` imprime; a
  criatura segue o traço sem salto para a volta. Detalhe em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md).

## v0.11.0 — bico andado, PULO no toque duplo, TIRO no toque simples e SPRINT com energia no segurar (2026-11-21)

- **Pedido do operador:** (1) **não ignorar mais o bico** (v0.10 ele era
  cortado da rota); (2) **inverter os toques**: PULO no toque duplo e TIRO no
  toque simples; (3) a **habilidade de escavar** só vale **sem um caminho** e
  deve ativar **no momento em que o tempo mínimo de segurar passa** (não no
  soltar); (4) o **tiro usa o toque simples**, mas **segurar durante uma
  caminhada sem mover o dedo** (com alvo marcado ou não) faz o animal dar um
  **SPRINT**, que **gasta uma barra de energia**.
- **`sim/formas.gd`:** o **BICO saiu** do leitor de formas — o traço é a rota
  inteira, do jeito que foi desenhado (o espinho é andado). A análise agora
  devolve só **laços**; `bicos`, os índices `i`/`j` do corte e os limiares do
  bico saíram.
- **`sim/corpo.gd`:** sem `_bicos`/`_sem_bicos` (nada é cortado). **SEGURAR**
  virou `_cmd_segurar`: **com um caminho em curso → SPRINT** (`sprint.fator`
  1,7×, gasta `gasto_s` 0,45/s da barra `energia`, para ao soltar ou ao zerar;
  recupera `recarga_s` 0,22/s); **sem caminho → habilidade (cavar)**, que agora
  é chamada no limiar. O sprint entra na velocidade de `_avancar_rota` e no
  `passo` (gasto/recuperação), com reset no fim/novo caminho.
- **`sim/gestos.gd`:** o **toque simples fica PENDENTE** até a janela do duplo
  fechar (o `tick` solta "toque" = TIRO); o **segundo toque** vira
  "toque_duplo" = PULO; o **SEGURAR ativa no limiar** (`tick` emite
  "segurar_inicio") e o soltar emite "segurar_fim" (não é mais no soltar que a
  habilidade nasce).
- **`sim/comandos.gd` / `dados/gestos.json`:** mapa novo — `toque` → `tiro`,
  `toque_duplo` → `pular`, `segurar` → `segurar` (o corpo decide sprint ×
  habilidade), `segurar_fim` → `soltar_segurar`.
- **Dados (`dados/acoes.json`):** bloco novo `sprint` (1,7× · 0,45/s · 0,22/s ·
  mínimo 0,08); saem as chaves `bico_*` de `formas`.
- **`jogo/hud.gd`:** a **barra de ENERGIA** embaixo, à esquerda (fica laranja
  com menos de 25%) e a legenda nova: toque = tiro, toque duplo = pulo,
  segurar no caminho = sprint, segurar parado = habilidade.
- **`jogo/demo.gd`:** o pulo usa o **toque duplo**, o tiro o **toque simples**
  (dois tiros, com a recarga de 1 s); a cavada continua nos `segurar` sem
  caminho; o caminho em "L" leva ao adversário e o golpe final fecha.
- **Verificação:** **86 testes, 0 falhas**, 38 scripts (parser limpo); novos:
  o segurar ativando no limiar, o sprint acelerando/gastando/recuperando a
  energia, o segurar sem caminho cavando, e o bico **andado** (na rota).
  Sonda headless da demo: `laco:onda`, `mira_final`, dois
  `tiro:disparo`+`acerto` e `golpe_final`. **Oráculo de quadros**
  (`tools/quadros.sh`, 45 quadros 720×1280 em ~3 min): HUD com a legenda nova
  (toque = tiro, toque duplo = pulo, segurar no caminho = sprint) e a **barra
  de energia** cheia embaixo, à esquerda — abri os PNG. Detalhe em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md).

## v0.10.0 — marca ligada ao caminho, TIRO no toque duplo, PULO no toque e perseguição final (2026-11-21)

- **Pedido do operador:** (1) **sem a desaceleração final** quando o caminho
  termina num alvo marcado e **melhorar a perseguição final** — o animal estava
  batendo sem ter ido atrás do alvo; (2) o **ataque em área** deve acender
  **antes de chegar no laço**: a trava é a **distância até o CENTRO** da área
  (começar com ~7× o tamanho do animal), sem esperar o animal entrar no anel;
  (3) mudar o **gatilho do tiro e o método de marcação**: a **marcação** é a
  mesma do golpe — **levar o fim do caminho até o alvo** (durante o caminho ele
  fica marcado) — e o **tiro é o TOQUE DUPLO**; o **pulo vira o TOQUE SIMPLES**
  (que antes marcava). O resumo do tiro: com o alvo marcado, os toques duplos
  disparam **mirados nele**, não interrompem o caminho, o animal **para** para
  atirar e segue; a **marca não sai no disparo**, sai no **golpe físico** —
  está **ligada ao caminho**.
- **`sim/gestos.gd`:** o **toque simples fica PENDENTE** até a janela do duplo
  fechar (`toque_duplo_janela_ms` 280 ms): sem um segundo toque, o `tick` solta
  o "toque" (PULO); com o segundo perto e logo, é "toque_duplo" (TIRO) e o
  simples é descartado. Sai o par `_ultimo_toque_*`.
- **`dados/gestos.json`:** `toque` → `pular`; `toque_duplo` → `tiro` (o toque
  não trava mais mira).
- **`sim/corpo.gd`:** a **marca** (`mira_final_id`) nasce **durante o caminho**
  (`_montar_marcas` chama `_marcar_alvo_no_fim` a cada atualização da rota);
  ela **anda com o inimigo**, vale para o tiro e para o golpe, e **sai** no
  golpe físico (ou num caminho novo). **`_cmd_tiro`** (toque duplo): exige
  marca e recarga (`tiro_recarga_s` 1 s), atira no alvo (`_atirar`), pausa
  (`tiro_pausa_s` 0,25 s) e segue a rota. **A área** acende pela **distância ao
  centro** (`area_gatilho_px` 224). **Sem zona de freio** quando há marca. No
  fim do caminho com marca: `_iniciar_final` — perto, bate; longe, **PERSEGUE**
  (`_perseguir`, teto `embalo.perseguir_s` 3 s, embalo curto) e bate **ao
  chegar** (`ataque.alcance` + raio + 10). Saem a tolerância de 48 px
  (`mira_final_tol_px`) e `mira_final_pos`; o **tiro do bico** sai (o bico só
  corta o beco da rota).
- **Dados:** `combate` ganha `area_gatilho_px` (224) e `tiro_pausa_s` (0,25);
  saem `mira_final_tol_px` e `bico_pausa_s`; `embalo` ganha `perseguir_s`
  (3,0 s). `formas.lacos` não guarda mais o `anel` (o gatilho é a distância ao
  centro); `distancia_polilinha` sai.
- **`jogo/`:** `hud.gd` com a legenda nova (toque = pular, toque duplo = tiro,
  fim do caminho no alvo = marca) e "ALVO MARCADO"; `main._evento` nota
  "TIRO no alvo marcado"; `demo.gd` reescrito: laço perto (área), cavar, toque
  (pulo), caminho em "L" até o adversário (travessia + marca), **dois toques
  duplos (tiros)** e o **golpe final** na perseguição.
- **Verificação:** **90 testes, 0 falhas**, 38 scripts (parser limpo); novos:
  o toque pendente/duplo, o tiro no alvo marcado (mira, recarga, pausa, marca
  mantida), a marca nascendo durante o caminho, a perseguição final, a área
  pela distância e o bico sem tiro. Sonda headless da demo: `laco:onda`,
  `mira_final`, dois `tiro:disparo`+`acerto`, `batida`, `golpe_final`.
  **Oráculo de quadros** (`tools/quadros.sh`, 45 quadros 720×1280 em ~3 min,
  ~4 s/quadro — a linha pontilhada pesa no `softpipe`): HUD com a legenda nova
  (toque = pular, toque duplo = tiro, fim do caminho = marca) e a linha
  pontilhada escura seguindo o traço — abri os PNG. Detalhe em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md).

## v0.9.2 — a linha do caminho vira traço real pontilhado; cooldown dos especiais e EMBALO dos golpes (2026-11-21)

- **Pedido do operador (ajustes):** (1) a linha do caminho estava **quebrada**
  (retas entre os pontos da rota simplificada): desenhá-la **contínua**, como o
  desenho real do dedo, com mais pontos — e **pontilhada**, **mais escura e
  transparente**, na posição; (2) **cooldown de 1 s** para reusar os ataques
  especiais (área do laço e tiro do bico); (3) os golpes físicos devem
  **acelerar o movimento**: curto na **marcação** (golpe final) e mais longo no
  **empurrão** (embala antes, passa mais rápido que a caminhada pelo alvo e
  desacelera depois).
- **`jogo/trilha.gd` (reescrito):** a linha agora recebe `corpo.traco` (o traço
  CRU do dedo, denso) e desenha **pontos a cada 9 px de arco** — a curva de
  verdade, sem emendar retas. Estilo: `PASSO_PX` 9 · raio 2,1 · cor
  `#0a171f` a 55% (escura e transparente) · no chão (`z_index` 1) · pontinho
  maior no destino. `jogo/main.gd` mostra o traço enquanto desenha/anda na
  rota, e apaga ao terminar.
- **`sim/corpo.gd` — COOLDOWN (1 s):** os especiais usam `_recargas` ("onda" e
  "tiro"): ao disparar, `onda_recarga_s`/`tiro_recarga_s` (1,0 s) entram; a
  marca do especial **não é consumida** durante a recarga — fica **pendente** e
  acende quando ela termina (se a criatura ainda estiver no anel/perto da base).
- **`sim/corpo.gd` — EMBALO:** `_iniciar_embalo(duração, fator)` + `_fator_embalo()`
  (pico `sin(π·u)`), aplicado à velocidade do passo da rota. O **empurrão**
  (batida de travessia) chama o **longo** (0,6 s · 2,0×) — passa rápido pelo
  alvo e desacelera; a **marcação** (alvo final) chama o **curto** (0,25 s ·
  1,7×) uma vez, quando a criatura chega a `gatilho_px` (70 px) do alvo. A
  recarga do embalo final é armada de novo a cada nova marca/rota.
- **Dados:** `combate` ganha `onda_recarga_s` e `tiro_recarga_s` (1,0 s);
  bloco novo `embalo` (0,25 s/1,7× · 0,6 s/2,0× · 70 px).
- **Verificação:** **91 testes, 0 falhas**, 38 scripts (parser limpo); três
  novos: a recarga de 1 s (marca pendente), o empurrão embalando (passa > 135
  px/s) e a marcação com embalo CURTO (≤ 0,3 s). **Oráculo de quadros**
  (`tools/quadros.sh`, parcial: 33 quadros em ~2,5 min — ~4,5 s/quadro neste
  celular com a linha pontilhada; abri o quadro 30): a linha aparece
  **PONTILHADA, escura e translúcida**, acompanhando o traço do dedo (sem as
  retas entre pontos de referência da versão anterior). Detalhe em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md).

## v0.9.1 — o laço acende no anel, o bico em "T" não é andado e o caminho vira ESTRADA (2026-11-21)

- **Pedido do operador (ajustes):** (1) o efeito do laço deve acender quando a
  criatura estiver em **qualquer parte da circunferência** do laço, desde o nó —
  se ela já estiver andando no laço quando ele fecha, a habilidade já está
  ativa; (2) o **bico** só era lido a partir do parado: reconhecer o espinho no
  **meio do caminho** (formatos de "T") e **não andar o beco** — a criatura para
  antes de entrar e dispara na direção apontada; (3) o caminho é uma **ESTRADA
  mais larga**: o animal pode ir mais à esquerda, à direita ou no centro (os
  pontos eram a referência, não a obrigação de pisar na linha), o percurso fica
  **menos retilíneo e mais orgânico**, e o fim ganha uma **zona de freio** para
  parar suave.
- **`sim/formas.gd`:** o laço guarda o **anel** (a circunferência fechada) na
  marca. O **bico foi reescrito**: a PONTA é uma reversão (~180°) e a BASE é
  onde a volta **reencontra a estrada** — a primeira curva forte
  (`bico_base_angulo` 45°) depois da ponta, ou o fim do traço, sempre perto do
  traço anterior (`bico_base_px` 14, `bico_fim_px` 40 no fim). A marca leva
  `i`/`j` (índices no traço cru) do trecho a cortar. `distancia_polilinha`
  mede a distância ao anel. Isso pega o **"T" perpendicular**, o "V" e o bico
  deitado na própria linha.
- **`sim/corpo.gd`:** o gatilho do laço agora é a **distância ao anel**
  (qualquer parte), sem a checagem de direção: laço fechado com a criatura em
  cima = onda na hora. `_bicos`/`_sem_bicos` **cortam o beco da rota** (o trecho
  `i+1..j`) e o bico só arma a marca na base; ao acender, a criatura **PAUSA**
  (`bico_pausa_s` 0,25 s) e o tiro sai da base na direção da ponta.
  A rota virou **follow-the-road**: `_projetar` (busca local na rota),
  `_ponto_em_rota`/`_tangente_em_rota`, alvo **à frente** (`olhar_px` 22) +
  **desvio lateral orgânico** (duas senoides de fases sorteadas, amplitude
  `estrada_desvio_px` 9, dentro de `estrada_largura_px` 30) e **zona de freio**
  (`freio_px` 44, `freio_min` 0,12, smoothstep) — a criatura para onde está
  (`parada_px` 4), sem salto para o último ponto. No desvio de tronco, o alvo
  à frente **pula** o ponto dentro do objeto e o **lado** escolhido é mantido
  até passar (sem oscilar na beirada). O **alvo final** também é marcado quando
  a rota acaba **durante** o desenho (traço ao vivo); o comando `ataque` usa a
  **tangente** da estrada (o `_rota_i` agora é o segmento atual).
- **Dados (`dados/acoes.json`):** `formas` ganha `bico_base_px`, `bico_fim_px`,
  `bico_base_angulo` (sai `bico_volta_px`); `combate` ganha `bico_pausa_s`;
  `rota` ganha `olhar_px`, `estrada_largura_px`, `estrada_desvio_px`,
  `estrada_onda_px`, `estrada_onda2_px`, `freio_px`, `freio_min`, `parada_px`.
- **`jogo/`:** `demo.gd` troca o bico por um **"T" no meio do caminho**;
  `main._evento` mostra no log `mira_final:perde`.
- **Verificação:** **88 testes, 0 falhas**, 38 scripts (parser limpo); seis
  novos: laço acende no anel, T no meio não é andado (e a criatura para),
  estrada orgânica dentro da largura, freio no fim, T e anel em `test_formas`.
  **Oráculo de quadros** (`tools/quadros.sh`, 180 quadros 720×1280 em ~5 min,
  ~1,7 s/quadro): o laço acende cedo (nota "LAÇO: onda em área" antes de
  4,4 s, com a criatura no anel), o **"T" é desenhado e o beco sai do traço**
  (a linha segue reta), a criatura **para na base e dispara para cima** (nota
  "BICO: tiro disparado") e o corpo anda **DENTRO da faixa**, fora da linha
  branca — abri os PNG. Detalhe em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md).

## v0.9.0 — o ataque nasce do DESENHO: laço, bico, travessia e alvo final (2026-11-21)

- **Pedido do operador:** ajustar o sistema de gestos e ações — (1) **laço** no
  caminho = **ataque em área** com centro no centro estimado do laço, ativado
  no **nó** (onde o laço fecha na primeira linha) quando o animal passa por
  ele, sem depender de ir ao centro; (2) **bico** (ida e volta brusca) = **tiro**
  na direção do bico, saindo do ponto do caminho **antes** dele (um bico a
  partir da posição inicial dispara sem se mover); (3) **segurar parado** =
  **habilidade em si mesmo** com duração; (4) dois toques pulam sem
  interromper o caminho; (5) **cruzar a linha sobre** um alvo = **batida/
  empurrão**; (6) **terminar o caminho em cima** do adversário = **golpe
  físico**, com a marca **no inimigo** (se ele andar demais, a automira se
  perde); (7) **esquiva é o próprio caminhar** + tempo lento, sem efeito.
- **Decisões do operador na mesma conversa:** **nenhum gesto de dois dedos**
  (saem ataque ↑, defesa ↓ e especial abrindo); o efeito do golpe no
  adversário é **empurrão + piscada, sem vida**; a habilidade de teste do
  segurar é **cavar** (não a cor piscando), valendo **em qualquer lugar** da
  tela, não só em cima do animal.
- **`sim/formas.gd` (novo, puro):** lê o traço CRU e devolve MARCAS.
  **Laço:** cruzamento entre segmentos (`cruzamento`), área/centroide por
  shoelace, raio `√(área/π)` limitado, direção do fechamento; lido no traço
  reduzido (RDP 3 px). **Bico:** REVERSÕES (~180° numa janela de 10 px de
  arco) — a ponta e a base (onde a volta reencontra o caminho); volta
  estreita, altura ≥ 18 px; lido no traço **amostrado a cada 6 px** (uma ida e
  volta na MESMA reta tem desvio zero e o RDP comeria a ponta).
- **`sim/trajetoria.gd`:** a distância do Douglas-Peucker agora é ao
  **SEGMENTO** (não à reta infinita): a **ponta do bico** que passa além da
  corda deixa de ser engolida, e a criatura **anda o espinho**.
- **`sim/gestos.gd` (reescrito):** um dedo só; **segurar parado em qualquer
  lugar** = `segurar_inicio` (habilidade); segundo dedo **não é ação** (o
  caminho continua; toque/toque duplo/segurar ficam desarmados). Saem
  `_acao_dedos`, `defendendo`, `deslize`, `especial`, `caminho_cancelar`.
- **`sim/comandos.gd`:** tabela nova (`toque` → travar, `toque_duplo` → pular,
  `segurar` → habilidade, `trajetoria` → mover); saem `setor` e o `deslize`.
- **`sim/corpo.gd`:** o ataque saiu dos gestos e foi para as FORMAS —
  `tracar` guarda o traço cru, lê as formas (a cada ~5 pontos, e no soltar) e
  monta as **marcas**; o gatilho é a passagem da criatura pelo ponto da marca
  (`gatilho_raio_px` 24; o laço exige a direção do fechamento). **Onda**
  (círculo que cresce do centro e empurra quem varre), **tiro** (projétil na
  direção do bico, para no primeiro alvo), **batida** de travessia,
  **alvo final** marcado no inimigo (golpe físico na chegada; perdido se ele
  andar > 48 px), **habilidade** genérica com `cavar` como primeira. Saem
  `esquiva`, `defesa`, `especial`, `desvio` e `guardar_rota`/`voltar_rota`.
  A rota ao vivo continua igual (pontos de referência, desconto, desvio de
  objeto, barreira e pulo).
- **`sim/adversario.gd`:** `empurrar(dir, px)` — desliza (260 px/s) até gastar
  o empurrão, cortado pelo mundo, e **pisca** 0,24 s; `piscando()`/`empurrado()`.
  **`sim/alvos.gd`:** `empurrar` (só quem sabe reagir) e `reage`.
- **`jogo/`:** `efeitos.gd` (novo: onda/tiro); `mira.gd` desenha o **"X"
  amarelo do alvo final no inimigo**; `criatura.gd` perde rastro de esquiva e
  anel de defesa, ganha anel de habilidade; `adversario_mock.gd` pisca no
  acerto; `hud.gd` com a legenda/estado novos e a **nota** do último golpe;
  `main.gd` sem cancelamento de traço (não há gesto de dois dedos), com o
  fechamento do caminho chamando `finalizar_rota` e o nó dos efeitos.
  `demo.gd` reescrito: laço → onda; bico → tiro; segurar → cavar (desce e
  sobe); toque duplo; travessia; fim em cima (golpe final).
- **Dados:** `gestos.json` só com toque/toque duplo/segurar/trajetória;
  `acoes.json` ganha `formas`, `combate`, `habilidade` + `cavar` e `batida`;
  saem `esquiva`, `especial`, `defender`, `escavar` (virou `cavar`).
- **Verificação:** **82 testes, 0 falhas**, 38 scripts (parser limpo).
  **Sonda headless da demo inteira** (2.400 quadros, `--demo`): `laco:onda` em
  ~3 s, `bico:tiro` em ~4,6 s, `habilidade:on` + `camada:subsolo` (8,2 s) e
  `camada:superficie` (10,0 s), `mira_final:adversario:0` (12,6 s), `batida` +
  `acerto` + `golpe_final:adversario:0` (15,6 s). **Oráculo de quadros**
  (`tools/quadros.sh`, 150 quadros 720×1280 em ~3 min 50 s, ~1,5 s/quadro):
  caminho com **laço** desenhado, **onda azul saindo do centro** do laço em
  3,1 s, HUD v0.9 e o **bico** desenhado em 4,6 s — abri os PNG. Uma segunda
  gravação (520 quadros, a demo inteira) mostrou a **cavada** (terra voando e
  `subsolo` na HUD), o **alvo final** e o **"X" amarelo pulsando NO INIMIGO**
  em 16,7 s — abri os PNG. Detalhe de projeto em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md).

## v0.8.0 — gestos de ação com DOIS dedos (2026-11-20)

- **Pedido do operador:** os gestos de ação conflitavam com o movimento
  contínuo. Agora: **mover = 1 dedo arrastando** (como está, sem espera);
  **ataque = 2 dedos para cima**; **defesa = 2 dedos para baixo**; **especial =
  2 dedos abrindo** (do centro para a borda, como um zoom). O dedo que desenha
  o caminho **desconta**: com o segundo dedo dá para atacar **durante** o
  desenho, sem parar o traço.
- **`sim/gestos.gd` (multitouch, reescrito):** o PRIMEIRO dedo é o do caminho;
  os dedos EXTRAS formam o ponteiro da ação (média dos deslocamentos) — cima
  (`acao_min_px` 44 px em até `acao_max_ms` 0,7 s) → `deslize` (ataque);
  baixo → `segurar_inicio` com `defesa` (sustentada até soltar); lateral +
  afastamento do dedo do caminho ≥ `especial_abre_px` (70 px) → `especial`.
  Um disparo por gesto; soltar e tocar de novo abre outro. Se o segundo dedo
  chega antes de o caminho desenhar (`desenho_min_ms` 150 ms), o gesto é só
  ação: `caminho_cancelar` (o motor devolve a rota anterior). Toque, toque
  duplo e escavar continuam no dedo do caminho sozinho.
- **`sim/comandos.gd`:** evento `especial` próprio (ação + direção de fora).
  A tabela `deslize` ficou só com "cima" — o "baixo" agora é DEFESA, não
  esquiva.
- **`jogo/main.gd`:** entrada multitouch (`_dedos` por índice, origem congelada
  no PRIMEIRO dedo); `caminho_cancelar` restaura a rota; uma AÇÃO devolve o
  tempo na hora (`_plano_liberado`), o golpe não fica em câmera lenta. **Bug
  meu da v0.7 corrigido:** a fórmula do véu estava invertida (alfa cheio FORA
  do desenho); agora é 0 parado, 0,22 desenhando e cai junto com a rampa
  (medido nos quadros: brilho médio 110 desenhando × 135–140 parado).
- **`jogo/demo.gd`:** roteiro reescrito com TRILHAS por dedo (caminho de 1
  dedo; ataque/especial/defesa de 2 dedos; ataque com o dedo extra no meio de
  um caminho em curso); `jogo/hud.gd` com a legenda nova.
- **Dados (`dados/gestos.json`):** entram `desenho_min_ms`, `acao_min_px`,
  `acao_max_ms`, `especial_abre_px`; saem os `flick_*` e o `segurar_estavel_ms`.
- **Verificação:** **73 testes, 0 falhas**, 35 scripts. Sonda headless da demo
  inteira (400 quadros): caminho ao vivo (véu 0,22 · 0,35×), ataque de 2 dedos
  em 2,2 s **sem andar** (célula estável, rota seguindo), especial em 3,4 s,
  defesa em 4,6 s (rota parada, `soltar` retoma), pulo, mira, ataque no alvo, e
  **ataque com o 2º dedo em 10,0 s com o caminho ainda sendo desenhado**
  (`desenhando` segue, a rota continua, o tempo volta na hora). Quadros do
  oráculo (96) abertos: legenda, véu e ataque sem véu.

## v0.7.1 — o gesto de AÇÃO não é passo (2026-11-20)

- **Correção do operador sobre a v0.7.0:** "em paralelo" queria dizer poder
  **atacar DURANTE a caminhada**, e não que todo gesto vira movimento. Na
  v0.7.0 o risco de ataque também desenhava um passo (≈120 px de mundo) e
  desviava a criatura.
- **Gestos (`sim/gestos.gd`):** quando o risco dispara, `_desenhando` volta a
  falso — o gesto é de AÇÃO, não de caminho — e o `soltar` não emite
  `trajetoria` (e nem `nada`: o gesto já resolveu). A **defesa** também
  cancela o traço. Um gesto = uma intenção.
- **Corpo (`sim/corpo.gd`):** novos `guardar_rota()` / `voltar_rota(g)` — o
  instantâneo da rota (pontos, índice, progresso, barreira e autonomia) é
  tirado na DESCIDA do dedo (`jogo/main.gd`) e devolvido quando o gesto vira
  ação. Assim o golpe acontece **por cima** da caminhada, que continua de onde
  estava.
- **Tela (`jogo/main.gd`):** `_cancelar_traco()` no evento `deslize` e no
  `segurar_inicio` (defesa/escavar); num risco o tempo volta na hora
  (`_retomada = 0`), sem rampa — ação não fica em câmera lenta. O véu é
  suavizado e o "planejamento" (tempo lento + véu) só começa quando o gesto
  **deixou de poder ser um risco** (`_planejavel` em `sim/gestos.gd`): senão a
  tela escureceria por dois quadros a cada ataque.
- **Verificação:** 72 testes; sonda headless da demo inteira (520 quadros, 30 fps):
  ataques em 2,6 s / 3,6 s / 4,9 s / 6,0 s / 9,2 s / 12,4 s **não** movem a
  criatura (célula estável; a rota de 3 pontos volta logo após o disparo); a
  defesa em 10,6 s cancela o traço para baixo; os dois caminhos seguem
  normais. **71 testes, 0 falhas**, 35 scripts.
- **O que fica:** a linha da rota pode piscar por ~2 quadros no começo de um
  risco (o traço nasce ao vivo e é cancelado no disparo) — ver `RESIDUOS`.

## v0.7.0 — caminho ao vivo, sem espera, e ações em paralelo (2026-11-20)

- **Pedido do operador:** (1) tirar o atraso do toque longo — o arrasto
  contínuo vira caminho **direto**; (2) a linha **não se move com o animal**
  (parte da posição no INÍCIO do gesto; se ele se mexeu no meio, volta para
  começar por lá); (3) **ataques e afins em paralelo**, sem atraso; (4)
  **escurecer** a tela durante o desenho e uma **rampa de aceleração** na saída;
  (5) **mais sensibilidade** (dedo menor cobrindo mais tela).
  **Decisões dele** (perguntadas antes de codar): caminho **AO VIVO** (a
  criatura já anda atrás do dedo) e ação disparada **no meio do risco**, ao
  cruzar o limiar.
- **Gestos (`sim/gestos.gd`, reescrito):** `segurar_min_ms` deixou de ser porta
  do caminho — passou de `desenho_min_px` (16 px) já é caminho
  (`desenhando()`), e o `tick` só decide **defesa** (baixo + parado 0,18 s) e
  **escavar** (segurar nela, parado, sem arrastar, 0,38 s — decidido no
  soltar). O **RISCO** (`flick_*`) dispara `deslize` NO MEIO do arrasto e o
  caminho continua: 44–170 px, ≤ 0,26 s, ≥ 700 px/s, desvio da corda ≤ 24 px,
  **um por gesto** (senão um desenho rápido viraria metralhadora). Guarda
  `_tempos` por ponto para medir velocidade numa janela de 90 ms.
- **Corpo (`sim/corpo.gd`):** novo `tracar(pontos, mundo, inicio)` — a rota é
  refeita a cada quadro com o traço até agora, o progresso **nunca anda para
  trás** e a origem fica congelada. No primeiro quadro, se a criatura já se
  mexeu, o trecho que a traz de volta ao começo é posto NA FRENTE **depois** da
  simplificação (um traço reto com os três pontos colineares seria engolido
  pelo Douglas-Peucker e ela cortaria o caminho — foi o primeiro teste
  vermelho). `_pontos_de_rota` (desconto + RDP) e `_guardar_rota` foram
  extraídos do antigo `_cmd_mover`, que continua valendo (testes antigos).
- **Tela (`jogo/main.gd`):** na descida do dedo congela-se a **origem**
  (posição da criatura + `canvas_transform` inverso); o traço é traduzido com
  `desenho.ganho` (1,6), então 100 px de dedo desenham 160 px de tela. O **véu**
  (`ColorRect` na CanvasLayer da HUD, atrás dos rótulos) escurece
  `planejamento.escurecer` (0,22) enquanto desenha/defende e clareia junto com
  a **rampa** `retomada_ms` (0,45 s), que devolve o tempo de 0,35× a 1× com
  `v²` (começa devagar e solta no fim). `jogo/trilha.gd` perdeu a âncora;
  `jogo/hud.gd` (legenda v0.7.0, "DESENHANDO") e `jogo/demo.gd` (sem `hold`,
  divide o traço pelo ganho para cobrir as mesmas células) seguem a regra.
- **Dados (`dados/gestos.json`):** `desenho.ganho` 1,6; `planejamento` 0,35× ·
  0,45 s · 0,22; `flick_*`; saíram `trajetoria_min_px` e `deslize_max_ms`
  (eram da regra antiga).
- **Verificação:** `tools/testes.sh` — **70 testes, 0 falhas**, 35 scripts no
  parser. `test_gestos.gd` reescrito (sem espera, risco no meio, um por gesto,
  desenho lento/curvo sem ação, defesa, escavar, toques); `test_corpo.gd` ganhou
  o traço ao vivo (cresce sem voltar; a volta ao começo quando ela se mexeu).
  Oráculo: 96 quadros 720×1280 (t≈3,2 s) — véu visível, rota ao vivo atrás do
  dedo, ataque disparado no meio do risco com o caminho continuando; a demo
  completa (500 quadros) confere os passos seguintes.

## v0.6.1 — o aviso de atualização volta a aparecer na tela (2026-11-20)

- **Relato do operador:** o app detectou a atualização (a HUD dizia "toque em
  ATUALIZAR"), mas **não havia botão nem painel na tela** para atualizar.
- **Causa medida:** o `Atualizador` é um `Control` filho de uma `CanvasLayer`;
  os anchors sozinhos **não davam tamanho a ele** (ficava 0×0). O botão
  "ATUALIZAR" era ancorado no topo-direita de um retângulo de 0×0 e caía em
  **x = −252** (fora da tela); o painel de download tinha o mesmo problema. A
  HUD mostrava o texto, mas o controle não.
- **Conserto:** o `Atualizador` passou a ocupar a tela (`size` =
  `get_viewport_rect().size`, reaplicado em `size_changed`); o botão desceu
  para `y + 420` (abaixo da legenda) e, na **primeira detecção**, o painel
  "Nova versão … disponível" abre **sozinho**, com "Baixar agora" e "Depois".
  O botão continua disponível depois; o painel não reabre sozinho na mesma
  sessão.
- **Verificação:** sonda headless com `await` mediu o `Atualizador` em
  720×1280 e o botão em x = 468..708 (dentro da tela); a tela real com build
  13 contra a Release conferiu o painel. 66 testes, 35 scripts, CI e APK
  verdes. O runner de testes síncrono não roda quadros, então o layout do
  atualizador não tem teste unitário (ver `RESIDUOS`).
- **Para o operador:** a **v0.5.0 instalada** tem o código antigo e não
  consegue mostrar o botão — é preciso instalar o APK da **v0.6.1 à mão uma
  vez** (o `ATUALIZAR` do app não aparece nela). Depois disso o aviso funciona
  nas próximas versões. O APK 0.6.0-b14 também tem o defeito; use o 0.6.1-b15.

## v0.6.0 — retrato, gestos de tela, caminho por âncora e desvio de objetos (2026-11-20)

- **Pedido do operador:** os gestos de ação não são mais relativos ao animal
  (não existe "para a frente dele"): são da TELA — para cima é ataque físico,
  lados são especiais, para baixo é esquiva; arrastar para trás e continuar
  segurando é defesa. Tela em **retrato**. O caminho passa a ser desenhado a
  partir de uma **âncora segurada** longe da criatura (o dedo não tapa a
  visão), com **retardo de tempo** durante o desenho/planejamento; **desconto
  inicial** do vai-e-volta; caminho contado como **pontos de referência** com
  **pequenos desvios de objetos**; barreira sem pulo = para, com pulo = segue.
- **Gestos (`sim/gestos.gd`):** setores de tela (0° = direita, -90° = cima);
  segurar parado 0,38 s cria a âncora; arrastar a partir dela = `trajetoria`;
  baixo + segurar (parado 0,18 s) = `segurar_inicio` de defesa; segurar nela
  sem arrastar = escavar (só no soltar, e só se não arrastou além de 16 px).
  Toque, toque duplo e os demais limiares continuam em `dados/gestos.json`.
- **Comandos (`sim/comandos.gd`):** a tabela `mapa.deslize` agora é de ângulos
  de TELA: cima → ataque; direita/esquerda → especial com lado; baixo →
  esquiva com direção. A defesa (`defesa: true`) vence o "nela".
- **Caminho (`sim/trajetoria.gd` + `sim/corpo.gd`):** o traço é cortado no
  início (`descontar_inicio`: só se houve volta ≥ 6 px, janela de 140 px e
  reta andável) e reduzido por Douglas-Peucker (`simplificar`, 10 px) a pontos
  de referência. O corpo procura um ponto por vez; tronco é contornado por um
  leque de até ±120° (`desvio_angulos`, teto de 80 passos); água/rocha/altura
  são barreira: a criatura **para** (`barrado()`), a rota fica guardada e um
  **pulo** durante a rota atravessa e retoma. Caiu na água? Não anda sobre ela:
  precisa de outro pulo.
- **Especial:** ação nova em `dados/acoes.json` (fases 0,14/0,22/0,26; alcance
  56; arco 120°; recarga 0,55), um golpe lateral genérico — o conteúdo por
  criatura fica para P4/P5. O ataque físico continua mirando no alvo/rota, não
  no ângulo do dedo.
- **Retrato:** `project.godot` 720×1280, `window/handheld/orientation=1`;
  oráculo em 720×1280; HUD e painel de atualização reorganizados para a tela
  alta (texto do aviso em cima, botões embaixo); botão "Verificar atualização"
  desceu para não colidir com a legenda.
- **Tempo lento:** enquanto a âncora existe, o MUNDO roda a 0,35×
  (`planejamento.escala_tempo`); o relógio do gesto e o dedo continuam reais.
  A HUD mostra `PLANEJANDO 35%`.
- **Prévia:** o traço é desenhado transladado sobre a criatura (a âncora vira
  o "animal virtual") com um anel ciano no ponto segurado; ao soltar, a rota
  começa na posição atual dela.
- **Testes:** 66 verdes (gestos de tela/âncora/defesa, desconto, RDP, ordem dos
  waypoints, desvio de tronco, barreira + pulo, pulo curto na água, especial,
  esquiva de tela). Parser: 35 scripts limpos. Oráculo: 60 quadros 720×1280
  sem erro de script, âncora e prévia conferidas por imagem.
- Dois defeitos encontrados no caminho: a célula bloqueada era testada 3 px à
  frente e caía na célula de baixo (o desvio nunca começava) — agora o primeiro
  bloqueio é amostrado ao longo do passo; e a criatura conseguia **andar para
  fora da água** depois de um pulo curto — agora a célula atual de terreno
  bloqueia o passo normal.
- **Fica para depois:** especiais por criatura, ajuste fino de
  `escala_tempo`/`desconto_raio_px` com o operador, física de pouso/natação e
  a afinidade (P4).

## v0.5.0 — movimento com rota + autonomia, alvos e atualizador consertado (2026-11-20)

- **Atualização (relato do operador):** só funcionou baixando à mão. Medido: o
  manifesto e o `galapago/build` estavam certos; o defeito era **quando**
  verificar — só no arranque a frio, e o Android mantém o app vivo. Agora
  verifica ao abrir, **ao voltar do segundo plano**, de 5 em 5 min, e por botão
  ("Verificar atualização"); o estado fica **visível** na HUD; duas fontes
  (manifesto e API da Release) com nova tentativa; e um botão persistente
  "ATUALIZAR" que não depende de o aviso ser visto.
- **Movimento redesenhado (regra do operador):** rota e ações **andam
  juntas**. Ataque, esquiva e pulo são OVERLAYS que não cancelam a rota; a
  esquiva desloca e volta; o pulo é arco enquanto ela segue; a defesa PARALISA
  sem apagar; só uma rota nova substitui. Arrasto perto dela = rota (mesmo
  rápido); longe = gesto de ação (frente = ataque; lados = esquiva).
- **Alvos:** toque trava/solta a mira em árvore ou adversário (posição
  re-resolvida: mira em alvo MÓVEL); o ataque vai na direção do alvo, ou da
  rota sem alvo; baú interage.
- **Autonomia:** ao fim da rota, fica parada, vagueia devagar ou vai/ronda o
  alvo marcado — sorteio **semeado** (determinístico).
- **Adversário de teste** (`sim/adversario.gd`): vagueia sem reagir, sem dano,
  sem contato; determinístico por semente; não entra na água.
- `sim/corpo.gd` reescrito; `sim/alvos.gd` e `sim/adversario.gd` novos; HUD
  mostra versão, estado da atualização, rota/autonomia, alvo e camada.
- **Testes:** 49 verdes (rota, overlays sem cancelar rota, defesa para/retoma,
  alvo móvel, autonomia determinística e dentro do mapa, escavação). Parser: 35 scripts limpos.
- Defeito real encontrado e corrigido: no quadro em que a rota terminava, o
  código limpava `rota` e depois lia a posição dela — a criatura ia para
  (0,0). Agora a posição final é calculada antes de limpar.

## v0.4.0 — a fundação: gestos, ações e camadas (2026-11-20)

- **Escala confirmada (captura do operador = análise):** criatura 64×64 px de
  arte, célula 32 px, câmera 2×. A "impressão de grande" é a ampliação
  (64 × 2 × ~1,64 da tela real), não a resolução.
- **Gestos** (`sim/gestos.gd`, tempo simulado = determinístico): toque, toque
  duplo, segurar, deslize, trajetória; limiares em `dados/gestos.json`.
- **Gestos → comandos** (`sim/comandos.gd`): deslize por SETOR relativo ao
  OLHAR da criatura (frente-esquerda → `ataque_x`, frente → `investida`,
  frente-direita → `ataque_y`, trás → `esquiva`); tabela em `dados/gestos.json`
  (a legenda da HUD e a demo seguem ela).
- **Ações** (`sim/corpo.gd` + `dados/acoes.json`): máquina com
  antecipação/ativa/recuperação, recarga, sustentada (defender), pulo e
  deslocamento consultam o mundo (não atravessam parede, pulo pousa só onde
  dá), escavar troca a camada.
- **Mundo em camadas** (`sim/mundo.gd` + `dados/terrenos.json` +
  `dados/mapas/fundacao.json`): superfície (terreno por célula, altura, andável,
  escavável, rampa 1,5) e subsolo (túneis); andar vence 0,5 nível, pulo sobe 1,
  escavação desce/sobe.
- **Visibilidade** (`sim/visibilidade.gd`): copa opaca de longe, quase
  transparente com a criatura por baixo (smoothstep) — baú escondido no bosque.
- **Apresentação em MOCKUP de xadrez** (`jogo/mock.gd`, `jogo/camadas/`):
  parallax fundo (0,35×) e frente (1,35×), chão com paredes e buracos, objetos
  y-sort pela base, subsolo que escurece a cena, copas acima de tudo, HUD de
  desenvolvimento com a legenda gerada da tabela.
- **Demo roteirizada** (`jogo/demo.gd`): sintetiza DEDOS (não comandos) e passa
  pelo fluxo real; cobre trajetória, os 3 deslizes, toque duplo (pulo sobre o
  canal), segurar (defender), escavação (desce, anda no túnel, sobe) e bosque.
- **Verificação:** 43 testes (gestos, comandos, corpo, mundo, visibilidade),
  parser em 30 scripts; demo 450 quadros a 15 fps SEM erro de script; camadas
  conferidas por amostragem de pixels (superfície verde/cinza/azul, subsolo
  escuro). O modelo desta sessão não lê imagem → verificação visual programática.
- GDDs novos: [`docs/gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md) e
  [`docs/gdd/mapa.md`](gdd/mapa.md) reescrito para as camadas.

## v0.3.1 — atualização pelo método do IASD; repositório público (2026-11-20)

- O operador recusou o canal separado (link para o navegador, login no GitHub)
  e pediu o método do Áudio Visual IASD com o repositório público. Feito:
  `ShellUpdater.kt` do IASD lido e replicado em Godot — manifesto
  `versao.json` como asset da Release `dev`, download DENTRO do app com barra,
  tamanho conferido, instalador do sistema via `OS.shell_open(arquivo)`
  (conferido no `GodotIO.java` 4.7.2: `FileProvider` `<pacote>.fileprovider`).
  Permissão `REQUEST_INSTALL_PACKAGES` por `custom_permissions` (não está na
  lista do Godot). `sim/atualizacao.gd`: host travado, teto de 300 MB,
  `download_completo` (6 testes).
- **Antes de abrir o repositório:** histórico inteiro auditado (10 commits) —
  sem token/chave; a única coisa sensível era o keystore de dev + senha.
  Keystore NOVO (RSA 3072, senha aleatória) só em secrets
  (`ANDROID_KEYSTORE_B64`/`_SENHA`) e no cofre do operador; o antigo saiu da
  árvore (fica no histórico, revogado). Reinstalação única do operador.
- Canal da v0.3.0 desmontado: repositório `Projeto-Galapago-canal` apagado,
  secret `CANAL_DEPLOY_KEY` apagado, `publicar-canal.sh` removido.

## v0.3.0 — atualização automática + ilha vista de cima em alta resolução (2026-11-20)

- **Atualização (P9):** canal PÚBLICO só de versão (`jonathasptbr-gh/Projeto-Galapago-canal`,
  `canal.json`) — decisão do operador: tudo privado. CI → `tools/android/publicar-canal.sh`
  via deploy key só do canal (secret `CANAL_DEPLOY_KEY`; a chave privada não
  existe fora do secret). App → `jogo/atualizador.gd` (HTTP no `raw`, `?t=`) +
  `sim/atualizacao.gd` (pura, 3 testes) → aviso com "Atualizar" (abre o APK da
  Release `dev` no navegador; precisa de login no GitHub). `exportar.sh` grava
  `config/version`/`galapago/build` num `project.godot` temporário;
  `permissions/internet=true`; `include_filter="*.json"`.
- **Tela (decisão do operador):** 1280×720, `canvas_items`, `expand`; arte
  *nearest* com câmera zoom 2; linhas/sombras/anel/texto lisos (antialiasing);
  snap 2D desligado (movimento em subpixel). Oráculo em 1280×720 (~40 s/60 quadros).
- **Mapa (P10):** `sim/mapa.gd` (cantos Wang por níveis mar/areia/grama/planalto,
  validador, 8 testes incl. o desenho real) + `jogo/mapa.gd` (TileMapLayer
  montado em código dos metadados do PixelLab) + `dados/mapas/ilha_teste.json`
  (41×22 pontos, 12 objetos) + y-sort de objetos/criatura pela base + sombras
  lisas. Design em `docs/gdd/mapa.md`.
- **Arte (PixelLab, 6 gerações; saldo 33/40):** tilesets standard 32 px
  `mar_areia` (transição 0,25), `areia_grama` (encadeado na areia),
  `grama_planalto` (transição 0,5 = paredes de penhasco ao sul) — cores dos
  terrenos compartilhados conferidas iguais (`#ffebba`, `#37a129`); objetos
  Pixen high top-down: `arvore` 64 (seed 3001), `rocha` 32 (3002), `estacao` 96
  (3003). Duas gerações falharam no servidor (502 e timeout) e não foram cobradas.
- Ferramentas: `tools/pixellab-tileset.mjs`, `tools/pixellab-imagem.mjs`.
- Conferido de fora após o CI #8: `canal.json` responde 200 SEM autenticação
  (`versao_codigo` 8, `0.3.0-b8`); o link do APK sem login responde 404 (privado,
  como decidido); o APK traz `assets/dados/mapas/*.json` e os metadados dos
  tilesets. Achado no b9: o `raw` serve cache de até 5 min ignorando o `?t=` →
  o atualizador passa a ler pela API (fresca), com o `raw` de reserva (b10).
  O b8 foi deixado em `Download/DSH-Go/` de propósito: o push seguinte
  (b9) faz o b8 oferecer a atualização — teste real do fluxo pelo operador.

## v0.2.0 — APK no CI (P2) + catálogo do PixelLab e guias (2026-11-20)

- **P2:** job `apk` no `ci.yml` (depois de `testes`): JDK 17 (temurin), Godot
  4.7.2, templates Android extraídos do `.tpz` de 1,2 GB e guardados em cache
  (`android_debug.apk`, `android_release.apk`), `tools/android/exportar.sh`
  (import → editor settings com `java_sdk_path`/`android_sdk_path` → preset
  temporário com `version/code` = nº do run → `--export-release "Android"` →
  `aapt`/`apksigner` conferem). Publica Release `dev` (pré-release refeita a
  cada push em main) e Release por tag `v*`.
- `export_presets.cfg`: Android, só arm64-v8a, sem Gradle,
  `com.projetogalapago.jogo` (provisório), imersivo, paisagem (do projeto).
  Validado localmente: o Godot lê o preset e só reclama do que falta aqui
  (templates, JDK, SDK) — os mesmos três que o CI fornece.
- Keystore de DESENVOLVIMENTO versionado (`tools/android/galapago-dev.keystore`,
  PKCS12, alias `galapago`): assina builds de teste para que cada APK instale
  por cima do anterior. A chave da loja será outra, em *secret*.
- `tools/baixar-apk.mjs`: baixa o APK de uma Release (privada) para
  `/sdcard/Download/DSH-Go/`.
- CI #5 vermelho → `import_etc2_astc=true` (o export Android recusa sem ETC2/ASTC);
  CI #6 verde: `com.projetogalapago.jogo` `0.2.0-b6`, minSdk 24, targetSdk 36,
  26 MB; assinatura conferida localmente = SHA-256 do keystore de dev. APK
  entregue em `/sdcard/Download/DSH-Go/projeto-galapago-dev.apk`.
- **Catálogo PixelLab da fonte:** `tools/pixellab-catalogo.mjs` (MCP
  `tools/list` + `resources/list`/`read`) → `docs/pixellab/CATALOGO.md`
  (140 ferramentas em 11 categorias), `ferramentas.json` (esquemas completos),
  `recursos/` (7 guias oficiais, 3 de Godot). Diff servidor × ferramentas
  visíveis na sessão: idêntico (140 = 140).
- **Guias:** `docs/PIXELLAB.md` (ferramenta por tarefa do jogo, custos, o que o
  trial não tem: Tier 1 = tiles/salas pro, edit_animation, transfer_outfit…;
  Tier 2 = música e som), `docs/GODOT.md` (CLI conferida no `--help`, arquivos,
  convenções, pixel art, toque, export Android e armadilhas), `docs/BUILD.md`
  (o rito; o `ci.yml` já o citava sem existir).
- **Ferramentas:** `tools/godot-api.sh` (API 4.7.2 offline: estrutura do
  `--doctool` + textos da tag `4.7.2-stable` em cache), `tools/ci-log.mjs`,
  e `tools/testes.sh` passa a rodar `--check-only` em todo `.gd` (testado:
  reprova erro de parse com código 1).
- Ambiente: JDK 17 no celular (para `keytool`); o `dpkg` só configura com
  `/usr/share/man/man1` existente (imagem enxuta). `~/.local/bin` NÃO está no
  PATH dos shells do agente: os scripts já caem para `$HOME/.local/bin/godot`.

## v0.1.1 — PixelLab conectado, P1 (2026-11-20)

- Chave do operador (chegou pelo chat) → cofre `refs.PIXELLAB_TOKEN`; validada
  antes de configurar (MCP `initialize` + `tools/list` = 140 ferramentas +
  `get_balance`: trial, 40 gerações).
- Entrada `mcp-pixellab` no `cordis.patch.yml` do perfil web (backup em
  `~/tmp/cordis.patch.yml.bak-20261120-1552`); cabeçalho por `!!js` que lê o
  cofre. Conferida por `dsh web --dump-config` e pela avaliação do `!!js` fora
  do motor. Recarga a quente: as ferramentas vieram na mesma sessão.
- Prova: `create_image_pixen` 64×64, vista lateral, seed 20261120 →
  `arte/fonte/p1-cao-base-pixen.png` (64 cores, fundo transparente). 1 geração.
- `docs/ARTE.md`: como a conexão é feita, como trocar a chave, tabela de custo.
- Ambiente: Pillow instalado por pip (inspeção de PNG em script).

## v0.1.0 — esqueleto (2026-11-20)

- Repositório privado `jonathasptbr-gh/Projeto-Galapago` criado; motor
  **Godot 4.7.2** (renderizador de compatibilidade, 320×180 inteiro) e arte
  via **PixelLab MCP** — decisões do operador.
- Viabilidade medida antes de decidir: Godot arm64 renderiza neste celular sob
  Xvfb com Mesa **softpipe** (llvmpipe: SIGILL no JIT do proot; GLES sem EGL).
  Daí o oráculo `tools/quadros.sh` (Movie Maker, `--write-movie`).
- `sim/trajetoria.gd` (amostrar, comprimento, ponto_em) + 4 testes;
  executor `testes/run.gd` + `tools/testes.sh` (reprova também SCRIPT ERROR —
  controle negativo feito: falha proposital e erro de script reprovaram).
- Cena viva `jogo/main.tscn`: risca → a criatura provisória segue; `--demo`
  roteiriza o traço para o oráculo.
- CI `ci.yml`: Godot x86_64, testes, quadros como artefato. APK fica para P2.
- Docs: `AGENTS.md` (contrato), `CONCEITO`, `ARQUITETURA`, `ORACULO`, `ARTE`,
  `AMBIENTE`, fila `PEDIDOS-EM-ESPERA` (P1–P8), `RESIDUOS`.
