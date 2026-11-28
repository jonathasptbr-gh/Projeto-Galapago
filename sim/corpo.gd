extends RefCounted
## O CORPO da criatura — LÓGICA PURA, avançado por `passo(dt, mundo, alvos)`.
##
## DUAS COISAS ANDAM JUNTAS (é o que este arquivo garante):
##
## - a **ROTA** (o traço riscado): a criatura segue até o fim. Só perde a rota
##   se o jogador riscar OUTRA ou se escavar (troca de camada, e a rota não
##   vale mais lá). A rota é uma SÉRIE DE PONTOS de referência
##   (sim/trajetoria.simplificar) procurados na ordem; a criatura pode se
##   desviar um pouco para contornar OBJETOS. Água, rocha e altura são
##   BARREIRAS: ela para e a rota continua guardada — um pulo durante a rota
##   passa por cima e retoma o percurso;
## - os **OVERLAYS** (pulo, golpes, tiros e habilidade), que
##   acontecem POR CIMA da rota sem cancelá-la.
##
## v0.19 — **GESTOS DE UM DEDO**: toque = **TIRO**, segurar = **CORRER** (ou a
## habilidade, sem caminho).
##
## - **TOQUE = TIRO CARREGADO com TEMPO CONFIGURÁVEL** (`_cmd_tiro`): o toque
##   NÃO atira na hora (salvo `carga_tiro_s` = 0). Ele começa a CARGA (o animal
##   para e `_carga_t` cresce) e o disparo sai **sozinho** ao completar
##   `carga_tiro_s` — o tempo do slider da HUD, padrão `combate.tiro_carga_s`
##   (0,5 s). O **TAMANHO do tiro é PROPORCIONAL a esse tempo**:
##   `carga_tiro_s` 0 = tiro BASE e instantâneo (9 px/280/24, sem preparo) e
##   `tiro_carga_max_s()` (`combate.tiro_carga_max_s`, 1,5 s) = tiro MÁXIMO
##   (13,5/448/48); no meio, escala em linha reta. A direção é o **ALVO MARCADO
##   vivo**; sem ele, o **DESTINO FINAL do caminho** capturado no começo da
##   carga; sem um nem outro, `olhar` — **nunca o toque**. Sem rota e sem alvo,
##   o toque é `"recusado: sem destino"` e a carga nem começa. A carga só é
##   CANCELADA por um caminho novo (`_guardar_rota(reiniciar=true)`) ou por um
##   segurar (o jogador mudou de ideia e vai correr). Soltar o dedo não dispara
##   nem cancela. `carga_tiro_s` pode mudar a qualquer momento: a carga EM CURSO
##   guarda o teto do começo, mas o TAMANHO é o valor lido no disparo.
## - **SEGURAR = CORRER** (`_cmd_segurar`): com caminho, liga o SPRINT CONTÍNUO
##   (`sprint.fator`) e gasta a barra de ENERGIA enquanto o dedo fica; ao
##   soltar (`_cmd_soltar_segurar`) o embalo continua na CAUDA
##   (`sprint.cauda_s`). Sem caminho é a HABILIDADE em si mesmo (cavar). O
##   segurar também cancela uma carga em curso.
## - **RAMPA DE ACELERAÇÃO** (`rota.rampa_s`, 0,3 s): toda caminhada NOVA começa
##   a ~15% da velocidade e chega a 100% em `rampa_s` (`_rampa_t`/`_fator_rampa`,
##   smoothstep). O traço ao vivo reinicia a rampa uma vez; retomar depois de
##   uma pausa/tiro NÃO reinicia.
## - **MARCHA PELO TAMANHO DO CAMINHO** (v0.45): caminho até `caminhada_max_px`
##   (≈ o comprimento do corpo, 45 px) é **CAMINHADA** (`velocidade_caminhada`,
##   28 px/s); acima disso é **TROTE** (`velocidade`, 110 px/s). O traço ao vivo
##   só PROMOVE (cresceu ⇒ trota) e o trote fica TRAVADO até a rota acabar: um
##   traço novo e curto no meio da corrida não rebaixa a marcha; a marcha só é
##   redecidida ao sair do repouso (ou ao vaguear). Correr acelerado (segurar)
##   força o trote.
##
## **SEGURAR QUE VIRA DESENHO**: se o dedo que SEGURA (sprint) se move
## sem levantar, o jogo RECOMEÇA o traço na posição ATUAL
## (`sim/gestos.recomecar`) e o corpo adota a rota nova (`tracar(inicio=true)`)
## **sem cortar o sprint nem rearmar a rampa** — a criatura continua acelerada
## no caminho novo. Ao soltar, a trajetória encerra o segurar
## (`soltar_segurar`), então o sprint não fica preso. Um caminho novo que NÃO
## vem de um segurar zera sprint e rampa como antes.
##
## v0.11.1 — a ESTRADA deixou de CORTAR CAMINHO:
##
## - **projeção com continuidade**: o ponto da rota onde a criatura está é
##   escolhido pelo avanço esperado, não só pela distância; num cruzamento ou
##   num bico (ida e volta sobre a mesma linha) ela não "pula" para o braço de
##   volta — o laço e a ponta do bico são ANDADOS;
## - **alvo pela VISÃO**: o ponto à frente é o mais LONGE que a linha reta
##   alcança andando (pedaços de 2 px); assim a criatura contorna a curva da
##   rota em vez de cortar a corda por dentro de uma pedra/beira de mar. O
##   desvio orgânico lateral só vale se o alvo desviado também for alcançável;
## - **desvio de tronco** conserva o lado, mas cai para o outro lado se o
##   primeiro não passar (nunca fica presa na beirada);
## - **AMONTOADOS** (`sim/trajetoria.limpar_amontoados`): um laço/cruzamento/
##   vai-e-volta dentro de uma zona do tamanho do animal é cortado da rota;
## - **INÉRCIA no fim**: a criatura vai até o fim da rota em velocidade NORMAL e
##   só freia DEPOIS de chegar, num pedaço curto fora do caminho (maior quando
##   está no SPRINT manual). A zona de freio antes do fim não existe mais.
##
## v0.11.2 — ÁGUA/ROCHA deixaram de ser parada automática: se a ROTA entra no
## bloqueio e VOLTA a uma célula andável dentro de `contorno_alcance_px`
## (arco) e `contorno_raio_px` (distância do animal), a criatura mira a
## continuação e contorna com o MESMO leque do tronco (nunca entra na água).
## Se a rota termina no bloqueio ou não há continuação no raio, para na
## fronteira (o PULO atravessa). Depois de `desvio_teimoso_apos` passos de
## contorno sem a rota andar, desiste e para — não fica indo e voltando.
##
## v0.11.3 — o contorno passou a valer para DESNÍVEL (a barreira é lida por
## `caminho_livre`, não só `bloqueio`; a continuação precisa ser de nível
## alcançável) e a direção ficou estável (`_dir_suave`/`_olhar_suave` +
## `_desvio_angulo`). A LINHA apaga o que já foi andado: `traco_t` é o arco
## andado do traço cru.
##
## v0.11.4 — três ajustes de sensação (pedidos do operador):
##
## - **A MARCA vale para a PONTA, não para a passagem.** Ela nasce quando a
##   ponta do caminho alcança um adversário e **sai** se o traço continua e
##   termina longe dele (`_soltar_marca_longe_da_ponta`). Assim, um caminho que
##   PASSA por cima (batida/empurrão) e segue para longe **não volta** para dar
##   o golpe de perseguição;
## - **PULO NA FILA**: o toque duplo durante o ar é percebido na hora
##   (`_pulo_fila_t`) e o pulo sai no **quadro em que o anterior termina** —
##   pulsos seguidos emendam sem o atraso de esperar o toque cair no chão.
##   O pedido expira em `pular.buffer_s`;
## - **CAUDA DO SPRINT**: soltar o segurar não corta a velocidade na hora. O
##   embalo **continua por `sprint.cauda_s` e cai aos poucos** (`_fator_sprint`),
##   então dá para **pular ainda acelerado e ir mais longe**. A energia só é
##   gasta enquanto o segurar está ativo.
##
## v0.11.5 — o **ATAQUE EM ÁREA DO LAÇO** foi desligado (decisão do operador)
## e, em 2026-11-27, **removido** com o leitor de formas (`sim/formas.gd`):
## desenhar um círculo é só **caminho**; não há mais ONDA.
##
## v0.13 — **PULO AUTOMÁTICO** (`pulo_auto`, desligado por padrão; o botão da
## HUD liga/desliga) e **PULO MAIS LONGE NO SPRINT**:
##
## - o pulo automático dispara quando a rota para numa **escada de UM nível
##   para cima** e o caminho CONTINUA **depois do pouso**: vale para a célula
##   que já é o degrau e para um **vão de água curto** antes dele, desde que o
##   pouso esteja dentro do alcance do pulo. Água no mesmo nível, rocha/objeto,
##   degrau de 2+ níveis, caminho que acaba na beirada e pouso fora do alcance
##   NÃO disparam — continuam exigindo o toque duplo;
## - a decisão é da `sim/` (testável): `pulo_auto` é um estado do corpo, e o
##   disparo chama o MESMO `_iniciar_pulo` do toque duplo, respeitando a
##   recarga; o evento sai como `pulo:auto` (o `pulo:on` continua saindo);
## - **velocidade aumentada = pulo mais longo**: enquanto está no ar com o
##   sprint (ou a cauda dele) ativo, o avanço horizontal ganha
##   `pular.sprint_fator` (1,5) — o pulo acelerado passa de ~2,1 para ~3,1
##   células (46,9 px normal; 66,8 → 98,2 px com sprint). O fator só vale NO
##   AR; andar acelerado não mudou.
##
## v0.9 — O ATAQUE NASCE DO DESENHO, não de um gesto de dois dedos (a onda
## do laço saiu em 2026-11-27):
##
## - **bico** (o "T"/"V" que sai da estrada e volta) → **v0.11: o bico é
##   andado** (o traço é obedecido como foi desenhado; nada é ignorado);
## - **toque simples** → TIRO híbrido (com marca: automira; sem marca: direção do
##   toque; **v0.18: carga de 1 s, alvo marcado/destino final — nunca o toque**);
##   **toque duplo** → PULO;
## - **segurar** durante um caminho → SPRINT (gasta a barra de ENERGIA); sem
##   caminho → habilidade em si mesmo (cavar), ativada no limiar do segurar;
## - **travessia** de um alvo → BATIDA/empurrão ao passar por cima;
## - **fim do caminho em cima do adversário** → ele é marcado como alvo do
##   GOLPE FINAL (a marca vai NELE, não no lugar final). Se ele andar demais
##   até a criatura chegar, a automira se perde e o golpe sai no vazio.
##   v0.11.4: quem passou por cima e SEGUIU para longe não volta — a marca
##   acompanha a PONTA do traço, não a passagem.
##
## A **ESQUIVA É O PRÓPRIO CAMINHAR** (com o tempo lento do desenho): não há
## efeito de esquiva. A **HABILIDADE É DE SI MESMO** e dura um tempo: segurar o
## dedo parado a ativa (hoje `cavar`).
##
## O **DESCONTO INICIAL** (sim/trajetoria.descontar_inicio) tira o vai-e-volta
## do começo do traço antes de a rota existir — MAS não quando esse vai-e-volta
## é um BICO desenhado de propósito (ele é ataque).
##
## v0.7 — **TRAÇO AO VIVO** (`tracar`): enquanto o dedo desenha, a rota é
## refeita a cada quadro com o traço até agora e a criatura JÁ ANDA por ela. A
## origem é fixa (onde ela estava quando o dedo desceu). O progresso nunca
## anda para trás.
##
## Sem rota, entra em **AUTONOMIA**: parada ou vagueando devagar (o ir até o
## alvo travado e o rondar saíram com o `travar` em 2026-11-27). A escolha é
## sorteio com semente.
##
## O ALVO marcado (`mira_final_id`) é resolvido pela lista de sim/alvos.gd a
## cada quadro — mirar num adversário que anda funciona.

