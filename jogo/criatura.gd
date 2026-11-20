extends Node2D
## A criatura provisória: segue a trajetória riscada (sim/trajetoria.gd).
## Sprite em pixel art com os pés na origem (y-sort), sombra lisa, passada com
## sobe-e-desce suave (movimento em subpixel — a tela não é pixelada).

const Trajetoria := preload("res://sim/trajetoria.gd")
const Objeto := preload("res://jogo/objeto.gd")
const VELOCIDADE := 110.0  # px de mundo por segundo

var textura: Texture2D
var caminho := PackedVector2Array()
var _andado := 0.0
var _tempo := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	if textura:
		_sprite.texture = textura
		_sprite.offset = Vector2(0, -Objeto.base_opaca(textura) + textura.get_height() / 2.0)
	add_child(_sprite)


func seguir(pontos: PackedVector2Array) -> void:
	caminho = Trajetoria.amostrar(pontos, 4.0)
	_andado = 0.0


func andando() -> bool:
	return caminho.size() >= 2 and _andado < Trajetoria.comprimento(caminho)


func _process(delta: float) -> void:
	_tempo += delta
	if andando():
		var antes := position
		_andado = minf(_andado + VELOCIDADE * delta, Trajetoria.comprimento(caminho))
		position = Trajetoria.ponto_em(caminho, _andado)
		var dx := position.x - antes.x
		if absf(dx) > 0.01:
			_sprite.flip_h = dx < 0.0
		_sprite.position.y = -absf(sin(_tempo * 11.0)) * 2.5
	else:
		_sprite.position.y = 0.0


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.3), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	if not textura:
		draw_circle(Vector2(0, -10), 10.0, Color("e8743b"), true, -1.0, true)
