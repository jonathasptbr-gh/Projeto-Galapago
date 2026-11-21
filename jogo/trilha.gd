extends Node2D
## A linha riscada pelo jogador, desenhada LISA (antialiasing na resolução da
## tela) por cima do chão e por baixo dos objetos, com um anel no destino.
## v0.7: a linha mostrada é a ROTA que a criatura já está seguindo (o caminho
## é desenhado ao vivo), em pontos de MUNDO. Não há mais âncora na tela: a
## origem é a posição da criatura quando o dedo desceu.

var pontos := PackedVector2Array()


func mostrar(p: PackedVector2Array) -> void:
	pontos = p
	queue_redraw()


func _draw() -> void:
	if pontos.size() < 2:
		return
	draw_polyline(pontos, Color(0, 0, 0, 0.25), 4.0, true)
	draw_polyline(pontos, Color(1, 1, 1, 0.9), 2.0, true)
	var fim := pontos[pontos.size() - 1]
	draw_arc(fim, 8.0, 0.0, TAU, 40, Color(1, 1, 1, 0.95), 1.5, true)
	draw_circle(fim, 2.5, Color(1, 1, 1, 0.95), true, -1.0, true)
