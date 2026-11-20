extends Node2D
## Cena viva mínima (v0.1): o jogador risca, a criatura provisória segue.
##
## Camada `jogo/`: lê toque, desenha, chama a `sim/`. Regra nenhuma de jogo
## mora aqui. Com o argumento de usuário `--demo` (depois de `--` na linha de
## comando), um traço roteirizado substitui o dedo: é o que o oráculo de
## quadros grava (tools/quadros.sh).

const Trajetoria := preload("res://sim/trajetoria.gd")

const VELOCIDADE := 60.0  # px/s na resolução interna
const DIST_MIN := 3.0
const COR_CEU := Color("1b2a3a")
const COR_CHAO := Color("3c6e47")
const COR_TRACO := Color("f2efe6")
const COR_CRIATURA := Color("e8743b")

var _riscando := false
var _bruto := PackedVector2Array()
var _caminho := PackedVector2Array()
var _andado := 0.0
var _pos := Vector2(40, 140)


func _ready() -> void:
	if "--demo" in OS.get_cmdline_user_args():
		var demo := PackedVector2Array()
		for i in 41:
			var t := i / 40.0
			demo.append(Vector2(40 + 240 * t, 140 - 50 * sin(t * PI)))
		_seguir(demo)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed:
			_riscando = true
			_bruto = PackedVector2Array([ev.position])
		else:
			_riscando = false
			_seguir(_bruto)
	elif ev is InputEventScreenDrag and _riscando:
		_bruto.append(ev.position)
	queue_redraw()


func _seguir(pontos: PackedVector2Array) -> void:
	_caminho = Trajetoria.amostrar(pontos, DIST_MIN)
	_andado = 0.0


func _process(delta: float) -> void:
	if _caminho.size() >= 2:
		_andado = minf(_andado + VELOCIDADE * delta, Trajetoria.comprimento(_caminho))
		_pos = Trajetoria.ponto_em(_caminho, _andado)
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), COR_CEU)
	draw_rect(Rect2(0, 150, 320, 30), COR_CHAO)
	var traco := _bruto if _riscando else _caminho
	if traco.size() >= 2:
		draw_polyline(traco, COR_TRACO, 1.0)
	draw_circle(_pos.round(), 6, COR_CRIATURA)
	draw_string(ThemeDB.fallback_font, Vector2(6, 14), "Projeto Galápago v0.1",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COR_TRACO)
