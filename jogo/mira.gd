extends Node2D
## MARCA DE MIRA: desenha o alvo travado (anel + cruzeta que pulsa) e o ALVO
## FINAL do caminho (marca amarela no INIMIGO, não no lugar final). A posição
## vem da lista de alvos (sim/alvos.gd), então as duas acompanham um adversário
## que anda; se ele andar demais, o corpo perde a marca (v0.9).

const Alvos := preload("res://sim/alvos.gd")

var corpo: RefCounted
var alvos: Array = []
var _tempo := 0.0


func _process(delta: float) -> void:
	_tempo += delta
	queue_redraw()


func _draw() -> void:
	if corpo == null:
		return
	_desenhar_mira()
	_desenhar_alvo_final()


func _desenhar_mira() -> void:
	if corpo.alvo_id == "":
		return
	var p := Alvos.pos_de(alvos, corpo.alvo_id)
	if p == Vector2.ZERO:
		return
	var pulso := 1.0 + 0.12 * sin(_tempo * 6.0)
	var r := 20.0 * pulso
	draw_arc(p, r, 0.0, TAU, 32, Color(1.0, 0.35, 0.35, 0.95), 2.0, true)
	for a in [0.0, PI / 2.0, PI, PI * 1.5]:
		var d := Vector2.from_angle(a)
		draw_line(p + d * (r + 3.0), p + d * (r + 9.0), Color(1.0, 0.35, 0.35, 0.95), 2.0, true)
	draw_circle(p, 2.0, Color(1.0, 0.35, 0.35, 0.95), true, -1.0, true)


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
