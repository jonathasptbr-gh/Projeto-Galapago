extends Node2D
## EFEITOS na tela (v0.9): a ONDA do laço (anel que cresce a partir do centro)
## e o TIRO do bico (projétil). Só LÊ `corpo.efeitos` — a regra (raio, alcance,
## empurrão, quem foi atingido) é da `sim/`, em `sim/corpo.gd`.
## S5b — duas instâncias: `no_ar = false` desenha só a ONDA, no mapa do chão
## (`jogo/mundo3d/chao.gd`: fica sob a criatura e as copas); `no_ar = true`
## desenha só o TIRO, projétil no ar, na camada de tela por cima do 3D (a
## afim da câmera + `relevo`, como antes: chão do mapa o colaria no relevo
## e o esconderia sob a própria criatura que atira).

var corpo: RefCounted
var mundo: RefCounted
## false: a onda (no mapa do chão); true: o tiro (na tela)
var no_ar := false
## só no ar: desenha em px de MUNDO da sim; o pai aplica a afim chão→tela da
## câmera 3D (`sim/camera3d.gd chao_para_tela`, no plano de referência) e
## `relevo` (do main) leva o ponto ao TOPO do terreno da sua célula nesse plano.
var relevo := Callable()


func _process(_delta: float) -> void:
	queue_redraw()


func _relevo(p: Vector2) -> Vector2:
	return relevo.call(p) if relevo.is_valid() else p


func _draw() -> void:
	if corpo == null:
		return
	for e in corpo.efeitos:
		match str(e["tipo"]):
			"onda":
				if no_ar:
					continue
				var centro := Vector2(e["centro"])
				var r := float(e["raio"])
				if r > 0.5:
					draw_circle(centro, r, Color(0.45, 0.75, 1.0, 0.16), true)
					draw_arc(centro, r, 0.0, TAU, 64, Color(0.62, 0.9, 1.0, 0.95), 3.0, true)
					draw_arc(centro, r * 0.7, 0.0, TAU, 48, Color(0.62, 0.9, 1.0, 0.35), 2.0, true)
			"tiro":
				if not no_ar:
					continue
				var p := _relevo(Vector2(e["pos"]))
				var d := Vector2(e["dir"]) if Vector2(e["dir"]).length() > 0.01 else Vector2.RIGHT
				draw_line(p - d * 20.0, p, Color(1.0, 0.8, 0.3, 0.75), 4.0, true)
				draw_circle(p, float(e["raio"]), Color(1.0, 0.9, 0.45, 0.95), true, -1.0, true)
				draw_circle(p, float(e["raio"]) * 0.45, Color(1.0, 1.0, 0.9, 0.95), true, -1.0, true)