const Mundo := preload("res://sim/mundo.gd")
const Trajetoria := preload("res://sim/trajetoria.gd")
const Alvos := preload("res://sim/alvos.gd")

## Passo da varredura de TERRENO na rota (v0.11.2).
const PASSO_TERRENO := 4.0

# --- estado ---
var defs: Dictionary = {}
var rota_cfg: Dictionary = {}
var pos := Vector2.ZERO          # posição no chão
var z := 0.0                     # altura no ar (pulo)
var olhar := Vector2.RIGHT
var camada := Mundo.SUPERFICIE
var velocidade := 110.0
## Marcha da ROTA (v0.45): caminho curto = CAMINHADA (`velocidade_caminhada`),
## caminho maior que `caminhada_max_px` (≈ o comprimento do animal) = TROTE
## (`velocidade`, a normal). O trote TRAVA até a rota acabar: um traço novo e
## curto desenhado no meio da corrida não rebaixa a marcha.
var trote := false
var velocidade_caminhada := 28.0
var caminhada_max_px := 45.0

# rota (pontos de referência; `_rota_i` = o próximo que ela procura)
var rota := PackedVector2Array()
var rota_t := 0.0
var total_rota := 0.0
var _rota_i := 0
var _barrado := false
var _desvios := 0
var _desvio_lado := 0.0            # lado do desvio em curso (histerese no tronco)
var _desvio_ref := 0.0             # arco do último desvio (só encerra depois de folga)
var _desvio_inicio_s := 0.0        # arco onde o contorno começou (teto de teimosia)
var _desvio_angulo := 0.0           # ângulo do contorno em curso (anti-tremor)
# DIREÇÃO SUAVE (v0.11.3): o alvo pode mudar 2 px por quadro; a criatura não.
var _dir_suave := Vector2.ZERO       # direção usada para ANDAR (filtrada)
var _olhar_suave := Vector2.ZERO     # direção do desenho (filtrada, só visual)

# overlays
var _pulo_t := 0.0
var _pulo_dur := 0.0
var _pulo_altura := 0.0
# PULO NA FILA (v0.11.4): o pedido feito NO AR fica guardado este tempo e sai
# no quadro em que o pulo anterior termina (emenda sem perder o gesto).
var _pulo_fila_t := 0.0
var ataque := ""                 # "" = nenhum
var ataque_t := 0.0
var ataque_dir := Vector2.RIGHT
var escavando := false
var _recargas := {}

# v0.9 — o desenho CRU, as marcas de ataque e os efeitos vivos
var traco := PackedVector2Array()
var traco_t := 0.0               # arco JÁ ANDADO do traço cru (a linha apaga)
var marcas: Array = []           # {tipo, ponto, chave, dir, ...} a acender (batidas)
var efeitos: Array = []          # tiros vivos (o jogo desenha)
var mira_final_id := ""          # adversário marcado pelo fim do caminho
var _perseguindo := false        # perseguição final do alvo marcado
var _perseguir_t := 0.0
var habilidade := ""             # habilidade de si mesmo em curso ("" = nenhuma)
var habilidade_t := 0.0
var habilidade_dur := 0.0
var _combate: Dictionary = {}
var _embalo: Dictionary = {}
var _arcos_rota := PackedFloat32Array()  # arco acumulado em cada ponto da rota
var _fase1 := 0.0                   # fases do desvio orgânico (semente da rota)
var _fase2 := 0.0
var _pausa_t := 0.0                 # pausa curta ao disparar o tiro
# TEMPO DA CARGA do tiro do TOQUE (v0.19): 0 = instantâneo/tiro base e
# `tiro_carga_max_s()` = tiro máximo. A HUD escreve aqui pelo slider; o TAMANHO
# do disparo é proporcional a este tempo (ver `_disparar_carga`).
var carga_tiro_s := 0.5
# TIRO CARREGADO (v0.18): o TOQUE arma a carga e o disparo sai sozinho no teto;
# o segurar cancela a carga (vai correr).
var _carga_ativa := false
var _carga_t := 0.0
var _carga_max_s := 0.5             # `carga_tiro_s` travado no começo da carga
var _carga_alvo_id := ""            # alvo marcado copiado no início da carga
var _carga_destino := Vector2.ZERO  # DESTINO FINAL do caminho (sem alvo vivo)
var _carga_tem_destino := false     # a rota tinha ≥ 2 pontos ao carregar?
# SPRINT (v0.11): segurar DURANTE um caminho acelera e gasta a ENERGIA; ao
# soltar, a CAUDA mantém o embalo por `sprint.cauda_s`.
var energia := 1.0
var _sprint := false
var _sprint_cfg: Dictionary = {}
# RAMPA DE ACELERAÇÃO (v0.18): tempo desde o começo da rota ATUAL; zera só
# numa rota nova (`_guardar_rota(reiniciar=true)`) e nunca num pulo/contorno.
var _rampa_t := 0.0
# PULO AUTOMÁTICO (v0.13): a HUD liga/desliga; padrão em `pular.auto_padrao`.
# Ligado, o corpo pula sozinho a escada de UM nível quando a rota continua.
var pulo_auto := false
# CAUDA do sprint (v0.11.4): ao soltar, o embalo continua caindo aos poucos
var _sprint_cauda_t := 0.0
# EMBALO dos golpes físicos (v0.9.2): acelera curto na marcação e longo no
# empurrão, passando mais rápido pelo alvo e desacelerando depois
var _turbo_t := 0.0
var _turbo_dur := 0.0
var _turbo_fator := 1.0
var _embalo_final_feito := false
var _disparadas := {}            # chaves de marcas que já acenderam
# INÉRCIA do fim (v0.11.1): o corpo passa do último ponto em velocidade normal
# e desacelera FORA da rota (pedaço curto; maior no sprint manual)
var _inercia_t := 0.0
var _inercia_dur := 0.0
var _inercia_dir := Vector2.ZERO
var _inercia_v0 := 0.0

# autonomia (o `travar`/`alvo_id` da mira vermelha saiu em 2026-11-27)
var autonomia := "parado"        # parado | vagar
var _auto_t := 0.0
var _auto_destino := Vector2.ZERO
var _auto_espera := 0.0
var rng := RandomNumberGenerator.new()

# GOLPE DO INIMIGO (v0.14): empurrão externo + atordoamento curto. Não há vida
# (decisão do operador): o que dói é ser jogado longe e ficar sem agir.
var atordoado_t := 0.0
var _invencivel_t := 0.0
var _empurrao_ext := Vector2.ZERO
var _reacao_cfg: Dictionary = {}

var eventos: Array[String] = []


func _init(definicoes: Dictionary = {}) -> void:
	defs = definicoes
	velocidade = float(defs.get("mover", {}).get("velocidade", 110.0))
	velocidade_caminhada = maxf(float(defs.get("mover", {}).get("velocidade_caminhada", 28.0)), 0.0)
	caminhada_max_px = maxf(float(defs.get("mover", {}).get("caminhada_max_px", 45.0)), 1.0)
	rota_cfg = defs.get("rota", {})
	_combate = defs.get("combate", {})
	carga_tiro_s = maxf(float(_combate.get("tiro_carga_s", 0.5)), 0.0)
	_embalo = defs.get("embalo", {})
	_sprint_cfg = defs.get("sprint", {})
	_reacao_cfg = defs.get("reacao", {})
	pulo_auto = bool(defs.get("pular", {}).get("auto_padrao", false))


# ---------------------------------------------------------------- consultas

func em_rota() -> bool:
	return rota.size() >= 2 and _rota_i < rota.size()


## Está FREANDO depois do fim da rota (a mini inércia da v0.11.1)?
func em_inercia() -> bool:
	return _inercia_t > 0.0


func em_autonomia() -> bool:
	return not em_rota() and not em_inercia()


## A carga do tiro do TOQUE, de 0 a 1 (0 quando não está carregando): é o
## PREENCHIMENTO do preparo (`_carga_t / _carga_max_s`), o que a HUD mostra no
## anel — NÃO o tamanho do tiro (esse vem de `carga_tiro_s`). Com o preparo
## instantâneo não há carga ativa; a guarda de `_carga_max_s` perto de zero
## devolve 1,0 (preparo concluído).
func carga() -> float:
	if not _carga_ativa:
		return 0.0
	if _carga_max_s <= 0.001:
		return 1.0
	return clampf(_carga_t / _carga_max_s, 0.0, 1.0)


## O TETO do tempo de carga do tiro (v0.19), em segundos, de
## `combate.tiro_carga_max_s` (1,5 s): é onde o tiro sai MÁXIMO
## (`tiro_carga_*_x`) e o fim do slider da HUD. Nunca devolve ≤ 0 (é divisor do
## tamanho em `_disparar_carga`).
func tiro_carga_max_s() -> float:
	return maxf(float(_combate.get("tiro_carga_max_s", 1.5)), 0.001)


## Está CARREGANDO o tiro agora (parada, sem andar)?
func carregando() -> bool:
	return _carga_ativa


## Está parada numa barreira de terreno (a rota continua guardada)?
func barrado() -> bool:
	return _barrado


## Golpe valendo agora (fase ativa)? A apresentação usa para desenhar o arco.
func golpe_ativo() -> Dictionary:
	if ataque == "":
		return {}
	var d: Dictionary = defs.get(ataque, {})
	var f: Array = d.get("fases", [0.1, 0.15, 0.2])
	if ataque_t < float(f[0]) or ataque_t > float(f[0]) + float(f[1]):
		return {}
	return {"alcance": float(d.get("alcance", 40.0)), "arco": float(d.get("arco", 80.0)), "dir": ataque_dir}


func no_ar() -> bool:
	return _pulo_t > 0.0


## Uma habilidade de si mesmo está em curso (cavar inclusive)?
func habilidade_ativa() -> bool:
	return escavando or habilidade != ""


func drenar_eventos() -> Array[String]:
	var e := eventos
	eventos = []
	return e


## A criatura está atordoada (não obedece comando e não anda)?
func atordoado() -> bool:
	return atordoado_t > 0.0


## Está no SPRINT do segurar (correndo)? Só leitura; a regra fica no passo.
func correndo() -> bool:
	return _sprint


## Marcha da rota: true = TROTE (caminho maior que o corpo), false = CAMINHADA.
func trotando() -> bool:
	return trote


## Velocidade de CRUZEIRO da marcha atual (px/s), sem sprint, rampa ou embalo.
func velocidade_base() -> float:
	return velocidade if trote else velocidade_caminhada


## Ainda no curto período de invencibilidade depois de um golpe?
func invencivel() -> bool:
	return _invencivel_t > 0.0


## O INIMIGO acertou (v0.14): empurra `forca_px` na direção `dir` e deixa
## `atordoamento_s` sem agir. Devolve `false` se não valeu (invencível, no
## subsolo ou já atordoada) — quem chama não conta o acerto nesse caso.
func levar_golpe(dir: Vector2, forca_px: float, atordoamento_s: float) -> bool:
	if camada == Mundo.SUBSOLO:
		return false
	if atordoado_t > 0.0 or _invencivel_t > 0.0:
		return false
	if dir.length() < 0.001:
		dir = -olhar if olhar.length() > 0.01 else Vector2.RIGHT
	_empurrao_ext += dir.normalized() * maxf(forca_px, 0.0)
	atordoado_t = maxf(atordoado_t, maxf(atordoamento_s, 0.0))
	_invencivel_t = maxf(float(_reacao_cfg.get("invencivel_s", 0.8)), 0.0)
	# o susto corta o sprint (a rota continua guardada)
	_sprint = false
	_sprint_cauda_t = 0.0
	eventos.append("levou:golpe")
	return true


# ---------------------------------------------------------------- comandos

