extends Node2D
## A LINHA DO CAMINHO (v0.9.2): desenhada como o traço REAL do dedo — os pontos
## densos do desenho, não a rota simplificada (que traçava retas entre os
## pontos de referência e ficava quebrada).
##
## Estilo: **PONTILHADA**, **escura e transparente**, no chão (z_index 1, embaixo
## dos objetos e da criatura). Os pontinhos são espaçados por ARCO, então
## acompanham a curva de verdade, sem emendar retas.
##
## O que ela mostra é `corpo.traco` (o desenho cru, em pontos de MUNDO) — quem
## chama decide quando há linha (desenhando ou em rota).

var pontos := PackedVector2Array()

const PASSO_PX := 7.0       # distância entre os pontinhos, no arco
const RAIO := 2.1           # raio do pontinho
const COR := Color(0.04, 0.09, 0.12, 0.55)  # escura e transparente


func mostrar(p: PackedVector2Array) -> void:
	pontos = p
	queue_redraw()


func _draw() -> void:
	if pontos.size() < 2:
		return
	var sobra := 0.0
	for i in range(1, pontos.size()):
		var a := pontos[i - 1]
		var b := pontos[i]
		var seg := a.distance_to(b)
		if seg < 0.0001:
			continue
		var t := sobra
		while t <= seg:
			draw_circle(a.lerp(b, t / seg), RAIO, COR, true, -1.0, true)
			t += PASSO_PX
		sobra = t - seg
	# a ponta do caminho: um pontinho um pouco maior (o destino)
	draw_circle(pontos[pontos.size() - 1], RAIO + 1.0, Color(COR, 0.85), true, -1.0, true)
