extends Node3D
## Mata úmida piloto independente do jogo. Reconstrução idempotente e seed fixa.
## MultiMeshes por família/variante: não há um nó por planta, folha ou árvore.
## Terreno contínuo, canal sinuoso rebaixado, trilha na margem oeste.

const Biblioteca := preload("res://jogo/mundo3d/natureza/malhas.gd")
const SEMENTE := 20261126
const LIMITE_X := 23.0
const Z_INICIO := -39.0
const Z_FIM := 23.0
const PASSO := 0.7
const AGUA_Y := -0.12

var estatisticas: Dictionary = {}
var lotes: Array[MultiMeshInstance3D] = []


static func rio_x(z: float) -> float:
	return 1.65 * sin(z * 0.19) + 1.05 * sin(z * 0.38 + 0.5) + 0.7


static func largura_rio(z: float) -> float:
	return 1.18 + 0.22 * sin(z * 0.27 + 0.8)


static func trilha_x(z: float) -> float:
	return rio_x(z) - 3.05 - sin(z * 0.24) * 0.55


static func altura(x: float, z: float) -> float:
	var d := absf(x - rio_x(z)) - largura_rio(z)
	var margem := smoothstep(-0.38, 1.6, d)
	var relevo := sin(x * 0.29 + z * 0.17) * 0.19 + sin(z * 0.63 - x * 0.13) * 0.09
	return lerpf(-0.48, 0.30 + relevo, margem)


static func ponto(x: float, z: float) -> Vector3:
	return Vector3(x, altura(x, z), z)


func construir(semente := SEMENTE) -> void:
	for filho in get_children():
		filho.free()
	lotes.clear()
	estatisticas = {"semente": semente, "instancias": 0, "lotes": 0, "arvores": 0,
		"triangulos_instanciados": 0, "vertices_armazenados": 0}
	var r := RandomNumberGenerator.new()
	r.seed = semente
	_terreno()
	_agua()
	var casca := Biblioteca.material()
	var folha := Biblioteca.material(true)
	# Estrato arbóreo: espaçamento irregular, tronco esguio, clareira não invadida.
	var posicoes: Array[Transform3D] = []
	for iz in range(11):
		for ix in range(9):
			var x := -21.0 + ix * 5.1 + r.randf_range(-1.6, 1.6)
			var z := -36.0 + iz * 5.2 + r.randf_range(-1.8, 1.8)
			if absf(x - rio_x(z)) < 3.25 or absf(x - trilha_x(z)) < 1.25:
				continue
			posicoes.append(_transforme(ponto(x, z) - Vector3.UP * 0.08, r.randf_range(0.0, TAU),
				Vector3.ONE * r.randf_range(0.78, 1.20)))
	# Árvores de primeiro plano enquadram o passeio sem formar uma parede frontal.
	posicoes.append(_transforme(ponto(-6.2, 4.4) - Vector3.UP * 0.08, 1.5, Vector3.ONE * 1.06))
	posicoes.append(_transforme(ponto(5.5, -1.5) - Vector3.UP * 0.08, 2.3, Vector3.ONE))
	estatisticas["arvores"] = posicoes.size()
	for variante in range(4):
		var arv: Dictionary = Biblioteca.arvore(semente + variante * 101)
		var ts: Array[Transform3D] = []
		for i in range(variante, posicoes.size(), 4):
			ts.append(posicoes[i])
		_lote("Troncos_%d" % variante, arv["madeira"], ts, casca, r)
		_lote("Folhas_%d" % variante, arv["folhas"], ts, folha, r)
	# Samambaias preferem margem; arbustos preenchem os espaços em manchas.
	for variante in range(3):
		var samambaias: Array[Transform3D] = []
		var arbustos: Array[Transform3D] = []
		var capins: Array[Transform3D] = []
		for i in range(49):
			var z := r.randf_range(-31.0, 17.0)
			var lado := -1.0 if i % 2 == 0 else 1.0
			var x := rio_x(z) + lado * r.randf_range(1.9, 8.0)
			if absf(x - trilha_x(z)) < 0.85:
				continue
			samambaias.append(_transforme(ponto(x, z), r.randf_range(0.0, TAU),
				Vector3.ONE * r.randf_range(0.55, 1.13)))
		for i in range(95):
			var x := r.randf_range(-21.0, 21.0)
			var z := r.randf_range(-37.0, 20.0)
			if not _vegetavel(x, z):
				continue
			arbustos.append(_transforme(ponto(x, z), r.randf_range(0.0, TAU),
				Vector3.ONE * r.randf_range(0.55, 1.30)))
		for i in range(270):
			var x := r.randf_range(-22.0, 22.0)
			var z := r.randf_range(-38.0, 22.0)
			if not _vegetavel(x, z):
				continue
			capins.append(_transforme(ponto(x, z), r.randf_range(0.0, TAU),
				Vector3.ONE * r.randf_range(0.7, 1.4)))
		_lote("Samambaias_%d" % variante, Biblioteca.samambaia(semente + variante), samambaias, folha, r)
		_lote("Sub_bosque_%d" % variante, Biblioteca.sub_bosque(semente + variante), arbustos, folha, r)
		_lote("Gramineas_%d" % variante, Biblioteca.capim(semente + variante), capins, folha, r, false)
	# Pedras irregulares nos meandros, seixos emergentes; nenhum bloco urbano.
	for variante in range(3):
		var pedras: Array[Transform3D] = []
		for i in range(45):
			var z := r.randf_range(-35.0, 20.0)
			var lado := -1.0 if i % 2 == 0 else 1.0
			var x := rio_x(z) + lado * r.randf_range(0.85, 2.0)
			var escala := r.randf_range(0.18, 0.58)
			pedras.append(_transforme(ponto(x, z) - Vector3.UP * 0.03, r.randf_range(0.0, TAU),
				Vector3(escala * 1.2, escala, escala)))
		_lote("Rochas_%d" % variante, Biblioteca.rocha(semente + variante), pedras, casca, r)
	var troncos: Array[Transform3D] = [
		_transforme(ponto(-4.7, 0.8), -0.45, Vector3.ONE),
		_transforme(ponto(2.5, -9.8), 0.9, Vector3.ONE * 0.82),
		_transforme(ponto(-9.8, -13.5), 1.2, Vector3.ONE * 1.2)]
	_lote("Troncos_caidos", Biblioteca.tronco(semente), troncos, casca, r)
	_serrapilheira(r)
	estatisticas["lotes"] = lotes.size()


