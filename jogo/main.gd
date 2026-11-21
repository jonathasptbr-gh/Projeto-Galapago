extends Node2D
## Cena principal (v0.6): a FUNDAÇÃO em RETRATO, com caminho por ÂNCORA.
##
## Camadas de desenho (z_index), de trás para frente:
##   −20 parallax fundo · 0 chão · 1 trilha/rota · 2 objetos (y-sort: troncos,
##   baú, adversário, criatura) · 15 subsolo · 25 marca de mira · 30 copas ·
##   40 parallax frente · HUD.
##
## Fluxo: dedo → sim/gestos (âncora do caminho + gestos de tela) →
## sim/comandos → sim/corpo (pontos de referência + desvio + overlays +
## autonomia). O tempo é SIMULADO (tempo_ms): demo e oráculo são determinísticos.
## Enquanto a âncora existe, o MUNDO roda em tempo lento (`planejamento`);
## o relógio do gesto continua real, senão o desenho ficaria arrastado.

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
var _dedo := -1
var _abertos := {}


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
	if "--demo" in OS.get_cmdline_user_args():
		add_child(Demo.new(self))


func _process(delta: float) -> void:
	tempo_ms += delta * 1000.0
	_entregar(reconhecedor.tick(tempo_ms))
	# PLANEJAMENTO: com a âncora viva, o mundo desacelera; o dedo continua em
	# tempo real (é o que dá tempo de desenhar e de planejar).
	var plano: Dictionary = cfg_gestos.get("planejamento", {})
	var escala := 1.0
	if reconhecedor.ancorado():
		escala = float(plano.get("escala_tempo", 0.35))
	var dt := delta * escala
	for adv in adversarios:
		adv.passo(dt, mundo)
	Alvos.sincronizar(alvos, adversarios)
	corpo.passo(dt, mundo, alvos)
	for e in corpo.drenar_eventos():
		_evento(e)
	for cp in copas:
		cp.atualizar(corpo.pos, delta, corpo.camada == Mundo.SUBSOLO)
	# a rota continua VISÍVEL durante um gesto de ação; só a prévia da âncora
	# substitui a linha enquanto o jogador desenha.
	if reconhecedor.ancorado():
		_atualizar_previa()
	elif corpo.em_rota():
		trilha.mostrar(corpo.rota)
	else:
		trilha.mostrar(PackedVector2Array())
	camera.position = criatura.ponto_visual()
	hud.estado(corpo, alvos, reconhecedor.ancorado(), escala)


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
		if ev.pressed and _dedo == -1:
			_dedo = ev.index
			dedo_desceu(ev.position)
		elif not ev.pressed and ev.index == _dedo:
			_dedo = -1
			dedo_subiu(ev.position)
	elif ev is InputEventScreenDrag and ev.index == _dedo:
		dedo_moveu(ev.position)


func dedo_desceu(p: Vector2) -> void:
	if _dedo == -1:
		_dedo = 0  # o demo chama direto, sem InputEvent
	_entregar(reconhecedor.iniciar(p, tempo_ms, tela_de(criatura.ponto_visual() + Vector2(0, -20))))


func dedo_moveu(p: Vector2) -> void:
	_entregar(reconhecedor.mover(p, tempo_ms))


func dedo_subiu(p: Vector2) -> void:
	_entregar(reconhecedor.soltar(p, tempo_ms))
	_dedo = -1


func _entregar(evs: Array) -> void:
	for ev in evs:
		var pts_tela: PackedVector2Array = ev["pontos"]
		var desloc := Vector2.ZERO
		if ev["gesto"] == "trajetoria":
			# A ÂNCORA é o "animal virtual": o desenho inteiro é transladado
			# para que ela caia em cima da criatura — o dedo fica longe dela.
			desloc = tela_de(corpo.pos) - Vector2(ev.get("ancora", ev["fim"]))
		var pm := PackedVector2Array()
		for q in pts_tela:
			pm.append(mundo_de(q + desloc))
		ev["pontos_mundo"] = pm
		ev["alvo"] = pm[pm.size() - 1] if not pm.is_empty() else corpo.pos
		var cmd := Comandos.traduzir(ev, cfg_gestos.get("mapa", {}))
		var res := "não reconhecido" if cmd.is_empty() else str(corpo.comandar(cmd, mundo, alvos))
		hud.gesto(ev, cmd, res)


## Prévia do caminho durante a âncora: desenha o traço TRANSLADADO para a
## criatura (o dedo não tapa a visão) e marca onde está o "animal virtual".
func _atualizar_previa() -> void:
	if not reconhecedor.ancorado():
		trilha.mostrar(PackedVector2Array())
		return
	var desloc: Vector2 = tela_de(corpo.pos) - reconhecedor.ancora()
	var prev := PackedVector2Array()
	for q in reconhecedor.pontos():
		prev.append(mundo_de(q + desloc))
	trilha.mostrar(prev, mundo_de(reconhecedor.ancora()), true)


func mundo_de(tela: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * tela


func tela_de(mundo_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * mundo_pos


func _json(caminho: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(caminho))
