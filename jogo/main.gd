extends Node2D
## Cena principal (v0.4): a FUNDAÇÃO em mockup.
##
## Camadas de desenho (z_index), de trás para frente:
##   -20 parallax fundo (mar profundo, anda devagar)
##     0 chão (xadrez por terreno; níveis altos sobem, com parede ao sul;
##       água semitransparente mostra o fundo)
##     1 trilha (o traço, liso)
##     2 objetos com y-sort pela base (troncos, baú, a criatura)
##    15 subsolo (só com a criatura embaixo da terra; ela sobe para 20)
##    30 copas (subcamada de visibilidade)
##    40 parallax frente (nuvens, andam mais rápido)
##   HUD (CanvasLayer, resolução da tela)
## O fluxo do dedo: dedo_* → sim/gestos → sim/comandos → sim/corpo; o tempo é
## SIMULADO (tempo_ms), então a demo e o oráculo são determinísticos.

const Mundo := preload("res://sim/mundo.gd")
const Corpo := preload("res://sim/corpo.gd")
const Gestos := preload("res://sim/gestos.gd")
const Comandos := preload("res://sim/comandos.gd")
const Mock := preload("res://jogo/mock.gd")
const Chao := preload("res://jogo/camadas/chao.gd")
const Subsolo := preload("res://jogo/camadas/subsolo.gd")
const ObjetoMock := preload("res://jogo/camadas/objeto_mock.gd")
const Copa := preload("res://jogo/camadas/copa.gd")
const Parallax := preload("res://jogo/camadas/parallax.gd")
const Criatura := preload("res://jogo/criatura.gd")
const Trilha := preload("res://jogo/trilha.gd")
const Hud := preload("res://jogo/hud.gd")
const Demo := preload("res://jogo/demo.gd")

const MAPA := "res://dados/mapas/fundacao.json"

var mundo: RefCounted
var corpo: RefCounted
var reconhecedor: RefCounted
var cfg_gestos: Dictionary
var tempo_ms := 0.0
var chao: Node2D
var subsolo: Node2D
var criatura: Node2D
var trilha: Node2D
var camera: Camera2D
var hud: CanvasLayer
var copas: Array = []
var _dedo := -1
var _bruto := PackedVector2Array()


func _ready() -> void:
	var mapa := _json(MAPA)
	cfg_gestos = _json("res://dados/gestos.json")
	mundo = Mundo.criar(mapa, _json("res://dados/terrenos.json"))
	for e in mundo.validar():
		push_error("mapa: " + e)
	corpo = Corpo.new(_json("res://dados/acoes.json"))
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
	criatura = Criatura.new()
	criatura.corpo = corpo
	criatura.mundo = mundo
	objetos.add_child(criatura)
	subsolo = Subsolo.new()
	subsolo.mundo = mundo
	subsolo.z_index = 15
	subsolo.visible = false
	no.add_child(subsolo)

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
	corpo.passo(delta, mundo)
	for e in corpo.drenar_eventos():
		if e.begins_with("camada:"):
			subsolo.visible = corpo.camada == Mundo.SUBSOLO
			chao.queue_redraw()
			subsolo.queue_redraw()
		elif e == "fim:mover":
			trilha.mostrar(PackedVector2Array())
	for cp in copas:
		cp.atualizar(corpo.pos, delta, corpo.camada == Mundo.SUBSOLO)
	camera.position = criatura.ponto_visual()
	var alt: float = mundo.altura(mundo.celula_de(corpo.pos)) if corpo.camada == Mundo.SUPERFICIE else 0.0
	hud.estado(corpo, alt)


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
	_bruto = PackedVector2Array([mundo_de(p)])
	_entregar(reconhecedor.iniciar(p, tempo_ms, tela_de(criatura.ponto_visual() + Vector2(0, -20))))


func dedo_moveu(p: Vector2) -> void:
	_bruto.append(mundo_de(p))
	trilha.mostrar(_bruto)
	_entregar(reconhecedor.mover(p, tempo_ms))


func dedo_subiu(p: Vector2) -> void:
	_entregar(reconhecedor.soltar(p, tempo_ms))


func _entregar(evs: Array) -> void:
	for ev in evs:
		ev["alvo"] = mundo_de(ev["fim"])
		var pm := PackedVector2Array()
		for q in ev["pontos"]:
			pm.append(mundo_de(q))
		ev["pontos_mundo"] = pm
		var cmd := Comandos.traduzir(ev, corpo.olhar, cfg_gestos.get("mapa", {}))
		var res := "não reconhecido" if cmd.is_empty() else str(corpo.comandar(cmd, mundo))
		hud.gesto(ev, cmd, res)
		if cmd.get("acao", "") == "mover" and res == "aceito":
			trilha.mostrar(corpo.caminho)
		elif ev["gesto"] != "segurar_inicio":
			trilha.mostrar(PackedVector2Array())


func mundo_de(tela: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * tela


func tela_de(mundo_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * mundo_pos


func _json(caminho: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(caminho))
