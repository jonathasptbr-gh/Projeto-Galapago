extends Node2D
## A linha riscada pelo jogador, desenhada LISA (antialiasing na resolução da
## tela) por cima do chão e por baixo dos objetos, com um anel no destino.
## v0.6: durante o desenho por ÂNCORA, a linha já aparece transladada sobre a
## criatura e um anel marca o "animal virtual" (o ponto segurado, longe dela).

var pontos := PackedVector2Array()
var ancora := Vector2.ZERO
var tem_ancora := false


func mostrar(p: PackedVector2Array, a := Vector2.ZERO, marca := false) -> void:
	pontos = p
	ancora = a
	tem_ancora = marca
	queue_redraw()


func _draw() -> void:
	if tem_ancora:
		draw_arc(ancora, 10.0, 0.0, TAU, 32, Color(0.35, 0.9, 1.0, 0.95), 2.0, true)
		draw_line(ancora + Vector2(-5, 0), ancora + Vector2(5, 0), Color(0.35, 0.9, 1.0, 0.95), 1.5, true)
		draw_line(ancora + Vector2(0, -5), ancora + Vector2(0, 5), Color(0.35, 0.9, 1.0, 0.95), 1.5, true)
	if pontos.size() < 2:
		return
	draw_polyline(pontos, Color(0, 0, 0, 0.25), 4.0, true)
	draw_polyline(pontos, Color(1, 1, 1, 0.9), 2.0, true)
	var fim := pontos[pontos.size() - 1]
	draw_arc(fim, 8.0, 0.0, TAU, 40, Color(1, 1, 1, 0.95), 1.5, true)
	draw_circle(fim, 2.5, Color(1, 1, 1, 0.95), true, -1.0, true)
