extends Node2D
## Cena principal: o mapa NATUREZA (a mata de `sim/natureza.gd` +
## `jogo/mundo3d/natureza/`) em RETRATO, com caminho desenhado AO VIVO. Desde
## 2026-11-27 é o ÚNICO mapa: a Fundação (ilha de teste), o baú e a onda do
## laço saíram do jogo (decisão do operador).
##
## P24 — MUNDO 3D. De trás para frente:
##   vista (CanvasLayer −1, `jogo/mundo3d/vista.gd`: SubViewport com a mata 3D,
##   os atores 3D e o Pixel Pass; o TERRENO pinta no topo das células o MAPA
##   DO CHÃO, `chao` — S5b) · `sobre` (Node2D, canvas 0: só o que está NO AR,
##   os projéteis — `efeitos_ar` z24 e `perigos_ar` z1; o `transform` do nó é,
##   a cada quadro, `cam3d.chao_para_tela(tela, NIVEL_REF)`; ortográfica ⇒ afim
##   exata) · barra de giro (CanvasLayer 1) · HUD.
## MAPA DO CHÃO (`jogo/mundo3d/chao.gd`, SubViewport 2D fora da tela): trilha
##   z1, perigos z1 e mira z25, filhos de `chao.raiz`, em px
##   de mundo da sim → texels por uma afim FIXA; não dependem da câmera nem da
##   altura — árvores, paredes e atores passam por cima deles.
## Câmera: `sim/camera3d.gd` (`dados/camera3d.json`) segue a criatura; a BARRA
## DE GIRO no topo (`ALTURA_BARRA` px) gira 360° — dedo que DESCE nela é da
## barra (`_toque_barra`, no `_input`) e nunca vira gesto, pinça nem caminho.
## Toque → chão: `mundo_de`/`tela_de` e o desenho usam a mesma afim (a câmera
## SUAVE, a que o jogador vê); o caminho cai no chão certo em qualquer yaw.
##
## Fluxo: dedo → sim/gestos (um dedo: caminho ao vivo; toque = TIRO CARREGADO,
## toque duplo = pulo, segurar = CORRER com caminho / habilidade sem ele) →
## sim/comandos → sim/corpo (traço ao vivo + travessias do caminho + carga do tiro
## + overlays + autonomia). O tempo é SIMULADO (tempo_ms): demo e oráculo são
## determinísticos. Nenhuma regra de jogo mora aqui: o main lê o dedo, desenha
## e chama o comando.
##
## v0.9 — a ORIGEM do caminho é congelada no `dedo_desceu` (posição da criatura
## naquele instante). O traço vira ataque dentro do `sim/corpo.gd` (travessia
## → batida; fim em cima do adversário → golpe final marcado nele; a onda do
## laço saiu em 2026-11-27). Enquanto desenha, o mundo roda em tempo lento e a
## tela escurece; ao soltar, o tempo ACELERA numa rampa.
##
## v0.18 — a **PAUSA DE SAÍDA** não existe mais (nem `corpo.em_atraso()`): o
## toque (`"tiro"`) começa a CARGA de 1 s — o animal para e o disparo sai
## sozinho, com carga cheia, mirado no alvo marcado vivo ou no fim do caminho;
## o segurar com caminho é o CORRER contínuo e, sem caminho, a habilidade. A
## RAMPA de aceleração (`rota.rampa_s`) é do CORPO no começo de cada caminhada
## NOVA; o main só desacelera e retoma o MUNDO enquanto o dedo desenha. A HUD
## desenha a barra de carga e a criatura, o anel; o jogo só lê o corpo e desenha.

const Mundo := preload("res://sim/mundo.gd")
const Corpo := preload("res://sim/corpo.gd")
const Gestos := preload("res://sim/gestos.gd")
const CameraToque := preload("res://sim/camera_toque.gd")
const Cam3D := preload("res://sim/camera3d.gd")
const Comandos := preload("res://sim/comandos.gd")
const Alvos := preload("res://sim/alvos.gd")
const Adversario := preload("res://sim/adversario.gd")
const Vista := preload("res://jogo/mundo3d/vista.gd")
const Chao := preload("res://jogo/mundo3d/chao.gd")
const Espaco := preload("res://jogo/mundo3d/espaco.gd")
const Ator := preload("res://jogo/mundo3d/ator.gd")
const BarraGiro := preload("res://jogo/barra_giro.gd")
const Perigos := preload("res://jogo/perigos.gd")
const Mira := preload("res://jogo/mira.gd")
const Trilha := preload("res://jogo/trilha.gd")
const Efeitos := preload("res://jogo/efeitos.gd")
const Hud := preload("res://jogo/hud.gd")
const Demo := preload("res://jogo/demo.gd")
const Natureza := preload("res://sim/natureza.gd")
const Mata := preload("res://jogo/mundo3d/natureza/mapa.gd")

