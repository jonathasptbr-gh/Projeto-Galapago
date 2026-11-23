extends RefCounted
## PELE ESQUELÉTICA — o rig desenhado SÓ com linhas e pontos de articulação:
## linhas BRANCAS nos ossos, pontos VERMELHOS nas juntas. Nada de corpo
## preenchido: nesta fase o alvo é ler o movimento das juntas. Foco no
## quadrúpede canino; serpente e ave usam o mesmo renderizador genérico.
## Trocar por sprite é trocar esta pele, não a mecânica.

const E := preload("res://sim/esqueleto.gd")
const LINHA := Color("#ffffff")
const PONTO := Color("#ff3030")
const ANCORA := {"boca": Color("#7fe0ff"), "coroa": Color("#ffd84d"), "base_cauda": Color("#ff9f6b"),
	"dorso": Color("#c58bff"), "asa_e": Color("#9fe26a"), "asa_d": Color("#9fe26a")}


## `base` é o ponto do chão da criatura na tela; `tinta` escurece no subsolo.
static func desenhar(c: CanvasItem, rig: Dictionary, direcao: String, fase: float, clipe: String,
		base: Vector2, tinta: Color = Color.WHITE, debug: bool = false, escala: float = 1.0,
		pose_pronta: Dictionary = {}) -> void:
	var pose := pose_pronta
	if pose.is_empty():
		pose = E.pose(rig, direcao, fase, clipe)
	if pose.is_empty():
		return
	var j: Dictionary = pose["juntas"]
	var piv := Vector2(float(rig["pivot_px"][0]), float(rig["pivot_px"][1]))
	var perf: Dictionary = rig["profiles"][rig["directions"][direcao]["profile"]]
	var linha := LINHA * tinta
	var ponto := PONTO * tinta
	# ossos (linhas) primeiro, juntas (pontos) por cima
	for b in perf["bones"]:
		if j.has(b["a"]) and j.has(b["b"]):
			c.draw_line(_p(j[b["a"]], base, piv, escala), _p(j[b["b"]], base, piv, escala),
				linha, 2.0 * escala, true)
	for nome in j:
		c.draw_circle(_p(j[nome], base, piv, escala), 2.2 * escala, ponto, true, -1.0, true)
	if debug:
		_ancoras(c, rig, pose, direcao, base, piv, escala)


static func _p(p: Vector2, base: Vector2, piv: Vector2, s: float) -> Vector2:
	return base + (p - piv) * s


## Só no debug: âncoras por NOME (as mesmas que módulos e VFX usam).
static func _ancoras(c: CanvasItem, rig: Dictionary, pose: Dictionary, direcao: String,
		base: Vector2, piv: Vector2, s: float) -> void:
	var t := E.sockets(rig, pose, direcao)
	for nome in t:
		if not t[nome]["visivel"]:
			continue
		var cor: Color = ANCORA.get(nome, Color("#ffd84d"))
		if t[nome]["z"] == "back":
			cor = Color(cor.darkened(0.25), 0.75)
		var p: Vector2 = _p(t[nome]["pos"], base, piv, s)
		c.draw_circle(p, 3.4 * s, Color(0, 0, 0, 0.8), true, -1.0, true)
		c.draw_circle(p, 2.4 * s, cor, true, -1.0, true)
