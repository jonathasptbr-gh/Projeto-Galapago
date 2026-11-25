extends Node3D
## A ilha em 3D, construída a partir de um `Mundo` (sim/mundo.gd) já montado.
##
## Contrato:
## - `construir(mundo)`: apaga o que havia e cria os filhos
##   `Terreno` (uma ArrayMesh, UMA superfície por cor de terreno — o xadrez de
##   `dados/terrenos.json` vira duas superfícies por terreno), `Casca` (o
##   contorno do terreno, malha própria já inflada), `Agua` (plano no nível 0)
##   e `Objetos` (primitivas low-poly com casca: arvore, bau, rocha e
##   genéricos). Seguro chamar de novo depois de editar o mundo.
## - Espaço: o da câmera (sim/camera3d.gd): 1 unidade = 1 célula = 32 px da
##   sim; a célula (x, y) ocupa x..x+1 em X e y..y+1 em Z; Y para cima.
## - Altura: `ALTURA_NIVEL` unidades por nível de `terrenos.json` (0 mar,
##   1 chão, 2 planalto; rampa 1,5 = bloco de meia altura entre 1 e 2).
##   `altura_3d(niveis)` e `ponto(q_px, niveis)` convertem.
## - Terreno: célula com altura > 0 é um bloco; só se emitem o topo e as
##   paredes que dão para célula mais baixa (fora do mapa = água). Paredes que
##   dão para a água descem até `FUNDO_NIVEIS` (abaixo do plano da água).
## - Casca do terreno: cada parede exposta repetida `CONTORNO_TERRENO` para
##   fora (esticada nas pontas e `CONTORNO_TERRENO_SOBE` acima do topo, para a
##   linha não sair tracejada com ~1 px interno), desenhada só de costas
##   (cull_front): vira a
##   linha atrás da borda do topo quando a borda é silhueta. Bordas de frente
##   (parede virada para a câmera) não ganham linha — a faixa de luz separa.
## - `#` (rocha, não andável) ganha uma pedra low-poly em cima do bloco.
## Fora: subsolo/túneis (`mundo.tuneis`) e células escavadas não são
## desenhados; a água é opaca (o `transparente` de terrenos.json é ignorado).

const Cam := preload("res://sim/camera3d.gd")
const Mat := preload("res://jogo/mundo3d/materiais.gd")

const ALTURA_NIVEL := 0.4
const FUNDO_NIVEIS := -1.0
## quanto a casca do terreno sai da parede (unidades)
const CONTORNO_TERRENO := 0.06
const CONTORNO_TERRENO_SOBE := 0.03
## água além da borda do mapa (unidades), para a vista inclinada não ver o vazio
const MARGEM_AGUA := 80.0
const COR_TRONCO := Color("#6b4a2f")
const COR_COPA := Color("#3f8a3e")
const COR_BAU := Color("#9a6a34")
const COR_BAU_FERRAGEM := Color("#d8b04a")
const COR_ROCHA := Color("#77767e")
const COR_GENERICO := Color("#7f8fa6")

var terreno: MeshInstance3D
var casca: MeshInstance3D
var agua: MeshInstance3D
var objetos: Node3D
## superfícies por cor no último `construir` (diagnóstico)
var n_superficies := 0


static func altura_3d(niveis: float) -> float:
	return niveis * ALTURA_NIVEL


## px de mundo da sim + altura em níveis → ponto 3D
static func ponto(q_px: Vector2, niveis := 0.0) -> Vector3:
	return Cam.para_3d(q_px, altura_3d(niveis))


func construir(mundo: RefCounted) -> void:
	for f in get_children():
		remove_child(f)
		f.queue_free()
	_construir_terreno(mundo)
	_construir_agua(mundo)
	objetos = Node3D.new()
	objetos.name = "Objetos"
	add_child(objetos)
	_construir_objetos(mundo)


# --- terreno -------------------------------------------------------------------

func _construir_terreno(mundo: RefCounted) -> void:
	var por_cor := {}  # html -> SurfaceTool
	var st_casca := SurfaceTool.new()
	st_casca.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tem_casca := false
	var lados: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in mundo.altura_grade:
		for x in mundo.largura:
			var c := Vector2i(x, y)
			var h: float = mundo.altura(c)
			if h <= 0.0:
				continue
			var t: Dictionary = mundo.terreno(c)
			var cores: Array = t.get("cores", ["#808080"])
			var cor_topo := Color(String(cores[(x + y) % cores.size()]))
			var cor_parede := Color(String(cores[0]))
			var topo := altura_3d(h)
			var st := _st(por_cor, cor_topo)
			_quad(st, Vector3(x, topo, y), Vector3(x + 1, topo, y),
				Vector3(x + 1, topo, y + 1), Vector3(x, topo, y + 1), Vector3.UP)
			for d in lados:
				var v := c + d
				var hv: float = mundo.altura(v) if mundo.dentro(v) else 0.0
				if hv >= h:
					continue
				var base := altura_3d(hv) if hv > 0.0 else altura_3d(FUNDO_NIVEIS)
				_parede(_st(por_cor, cor_parede), c, d, base, topo, 0.0)
				_parede(st_casca, c, d, base, topo + CONTORNO_TERRENO_SOBE, CONTORNO_TERRENO)
				tem_casca = true
	var malha := ArrayMesh.new()
	for html in por_cor:
		var st: SurfaceTool = por_cor[html]
		st.commit(malha)
		malha.surface_set_material(malha.get_surface_count() - 1, Mat.toon(Color(String(html))))
	n_superficies = malha.get_surface_count()
	terreno = MeshInstance3D.new()
	terreno.name = "Terreno"
	terreno.mesh = malha
	add_child(terreno)
	casca = MeshInstance3D.new()
	casca.name = "Casca"
	casca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if tem_casca:
		casca.mesh = st_casca.commit()
		casca.material_override = Mat.casca(0.0)
	add_child(casca)