## Recebe um comando (sim/comandos.gd). Devolve "ok", "ok: <detalhe>" ou
## "recusado: <motivo>" — quem mostra é a HUD.
func comandar(cmd: Dictionary, mundo: RefCounted, alvos: Array = []) -> String:
	if atordoado():
		return "recusado: atordoado"
	var a: String = cmd.get("acao", "")
	match a:
		"mover":
			return _cmd_mover(cmd, mundo, alvos)
		"olhar":
			var v: Vector2 = cmd.get("alvo", pos) - pos
			if v.length() > 1.0:
				olhar = v.normalized()
			return "ok"
		"ataque":
			return _cmd_ataque()
		"pular":
			return _cmd_pular(cmd)
		"habilidade":
			return _cmd_habilidade(mundo)
		"tiro":
			return _cmd_tiro(cmd, alvos)
		"segurar":
			return _cmd_segurar(mundo)
		"soltar_segurar":
			return _cmd_soltar_segurar()
	if not defs.has(a):
		return "recusado: ação desconhecida (%s)" % a
	return "recusado: nada a fazer"


func _cmd_mover(cmd: Dictionary, mundo: RefCounted, alvos: Array) -> String:
	var pts := PackedVector2Array([pos])
	pts.append_array(cmd.get("pontos", PackedVector2Array()))
	if pts.size() < 2:
		return "recusado: caminho vazio"
	return _adotar_traco(pts, mundo, true, alvos)


## TRAÇO AO VIVO (v0.7): a rota é refeita a cada quadro com o desenho até
## agora; a criatura já caminha por ela. `pontos[0]` é a ORIGEM congelada (onde
## ela estava quando o dedo desceu) — quem chama põe esse ponto.
## `inicio` = primeiro quadro do gesto: se ela se mexeu até aqui, o traço
## ganha na frente o trecho que a traz de volta ao começo.
func tracar(pontos: PackedVector2Array, mundo: RefCounted, inicio := false, alvos: Array = []) -> String:
	return _adotar_traco(pontos, mundo, inicio, alvos)


## Guarda o traço cru, monta a rota e as marcas (travessias). Devolve o texto
## para a HUD. O traço é obedecido COMO FOI DESENHADO (o bico anda).
func _adotar_traco(pontos: PackedVector2Array, mundo: RefCounted, inicio: bool, alvos: Array) -> String:
	if pontos.size() < 2:
		return "recusado: caminho vazio"
	if inicio:
		traco_t = 0.0
	traco = pontos.duplicate()
	var nova := _pontos_de_rota(traco, mundo)
	if nova.is_empty():
		return "recusado: caminho curto"
	if inicio:
		# ela andou enquanto o dedo descia: põe NA FRENTE o trecho que a traz de
		# volta ao começo do traço (depois da simplificação, senão um traço reto
		# engoliria a volta e ela "cortaria" o caminho).
		var base := pos
		if base.distance_to(nova[0]) > float(rota_cfg.get("chegada_px", 12.0)):
			var com_volta := PackedVector2Array([base])
			com_volta.append_array(nova)
			nova = com_volta
	_guardar_rota(nova, inicio)
	_montar_marcas(alvos)
	return "ok: rota de %d px" % int(total_rota)


## O traço vira PONTOS DE REFERÊNCIA: DESCONTO INICIAL (o vai-e-volta do
## começo não é obedecido), Douglas-Peucker e a LIMPEZA DOS AMONTOADOS
## (v0.11.1: laço/cruzamento minúsculo e vai-e-volta nervoso não são andados).
func _pontos_de_rota(pts: PackedVector2Array, mundo: RefCounted) -> PackedVector2Array:
	if pts.size() < 2:
		return PackedVector2Array()
	var cortado := Trajetoria.descontar_inicio(pts, float(rota_cfg.get("desconto_raio_px", 44.0)),
		float(rota_cfg.get("desconto_janela_px", 140.0)))
	if cortado.size() < pts.size() and cortado.size() >= 2:
		# se a reta até o ponto de alinhamento atravessa parede, o desvio
		# inicial era necessário: não corta.
		if mundo.caminho_livre(pts[0], cortado[1], camada):
			pts = cortado
	var nova := Trajetoria.simplificar(pts, float(rota_cfg.get("simplificar_px", 10.0)))
	# AMONTOADO: retorno a uma zona do tamanho do animal em poucos px de arco.
	# O atalho só vale se for andável (não pula para o outro lado de um tronco).
	var livre := func(a: Vector2, b: Vector2) -> bool:
		return mundo.caminho_livre(a, b, camada)
	nova = Trajetoria.limpar_amontoados(nova,
		float(rota_cfg.get("amontoado_raio_px", 24.0)),
		float(rota_cfg.get("amontoado_janela_px", 100.0)), livre)
	if nova.size() < 2 or Trajetoria.comprimento(nova) < 6.0:
		return PackedVector2Array()
	return nova


## Adota `nova` como rota. `reiniciar` zera o progresso (rota nova); sem ele o
## progresso é preservado (o traço ao vivo só CRESCE no fim). Nunca fica
## mirando um ponto que já está ao alcance.
func _guardar_rota(nova: PackedVector2Array, reiniciar: bool) -> void:
	# MARCHA (v0.45): sair do repouso decide de novo; crescer o traço só PROMOVE
	# (caminhada → trote). Rota nova desenhada em movimento não rebaixa o trote.
	var partindo := rota.is_empty() and not em_inercia()
	rota = nova
	total_rota = Trajetoria.comprimento(rota)
	if partindo:
		trote = false
	if total_rota > caminhada_max_px and not trote:
		trote = true
		_rampa_t = 0.0  # acelera da caminhada para o trote, sem salto
	_arcos_rota = Trajetoria.arcos_pontos(rota)
	_inercia_t = 0.0  # caminho novo cancela a inércia do antigo
	_barrado = false
	autonomia = ""
	_auto_destino = Vector2.ZERO
	if reiniciar:
		_rota_i = 0
		rota_t = 0.0
		_desvios = 0
		_desvio_lado = 0.0
		_desvio_ref = 0.0
		_desvio_inicio_s = 0.0
		_desvio_angulo = 0.0
		_dir_suave = Vector2.ZERO
		_olhar_suave = Vector2.ZERO
		# um traço ao vivo que CONTINUA um SEGURAR (o dedo não levantou)
		# nasce com a criatura já embalada: a rota nova não corta o sprint nem a
		# cauda. Caminho novo de verdade (sem segurar) zera como antes.
		if not _sprint:
			_sprint_cauda_t = 0.0
		# v0.18: rota nova joga fora a CARGA (um tiro carregado vale para o
		# caminho que o jogador acabou de fechar) e REARMA a rampa de
		# aceleração do começo da caminhada.
		_carga_ativa = false
		_carga_t = 0.0
		_carga_alvo_id = ""
		_carga_tem_destino = false
		_carga_destino = Vector2.ZERO
		# mesma regra do sprint: continuar um segurar mantém a rampa já vencida.
		# rota nova em cima de um TROTE já em curso mantém a velocidade da
		# corrida (v0.45): quem já corre segue correndo, seja qual for o traço.
		if not _sprint and not trote:
			_rampa_t = 0.0
		marcas = []
		_disparadas = {}
		mira_final_id = ""
		_perseguindo = false
		_embalo_final_feito = false
		_turbo_t = 0.0
		# a "estrada" ganha fases próprias (mesma semente = mesmo passeio)
		_fase1 = rng.randf() * TAU
		_fase2 = rng.randf() * TAU
		eventos.append("rota:nova")
	if _rota_i >= rota.size():
		_rota_i = maxi(0, rota.size() - 1)


# ---------------------------------------------------------------- marcas (travessias)

## Monta as marcas pendentes: as TRAVESSIAS de alvo na rota. O que já acendeu
## não volta.
func _montar_marcas(alvos: Array) -> void:
	# travessias: refeitas a cada atualização (a rota cresce)
	for m in marcas.duplicate():
		if str(m["tipo"]) == "batida":
			marcas.erase(m)
	_marcas_de_travessia(alvos)
	# a MARCA do alvo nasce durante o caminho: quando a PONTA do traço o alcança
	# — e SAI se a ponta segue e deixa o alvo para trás (v0.11.4).
	if rota.size() >= 2:
		var ponta: Vector2 = rota[rota.size() - 1]
		_soltar_marca_longe_da_ponta(alvos, ponta)
		_marcar_alvo_no_fim(alvos, ponta)


func _tem_marca(chave: String) -> bool:
	for m in marcas:
		if str(m["chave"]) == chave:
			return true
	return false


## Alvos que a ROTA atravessa (a linha passou por cima): marca de BATIDA no
## ponto mais perto da rota. Empurra quem sabe reagir (adversário); árvore só
## leva a batida.
func _marcas_de_travessia(alvos: Array) -> void:
	if rota.size() < 2 or alvos.is_empty():
		return
	var cruza := float(_combate.get("batida_cruza_px", 8.0))
	for a in alvos:
		if not a.get("travavel", false):
			continue
		var alvo_p: Vector2 = a["pos"]
		var limite := float(a["raio"]) + cruza
		var melhor := Vector2.ZERO
		var melhor_d := limite
		var melhor_dir := Vector2.ZERO
		for i in range(1, rota.size()):
			var a0 := rota[i - 1]
			var a1 := rota[i]
			var ab := a1 - a0
			var l2 := ab.length_squared()
			if l2 < 0.0001:
				continue
			var t := clampf((alvo_p - a0).dot(ab) / l2, 0.0, 1.0)
			var q := a0 + ab * t
			var d := q.distance_to(alvo_p)
			if d <= melhor_d:
				melhor_d = d
				melhor = q
				melhor_dir = ab.normalized()
		if melhor == Vector2.ZERO and melhor_d >= limite:
			continue
		var chave := "batida:%s:%d,%d" % [str(a["id"]), roundi(melhor.x), roundi(melhor.y)]
		if _disparadas.has(chave) or _tem_marca(chave):
			continue
		marcas.append({
			"tipo": "batida", "ponto": melhor, "alvo_id": str(a["id"]),
			"dir": melhor_dir, "chave": chave,
		})


## O gatilho: a criatura passou pelo ponto da marca (até
## `combate.batida_gatilho_px`). Devolve nada; os eventos vão para a fila.
func _checar_marcas(alvos: Array) -> void:
	if marcas.is_empty():
		return
	var raio := float(_combate.get("batida_gatilho_px", 24.0))
	for m in marcas.duplicate():
		# batida: acende no ponto da travessia
		if pos.distance_to(Vector2(m["ponto"])) <= raio:
			_disparar(m, alvos)


func _disparar(m: Dictionary, alvos: Array) -> void:
	marcas.erase(m)
	_disparadas[str(m["chave"])] = true
	match str(m["tipo"]):
		"batida":
			var id := str(m["alvo_id"])
			var a := Alvos.por_id(alvos, id)
			if a.is_empty():
				return
			if pos.distance_to(Vector2(a["pos"])) > float(_combate.get("batida_tol_px", 34.0)) + float(a["raio"]):
				return
			Alvos.empurrar(alvos, id, Vector2(m["dir"]), float(_combate.get("batida_empurrao", 26.0)))
			_cmd_golpe("batida", Vector2(m["dir"]))
			# EMBALO LONGO do empurrão: passa mais rápido pelo alvo e desacelera
			_iniciar_embalo(float(_embalo.get("longo_s", 0.6)), float(_embalo.get("longo_fator", 2.0)))
			eventos.append("batida:" + id)
			eventos.append("acerto:" + id)


## EMBALO (v0.9.2): um "pico" de velocidade que sobe e desce suave
## (`sin(π·u)`). Curto na marcação do alvo final; longo no empurrão.
func _iniciar_embalo(duracao: float, fator: float) -> void:
	_turbo_dur = maxf(duracao, 0.05)
	_turbo_t = _turbo_dur
	_turbo_fator = maxf(fator, 1.0)


func _fator_embalo() -> float:
	if _turbo_t <= 0.0 or _turbo_dur <= 0.0:
		return 1.0
	var u := clampf(1.0 - _turbo_t / _turbo_dur, 0.0, 1.0)
	return 1.0 + (_turbo_fator - 1.0) * sin(PI * u)


