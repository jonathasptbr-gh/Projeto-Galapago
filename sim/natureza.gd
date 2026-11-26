extends RefCounted
## MAPA DE TESTES "NATUREZA" — LÓGICA PURA (sem nó, sem desenho).
##
## Uma única fonte para a regra (sim/mundo.gd) e para o desenho
## (jogo/mundo3d/natureza/mapa.gd): o riacho, a trilha, os vaus, as árvores e
## os troncos caídos saem daqui, com semente explícita. O render só enfeita
## (samambaias, capim, pedras pequenas, folhas no chão) sem mudar o que bloqueia.
##
## Espaço do desenho ("local"): metros, x para leste, z para sul, chão andável
## em y = 0. Grade da sim: 1 célula = 1 unidade = 32 px; a célula (cx, cz) cobre
## x ∈ [X0 + cx, X0 + cx + 1] e z ∈ [Z0 + cz, Z0 + cz + 1]. No espaço da câmera
## (sim/camera3d.gd) o mapa local vai deslocado por `origem_3d()`: chão andável
## em y = 0,4 (nível 1 de dados/terrenos.json).
##
## Terrenos usados: "," mata (andável), "p" trilha, ":" clareira de terra fofa
## (escavável), "v" vau de cascalho (andável, atravessa o riacho), "~" água.
## Árvores = objeto "arvore" (o tronco bloqueia a célula); troncos caídos =
## objeto "tronco" com `bloqueia`, um por célula que o tronco ocupa.

const SEMENTE := 20261126
const X0 := -23.0
const Z0 := -39.0
const LARGURA := 46
const ALTURA := 62
## nível da sim do chão andável (o mesmo de "," em dados/terrenos.json)
const NIVEL_CHAO := 1.0
## unidades 3D por nível (o mesmo de jogo/mundo3d/ilha.gd)
const ALTURA_NIVEL := 0.4
## folga além da margem visível do riacho em que a célula ainda é água
const FOLGA_AGUA := 0.25
## meia largura da trilha (unidades) e centros dos vaus (z)
const MEIA_TRILHA := 0.7
const VAUS: Array[float] = [-27.5, -9.5, 9.5]
## meia largura do vau em z (unidades)
const MEIA_VAU := 0.9
## clareira de terra fofa: centro (x, z) e raio
const CLAREIRA := Vector3(-12.0, 0.0, 6.0)
const RAIO_CLAREIRA := 1.7
## onde a criatura começa e onde o adversário passeia (x, z locais, aproximados)
const INICIO := Vector2(0.0, -3.5)
const ADVERSARIO := Vector2(0.0, 3.0)
## troncos caídos: x, z, yaw, escala (comprimento-base 3,7 ao longo de +X local)
const TRONCOS: Array = [[-4.7, 0.8, -0.45, 1.0], [2.5, -9.8, 0.9, 0.82], [-9.8, -13.5, 1.2, 1.2]]
const COMPRIMENTO_TRONCO := 3.7


static func rio_x(z: float) -> float:
	return 1.65 * sin(z * 0.19) + 1.05 * sin(z * 0.38 + 0.5) + 0.7


static func largura_rio(z: float) -> float:
	return 1.18 + 0.22 * sin(z * 0.27 + 0.8)


static func trilha_x(z: float) -> float:
	return rio_x(z) - 3.05 - sin(z * 0.24) * 0.55


## Peso (0..1) de um vau na altura z: 1 no meio da travessia.
static func vau(z: float) -> float:
	var w := 0.0
	for zv in VAUS:
		w = maxf(w, 1.0 - smoothstep(MEIA_VAU * 0.6, MEIA_VAU + 0.3, absf(z - zv)))
	return w


## O ponto local (x, z) é água da regra? (o vau não é)
static func agua(x: float, z: float) -> bool:
	return absf(x - rio_x(z)) < largura_rio(z) + FOLGA_AGUA and vau(z) < 0.5


static func trilha(x: float, z: float) -> bool:
	return absf(x - trilha_x(z)) < MEIA_TRILHA


static func clareira(x: float, z: float) -> bool:
	return Vector2(x - CLAREIRA.x, z - CLAREIRA.z).length() < RAIO_CLAREIRA


## Célula da sim → centro local (x, z).
static func centro_local(c: Vector2i) -> Vector2:
	return Vector2(X0 + c.x + 0.5, Z0 + c.y + 0.5)


## Ponto local (x, z) → célula da sim.
static func celula_local(x: float, z: float) -> Vector2i:
	return Vector2i(floori(x - X0), floori(z - Z0))


## Onde o nó local vai no espaço da câmera (sim/camera3d.gd).
static func origem_3d() -> Vector3:
	return Vector3(-X0, NIVEL_CHAO * ALTURA_NIVEL, -Z0)


