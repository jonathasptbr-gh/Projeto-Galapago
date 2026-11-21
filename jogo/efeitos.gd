extends Node2D
## EFEITOS na tela (v0.9): a ONDA do laço (anel que cresce a partir do centro)
## e o TIRO do bico (projétil). Só LÊ `corpo.efeitos` — a regra (raio, alcance,
## empurrão, quem foi atingido) é da `sim/`, em `sim/corpo.gd`.

var corpo: RefCounted


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if corpo == null:
		return
	for e in corpo.efeitos:
		match str(e["tipo"]):
			"onda":
				var centro := Vector2(e["centro"])
				var r := float(e["raio"])
				if r > 0.5:
					draw_circle(centro, r, Color(0.45, 0.75, 1.0, 0.16), true)
					draw_arc(centro, r, 0.0, TAU, 64, Color(0.62, 0.9, 1.0, 0.95), 3.0, true)
					draw_arc(centro, r * 0.7, 0.0, TAU, 48, Color(0.62, 0.9, 1.0, 0.35), 2.0, true)
			"tiro":
				var p := Vector2(e["pos"])
				var d := Vector2(e["dir"]) if Vector2(e["dir"]).length() > 0.01 else Vector2.RIGHT
				draw_line(p - d * 20.0, p, Color(1.0, 0.8, 0.3, 0.75), 4.0, true)
				draw_circle(p, float(e["raio"]), Color(1.0, 0.9, 0.45, 0.95), true, -1.0, true)
				draw_circle(p, float(e["raio"]) * 0.45, Color(1.0, 1.0, 0.9, 0.95), true, -1.0, true)