## a mata tem árvores de até ~14 unidades: a fatia near..far da vista cresce
const RELEVO_MATA := 15.0
## altura (unidades) acima dos pés onde fica o centro da COPA VAZADA
const FOCO_COPA := 0.45
# JOYSTICK da vista íntima: o deslocamento do dedo até este RAIO vira magnitude
# 1,0 do controle relativo (100% do curso). Com o teto de 88 px/s do modo
# PERTO, metade do raio = 44 px/s; além do raio satura em 88. A DIREÇÃO é a do
# dedo projetada no chão (gira com a câmera).
const RAIO_JOYSTICK_PX := 90.0
## BARRA DE GIRO: faixa tátil de largura total do alto da tela (px de canvas).
## A HUD começa abaixo dela (`Hud.TOPO`).
const ALTURA_BARRA := Hud.TOPO
## plano de referência das sobreposições NO AR (`sobre`): o chão comum (nível 1)
const NIVEL_REF := 1.0
## altura (unidades 3D) acima dos pés que a câmera olha e que o gesto usa como
## "ponto da criatura" na tela
const ALTURA_FOCO := 0.0
const ALTURA_CORPO_TELA := 0.6
# atores provisórios (P24): cores por estado
const COR_CRIATURA := Color("#e07a3a")
const COR_CRIATURA_SUBSOLO := Color("#4f5b6b")
const COR_CRIATURA_ATORDOADA := Color("#d8403a")
const COR_ADV := Color("#8b5cf6")
const COR_ADV_HOSTIL := Color("#c2345e")
const COR_ADV_PREPARO := Color("#f2c23a")
const COR_ADV_PISCA := Color("#ff9a7a")
## no subsolo a criatura afunda no bloco (o subsolo não é desenhado em 3D)
const AFUNDA_SUBSOLO := 0.6
## o adversário escondido afunda no chão
const AFUNDA_OCULTO := 0.95

