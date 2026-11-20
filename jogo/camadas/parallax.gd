extends Node2D
## PARALLAX (mockup): um FUNDO distante que anda mais devagar que a câmera
## (o mar profundo, visto pela água semitransparente do chão) e NUVENS na
## frente de tudo, que andam mais rápido. Parallax2D (Godot ≥ 4.3).

const Mock := preload("res://jogo/mock.gd")


func _ready() -> void:
	var fundo := Parallax2D.new()
	fundo.scroll_scale = Vector2(0.35, 0.35)
	fundo.repeat_size = Vector2(256, 256)
	fundo.repeat_times = 8
	fundo.z_index = -20
	var mar := Sprite2D.new()
	mar.texture = Mock.xadrez(256, 32, Color("#0e2f4a"), Color("#123a5a"))
	mar.centered = false
	fundo.add_child(mar)
	add_child(fundo)

	var frente := Parallax2D.new()
	frente.scroll_scale = Vector2(1.35, 1.35)
	frente.repeat_size = Vector2(900, 600)
	frente.repeat_times = 3
	frente.z_index = 40
	frente.add_child(_Nuvens.new())
	add_child(frente)


class _Nuvens:
	extends Node2D

	func _draw() -> void:
		for c in [Vector2(120, 90), Vector2(520, 340), Vector2(760, 120)]:
			for k in 4:
				draw_circle(c + Vector2(k * 26 - 39, (k % 2) * 8), 30.0 - k * 2.0, Color(1, 1, 1, 0.13), true, -1.0, true)