## Quanto o SPRINT acelera AGORA (1,0 = normal). Com o dedo parado e energia é
## o fator cheio; SOLTOU (ou a energia acabou), a CAUDA (v0.11.4) mantém parte
## do embalo e cai aos poucos por `sprint.cauda_s` — é ela que deixa pular logo
## depois de soltar e ainda ir mais longe.
func _fator_sprint() -> float:
	var cheio := maxf(float(_sprint_cfg.get("fator", 1.7)), 1.0)
	if _sprint and energia > 0.0:
		return cheio
	if _sprint_cauda_t <= 0.0:
		return 1.0
	var dur := maxf(float(_sprint_cfg.get("cauda_s", 0.6)), 0.01)
	var u := clampf(_sprint_cauda_t / dur, 0.0, 1.0)
	return 1.0 + (cheio - 1.0) * u


## Duração da RAMPA de aceleração do começo da caminhada (`rota.rampa_s`, 0,30 s).
func _rampa_s() -> float:
	return maxf(float(rota_cfg.get("rampa_s", 0.30)), 0.0001)


## Quanto da velocidade vale AGORA no começo da caminhada: 0,15 → 1,0 em
## `rampa_s`, com smoothstep (`u*u*(3-2u)`). Nunca zero — senão o `_barrado`
## confundiria "começando a andar" com "parado na barreira".
func _fator_rampa() -> float:
	var u := clampf(_rampa_t / _rampa_s(), 0.0, 1.0)
	return 0.15 + 0.85 * (u * u * (3.0 - 2.0 * u))


## Deslocamento do quadro (px) com todos os fatores da regra de movimento.
func _passo_camera(v: float, dt: float) -> float:
	return v * dt


# ---------------------------------------------------------------- efeitos

## Tiros: andam na direção do disparo e param no primeiro alvo.
func _atualizar_efeitos(dt: float, alvos: Array) -> void:
	for e in efeitos.duplicate():
		if str(e["tipo"]) == "tiro":
			var quanto := float(e["velocidade"]) * dt
			e["pos"] = Vector2(e["pos"]) + Vector2(e["dir"]) * quanto
			e["andado"] = float(e["andado"]) + quanto
			var bateu := ""
			for a in alvos:
				if not Alvos.reage(a):
					continue
				if Vector2(e["pos"]).distance_to(Vector2(a["pos"])) <= float(e["raio"]) + float(a["raio"]):
					bateu = str(a["id"])
					break
			if bateu != "":
				# o empurrão do tiro vem do EFEITO (a carga o escala); o dado
				# `combate.tiro_empurrao` é o piso de um tiro sem carga.
				Alvos.empurrar(alvos, bateu, Vector2(e["dir"]),
					float(e.get("empurrao", _combate.get("tiro_empurrao", 24.0))))
				eventos.append("acerto:" + bateu)
				efeitos.erase(e)
			elif float(e["andado"]) >= float(e["alcance"]):
				efeitos.erase(e)


## O FIM do traço: se ele terminou EM CIMA de um adversário, ele fica marcado
## como alvo do golpe final — a marca vai NELE (e anda com ele!) até a criatura
## chegar. Devolve o texto para a HUD.
func finalizar_rota(alvos: Array) -> String:
	_montar_marcas(alvos)
	_checar_marcas(alvos)
	if rota.is_empty():
		return ""
	return _marcar_alvo_no_fim(alvos, rota[rota.size() - 1])


## A MARCA do alvo (v0.10): o FIM do caminho alcançou um adversário? Ele fica
## marcado — a marca ANDA com ele e vale para o TIRO (toque duplo) e para o
## GOLPE FINAL. Ela está ligada ao CAMINHO: sai no golpe físico (ou quando o
## caminho é trocado). Chamada também a cada quadro do desenho (marca viva).
func _marcar_alvo_no_fim(alvos: Array, fim: Vector2) -> String:
	var melhor := {}
	var melhor_d := float(_combate.get("mira_final_raio", 34.0))
	for a in alvos:
		if not Alvos.reage(a):
			continue
		var d: float = fim.distance_to(Vector2(a["pos"])) - float(a["raio"])
		if d <= melhor_d:
			melhor = a
			melhor_d = d
	if melhor.is_empty():
		return ""
	if mira_final_id == str(melhor["id"]):
		return "ok: alvo marcado"
	mira_final_id = str(melhor["id"])
	_embalo_final_feito = false
	eventos.append("mira_final:" + mira_final_id)
	return "ok: alvo marcado"


## v0.11.4 — a MARCA acompanha a PONTA, não a PASSAGEM: se o caminho passou por
## cima do alvo (batida/empurrão) e continuou, terminando LONGE dele, a marca
## SAI. Sem isso a criatura chegava ao fim e VOLTAVA para dar o golpe de
## perseguição num alvo que só tinha empurrado de passagem.
func _soltar_marca_longe_da_ponta(alvos: Array, ponta: Vector2) -> void:
	if mira_final_id == "":
		return
	var a := Alvos.por_id(alvos, mira_final_id)
	if a.is_empty():
		mira_final_id = ""
		eventos.append("mira_final:perde")
		return
	var d: float = ponta.distance_to(Vector2(a["pos"])) - float(a["raio"])
	if d > float(_combate.get("mira_final_raio", 34.0)):
		mira_final_id = ""
		_embalo_final_feito = false
		eventos.append("mira_final:")


## O golpe físico que FECHA o caminho: perto do alvo marcado, bate e empurra,
## e a MARCA SAI (ela está ligada ao caminho). O animal só bate se chegou
## perto — quem persegue é `_perseguir`.
func _golpe_final(alvos: Array) -> void:
	var id := mira_final_id
	mira_final_id = ""
	_perseguindo = false
	if id == "":
		return
	var a := Alvos.por_id(alvos, id)
	if a.is_empty():
		eventos.append("mira_final:perde")
		return
	var dir: Vector2 = Vector2(a["pos"]) - pos
	if dir.length() < 0.5:
		dir = olhar
	dir = dir.normalized()
	_cmd_golpe("ataque", dir)
	Alvos.empurrar(alvos, id, dir, float(_combate.get("mira_final_empurrao", 44.0)))
	eventos.append("acerto:" + id)
	eventos.append("golpe_final:" + id)


func _cmd_ataque() -> String:
	# a direção do golpe NÃO vem do gesto: é a ROTA (sem rota, o olhar)
	var para: Vector2 = olhar
	if em_rota():
		para = _tangente_em_rota(rota_t)
	return _cmd_golpe("ataque", para)


## Golpe genérico (ataque físico ou batida): mesma máquina de fases, mesma
## recarga por nome. O `ataque` guarda QUAL golpe está em curso.
func _cmd_golpe(nome: String, dir: Vector2) -> String:
	if not defs.has(nome):
		return "recusado: sem %s definido" % nome
	if float(_recargas.get(nome, 0.0)) > 0.0:
		return "recusado: recarga"
	if ataque != "":
		return "recusado: golpe em curso"
	if dir.length() < 0.01:
		dir = olhar
	ataque = nome
	ataque_t = 0.0
	ataque_dir = dir.normalized()
	olhar = ataque_dir
	eventos.append("golpe:" + nome)
	return "ok: %s" % ("atacando" if nome == "ataque" else "batendo")


func _cmd_pular(cmd: Dictionary) -> String:
	if camada == Mundo.SUBSOLO:
		return "recusado: no subsolo não dá para pular"
	if float(_recargas.get("pular", 0.0)) > 0.0:
		return "recusado: recarga"
	if no_ar():
		# v0.11.4: o pulo pedido NO AR é PERCEBIDO na hora e só é EXECUTADO
		# quando a animação do atual termina (emenda; sem esperar o toque cair).
		var buffer := maxf(float(defs.get("pular", {}).get("buffer_s", 0.6)), 0.0)
		if buffer <= 0.0:
			return "recusado: já está no ar"
		if _pulo_fila_t > 0.0:
			return "ok: pulo já na fila"
		_pulo_fila_t = buffer
		eventos.append("pulo:fila")
		return "ok: pulo na fila"
	_iniciar_pulo()
	return "ok: pulando"


## Começa o arco do pulo em si (fases em `dados/acoes.json`). Separado do
## comando porque a FILA (v0.11.4) precisa disparar o próximo sem passar pelo
## comando de novo.
func _iniciar_pulo() -> void:
	var d: Dictionary = defs.get("pular", {"fases": [0.06, 0.42, 0.06], "altura": 26.0})
	_pulo_dur = maxf(float(d.get("fases", [0.06, 0.42, 0.06])[1]), 0.1)
	_pulo_t = _pulo_dur
	_pulo_altura = float(d.get("altura", 26.0))
	eventos.append("pulo:on")


## TIRO DO TOQUE (v0.18; v0.19 com o TEMPO configurável) — **CARREGADO**.
##
## - já carregando: `"ok: carregando"` (o toque repetido não reinicia);
## - em RECARGA: `"recusado: recarga"`;
## - captura o ALVO MARCADO e o DESTINO FINAL (último ponto da rota, se ≥ 2);
## - sem alvo e sem destino: `"recusado: sem destino"` — a direção NUNCA é o
##   toque;
## - `carga_tiro_s` = 0 (instantâneo): dispara NA HORA dentro deste comando,
##   sem estado de carga (`"ok: tiro"`) e com o tiro BASE (carga 0) — a HUD não
##   chega a ver "CARREGANDO";
## - senão começa a CARGA: `_carga_t` de 0 até `carga_tiro_s`, com o animal
##   PARADO (o ramo da carga no `passo` retorna antes de andar), e o disparo sai
##   SOZINHO no teto, com o tamanho proporcional ao tempo (`_disparar_carga`).
##
## `cmd` continua na assinatura porque o comando do gesto carrega o toque em
## `alvo`, mas ele NÃO é usado. A carga só é cancelada por um caminho novo ou
## por um segurar.
func _cmd_tiro(_cmd: Dictionary, alvos: Array) -> String:
	if _carga_ativa:
		return "ok: carregando"
	if float(_recargas.get("tiro", 0.0)) > 0.0:
		return "recusado: recarga"
	_capturar_carga()
	if _carga_alvo_id == "" and not _carga_tem_destino:
		_zerar_carga()
		return "recusado: sem destino"
	# v0.19: TEMPO 0 = INSTANTÂNEO. O tiro base sai agora, sem estado de carga;
	# o tamanho fica com `_disparar_carga`, que lê `carga_tiro_s` (0).
	if carga_tiro_s <= 0.001:
		_disparar_carga(alvos)
		return "ok: tiro"
	_iniciar_carga()
	return "ok: carregando"


## Cria o projétil. Quem chama decide a direção; `carga` (0..1) escala `raio`,
## `alcance` e `empurrao` do efeito. O tiro do TOQUE passa
## `carga_tiro_s / tiro_carga_max_s()`: 0 = tiro BASE, 1 = tiro MÁXIMO.
func _atirar(dir: Vector2, carga := 0.0) -> void:
	var c := clampf(carga, 0.0, 1.0)
	efeitos.append({
		"tipo": "tiro", "pos": pos, "dir": dir,
		"raio": float(_combate.get("tiro_raio", 9.0)) * _escala_carga(c, "tiro_carga_raio_x"),
		"andado": 0.0,
		"alcance": float(_combate.get("tiro_alcance", 280.0)) * _escala_carga(c, "tiro_carga_alcance_x"),
		"empurrao": float(_combate.get("tiro_empurrao", 24.0)) * _escala_carga(c, "tiro_carga_empurrao_x"),
		"velocidade": float(_combate.get("tiro_velocidade", 420.0)),
	})


## Quanto uma grandeza do tiro cresce com a carga: `1 + (x - 1) * carga`, com
## `x` vindo de `combate` (`tiro_carga_raio_x`, `..._alcance_x`, `..._empurrao_x`).
## `x` = 1 (ou ausente) não escala nada.
func _escala_carga(carga: float, chave: String) -> float:
	var x := maxf(float(_combate.get(chave, 1.0)), 1.0)
	return 1.0 + (x - 1.0) * clampf(carga, 0.0, 1.0)


