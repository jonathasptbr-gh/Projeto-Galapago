extends Node2D
## MARCA DE MIRA: desenha o ALVO FINAL do caminho (marca amarela no INIMIGO,
## não no lugar final). A posição vem da lista de alvos (sim/alvos.gd), então
## ela acompanha um adversário que anda; se ele andar demais, o corpo perde a
## marca (v0.9). A mira vermelha do `travar` saiu em 2026-11-27.
## S5b: é marca NO CHÃO, no mapa do chão (`jogo/mundo3d/chao.gd`):
## o corpo do inimigo cobre o anel em volta dos pés.

const Alvos := preload("res://sim/alvos.gd")

var mundo: RefCounted
## Desenha em px de MUNDO da sim; o pai (`chao.raiz`) leva ao mapa do chão.
var corpo: RefCounted
var alvos: Array = []
var _tempo := 0.0


func _process(delta: float) -> void:
	_tempo += delta
	queue_redraw()


func _draw() -> void:
	if corpo == null:
		return
	_desenhar_alvo_final()


func _desenhar_alvo_final() -> void:
	if corpo.mira_final_id == "":
		return
	var p := Alvos.pos_de(alvos, corpo.mira_final_id)
	if p == Vector2.ZERO:
		return
	var pulso := 2.0 + 2.0 * sin(_tempo * 8.0)
	var cor := Color(1.0, 0.84, 0.2, 0.95)
	draw_arc(p, 24.0 + pulso, 0.0, TAU, 40, cor, 2.5, true)
	for d in [Vector2(1, 1), Vector2(1, -1)]:
		draw_line(p - d * 9.0, p + d * 9.0, cor, 2.5, true)
	draw_circle(p, 2.0, cor, true, -1.0, true)
