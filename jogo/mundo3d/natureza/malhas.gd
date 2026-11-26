extends RefCounted
## Biblioteca autoral: unidades em metros, Y para cima, origem no pé.
## Folhas são silhuetas recortadas em geometria opaca (sem alpha/overdraw de cards).
## Nenhuma dependência de render, árvore de cena, sorteio global ou asset externo.

class Oficina:
	extends RefCounted
	var vertices := PackedVector3Array()
	var normais := PackedVector3Array()
	var cores := PackedColorArray()

	func tri(a: Vector3, b: Vector3, c: Vector3, cor: Color, normal := Vector3.ZERO) -> void:
		var cruz := (b - a).cross(c - a)
		var n := normal
		if n == Vector3.ZERO:
			n = cruz.normalized()
		# Godot: frente HORÁRIA, portanto cross·normal deve ser negativo.
		# Preserva a normal física de autoria e ajusta só a ordem dos vértices.
		vertices.append_array(PackedVector3Array([a, c, b] if cruz.dot(n) > 0.0 else [a, b, c]))
		normais.append_array(PackedVector3Array([n, n, n]))
		cores.append_array(PackedColorArray([cor, cor, cor]))

	func ramo(a: Vector3, b: Vector3, raio_a: float, raio_b: float, cor: Color, lados := 7) -> void:
		var eixo := (b - a).normalized()
		var u := eixo.cross(Vector3.FORWARD).normalized()
		if u.length_squared() < 0.1:
			u = eixo.cross(Vector3.RIGHT).normalized()
		var v := eixo.cross(u).normalized()
		for i in range(lados):
			var p := u * cos(TAU * i / lados) + v * sin(TAU * i / lados)
			var q := u * cos(TAU * (i + 1) / lados) + v * sin(TAU * (i + 1) / lados)
			var ca := cor * (0.88 + 0.12 * sin(i * 2.4))
			ca.a = 1.0
			tri(a + p * raio_a, b + p * raio_b, b + q * raio_b, ca, (p + q).normalized())
			tri(a + p * raio_a, b + q * raio_b, a + q * raio_a, ca, (p + q).normalized())
			tri(b, b + q * raio_b, b + p * raio_b, cor, eixo)

	func folha(base: Vector3, ponta: Vector3, largura: float, cor: Color, dobra := 0.07) -> void:
		var eixo := ponta - base
		var lado := eixo.cross(Vector3.UP).normalized() * largura
		if lado.length_squared() < 0.000001:
			lado = Vector3.RIGHT * largura
		var meio := base + eixo * 0.46 + Vector3.UP * dobra
		var esq := base + eixo * 0.42 + lado
		var dir := base + eixo * 0.42 - lado
		tri(base, esq, meio, cor)
		tri(esq, ponta, meio, cor)
		tri(ponta, dir, meio, cor.lightened(0.04))
		tri(dir, base, meio, cor.lightened(0.04))

	func malha() -> ArrayMesh:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normais
		arrays[Mesh.ARRAY_COLOR] = cores
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return m


const NATURAL := preload("res://jogo/mundo3d/natureza/natural.gdshader")
const FOLHA := preload("res://jogo/mundo3d/natureza/folha.gdshader")