var mundo: RefCounted
var corpo: RefCounted
var reconhecedor: RefCounted
var cfg_gestos: Dictionary
var tempo_ms := 0.0
var alvos: Array = []
var adversarios: Array = []
var cfg_adversario: Dictionary = {}
var hostilidade := false
var mira: Node2D
var trilha: Node2D
var perigos: Node2D
## os projéteis (no ar): na tela, por cima do 3D
var efeitos_ar: Node2D
var perigos_ar: Node2D
var hud: CanvasLayer
var veu: ColorRect
var _dedos := {}  # índice do dedo -> pressionado (multitouch)
var camera_toque := CameraToque.new()
# --- P24: o mundo 3D ---
var cam3d: RefCounted
var vista: CanvasLayer
## a mata 3D (jogo/mundo3d/natureza/mapa.gd)
var mata: Node3D
var ator_criatura: Node3D
var atores_adv: Array = []
## o MAPA DO CHÃO (SubViewport): trilha, perigos e mira
var chao: SubViewport
## Node2D pai das sobreposições NO AR (projéteis: efeitos_ar, perigos_ar)
var sobre: Node2D
var barra: Control
## dedos que DESCERAM na barra de giro: índice -> último x de tela
var _dedos_barra := {}
## tamanho da tela em unidades de canvas (retrato, `aspect=expand`)
var _tela := Vector2(720, 1280)
## px de mundo da sim que um ponto anda, NO PLANO DE REFERÊNCIA, para
## aparecer onde estaria 1 unidade 3D mais alto (ver `relevo`)
var _subir := Vector2.ZERO
## altura dos pés da criatura (níveis), suavizada: degrau vira rampa
var _h_cria := 1.0
var _adv_h: Array = []
var _adv_oculto: Array = []
## alturas de terreno existentes (níveis), da maior para a menor (`mundo_de`)
var _niveis: Array = []
var _joystick_origem := Vector2.ZERO
var _joystick_dedo := -1
# a ORIGEM do gesto (congelada na descida do dedo): a linha não anda com ela
var _gesto_tela := Vector2.ZERO
var _gesto_origem := Vector2.ZERO
# o desenho já convertido (tela → mundo), ponto a ponto: cada trecho novo usa a
# câmera do instante em que o dedo passou (girar no meio do desenho não
# entorta o que já foi riscado)
var _gesto_q := PackedVector2Array()
var _gesto_m := PackedVector2Array()
var _traco_iniciado := false
# o traço nasceu de um SEGURAR que virou desenho (dedo não levantou)?
# Só esse caso recomeça a origem e encerra o sprint ao soltar.
var _desenho_de_segurar := false
# tempo lento do desenho e a rampa de volta ao tempo normal (do MUNDO; a
# rampa de aceleração do começo da caminhada é do corpo)
var _escala := 1.0
var _retomada := 0.0
var _veu_alfa := 0.0
var _tempo_vis := 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var mapa := Natureza.mundo_dict()
	cfg_gestos = _json("res://dados/gestos.json")
	cfg_adversario = _json("res://dados/adversario.json")
	mundo = Mundo.criar(mapa, _json("res://dados/terrenos.json"))
	for e in mundo.validar():
		push_error("mapa: " + e)
	corpo = Corpo.new(_json("res://dados/acoes.json"))
	corpo.rng.seed = 20261120
	corpo.pos = mundo.centro(Vector2i(mapa["inicio"][0], mapa["inicio"][1]))
	reconhecedor = Gestos.new(cfg_gestos.get("limiares", {}))
	_niveis = _alturas_do_mapa()
	_tela = get_viewport_rect().size

	# o MAPA DO CHÃO entra na árvore ANTES da vista: é desenhado antes do 3D
	# que o lê, no mesmo quadro
	chao = Chao.new()
	chao.configurar(mundo.largura, mundo.altura_grade)
	add_child(chao)

	# o PALCO 3D: mata + atores, câmera ortográfica orbital
	cam3d = Cam3D.new(_json("res://dados/camera3d.json"))
	vista = Vista.new()
	vista.altura_interna = int(cam3d.cfg["pixel_pass"]["altura_interna"])
	# padrão: 3D liso; `--pixel` liga o Pixel Pass (`--liso`, antigo, é aceito e
	# não muda nada)
	vista.pixel_pass = "--pixel" in args
	vista.altura_relevo = RELEVO_MATA
	add_child(vista)
	# a mata: luz contínua e cores vivas; sem o contorno de tela (linha preta
	# em cada folha viraria desenho animado e custaria caro)
	mata = Mata.new()
	mata.name = "Mata"
	mata.position = Natureza.origem_3d()
	vista.mundo_3d.add_child(mata)
	mata.construir()
	mata.ligar_chao(chao.get_texture(), chao.ret_shader())
	Mata.ambientar(vista.ambiente.environment, vista.sol, false)
	vista.contorno.layers = 0
	ator_criatura = Ator.new()
	ator_criatura.name = "Criatura"
	ator_criatura.cor = COR_CRIATURA
	vista.mundo_3d.add_child(ator_criatura)

	for a in mapa.get("adversarios", []):
		var adv := Adversario.new(int(a.get("semente", 1)), Rect2(), cfg_adversario)
		adv.pos = mundo.centro(Vector2i(a["celula"][0], a["celula"][1]))
		adversarios.append(adv)
		var at := Ator.new()
		at.name = "Adversario%d" % atores_adv.size()
		at.cor = COR_ADV
		at.escala = 0.9
		vista.mundo_3d.add_child(at)
		atores_adv.append(at)
		_adv_h.append(mundo.altura(mundo.celula_de(adv.pos)))
		_adv_oculto.append(0.0)
	alvos = Alvos.montar(mapa.get("objetos", []), adversarios, mundo)

	# MARCAS NO CHÃO: px de mundo da sim, no mapa do chão (o terreno as pinta)
	trilha = Trilha.new()
	trilha.z_index = 1
	chao.raiz.add_child(trilha)
	perigos = Perigos.new()
	perigos.adversarios = adversarios
	perigos.mundo = mundo
	perigos.z_index = 1
	chao.raiz.add_child(perigos)
	mira = Mira.new()
	mira.corpo = corpo
	mira.mundo = mundo
	mira.alvos = alvos
	mira.z_index = 25
	chao.raiz.add_child(mira)

	# NO AR (projéteis): px de mundo da sim, por cima do 3D, afim da câmera
	sobre = Node2D.new()
	sobre.name = "Sobreposicoes"
	add_child(sobre)
	var relevo := Callable(self, "relevo")
	perigos_ar = Perigos.new()
	perigos_ar.no_ar = true
	perigos_ar.adversarios = adversarios
	perigos_ar.mundo = mundo
	perigos_ar.relevo = relevo
	perigos_ar.z_index = 1
	sobre.add_child(perigos_ar)
	efeitos_ar = Efeitos.new()
	efeitos_ar.corpo = corpo
	efeitos_ar.mundo = mundo
	efeitos_ar.relevo = relevo
	efeitos_ar.z_index = 24
	sobre.add_child(efeitos_ar)

	# BARRA DE GIRO (sempre visível, também na vista íntima e com CONFIG)
	var camada_barra := CanvasLayer.new()
	camada_barra.name = "BarraGiro"
	camada_barra.layer = 1
	add_child(camada_barra)
	barra = BarraGiro.new()
	barra.graus_por_px = float(cam3d.cfg["giro"]["graus_por_px"])
	camada_barra.add_child(barra)

	hud = Hud.new()
	hud.hostilidade_alternada.connect(definir_hostilidade)
	hud.pixel_pass_alternado.connect(definir_pixel_pass)
	hud.sombras_alternadas.connect(definir_sombras)
	add_child(hud)
	hud.definir_pixel_pass(vista.pixel_pass)
	hud.diagnostico.configurar(vista, chao)
	# Capturas comparáveis: mesma seed/câmera/demo; só a sombra muda.
	var modo_sombra := Mata.Sombras.COMPLETAS
	if "--sombras=simplificadas" in args:
		modo_sombra = Mata.Sombras.SIMPLIFICADAS
	elif "--sombras=desligadas" in args:
		modo_sombra = Mata.Sombras.DESLIGADAS
	definir_sombras(modo_sombra)
	# Atalho explícito para a captura mínima; o jogo normal começa sem diagnóstico.
	hud.definir_diagnostico("--diagnostico" in args)
	# VÉU do desenho: escurece a tela para ilustrar a desaceleração (fica
	# ATRÁS dos rótulos da HUD, que são filhos da mesma CanvasLayer).
	veu = ColorRect.new()
	veu.color = Color(0, 0, 0, 0)
	veu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(veu)
	hud.move_child(veu, 0)

	_h_cria = mundo.altura(mundo.celula_de(corpo.pos))
	_atualizar_atores(0.0)
	posicionar_camera()
	if "--demo" in args:
		add_child(Demo.new(self))