## SEGURAR (v0.16) — **CORRER**; sem caminho, a HABILIDADE:
##
## - já carregando o tiro: **ZERA a carga** (o jogador mudou de ideia e vai
##   correr) e segue;
## - com **caminho** em curso e energia: liga o SPRINT CONTÍNUO (gasta a barra
##   de ENERGIA enquanto o dedo fica; o soltar mantém a CAUDA);
## - sem caminho (ou sem energia para correr): a HABILIDADE em si mesmo
##   (cavar), ativada no limiar do segurar.
func _cmd_segurar(mundo: RefCounted) -> String:
	if _carga_ativa:
		_zerar_carga()
	if em_rota():
		if energia <= float(_sprint_cfg.get("minimo", 0.08)):
			return "recusado: sem energia"
		if _sprint:
			return "ok: já em sprint"
		if not trote:
			# corrida acelerada não existe em cima de uma caminhada: assume o
			# trote e acelera pela rampa (sem salto de 28 → 187 px/s).
			trote = true
			_rampa_t = 0.0
		_sprint = true
		eventos.append("sprint:on")
		return "ok: sprint"
	_sprint = false
	return _cmd_habilidade(mundo)


## SOLTAR o segurar (v0.16): DESLIGA o sprint, com a CAUDA mantendo o embalo
## (`sprint.cauda_s`). **Não dispara tiro** — o tiro agora é o TOQUE, que
## carrega e dispara sozinho.
func _cmd_soltar_segurar() -> String:
	if _sprint:
		_sprint = false
		# v0.11.4: a CAUDA mantém o embalo por um tempo (o teste de "pular
		# ainda acelerado" depende dela).
		_sprint_cauda_t = maxf(float(_sprint_cfg.get("cauda_s", 0.6)), 0.0)
		eventos.append("sprint:off")
	return "ok"


## Copia o que o tiro precisa no começo da carga: o DESTINO FINAL do caminho
## (se ele tem ≥ 2 pontos) e o alvo marcado.
func _capturar_carga() -> void:
	_carga_tem_destino = rota.size() >= 2
	_carga_destino = rota[rota.size() - 1] if _carga_tem_destino else Vector2.ZERO
	_carga_alvo_id = mira_final_id


## Começa a CARGA: o corpo para (o `passo` volta antes de andar) e `_carga_t`
## cresce até `carga_tiro_s`. O teto é TRAVADO aqui, no começo: mudar o slider
## no meio não reinicia nem encurta o preparo em curso (o TAMANHO do disparo,
## sim, é lido no disparo). Com `carga_tiro_s` = 0 não há preparo — quem trata
## o instantâneo é o `_cmd_tiro`.
func _iniciar_carga() -> void:
	_carga_ativa = true
	_carga_t = 0.0
	_carga_max_s = maxf(carga_tiro_s, 0.0)
	if _carga_max_s > 0.001:
		eventos.append("carga:on")


## Zera a carga (depois do disparo, de uma recusa ou de um cancelamento). O
## alvo MARCADO (`mira_final_id`) não é tocado: a marca pertence ao caminho.
func _zerar_carga() -> void:
	_carga_ativa = false
	_carga_t = 0.0
	_carga_alvo_id = ""
	_carga_tem_destino = false
	_carga_destino = Vector2.ZERO


## Dispara a CARGA no teto (o `passo` chama ao completar `carga_tiro_s`; com o
## tempo em 0 o próprio `_cmd_tiro` chama). Direção: **alvo marcado vivo** →
## **destino capturado** → `olhar`. A carga passada ao `_atirar` é o TAMANHO do
## tiro, `carga_tiro_s / tiro_carga_max_s()`: 0 = base (9/280/24) · 1 = máximo
## (13,5/448/48), linear no meio. Deixa a recarga e a pausa curta do tiro, e
## zera a carga.
func _disparar_carga(alvos: Array) -> void:
	var dir := Vector2.ZERO
	if _carga_alvo_id != "":
		var a := Alvos.por_id(alvos, _carga_alvo_id)
		if not a.is_empty():
			dir = Vector2(a["pos"]) - pos
	if dir.length() < 0.5 and _carga_tem_destino:
		dir = _carga_destino - pos
	if dir.length() < 0.5:
		dir = olhar
	if dir.length() < 0.01:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	_atirar(dir, clampf(carga_tiro_s / tiro_carga_max_s(), 0.0, 1.0))
	olhar = dir
	_recargas["tiro"] = float(_combate.get("tiro_recarga_s", 1.0))
	_pausa_t = maxf(_pausa_t, float(_combate.get("tiro_pausa_s", 0.25)))
	eventos.append("tiro:disparo")
	_zerar_carga()


## HABILIDADE EM SI MESMO (v0.9): o que era o gesto de escavar virou a
## habilidade do segurar parado. Ela dura um tempo e acontece sem sair do lugar.
## A primeira é `cavar` (a que existia); outras entram em `dados/acoes.json`
## com "duracao".
func _cmd_habilidade(mundo: RefCounted) -> String:
	if habilidade_ativa():
		return "recusado: habilidade em curso"
	if float(_recargas.get("habilidade", 0.0)) > 0.0:
		return "recusado: recarga"
	var nome: String = str(defs.get("habilidade", {}).get("nome", "cavar"))
	if nome == "cavar":
		return _cmd_cavar(mundo)
	if not defs.has(nome):
		return "recusado: habilidade desconhecida (%s)" % nome
	var d: Dictionary = defs[nome]
	habilidade = nome
	habilidade_dur = maxf(float(d.get("duracao", 1.0)), 0.1)
	habilidade_t = 0.0
	eventos.append("habilidade:on")
	return "ok: %s" % nome


func _cmd_cavar(mundo: RefCounted) -> String:
	if escavando:
		return "recusado: cavando"
	var c: Vector2i = mundo.celula_de(pos)
	if not mundo.pode_escavar(c, camada):
		return "recusado: aqui não dá para cavar"
	escavando = true
	var d: Dictionary = defs.get("cavar", {"fases": [0.15, 0.55, 0.15]})
	_escavar_dur = maxf(float(d.get("fases", [0.15, 0.55, 0.15])[1]), 0.1)
	_escavar_t = 0.0
	_escavar_celula = c
	eventos.append("habilidade:on")
	return "ok: cavando"


var _escavar_t := 0.0
var _escavar_dur := 0.0
var _escavar_celula := Vector2i.ZERO


# ---------------------------------------------------------------- avanço

func passo(dt: float, mundo: RefCounted, alvos: Array = []) -> void:
	_invencivel_t = maxf(_invencivel_t - dt, 0.0)
	atordoado_t = maxf(atordoado_t - dt, 0.0)
	for k in _recargas.keys():
		_recargas[k] = maxf(0.0, float(_recargas[k]) - dt)
	_atualizar_pulo(dt)
	_atualizar_ataque(dt)
	_atualizar_habilidade(dt)
	_atualizar_efeitos(dt, alvos)
	_turbo_t = maxf(_turbo_t - dt, 0.0)
	_sprint_cauda_t = maxf(_sprint_cauda_t - dt, 0.0)
	# ENERGIA do sprint: gasta acelerando no caminho, recupera parada/andando
	if _sprint and em_rota() and energia > 0.0:
		energia = maxf(0.0, energia - float(_sprint_cfg.get("gasto_s", 0.45)) * dt)
		if energia <= 0.0:
			_sprint = false
			_sprint_cauda_t = maxf(float(_sprint_cfg.get("cauda_s", 0.6)), 0.0)
			eventos.append("sprint:off")
	else:
		energia = minf(1.0, energia + float(_sprint_cfg.get("recarga_s", 0.22)) * dt)
	if escavando:
		_atualizar_escavar(dt, mundo)
		pos = mundo.centro(_escavar_celula)
		return
	# GOLPE DO INIMIGO (v0.14): o empurrão desliza e, ATORDOADA, ela não anda
	# nem obedece. A rota fica guardada e retoma quando o atordoamento passa.
	if _empurrao_ext.length() > 0.01:
		_aplicar_empurrao(dt, mundo)
	if atordoado_t > 0.0:
		return
	# pausa curta do tiro: para para atirar e depois segue
	if _pausa_t > 0.0:
		_pausa_t = maxf(_pausa_t - dt, 0.0)
		_checar_marcas(alvos)
		return
	# CARGA do tiro do TOQUE (v0.18/v0.19): o animal PARA enquanto carrega (a
	# rota fica guardada e ele retoma depois do tiro). A carga não gasta energia
	# e tem teto em `carga_tiro_s`, travado no começo por `_iniciar_carga`; ao
	# completá-lo o tiro sai SOZINHO, com o tamanho proporcional ao tempo.
	if _carga_ativa:
		_carga_t = minf(_carga_t + dt, _carga_max_s)
		if _carga_t >= _carga_max_s - 0.0001:
			_disparar_carga(alvos)
		else:
			_checar_marcas(alvos)
		return
	if em_rota():
		pos = _avancar_rota(dt, mundo, alvos)
	elif em_inercia():
		_avancar_inercia(dt, mundo)
	elif _perseguindo:
		_perseguir(dt, mundo, alvos)
	else:
		_autonomia(dt, mundo)
	_checar_marcas(alvos)


## Desliza o empurrão externo (golpe do inimigo) até gastá-lo. O mundo corta o
## passo — ele não é jogado para dentro da água nem de uma parede.
func _aplicar_empurrao(dt: float, mundo: RefCounted) -> void:
	var dir := _empurrao_ext.normalized()
	var quanto := minf(float(_reacao_cfg.get("empurrao_velocidade", 420.0)) * dt, _empurrao_ext.length())
	var novo: Vector2 = mundo.limitar_segmento(pos, pos + dir * quanto, camada)
	var andado := novo.distance_to(pos)
	pos = novo
	_empurrao_ext -= dir * andado
	if andado < 0.01:
		_empurrao_ext = Vector2.ZERO


