extends Node2D
## Cena principal (v0.7): a FUNDAÇÃO em RETRATO, com caminho desenhado AO VIVO.
##
## Camadas de desenho (z_index), de trás para frente:
##   −20 parallax fundo · 0 chão · 1 trilha/rota · 2 objetos (y-sort: troncos,
##   baú, adversário, criatura) · 15 subsolo · 25 marca de mira · 30 copas ·
##   40 parallax frente · HUD.
##
## Fluxo: dedo → sim/gestos (caminho sem espera + gestos de tela) →
## sim/comandos → sim/corpo (traço ao vivo + desvio + overlays + autonomia).
## O tempo é SIMULADO (tempo_ms): demo e oráculo são determinísticos.
##
## v0.7 — a ORIGEM do caminho é congelada no `dedo_desceu` (posição da criatura
## naquele instante): o traço é traduzido tela→mundo com essa origem e com o
## GANHO de sensibilidade (`desenho.ganho`), então a linha não anda junto com o
## animal enquanto o dedo desenha. Enquanto desenha (ou defende), o mundo roda
## em tempo lento e a tela escurece; ao soltar, o tempo ACELERA numa rampa.

const Mundo := preload("res://sim/mundo.gd")
const Corpo := preload("res://sim/corpo.gd")
const Gestos := preload("res://sim/gestos.gd")
const Comandos := preload("res://sim/comandos.gd")
const Alvos := preload("res://sim/alvos.gd")
const Adversario := preload("res://sim/adversario.gd")
const Mock := preload("res://jogo/mock.gd")
const Chao := preload("res://jogo/camadas/chao.gd")
const Subsolo := preload("res://jogo/camadas/subsolo.gd")
const ObjetoMock := preload("res://jogo/camadas/objeto_mock.gd")
const Copa := preload("res://jogo/camadas/copa.gd")
const Parallax := preload("res://jogo/camadas/parallax.gd")
const Criatura := preload("res://jogo/criatura.gd")
const AdversarioMock := preload("res://jogo/adversario_mock.gd")
const Mira := preload("res://jogo/mira.gd")
const Trilha := preload("res://jogo/trilha.gd")
const Hud := preload("res://jogo/hud.gd")
const Demo := preload("res://jogo/demo.gd")

const MAPA := "res://dados/mapas/fundacao.json"

var mundo: RefCounted
var corpo: RefCounted
var reconhecedor: RefCounted
var cfg_gestos: Dictionary
var tempo_ms := 0.0
var alvos: Array = []
var adversarios: Array = []
var chao: Node2D
var subsolo: Node2D
var criatura: Node2D
var mira: Node2D
var trilha: Node2D
var camera: Camera2D
var hud: CanvasLayer
var copas: Array = []
var veu: ColorRect
var _dedos := {}  # índice do dedo -> pressionado (multitouch)
var _abertos := {}
# a ORIGEM do gesto (congelada na descida do dedo): a linha não anda com ela
var _gesto_tela := Vector2.ZERO
var _gesto_origem := Vector2.ZERO
var _gesto_inv := Transform2D.IDENTITY
var _traco_iniciado := false
# a rota de ANTES do gesto: dois dedos cancelam o traço e a devolvem
var _rota_antes := {}
var _cancelou := false
# tempo lento do desenho e a rampa de aceleração da saída
var _escala := 1.0
var _retomada := 0.0
var _veu_alfa := 0.0
# uma AÇÃO durante o desenho devolve o tempo na hora (o golpe não fica lento)
var _plano_liberado := false