## Põe a câmera em cima da criatura sem suavizar (início, teleporte da demo).
func posicionar_camera() -> void:
	_h_cria = mundo.altura(mundo.celula_de(corpo.pos))
	_atualizar_atores(0.0)
	cam3d.posicionar(_foco_criatura())
	_atualizar_camera(0.0)


func _foco_criatura() -> Vector3:
	return Espaco.ponto(corpo.pos, _h_cria) + Vector3(0.0, ALTURA_FOCO, 0.0)


func _process(delta: float) -> void:
	tempo_ms += delta * 1000.0
	_tempo_vis += delta
	# O relógio do gesto é REAL: o `tick` solta o TOQUE pendente quando a janela
	# do duplo fecha e ativa o segurar no limiar (a regra é de sim/gestos.gd).
	_entregar(reconhecedor.tick(tempo_ms))
	# TRAÇO AO VIVO: enquanto o dedo desenha, a rota é refeita e a criatura já
	# anda por ela. O relógio do GESTO é real; quem desacelera é o MUNDO.
	if reconhecedor.desenhando():
		var pts_gesto := _pontos_gesto()
		# um recomeço de segurar começa com UM ponto — não traça ainda.
		if pts_gesto.size() >= 2:
			var res := str(corpo.tracar(pts_gesto, mundo, not _traco_iniciado, alvos))
			# No recomeço do segurar, um "recusado" (traço curto) NÃO marca o
			# início: senão a rota seria adotada como continuação (inicio=false)
			# e herdaria o progresso da rota antiga.
			if not _desenho_de_segurar or res.begins_with("ok"):
				_traco_iniciado = true
	# PLANEJAMENTO: desenhando, o mundo desacelera; ao soltar, uma RAMPA de
	# aceleração devolve o tempo normal (dá tempo de reagir).
	var plano: Dictionary = cfg_gestos.get("planejamento", {})
	var lento := float(plano.get("escala_tempo", 0.35))
	var retomada_s := maxf(float(plano.get("retomada_ms", 450)) / 1000.0, 0.001)
	var planejando: bool = reconhecedor.planejando()
	if planejando:
		_retomada = retomada_s
		_escala = lento
	elif _retomada > 0.0:
		_retomada = maxf(0.0, _retomada - delta)
		var v := 1.0 - _retomada / retomada_s
		_escala = lerpf(lento, 1.0, v * v)  # começa devagar e solta no fim
	else:
		_escala = 1.0
	var dt := delta * _escala
	# o inimigo só caça quem está na SUPERFÍCIE; no subsolo ele não tem alvo
	var alvo_corpo: Variant = corpo if corpo.camada == Mundo.SUPERFICIE else null
	for adv in adversarios:
		adv.passo(dt, mundo, alvo_corpo)
		for e in adv.drenar_eventos():
			_evento(e)
	Alvos.sincronizar(alvos, adversarios)
	corpo.passo(dt, mundo, alvos)
	for e in corpo.drenar_eventos():
		_evento(e)
	_atualizar_atores(delta)
	_atualizar_camera(delta)
	# A LINHA mostra o TRAÇO CRU (os pontos densos do desenho): contínua e fiel
	# ao movimento do dedo, não a rota simplificada (v0.9.2).
	if corpo.em_rota() or reconhecedor.desenhando():
		trilha.mostrar(corpo.traco, corpo.traco_t)
	else:
		trilha.mostrar(PackedVector2Array())
	hud.estado(corpo, alvos, planejando, _escala, adversarios, hostilidade)
	_escurecer(planejando, plano, retomada_s, delta)


## Atores 3D provisórios: só LEEM a sim (posição, olhar, salto, camada,
## hostilidade, preparo, esconderijo) e trocam de cor por estado.
func _atualizar_atores(delta: float) -> void:
	var subsolo: bool = corpo.camada == Mundo.SUBSOLO
	var alvo_h: float = mundo.altura(mundo.celula_de(corpo.pos))
	_h_cria = alvo_h + (_h_cria - alvo_h) * exp(-14.0 * delta)
	var salto: float = float(corpo.z) / Cam3D.PX_POR_UNIDADE - (AFUNDA_SUBSOLO if subsolo else 0.0)
	ator_criatura.atualizar(corpo.pos, _h_cria, corpo.olhar, salto)
	var cor := COR_CRIATURA
	if subsolo:
		cor = COR_CRIATURA_SUBSOLO
	elif corpo.atordoado():
		cor = COR_CRIATURA_ATORDOADA if fmod(_tempo_vis, 0.2) < 0.1 else COR_CRIATURA
	_pintar(ator_criatura, cor)
	for i in adversarios.size():
		var adv: RefCounted = adversarios[i]
		var at: Node3D = atores_adv[i]
		var ah: float = mundo.altura(mundo.celula_de(adv.pos))
		_adv_h[i] = ah + (float(_adv_h[i]) - ah) * exp(-14.0 * delta)
		var oc := 1.0 if adv.oculto() else 0.0
		_adv_oculto[i] = lerpf(float(_adv_oculto[i]), oc, clampf(delta * 9.0, 0.0, 1.0)) if delta > 0.0 else oc
		var pulo := absf(sin(_tempo_vis * 4.0)) * 0.06 * (1.0 - float(_adv_oculto[i]))
		at.atualizar(adv.pos, float(_adv_h[i]), adv.olhar, pulo - AFUNDA_OCULTO * float(_adv_oculto[i]))
		var c := COR_ADV_HOSTIL if adv.hostil else COR_ADV
		if adv.piscando():
			c = COR_ADV_PISCA
		elif adv.preparando() and fmod(_tempo_vis, 0.25) < 0.125:
			c = COR_ADV_PREPARO
		_pintar(at, c)