static func _vegetavel(x: float, z: float) -> bool:
	return absf(x - rio_x(z)) > largura_rio(z) + 0.7 and absf(x - trilha_x(z)) > 0.8


static func _transforme(p: Vector3, yaw: float, escala: Vector3) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(escala), p)


func _lote(nome: String, m: ArrayMesh, ts: Array[Transform3D], mat: Material,
		r: RandomNumberGenerator, sombra := true) -> void:
	if ts.is_empty():
		return
	m.surface_set_material(0, mat)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = m
	multi.instance_count = ts.size()
	for i in range(ts.size()):
		multi.set_instance_transform(i, ts[i])
		var tom := r.randf_range(0.84, 1.12)
		multi.set_instance_color(i, Color(tom, tom, tom, 1.0))
	var no := MultiMeshInstance3D.new()
	no.name = nome
	no.multimesh = multi
	if not sombra:
		no.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(no)
	lotes.append(no)
	var nv := m.surface_get_array_len(0)
	estatisticas["instancias"] += ts.size()
	estatisticas["vertices_armazenados"] += nv
	estatisticas["triangulos_instanciados"] += nv / 3 * ts.size()


func _unica(nome: String, o: RefCounted, mat: Material) -> void:
	var m: ArrayMesh = o.malha()
	m.surface_set_material(0, mat)
	var no := MeshInstance3D.new()
	no.name = nome
	no.mesh = m
	add_child(no)
	var nv := m.surface_get_array_len(0)
	estatisticas["vertices_armazenados"] += nv
	estatisticas["triangulos_instanciados"] += nv / 3