func _st(por_cor: Dictionary, cor: Color) -> SurfaceTool:
	var k := cor.to_html(false)
	if not por_cor.has(k):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		por_cor[k] = st
	return por_cor[k]


## Parede da célula `c` do lado `d` (normal = d no plano XZ), de `base` a
## `topo`; `fora` > 0 afasta a parede para fora e a estica nas pontas.
func _parede(st: SurfaceTool, c: Vector2i, d: Vector2i, base: float, topo: float, fora: float) -> void:
	var centro := Vector3(c.x + 0.5, 0.0, c.y + 0.5)
	var n := Vector3(d.x, 0.0, d.y)
	var lado := Vector3(-d.y, 0.0, d.x) * (0.5 + fora)
	var meio := centro + n * (0.5 + fora)
	var a := meio - lado
	var b := meio + lado
	_quad(st, Vector3(a.x, base, a.z), Vector3(b.x, base, b.z),
		Vector3(b.x, topo, b.z), Vector3(a.x, topo, a.z), n)


## Quad (dois triângulos) com a normal dada; a ordem dos vértices é acertada
## para a face da frente olhar para `n` (o Godot usa sentido horário na frente).
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b
		b = d
		d = t
	st.set_normal(n)
	for p in [a, b, c, a, c, d]:
		st.add_vertex(p)


# --- água ----------------------------------------------------------------------

func _construir_agua(mundo: RefCounted) -> void:
	var cor := Color(String(Array(mundo.legenda.get("~", {}).get("cores", ["#2f6f9f"]))[0]))
	var plano := PlaneMesh.new()
	plano.size = Vector2(mundo.largura + 2.0 * MARGEM_AGUA, mundo.altura_grade + 2.0 * MARGEM_AGUA)
	agua = MeshInstance3D.new()
	agua.name = "Agua"
	agua.mesh = plano
	agua.material_override = Mat.toon(cor)
	agua.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	agua.position = Vector3(mundo.largura * 0.5, 0.0, mundo.altura_grade * 0.5)
	add_child(agua)


# --- objetos -------------------------------------------------------------------

func _construir_objetos(mundo: RefCounted) -> void:
	for o in mundo.objetos:
		var cel := Vector2i(int(o["celula"][0]), int(o["celula"][1]))
		var chao := Vector3(cel.x + 0.5, altura_3d(mundo.altura(cel)), cel.y + 0.5)
		match String(o.get("tipo", "")):
			"arvore":
				_arvore(chao, float(o.get("copa", 40)) / Cam.PX_POR_UNIDADE)
			"bau":
				_bau(chao)
			"rocha":
				_rocha(chao, cel)
			_:
				_peca(BoxMesh.new(), COR_GENERICO, Mat.FORMA_CAIXA, chao + Vector3(0, 0.5, 0), Vector3(0.7, 1.0, 0.7))
	for y in mundo.altura_grade:
		for x in mundo.largura:
			if mundo.celulas[y][x] == "#":
				var c := Vector2i(x, y)
				_rocha(Vector3(x + 0.5, altura_3d(mundo.altura(c)), y + 0.5), c)


func _arvore(chao: Vector3, raio_copa: float) -> void:
	var tronco := CylinderMesh.new()
	tronco.top_radius = 0.12
	tronco.bottom_radius = 0.17
	tronco.height = 0.9
	tronco.radial_segments = 6
	tronco.rings = 1
	_peca(tronco, COR_TRONCO, Mat.FORMA_CILINDRO, chao + Vector3(0, 0.45, 0))
	var copa := SphereMesh.new()
	var r := maxf(raio_copa * 0.75, 0.4)
	copa.radius = r
	copa.height = r * 1.5
	copa.radial_segments = 7
	copa.rings = 3
	_peca(copa, COR_COPA, Mat.FORMA_NORMAL, chao + Vector3(0, 0.8 + r * 0.6, 0))


func _bau(chao: Vector3) -> void:
	_peca(BoxMesh.new(), COR_BAU, Mat.FORMA_CAIXA, chao + Vector3(0, 0.22, 0), Vector3(0.7, 0.44, 0.48))
	_peca(BoxMesh.new(), COR_BAU_FERRAGEM, Mat.FORMA_CAIXA, chao + Vector3(0, 0.3, 0), Vector3(0.74, 0.08, 0.52))


func _rocha(chao: Vector3, c: Vector2i) -> void:
	var m := SphereMesh.new()
	m.radius = 0.42
	m.height = 0.6
	m.radial_segments = 6
	m.rings = 2
	var mi := _peca(m, COR_ROCHA, Mat.FORMA_NORMAL, chao + Vector3(0, 0.2, 0))
	mi.rotation.y = float((c.x * 73 + c.y * 37) % 360) * PI / 180.0


func _peca(malha: PrimitiveMesh, cor: Color, forma: int, pos: Vector3, tam := Vector3.ONE) -> MeshInstance3D:
	if malha is BoxMesh:
		(malha as BoxMesh).size = tam
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = Mat.toon(cor, Mat.CONTORNO, forma)
	mi.position = pos
	objetos.add_child(mi)
	return mi
