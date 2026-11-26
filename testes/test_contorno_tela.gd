extends "res://testes/caso.gd"
## O CONTORNO DE TELA (S6): no modo padrão (`Mat.MODO_TELA`) a linha é o pós
## pela profundidade (jogo/mundo3d/contorno_tela.gdshader) num quad de tela
## cheia da vista, e a casca invertida não existe — sem next_pass nos objetos,
## `Casca`/`Aba` do terreno sem malha.

const Mundo := preload("res://sim/mundo.gd")
const Ilha := preload("res://jogo/mundo3d/ilha.gd")
const Mat := preload("res://jogo/mundo3d/materiais.gd")
const Vista := preload("res://jogo/mundo3d/vista.gd")

const TERRENOS := {
	"~": {"altura": 0, "cores": ["#2f6f9f"]},
	",": {"altura": 1, "cores": ["#4f9a45", "#5cab51"]},
	"^": {"altura": 2, "cores": ["#9a9aa2"]},
}


func test_padrao_e_o_contorno_de_tela() -> void:
	igual(Mat.modo_contorno, Mat.MODO_TELA, "contorno de tela é o padrão")
	checar(Mat.contorno_tela(), "contorno_tela() no modo padrão")


func test_sem_casca_no_modo_tela() -> void:
	var objs := [{"tipo": "arvore", "celula": [1, 1], "copa": 46}, {"tipo": "bau", "celula": [2, 1]}]
	var m = Mundo.criar({"celulas": ["~~~~~", "~,,^~", "~~~~~"], "objetos": objs}, TERRENOS)
	var ilha: Node3D = Ilha.new()
	ilha.construir(m)
	checar(ilha.casca != null and ilha.casca.mesh == null, "Casca sem malha")
	checar(ilha.aba != null and ilha.aba.mesh == null, "Aba sem malha")
	checar(ilha.objetos.get_child_count() > 0, "objetos montados")
	for o in ilha.objetos.get_children():
		var mat: ShaderMaterial = (o as MeshInstance3D).material_override
		checar(mat.next_pass == null, "objeto sem casca (next_pass): %s" % o.name)
	ilha.free()
	checar(Mat.toon(Color.RED, Mat.CONTORNO).next_pass == null, "toon com contorno pedido, sem casca")


func test_casca_volta_no_modo_casca() -> void:
	Mat.modo_contorno = Mat.MODO_CASCA
	var mat := Mat.toon(Color.BLUE, Mat.CONTORNO)
	Mat.modo_contorno = Mat.MODO_TELA
	checar(mat.next_pass != null, "modo casca: next_pass de casca")


func test_vista_tem_o_quad_de_tela() -> void:
	var v: CanvasLayer = Vista.new()
	var q: MeshInstance3D = v.contorno
	checar(q != null and q.get_parent() == v.sv, "quad filho do SubViewport (mesmo mundo 3D)")
	checar(q.mesh is QuadMesh, "QuadMesh")
	igual((q.mesh as QuadMesh).size, Vector2(2, 2), "2×2: cobre o clip space")
	checar(q.extra_cull_margin >= 16000.0, "extra_cull_margin grande (não some no frustum)")
	igual(q.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "sem sombra")
	var mat: ShaderMaterial = q.material_override
	igual(mat.shader.resource_path, "res://jogo/mundo3d/contorno_tela.gdshader", "shader do contorno")
	checar(q.visible, "visível no modo tela")
	v.free()


func test_vinco_no_shader_e_na_vista() -> void:
	# S7: o mesmo shader soma a linha de VINCO (orientação que muda bruscamente)
	var v: CanvasLayer = Vista.new()
	var mat: ShaderMaterial = v.contorno.material_override
	var nomes := []
	for u in mat.shader.get_shader_uniform_list():
		nomes.append(String(u["name"]))
	for n in ["limiar_vinco_graus", "banda_vinco_graus", "saturacao_vinco", "vinco_um_lado"]:
		checar(n in nomes, "uniform do vinco: %s" % n)
	igual(mat.get_shader_parameter("limiar_vinco_graus"), v.limiar_vinco_graus, "limiar do vinco ligado à vista")
	checar(v.limiar_vinco_graus > 60.0 and v.limiar_vinco_graus < 90.0,
		"limiar entre as facetas (copa ~51°, tronco 60°) e a quina de caixa (90°)")
	v.limiar_vinco_graus = 80.0
	igual(mat.get_shader_parameter("limiar_vinco_graus"), 80.0, "setter repassa ao shader")
	v.free()
