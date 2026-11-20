extends Node2D
## Objeto do mundo em MOCKUP (tronco de árvore, baú…), com a origem na BASE
## (para o y-sort) e desenhado na altura do terreno. A copa NÃO é daqui: fica
## numa camada por cima de tudo (jogo/camadas/copa.gd).

const Mock := preload("res://jogo/mock.gd")

var tipo := ""
var desnivel := 0.0
var id_objeto := ""
var aberto := false


func _draw() -> void:
	var o := Vector2(0, desnivel)
	draw_set_transform(o, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 12.0, Color(0, 0, 0, 0.25), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	match tipo:
		"arvore":
			draw_texture_rect(Mock.xadrez(12, 3, Color("#6e4a2a"), Color("#8a5d35")), Rect2(o + Vector2(-6, -26), Vector2(12, 26)), false)
		"bau":
			var a := Color("#6b6b6b") if aberto else Color("#d9a520")
			var b := Color("#8a8a8a") if aberto else Color("#f2c94c")
			draw_texture_rect(Mock.xadrez(20, 4, a, b), Rect2(o + Vector2(-10, -14), Vector2(20, 14)), false)
		_:
			draw_rect(Rect2(o + Vector2(-8, -16), Vector2(16, 16)), Color.MAGENTA)
