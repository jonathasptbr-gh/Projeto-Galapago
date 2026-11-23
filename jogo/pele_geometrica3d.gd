extends RefCounted
## PELE ESQUELÉTICA 3D — o esqueleto de `sim/esqueleto3d.gd` desenhado em 2D:
## linhas BRANCAS de 2 px nos ossos e pontos VERMELHOS de raio 1,4 nas juntas,
## ordenados do longe para o perto pela profundidade da projeção. Mantém a
## mesma leitura da pele geométrica 2D; o que muda é a matemática por trás.
## As camadas de pixel art por osso (Fase B) NÃO entram aqui.

const E3 := preload("res://sim/esqueleto3d.gd")
const LINHA := Color("#ffffff")
const PONTO := Color("#ff3030")
const ANCORA := {"boca": Color("#7fe0ff"), "coroa": Color("#ffd84d"), "base_cauda": Color("#ff9f6b"),
	"dorso": Color("#c58bff"), "asa_e": Color("#9fe26a"), "asa_d": Color("#9fe26a")}


## `base` é o ponto do chão da criatura na tela; `tinta` escurece no subsolo.
## A `pose` já chega projetada com o yaw contínuo da câmera; `direcao` não
## entra aqui. Os sockets de módulos/VFX também já vêm resolvidos nela.
static func desenhar(c: CanvasItem, rig: Dictionary, pose: Dictionary, base: Vector2,
		tinta: Color = Color.WHITE, debug: bool = false, escala: float = 1.0) -> void:
	if pose.is_empty():
		return
	var j: Dictionary = pose.get("juntas", {})
	if j.is_empty():
		return
	var piv := Vector2(float(rig["pivot_px"][0]), float(rig["pivot_px"][1]))
	var linha := LINHA * tinta
	var ponto := PONTO * tinta
	for item in E3.ordem_pintor(rig, pose):
		if String(item["tipo"]) == "osso":
			if not j.has(item["a"]) or not j.has(item["b"]):
				continue
			c.draw_line(_p(j[item["a"]], base, piv, escala), _p(j[item["b"]], base, piv, escala),
				linha, 2.0 * escala, true)
		else:
			if not j.has(item["nome"]):
				continue
			c.draw_circle(_p(j[item["nome"]], base, piv, escala), 1.4 * escala, ponto, true, -1.0, true)
	if debug:
		_ancoras(c, pose, base, piv, escala)


static func _p(p: Vector2, base: Vector2, piv: Vector2, s: float) -> Vector2:
	return base + (p - piv) * s


## Só no debug: âncoras por NOME (as mesmas que módulos e VFX usam).
static func _ancoras(c: CanvasItem, pose: Dictionary, base: Vector2, piv: Vector2, s: float) -> void:
	var t: Dictionary = pose.get("sockets", {})
	for nome in t:
		if not bool(t[nome]["visivel"]):
			continue
		var cor: Color = ANCORA.get(nome, Color("#ffd84d"))
		if t[nome]["z"] == "back":
			cor = Color(cor.darkened(0.25), 0.75)
		var p: Vector2 = _p(t[nome]["pos"], base, piv, s)
		c.draw_circle(p, 3.4 * s, Color(0, 0, 0, 0.8), true, -1.0, true)
		c.draw_circle(p, 2.4 * s, cor, true, -1.0, true)