## Avança a rota como uma ESTRADA (v0.9.1/v0.11.1): a criatura segue o traço
## por dentro de uma FAIXA (pode ir mais à esquerda, à direita ou no centro),
## mira o ponto mais LONGE que a VISÃO alcança andando (a curva é contornada,
## não cortada por dentro de uma pedra/água) e vai até o FIM na velocidade
## normal. Não há mais freio antes do fim: a frenagem é a INÉRCIA
## (`_iniciar_inercia`), fora da rota. Se um passo for barrado, a rota NÃO é
## apagada: para (`barrado()`) e espera — um pulo passa por cima e retoma.
func _avancar_rota(dt: float, mundo: RefCounted, alvos: Array) -> Vector2:
	if rota.is_empty() or total_rota <= 0.001:
		return _terminar_rota(alvos)
	var base := pos
	# RAMPA DE ACELERAÇÃO (v0.18): o começo da caminhada NOVA é mais lento
	# (15% → 100% em `rota.rampa_s`, smoothstep). O relógio só anda quando a
	# criatura anda de fato; a carga/pausa não o consome.
	_rampa_t = minf(_rampa_t + dt, _rampa_s())
	var fator_rampa := _fator_rampa()
	var fator_sprint := _fator_sprint()
	# PULO ACELERADO (v0.13): no AR, o sprint (ou a cauda dele) alonga o avanço
	# horizontal; no chão o fator é 1 e a caminhada não muda.
	var fator_ar := 1.0
	if no_ar() and fator_sprint > 1.001:
		fator_ar = maxf(float(defs.get("pular", {}).get("sprint_fator", 1.0)), 1.0)
	# o avanço que ela DEVERIA ter neste quadro: é o que desempata a projeção
	# num cruzamento/bico (dois braços no mesmo lugar) e impede o "pulo".
	var esperado := maxf(_passo_camera(velocidade_base() * fator_sprint * fator_ar * _fator_embalo() * fator_rampa, dt) * 2.0, 2.0)
	var proj := _projetar(base, esperado)
	# teto de segurança do avanço: um cruzamento/laço não pode "teleportar" a
	# criatura para o fim do braço; no máximo o que ela andaria em ~4 quadros.
	rota_t = minf(float(proj["s"]), rota_t + maxf(esperado * 4.0, 24.0))
	_rota_i = _indice_em(rota_t)
	if rota_t >= total_rota - float(rota_cfg.get("parada_px", 4.0)):
		return _terminar_rota(alvos)
	# EMBALO CURTO da marcação: ao chegar perto do alvo final, acelera para o
	# golpe (logo antes de bater), uma vez por marca.
	if mira_final_id != "" and not _embalo_final_feito:
		var alvo_f := Alvos.pos_de(alvos, mira_final_id)
		if alvo_f != Vector2.ZERO and pos.distance_to(alvo_f) <= float(_embalo.get("gatilho_px", 70.0)):
			_iniciar_embalo(float(_embalo.get("curto_s", 0.25)), float(_embalo.get("curto_fator", 1.7)))
			_embalo_final_feito = true
	var passo := _passo_camera(velocidade_base() * _fator_embalo() * fator_sprint * fator_ar * fator_rampa, dt)
	# ALVO: o ponto MAIS LONGE da estrada que a linha reta alcança andando.
	# Sem isso, a criatura corta a corda de uma curva e bate na pedra/beira.
	var alvo := _alvo_visivel(base, mundo)
	var contorno := bool(alvo.get("contorno", false))
	var s_alvo := float(alvo["s"])
	var centro := _ponto_em_rota(s_alvo)
	var tang := _tangente_em_rota(s_alvo)
	if tang.length() < 0.01:
		tang = olhar if olhar.length() > 0.01 else Vector2.RIGHT
	var meia := maxf(float(rota_cfg.get("estrada_largura_px", 30.0)) * 0.5, 0.0)
	var desvio := clampf(_desvio_organico(s_alvo), -meia, meia)
	var destino := centro
	var para_centro := centro - base
	if absf(desvio) > 0.01 and para_centro.length() > 0.5:
		# a onda lateral encolhe quando o alvo está PERTO (numa curva fechada a
		# distância em linha reta é bem menor que o arco) e nunca puxa para
		# trás: o desvio é só enfeite, não pode virar a criatura de lado.
		var escal := clampf(para_centro.length() / maxf(float(rota_cfg.get("olhar_px", 22.0)), 1.0), 0.0, 1.0)
		var desviado := centro + tang.orthogonal() * desvio * escal
		var dc := para_centro.normalized()
		var dd := desviado - base
		if dd.length() > 0.5 and dd.normalized().dot(dc) >= 0.5 \
				and mundo.caminho_livre(base, desviado, camada) \
				and mundo.bloqueio(mundo.celula_de(desviado), camada) == "":
			destino = desviado
	var para := destino - base
	if para.length() < 0.01:
		para = tang
	var desejado := para.normalized()
	# DIREÇÃO ESTÁVEL: filtra o alvo (mira 2 px de diferença não vira piscada)
	# e limita o giro por quadro. `_olhar_suave` é a direção DESENHADA; o corpo
	# ainda anda o passo real (a segurança do desvio é do `_passo_com_desvio`).
	var suavidade := maxf(float(rota_cfg.get("giro_suavidade", 10.0)), 0.0)
	var giro_max := maxf(float(rota_cfg.get("giro_max_graus_s", 720.0)), 0.0)
	if _dir_suave.length() < 0.01:
		_dir_suave = desejado
	_dir_suave = _suavizar_direcao(_dir_suave, desejado, dt, suavidade, giro_max)
	if _olhar_suave.length() < 0.01:
		_olhar_suave = olhar if olhar.length() > 0.01 else desejado
	var novo := _passo_com_desvio(base, _dir_suave, passo, destino, mundo, contorno)
	if novo.distance_to(base) < 0.001:
		_barrado = true
		_atualizar_traco_t(dt, base)
		_tentar_pulo_auto(mundo, base, _dir_suave, passo)
		return base
	_barrado = false
	var real := (novo - base).normalized()
	_olhar_suave = _suavizar_direcao(_olhar_suave, real, dt, suavidade, giro_max)
	olhar = _olhar_suave
	_atualizar_traco_t(dt, novo)
	return novo


## PULO AUTOMÁTICO (v0.13, com `pulo_auto` ligado): a rota parou diante de uma
## escada de UM nível para CIMA e o desenho CONTINUA em cima dela? Então o corpo
## pula sozinho, pelo mesmo `_iniciar_pulo` do toque duplo. O sistema aceita dois
## formatos de obstáculo:
##
## - a célula bloqueada já é o degrau (`^`/`b`: andável 1 nível acima);
## - ou há um VÃO DE ÁGUA curto antes do degrau (o pouso é a célula andável 1
##   nível acima, DENTRO do alcance do pulo).
##
## NÃO disparam: água no mesmo nível, rocha/objeto, degrau de 2+ níveis, caminho
## que ACABA na beirada, ou pouso longe demais (nesse caso um pulo cairia na
## água). Nesses casos o toque duplo continua sendo o gesto.
func _tentar_pulo_auto(mundo: RefCounted, base: Vector2, dir: Vector2, passo: float) -> bool:
	if not pulo_auto or no_ar() or camada == Mundo.SUBSOLO:
		return false
	if float(_recargas.get("pular", 0.0)) > 0.0:
		return false
	if dir.length() < 0.01 or total_rota - rota_t < PASSO_TERRENO * 2.0:
		return false
	# olha um pouco ALÉM do passo: a criatura para até 4 px antes da borda e o
	# passo de um quadro pode não chegar a invadir a célula do degrau.
	var olhar := maxf(passo + PASSO_TERRENO * 2.0, PASSO_TERRENO * 2.0)
	var bloq: Dictionary = _primeiro_bloqueio(base, base + dir.normalized() * olhar, mundo)
	if bloq.is_empty() or str(bloq.get("tipo", "")) != "terreno":
		return false
	var c: Vector2i = bloq["celula"]
	var c0: Vector2i = mundo.celula_de(base)
	var h0: float = mundo.altura(c0)
	# formato 1: a própria célula bloqueada é o degrau de 1 nível;
	# formato 2: um vão de água (altura 0) curto antes do degrau.
	var degrau_na_celula: bool = mundo.andavel(c, camada) and _um_nivel_acima(mundo, c, h0)
	var vao_de_agua: bool = not mundo.andavel(c, camada) and mundo.altura(c) <= 0.01 \
			and mundo.bloqueio(c, camada) == "terreno"
	if not degrau_na_celula and not vao_de_agua:
		return false
	# ALCANCE do pulo com os fatores de AGORA (sprint alonga o ar) — um pouso
	# fora disso cairia na água, então o sistema não dispara.
	var fs := _fator_sprint()
	var fator_ar := 1.0
	if fs > 1.001:
		fator_ar = maxf(float(defs.get("pular", {}).get("sprint_fator", 1.0)), 1.0)
	var dur := maxf(float(defs.get("pular", {}).get("fases", [0.06, 0.42, 0.06])[1]), 0.1)
	var alcance := velocidade_base() * fs * fator_ar * _fator_embalo() * dur * 0.9
	# O PONTO DE POUSO (1 nível acima) adiante na ROTA e a CONTINUAÇÃO depois
	# dele — é o que separa "degrau no meio do caminho" de "o caminho acaba".
	var cp := float(mundo.celula_px)
	var fim := minf(rota_t + cp * 3.0, total_rota - PASSO_TERRENO)
	var s := rota_t + PASSO_TERRENO
	while s <= fim:
		var p := _ponto_em_rota(s)
		var pc: Vector2i = mundo.celula_de(p)
		if pc != c0 and mundo.andavel(pc, camada) \
				and mundo.bloqueio(pc, camada) == "" \
				and _um_nivel_acima(mundo, pc, h0):
			if p.distance_to(base) > alcance:
				return false  # o pulo não chega: não pula para cair na água
			var s2 := s + cp * 0.75
			while s2 <= minf(rota_t + cp * 4.0, total_rota):
				var p2: Vector2i = mundo.celula_de(_ponto_em_rota(s2))
				if p2 != pc and mundo.andavel(p2, camada) \
						and mundo.bloqueio(p2, camada) == "" \
						and mundo.altura(p2) <= h0 + 1.01:
					_iniciar_pulo()
					eventos.append("pulo:auto")
					return true
				s2 += PASSO_TERRENO
			return false  # achou o degrau, mas o caminho acaba em cima dele
		s += PASSO_TERRENO
	return false


## A célula `c` está exatamente UM nível acima de `h0`?
func _um_nivel_acima(mundo: RefCounted, c: Vector2i, h0: float) -> bool:
	var dh: float = mundo.altura(c) - h0
	return dh >= 0.99 and dh <= 1.01


## Projeta a criatura na rota. Em vez de só a menor distância (que num
## cruzamento ou num bico aponta para o outro braço), o custo soma um desvio de
## ARCO em relação ao avanço esperado: o ponto certo é o que fica perto DESTA
## criatura e na CONTINUAÇÃO do trecho que ela já andou. Devolve {s, i, d}.
func _projetar(q: Vector2, esperado: float = -1.0) -> Dictionary:
	if rota.size() < 2 or _arcos_rota.size() < 2:
		return {"s": 0.0, "i": 0, "d": INF}
	var alvo_s := rota_t if esperado < 0.0 else rota_t + esperado
	var peso := float(rota_cfg.get("projecao_peso", 0.25))
	var melhor_custo := INF
	var melhor_s := 0.0
	var melhor_d := INF
	var melhor_i := 0
	for i in range(rota.size() - 1):
		var a := rota[i]
		var b := rota[i + 1]
		var ab := b - a
		var l2 := ab.length_squared()
		var t := 0.0
		if l2 > 0.0001:
			t = clampf((q - a).dot(ab) / l2, 0.0, 1.0)
		var p := a + ab * t
		var d := p.distance_to(q)
		var s := _arcos_rota[i] + ab.length() * t
		var custo := d + peso * absf(s - alvo_s)
		if custo < melhor_custo:
			melhor_custo = custo
			melhor_d = d
			melhor_i = i
			melhor_s = s
	return {"s": melhor_s, "i": melhor_i, "d": melhor_d}