static func _cor_chao(x: float, z: float) -> Color:
	var ruido := clampf(0.5 + sin(x * 0.65 + sin(z * 0.31)) * 0.26 + cos(z * 0.59 - x * 0.23) * 0.20, 0.0, 1.0)
	var terra := Color("#635c43").lerp(Color("#3c4931"), ruido)
	var caminho := 1.0 - smoothstep(0.35, 1.15, absf(x - trilha_x(z)))
	terra = terra.lerp(Color("#807359"), caminho * 0.85)
	var margem := 1.0 - smoothstep(0.1, 1.15, absf(absf(x - rio_x(z)) - largura_rio(z)))
	return terra.lerp(Color("#484b3c"), margem * 0.65)


static func _normal_chao(x: float, z: float) -> Vector3:
	return Vector3(altura(x - 0.06, z) - altura(x + 0.06, z), 0.12,
		altura(x, z - 0.06) - altura(x, z + 0.06)).normalized()


func _terreno() -> void:
	var o := Biblioteca.Oficina.new()
	var nx := int(ceil(LIMITE_X * 2.0 / PASSO))
	var nz := int(ceil((Z_FIM - Z_INICIO) / PASSO))
	for iz in range(nz):
		for ix in range(nx):
			var x := -LIMITE_X + ix * PASSO
			var z := Z_INICIO + iz * PASSO
			var a := ponto(x, z)
			var b := ponto(x + PASSO, z)
			var c := ponto(x, z + PASSO)
			var d := ponto(x + PASSO, z + PASSO)
			# Cor/normal por vértice compartilhado: não cria xadrez de facetas.
			for p in [a, b, c, b, d, c]:
				o.vertices.append(p)
				o.normais.append(_normal_chao(p.x, p.z))
				o.cores.append(_cor_chao(p.x, p.z))
	_unica("Solo_continuo", o, Biblioteca.material())


func _agua() -> void:
	var o := Biblioteca.Oficina.new()
	for i in range(124):
		var z := Z_INICIO + i * 0.5
		var z2 := z + 0.5
		for j in range(6):
			var u := -1.0 + j / 3.0
			var v := u + 1.0 / 3.0
			var a := Vector3(rio_x(z) + largura_rio(z) * u, AGUA_Y, z)
			var b := Vector3(rio_x(z) + largura_rio(z) * v, AGUA_Y, z)
			var c := Vector3(rio_x(z2) + largura_rio(z2) * u, AGUA_Y, z2)
			var d := Vector3(rio_x(z2) + largura_rio(z2) * v, AGUA_Y, z2)
			var cor := Color("#436863").lerp(Color("#687b70"), absf(u) * 0.45 + sin(z * 0.75) * 0.08)
			o.tri(a, c, b, cor)
			o.tri(b, c, d, cor)
	var m := Biblioteca.material()
	m.roughness = 0.28
	m.metallic_specular = 0.65
	_unica("Riacho", o, m)
	# Pequenos filetes opacos: movimento sugerido, sem passe transparente ou SSR.
	var reflexos := Biblioteca.Oficina.new()
	for i in range(160):
		var z := Z_INICIO + i * 0.38
		var x := rio_x(z) + sin(i * 4.3) * largura_rio(z) * 0.78
		var p := Vector3(x, AGUA_Y + 0.008, z)
		var cor := Color("#91a89a").darkened((sin(i * 1.7) + 1.0) * 0.11)
		reflexos.tri(p, p + Vector3(0.10, 0.0, 0.19), p + Vector3(0.018, 0.0, 0.62), cor, Vector3.UP)
	_unica("Filetes_correnteza", reflexos, Biblioteca.material())


func _serrapilheira(r: RandomNumberGenerator) -> void:
	var o := Biblioteca.Oficina.new()
	for i in range(1500):
		var x := r.randf_range(-16.0, 16.0)
		var z := r.randf_range(-30.0, 18.0)
		if absf(x - rio_x(z)) < largura_rio(z) + 0.3:
			continue
		var p := ponto(x, z) + Vector3.UP * 0.02
		var a := r.randf_range(0.0, TAU)
		var dest := p + Vector3(cos(a) * 0.13, 0.015, sin(a) * 0.13)
		o.folha(p, dest, 0.036, Color("#7b6948").lerp(Color("#4b4d32"), r.randf()), 0.012)
	_unica("Folhas_no_solo", o, Biblioteca.material())
