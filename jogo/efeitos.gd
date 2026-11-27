extends Node2D
## EFEITOS na tela: o TIRO (projétil). Só LÊ `corpo.efeitos` — a regra (raio,
## alcance, empurrão, quem foi atingido) é da `sim/`, em `sim/corpo.gd`.
## O tiro é projétil NO AR: desenha na camada de tela por cima do 3D (a afim
## da câmera + `relevo`; o mapa do chão o colaria no relevo e o esconderia sob
## a própria criatura que atira). A ONDA do laço, que era desenhada no mapa do
## chão, saiu em 2026-11-27.

var corpo: RefCounted
var mundo: RefCounted
## desenha em px de MUNDO da sim; o pai aplica a afim chão→tela da câmera 3D
## (`sim/camera3d.gd chao_para_tela`, no plano de referência) e `relevo` (do
## main) leva o ponto ao TOPO do terreno da sua célula nesse plano.
var relevo := Callable()


func _process(_delta: float) -> void:
	queue_redraw()


func _relevo(p: Vector2) -> Vector2:
	return relevo.call(p) if relevo.is_valid() else p


func _draw() -> void:
	if corpo == null:
		return
	for e in corpo.efeitos:
		if str(e["tipo"]) != "tiro":
			continue
		var p := _relevo(Vector2(e["pos"]))
		var d := Vector2(e["dir"]) if Vector2(e["dir"]).length() > 0.01 else Vector2.RIGHT
		draw_line(p - d * 20.0, p, Color(1.0, 0.8, 0.3, 0.75), 4.0, true)
		draw_circle(p, float(e["raio"]), Color(1.0, 0.9, 0.45, 0.95), true, -1.0, true)
		draw_circle(p, float(e["raio"]) * 0.45, Color(1.0, 1.0, 0.9, 0.95), true, -1.0, true)
