extends "res://testes/caso.gd"
## A ABA do contorno do terreno (jogo/mundo3d/ilha.gd, nó `Aba`): 6 vértices por
## parede exposta, de largura ZERO na malha (o casca.gdshader, forma 3, abre os
## vértices de fora — UV.x = 1 — pela NORMAL), na altura topo + SOBE.

const Mundo := preload("res://sim/mundo.gd")
const Ilha := preload("res://jogo/mundo3d/ilha.gd")
const Mat := preload("res://jogo/mundo3d/materiais.gd")

const TERRENOS := {
	"~": {"altura": 0, "cores": ["#2f6f9f"]},
	",": {"altura": 1, "cores": ["#4f9a45", "#5cab51"]},
	"^": {"altura": 2, "cores": ["#9a9aa2"]},
}


## a aba só existe no modo casca (reserva): força o modo e o devolve
func _ilha(celulas: Array) -> Node3D:
	var antes := Mat.modo_contorno
	Mat.modo_contorno = Mat.MODO_CASCA
	var m = Mundo.criar({"celulas": celulas, "objetos": []}, TERRENOS)
	var ilha: Node3D = Ilha.new()
	ilha.construir(m)
	Mat.modo_contorno = antes
	return ilha


func test_aba_uma_por_parede_exposta() -> void:
	var ilha := _ilha(["~~~~~", "~,,^~", "~~~~~"])
	var a: Array = ilha.aba.mesh.surface_get_arrays(0)
	igual(PackedVector3Array(a[Mesh.ARRAY_VERTEX]).size(), 6 * (3 + 2 + 4), "aba só nas paredes expostas")
	igual(ilha.aba.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "aba não projeta sombra")
	var mat: ShaderMaterial = ilha.aba.material_override
	igual(int(mat.get_shader_parameter("forma")), Mat.FORMA_TERRENO, "material da casca do terreno")
	ilha.free()


func test_aba_tem_largura_zero_e_marca_os_de_fora() -> void:
	var ilha := _ilha(["~~~", "~,~", "~~~"])
	var a: Array = ilha.aba.mesh.surface_get_arrays(0)
	var vs := PackedVector3Array(a[Mesh.ARRAY_VERTEX])
	var uvs := PackedVector2Array(a[Mesh.ARRAY_TEX_UV])
	var ns := PackedVector3Array(a[Mesh.ARRAY_NORMAL])
	var y := Ilha.altura_3d(1.0) + Ilha.CONTORNO_TERRENO_SOBE
	var fora := 0
	for i in vs.size():
		perto(vs[i].y, y, 0.0001, "aba na altura do topo + SOBE")
		perto(absf(ns[i].y), 0.0, 0.0001, "normal = a da parede (horizontal)")
		# na malha todo vértice fica na linha da parede: x ou z em 1 ou 2
		var d := Vector3(ns[i].x, 0, ns[i].z)
		var linha := Vector3(1.5, 0, 1.5) + d * 0.5
		perto(absf((vs[i] - linha).dot(d)), 0.0, 0.0001, "largura zero na malha")
		if uvs[i].x > 0.5:
			fora += 1
	igual(fora, 4 * 3, "3 vértices de fora por quad (2 triângulos)")
	ilha.free()