## Material novo (não compartilhado): folhas = duas faces + luz que atravessa;
## o resto = sólido de uma face. Os dois aceitam a COPA VAZADA (`usar_foco`).
static func material(folhas := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = FOLHA if folhas else NATURAL
	return m


static func _rng(semente: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = semente
	return r


## `simples`: a mesma silhueta com ~1/4 dos ramúsculos e folhas (árvores de
## moldura, longe da criatura).
static func arvore(semente: int, simples := false) -> Dictionary:
	var r := _rng(semente)
	var lenho := Oficina.new()
	var folhas := Oficina.new()
	var casca := Color("#6e5134")
	var verde := Color("#4fa63a").lerp(Color("#2d8a46"), r.randf())
	var altura := r.randf_range(8.4, 11.8)
	var raio := r.randf_range(0.16, 0.24)
	var pontos: Array[Vector3] = [Vector3.ZERO]
	for i in range(1, 8):
		pontos.append(Vector3(sin(i * 0.66 + semente) * 0.30, altura * i / 7.0,
			cos(i * 0.81 + semente) * 0.23))
		lenho.ramo(pontos[i - 1], pontos[i], raio * (1.0 - (i - 1) * 0.125),
			raio * (1.0 - i * 0.125), casca, 9)
	# Sapopemas pequenas e raízes que realmente se afilam no solo.
	for i in range(6):
		var a := TAU * i / 6.0 + r.randf_range(-0.2, 0.2)
		var pe := Vector3(cos(a), 0.0, sin(a))
		lenho.ramo(pe * 0.08 + Vector3.UP * 0.65, pe * r.randf_range(0.8, 1.4) - Vector3.UP * 0.15,
			raio * 0.72, 0.025, casca.darkened(0.14), 5)
	# Ramos laterais de comprimentos diferentes, bifurcações e ramúsculos.
	for i in range(13):
		var a := i * 2.399 + r.randf_range(-0.25, 0.25)
		var nivel := 2 + i % 5
		var inicio := pontos[nivel].lerp(pontos[nivel + 1], r.randf_range(0.05, 0.80))
		var alcance := r.randf_range(1.5, 2.7) * (1.0 - maxf(0.0, nivel - 4) * 0.16)
		var radial := Vector3(cos(a), 0.0, sin(a))
		var subida := r.randf_range(0.85, 1.6)
		var desvio := Vector3(-sin(a), 0.0, cos(a)) * r.randf_range(-0.24, 0.24)
		var curva_a := inicio + radial * alcance * 0.32 + Vector3.UP * subida * 0.48
		var curva_b := inicio + radial * alcance * 0.68 + Vector3.UP * subida * 0.80 + desvio
		var fim := inicio + radial * alcance + Vector3.UP * subida + desvio * 1.5
		lenho.ramo(inicio, curva_a, raio * 0.43, 0.057, casca, 6)
		lenho.ramo(curva_a, curva_b, 0.057, 0.034, casca, 6)
		lenho.ramo(curva_b, fim, 0.034, 0.010, casca, 5)
		# Ramúsculos também junto às bifurcações: massas foliares irregulares,
		# não uma única estrela vazia na ponta de cada galho.
		for j in range(2 if simples else 5):
			var giro := a + (j - 2) * 0.63 + (0.63 if simples else 0.0) + r.randf_range(-0.3, 0.3)
			var broto := curva_a.lerp(fim, 0.14 + j * 0.20)
			var direcao := Vector3(cos(giro), r.randf_range(0.10, 0.56), sin(giro))
			var ponta := broto + direcao * r.randf_range(0.75, 1.3)
			lenho.ramo(broto, ponta, 0.019, 0.004, casca, 4)
			for k in range(8 if simples else 12):
				var t := 0.04 + k * (0.12 if simples else 0.081)
				var origem := broto.lerp(ponta, t)
				var ang := giro + (1.0 if k % 2 == 0 else -1.0) * r.randf_range(0.65, 1.8)
				var tamanho := r.randf_range(0.28, 0.50)
				var dest := origem + Vector3(cos(ang) * tamanho, r.randf_range(-0.16, 0.19), sin(ang) * tamanho)
				var esc := 1.35 if simples else 1.0
				folhas.folha(origem, origem + (dest - origem) * esc, tamanho * 0.32 * esc, verde.lightened(r.randf_range(0.0, 0.15)), 0.035)
	# Ponteiro vivo fecha a silhueta no alto em vez de terminar em estaca nua.
	for j in range(3):
		var ang := j * 2.399 + r.randf()
		var base := pontos[6].lerp(pontos[7], 0.4 + j * 0.25)
		var ponta := base + Vector3(cos(ang), 0.6, sin(ang)) * 0.7
		lenho.ramo(base, ponta, 0.024, 0.005, casca, 4)
		for k in range(12):
			var origem := base.lerp(ponta, k / 12.0)
			var lado := ang + (1.2 if k % 2 == 0 else -1.2)
			folhas.folha(origem, origem + Vector3(cos(lado) * 0.4, 0.10, sin(lado) * 0.4),
				0.12, verde.lightened(0.12), 0.035)
	return {"madeira": lenho.malha(), "folhas": folhas.malha()}


static func samambaia(semente: int) -> ArrayMesh:
	var r := _rng(semente)
	var o := Oficina.new()
	for i in range(8):
		var ang := TAU * i / 8.0 + r.randf_range(-0.18, 0.18)
		var radial := Vector3(cos(ang), 0.0, sin(ang))
		var lateral := Vector3(-sin(ang), 0.0, cos(ang))
		var comprimento := r.randf_range(0.8, 1.3)
		var anterior := Vector3(0.0, 0.06, 0.0)
		for j in range(1, 11):
			var t := j / 10.0
			var p := radial * comprimento * t + Vector3.UP * (0.07 + sin(t * 2.3) * comprimento * 0.55)
			# Ráquis fina em fita de 2 triângulos: o volume vem dos folíolos.
			var lado_haste := lateral * (0.007 * (1.05 - t))
			o.tri(anterior - lado_haste, p - lado_haste, p + lado_haste, Color("#5c9a3c"))
			o.tri(anterior - lado_haste, p + lado_haste, anterior + lado_haste, Color("#5c9a3c"))
			var tamanho := sin(t * PI) * comprimento * 0.25 + 0.025
			for lado in [-1.0, 1.0]:
				var dest: Vector3 = p + lateral * lado * tamanho + radial * 0.10 - Vector3.UP * tamanho * 0.13
				o.folha(p, dest, tamanho * 0.16, Color("#3f9a3a").lightened(t * 0.13), 0.015)
			anterior = p
	return o.malha()


static func sub_bosque(semente: int) -> ArrayMesh:
	var r := _rng(semente)
	var o := Oficina.new()
	for i in range(7):
		var a := TAU * i / 7.0 + r.randf_range(-0.3, 0.3)
		var altura := r.randf_range(0.45, 1.2)
		var p := Vector3(cos(a) * 0.15, altura * 0.72, sin(a) * 0.15)
		o.ramo(Vector3.ZERO, p, 0.012, 0.005, Color("#5f7a3c"), 3)
		o.folha(p * 0.55, p + Vector3(cos(a) * 0.53, altura * 0.2, sin(a) * 0.53),
			0.14, Color("#2c8a50").lightened(r.randf_range(0.0, 0.12)), 0.06)
		o.folha(p * 0.8, p + Vector3(-sin(a) * 0.4, -0.1, cos(a) * 0.4),
			0.12, Color("#3a8f4a"), 0.04)
	return o.malha()


static func capim(semente: int) -> ArrayMesh:
	var r := _rng(semente)
	var o := Oficina.new()
	for i in range(11):
		var a := r.randf_range(0.0, TAU)
		var p := Vector3(r.randf_range(-0.18, 0.18), 0.015, r.randf_range(-0.18, 0.18))
		var h := r.randf_range(0.15, 0.42)
		o.folha(p, p + Vector3(cos(a) * h * 0.65, h, sin(a) * h * 0.65),
			0.022, Color("#8fae48").lerp(Color("#4f8a36"), r.randf()), 0.01)
	return o.malha()


static func rocha(semente: int) -> ArrayMesh:
	var r := _rng(semente)
	var o := Oficina.new()
	var aneis: Array[PackedVector3Array] = []
	for j in range(3):
		var anel := PackedVector3Array()
		for i in range(8):
			var a := TAU * i / 8.0
			var raio := r.randf_range(0.75, 1.04) * (0.68 if j == 2 else 1.0)
			anel.append(Vector3(cos(a) * raio, j * 0.33 + r.randf_range(-0.07, 0.07), sin(a) * raio * 0.72))
		aneis.append(anel)
	for i in range(8):
		var n := (i + 1) % 8
		for j in range(2):
			var cor := Color("#7f8077").lerp(Color("#8f8c80"), r.randf() * 0.5)
			if j == 1 and i % 3 != 0:
				cor = cor.lerp(Color("#4f9a3c"), 0.40)
			o.tri(aneis[j][i], aneis[j + 1][i], aneis[j + 1][n], cor)
			o.tri(aneis[j][i], aneis[j + 1][n], aneis[j][n], cor)
		o.tri(aneis[2][i], Vector3(0.05, 0.78, 0.0), aneis[2][n], Color("#87897d"))
	return o.malha()


static func tronco(semente: int) -> ArrayMesh:
	var r := _rng(semente)
	var o := Oficina.new()
	var fim := Vector3(3.7, 0.22, 0.14)
	o.ramo(Vector3(0.0, 0.24, 0.0), fim, 0.27, 0.19, Color("#5e4630"), 11)
	# Cerne claro nos cortes e lascas, musgo geométrico na face de cima.
	o.ramo(fim, fim + Vector3(0.014, 0.0, 0.0), 0.154, 0.15, Color("#c4a477"), 11)
	for i in range(4):
		var p := Vector3(0.6 + i * 0.72, 0.35, 0.04)
		o.ramo(p, p + Vector3(0.22, r.randf_range(0.3, 0.6), -0.31), 0.07, 0.017, Color("#6a5036"), 5)
	for i in range(24):
		var p := Vector3(r.randf_range(0.1, 3.5), 0.49, r.randf_range(-0.09, 0.12))
		o.folha(p, p + Vector3(0.19, 0.015, 0.07), 0.08, Color("#5aa23e"), 0.01)
	return o.malha()