## O caractere de terreno da célula.
static func terreno_celula(c: Vector2i) -> String:
	var p := centro_local(c)
	if agua(p.x, p.y):
		return "~"
	if absf(p.x - rio_x(p.y)) < largura_rio(p.y) + FOLGA_AGUA:
		return "v"
	if trilha(p.x, p.y):
		return "p"
	if clareira(p.x, p.y):
		return ":"
	return ","


## Árvores: [{x, z, yaw, escala}] — grade irregular que poupa riacho, trilha,
## vaus, clareira e o começo. A ordem é estável (o render divide em variantes).
static func arvores(semente := SEMENTE) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = semente
	var out: Array = []
	for iz in range(11):
		for ix in range(9):
			var x := -21.0 + ix * 5.1 + r.randf_range(-1.6, 1.6)
			var z := -36.0 + iz * 5.2 + r.randf_range(-1.8, 1.8)
			var yaw := r.randf_range(0.0, TAU)
			var escala := r.randf_range(0.78, 1.20)
			if _livre_para_arvore(x, z):
				out.append({"x": x, "z": z, "yaw": yaw, "escala": escala})
	for extra in [[-6.2, 4.4, 1.5, 1.06], [5.5, -1.5, 2.3, 1.0]]:
		if _livre_para_arvore(extra[0], extra[1]):
			out.append({"x": extra[0], "z": extra[1], "yaw": extra[2], "escala": extra[3]})
	return out


static func _livre_para_arvore(x: float, z: float) -> bool:
	if absf(x - rio_x(z)) < 3.25 or absf(x - trilha_x(z)) < 1.25:
		return false
	if clareira(x, z) or Vector2(x, z).distance_to(_inicio_local()) < 2.0:
		return false
	var c := celula_local(x, z)
	return c.x >= 0 and c.y >= 0 and c.x < LARGURA and c.y < ALTURA


## Células que um tronco caído ocupa (amostrado a cada 0,25 ao longo dele).
static func celulas_tronco(t: Array) -> Array:
	var dir := Vector2(cos(float(t[2])), -sin(float(t[2])))
	var comp := COMPRIMENTO_TRONCO * float(t[3])
	var vistas := {}
	var out: Array = []
	var n := int(ceil(comp / 0.25))
	for i in range(n + 1):
		var p := Vector2(t[0], t[1]) + dir * comp * (float(i) / n)
		var c := celula_local(p.x, p.y)
		if not vistas.has(c):
			vistas[c] = true
			out.append(c)
	return out


static func _inicio_local() -> Vector2:
	return Vector2(trilha_x(INICIO.y), INICIO.y)


## O mapa no formato de dados/mapas/*.json, pronto para sim/mundo.gd.
static func mundo_dict(semente := SEMENTE) -> Dictionary:
	var celulas := PackedStringArray()
	for cz in range(ALTURA):
		var linha := ""
		for cx in range(LARGURA):
			linha += terreno_celula(Vector2i(cx, cz))
		celulas.append(linha)
	var objetos: Array = []
	var ocupadas := {}
	for a in arvores(semente):
		var c := celula_local(a["x"], a["z"])
		if ocupadas.has(c):
			continue
		ocupadas[c] = true
		objetos.append({"tipo": "arvore", "celula": [c.x, c.y], "copa": 46})
	for t in TRONCOS:
		for c in celulas_tronco(t):
			if ocupadas.has(c) or c.x < 0 or c.y < 0 or c.x >= LARGURA or c.y >= ALTURA:
				continue
			ocupadas[c] = true
			objetos.append({"tipo": "tronco", "celula": [c.x, c.y], "bloqueia": true})
	var ini := celula_local(_inicio_local().x, _inicio_local().y)
	var adv := _livre_perto(celulas, ocupadas, celula_local(trilha_x(ADVERSARIO.y) + 2.5, ADVERSARIO.y))
	return {
		"_leia": "Gerado por sim/natureza.gd (mapa de testes NATUREZA); não editar à mão.",
		"celula_px": 32,
		"celulas": Array(celulas),
		"inicio": [ini.x, ini.y],
		"objetos": objetos,
		"adversarios": [{"celula": [adv.x, adv.y], "semente": 7}],
	}


## Primeira célula andável (mata/trilha/clareira) em anéis em volta de `c`.
static func _livre_perto(celulas: PackedStringArray, ocupadas: Dictionary, c: Vector2i) -> Vector2i:
	for raio in range(0, 8):
		for dz in range(-raio, raio + 1):
			for dx in range(-raio, raio + 1):
				var q := c + Vector2i(dx, dz)
				if q.x < 0 or q.y < 0 or q.x >= LARGURA or q.y >= ALTURA or ocupadas.has(q):
					continue
				if celulas[q.y][q.x] in [",", "p", ":"]:
					return q
	return c