func _ready() -> void:
	var mapa := _json(MAPA)
	cfg_gestos = _json("res://dados/gestos.json")
	mundo = Mundo.criar(mapa, _json("res://dados/terrenos.json"))
	for e in mundo.validar():
		push_error("mapa: " + e)
	corpo = Corpo.new(_json("res://dados/acoes.json"))
	corpo.rng.seed = 20261120
	corpo.pos = mundo.centro(Vector2i(mapa["inicio"][0], mapa["inicio"][1]))
	reconhecedor = Gestos.new(cfg_gestos.get("limiares", {}))
	RenderingServer.set_default_clear_color(Color("#0b2438"))

	add_child(Parallax.new())
	var no := Node2D.new()
	add_child(no)
	chao = Chao.new()
	chao.mundo = mundo
	no.add_child(chao)
	trilha = Trilha.new()
	trilha.z_index = 1
	no.add_child(trilha)

	var objetos := Node2D.new()
	objetos.y_sort_enabled = true
	objetos.z_index = 2
	no.add_child(objetos)
	for o in mapa.get("objetos", []):
		var c := Vector2i(o["celula"][0], o["celula"][1])
		var ob := ObjetoMock.new()
		ob.tipo = o["tipo"]
		ob.id_objeto = "%s:%d,%d" % [o["tipo"], c.x, c.y]
		ob.position = mundo.centro(c) + Vector2(0, 8)
		ob.desnivel = Mock.desnivel(mundo.altura(c))
		objetos.add_child(ob)
		if o.has("copa"):
			var cp := Copa.new()
			cp.raio = float(o["copa"])
			cp.base = ob.position + Vector2(0, ob.desnivel)
			cp.z_index = 30
			no.add_child(cp)
			copas.append(cp)

	for a in mapa.get("adversarios", []):
		var adv := Adversario.new(int(a.get("semente", 1)))
		adv.pos = mundo.centro(Vector2i(a["celula"][0], a["celula"][1]))
		adversarios.append(adv)
		var no_adv := AdversarioMock.new()
		no_adv.adv = adv
		objetos.add_child(no_adv)
	alvos = Alvos.montar(mapa.get("objetos", []), adversarios, mundo)

	criatura = Criatura.new()
	criatura.corpo = corpo
	criatura.mundo = mundo
	objetos.add_child(criatura)

	subsolo = Subsolo.new()
	subsolo.mundo = mundo
	subsolo.z_index = 15
	subsolo.visible = false
	no.add_child(subsolo)

	mira = Mira.new()
	mira.corpo = corpo
	mira.alvos = alvos
	mira.z_index = 25
	no.add_child(mira)

	camera = Camera2D.new()
	camera.zoom = Vector2(Mock.ZOOM, Mock.ZOOM)
	camera.limit_left = -Mock.CELULA
	camera.limit_top = -Mock.CELULA
	camera.limit_right = (mundo.largura + 1) * Mock.CELULA
	camera.limit_bottom = (mundo.altura_grade + 1) * Mock.CELULA
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.position = corpo.pos
	no.add_child(camera)
	camera.make_current()

	hud = Hud.new()
	hud.cfg = cfg_gestos
	add_child(hud)
	# VÉU do desenho: escurece a tela para ilustrar a desaceleração (fica
	# ATRÁS dos rótulos da HUD, que são filhos da mesma CanvasLayer).
	veu = ColorRect.new()
	veu.color = Color(0, 0, 0, 0)
	veu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(veu)
	hud.move_child(veu, 0)
	if "--demo" in OS.get_cmdline_user_args():
		add_child(Demo.new(self))


func _process(delta: float) -> void:
	tempo_ms += delta * 1000.0
	_entregar(reconhecedor.tick(tempo_ms))
	# TRAÇO AO VIVO: enquanto o dedo desenha, a rota é refeita e a criatura já
	# anda por ela. O relógio do GESTO é real; quem desacelera é o MUNDO.
	if reconhecedor.desenhando():
		corpo.tracar(_pontos_gesto(), mundo, not _traco_iniciado)
		_traco_iniciado = true
	# PLANEJAMENTO: desenhando/defendendo o mundo desacelera; ao soltar, uma
	# RAMPA de aceleração devolve o tempo normal (dá tempo de reagir).
	var plano: Dictionary = cfg_gestos.get("planejamento", {})
	var lento := float(plano.get("escala_tempo", 0.35))
	var retomada_s := maxf(float(plano.get("retomada_ms", 450)) / 1000.0, 0.001)
	var planejando: bool = reconhecedor.planejando() and not _plano_liberado
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
	for adv in adversarios:
		adv.passo(dt, mundo)
	Alvos.sincronizar(alvos, adversarios)
	corpo.passo(dt, mundo, alvos)
	for e in corpo.drenar_eventos():
		_evento(e)
	for cp in copas:
		cp.atualizar(corpo.pos, delta, corpo.camada == Mundo.SUBSOLO)
	# a rota (a mesma que o dedo desenhou) fica VISÍVEL durante os gestos de
	# ação: ataque, esquiva e pulo acontecem POR CIMA dela, sem movê-la.
	if corpo.em_rota():
		trilha.mostrar(corpo.rota)
	else:
		trilha.mostrar(PackedVector2Array())
	camera.position = criatura.ponto_visual()
	hud.estado(corpo, alvos, planejando, _escala)
	_escurecer(planejando, plano, retomada_s, delta)


