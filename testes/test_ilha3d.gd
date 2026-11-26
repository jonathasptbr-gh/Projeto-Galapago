extends "res://testes/caso.gd"
## Fumaça do construtor da ilha 3D (jogo/mundo3d/ilha.gd): monta sem nó na
## árvore, a partir de mapas pequenos, e confere superfícies, casca e objetos.
## A casca só existe no modo casca (reserva; `Mat.modo_contorno`): os testes
## dela forçam o modo e o devolvem.

const Mundo := preload("res://sim/mundo.gd")
const Ilha := preload("res://jogo/mundo3d/ilha.gd")
const Mat := preload("res://jogo/mundo3d/materiais.gd")

const TERRENOS := {
	"~": {"altura": 0, "cores": ["#2f6f9f"]},
	",": {"altura": 1, "cores": ["#4f9a45", "#5cab51"]},
	"^": {"altura": 2, "cores": ["#9a9aa2"]},
	"#": {"altura": 1, "cores": ["#5b5b62"]},
}


func _ilha(celulas: Array, objetos := [], modo := Mat.MODO_CASCA) -> Node3D:
	var antes := Mat.modo_contorno
	Mat.modo_contorno = modo
	var m = Mundo.criar({"celulas": celulas, "objetos": objetos}, TERRENOS)
	var ilha: Node3D = Ilha.new()
	ilha.construir(m)
	Mat.modo_contorno = antes
	return ilha


func _vertices(mi: MeshInstance3D) -> int:
	var total := 0
	for s in mi.mesh.get_surface_count():
		total += PackedVector3Array(mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]).size()
	return total


func test_celula_isolada_tem_topo_e_quatro_paredes() -> void:
	var ilha := _ilha(["~~~", "~,~", "~~~"])
	igual(ilha.n_superficies, 1, "topo de (1,1) e paredes usam a cor 0 do xadrez")
	igual(_vertices(ilha.terreno), 6 * 5, "1 topo + 4 paredes, 6 vértices cada")
	igual(_vertices(ilha.casca), 6 * 4, "casca: as 4 paredes expostas")
	igual(ilha.objetos.get_child_count(), 0, "sem objetos")
	ilha.free()


func test_vizinho_igual_nao_tem_parede_e_degrau_tem() -> void:
	# duas células de chão lado a lado + uma de planalto: 3 topos;
	# paredes: chão esq (N,S,O) + chão dir (N,S) + planalto (N,S,L,O→chão)
	var ilha := _ilha(["~~~~~", "~,,^~", "~~~~~"])
	igual(_vertices(ilha.terreno), 6 * (3 + 3 + 2 + 4), "topos + paredes expostas")
	igual(_vertices(ilha.casca), 6 * (3 + 2 + 4), "casca só nas paredes expostas")
	ilha.free()


func test_objetos_e_rocha_de_terreno() -> void:
	var objs := [{"tipo": "arvore", "celula": [1, 1], "copa": 46}, {"tipo": "bau", "celula": [2, 1]},
		{"tipo": "estacao", "celula": [3, 1]}]
	var ilha := _ilha(["~~~~~~", "~,,,#~", "~~~~~~"], objs)
	# árvore = tronco + copa; baú = caixa + ferragem; genérico = 1; '#' = 1 pedra
	igual(ilha.objetos.get_child_count(), 2 + 2 + 1 + 1, "peças de objeto")
	var copa: MeshInstance3D = ilha.objetos.get_child(1)
	checar(copa.position.y > Ilha.ALTURA_NIVEL, "copa acima do chão")
	ilha.free()


func test_ponto_converte_px_e_niveis() -> void:
	var p: Vector3 = Ilha.ponto(Vector2(48, 80), 2.0)
	checar(p.is_equal_approx(Vector3(1.5, 2.0 * Ilha.ALTURA_NIVEL, 2.5)), "ponto: %s" % p)
