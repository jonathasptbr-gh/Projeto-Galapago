extends Node2D
## Cena principal (v0.3): a ilha de teste vista de cima, com profundidade.
##
## Mundo (pixels de mundo; câmera com zoom 2 → cada pixel da arte vira 2×2 na
## tela 1280×720) = mapa (TileMapLayer) + trilha + objetos com y-sort (árvores,
## rochas, estação e a criatura, ordenados pela base). HUD em CanvasLayer, na
## resolução da tela. Com `-- --demo`, um traço roteirizado substitui o dedo
## (é o que o oráculo grava). Regra de jogo nenhuma mora aqui.

const Mapa := preload("res://jogo/mapa.gd")
const Objeto := preload("res://jogo/objeto.gd")
const Criatura := preload("res://jogo/criatura.gd")
const Trilha := preload("res://jogo/trilha.gd")
const Atualizador := preload("res://jogo/atualizador.gd")

const MAPA := "res://dados/mapas/ilha_teste.json"
const ZOOM := 2.0
const DIR_OBJETOS := "res://arte/cenarios/objetos/"
const SOMBRA := {"arvore": 0.0, "rocha": 12.0, "estacao": 30.0}  # árvore: sombra já vem na arte

var mundo: Node2D
var mapa: Node2D
var objetos: Node2D
var trilha: Node2D
var criatura: Node2D
var camera: Camera2D
var _riscando := false
var _bruto := PackedVector2Array()


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("0f3b45"))
	mundo = Node2D.new()
	add_child(mundo)

	mapa = Mapa.new()
	mundo.add_child(mapa)
	for e in mapa.carregar(MAPA):
		push_error("mapa: " + e)

	trilha = Trilha.new()
	mundo.add_child(trilha)

	objetos = Node2D.new()
	objetos.y_sort_enabled = true
	mundo.add_child(objetos)
	for o in mapa.dados.get("objetos", []):
		var obj := Objeto.new()
		var tipo: String = o["tipo"]
		var arq := DIR_OBJETOS + tipo + ".png"
		if ResourceLoader.exists(arq):
			obj.textura = load(arq)
		obj.raio_sombra = SOMBRA.get(tipo, 14.0)
		obj.position = mapa.centro_celula(Vector2(o["celula"][0], o["celula"][1]))
		objetos.add_child(obj)

	criatura = Criatura.new()
	if ResourceLoader.exists("res://arte/criaturas/cao_base_prova.png"):
		criatura.textura = load("res://arte/criaturas/cao_base_prova.png")
	var ini: Array = mapa.dados.get("inicio", [0, 0])
	criatura.position = mapa.centro_celula(Vector2(ini[0], ini[1]))
	objetos.add_child(criatura)

	camera = Camera2D.new()
	camera.zoom = Vector2(ZOOM, ZOOM)
	var r: Rect2 = mapa.limites()
	camera.limit_left = int(r.position.x)
	camera.limit_top = int(r.position.y)
	camera.limit_right = int(r.end.x)
	camera.limit_bottom = int(r.end.y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.position = criatura.position
	mundo.add_child(camera)
	camera.make_current()

	_montar_hud()

	if "--demo" in OS.get_cmdline_user_args():
		var p := PackedVector2Array()
		var a := criatura.position
		for i in 41:
			var t := i / 40.0
			# contorna o planalto por baixo (ainda não há altura nem colisão)
			p.append(a + Vector2(330.0 * t, 150.0 * t + 40.0 * sin(t * PI)))
		trilha.mostrar(p)
		criatura.seguir(p)


func _montar_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var titulo := Label.new()
	var versao: String = ProjectSettings.get_setting("application/config/version", "local")
	titulo.text = "Projeto Galápago  ·  %s" % ("build local" if versao == "local" else "v" + versao)
	var ls := LabelSettings.new()
	ls.font_size = 22
	ls.outline_size = 6
	ls.outline_color = Color(0, 0, 0, 0.6)
	titulo.label_settings = ls
	titulo.position = Vector2(20, 14)
	hud.add_child(titulo)
	hud.add_child(Atualizador.new())


func _process(_delta: float) -> void:
	camera.position = criatura.position
	if not _riscando and not criatura.andando() and not trilha.pontos.is_empty():
		trilha.mostrar(PackedVector2Array())


func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventScreenTouch or ev is InputEventScreenDrag):
		return
	var local := mundo.make_input_local(ev)
	if ev is InputEventScreenTouch:
		if ev.pressed:
			_riscando = true
			_bruto = PackedVector2Array([criatura.position, local.position])
		else:
			_riscando = false
			criatura.seguir(_bruto)
	elif _riscando:
		_bruto.append(local.position)
	trilha.mostrar(_bruto)