## VÉU: escurece enquanto desenha e clareia junto com a rampa de aceleração.
## Suavizado para não piscar num gesto de ação que mal começou.
func _escurecer(planejando: bool, plano: Dictionary, retomada_s: float, delta: float) -> void:
	var forca := float(plano.get("escurecer", 0.22))
	# 1 enquanto planeja; ao soltar, 1 → 0 junto com a rampa
	var alvo := 1.0 if planejando else _retomada / retomada_s
	_veu_alfa = lerpf(_veu_alfa, clampf(alvo, 0.0, 1.0), clampf(delta * 9.0, 0.0, 1.0))
	veu.color = Color(0, 0, 0, forca * _veu_alfa)


func _evento(e: String) -> void:
	if e.begins_with("camada:"):
		subsolo.visible = corpo.camada == Mundo.SUBSOLO
		chao.queue_redraw()
		subsolo.queue_redraw()
	elif e.begins_with("interagir:"):
		var id := e.substr(10)
		_abertos[id] = true
		for n in get_node(".").find_children("*", "", true, false):
			if n is ObjetoMock and n.id_objeto == id:
				n.aberto = true
	elif e == "rota:fim":
		trilha.mostrar(PackedVector2Array())


# ---------- o dedo (toque real e demo passam por aqui) ----------

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed and not _dedos.has(ev.index):
			dedo_desceu(ev.index, ev.position)
		elif not ev.pressed and _dedos.has(ev.index):
			dedo_subiu(ev.index, ev.position)
	elif ev is InputEventScreenDrag and _dedos.has(ev.index):
		dedo_moveu(ev.index, ev.position)


func dedo_desceu(dedo: int, p: Vector2) -> void:
	var primeiro := _dedos.is_empty()
	_dedos[dedo] = true
	if primeiro:
		# CONGELA a origem: a posição dela AGORA é o começo do traço, e o mapa
		# tela→mundo deste instante traduz o desenho (a linha não anda com o
		# animal nem com a câmera).
		_gesto_tela = p
		_gesto_origem = corpo.pos - corpo.desvio
		_gesto_inv = get_viewport().get_canvas_transform().affine_inverse()
		_traco_iniciado = false
		_rota_antes = corpo.guardar_rota()
		_cancelou = false
		_plano_liberado = false
	_entregar(reconhecedor.iniciar(dedo, p, tempo_ms, tela_de(criatura.ponto_visual() + Vector2(0, -20))))


func dedo_moveu(dedo: int, p: Vector2) -> void:
	_entregar(reconhecedor.mover(dedo, p, tempo_ms))


func dedo_subiu(dedo: int, p: Vector2) -> void:
	_dedos.erase(dedo)
	_entregar(reconhecedor.soltar(dedo, p, tempo_ms))


func _entregar(evs: Array) -> void:
	for ev in evs:
		# Dois dedos ANTES de o caminho desenhar: o traço cai (o gesto é de ação).
		if ev["gesto"] == "caminho_cancelar":
			_cancelar_traco()
			continue
		# AÇÃO: o golpe não fica em câmera lenta — o tempo volta na hora (o
		# desenho continua, se havia um).
		if ev["gesto"] == "deslize" or ev["gesto"] == "especial" \
				or (ev["gesto"] == "segurar_inicio" and ev.get("defesa", false)):
			_plano_liberado = true
			_retomada = 0.0
		if ev["gesto"] == "trajetoria":
			# O caminho já foi desenhado AO VIVO: aqui só se fecha a rota com o
			# último trecho (nada de recomeçar do zero).
			var res := str(corpo.tracar(_pontos_gesto(), mundo, not _traco_iniciado))
			_traco_iniciado = false
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


## Cancela o caminho riscado por este gesto: devolve a rota (e o progresso)
## que existia antes do dedo descer. É o que faz um gesto de DOIS dedos não
## deixar passo para trás.
func _cancelar_traco() -> void:
	if _cancelou:
		return
	_cancelou = true
	corpo.voltar_rota(_rota_antes)
	_traco_iniciado = false


## O desenho do dedo em MUNDO, a partir da origem congelada e com o GANHO de
## sensibilidade: um dedo menor cobre mais tela (o mesmo traço em px de tela é
## multiplicado por `desenho.ganho`).
func _pontos_gesto() -> PackedVector2Array:
	var ganho := float(cfg_gestos.get("desenho", {}).get("ganho", 1.0))
	var pts := PackedVector2Array()
	for q in reconhecedor.pontos():
		pts.append(_gesto_origem + _gesto_inv.basis_xform((q - _gesto_tela) * ganho))
	return pts


func mundo_de(tela: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * tela


func tela_de(mundo_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * mundo_pos


func _json(caminho: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(caminho))