## Repinta só quando a cor muda (os materiais vêm do cache por cor).
func _pintar(at: Node3D, cor: Color) -> void:
	if not Color(at.cor).is_equal_approx(cor):
		at.pintar(cor)


## Câmera 3D: segue a criatura (relógio REAL: a câmera não desacelera com o
## desenho), avança a troca de vista, posiciona a vista e as sobreposições.
func _atualizar_camera(delta: float) -> void:
	_tela = get_viewport_rect().size
	cam3d.seguir(_foco_criatura(), delta)
	cam3d.avancar(delta)
	vista.aplicar_camera(cam3d)
	mata.definir_foco(ator_criatura.position + Vector3(0.0, FOCO_COPA, 0.0))
	var ref := Espaco.altura_3d(NIVEL_REF)
	var m: Transform2D = cam3d.chao_para_tela(_tela, ref)
	sobre.transform = m
	var m1: Transform2D = cam3d.chao_para_tela(_tela, ref + 1.0)
	_subir = m.affine_inverse().basis_xform(m1.origin - m.origin)
	barra.size = Vector2(_tela.x, ALTURA_BARRA)
	barra.definir(rad_to_deg(cam3d.yaw), not _dedos_barra.is_empty())


## Um ponto do chão (px de mundo da sim) levado ao TOPO do terreno da sua
## célula, expresso no plano de referência das sobreposições no ar: o pai
## (`sobre`) o põe na tela exatamente onde fica o chão 3D daquela célula. Só os
## projéteis usam; as marcas de chão estão no mapa do chão.
func relevo(p: Vector2) -> Vector2:
	var h := Espaco.altura_3d(mundo.altura(mundo.celula_de(p)))
	return p + _subir * (h - Espaco.altura_3d(NIVEL_REF))


## VÉU: escurece enquanto desenha e clareia junto com a rampa de aceleração.
## Suavizado para não piscar num gesto que mal começou.
func _escurecer(planejando: bool, plano: Dictionary, retomada_s: float, delta: float) -> void:
	var forca := float(plano.get("escurecer", 0.22))
	# 1 enquanto planeja; ao soltar, 1 → 0 junto com a rampa
	var alvo := 1.0 if planejando else _retomada / retomada_s
	_veu_alfa = lerpf(_veu_alfa, clampf(alvo, 0.0, 1.0), clampf(delta * 9.0, 0.0, 1.0))
	veu.color = Color(0, 0, 0, forca * _veu_alfa)


func _evento(e: String) -> void:
	if e.begins_with("camada:"):
		# P24: o subsolo não é desenhado em 3D; o ator afunda e escurece
		print("evento: ", e)
		hud.nota("SUBSOLO" if corpo.camada == Mundo.SUBSOLO else "SUPERFÍCIE")
	elif e == "rota:fim":
		trilha.mostrar(PackedVector2Array())
	elif e == "carga:on":
		print("evento: ", e)
		hud.nota("CARREGANDO")
	elif e == "sprint:on":
		print("evento: ", e)
		hud.nota("CORRENDO")
	elif e == "sprint:off":
		# soltou o segurar: a CAUDA mantém o embalo por `sprint.cauda_s`
		print("evento: ", e)
		hud.nota("CAUDA — o embalo continua")
	elif e.begins_with("tiro:"):
		print("evento: ", e)
		hud.nota("TIRO")
	elif e.begins_with("batida:"):
		print("evento: ", e)
		hud.nota("BATIDA em %s" % e.substr(7))
	elif e.begins_with("acerto:"):
		print("evento: ", e)
		hud.nota("ACERTO em %s" % e.substr(7))
	elif e.begins_with("golpe_final:"):
		print("evento: ", e)
		hud.nota("GOLPE FINAL em %s" % e.substr(12))
	elif e == "mira_final:perde":
		print("evento: ", e)
		hud.nota("alvo marcado se perdeu")
	elif e == "mira_final:":
		# v0.11.4: o caminho passou por cima e SEGUIU — não volta para bater
		print("evento: ", e)
		hud.nota("marca solta: o caminho seguiu longe")
	elif e.begins_with("mira_final:"):
		print("evento: ", e)
		hud.nota("ALVO MARCADO em %s" % e.substr(11))
	elif e.begins_with("perigo:"):
		print("evento: ", e)
		hud.nota("INIMIGO PREPARA %s" % _nome_ataque(e.substr(7)))
	elif e.begins_with("acerta:"):
		print("evento: ", e)
		hud.nota("GOLPE DO INIMIGO: %s" % _nome_ataque(e.substr(7)))
	elif e == "levou:golpe":
		print("evento: ", e)
	elif e == "esconde:prepara":
		print("evento: ", e)
		hud.nota("o inimigo vai se esconder")
	elif e == "esconde:on":
		print("evento: ", e)
		hud.nota("o inimigo se ESCONDEU — intocável")
	elif e == "esconde:off":
		print("evento: ", e)
		hud.nota("o inimigo reapareceu")
	elif e == "esconde:sai":
		pass


