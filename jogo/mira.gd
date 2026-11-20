extends Node2D
## MARCA DE MIRA: desenha o alvo travado (anel + cruzeta que pulsa). A posição
## vem da lista de alvos (sim/alvos.gd), então acompanha um adversário que anda.

const Alvos := preload("res://sim/alvos.gd")

var corpo: RefCounted
var alvos: Array = []
var _tempo := 0.0


func _process(delta: float) -> void:
	_tempo += delta
	queue_redraw()


func _draw() -> void:
	if corpo == null or corpo.alvo_id == "":
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
