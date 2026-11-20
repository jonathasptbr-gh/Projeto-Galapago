extends Node2D
## Camada SUBSOLO (mockup): só aparece com a criatura embaixo da terra.
## Escurece a superfície inteira e desenha os túneis (e o que foi escavado)
## em xadrez marrom. A criatura sobe de z_index para ficar por cima dela.

var mundo: RefCounted


func _draw() -> void:
	if mundo == null:
		return
	var cp := float(mundo.celula_px)
	draw_rect(Rect2(Vector2(-cp * 4, -cp * 4), Vector2(mundo.largura + 8, mundo.altura_grade + 8) * cp), Color(0.03, 0.02, 0.02, 0.82))
	var meia := cp / 2.0
	for y in mundo.altura_grade:
		for x in mundo.largura:
			var c := Vector2i(x, y)
			if not mundo.andavel(c, "subsolo"):
				continue
			var o := Vector2(x * cp, y * cp)
			var a := Color("#6b4a2e")
			var b := Color("#7d5737")
			draw_rect(Rect2(o, Vector2(meia, meia)), a)
			draw_rect(Rect2(o + Vector2(meia, 0), Vector2(meia, meia)), b)
			draw_rect(Rect2(o + Vector2(0, meia), Vector2(meia, meia)), b)
			draw_rect(Rect2(o + Vector2(meia, meia), Vector2(meia, meia)), a)
			if mundo.pode_escavar(c, "subsolo"):  # dá para subir aqui
				draw_arc(o + Vector2(meia, meia), meia * 0.6, 0.0, TAU, 24, Color(1, 0.85, 0.5, 0.8), 1.5, true)