func _nome_ataque(nome: String) -> String:
	match nome:
		"bote":
			return "BOTE"
		"esbarrao":
			return "ESBARRÃO"
		"cuspe":
			return "CUSPE"
		"esconder":
			return "ESCONDER"
	return nome.to_upper()


## Liga/desliga a hostilidade em TODOS os adversários (o botão da HUD chama).
func definir_hostilidade(v: bool) -> void:
	hostilidade = v
	for adv in adversarios:
		adv.definir_hostil(v)
	if hud:
		hud.nota("HOSTILIDADE %s" % ("LIGADA — ele vai caçar" if v else "desligada"))


## Pixel Pass ligado (pixel art) ou desligado (3D liso, o padrão). O botão da
## HUD chama; `--pixel` começa ligado.
func definir_pixel_pass(v: bool) -> void:
	vista.pixel_pass = v
	vista.aplicar_camera(cam3d)
	if hud:
		hud.definir_pixel_pass(v)
		hud.nota("PIXEL ART %s" % ("ligado" if v else "desligado — 3D liso"))


## P25/2.1: DESLIGADAS = sem sombra da luz direcional em TODA a cena,
## inclusive atores e chão, não só as árvores. Nenhuma geometria é reconstruída.
## Não grava qualidade: cada partida começa em COMPLETAS.
func definir_sombras(modo: int) -> void:
	mata.definir_sombras(modo)
	vista.sol.shadow_enabled = mata.modo_sombras != Mata.Sombras.DESLIGADAS
	hud.definir_sombras(mata.modo_sombras)


# ---------- o dedo (toque real e demo passam por aqui) ----------

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and corpo != null:
		_cancelar_contatos()


func _cancelar_contatos() -> void:
	_dedos.clear()
	_dedos_barra.clear()
	camera_toque.dedos.clear()
	camera_toque.par.clear()
	camera_toque.bloqueado = false
	reconhecedor = Gestos.new(cfg_gestos.get("limiares", {}))
	_joystick_dedo = -1
	corpo.comandar({"acao": "soltar_segurar"}, mundo, alvos)
	if _traco_iniciado:
		corpo.definir_controle_relativo(true)
		corpo.definir_controle_relativo(camera_toque.intima())
	_traco_iniciado = false
	_desenho_de_segurar = false
	_levar_modo_camera()
	corpo.mover_relativo(Vector2.ZERO)


# Solturas de contatos iniciados no mundo devem chegar mesmo sobre um botão.
# A BARRA DE GIRO decide primeiro (antes da GUI e do `_unhandled_input`).
func _input(ev: InputEvent) -> void:
	if _toque_barra(ev):
		get_viewport().set_input_as_handled()
		return
	if ev is InputEventScreenTouch:
		if _dedos.has(ev.index):
			if ev.canceled:
				_cancelar_contatos()
			elif not ev.pressed:
				dedo_subiu(ev.index, ev.position)
		elif ev.pressed and not _dedos.is_empty():
			dedo_desceu(ev.index, ev.position)
			get_viewport().set_input_as_handled()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed and not _dedos.has(ev.index):
			dedo_desceu(ev.index, ev.position)
		elif not ev.pressed and _dedos.has(ev.index):
			dedo_subiu(ev.index, ev.position)
	elif ev is InputEventScreenDrag and _dedos.has(ev.index):
		dedo_moveu(ev.index, ev.position)


## BARRA DE GIRO: o dedo que DESCE dentro da faixa do topo (`ALTURA_BARRA`)
## pertence à barra até subir — o deslocamento horizontal gira a câmera
## (`cam3d.girar_px`) e nada dele chega a `dedo_*`, a `sim/camera_toque.gd`
## (pinça) ou a `sim/gestos.gd` (caminho). Dedo que desce fora da faixa segue
## o fluxo de sempre, mesmo se depois passar por ela. Um dedo na barra e outro
## desenhando não se veem: cada um tem seu índice. Devolve true se o evento era
## da barra (o `_input` o consome).
func _toque_barra(ev: InputEvent) -> bool:
	if ev is InputEventScreenTouch:
		var t := ev as InputEventScreenTouch
		if _dedos_barra.has(t.index):
			if not t.pressed or t.canceled:
				_dedos_barra.erase(t.index)
			return true
		if t.pressed and not _dedos.has(t.index) and na_barra(t.position):
			_dedos_barra[t.index] = t.position.x
			return true
	elif ev is InputEventScreenDrag:
		var d := ev as InputEventScreenDrag
		if _dedos_barra.has(d.index):
			var x0: float = _dedos_barra[d.index]
			cam3d.girar_px(d.position.x - x0)
			_dedos_barra[d.index] = d.position.x
			return true
	return false


