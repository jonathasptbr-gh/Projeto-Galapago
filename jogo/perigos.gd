extends Node2D
## A ÁREA DEMARCADA NO CHÃO (v0.14) — o aviso de que o inimigo está preparando
## um ataque. Só LÊ o que a `sim/adversario.gd` já decidiu (`perigos` e
## `efeitos`): aqui não há regra nenhuma.
##
## Três formas, uma por ataque:
## - **círculo** (bote): onde ele vai morder; a borda fecha e o miolo enche até
##   a hora do golpe — saia de dentro;
## - **faixa** (esbarrão): a canaleta por onde ele vai CORRER — saia do corredor;
## - **linha** (cuspe): o caminho do projétil — saia da linha.
##
## O miolo acende devagar e PISCA perto do fim: dá tempo de reagir sem precisar
## contar segundos. O projétil do cuspe é desenhado aqui também.
## S5b — duas instâncias: `no_ar = false` desenha as ÁREAS no mapa do chão
## (`jogo/mundo3d/chao.gd`: o inimigo, as copas e as paredes ficam por cima);
## `no_ar = true` desenha só o PROJÉTIL do cuspe, no ar, na camada de tela
## (afim da câmera + `relevo`).


var mundo: RefCounted
## false: as áreas (no mapa do chão); true: o projétil (na tela)
var no_ar := false
## só no ar: o pai aplica a afim chão→tela da câmera 3D (plano de referência)
## e `relevo` (do main) leva o ponto ao TOPO do terreno da sua célula.
var relevo := Callable()
var adversarios: Array = []


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for adv in adversarios:
		if adv == null:
			continue
		if not no_ar:
			for p in adv.perigos:
				_area(p)
			continue
		for e in adv.efeitos:
			var origem := Vector2(e.get("pos", Vector2.ZERO))
			draw_set_transform(_relevo(origem) - origem)
			_projetil(e)
		draw_set_transform(Vector2.ZERO)


func _relevo(p: Vector2) -> Vector2:
	return relevo.call(p) if relevo.is_valid() else p


func _cor(tipo: String) -> Color:
	match tipo:
		"bote":
			return Color(1.0, 0.30, 0.24)
		"esbarrao":
			return Color(1.0, 0.56, 0.16)
		"cuspe":
			return Color(0.85, 0.34, 0.92)
	return Color(1.0, 0.4, 0.3)


func _area(p: Dictionary) -> void:
	var prep := maxf(float(p.get("preparo", 0.6)), 0.001)
	var u := clampf(float(p.get("t", 0.0)) / prep, 0.0, 1.0)
	var ativo := bool(p.get("ativo", false))
	if ativo:
		u = 1.0
	var cor := _cor(str(p.get("tipo", "")))
	var pulso := 0.5 + 0.5 * sin(float(p.get("t", 0.0)) * 26.0)
	var cheio := Color(cor.r, cor.g, cor.b, 0.10 + 0.18 * u)
	var borda := Color(cor.r, cor.g, cor.b, 0.9)
	if u > 0.8:
		# perto do fim: pisca em branco (é a hora de sair)
		borda = borda.lerp(Color(1, 1, 1, 1), 0.55 * pulso)
	match str(p.get("forma", "circulo")):
		"circulo":
			_circulo(Vector2(p.get("pos", Vector2.ZERO)), float(p.get("raio", 30.0)),
				u, ativo, cheio, borda, pulso)
		"faixa":
			_faixa(Vector2(p.get("pos", Vector2.ZERO)), Vector2(p.get("dir", Vector2.RIGHT)),
				float(p.get("alcance", 0.0)), float(p.get("largura", 34.0)),
				u, ativo, cheio, borda)
		"linha":
			_linha(Vector2(p.get("pos", Vector2.ZERO)), Vector2(p.get("dir", Vector2.RIGHT)),
				float(p.get("alcance", 0.0)), u, ativo, cheio, borda)


func _circulo(c: Vector2, raio: float, u: float, ativo: bool,
		cheio: Color, borda: Color, pulso: float) -> void:
	draw_circle(c, raio, cheio, true, -1.0, true)
	draw_arc(c, raio, 0.0, TAU, 48, borda, 2.5, true)
	# cruzeta no centro: o "aqui"
	var t := 5.0
	draw_line(c - Vector2(t, 0), c + Vector2(t, 0), borda, 1.5, true)
	draw_line(c - Vector2(0, t), c + Vector2(0, t), borda, 1.5, true)
	if ativo:
		draw_circle(c, raio, Color(1, 1, 1, 0.16), true, -1.0, true)
		return
	# o anel fecha: mostra o tempo que falta
	draw_arc(c, raio * 0.78, -PI / 2.0, -PI / 2.0 + TAU * u, 48, borda, 3.5, true)
	# e o miolo enche até o golpe
	draw_circle(c, raio * u, Color(cheio.r, cheio.g, cheio.b, 0.22), true, -1.0, true)


func _faixa(a: Vector2, dir: Vector2, alcance: float, largura: float, u: float,
		ativo: bool, cheio: Color, borda: Color) -> void:
	if dir.length() < 0.01:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	var perp := dir.orthogonal()
	var meia := maxf(largura, 10.0) * 0.5
	var b := a + dir * alcance
	var pts := PackedVector2Array([
		a + perp * meia, b + perp * meia, b - perp * meia, a - perp * meia,
	])
	draw_colored_polygon(pts, cheio)
	var contorno := PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]])
	draw_polyline(contorno, borda, 2.0, true)
	# a corrida: a linha avança até o fim do preparo
	draw_line(a, a + dir * alcance * u, Color(1, 1, 1, (0.55 if not ativo else 0.75)), 2.0, true)
	# seta de direção
	var fim := a + dir * alcance
	var d := 9.0
	draw_colored_polygon(PackedVector2Array([
		fim + dir * d, fim + perp * d * 0.7, fim - perp * d * 0.7,
	]), borda)
	if ativo:
		draw_line(a, b, Color(1, 1, 1, 0.55), 3.0, true)


func _linha(a: Vector2, dir: Vector2, alcance: float, u: float, ativo: bool,
		cheio: Color, borda: Color) -> void:
	if dir.length() < 0.01:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	var b := a + dir * alcance
	draw_line(a, b, Color(cheio.r, cheio.g, cheio.b, 0.28), 7.0, true)
	draw_line(a, a + dir * alcance * u, borda, 2.5, true)
	var ponta := a + dir * alcance * u
	draw_circle(ponta, 3.0, Color(1, 1, 1, 0.9), true, -1.0, true)
	if ativo:
		draw_line(a, b, Color(1, 1, 1, 0.55), 2.0, true)


func _projetil(e: Dictionary) -> void:
	var p := Vector2(e.get("pos", Vector2.ZERO))
	var d := Vector2(e.get("dir", Vector2.RIGHT))
	if d.length() < 0.01:
		d = Vector2.RIGHT
	d = d.normalized()
	var r := float(e.get("raio", 9.0))
	draw_line(p - d * 18.0, p, Color(0.95, 0.45, 0.92, 0.55), 4.0, true)
	draw_circle(p, r, Color(0.85, 0.34, 0.92, 0.95), true, -1.0, true)
	draw_circle(p, r * 0.42, Color(1, 1, 1, 0.95), true, -1.0, true)
