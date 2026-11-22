extends Node2D
## Camada CHÃO (mockup): cada célula em xadrez 2×2 na cor do terreno; níveis
## acima do chão são desenhados mais ALTOS na tela, com a face sul (parede)
## aparecendo onde a célula de baixo é mais baixa — é isso que dá profundidade.
## A água é semitransparente: deixa ver o fundo parallax (profundidade do mar).
## Buracos escavados aparecem como um círculo escuro.

const Mock := preload("res://jogo/mock.gd")

var mundo: RefCounted
var inclinacao := 1.0


func _draw() -> void:
	if mundo == null:
		return
	var cp := float(mundo.celula_px)
	var meia := cp / 2.0
	for y in mundo.altura_grade:
		for x in mundo.largura:
			var c := Vector2i(x, y)
			var t: Dictionary = mundo.terreno(c)
			var cores: Array = t.get("cores", ["#ff00ff", "#000000"])
			var a := Color(cores[0])
			var b := Color(cores[1])
			if t.get("transparente", false):
				a.a = 0.55
				b.a = 0.55
			var alt: float = float(t.get("altura", 1))
			var dy := Mock.desnivel(alt, inclinacao)
			var o := Vector2(x * cp, y * cp + dy)
			# topo da célula em xadrez 2×2
			draw_rect(Rect2(o, Vector2(meia, meia)), a)
			draw_rect(Rect2(o + Vector2(meia, 0), Vector2(meia, meia)), b)
			draw_rect(Rect2(o + Vector2(0, meia), Vector2(meia, meia)), b)
			draw_rect(Rect2(o + Vector2(meia, meia), Vector2(meia, meia)), a)
			# Pequenas marcas de textura aparecem gradualmente só de perto.
			var detalhe := clampf((1.0 - inclinacao) / 0.40, 0.0, 1.0)
			if detalhe > 0.0 and (x * 7 + y * 11) % 3 == 0:
				var cor_detalhe := a.lightened(0.18)
				cor_detalhe.a = 0.35 * detalhe
				draw_line(o + Vector2(5, 9), o + Vector2(9, 9), cor_detalhe, 1.0)
			# face sul (parede) se a de baixo é mais baixa
			var alt_baixo: float = mundo.altura(Vector2i(x, y + 1))
			var face := Mock.desnivel(alt_baixo, inclinacao) - dy
			if face > 0.5:
				draw_rect(Rect2(Vector2(x * cp, (y + 1) * cp + dy), Vector2(cp, face)), a.darkened(0.45))
				draw_line(Vector2(x * cp, (y + 1) * cp + dy), Vector2((x + 1) * cp, (y + 1) * cp + dy), a.darkened(0.65), 1.0)
			if mundo.escavadas.has(c):
				draw_circle(o + Vector2(meia, meia), meia * 0.62, Color(0.08, 0.05, 0.03, 0.9), true, -1.0, true)
