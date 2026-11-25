extends Node3D
## Ator PROVISÓRIO em 3D: corpo (cápsula) + cabeça (esfera) + focinho (cone)
## apontando a direção, todos toon com casca. Fica no lugar da criatura e dos
## adversários até a pele 3D de verdade chegar.
##
## Contrato:
## - `cor` (antes de entrar na árvore, ou `pintar(cor)` depois) e `escala`
##   (1 = cabe numa célula: ~0,9 unidade de altura).
## - `atualizar(pos_px, h, direcao, salto := 0.0)`:
##   `pos_px` px de mundo da sim (os pés); `h` altura do chão em NÍVEIS (o
##   mesmo número de `mundo.altura(c)`); `direcao` no plano da sim (x direita,
##   y baixo/sul) — vetor nulo mantém o olhar anterior; `salto` elevação extra
##   em UNIDADES 3D (0 = no chão).
## - Origem do nó = pés; frente local = -Z (o focinho), girado em Y.

const Ilha := preload("res://jogo/mundo3d/ilha.gd")
const Mat := preload("res://jogo/mundo3d/materiais.gd")

@export var cor := Color("#e07a3a")
@export var escala := 1.0

var _corpo: MeshInstance3D
var _cabeca: MeshInstance3D
var _focinho: MeshInstance3D


func _ready() -> void:
	var corpo := CapsuleMesh.new()
	corpo.radius = 0.2
	corpo.height = 0.62
	corpo.radial_segments = 10
	corpo.rings = 3
	_corpo = _parte(corpo, Vector3(0, 0.31, 0))
	var cabeca := SphereMesh.new()
	cabeca.radius = 0.17
	cabeca.height = 0.34
	cabeca.radial_segments = 10
	cabeca.rings = 5
	_cabeca = _parte(cabeca, Vector3(0, 0.72, -0.04))
	var focinho := CylinderMesh.new()
	focinho.top_radius = 0.0
	focinho.bottom_radius = 0.09
	focinho.height = 0.22
	focinho.radial_segments = 8
	focinho.rings = 1
	_focinho = _parte(focinho, Vector3(0, 0.7, -0.24))
	_focinho.rotation.x = -PI * 0.5  # ponta do cone (+Y) vira -Z (frente)
	scale = Vector3.ONE * escala
	pintar(cor)


func _parte(malha: PrimitiveMesh, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.position = pos
	add_child(mi)
	return mi


func pintar(nova: Color) -> void:
	cor = nova
	if _corpo == null:
		return
	_corpo.material_override = Mat.toon(cor, Mat.CONTORNO, Mat.FORMA_NORMAL)
	_cabeca.material_override = Mat.toon(cor.lightened(0.15), Mat.CONTORNO, Mat.FORMA_NORMAL)
	_focinho.material_override = Mat.toon(cor.darkened(0.25), Mat.CONTORNO * 0.6, Mat.FORMA_NORMAL)


func atualizar(pos_px: Vector2, h: float, direcao: Vector2, salto := 0.0) -> void:
	position = Ilha.ponto(pos_px, h) + Vector3(0, salto, 0)
	if direcao.length_squared() > 0.000001:
		# frente local -Z deve apontar para (direcao.x, 0, direcao.y)
		rotation.y = atan2(-direcao.x, -direcao.y)
