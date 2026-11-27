# Resíduos — o que o lote viu e não consertou

> Toda **publicação** (`vX.Y.Z`) deixa ao menos uma linha aqui antes do push,
> mesmo que seja "nenhum"; commit comum não registra (nota, se houver, vai em
> `## Não publicado` do histórico). Linha não se apaga: muda o estado.
> `congelado (rig)`: parado até a reestruturação da fundação do rig (2026-11-25).
> `obsoleto (3D)`: o assunto saiu do jogo com a Fundação 3D (P24, v0.35.0) — o
> código ou desenho 2D citado não está no caminho de jogo (`jogo/main.gd`,
> `jogo/mundo3d/`); conferido com `rg` na triagem P28 (2026-11-26).
> `descartado (operador)`: o operador decidiu não aplicar (2026-11-26, fechamento do P28).

| versão | onde | o quê | tamanho | estado |
|---|---|---|---|---|
| v0.36.0 | desempenho | mapa NATUREZA: ~691 mil triângulos instanciados no mapa inteiro, 341 MultiMeshes em setores; FPS e aquecimento no aparelho não medidos | médio | aberto |
| v0.36.0 | natureza | água opaca e parada (sem reflexo, refração ou correnteza animada); sem vento nas folhas | pequeno | aberto |
| v0.36.0 | natureza | sem subsolo desenhado: cavar só na clareira de terra fofa, e o túnel não aparece (como na Fundação) | pequeno | descartado (operador) |
| v0.36.0 | natureza | sem contorno de tela na mata: o ator provisório fica sem linha ali; árvores e pedras não são alvo de colisão física do tiro além do tronco da célula | pequeno | aberto |
| v0.36.0 | natureza | a linha do caminho (pontos escuros e translúcidos de `jogo/trilha.gd`) fica discreta na terra escura da mata; a cor é compartilhada com a Fundação e não foi mexida | pequeno | aberto (design) |
| v0.36.0 | oráculo | o CI filma só a Fundação; a Natureza é filmada à mão (`DEMO_ARGS="--natureza"`) | pequeno | descartado (operador) |
| v0.35.4 | contorno | o "pescoço" do ator provisório (esfera × cápsula) mudou levemente no contorno e já era ruidoso; conferir no aparelho | pequeno | aberto |
| v0.35.4 | oráculo | a prova local em Vulkan/lavapipe depende de um shim fora do repositório (`~/tmp/lvpshim/shim.so`, `LD_PRELOAD` que força `LLVMGetHostCPUName` = `cortex-a76`, porque o llvmpipe emitia SVE que o kernel não expõe); não está em `docs/AMBIENTE.md` nem `docs/ORACULO.md` | pequeno | resolvido v0.36.0 (shim descrito em ORACULO.md) |
| v0.35.3 | contorno | na vista alta, paredes baixas (planalto, costa, rampa) ganham duas linhas próximas (topo e pé) | pequeno | aberto (design) |
| v0.35.3 | contorno | pontinhos quase invisíveis em vértices de 4 facetas da copa e em 1 ponto da pedra | pequeno | aberto |
| v0.35.3 | desempenho | contorno sobe para 49 leituras de profundidade/pixel no liso (41 no Pixel Pass); custo no aparelho não medido | médio | aberto |
| v0.35.2 | contorno | o ator provisório é cápsula de fundo redondo: a linha abraça a base em vez de sumir (some com pés de verdade) | pequeno | aberto |
| v0.35.2 | contorno | linha um pouco mais fina que a casca antiga (~3 px de canvas); espessura em `vista.espessura_contorno` | pequeno | aberto |
| v0.35.2 | desempenho | contorno de tela lê 21 amostras de profundidade por pixel na resolução física (+ resolve do MSAA no Mobile); custo no aparelho não medido | médio | aberto |
| v0.35.1 | chão | a textura do chão tem ~1 texel por px da sim: ampliada 3× (vista alta) a 6× (íntima) no aparelho, pontos e anéis ficam um pouco macios | pequeno | aberto |
| v0.35.1 | desempenho | a textura do chão (2046×806) é redesenhada todo quadro, e o liso roda MSAA 4× na resolução física com atlas de sombra 4096 — custo no aparelho não medido | médio | aberto |
| v0.35.1 | chão | não há quadro do caminho passando sob uma copa (a demo não passa por lá); garantido pela profundidade, não filmado | pequeno | aberto |
| v0.35.0 | 3D | sobreposições (trilha, mira, perigos, efeitos) ficam por cima do 3D: uma copa não esconde a trilha | pequeno | resolvido v0.35.1 (projéteis seguem no ar) |
| v0.35.0 | 3D | copas de árvore escondem a criatura que passa por baixo (no 2D a copa ficava translúcida) | pequeno | descartado (operador) |
| v0.35.0 | 3D | subsolo e células escavadas não são desenhados no mundo 3D | médio | descartado (operador) |
| v0.35.0 | visual | no Vulkan (CI #108) o contorno de algumas paredes sai tracejado, aparecem manchas escuras nas copas na vista íntima e o dither está forte | pequeno | resolvido v0.35.1 (dither: Pixel Pass fora do padrão) |
| v0.35.0 | 3D | criatura e inimigo são atores provisórios (cápsula); a pele real depende do rig, congelado | grande | aberto |
| v0.35.0 | desempenho | Mobile/Vulkan não medido em aparelho; o oráculo local é só prévia em Compatibility | médio | aberto |
| v0.34.3 | rig | cotovelo acima do ombro em 6/24 fases do galope: com o polo atrás, exigiria a pata 0,3–6,7 px mais longe que o arco do balanço — conserto de **trajetória** (dados), não de solver | médio | congelado (rig) |
| v0.34.3 | rig | joelho acima da anca em 3/24 e jarrete acima do joelho em 2/24: só no recolhimento máximo; clampar até a distância de apoio ordenaria, mas mudaria o contato | pequeno | congelado (rig) |
| v0.34.3 | marcha | o clamp do balanço aumenta a passada aparente do `fe` (17,0 → 17,46) sem mudar o dado | pequeno | congelado (rig) |
| v0.34.2 | rig | cotovelo dianteiro acima do ombro em 10/24 fases do galope: as duas dobras violam **por geometria** (ombro→pata < 9,72 px, cadeia de 21 px) — o conserto é de alvo/pose | médio | congelado (rig) |
| v0.34.2 | rig | joelho traseiro acima da anca em 3/24 e jarrete em 4/24: só no recolhimento máximo, onde a dobra válida pularia o joelho > 2,5 px (guarda anti-pisca) | pequeno | congelado (rig) |
| v0.34.2 | rig | a regra da dobra vale só nos clipes de marcha; idle, jump_*, charge, shot, bite, slam, dig, hit, stunned, death e get_up ficam fora (postura autoral) | pequeno | congelado (rig) |
| v0.34.2 | nomes | `joelho_fe/fd` é o **cotovelo**: 39 referências em 6 arquivos, 3 deles do rig 2D — renomeação fica para um lote próprio | pequeno | aberto |
| v0.34.1 | fluidez | pico do joelho traseiro em 3,48 px/quadro a 60 fps (teto do teste subiu 2,5→3,5); o pé não acelera — vigiar "piscada" no jarrete no aparelho | pequeno | congelado (rig) |
| v0.34.1 | rig | punho não existe com 24 juntas: antebraço e metacarpo são UM osso (só a razão da referência foi aplicada); punho próprio = +2 juntas, teto 26 (decisão 1C) | médio | congelado (rig) |
| v0.34.1 | rig | omoplata a 62° (prancha: 45°); 45° exigiria o ombro ~6 px à frente da cernelha e prende o fim do apoio do galope em z=12,4 | pequeno | congelado (rig) |
| v0.34.1 | pose | a fase reunida da prancha não é reproduzida: extensão 1,69 cernelhas (prancha 1,89) e compressão 0,67 (prancha 0,23) — tronco inclina ao contrário | médio | congelado (rig) |
| v0.34.0 | fluidez | com a passada maior, os tetos do teste subiram (transição walk→run 15 px; pico do run 2,5 px/quadro a 60 fps) — vigiar "estalo" na troca no aparelho | pequeno | congelado (rig) |
| v0.34.0 | sprint | a corrida acelerada usa a MESMA marcha do galope (muda só a velocidade); marcha própria de sprint (passada/voo maiores) exige perna mais longa | médio | congelado (rig) |
| v0.34.0 | câmera | no modo perto o segurar, sem rota, ainda cai na habilidade (cavar): o modo não alimenta o reconhecedor, mas o comando existe | pequeno | aberto |
| v0.34.0 | corpo | L2 aplicado só ao cão; o equino segue com as proporções antigas e a marcha dele (passada 17/21) | pequeno | congelado (rig) |
| v0.33.4 | animação | cadência do walk subiu ~61% com a reconciliação (0,198 s por ciclo aos 110 px/s); julgar no aparelho — o candidato C existe se ficar miúdo demais | design | aberto |
| v0.33.4 | rig | proporções do cão (item 3 da ordem) continuam pendentes: pernas, tronco e pescoço ainda são os do ajuste manual, não uma régua anatômica | médio | congelado (rig) |
| v0.33.3 | rig | descompasso entre `passada` e `duty × ciclo` (walk do cão −7,36 px; galope +1,90 px): a âncora no mundo esconde a diferença; reconciliar é o item (3) | médio | congelado (rig) |
| v0.33.3 | rig | `motion` ainda guarda chaves legadas (`duty_walk`, `galope_passo_px`, `run_baixa_px`, …) só porque `testes/test_esqueleto3d.gd` as lê; o motor não as usa | pequeno | congelado (rig) |
| v0.33.3 | rig | `_validar_marchas` assume exatamente 4 patas (`MARCHA_PATAS`); N pernas exige mexer em `_pernas`/topologia — bloqueio do inseto | pequeno | congelado (rig) |
| v0.33.2 | rig | o equino declara `porte_px` 68×68, o mesmo do cão — a régua de porte por arquétipo/família (decisão 1C) ainda não foi aplicada | médio | congelado (rig) |
| v0.33.2 | rig | `_patas` continua decidindo a pata por clipe, com defasagens cravadas no código; o item (2) da ordem (marcha por contato) é o próximo | médio | congelado (rig) |
| v0.33.1 | RIG | o método está escrito, mas o motor ainda decide a pata por clipe (`_patas`) e o inseto continua bloqueado pelo schema 2+2 — os lotes 1–5 da ordem de trabalho não foram feitos | médio | congelado (rig) |
| v0.33.0 | P10 | bípede, ave e serpente compilam (schema 4) mas seguem sem marcha: `locomocao_suportada` é falso e não há teste de passada para eles | médio | congelado (rig) |
| v0.33.0 | P10 | as cinco chaves do voo só existem no `canino3d.json`; o equino herda os defaults e o teste de voo só roda no cão | médio | congelado (rig) |
| v0.33.0 | P10 | decisões de raiz abertas: teto de 20 juntas (o cão tem 24), caixa por clipe × por animal e régua de porte entre arquétipos (canino 68×68, serpente 96×64, ave 64×64) | decisão | congelado (rig) |
| v0.33.0 | P10 | revisão do cão nas 8 direções e do canvas no aparelho do operador pendente | operador | congelado (rig) |
| v0.33.0 | clone | outra sessão commitou a `v0.32.0` (história) dentro do branch do lote às 12:01; o lote foi reconstruído sobre `origin/main` sem perda e o branch antigo `lote/v0.31.6` fica como evidência | pequeno | resolvido |
| v0.32.0 | história | decisões pendentes do GDD (ver docs/gdd/historia.md §Decisões pendentes) | design | aberto |
| v0.31.5 | notificações | o comentário automático saiu, mas e-mail de falha de workflow e de revisão ainda depende das configurações pessoais do GitHub | pequeno | aberto |
| v0.31.4 | P10 | rig paramétrico em WIP no branch `wip/rig-parametrico-3d` (voo 0,93:1; reancoragem 3/4); não entregue | médio | congelado (rig) |
| v0.31.3 | animação | primeiro quadro walk→run ~2,5 px a 60 fps (o teto do teste subiu de 2 para 3 na mesma edição) — acima do <2 px anterior | pequeno | aberto |
| v0.31.3 | caminhada | patinação residual: 110 px/s é rápido para passo de 4 tempos com perna de 20 px | médio | aberto |
| v0.31.3 | cadência | cadência subiu (~12,5 passos/s); julgar no aparelho | design | aberto |
| v0.31.3 | aparelho | revisão no celular do operador pendente | operador | aberto |
| v0.31.2 | IK 3D | alvo inalcançável extremo corrige o contato, mas a pata pode sair do alvo | médio | aberto |
| v0.31.2 | animação | `death`/`get_up` e misturas de clipes continuam deformando ossos | médio | aberto |
| v0.31.2 | aparelho | revisão das pernas traseiras no celular do operador pendente | operador | aberto |
| v0.31.1 | animação | `death`/`get_up` e misturas de clipes não preservam a rigidez de todos os ossos | médio | aberto |
| v0.31.1 | IK 3D | alvo inalcançável é limitado pelo alcance, mas a pata pode perder apoio | médio | aberto |
| v0.31.1 | aparelho | revisão das dobras e do apoio no celular do operador pendente | operador | aberto |
| v0.31.0 | transições | a 30 fps o primeiro quadro da troca fica ~3 px (o <2 px é a 60 fps); o crossfade pode borrar pernas sobrepostas | pequeno | aberto |
| v0.31.0 | sockets | a visibilidade dos sockets troca pelo clipe novo no primeiro quadro (boca/cauda podem piscar na troca) | pequeno | aberto |
| v0.31.0 | 2D | só a pele 3D mistura clipes; serpente/ave continuam no corte seco | pequeno | aberto |
| v0.31.0 | aparelho | sem teste no celular; GIFs são prova externa (Pillow) | operador | aberto |
| v0.30.0 | sockets | `boca` e `base_cauda` piscam nas fronteiras de setor (`oculto_em` é por direção) mesmo com o corpo girando suave | pequeno | aberto |
| v0.30.0 | silhueta | em 90°/270° a vista frontal vira uma linha de 16 px; em 68 px o arame 3D é mais cruzado que o 2D | design | aberto |
| v0.30.0 | sombra | com pitch 20° o cão "sobe/desce" em relação à sombra ao girar (patas em alturas diferentes) | design | aberto |
| v0.30.0 | aparelho | sem teste no celular (só headless/Xvfb softpipe) | operador | aberto |
| v0.29.0 | câmera | com 20°, as patas caem em alturas diferentes na tela (spread 5,5–7,6 px); não existe mais a base única do 2D — é a câmera escolhida | design | aberto |
| v0.29.0 | leitura | em 68 px o esqueleto 3D é mais "arame" e cruzado que o 2D, sobretudo nas diagonais; a leitura de cão é menos imediata | design | aberto |
| v0.29.0 | fase B | camadas de pixel art por osso ainda não desenhadas (só o campo `pecas` e a validação) | médio | aberto |
| v0.29.0 | rig | validação estrita de 22 juntas/21 ossos: mudar juntas exige migrar schema e testes | pequeno | congelado (rig) |
| v0.29.0 | aparelho | sem teste no celular (só headless/Xvfb softpipe) | operador | aberto |
| v0.28.0 | frontal | a anca frontal fica recuada (±4,5 px) para não colidir com a perna dianteira; o quarto largo aparece mais na vista dorsal | design | obsoleto (3D) |
| v0.28.0 | diagonais | o ombro/anca "longe" fica a ~0,5 px da linha do dorso; no zoom de 5× parece encostado, não articulado | pequeno | obsoleto (3D) |
| v0.28.0 | arte | a pele esquelética segue como prova de juntas: nada aqui é arte aprovada | decisão | aberto |
| v0.27.1 | — | nenhum | — | — |
| v0.27.0 | CI | o `preview` num PR falha ao criar o deployment do Pages: o ambiente `github-pages` só aceita `main` (`custom_branch_policies`); liberar `lote/*` em Settings → Environments → github-pages, ou revisar pelo artefato `quadros` do run | médio | resolvido v0.27.1 (sem PR: entrega direto em main; preview só na publicação) |
| v0.27.0 | animação | `Anim.retrato` lê `corpo._fator_sprint()` (método privado) só para a pose de decolagem; se o corpo trocar de API, o retrato quebra no parser | pequeno | aberto |
| v0.27.0 | pele | a mordida não tem faísca nas vistas de costas (`north`, `north-east`, `north-west`): a boca é oculta nesses setores, então o VFX falha fechado | pequeno | obsoleto (3D) |
| v0.27.0 | rig | `west`, `north-west` e `south-west` continuam espelhos dos perfis leste/nordeste; são oito setores, mas quatro desenhos base | pequeno | congelado (rig) |
| v0.27.0 | arte | a pele esquelética segue como prova de juntas: nada aqui é arte aprovada | decisão | aberto |
| v0.27.0 | cadência | 400/300/350/340 ms são ponto de partida; afinar no aparelho com o operador | design | aberto |
| v0.27.0 | ferramenta | `tools/folha_canino.gd` não tem teste automatizado próprio (o desenho tem) | pequeno | aberto |
| v0.26.3 | baseline | o artifact de 10 MB pode engasgar na rede do celular; o script tenta 2× e aceita `--zip`/`--pasta` | pequeno | aberto |
| v0.26.2 | preview | a pausa de 8 s é empírica; se o `deploy-pages` voltar a falhar, aumentar ou trocar por retry com espera | pequeno | aberto |
| v0.26.1 | preview | GIF de ~1,1 MB ainda é o arquivo mais pesado da revisão; se doer no celular, cortar quadros | pequeno | aberto |
| v0.26.0 | preview | GIF depende de `python3-pil` no runner; sem ele o comentário sai só com os quadros-chave | pequeno | aberto |
| v0.26.0 | preview | o Pages substitui a página a cada push: imagem de lote antigo dá 404 (o comentário é atualizado no lugar) | pequeno | aberto |
| v0.26.0 | preview | o branch `gh-pages` existe só porque o Pages exigiu uma origem para ser criado; o site vem de `build_type=workflow` | pequeno | aberto |
| v0.26.0 | rito | `main` continua sem proteção de branch (exige o operador em Settings → Branches); o PR é disciplina, não trava | médio | descartado (operador) |
| v0.26.0 | licença | repositório público ainda sem LICENSE — decisão do operador (MIT? todos os direitos reservados?) | decisão | descartado (operador) |
| v0.26.0 | ferramentas | `preview.mjs` e `quadros-baseline.mjs` sem teste automatizado próprio | pequeno | aberto |
| v0.25.2 | pele | esqueleto puro é para estudo de juntas; a leitura de personagem no mapa fica de propósito em segundo plano até a arte | decisão | aberto |
| v0.25.2 | foco | serpente e ave seguem sem ossos completos (pontos soltos como asas) — renderizam, mas não foram polidos | médio | obsoleto (3D) |
| v0.25.2 | sombra | a sombra elíptica do mock continua sob o esqueleto (ajuda a ler o chão) | pequeno | obsoleto (3D) |
| v0.25.1 | biomecânica | amplitudes (passo 5 px, levantar 3 px, bounce 2,8 px) são ponto de partida; afinar no aparelho com o operador | design | aberto |
| v0.25.1 | galope | sem inclinação de tronco (pitch) nem curva do dorso; só balanço vertical | médio | aberto |
| v0.25.1 | marchas | não existe o TROTE intermediário: correr pula direto ao galope | design | aberto |
| v0.25.1 | serpente | sem revisão de marcha (a ondulação já seguia a biomecânica ofídia) | pequeno | aberto |
| v0.25.0 | baseline | trocado pelos 60 quadros do CI #57 (llvmpipe) no commit seguinte ao da mudança visível | verificação | resolvido em v0.25.0 |
| v0.25.0 | animação | `shot` não é acionado no jogo (não há sinal de "acabou de atirar"); `hit`/`death` seguem dormentes | médio | aberto |
| v0.25.0 | pele | o corpo padrão é o canino; serpente e ave só entram por flag de demo | decisão | obsoleto (3D) |
| v0.25.0 | aparelho | falta o teste de toque e leitura no celular do operador (é o objetivo deste lote) | operador | obsoleto (3D) |
| v0.24.0 | módulos | só três formas provisórias (tufo, espinho, membrana) e sem rotação/encaixe fino por direção | pequeno | aberto |
| v0.24.0 | arte | módulo composto na pele geométrica; a pele de sprite (peças separadas) ainda não existe | médio | aberto |
| v0.24.0 | VFX | janela fixa de 150 ms e desenho vetorial; partículas e som reais não foram feitos | pequeno | aberto |
| v0.24.0 | regra | por contrato módulo/efeito não concede habilidade — se um dia conceder, é pacote de regra, não de arte | decisão | aberto |
| v0.23.1 | animação | `run`, `hit` e `death` têm clipe nos rigs, mas o corpo ainda não os aciona (sprint não exposto, sem vida) | médio | aberto |
| v0.23.1 | animação | 28 ações (T1/T2/T3: comer, dormir, voar, nadar…) continuam só no catálogo, sem desenho | médio | aberto |
| v0.23.1 | pulo | a máquina usa `jump_air`; `jump_start`/`jump_land` só aparecem quando a apresentação detectar a transição | pequeno | aberto |
| v0.23.1 | morte | tomba e para, mas não há vida nem renascimento: clipe dormente | design | aberto |
| v0.23.0 | animação | só `bite`, `stunned`, `dig` e `charge` têm desenho; as outras 37 ações têm catálogo mas ainda não têm clipe na pele | médio | aberto |
| v0.23.0 | animação | durações e janelas de evento são provisórias (125 ms herdado da E2); ajustar no aparelho | pequeno | aberto |
| v0.23.0 | vida/dano | `hit`/`death` existem na máquina e no catálogo, mas o jogo não tem vida: ficam dormentes | design | aberto |
| v0.23.0 | camadas | a máquina escolhe UM clipe; overlay simultâneo (comer andando) só com peças separadas de arte | design | aberto |
| v0.23.0 | corrida | andar e correr usam o mesmo clipe `walk`; `run` entra quando houver estado de sprint exposto | pequeno | aberto |
| v0.23.0 | ave/serpente | os drivers de ação (avanço/abaixar) são genéricos; ler bem nas duas anatomias ainda não foi avaliado pelo operador | médio | aberto |
| v0.22.0 | arte | pele geométrica provisória (silhuetas de ave/serpente ainda fracas); a arte real é a F5 | médio | obsoleto (3D) |
| v0.22.0 | jogo | a pele só liga na demo (`--geo-*`); o jogo normal continua no mock de xadrez | decisão | obsoleto (3D) |
| v0.22.0 | animação | só `idle`/`walk`; as demais 41 ações e a máquina de estados são a F3 | médio | resolvido v0.23.0 (máquina de estados; as ações seguem na linha v0.23.0) |
| v0.22.0 | escala | canino 68×68, serpente 96×64 e ave 64×64 sem régua de porte comum entre arquétipos | design | aberto |
| v0.22.0 | golpe | a âncora `boca` só move a ORIGEM do cone; dano, alcance e regra seguem em `sim/corpo.gd` | pequeno | obsoleto (3D) |
| v0.21.2 | arte | rigs geométricos de serpente e ave provisórios, ainda sem validação visual (depende da F2) | médio | obsoleto (3D) |
| v0.21.2 | dados/rig | escalas diferentes por família (canino 68×68, serpente 96×64, ave 64×64); a regra de porte entre arquétipos continua em aberto | design | aberto |
| v0.21.2 | dados/rig | serpente e ave só têm `idle`/`walk`; voo, nado e as demais 41 ações do catálogo ficam para a F3 | médio | aberto |
| v0.21.1 | arte | o contrato tem 8 direções, mas a arte existente tem 4 (canino) e 1 (serpente); a pele de sprite deverá declarar o subconjunto por clipe | médio | aberto |
| v0.21.0 | `dados/rig/` | só o canino; serpente e ave (as outras âncoras) ainda sem rig | médio | resolvido v0.21.2 (rigs de serpente e ave) |
| v0.21.0 | `sim/esqueleto.gd` | só `idle`/`walk`; as 43 ações do catálogo e a máquina de estados são F3 | médio | resolvido v0.23.0 (máquina de estados; as ações seguem na linha v0.23.0) |
| v0.21.0 | `jogo/` | nenhuma pele usa o esqueleto; integração visual é F2 e troca para sprite é F5 | decisão | aberto |
| v0.21.0 | docs | `ARQUITETURA.md` e `AGENTS.md` não listam `dados/rig/` nem a camada do esqueleto (árvore ocupada por outra sessão) | pequeno | resolvido v0.22.0 (`dados/rig/` no AGENTS.md e no ARQUITETURA.md) |
| v0.21.0 | combate | `hit`/`death` existem no catálogo, mas o jogo não tem regra de vida (só atordoado/empurrão) | design | aberto |
| v0.21.0 | arte | rig geométrico provisório; nada de arte aprovada e nenhuma geração PixelLab gasta | decisão | aberto |
| v0.20.2 | oráculo | 60 quadros não encenam segurar→mover; a prova desse caso é teste headless, e a divergência local q36/q37 continua pré-existente (softpipe × llvmpipe), baseline preservado | verificação | obsoleto (3D) |
| v0.20.2 | controles | o caminho nascido do segurar foi verificado em teste e em integração headless, mas ainda não no toque físico do aparelho | verificação / operador | aberto |
| v0.20.2 | `jogo/main.gd` | no desenho NORMAL, um primeiro `tracar` recusado por traço curto ainda marca `_traco_iniciado` (comportamento antigo preservado); só o recomeço do segurar espera o `ok` | pequeno | aberto |
| v0.20.1 | oráculo | comparação local softpipe divergiu em 2 de 60 quadros superiores contra baseline llvmpipe; confirmar no CI, baseline preservado | verificação | obsoleto (3D) |
| v0.20.1 | vista íntima | inclinação mais baixa e controles ainda precisam de avaliação no aparelho pelo operador; seguem as limitações visuais da v0.20.0 | verificação | aberto |
| v0.20.0 | `jogo/main.gd` | primeiro dedo na HUD seguido de segundo no mundo não é reconhecido como pinça; tratamento seguro requer testar propagação real e preservar botões | médio | aberto |
| v0.20.0 | `jogo/mock.gd` | marcas, efeitos, perigos e adversários em terreno elevado interpolam da posição histórica ao topo: nas inclinações intermediárias não coincidem exatamente com o topo | visual | obsoleto (3D) |
| v0.20.0 | controles | vista íntima não tem gestos definidos para ataque ou salto; pinça e controle relativo precisam de teste no aparelho | decisão / operador | aberto |
| v0.20.0 | oráculo | quadros capturados não mostram marcas ou efeitos sobre planalto; continuidade verificada em teste numérico, não visualmente; baseline CI não atualizado | verificação | obsoleto (3D) |
| v0.19.0 | `jogo/hud.gd` | o **slider** da carga é **runtime-only**: o valor **não é salvo** entre aberturas — cada partida começa em `combate.tiro_carga_s` (0,5 s); salvar configuração é da UI real | pequeno | descartado (operador) |
| v0.19.0 | `dados/acoes.json` | o **padrão 0,5 s** e a **faixa 0–1,5 s** do slider (`tiro_carga_s`/`tiro_carga_max_s`) são **pontos de partida** — ajustar no aparelho com o operador | pequeno | aberto |
| v0.19.0 | `sim/corpo.gd` | o **tamanho** do tiro é **linear no tempo** (`carga_tiro_s / tiro_carga_max_s`): a faixa toda só dá **2× no empurrão** e **1,5× no raio** — o padrão 0,5 s já é **1/3 do ganho**, não um tiro "fraco" | design | aberto |
| v0.19.0 | `sim/corpo.gd` | o **instantâneo (0 s)** não tem estado de carga: dispara dentro do próprio comando (`"ok: tiro"`), então a HUD **não** mostra "CARREGANDO" nem barra/anel nesse caso | pequeno | aberto |
| v0.19.0 | `sim/gestos.gd` | o toque espera a janela do duplo (**280 ms**) **antes** de começar a carga: com o preparo em 0 s o tiro ainda sai ~0,28 s depois do dedo | design | aberto |
| v0.19.0 | `sim/corpo.gd` | sem rota e sem alvo o toque é `"recusado: sem destino"` e a carga nem começa — não se atira "no dedo"; o tiro depende do destino final do caminho | decisão | aberto |
| v0.19.0 | `jogo/hud.gd` | o **slider**, o rótulo da carga, a barra amarela, o anel na criatura e o botão **CONFIG** são **mockup** de desenvolvimento — a UI real decide depois | arte (P6/P7) | aberto |
| v0.19.0 | oráculo | os 60 quadros do CI cobrem só os 2 primeiros segundos; o slider/CONFIG e o preparo pedem a demo inteira (~480 quadros) para o olho | operador | aberto |
| v0.19.0 | `testes/baseline/` | baseline atualizado com os 60 quadros do **CI #45** (`llvmpipe`, commit `49b9810`); o CI #45 reprovou só no diff (CONFIG/rótulo/slider/linha nova) — prova de que a mudança era visível | pequeno | resolvido em v0.19.0 |
| v0.18.0 | `dados/acoes.json` | a **rampa** `rota.rampa_s` 0,30 s e a **carga** `combate.tiro_carga_s` 1,0 s são **pontos de partida** — ajustar no aparelho | pequeno | removido em v0.19.0 (a carga de 1,0 s; a rampa segue) |
| v0.18.0 | `sim/gestos.gd` | o toque simples espera a janela do duplo (280 ms) para o primeiro toque de um duplo não **atirar** antes do PULO; a pausa de saída (que pulava a espera) foi removida em v0.18.0 | design | aberto |
| v0.18.0 | `sim/corpo.gd` | o tiro do toque é **sempre de carga cheia** (1,0): 9/280/24 são o **dado bruto** do projétil e o disparo sai **13,5/448/48**; não existe tiro fraco | design | removido em v0.19.0 |
| v0.18.0 | `sim/corpo.gd` | sem rota e sem alvo o toque é `"recusado: sem destino"` e a carga nem começa — não se atira "no dedo"; o tiro depende do destino final do caminho | decisão | aberto |
| v0.18.0 | `sim/corpo.gd` | sem caminho o segurar **cava** (habilidade) em vez de correr: na perseguição final/sem rota não há sprint | decisão | aberto |
| v0.18.0 | `jogo/hud.gd` | o texto `CARREGANDO %`, a barra amarela acima da energia e o anel na criatura são **mockup de desenvolvimento** — a UI real decide depois | arte (P6/P7) | aberto |
| v0.18.0 | oráculo | os 60 quadros do CI cobrem só os 2 primeiros segundos; a demo inteira (~480 quadros) pede o olho do operador para as cenas novas (rampa/toque/carga/segurar) | operador | aberto |
| v0.18.0 | `testes/baseline/` | baseline atualizado com os 60 quadros do **CI #43** (`llvmpipe`, commit `0591201`); o CI #43 reprovou só no diff (legenda/demo novas) — prova de que a mudança era visível | pequeno | resolvido em v0.18.0 |
| v0.18.0 | `sim/` | a **v0.17 foi revertida** por decisão do operador: a pausa de saída, a arrancada curta do toque e o tiro no soltar do segurar não existem mais; as linhas v0.17 abaixo ficam como história | decisão | resolvido em v0.18.0 |
| v0.17.0 | `dados/acoes.json` | os tempos da v0.17 (pausa 0,35 s · segurar 0,2/0,38 s · carga 1,0 s · multiplicadores 1,6/1,5/2,0 · arrancada 0,6 s) são **pontos de partida** — ajustar no aparelho | pequeno | removido em v0.18.0 |
| v0.17.0 | `sim/gestos.gd` | fora da pausa o toque simples fica pendente até a janela do duplo (280 ms) para o primeiro toque de um duplo não correr antes do PULO; se o operador quiser resposta imediata, é mexer nessa janela e o PULO sofre | design | removido em v0.18.0 |
| v0.17.0 | `sim/corpo.gd` | a carga conta do **limiar** do segurar (200 ms na pausa, 380 ms fora), não do encostar: a carga cheia chega ~1 s depois do limiar, não do dedo | pequeno | removido em v0.18.0 |
| v0.17.0 | `sim/corpo.gd` | soltar o segurar durante a recarga (1 s) **cancela** a caminhada mas **não dispara** (caso raro): a caminhada cancelada continua cancelada e o tiro é recusado | pequeno | removido em v0.18.0 |
| v0.17.0 | `jogo/hud.gd` | a barra de carga amarela acima da energia e o anel de carga na criatura são **mockup de desenvolvimento** — a UI real decide depois | arte (P6/P7) | aberto |
| v0.17.0 | oráculo | os 60 quadros do CI cobrem só os 2 primeiros segundos; as cenas novas (pausa/segurar/toque/carga) pedem a demo inteira (~480 quadros) para o olho | operador | aberto |
| v0.17.0 | `testes/baseline/` | baseline atualizado com os 60 quadros do **CI #41** (`llvmpipe`, commit `3b01634`); o CI #41 reprovou só no diff (3,28% na legenda, 6,14% no último quadro pela pausa) — prova de que a mudança era visível | pequeno | resolvido em v0.17.0 |
| v0.16.1 | — | nenhum | — | — |
| v0.16.0 | `testes/baseline/` | baseline versionado (~9,6 MB) cresce a cada lote que muda o visível: cada atualização guarda 60 PNGs novos no histórico; avaliar poda/compressão se o repositório pesar | pequeno | resolvido (2026-11-25: baseline fora do git, referência = artefato da última publicação) |
| v0.16.0 | `testes/baseline/` | o baseline é do `llvmpipe` do runner; troca de runner, driver ou versão do Godot pode exigir atualizar o baseline no lote que a fizer | pequeno | resolvido v0.35.0 (baseline fora do git: a referência é a última publicação) |
| v0.16.0 | `tools/quadros-diff.mjs` | o diff pega mudança objetiva de pixels, não juízo fino de arte: o olho do operador continua sendo o aceite visual | limite | aberto |
| v0.15.0 | `sim/afinidade.gd` | a afinidade **não está ligada ao `jogo/`**: no aparelho a criatura continua obedecendo; ligar é P7 | decisão | aberto |
| v0.15.0 | `dados/afinidade.json` | traços, pesos, limiar, atraso, desvio e ganhos são **pontos de partida** — ajustar no aparelho | pequeno | aberto |
| v0.14.4 | docs | protocolo padrão ainda não replicado no repo do Áudio Visual IASD | pequeno | aberto |
| v0.14.3 | documentação | o protocolo de agentes é deste repositório; o projeto Áudio Visual IASD ainda não tem o mesmo guia — replicar lá é lote de outro repositório | pequeno | aberto |
| v0.14.2 | documentação | o guardião cobre estrutura e os dois toques, não toda divergência semântica; formatos Markdown suportados e limites em `docs/DOCUMENTACAO.md` | limite | aberto |
| v0.14.2 | lint | o repositório não tem configuração de linter JS; sintaxe e comportamento do guardião são verificados por Node (`--check` e testes) | pequeno | aberto |
| v0.14.0 | `dados/adversario.json` | preparos, alcances, empurrões e atordoamentos são **pontos de partida** — ajustar no aparelho | pequeno | aberto |
| v0.14.0 | `sim/adversario.gd` | o inimigo continua o **mockup roxo**, sem sprite de bote/esbarrão/cuspe/esconder: a leitura é pela área no chão, aura, "!" e montinho de terra | arte (P6/P7) | aberto |
| v0.14.0 | `sim/adversario.gd` | o **esconder** só dispara ao **levar um golpe** (recarga 7 s); um ataque que ERRA não o faz se esconder | design | aberto |
| v0.14.0 | `sim/corpo.gd` | o **atordoamento** não cancela um golpe seu já em curso (ele termina), só o sprint; a rota fica guardada | pequeno | aberto |
| v0.14.0 | `jogo/perigos.gd` | a demarcação tem **três formas** (círculo/faixa/linha); um ataque novo (cone, vários círculos) precisa de forma nova | pequeno | aberto |
| v0.14.0 | `sim/adversario.gd` | o acerto **não checa altura**: um bote/cuspe de cima de um barranco de 1 nível alcança quem está embaixo (o esbarrão para na borda) | pequeno | aberto |
| v0.14.0 | oráculo | a cena hostil exige `DEMO_ARGS="--hostil"`; os 60 quadros do CI mostram o começo do demo normal, **sem hostilidade** | pequeno | descartado (operador) |
| v0.13.0 | `sim/corpo.gd` | o pulo automático só sobe degrau de **1 nível**; **descer** degrau, água no mesmo nível e degrau de 2+ níveis continuam no toque duplo | decisão | aberto |
| v0.13.0 | `jogo/hud.gd` | o botão PULO AUTO é HUD de desenvolvimento (por cima do mapa) e **não persiste** entre aberturas: cada partida começa em `pular.auto_padrao` (falso) | pequeno | descartado (operador) |
| v0.13.0 | `sim/corpo.gd` | o alcance do pulo automático é estimado (`velocidade × fatores × 0,42 s × 0,9`), não simulado: numa rota muito curva ou no limite do vão o sistema pode não disparar (fica o toque duplo) ou disparar no último quadro | pequeno | aberto |
| v0.13.0 | `dados/acoes.json` | `pular.sprint_fator` 1,5 (pulo ~3,1 células) e a margem 0,9 do alcance são pontos de partida — ajustar no aparelho; com sprint o pulo pode passar do pouso em plataforma curta | design | aberto |
| v0.13.0 | oráculo | o botão aparece nos quadros, mas o demo não **clica** nele; a regra do automático é provada pelos testes e por simulação, não por quadro | pequeno | aberto |
| v0.12.0 | `dados/mapas/fundacao.json` | a extensão é só MOCKUP: trilha/passarela/rampa alta/plataforma ainda não têm arte (P6); a área também não tem decoração (árvore, pedra) | design | aberto |
| v0.12.0 | `jogo/main.gd` | não há atalho para a área de parkour: chega-se pelo túnel ou pelo pulo do canal e atravessando a ilha leste — dá ~40 s de caminhada desde o início | decisão | aberto |
| v0.12.0 | `sim/mundo.gd` | o vão de 2 células não tem regra própria: exige **pulo emendado ou sprint**; quem cai na água depende de outro pulo (é a regra que já existia) | design | aberto |
| v0.12.0 | `docs/gdd/mapa.md` | não há checkpoint/reset na extensão: sair da trilha é voltar andando ou pulando pela água até uma plataforma | pequeno | aberto |
| v0.11.5 | `dados/acoes.json` | com `formas.laco_ataque` falso, `formas.laco_*`, `formas.gatilho_raio_px` e `combate.onda_*`/`area_gatilho_px` ficam **sem uso** — voltam junto se a onda for religada | decisão | aberto |
| v0.11.5 | `sim/corpo.gd` | o ramo `laco` de `_checar_marcas`/`_disparar` e o desenho da onda em `jogo/efeitos.gd` ficam **parados** (código morto atrás do interruptor); só o teste com a chave ligada os exercita | decisão | aberto |
| v0.11.5 | `sim/formas.gd` | desenhar um círculo agora só anda em círculo: um traço que volta sobre si mesmo **não é encurtado** pelo leitor de formas (quem trata vai-e-volta curto é o `limpar_amontoados`) | pequeno | aberto |
| v0.11.4 | HUD (`jogo/hud.gd`) | com o zoom 1,6 o mapa ocupa a tela inteira e a **legenda GESTOS** passa a ficar **por cima do mapa** (antes caía no fundo azul); é HUD de desenvolvimento — some com a UI real | pequeno | aberto |
| v0.11.4 | `jogo/mock.gd` | o `ZOOM` 1,6 é **fracionário**: 1 px de arte vira 1–2 px de tela. No xadrez do mock não se nota; com a **arte real** (P6) é preciso decidir — arte desenhada em 2× ou voltar a um zoom inteiro (1 ou 2) | design | obsoleto (3D) |
| v0.11.4 | `sim/corpo.gd` | a **cauda do sprint** é queda linear de 0,60 s (1,7× → 1,0×): soltar o segurar ainda empurra o animal por ~40 px; `sprint.cauda_s` é ponto de partida | pequeno | aberto |
| v0.11.4 | `sim/corpo.gd` | a **fila do pulo** guarda UM pedido por `pular.buffer_s` (0,60 s): dois toques duplos no MESMO ar não empilham dois pulos (o segundo é ignorado) | decisão | aberto |
| v0.11.4 | `sim/corpo.gd` | a marca é validada na ponta **só enquanto o caminho é desenhado**; depois de soltar ela viaja com o alvo — passar por cima e SEGUIR já não a deixa nascer (o alvo é reavaliado a cada traço) | decisão | aberto |
| v0.11.4 | `sim/gestos.gd` | o **toque simples (tiro)** continua pendente 280 ms até a janela do duplo; o pedido era o pulo, então esse atraso não foi mexido | design | aberto |
| v0.11.3 | `jogo/trilha.gd` | o corte da linha é a projeção do corpo no **traço cru** (não na rota): no tremor inicial/amontoado e num cruzamento ele pode apagar um pouco antes/depois da passagem; nunca volta | pequeno | aberto |
| v0.11.3 | `sim/corpo.gd` | o contorno de **desnível** exige um ponto da rota em nível **≤ base + 0,5** a até 128 px/260 px; uma rota que termina no **topo** do barranco para na fronteira (o pulo sobe/desce) | decisão | aberto |
| v0.11.3 | `sim/corpo.gd` | a suavização **atrasa** a curva (720°/s); o bico/cantos ficam um pouco mais arredondados; o passo real ainda pode dar **1–2 viradas** de ~80–100° no início do contorno (uma vez), mas a direção desenhada não pisca | pequeno | aberto |
| v0.11.3 | `sim/corpo.gd` | `_dir_suave`/`_olhar_suave` valem no **caminho**; a perseguição final e a autonomia continuam com a direção direta (não foram suavizadas) | design | aberto |
| v0.11.3 | `dados/acoes.json` | `giro_suavidade` 10 e `giro_max_graus_s` 720 são pontos de partida — mais baixo = mais suave/atrasado; ajustar no aparelho | pequeno | aberto |
| v0.11.2 | `sim/corpo.gd` | o contorno de terreno exige um ponto **andável da ROTA** a até 128 px do animal e 260 px de arco: um lago/rocha maior, ou um rio largo sem volta, ainda **para na fronteira** (o pulo atravessa) | decisão | aberto |
| v0.11.2 | `sim/corpo.gd` | a **ALTURA** (planalto/rampa) não entra no contorno de água/rocha: continua sendo barreira que para e espera (o contorno usa `bloqueio`, e altura é `pode_andar`) | design | aberto |
| v0.11.2 | `sim/corpo.gd` | se o desvio real precisar de mais de 36 passos **sem a projeção andar 6 px**, a teimosia para antes — um lago grande com a volta longe pode dar `barrado` cedo | pequeno | aberto |
| v0.11.2 | `sim/corpo.gd` | o contorno é o **leque guloso** (o mesmo do tronco): bolsões de várias pedras em quina ainda podem deter a criatura (ela para, não atravessa) | design | aberto |
| v0.11.1 | `sim/corpo.gd` | o **desvio de tronco** é guloso (leque de ângulos + lado mantido): num **bolsão de 3+ troncos em quina** ainda pode ficar indo e volta na beirada; uma busca BFS local foi tentada e ficou fora (o resultado era pior e mais caro) | design | aberto |
| v0.11.1 | `sim/corpo.gd` | o **TIRO sem marca** vai na direção do toque **sem assistência**: toque atrás do animal atira para trás; toque em cima usa o olhar | decisão | resolvido v0.18.0 (a direção do tiro nunca é o toque) |
| v0.11.1 | `sim/corpo.gd` | o avanço da projeção tem teto por quadro (`esperado×4`, mínimo 24 px): em dt muito grande (travada de FPS) a criatura pode "segurar" o progresso por 1 quadro — não perde a rota | pequeno | aberto |
| v0.11.1 | `sim/corpo.gd` | a ponta do bico é arredondada em ~3 px (o passo de 3,7 px passa da ponta antes de a projeção virar) — não trava, mas não é um canto perfeito | pequeno | aberto |
| v0.11.1 | `sim/trajetoria.gd` | o amontoado é medido por 24 px/100 px de arco: um **bico de até ~48 px** e um laço de ~15 px de raio são cortados (decisão: nessa escala é tremida, não desenho) | design | aberto |
| v0.11.1 | `sim/corpo.gd` | a INÉRCIA passa do último ponto (`freio_extra_px` 16 px; 26 px no sprint): o animal termina um pouco além da ponta do traço | decisão | aberto |
| v0.11.1 | `dados/acoes.json` | `freio_extra_px` 16, `freio_sprint_x` 1,6, `amontoado_*` 24/100 e os mínimos do laço (2200/160/28) são pontos de partida — ajustar no aparelho | pequeno | aberto |
| v0.11.1 | `sim/formas.gd` | o laço pequeno não acende a área, mas o traço ainda é lido (custa o RDP dos laços a cada ~5 pontos); não foi medido no aparelho | pequeno | aberto |
| v0.11.0 | `sim/formas.gd` | o **bico** não é mais reconhecido: o espinho é andado como qualquer traço (sem ataque próprio) — se o operador quiser um efeito no bico, é conteúdo novo | decisão | aberto |
| v0.11.0 | `sim/gestos.gd` | o **toque simples (tiro) fica pendente** até a janela do duplo (280 ms): o tiro sai ~0,28 s depois do toque | decisão | aberto |
| v0.11.0 | `sim/corpo.gd` | o **SPRINT só existe dentro de um caminho**: na perseguição final (sem rota) o segurar cava (se a célula for escavável) em vez de acelerar | decisão | aberto |
| v0.11.0 | `sim/corpo.gd` | a **barra de energia** é uma só (`energia` 0..1): gasto 0,45/s (~2,2 s de sprint cheio) e recarga 0,22/s são pontos de partida | pequeno | aberto |
| v0.11.0 | HUD | a barra de energia fica em cima do `estado`, à esquerda; em tela muito baixa pode encostar nos rótulos | pequeno | aberto |
| v0.10.0 | `sim/formas.gd` | o **bico** continua sendo lido e o beco sai da rota, mas **não atira mais** (o tiro é o toque duplo): o gesto ficou sem efeito — decidir com o operador se sai de vez | design | resolvido v0.11.0 (o bico saiu do leitor de formas) |
| v0.10.0 | `sim/gestos.gd` | o **toque simples fica pendente** até a janela do duplo (280 ms): o pulo sai ~0,28 s depois do toque | decisão | resolvido v0.11.0 (o pulo foi para o toque duplo) |
| v0.10.0 | `sim/corpo.gd` | a marca está **ligada ao caminho**: um caminho novo a apaga; o alvo pode andar à vontade (o animal persegue), não há mais a perda por 48 px | decisão | aberto |
| v0.10.0 | `sim/corpo.gd` | a perseguição final tem teto (`perseguir_s` 3 s): barrada (água/altura) ou lenta demais, a marca se perde (`mira_final:perde`) | design | aberto |
| v0.10.0 | `sim/corpo.gd` | o tiro mira na posição do alvo **no disparo** (projétil reto): se ele andar durante o voo, pode errar | design | aberto |
| v0.10.0 | `dados/acoes.json` | `area_gatilho_px` 224 (≈7× o corpo de 32 px) é ponto de partida; o "tamanho do animal" pode ser o sprite de 64 px — ajustar no aparelho | pequeno | aberto |
| v0.10.0 | demo | o caminho do demo vai em "L" para desviar do planalto (a criatura não sobe andando); o golpe final do roteiro depende de o alvo estar alcançável | — | aberto |
| v0.10.0 | oráculo | 45 quadros 720×1280 em ~3 min (~4 s/quadro) com a linha pontilhada no `softpipe` local; o CI grava 60 e passa | pequeno | obsoleto (3D) |
| v0.10.0 | `sim/corpo.gd` | o `travar`/`alvo_id` (mira vermelha) e o **baú** ficaram **sem gesto**: o toque agora é o PULO; decidir se o baú ganha outro gatilho | design | aberto |
| v0.9.2 | `jogo/trilha.gd` | a linha mostra o traço CRU do dedo (inclusive o tremor inicial e o beco do bico), não o rastro do animal; é uma decisão, não um defeito | design | aberto |
| v0.9.2 | `jogo/trilha.gd` | os pontinhos são círculos em coordenadas de mundo (sem snap de pixel): em telas de zoom fracionário podem sair levemente borrados | pequeno | obsoleto (3D) |
| v0.9.2 | `sim/corpo.gd` | a marca do especial durante a recarga fica PENDENTE; se a criatura sair do anel/perto da base, ela não acende mais (é consumida no fim da rota) | decisão | aberto |
| v0.9.2 | `sim/corpo.gd` | o embalo é um multiplicador de velocidade do passo (pico `sin`); 0,25 s/1,7× e 0,6 s/2,0× são pontos de partida — ajustar no aparelho | pequeno | aberto |
| v0.9.2 | `sim/corpo.gd` | a marcação embala uma vez por marca (`_embalo_final_feito`); se a criatura for barrada depois do embalo, ele não repete ao retomar | design | aberto |
| v0.9.2 | oráculo | a linha pontilhada são dezenas de `draw_circle` por quadro: no `softpipe` local cada quadro caiu para ~4,5 s (33 quadros em ~2,5 min); no aparelho/CI a GPU resolve — medir no celular | pequeno | aberto |
| v0.9.1 | `sim/formas.gd` | a BASE do bico é o ponto do traço mais perto da volta: num "T" a volta entra na estrada e a base pode ficar alguns px dentro da boca do beco | design | resolvido v0.11.0 (o bico saiu do leitor de formas) |
| v0.9.1 | `sim/formas.gd` | a base é achada por uma CURVA (≥ 45°) na volta; se o dedo reencontrar a estrada numa curva muito suave, o bico pode não ser lido (o fim do traço tem a regra própria) | pequeno | resolvido v0.11.0 (o bico saiu do leitor de formas) |
| v0.9.1 | `sim/corpo.gd` | a estrada é um alvo À FRENTE + senoides; os valores (largura 30, desvio 9, ondas 120/47, freio 44) são pontos de partida — ajustar no aparelho | pequeno | aberto |
| v0.9.1 | `sim/corpo.gd` | o desvio de tronco mantém o LADO escolhido até passar: pode dar a volta pelo lado mais longo, mas não fica oscilando | design | aberto |
| v0.9.1 | `sim/corpo.gd` | quando a rota acaba DURANTE o desenho, o alvo final usa a posição ATUAL do inimigo (não a do soltar): é o que permite o golpe final com traço ao vivo | decisão | aberto |
| v0.9.1 | `sim/corpo.gd` | o bico pausa 0,25 s: a pausa também congela a autonomia/rota por um instante (o mundo continua) | decisão | resolvido v0.10.0 (`bico_pausa_s` saiu) |
| v0.9.1 | demo | o beco do demo virou um "T" no meio do caminho; o golpe final do roteiro depende de a criatura chegar perto do adversário | — | aberto |
| v0.9.1 | `sim/corpo.gd` | a leitura das formas refaz o RDP/laços e a busca do bico sobre o TRAÇO INTEIRO a cada ~5 pontos desenhados; o custo não foi medido no aparelho | pequeno | aberto |
| v0.9.1 | oráculo | 180 quadros 720×1280 em ~5 min (~1,7 s/quadro); a demo agora passa dos 19 s (o golpe final do roteiro fica fora dos 180) | operador | obsoleto (3D) |
| v0.9.0 | `sim/formas.gd` | a base do bico é o ponto onde a VOLTA reencontra o caminho (ou a partida, se o traço acaba na volta): num bico desenhado no MEIO de uma reta, a base pode sair alguns px antes do ponto exato | design | resolvido v0.11.0 (o bico saiu do leitor de formas) |
| v0.9.0 | `sim/formas.gd` | um laço é lido no traço reduzido (RDP 3 px) e um bico no traço amostrado (6 px): desenhos minúsculos (laço < 700 px², espinho < 18 px) não contam — limiares em `formas` | pequeno | aberto |
| v0.9.0 | `sim/corpo.gd` | a onda e o tiro só atingem ADVERSÁRIO (quem sabe reagir); árvore leva a batida de travessia mas não reage | design | aberto |
| v0.9.0 | `sim/corpo.gd` | o laço acende na passagem pelo nó; se a criatura já estiver DEPOIS do nó quando a forma é reconhecida, ele acende na volta (é o mesmo ponto) — e a onda não espera a criatura chegar ao centro | decisão | aberto |
| v0.9.0 | `sim/corpo.gd` | o bico acende na base; se a forma só é reconhecida com a criatura já DENTRO do espinho, ela acende ali (por isso o tiro pode sair ~30 px depois da base) | decisão | resolvido v0.11.0 (o bico saiu do leitor de formas) |
| v0.9.0 | `sim/corpo.gd` | `_checar_marcas` dispara por PROXIMIDADE: se a rota for barrada antes da marca, o ataque não acontece | design | aberto |
| v0.9.0 | `sim/corpo.gd` | as formas são lidas a cada ~5 pontos do traço; num traço muito curto o laço/bico pode ser lido um quadro depois (sem prejuízo de regra) | pequeno | aberto |
| v0.9.0 | `sim/corpo.gd` | o golpe final divide a máquina de golpe com a batida: se um golpe já está em curso, o empurrão sai mas o arco não aparece | pequeno | aberto |
| v0.9.0 | demo | o roteiro é um SHOWCASE, não teste: se o adversário andar muito, a marca do alvo final do demo pode se perder (o log mostra `mira_final:perde`) | — | aberto |
| v0.9.0 | oráculo | 150 quadros 720×1280 em ~3 min 50 s (~1,5 s/quadro) neste celular; a demo completa (~17 s) pede ~510 quadros (~13 min) | operador | obsoleto (3D) |
| v0.9.0 | `docs/HISTORICO.md` | a nota do lote cita a demo; números de quadros medidos localmente, não no CI | — | aberto |
| v0.8.0 | `dados/acoes.json` | ~~a `esquiva` ficou sem gesto~~ — **removida na v0.9** (esquivar é andar) | — | resolvido em v0.9.0 |
| v0.8.0 | `sim/gestos.gd` | ~~espalhamento vertical lido como ataque/defesa~~ — **não há mais gesto de dois dedos na v0.9** | — | resolvido em v0.9.0 |
| v0.8.0 | `jogo/main.gd` | ~~ação durante o desenho devolve o tempo~~ — **não há mais ação de dois dedos na v0.9** | — | resolvido em v0.9.0 |
| v0.8.0 | `sim/gestos.gd` | ~~ação lida no dedo extra~~ — **fora na v0.9** | — | resolvido em v0.9.0 |
| v0.7.1 | `jogo/main.gd` | ~~linha da rota pisca no começo de um risco~~ — **o risco deixou de existir na v0.8** (dois dedos) | — | resolvido em v0.8.0 |
| v0.7.1 | `sim/corpo.gd` | ~~`voltar_rota` não devolve a posição~~ — **função removida na v0.9** (não há cancelamento de traço) | — | resolvido em v0.9.0 |
| v0.7.0 | `dados/gestos.json` | `desenho.ganho` 1,6, véu 0,22 e rampa 0,45 s são pontos de partida — ajustar com o operador no aparelho | pequeno | aberto |
| v0.7.0 | `sim/gestos.gd` | ~~risco rápido disparava ação~~ — **substituído na v0.8** (ataque é 2 dedos) | — | resolvido em v0.8.0 |
| v0.7.0 | `jogo/main.gd` | o traço ao vivo refaz a rota (desconto + Douglas-Peucker) a cada quadro; custo não medido no aparelho | pequeno | aberto |
| v0.7.0 | demo | ~~cada risco também vira caminho e empurra a criatura~~ — **corrigido na v0.7.1** (o risco cancela o traço) | — | resolvido em v0.7.1 |
| v0.7.0 | `sim/corpo.tracar` | a "volta ao começo" só entra no 1º quadro do traço; depois disso ela segue a rota e não volta | design | aberto |
| v0.7.0 | HUD | legenda e estado continuam de desenvolvimento; o estado longo pode encostar na borda no retrato | pequeno | aberto |
| v0.6.1 | atualizador | a v0.5.0 instalada tem o código antigo e não mostra o botão; instalar o APK da v0.6.1 à mão **uma vez** | operador | aberto |
| v0.6.1 | atualizador | o painel abre sozinho só na primeira detecção da sessão; depois fica o botão | design | aberto |
| v0.6.1 | atualizador | layout verificado por sonda headless e tela real, não por teste no runner síncrono | pequeno | aberto |
| v0.6.1 | APK 0.6.0-b14 | o 0.6.0 tem o mesmo defeito de layout do aviso; não serve para atualizar — usar o 0.6.1-b15 | operador | aberto |
| v0.6.0 | especiais | os dois lados usam o MESMO golpe lateral genérico; o conteúdo por criatura/evolução é P4/P5 | design | aberto |
| v0.6.0 | `dados/gestos.json` | `planejamento.escala_tempo` 0,35× é um ponto de partida; ajustar com o operador | pequeno | aberto |
| v0.6.0 | `sim/trajetoria.descontar_inicio` | o corte pode endireitar uma curva inicial quando a reta é andável; `raio`/`janela` são ajustáveis | pequeno | aberto |
| v0.6.0 | `sim/corpo._primeiro_bloqueio` | desvio local só contorna OBJETO; parede côncava/longa para a criatura (de propósito) | design | aberto |
| v0.6.0 | pulo | pular de dentro da água é permitido e não há natação/dano; cair na água exige outro pulo | design | aberto |
| v0.6.0 | `sim/mundo.limitar_caminho` | ficou sem uso no corpo (só o teste cobre); decidir remover ou reaproveitar | pequeno | aberto |
| v0.6.0 | HUD | legenda/estado ainda de desenvolvimento; estado longo pode encostar na borda no retrato | pequeno | aberto |
| v0.6.0 | Android | `window/handheld/orientation=1` depende do manifesto gerado; o `exportar.sh` imprime `screenOrientation` no CI, mas o agente não instala o APK | operador confirma no aparelho | aberto |
| v0.6.0 | `jogo/atualizador.gd` | painel reorganizado para retrato, mas não visto com uma atualização real | pequeno | aberto |
| v0.6.0 | gestos | o caminho exigia SEGURAR antes e o arrasto rápido era ação — **suplantado na v0.7.0** (caminho ao vivo + risco) | — | resolvido v0.7.0 (suplantado) |
| v0.6.0 | demo | o toque no adversário móvel pode falhar se ele andar > 110 px; a demo é roteiro, não teste | pequeno | aberto |
| v0.6.0 | oráculo | 60 quadros locais em ~1 min 46 s; a demo completa (~16 s) pede ~480 quadros / ~15 min | operador | obsoleto (3D) |
| v0.1.0 | `jogo/main.gd` `_draw` | traço de 1 px sai com falhas nas diagonais (snap de vértice + `draw_polyline` largura 1) | pequeno — trocar por desenho por pixel (Bresenham) ou largura 2 quando a arena chegar (P3) | resolvido v0.9.2 (a linha virou pontilhada em `jogo/trilha.gd`) |
| v0.1.0 | `ci.yml` | ~~oráculo llvmpipe/x86_64 não provado~~ — **resolvido**: CI #1 (`cfdbb34`) verde com o passo de quadros | — | resolvido em v0.1.0 |
| v0.1.1 | cofre / histórico da sessão | a chave do PixelLab passou pelo chat: está no log da sessão de 2026-11-20 | operador gera chave nova e troca no cofre; agente reinicia/confirma com `get_balance` | aberto |
| v0.3.0 | jogo | sem altura nem colisão: a criatura anda sobre o mar e sobe o planalto como chão | P3/P4 (ver `docs/gdd/mapa.md`) | resolvido v0.4.0 (mundo em camadas: altura e andável) |
| v0.3.0 | `arte/criaturas/cao_base_prova.png` | sprite de LADO num mapa visto de CIMA | P6 decide a vista da criatura | obsoleto (3D) |
| v0.5.0 | movimento | pular é só VISUAL: não atravessa água/vão (a rota é cortada e ela para na beira) | decidir com o operador se o pulo deve vencer vãos | resolvido v0.6.0 (o pulo atravessa e retoma a rota) |
| v0.5.0 | combate | golpe desenha o cone mas não acerta nada (sem vida/dano por decisão do operador) | P4/P7 | resolvido v0.9.0 (onda e tiro empurram o adversário; vida segue fora) |
| v0.5.0 | `jogo/main.gd` | a lista de alvos é reconstruída só ao abrir (objetos fixos) e sincronizada a cada quadro | ok enquanto nada nasce/morre em jogo | aberto |
| v0.5.0 | interação | o baú só muda de cor; não há conteúdo nem inventário | design (P8) | aberto |
| v0.4.0 | verificação | o modelo da sessão não lê imagem: quadros conferidos por amostragem de pixels, não por olho | operador confirma o APK; ou delegar a um agente com visão | aberto |
| v0.4.0 | mockup | a criatura de xadrez ocupa ~40 px do canvas de 64 (margem de pose); só mock | some quando a arte real entrar | obsoleto (3D) |
| v0.4.0 | copas | a transparência da copa usa a distância no CHÃO, sem o desnível do planalto | relevante se houver árvore em dois níveis | obsoleto (3D) |
| v0.4.0 | demo | não cobre alvo (não há inimigos) nem afinidade (P4) | P4, P7 | aberto |
| v0.4.0 | `jogo/mapa.gd` + `sim/mapa.gd` + `ilha_teste.json` | renderizador Wang do v0.3 ficou PARADO (sem uso) | decidir: manter para a arte futura ou remover | aberto |
| v0.3.1 | atualizador | o caminho Android (shell_open → FileProvider → instalador) foi conferido no código do Godot, NÃO num aparelho | o operador reinstala uma vez e testa a próxima atualização | aberto |
| v0.3.1 | git (público) | `tools/android/galapago-dev.keystore` + senha seguem no histórico | revogado na prática; nunca reutilizar | aberto |
| v0.3.0 | `tools/pixellab-tileset.mjs` | com o job FALHO no servidor, fica esperando ~2,5 min em vez de falhar logo | pequeno — espera limitada a 45 s; a API não expõe status | resolvido em v0.16.1 |
| v0.3.0 | `arte/cenarios/objetos/arvore.png` | sombra desenhada na arte (desligamos a nossa para não dobrar) — as outras artes não têm | P6: padronizar (sombra sempre nossa) | obsoleto (3D) |
| v0.2.0 | `ci.yml` | Actions avisa: `checkout@v4`, `setup-java@v4`, `cache@v4` ainda miram Node 20 (forçadas a Node 24) | pequeno — subidas para v7/v6/v6 | resolvido em v0.16.1 |
| v0.2.0 | `tools/android/exportar.sh` passo 5 | no CI #6 o `apksigner verify` não imprimiu linha (o `aapt` sim); a assinatura foi conferida localmente com `keytool -printcert -jarfile` | pequeno — `--verbose`, `2>&1` e queda para `keytool` | resolvido em v0.16.1 |
| v0.2.0 | `export_presets.cfg` | pacote `com.projetogalapago.jogo` e keystore de dev são provisórios; trocar qualquer um obriga desinstalar | decidir antes da 1ª distribuição externa | aberto |
| v0.2.0 | P2 | o APK não foi testado em aparelho pelo agente (instalar é do operador) | o operador instala e risca | aberto |
| v0.1.1 | `arte/fonte/p1-cao-base-pixen.png` | prova sem paleta-mestra (64 cores livres) e câmera ainda não decidida — não é asset do jogo | resolve no P6 (âncora de arte) | aberto |