## O ALVO da estrada: o ponto mais LONGE (até o nominal `olhar_px`) que a linha
## reta de `base` alcança ANDANDO (amostras de 2 px). Dois freios evitam cortar
## o desenho: o ponto precisa estar NA FRENTE do sentido atual (num bico, o
## braço de volta fica atrás e é rejeitado — é o que faz a criatura CHEGAR na
## ponta) e o alvo nominal dentro de um tronco é pulado (o desvio de objeto
## trabalha). Devolve {s, beyond}.
func _alvo_visivel(base: Vector2, mundo: RefCounted) -> Dictionary:
	var olhar_px := maxf(float(rota_cfg.get("olhar_px", 22.0)), 1.0)
	var s_ini := minf(rota_t + 1.0, total_rota)
	var s_nom := minf(rota_t + olhar_px, total_rota)
	var pulo := 0.0
	var pulo_max := maxf(float(rota_cfg.get("alvo_pulo_objeto_px", 56.0)), 0.0)
	while s_nom < total_rota - 0.01 and pulo < pulo_max \
			and mundo.bloqueio(mundo.celula_de(_ponto_em_rota(s_nom)), camada) == "objeto":
		s_nom = minf(s_nom + 6.0, total_rota)
		pulo += 6.0
	# CONTORNO DE TERRENO (v0.11.2): a ROTA (não a corda) entra em água/rocha
	# perto do horizonte e logo VOLTA a uma célula andável dentro de um raio do
	# animal? Então o destino não é a água — é a continuação do desenho. Mira a
	# continuação e libera o MESMO leque do tronco para contornar. Se a rota
	# termina dentro do bloqueio (ou a continuação está longe demais), não há
	# contorno: para na fronteira e só o PULO atravessa.
	var contorno := false
	var s_terra := -1.0
	var contorno_alcance := maxf(float(rota_cfg.get("contorno_alcance_px", 260.0)), 8.0)
	var contorno_raio := maxf(float(rota_cfg.get("contorno_raio_px", 128.0)), 8.0)
	var horizonte := minf(rota_t + olhar_px + 24.0, total_rota)
	var altura_base: float = mundo.altura(mundo.celula_de(base))
	var s_t := minf(rota_t + 2.0, total_rota)
	var p_antes := _ponto_em_rota(rota_t)
	var achou_barreira := false
	while s_t <= horizonte:
		var p_t := _ponto_em_rota(s_t)
		# BARREIRA = não dá para ANDAR da amostra anterior até esta: água,
		# rocha, DESNÍVEL (encosta) ou canto diagonal. Antes só `bloqueio`
		# era lido, então a encosta (célula andável, mas alta demais) passava
		# batida e a criatura esbarrava nela.
		if not mundo.caminho_livre(p_antes, p_t, camada):
			achou_barreira = true
			break
		p_antes = p_t
		s_t += PASSO_TERRENO
	if achou_barreira:
		var fim_t := minf(rota_t + contorno_alcance, total_rota)
		var s_v := s_t + PASSO_TERRENO
		while s_v <= fim_t:
			var p_t := _ponto_em_rota(s_v)
			var c_t: Vector2i = mundo.celula_de(p_t)
			# a continuação precisa ser uma célula ANDÁVEL e, fora do subsolo,
			# de um nível alcançável a partir daqui (senão é o topo da
			# encosta, não a volta do caminho).
			var nivel_ok: bool = camada == Mundo.SUBSOLO \
					or mundo.altura(c_t) <= altura_base + 0.5
			if mundo.bloqueio(c_t, camada) == "" and nivel_ok \
					and p_t.distance_to(base) <= contorno_raio:
				s_terra = s_v
				contorno = true
				break
			s_v += PASSO_TERRENO
	if contorno:
		s_nom = s_terra
	var tang_agora := _tangente_em_rota(rota_t)
	if tang_agora.length() < 0.01:
		tang_agora = olhar if olhar.length() > 0.01 else Vector2.RIGHT
	var limite := maxf(s_nom, s_ini)
	var melhor := -1.0
	var s := s_ini
	while s <= limite + 0.01:
		var p := _ponto_em_rota(s)
		var para := p - base
		# só o que está NA FRENTE: num bico (ida e volta sobre a mesma linha)
		# o braço de volta fica para trás e seria um "corte" da ponta.
		if para.length() > 0.5 and para.normalized().dot(tang_agora) < -0.05:
			s += 2.0
			continue
		if mundo.bloqueio(mundo.celula_de(p), camada) == "" \
				and mundo.caminho_livre(base, p, camada):
			melhor = s
		s += 2.0
	if melhor < 0.0:
		melhor = s_nom  # não há visão: tenta o nominal; o desvio/barreira decide
	# durante o desvio de um tronco, mantém o alvo ALÉM dele: trocar entre o
	# ponto visível de cá e o de lá fazia o lado do desvio piscar a cada quadro.
	if contorno:
		melhor = s_nom  # mira a CONTINUAÇÃO, mesmo que a corda cruze a água
	elif _desvios > 0 and s_nom > melhor:
		melhor = s_nom
	return {"s": melhor, "beyond": melhor > s_nom + 1.0, "contorno": contorno}


## Índice do segmento que contém o arco `s`.
func _indice_em(s: float) -> int:
	if _arcos_rota.size() < 2:
		return 0
	var i := 0
	while i < _arcos_rota.size() - 2 and _arcos_rota[i + 1] < s:
		i += 1
	return i


## Ponto da rota a `s` px de arco do começo.
func _ponto_em_rota(s: float) -> Vector2:
	if rota.is_empty():
		return Vector2.ZERO
	if s <= 0.0:
		return rota[0]
	if s >= total_rota or _arcos_rota.size() < 2:
		return rota[rota.size() - 1]
	for i in range(1, rota.size()):
		if _arcos_rota[i] >= s:
			var seg := _arcos_rota[i] - _arcos_rota[i - 1]
			var t := (s - _arcos_rota[i - 1]) / maxf(seg, 0.0001)
			return rota[i - 1].lerp(rota[i], t)
	return rota[rota.size() - 1]


## Direção da rota a `s` px de arco.
func _tangente_em_rota(s: float) -> Vector2:
	if rota.size() < 2 or _arcos_rota.size() < 2:
		return olhar
	var i := 0
	while i < rota.size() - 2 and _arcos_rota[i + 1] < s:
		i += 1
	var d := rota[i + 1] - rota[i]
	return d.normalized() if d.length() > 0.01 else olhar


## Desvio lateral do "caminho orgânico": duas senoides de fases sorteadas (a
## mesma semente dá o mesmo passeio). A criatura anda ora mais à esquerda, ora
## mais à direita da linha, dentro da estrada — o caminho não fica retilíneo.
func _desvio_organico(s: float) -> float:
	var o1 := maxf(float(rota_cfg.get("estrada_onda_px", 120.0)), 1.0)
	var o2 := maxf(float(rota_cfg.get("estrada_onda2_px", 47.0)), 1.0)
	var amp := float(rota_cfg.get("estrada_desvio_px", 9.0))
	return amp * (0.68 * sin(TAU * s / o1 + _fase1) + 0.32 * sin(TAU * s / o2 + _fase2))


## Suaviza uma DIREÇÃO (v0.11.3): mistura exponentialmente (tempo constante
## `suavidade`) e limita a velocidade angular (`max_graus_s`). O alvo pode
## oscilar 2 px por quadro; a criatura não precisa piscar a direção.
func _suavizar_direcao(atual: Vector2, alvo: Vector2, dt: float,
		suavidade: float, max_graus_s: float) -> Vector2:
	if alvo.length() < 0.01:
		return atual
	alvo = alvo.normalized()
	if atual.length() < 0.01:
		return alvo
	var ang := atual.angle()
	var delta := wrapf(alvo.angle() - ang, -PI, PI)
	var passo := delta * clampf(dt * maxf(suavidade, 0.0), 0.0, 1.0)
	var maxp := deg_to_rad(maxf(max_graus_s, 0.0)) * dt
	if maxp > 0.0:
		passo = clampf(passo, -maxp, maxp)
	return Vector2.from_angle(ang + passo)


## Atualiza o arco ANDADO do traço cru (v0.11.3): a linha apaga o pedaço que a
## criatura já passou. Projeta a posição no traço com o mesmo critério de
## continuidade da rota (distância + arco esperado) e NUNCA volta.
func _atualizar_traco_t(dt: float, p_atual: Vector2) -> void:
	if traco.size() < 2:
		return
	var arcos := Trajetoria.arcos_pontos(traco)
	var total := arcos[arcos.size() - 1]
	var esperado := maxf(velocidade_base() * maxf(dt, 0.0) * 2.0, 2.0)
	var alvo := traco_t + esperado
	var peso := 0.25
	var melhor := INF
	var melhor_s := 0.0
	for i in range(traco.size() - 1):
		var a := traco[i]
		var b := traco[i + 1]
		var ab := b - a
		var l2 := ab.length_squared()
		var t := 0.0
		if l2 > 0.0001:
			t = clampf((p_atual - a).dot(ab) / l2, 0.0, 1.0)
		var d := (a + ab * t).distance_to(p_atual)
		var s := arcos[i] + ab.length() * t
		var custo := d + peso * absf(s - alvo)
		if custo < melhor:
			melhor = custo
			melhor_s = s
	traco_t = maxf(traco_t, minf(melhor_s, traco_t + maxf(esperado * 4.0, 24.0)))
	traco_t = clampf(traco_t, 0.0, total)

## Um passo em direção a `dir`. No ar (pulo) ignora o chão — é o que permite
## pular por cima da barreira e seguir a rota. No chão, OBJETO (tronco) pode
## ser contornado com um pequeno desvio angular; TERRENO (água, rocha, altura)
## para a criatura.
func _passo_com_desvio(base: Vector2, dir: Vector2, passo: float, alvo: Vector2,
		mundo: RefCounted, permitir_terreno := false) -> Vector2:
	var ideal := base + dir * passo
	if no_ar():
		if mundo.dentro(mundo.celula_de(ideal)):
			return ideal
		return base
	# caiu na água/rocha? só outro pulo sai de lá; andar não atravessa a barreira
	if mundo.bloqueio(mundo.celula_de(base), camada) == "terreno":
		return base
	var fim: Vector2 = mundo.limitar_segmento(base, ideal, camada)
	if fim.distance_to(ideal) < 0.01:
		# o passo direto ESTÁ livre. Enquanto o contorno não ANDOU uma folga na
		# rota, ele não "volta" para a reta (senão, num canto de troncos, a
		# criatura fica indo e voltando na quina): continua o contorno e, se o
		# leque não der passo, aceita a reta.
		if _desvios > 0 and rota_t - _desvio_ref < float(rota_cfg.get("desvio_folga_px", 14.0)):
			var contorno := _desvio_leque(base, dir, passo, alvo, mundo)
			if contorno != base:
				return contorno
		else:
			_desvios = 0
			_desvio_lado = 0.0
			_desvio_ref = 0.0
			_desvio_inicio_s = 0.0
			_desvio_angulo = 0.0
		return fim
	var bloq: Dictionary = _primeiro_bloqueio(base, ideal, mundo)
	var tipo := str(bloq.get("tipo", ""))
	# no meio de um contorno ele CONTINUA mesmo que a leitura do alvo já não
	# veja o lago à frente (a projeção passou dele): senão pararia no meio.
	if tipo == "objeto" or (tipo == "terreno" and (permitir_terreno or _desvios > 0)):
		return _desvio_leque(base, dir, passo, alvo, mundo)
	return base


## O LEQUE de desvios de objeto (v0.6/v0.11.1): mantém o LADO escolhido
## (histerese) e troca de lado se aquele não passar. Devolve `base` se nada
## passar. Só é chamado quando o passo direto está bloqueado (ou quando o
## contorno ainda está comprometido).
func _desvio_leque(base: Vector2, dir: Vector2, passo: float, alvo: Vector2, mundo: RefCounted) -> Vector2:
	if _desvios >= int(rota_cfg.get("desvios_max", 80)):
		return base
	# TEIMOSIA (v0.11.2): se o contorno rodeia sem a rota andar (muro de água/
	# rocha sem volta), PARA na fronteira em vez de ficar indo e voltando. Um
	# pulo atravessa; um caminho novo reinicia.
	if _desvios >= int(rota_cfg.get("desvio_teimoso_apos", 36)) \
			and rota_t - _desvio_inicio_s < float(rota_cfg.get("desvio_teimoso_px", 6.0)):
		return base
	var angulos: Array = rota_cfg.get("desvio_angulos", [20.0, -20.0, 40.0, -40.0, 60.0, -60.0, 80.0, -80.0, 100.0, -100.0, 120.0, -120.0])
	# primeiro o ÂNGULO do quadro anterior: o contorno vira uma linha estável,
	# não uma escolha nova a cada quadro (era o "piscar" da direção).
	var tentativas: Array = []
	if absf(_desvio_angulo) > 0.01:
		tentativas.append([_desvio_angulo])
	if _desvio_lado != 0.0:
		var mesmo: Array = []
		for a in angulos:
			if signf(float(a)) == _desvio_lado:
				mesmo.append(a)
		if not mesmo.is_empty():
			tentativas.append(mesmo)
	tentativas.append(angulos)
	var melhor := base
	var melhor_d := INF
	var escolhido := 0.0
	for lista in tentativas:
		for a in lista:
			var cand_ideal := base + dir.rotated(deg_to_rad(float(a))) * passo
			var cand: Vector2 = mundo.limitar_segmento(base, cand_ideal, camada)
			if cand.distance_to(cand_ideal) > 0.01:
				continue
			var d: float = cand.distance_to(alvo)
			if d < melhor_d:
				melhor = cand
				melhor_d = d
				escolhido = float(a)
		if melhor != base:
			break
	if melhor == base:
		return base
	if _desvios == 0:
		_desvio_inicio_s = rota_t
	_desvio_lado = signf(escolhido)
	_desvio_angulo = escolhido
	_desvio_ref = rota_t
	_desvios += 1
	return melhor


