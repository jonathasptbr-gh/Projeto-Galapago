extends Node2D
## ADVERSÁRIO de teste na tela (mockup roxo). Só desenha o que a
## sim/adversario.gd faz: ele vagueia e, quando leva um golpe (v0.9), PISCA e
## sai empurrado — dano ainda não existe.

const Mock := preload("res://jogo/mock.gd")

var adv: RefCounted
var _tempo := 0.0
var _sprite: Texture2D


func _ready() -> void:
	_sprite = Mock.xadrez(32, 8, Color("#8b5cf6"), Color("#a78bfa"))


func _process(delta: float) -> void:
	if adv == null:
		return
	_tempo += delta
	position = adv.pos
	queue_redraw()


func _draw() -> void:
	var pulo := absf(sin(_tempo * 4.0)) * 2.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.28), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	var cor := Color(1.0, 0.55, 0.45) if adv.piscando() else Color.WHITE
	draw_texture_rect(_sprite, Rect2(Vector2(-16, -30 - pulo), Vector2(32, 30)), false, cor)
	if adv.piscando():
		draw_arc(Vector2(0, -15), 20.0, 0.0, TAU, 24, Color(1.0, 0.7, 0.5, 0.9), 2.0, true)
	var o: Vector2 = adv.olhar if adv.olhar.length() > 0.01 else Vector2.RIGHT
	draw_circle(Vector2(-6, -30 - pulo) + o * 4.0, 2.0, Color("#22113f"))
	draw_circle(Vector2(6, -30 - pulo) + o * 4.0, 2.0, Color("#22113f"))