func na_barra(p: Vector2) -> bool:
	return p.y >= 0.0 and p.y < ALTURA_BARRA


func dedo_desceu(dedo: int, p: Vector2) -> void:
	var acao := camera_toque.descer(dedo, p)
	_dedos[dedo] = true
	# O zoom pode ter mudado desde o último toque: o modo é sincronizado AQUI
	# também, senão o dedo entraria com o modo velho (joystick × caminho).
	_levar_modo_camera()
	if acao == "pinca":
		# Cancela também toques pendentes; nenhum dedo remanescente reinicia gesto.
		corpo.comandar({"acao": "soltar_segurar"}, mundo, alvos)
		if _traco_iniciado:
			corpo.definir_controle_relativo(true)
			corpo.definir_controle_relativo(camera_toque.intima())
		reconhecedor = Gestos.new(cfg_gestos.get("limiares", {}))
		_traco_iniciado = false
		_desenho_de_segurar = false
		_joystick_dedo = -1
		corpo.mover_relativo(Vector2.ZERO)
		return
	if acao != "principal":
		return
	if camera_toque.intima():
		_joystick_dedo = dedo
		_joystick_origem = p
		corpo.mover_relativo(Vector2.ZERO)
		return
	_gesto_tela = p
	_gesto_origem = corpo.pos
	_gesto_q.clear()
	_gesto_m.clear()
	_traco_iniciado = false
	_desenho_de_segurar = false
	var cria_tela: Vector2 = cam3d.ponto_para_tela(ator_criatura.position + Vector3(0.0, ALTURA_CORPO_TELA, 0.0), _tela)
	_entregar(reconhecedor.iniciar(dedo, p, tempo_ms, cria_tela))


func dedo_moveu(dedo: int, p: Vector2) -> void:
	var acao := camera_toque.mover(dedo, p)
	if acao == "pinca":
		_aplicar_camera()
	elif acao == "principal":
		if camera_toque.intima() and dedo == _joystick_dedo:
			corpo.mover_relativo(_joystick_no_chao(p - _joystick_origem))
		else:
			# o dedo SEGURANDO que se move sem levantar começa um desenho
			# NOVO na posição ATUAL (a origem congelada na descida já não vale
			# para esses pontos). O segurar continua — o sprint não cai.
			var limiares: Dictionary = cfg_gestos.get("limiares", {})
			if not camera_toque.intima() and reconhecedor.ativo() \
					and not reconhecedor.desenhando() and reconhecedor.segurando() \
					and p.distance_to(reconhecedor.inicio()) > float(limiares.get("desenho_min_px", 16.0)):
				_recomecar_segurar(p)
			_entregar(reconhecedor.mover(dedo, p, tempo_ms))


## JOYSTICK (vista íntima): o deslocamento do dedo na TELA vira a direção no
## CHÃO (inversa da afim da câmera, então gira com o yaw); a magnitude é a do
## dedo na tela (0..1 até `RAIO_JOYSTICK_PX`).
func _joystick_no_chao(deslocamento_tela: Vector2) -> Vector2:
	var mag := minf(deslocamento_tela.length() / RAIO_JOYSTICK_PX, 1.0)
	var no_chao: Vector2 = cam3d.tela_para_chao(_tela).basis_xform(deslocamento_tela)
	if mag <= 0.0 or no_chao.length() < 0.000001:
		return Vector2.ZERO
	return no_chao.normalized() * mag


## Recomeça o traço do SEGURAR no ponto atual. A criatura é a ORIGEM
## (em mundo); o primeiro ponto nasce exatamente sobre ela.
func _recomecar_segurar(p: Vector2) -> void:
	reconhecedor.recomecar(p, tempo_ms)
	_gesto_origem = corpo.pos
	_gesto_tela = p
	_gesto_q.clear()
	_gesto_m.clear()
	_traco_iniciado = false
	_desenho_de_segurar = true


func dedo_subiu(dedo: int, p: Vector2) -> void:
	var acao := camera_toque.subir(dedo)
	_dedos.erase(dedo)
	if acao != "principal":
		return
	if camera_toque.intima():
		_joystick_dedo = -1
		corpo.mover_relativo(Vector2.ZERO)
	else:
		_entregar(reconhecedor.soltar(dedo, p, tempo_ms))


## Leva o MODO da câmera (PERTO/LONGE) para o corpo. É ele que decide o TETO
## de velocidade e se existe CAMINHADA (de longe, andar já é correr). A pinça
## pode mudar o zoom em QUALQUER movimento, então isto roda a cada movimento de
## pinça e em cada toque que ENTRA — nunca só na descida do primeiro dedo.
func _levar_modo_camera() -> void:
	var intima: bool = camera_toque.intima()
	corpo.definir_camera_perto(intima)
	if corpo.controle_relativo != intima:
		corpo.definir_controle_relativo(intima)