## A primeira célula DIFERENTE da atual que o passo encontraria e que está
## bloqueada: devolve {"tipo": "objeto"|"terreno", "celula": ...}. É o que
## decide entre contornar (objeto) e parar (terreno/altura).
func _primeiro_bloqueio(base: Vector2, ideal: Vector2, mundo: RefCounted) -> Dictionary:
	var dist := base.distance_to(ideal)
	if dist < 0.01:
		return {}
	var passos := maxi(1, ceili(dist))
	var c0: Vector2i = mundo.celula_de(base)
	for i in range(1, passos + 1):
		var p := base.lerp(ideal, float(i) / passos)
		var c: Vector2i = mundo.celula_de(p)
		if c == c0:
			continue
		var b: String = mundo.bloqueio(c, camada)
		if b != "":
			return {"tipo": b, "celula": c}
		if not mundo.pode_andar(c0, c, camada):
			return {"tipo": "terreno", "celula": c}
		# mesma regra da DIAGONAL do `Mundo.limitar_segmento`: passar na
		# quina exige uma das duas vizinhas ortogonais livre. Sem isto o
		# primeiro bloqueio dizia "nada" enquanto o limitador parava — e a
		# criatura congelava na quina de dois troncos sem tentar o desvio.
		if c.x != c0.x and c.y != c0.y:
			var h := Vector2i(c.x, c0.y)
			var v := Vector2i(c0.x, c.y)
			if not (mundo.pode_andar(c0, h, camada) or mundo.pode_andar(c0, v, camada)):
				var bh: String = mundo.bloqueio(h, camada)
				var bv: String = mundo.bloqueio(v, camada)
				var tipo := "objeto" if (bh == "objeto" or bv == "objeto") else "terreno"
				return {"tipo": tipo, "celula": h if bh != "" else v}
	return {}


## Fim da rota: o GOLPE FINAL (se o fim caiu em cima de um adversário) ou a
## INÉRCIA (v0.11.1): a criatura passou o último ponto em velocidade normal e
## agora freia num pedaço curto FORA do caminho. O fim é calculado ANTES de
## limpar; não há salto para o último ponto.
func _terminar_rota(alvos: Array) -> Vector2:
	var fim: Vector2 = rota[rota.size() - 1] if not rota.is_empty() else pos
	# a rota pode acabar DURANTE o desenho (traço ao vivo): a marca é feita
	# aqui também, com o adversário onde ele está agora.
	if mira_final_id == "" and not rota.is_empty():
		_marcar_alvo_no_fim(alvos, fim)
	var mirado := mira_final_id != ""
	# o sentido e a velocidade do FIM (antes de a rota ser limpa): a inércia
	# continua na tangente do último trecho. No sprint manual ela é maior.
	var dir := _tangente_em_rota(total_rota)
	if dir.length() < 0.01:
		dir = olhar
	var fator := _fator_sprint()
	# a INÉRCIA sai com a velocidade de CHEGADA: o sprint (ou a cauda) e a
	# RAMPA que ainda estiver valendo entram nela.
	var v0 := velocidade_base() * _fator_embalo() * fator * _fator_rampa()
	var freio := maxf(float(rota_cfg.get("freio_extra_px", 16.0)), 0.0)
	if fator > 1.0:
		freio *= maxf(float(rota_cfg.get("freio_sprint_x", 1.6)), 1.0)
	rota = PackedVector2Array()
	_arcos_rota = PackedFloat32Array()
	_rota_i = 0
	rota_t = 0.0
	total_rota = 0.0
	_barrado = false
	_desvios = 0
	_desvio_lado = 0.0
	_desvio_ref = 0.0
	_desvio_inicio_s = 0.0
	_desvio_angulo = 0.0
	_sprint = false
	marcas = []
	_auto_destino = fim
	_auto_t = 3.3  # decide JÁ no primeiro passo de autonomia
	_auto_espera = 0.0
	eventos.append("rota:fim")
	if mirado:
		_iniciar_final(alvos)
	else:
		_iniciar_inercia(dir, v0, freio)
	return pos


## INÉRCIA (v0.11.1): um "passo extra" fora da rota. A velocidade começa na
## mesma do fim e cai linearmente até parar em `v0 * dur / 2` px (poucos px).
func _iniciar_inercia(dir: Vector2, v0: float, distancia: float) -> void:
	_inercia_t = 0.0
	if distancia <= 0.01 or v0 <= 1.0:
		return
	if dir.length() < 0.01:
		dir = olhar
	if dir.length() < 0.01:
		return
	_inercia_dir = dir.normalized()
	_dir_suave = _inercia_dir
	_olhar_suave = _inercia_dir
	_inercia_v0 = v0
	_inercia_dur = maxf(2.0 * distancia / v0, 0.05)
	_inercia_t = _inercia_dur


## Anda o pedaço de inércia (desacelerando) e para. Se a barreira chegar antes
## do fim, para ali (não atravessa água/rocha e não "cava" um tronco).
func _avancar_inercia(dt: float, mundo: RefCounted) -> void:
	var u := clampf(1.0 - _inercia_t / maxf(_inercia_dur, 0.0001), 0.0, 1.0)
	var velocidade_agora := _inercia_v0 * (1.0 - u)
	var passo := _passo_camera(velocidade_agora, dt)
	_inercia_t = maxf(_inercia_t - dt, 0.0)
	if passo <= 0.001:
		return
	var ideal := pos + _inercia_dir * passo
	var novo := ideal
	if no_ar():
		if not mundo.dentro(mundo.celula_de(ideal)):
			novo = pos
	else:
		novo = mundo.limitar_segmento(pos, ideal, camada)
	if novo.distance_to(pos) < 0.001:
		_inercia_t = 0.0
		return
	olhar = (novo - pos).normalized()
	pos = novo


## O alcance de um golpe físico no alvo `a` (a criatura precisa CHEGAR perto).
func _alcance_final(a: Dictionary) -> float:
	return float(defs.get("ataque", {}).get("alcance", 40.0)) + float(a.get("raio", 15.0)) + 10.0


## O caminho acabou com alvo marcado: se já está no alcance, bate; senão, VAI
## ATRÁS dele (perseguição final) com o embalo curto.
func _iniciar_final(alvos: Array) -> void:
	var a := Alvos.por_id(alvos, mira_final_id)
	if a.is_empty():
		mira_final_id = ""
		eventos.append("mira_final:perde")
		return
	if pos.distance_to(Vector2(a["pos"])) <= _alcance_final(a):
		_golpe_final(alvos)
		return
	_perseguindo = true
	_perseguir_t = maxf(float(_embalo.get("perseguir_s", 3.0)), 0.3)
	_iniciar_embalo(float(_embalo.get("curto_s", 0.25)), float(_embalo.get("curto_fator", 1.7)))


## PERSEGUIÇÃO FINAL (v0.10): o animal VAI ATRÁS do alvo marcado a pé (em vez de
## atacar de longe), com o embalo curto. Ao chegar no alcance, o golpe físico;
## se for barrado/tempo esgotar, a marca se perde.
func _perseguir(dt: float, mundo: RefCounted, alvos: Array) -> void:
	_perseguir_t -= dt
	var a := Alvos.por_id(alvos, mira_final_id)
	if a.is_empty() or _perseguir_t <= 0.0:
		_perseguindo = false
		mira_final_id = ""
		eventos.append("mira_final:perde")
		return
	var alvo: Vector2 = Vector2(a["pos"])
	if pos.distance_to(alvo) <= _alcance_final(a):
		_golpe_final(alvos)
		return
	var dir := alvo - pos
	if dir.length() < 0.01:
		_golpe_final(alvos)
		return
	dir = dir.normalized()
	var passo := _passo_camera(velocidade_base() * _fator_embalo(), dt)
	var novo := _passo_com_desvio(pos, dir, passo, alvo, mundo)
	if novo.distance_to(pos) < 0.001:
		_barrado = true
		return
	_barrado = false
	olhar = (novo - pos).normalized()
	pos = novo


func _autonomia(dt: float, mundo: RefCounted) -> void:
	# vaguear não é rota: a marcha volta à caminhada (a animação também).
	trote = false
	_auto_t += dt
	var base: Vector2 = pos
	if _auto_espera > 0.0:
		_auto_espera -= dt
		autonomia = "parado"
		return
	# a cada ~3 s, ou ao chegar no destino, decide de novo
	if _auto_t >= 3.2 or _auto_destino.distance_to(base) < 6.0:
		_auto_t = 0.0
		_decidir_autonomia(mundo)
		base = pos
	if autonomia == "parado":
		return
	var v := _auto_destino - base
	if v.length() < 3.0:
		_auto_espera = 0.6
		return
	# vaguear é DEVAGAR
	var vel := velocidade * 0.35
	var passo_v := v.normalized() * minf(_passo_camera(vel, dt), v.length())
	var novo: Vector2 = mundo.limitar_segmento(base, base + passo_v, camada)
	if novo.distance_to(base) < 0.01:
		_auto_espera = 0.5
		return
	olhar = (novo - base).normalized()
	pos = novo


func _decidir_autonomia(mundo: RefCounted) -> void:
	var dado := rng.randf()
	if dado < 0.45:
		autonomia = "parado"
		_auto_espera = rng.randf_range(0.8, 2.0)
		return
	autonomia = "vagar"
	for _i in 8:
		var ang := rng.randf_range(0.0, TAU)
		var p: Vector2 = pos + Vector2.from_angle(ang) * rng.randf_range(30.0, 80.0)
		if mundo.andavel(mundo.celula_de(p), camada):
			_auto_destino = p
			return
	autonomia = "parado"
	_auto_espera = 1.0


func _atualizar_pulo(dt: float) -> void:
	_pulo_fila_t = maxf(_pulo_fila_t - dt, 0.0)
	if _pulo_t <= 0.0:
		z = 0.0
		return
	_pulo_t = maxf(_pulo_t - dt, 0.0)
	var u := 1.0 - _pulo_t / maxf(_pulo_dur, 0.001)
	z = sin(PI * u) * _pulo_altura
	if _pulo_t <= 0.0:
		z = 0.0
		_recargas["pular"] = float(defs.get("pular", {}).get("recarga", 0.08))
		eventos.append("pulo:off")
		# v0.11.4: o pulo PEDIDO durante o ar sai NESTE quadro (emenda o
		# próximo sem esperar o toque cair no chão).
		if _pulo_fila_t > 0.0:
			_pulo_fila_t = 0.0
			_iniciar_pulo()


func _atualizar_ataque(dt: float) -> void:
	if ataque == "":
		return
	ataque_t += dt
	var f: Array = defs.get(ataque, {}).get("fases", [0.1, 0.15, 0.2])
	var total := float(f[0]) + float(f[1]) + float(f[2])
	if ataque_t >= total:
		var nome := ataque
		ataque = ""
		ataque_t = 0.0
		_recargas[nome] = float(defs.get(nome, {}).get("recarga", 0.15))
		eventos.append("golpe:fim")


## Habilidade de si mesmo que NÃO é a cavar (a cavar tem fases próprias).
func _atualizar_habilidade(dt: float) -> void:
	if habilidade == "":
		return
	habilidade_t += dt
	if habilidade_t >= habilidade_dur:
		var nome := habilidade
		habilidade = ""
		_recargas[nome] = float(defs.get(nome, {}).get("recarga", 0.4))
		eventos.append("habilidade:off")


func _atualizar_escavar(dt: float, mundo: RefCounted) -> void:
	_escavar_t += dt
	var d: Dictionary = defs.get("cavar", {"fases": [0.15, 0.55, 0.15]})
	var f: Array = d.get("fases", [0.15, 0.55, 0.15])
	var total := float(f[0]) + float(f[1]) + float(f[2])
	if _escavar_t >= total:
		escavando = false
		camada = mundo.escavar(_escavar_celula, camada)
		pos = mundo.centro(_escavar_celula)
		rota = PackedVector2Array()
		_rota_i = 0
		rota_t = 0.0
		total_rota = 0.0
		_inercia_t = 0.0
		_barrado = false
		_desvios = 0
		_desvio_lado = 0.0
		_desvio_ref = 0.0
		_desvio_inicio_s = 0.0
		_desvio_angulo = 0.0
		marcas = []
		mira_final_id = ""
		_perseguindo = false
		# v0.18: escavar troca de camada e a rota some — a carga também.
		_zerar_carga()
		_arcos_rota = PackedFloat32Array()
		_recargas["habilidade"] = float(defs.get("habilidade", {}).get("recarga", 0.4))
		eventos.append("camada:" + camada)
		eventos.append("habilidade:off")
