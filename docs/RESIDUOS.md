# Resíduos — o que o lote viu e não consertou

> Toda versão deixa uma linha aqui antes do push, mesmo que seja "nenhum".

| versão | onde | o quê | tamanho |
|---|---|---|---|
| v0.13.0 | `sim/corpo.gd` | o pulo automático só sobe degrau de **1 nível**; **descer** degrau, água no mesmo nível e degrau de 2+ níveis continuam no toque duplo | decisão |
| v0.13.0 | `jogo/hud.gd` | o botão PULO AUTO é HUD de desenvolvimento (por cima do mapa) e **não persiste** entre aberturas: cada partida começa em `pular.auto_padrao` (falso) | pequeno |
| v0.13.0 | `sim/corpo.gd` | o alcance do pulo automático é estimado (`velocidade × fatores × 0,42 s × 0,9`), não simulado: numa rota muito curva ou no limite do vão o sistema pode não disparar (fica o toque duplo) ou disparar no último quadro | pequeno |
| v0.13.0 | `dados/acoes.json` | `pular.sprint_fator` 1,5 (pulo ~3,1 células) e a margem 0,9 do alcance são pontos de partida — ajustar no aparelho; com sprint o pulo pode passar do pouso em plataforma curta | design |
| v0.13.0 | oráculo | o botão aparece nos quadros, mas o demo não **clica** nele; a regra do automático é provada pelos testes e por simulação, não por quadro | pequeno |
| v0.12.0 | `dados/mapas/fundacao.json` | a extensão é só MOCKUP: trilha/passarela/rampa alta/plataforma ainda não têm arte (P6); a área também não tem decoração (árvore, pedra) | design |
| v0.12.0 | `jogo/main.gd` | não há atalho para a área de parkour: chega-se pelo túnel ou pelo pulo do canal e atravessando a ilha leste — dá ~40 s de caminhada desde o início | decisão |
| v0.12.0 | `sim/mundo.gd` | o vão de 2 células não tem regra própria: exige **pulo emendado ou sprint**; quem cai na água depende de outro pulo (é a regra que já existia) | design |
| v0.12.0 | `docs/gdd/mapa.md` | não há checkpoint/reset na extensão: sair da trilha é voltar andando ou pulando pela água até uma plataforma | pequeno |
| v0.11.5 | `dados/acoes.json` | com `formas.laco_ataque` falso, `formas.laco_*`, `formas.gatilho_raio_px` e `combate.onda_*`/`area_gatilho_px` ficam **sem uso** — voltam junto se a onda for religada | decisão |
| v0.11.5 | `sim/corpo.gd` | o ramo `laco` de `_checar_marcas`/`_disparar` e o desenho da onda em `jogo/efeitos.gd` ficam **parados** (código morto atrás do interruptor); só o teste com a chave ligada os exercita | decisão |
| v0.11.5 | `sim/formas.gd` | desenhar um círculo agora só anda em círculo: um traço que volta sobre si mesmo **não é encurtado** pelo leitor de formas (quem trata vai-e-volta curto é o `limpar_amontoados`) | pequeno |
| v0.11.4 | HUD (`jogo/hud.gd`) | com o zoom 1,6 o mapa ocupa a tela inteira e a **legenda GESTOS** passa a ficar **por cima do mapa** (antes caía no fundo azul); é HUD de desenvolvimento — some com a UI real | pequeno |
| v0.11.4 | `jogo/mock.gd` | o `ZOOM` 1,6 é **fracionário**: 1 px de arte vira 1–2 px de tela. No xadrez do mock não se nota; com a **arte real** (P6) é preciso decidir — arte desenhada em 2× ou voltar a um zoom inteiro (1 ou 2) | design |
| v0.11.4 | `sim/corpo.gd` | a **cauda do sprint** é queda linear de 0,60 s (1,7× → 1,0×): soltar o segurar ainda empurra o animal por ~40 px; `sprint.cauda_s` é ponto de partida | pequeno |
| v0.11.4 | `sim/corpo.gd` | a **fila do pulo** guarda UM pedido por `pular.buffer_s` (0,60 s): dois toques duplos no MESMO ar não empilham dois pulos (o segundo é ignorado) | decisão |
| v0.11.4 | `sim/corpo.gd` | a marca é validada na ponta **só enquanto o caminho é desenhado**; depois de soltar ela viaja com o alvo — passar por cima e SEGUIR já não a deixa nascer (o alvo é reavaliado a cada traço) | decisão |
| v0.11.4 | `sim/gestos.gd` | o **toque simples (tiro)** continua pendente 280 ms até a janela do duplo; o pedido era o pulo, então esse atraso não foi mexido | design |
| v0.11.3 | `jogo/trilha.gd` | o corte da linha é a projeção do corpo no **traço cru** (não na rota): no tremor inicial/amontoado e num cruzamento ele pode apagar um pouco antes/depois da passagem; nunca volta | pequeno |
| v0.11.3 | `sim/corpo.gd` | o contorno de **desnível** exige um ponto da rota em nível **≤ base + 0,5** a até 128 px/260 px; uma rota que termina no **topo** do barranco para na fronteira (o pulo sobe/desce) | decisão |
| v0.11.3 | `sim/corpo.gd` | a suavização **atrasa** a curva (720°/s); o bico/cantos ficam um pouco mais arredondados; o passo real ainda pode dar **1–2 viradas** de ~80–100° no início do contorno (uma vez), mas a direção desenhada não pisca | pequeno |
| v0.11.3 | `sim/corpo.gd` | `_dir_suave`/`_olhar_suave` valem no **caminho**; a perseguição final e a autonomia continuam com a direção direta (não foram suavizadas) | design |
| v0.11.3 | `dados/acoes.json` | `giro_suavidade` 10 e `giro_max_graus_s` 720 são pontos de partida — mais baixo = mais suave/atrasado; ajustar no aparelho | pequeno |
| v0.11.2 | `sim/corpo.gd` | o contorno de terreno exige um ponto **andável da ROTA** a até 128 px do animal e 260 px de arco: um lago/rocha maior, ou um rio largo sem volta, ainda **para na fronteira** (o pulo atravessa) | decisão |
| v0.11.2 | `sim/corpo.gd` | a **ALTURA** (planalto/rampa) não entra no contorno de água/rocha: continua sendo barreira que para e espera (o contorno usa `bloqueio`, e altura é `pode_andar`) | design |
| v0.11.2 | `sim/corpo.gd` | se o desvio real precisar de mais de 36 passos **sem a projeção andar 6 px**, a teimosia para antes — um lago grande com a volta longe pode dar `barrado` cedo | pequeno |
| v0.11.2 | `sim/corpo.gd` | o contorno é o **leque guloso** (o mesmo do tronco): bolsões de várias pedras em quina ainda podem deter a criatura (ela para, não atravessa) | design |
| v0.11.1 | `sim/corpo.gd` | o **desvio de tronco** é guloso (leque de ângulos + lado mantido): num **bolsão de 3+ troncos em quina** ainda pode ficar indo e volta na beirada; uma busca BFS local foi tentada e ficou fora (o resultado era pior e mais caro) | design |
| v0.11.1 | `sim/corpo.gd` | o **TIRO sem marca** vai na direção do toque **sem assistência**: toque atrás do animal atira para trás; toque em cima usa o olhar | decisão |
| v0.11.1 | `sim/corpo.gd` | o avanço da projeção tem teto por quadro (`esperado×4`, mínimo 24 px): em dt muito grande (travada de FPS) a criatura pode "segurar" o progresso por 1 quadro — não perde a rota | pequeno |
| v0.11.1 | `sim/corpo.gd` | a ponta do bico é arredondada em ~3 px (o passo de 3,7 px passa da ponta antes de a projeção virar) — não trava, mas não é um canto perfeito | pequeno |
| v0.11.1 | `sim/trajetoria.gd` | o amontoado é medido por 24 px/100 px de arco: um **bico de até ~48 px** e um laço de ~15 px de raio são cortados (decisão: nessa escala é tremida, não desenho) | design |
| v0.11.1 | `sim/corpo.gd` | a INÉRCIA passa do último ponto (`freio_extra_px` 16 px; 26 px no sprint): o animal termina um pouco além da ponta do traço | decisão |
| v0.11.1 | `dados/acoes.json` | `freio_extra_px` 16, `freio_sprint_x` 1,6, `amontoado_*` 24/100 e os mínimos do laço (2200/160/28) são pontos de partida — ajustar no aparelho | pequeno |
| v0.11.1 | `sim/formas.gd` | o laço pequeno não acende a área, mas o traço ainda é lido (custa o RDP dos laços a cada ~5 pontos); não foi medido no aparelho | pequeno |
| v0.11.0 | `sim/formas.gd` | o **bico** não é mais reconhecido: o espinho é andado como qualquer traço (sem ataque próprio) — se o operador quiser um efeito no bico, é conteúdo novo | decisão |
| v0.11.0 | `sim/gestos.gd` | o **toque simples (tiro) fica pendente** até a janela do duplo (280 ms): o tiro sai ~0,28 s depois do toque | decisão |
| v0.11.0 | `sim/corpo.gd` | o **SPRINT só existe dentro de um caminho**: na perseguição final (sem rota) o segurar cava (se a célula for escavável) em vez de acelerar | decisão |
| v0.11.0 | `sim/corpo.gd` | a **barra de energia** é uma só (`energia` 0..1): gasto 0,45/s (~2,2 s de sprint cheio) e recarga 0,22/s são pontos de partida | pequeno |
| v0.11.0 | HUD | a barra de energia fica em cima do `estado`, à esquerda; em tela muito baixa pode encostar nos rótulos | pequeno |
| v0.10.0 | `sim/formas.gd` | o **bico** continua sendo lido e o beco sai da rota, mas **não atira mais** (o tiro é o toque duplo): o gesto ficou sem efeito — decidir com o operador se sai de vez | design |
| v0.10.0 | `sim/gestos.gd` | o **toque simples fica pendente** até a janela do duplo (280 ms): o pulo sai ~0,28 s depois do toque | decisão |
| v0.10.0 | `sim/corpo.gd` | a marca está **ligada ao caminho**: um caminho novo a apaga; o alvo pode andar à vontade (o animal persegue), não há mais a perda por 48 px | decisão |
| v0.10.0 | `sim/corpo.gd` | a perseguição final tem teto (`perseguir_s` 3 s): barrada (água/altura) ou lenta demais, a marca se perde (`mira_final:perde`) | design |
| v0.10.0 | `sim/corpo.gd` | o tiro mira na posição do alvo **no disparo** (projétil reto): se ele andar durante o voo, pode errar | design |
| v0.10.0 | `dados/acoes.json` | `area_gatilho_px` 224 (≈7× o corpo de 32 px) é ponto de partida; o "tamanho do animal" pode ser o sprite de 64 px — ajustar no aparelho | pequeno |
| v0.10.0 | demo | o caminho do demo vai em "L" para desviar do planalto (a criatura não sobe andando); o golpe final do roteiro depende de o alvo estar alcançável | — |
| v0.10.0 | oráculo | 45 quadros 720×1280 em ~3 min (~4 s/quadro) com a linha pontilhada no `softpipe` local; o CI grava 60 e passa | pequeno |
| v0.10.0 | `sim/corpo.gd` | o `travar`/`alvo_id` (mira vermelha) e o **baú** ficaram **sem gesto**: o toque agora é o PULO; decidir se o baú ganha outro gatilho | design |
| v0.9.2 | `jogo/trilha.gd` | a linha mostra o traço CRU do dedo (inclusive o tremor inicial e o beco do bico), não o rastro do animal; é uma decisão, não um defeito | design |
| v0.9.2 | `jogo/trilha.gd` | os pontinhos são círculos em coordenadas de mundo (sem snap de pixel): em telas de zoom fracionário podem sair levemente borrados | pequeno |
| v0.9.2 | `sim/corpo.gd` | a marca do especial durante a recarga fica PENDENTE; se a criatura sair do anel/perto da base, ela não acende mais (é consumida no fim da rota) | decisão |
| v0.9.2 | `sim/corpo.gd` | o embalo é um multiplicador de velocidade do passo (pico `sin`); 0,25 s/1,7× e 0,6 s/2,0× são pontos de partida — ajustar no aparelho | pequeno |
| v0.9.2 | `sim/corpo.gd` | a marcação embala uma vez por marca (`_embalo_final_feito`); se a criatura for barrada depois do embalo, ele não repete ao retomar | design |
| v0.9.2 | oráculo | a linha pontilhada são dezenas de `draw_circle` por quadro: no `softpipe` local cada quadro caiu para ~4,5 s (33 quadros em ~2,5 min); no aparelho/CI a GPU resolve — medir no celular | pequeno |
| v0.9.1 | `sim/formas.gd` | a BASE do bico é o ponto do traço mais perto da volta: num "T" a volta entra na estrada e a base pode ficar alguns px dentro da boca do beco | design |
| v0.9.1 | `sim/formas.gd` | a base é achada por uma CURVA (≥ 45°) na volta; se o dedo reencontrar a estrada numa curva muito suave, o bico pode não ser lido (o fim do traço tem a regra própria) | pequeno |
| v0.9.1 | `sim/corpo.gd` | a estrada é um alvo À FRENTE + senoides; os valores (largura 30, desvio 9, ondas 120/47, freio 44) são pontos de partida — ajustar no aparelho | pequeno |
| v0.9.1 | `sim/corpo.gd` | o desvio de tronco mantém o LADO escolhido até passar: pode dar a volta pelo lado mais longo, mas não fica oscilando | design |
| v0.9.1 | `sim/corpo.gd` | quando a rota acaba DURANTE o desenho, o alvo final usa a posição ATUAL do inimigo (não a do soltar): é o que permite o golpe final com traço ao vivo | decisão |
| v0.9.1 | `sim/corpo.gd` | o bico pausa 0,25 s: a pausa também congela a autonomia/rota por um instante (o mundo continua) | decisão |
| v0.9.1 | demo | o beco do demo virou um "T" no meio do caminho; o golpe final do roteiro depende de a criatura chegar perto do adversário | — |
| v0.9.1 | `sim/corpo.gd` | a leitura das formas refaz o RDP/laços e a busca do bico sobre o TRAÇO INTEIRO a cada ~5 pontos desenhados; o custo não foi medido no aparelho | pequeno |
| v0.9.1 | oráculo | 180 quadros 720×1280 em ~5 min (~1,7 s/quadro); a demo agora passa dos 19 s (o golpe final do roteiro fica fora dos 180) | operador |
| v0.9.0 | `sim/formas.gd` | a base do bico é o ponto onde a VOLTA reencontra o caminho (ou a partida, se o traço acaba na volta): num bico desenhado no MEIO de uma reta, a base pode sair alguns px antes do ponto exato | design |
| v0.9.0 | `sim/formas.gd` | um laço é lido no traço reduzido (RDP 3 px) e um bico no traço amostrado (6 px): desenhos minúsculos (laço < 700 px², espinho < 18 px) não contam — limiares em `formas` | pequeno |
| v0.9.0 | `sim/corpo.gd` | a onda e o tiro só atingem ADVERSÁRIO (quem sabe reagir); árvore leva a batida de travessia mas não reage | design |
| v0.9.0 | `sim/corpo.gd` | o laço acende na passagem pelo nó; se a criatura já estiver DEPOIS do nó quando a forma é reconhecida, ele acende na volta (é o mesmo ponto) — e a onda não espera a criatura chegar ao centro | decisão |
| v0.9.0 | `sim/corpo.gd` | o bico acende na base; se a forma só é reconhecida com a criatura já DENTRO do espinho, ela acende ali (por isso o tiro pode sair ~30 px depois da base) | decisão |
| v0.9.0 | `sim/corpo.gd` | `_checar_marcas` dispara por PROXIMIDADE: se a rota for barrada antes da marca, o ataque não acontece | design |
| v0.9.0 | `sim/corpo.gd` | as formas são lidas a cada ~5 pontos do traço; num traço muito curto o laço/bico pode ser lido um quadro depois (sem prejuízo de regra) | pequeno |
| v0.9.0 | `sim/corpo.gd` | o golpe final divide a máquina de golpe com a batida: se um golpe já está em curso, o empurrão sai mas o arco não aparece | pequeno |
| v0.9.0 | demo | o roteiro é um SHOWCASE, não teste: se o adversário andar muito, a marca do alvo final do demo pode se perder (o log mostra `mira_final:perde`) | — |
| v0.9.0 | oráculo | 150 quadros 720×1280 em ~3 min 50 s (~1,5 s/quadro) neste celular; a demo completa (~17 s) pede ~510 quadros (~13 min) | operador |
| v0.9.0 | `docs/HISTORICO.md` | a nota do lote cita a demo; números de quadros medidos localmente, não no CI | — |
| v0.8.0 | `dados/acoes.json` | ~~a `esquiva` ficou sem gesto~~ — **removida na v0.9** (esquivar é andar) | — |
| v0.8.0 | `sim/gestos.gd` | ~~espalhamento vertical lido como ataque/defesa~~ — **não há mais gesto de dois dedos na v0.9** | — |
| v0.8.0 | `jogo/main.gd` | ~~ação durante o desenho devolve o tempo~~ — **não há mais ação de dois dedos na v0.9** | — |
| v0.8.0 | `sim/gestos.gd` | ~~ação lida no dedo extra~~ — **fora na v0.9** | — |
| v0.7.1 | `jogo/main.gd` | ~~linha da rota pisca no começo de um risco~~ — **o risco deixou de existir na v0.8** (dois dedos) | — |
| v0.7.1 | `sim/corpo.gd` | ~~`voltar_rota` não devolve a posição~~ — **função removida na v0.9** (não há cancelamento de traço) | — |
| v0.7.0 | `dados/gestos.json` | `desenho.ganho` 1,6, véu 0,22 e rampa 0,45 s são pontos de partida — ajustar com o operador no aparelho | pequeno |
| v0.7.0 | `sim/gestos.gd` | ~~risco rápido disparava ação~~ — **substituído na v0.8** (ataque é 2 dedos) | — |
| v0.7.0 | `jogo/main.gd` | o traço ao vivo refaz a rota (desconto + Douglas-Peucker) a cada quadro; custo não medido no aparelho | pequeno |
| v0.7.0 | demo | ~~cada risco também vira caminho e empurra a criatura~~ — **corrigido na v0.7.1** (o risco cancela o traço) | — |
| v0.7.0 | `sim/corpo.tracar` | a "volta ao começo" só entra no 1º quadro do traço; depois disso ela segue a rota e não volta | design |
| v0.7.0 | HUD | legenda e estado continuam de desenvolvimento; o estado longo pode encostar na borda no retrato | pequeno |
| v0.6.1 | atualizador | a v0.5.0 instalada tem o código antigo e não mostra o botão; instalar o APK da v0.6.1 à mão **uma vez** | operador |
| v0.6.1 | atualizador | o painel abre sozinho só na primeira detecção da sessão; depois fica o botão | design |
| v0.6.1 | atualizador | layout verificado por sonda headless e tela real, não por teste no runner síncrono | pequeno |
| v0.6.1 | APK 0.6.0-b14 | o 0.6.0 tem o mesmo defeito de layout do aviso; não serve para atualizar — usar o 0.6.1-b15 | operador |
| v0.6.0 | especiais | os dois lados usam o MESMO golpe lateral genérico; o conteúdo por criatura/evolução é P4/P5 | design |
| v0.6.0 | `dados/gestos.json` | `planejamento.escala_tempo` 0,35× é um ponto de partida; ajustar com o operador | pequeno |
| v0.6.0 | `sim/trajetoria.descontar_inicio` | o corte pode endireitar uma curva inicial quando a reta é andável; `raio`/`janela` são ajustáveis | pequeno |
| v0.6.0 | `sim/corpo._primeiro_bloqueio` | desvio local só contorna OBJETO; parede côncava/longa para a criatura (de propósito) | design |
| v0.6.0 | pulo | pular de dentro da água é permitido e não há natação/dano; cair na água exige outro pulo | design |
| v0.6.0 | `sim/mundo.limitar_caminho` | ficou sem uso no corpo (só o teste cobre); decidir remover ou reaproveitar | pequeno |
| v0.6.0 | HUD | legenda/estado ainda de desenvolvimento; estado longo pode encostar na borda no retrato | pequeno |
| v0.6.0 | Android | `window/handheld/orientation=1` depende do manifesto gerado; o `exportar.sh` imprime `screenOrientation` no CI, mas o agente não instala o APK | operador confirma no aparelho |
| v0.6.0 | `jogo/atualizador.gd` | painel reorganizado para retrato, mas não visto com uma atualização real | pequeno |
| v0.6.0 | gestos | o caminho exigia SEGURAR antes e o arrasto rápido era ação — **suplantado na v0.7.0** (caminho ao vivo + risco) | — |
| v0.6.0 | demo | o toque no adversário móvel pode falhar se ele andar > 110 px; a demo é roteiro, não teste | pequeno |
| v0.6.0 | oráculo | 60 quadros locais em ~1 min 46 s; a demo completa (~16 s) pede ~480 quadros / ~15 min | operador |
| v0.1.0 | `jogo/main.gd` `_draw` | traço de 1 px sai com falhas nas diagonais (snap de vértice + `draw_polyline` largura 1) | pequeno — trocar por desenho por pixel (Bresenham) ou largura 2 quando a arena chegar (P3) |
| v0.1.0 | `ci.yml` | ~~oráculo llvmpipe/x86_64 não provado~~ — **resolvido**: CI #1 (`cfdbb34`) verde com o passo de quadros | — |
| v0.1.1 | cofre / histórico da sessão | a chave do PixelLab passou pelo chat: está no log da sessão de 2026-11-20 | operador gera chave nova e troca no cofre; agente reinicia/confirma com `get_balance` |
| v0.3.0 | jogo | sem altura nem colisão: a criatura anda sobre o mar e sobe o planalto como chão | P3/P4 (ver `docs/gdd/mapa.md`) |
| v0.3.0 | `arte/criaturas/cao_base_prova.png` | sprite de LADO num mapa visto de CIMA | P6 decide a vista da criatura |
| v0.5.0 | movimento | pular é só VISUAL: não atravessa água/vão (a rota é cortada e ela para na beira) | decidir com o operador se o pulo deve vencer vãos |
| v0.5.0 | combate | golpe desenha o cone mas não acerta nada (sem vida/dano por decisão do operador) | P4/P7 |
| v0.5.0 | `jogo/main.gd` | a lista de alvos é reconstruída só ao abrir (objetos fixos) e sincronizada a cada quadro | ok enquanto nada nasce/morre em jogo |
| v0.5.0 | interação | o baú só muda de cor; não há conteúdo nem inventário | design (P8) |
| v0.4.0 | verificação | o modelo da sessão não lê imagem: quadros conferidos por amostragem de pixels, não por olho | operador confirma o APK; ou delegar a um agente com visão |
| v0.4.0 | mockup | a criatura de xadrez ocupa ~40 px do canvas de 64 (margem de pose); só mock | some quando a arte real entrar |
| v0.4.0 | copas | a transparência da copa usa a distância no CHÃO, sem o desnível do planalto | relevante se houver árvore em dois níveis |
| v0.4.0 | demo | não cobre alvo (não há inimigos) nem afinidade (P4) | P4, P7 |
| v0.4.0 | `jogo/mapa.gd` + `sim/mapa.gd` + `ilha_teste.json` | renderizador Wang do v0.3 ficou PARADO (sem uso) | decidir: manter para a arte futura ou remover |
| v0.3.1 | atualizador | o caminho Android (shell_open → FileProvider → instalador) foi conferido no código do Godot, NÃO num aparelho | o operador reinstala uma vez e testa a próxima atualização |
| v0.3.1 | git (público) | `tools/android/galapago-dev.keystore` + senha seguem no histórico | revogado na prática; nunca reutilizar |
| v0.3.0 | `tools/pixellab-tileset.mjs` | com o job FALHO no servidor, fica esperando ~2,5 min em vez de falhar logo | pequeno — consultar o status antes de baixar |
| v0.3.0 | `arte/cenarios/objetos/arvore.png` | sombra desenhada na arte (desligamos a nossa para não dobrar) — as outras artes não têm | P6: padronizar (sombra sempre nossa) |
| v0.2.0 | `ci.yml` | Actions avisa: `checkout@v4`, `setup-java@v4`, `cache@v4` ainda miram Node 20 (forçadas a Node 24) | pequeno — subir as versões quando houver v5 confirmadas |
| v0.2.0 | `tools/android/exportar.sh` passo 5 | no CI #6 o `apksigner verify` não imprimiu linha (o `aapt` sim); a assinatura foi conferida localmente com `keytool -printcert -jarfile` | pequeno — investigar a saída do apksigner 37 no próximo lote do CI |
| v0.2.0 | `export_presets.cfg` | pacote `com.projetogalapago.jogo` e keystore de dev são provisórios; trocar qualquer um obriga desinstalar | decidir antes da 1ª distribuição externa |
| v0.2.0 | P2 | o APK não foi testado em aparelho pelo agente (instalar é do operador) | o operador instala e risca |
| v0.1.1 | `arte/fonte/p1-cao-base-pixen.png` | prova sem paleta-mestra (64 cores livres) e câmera ainda não decidida — não é asset do jogo | resolve no P6 (âncora de arte) |