## A pinça mexeu no zoom: leva o MODO ao corpo e troca a VISTA da câmera 3D
## (íntima = baixa/perto; alta = a padrão). A transição é da câmera.
func _aplicar_camera() -> void:
	_levar_modo_camera()
	var intima: bool = camera_toque.intima()
	cam3d.definir_vista("intima" if intima else "alta")
	hud.definir_vista_intima(intima)


func _entregar(evs: Array) -> void:
	for ev in evs:
		if ev["gesto"] == "trajetoria":
			# O caminho já foi desenhado AO VIVO: aqui só se fecha a rota com o
			# último trecho (nada de recomeçar do zero) e se marca o alvo final.
			var res := str(corpo.tracar(_pontos_gesto(), mundo, not _traco_iniciado, alvos))
			_traco_iniciado = false
			var marca := str(corpo.finalizar_rota(alvos))
			if marca != "":
				res += " · " + marca
			# quando o desenho NASCEU de um SEGURAR (o dedo não levantou
			# entre o sprint e o traço), fechar a trajetória encerra o segurar —
			# senão o sprint ficaria preso. O desenho normal não passa por aqui.
			if _desenho_de_segurar:
				corpo.comandar({"acao": "soltar_segurar"}, mundo, alvos)
				_desenho_de_segurar = false
			hud.gesto(ev, Comandos.traduzir(ev, cfg_gestos.get("mapa", {})), res)
			continue
		var pm := PackedVector2Array()
		for q in PackedVector2Array(ev["pontos"]):
			pm.append(mundo_de(q))
		ev["pontos_mundo"] = pm
		ev["alvo"] = pm[pm.size() - 1] if not pm.is_empty() else corpo.pos
		var cmd := Comandos.traduzir(ev, cfg_gestos.get("mapa", {}))
		var res := "não reconhecido" if cmd.is_empty() else str(corpo.comandar(cmd, mundo, alvos))
		hud.gesto(ev, cmd, res)


## O desenho do dedo em MUNDO, a partir da origem congelada e com o GANHO de
## sensibilidade: um dedo menor cobre mais tela (o mesmo traço em px de tela é
## multiplicado por `desenho.ganho`). P24: cada trecho NOVO do dedo é levado ao
## chão pela câmera do instante em que foi riscado (inversa da afim da câmera
## 3D, só a base: translação não importa num deslocamento) e somado ao ponto
## anterior; com a câmera parada é exatamente `origem + inv·(q − q0)·ganho`.
func _pontos_gesto() -> PackedVector2Array:
	var ganho := float(cfg_gestos.get("desenho", {}).get("ganho", 1.0))
	var qs: PackedVector2Array = reconhecedor.pontos()
	var n := _gesto_q.size()
	if n > qs.size() or (n > 0 and (qs[0] != _gesto_q[0] or qs[n - 1] != _gesto_q[n - 1])):
		_gesto_q.clear()
		_gesto_m.clear()
		n = 0
	if n < qs.size():
		var inv: Transform2D = cam3d.tela_para_chao(_tela)
		for i in range(n, qs.size()):
			var q0 := _gesto_tela if i == 0 else qs[i - 1]
			var m0 := _gesto_origem if i == 0 else _gesto_m[i - 1]
			_gesto_m.append(m0 + inv.basis_xform((qs[i] - q0) * ganho))
			_gesto_q.append(qs[i])
	return _gesto_m.duplicate()


## Tela → CHÃO 3D sob o dedo (px de mundo da sim). Ortográfica: o raio do dedo
## cruza os planos de altura em pontos conhecidos; vale o MAIS ALTO cujo
## terreno tem exatamente aquela altura (o topo que o jogador vê). Fora de
## todos, o plano mais baixo.
func mundo_de(tela: Vector2) -> Vector2:
	var p := Vector2.ZERO
	for nivel in _niveis:
		p = cam3d.tela_para_chao(_tela, Espaco.altura_3d(float(nivel))) * tela
		if is_equal_approx(mundo.altura(mundo.celula_de(p)), float(nivel)):
			return p
	return p


## Chão (px de mundo da sim, no topo do terreno da célula) → tela.
func tela_de(mundo_pos: Vector2) -> Vector2:
	var h := Espaco.altura_3d(mundo.altura(mundo.celula_de(mundo_pos)))
	return cam3d.chao_para_tela(_tela, h) * mundo_pos


## A afim chão→tela no plano de referência (a das sobreposições). A demo usa
## a base dela para converter deslocamentos de mundo em px de tela.
func chao_tela() -> Transform2D:
	return cam3d.chao_para_tela(_tela, Espaco.altura_3d(NIVEL_REF))


## As alturas (níveis) que existem no mapa, da maior para a menor.
func _alturas_do_mapa() -> Array:
	var vistos := {}
	for y in mundo.altura_grade:
		for x in mundo.largura:
			vistos[float(mundo.altura(Vector2i(x, y)))] = true
	vistos[0.0] = true
	var lista: Array = vistos.keys()
	lista.sort()
	lista.reverse()
	return lista


func _json(caminho: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(caminho))
