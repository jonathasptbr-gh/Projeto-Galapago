extends Node3D
## Só a criatura-base; adversários continuam com o ator provisório.
## Pés em Espaco.ponto(pos_px, h), direção da sim no XZ e salto em unidades 3D.
## O GLB permanece intacto; escala/virada e materiais são locais a esta instância.

const Espaco := preload("res://jogo/mundo3d/espaco.gd")
const Cam3D := preload("res://sim/camera3d.gd")
const Mat := preload("res://jogo/mundo3d/materiais.gd")
const MODELO := preload("res://arte/modelos/Lobo.glb")
# AABB medido no Godot com a escala 0,25: 0,27 × 0,67 × 1,39 unidades.
# Uma célula tem 1 unidade; a pata mais baixa fica a 0,003 do chão.
const ESCALA_MODELO := 0.25
# Distância de CHÃO por ciclo, medida nos pés do próprio clipe (cinemática do
# GLB, 2026-11-28): Walk 0,52 unidade (pé planta 1,03 unidade de modelo em meio
# ciclo), Gallop 0,93. Com a fase presa à distância, o pé não patina nem quando
# o clipe toca mais rápido.
const PASSADA_WALK := 0.52
const PASSADA_GALLOP := 0.93

@export var cor := Color.WHITE

var _modelo: Node3D
var _malha: MeshInstance3D
var _anim: AnimationPlayer
var _bases: Array[Color] = []
var _clipe := ""


func _ready() -> void:
	_modelo = MODELO.instantiate()
	_modelo.name = "Lobo"
	_modelo.scale = Vector3.ONE * ESCALA_MODELO
	# Quaternius aponta para +Z depois da rotação do armature; ator.gd
	# aponta para -Z. A correção fica dentro da cena, não afeta olhar/câmera.
	_modelo.rotation.y = PI
	add_child(_modelo)
	_malha = _modelo.get_node("RootNode/AnimalArmature/Skeleton3D/Wolf")
	_anim = _modelo.get_node("AnimationPlayer")
	for i in _malha.mesh.get_surface_count():
		var original := _malha.mesh.surface_get_material(i) as StandardMaterial3D
		_bases.append(original.albedo_color)
	# As 24 tomadas do arquivo continuam disponíveis; só as versões SEM
	# prefixo AnimalArmature| são acionadas. O loop não edita o GLB.
	for nome in ["Idle", "Walk", "Gallop", "Gallop_Jump"]:
		_anim.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
	pintar(cor)
	_tocar("Idle")


func pintar(nova: Color) -> void:
	cor = nova
	if _malha == null:
		return
	for i in _bases.size():
		# A paleta original de quatro materiais (pelagem clara/escura,
		# olho, focinho) é preservada; só estados especiais aplicam tinta.
		var base := _bases[i]
		var tint := Color(base.r * nova.r, base.g * nova.g, base.b * nova.b)
		_malha.set_surface_override_material(i, Mat.toon(tint))


func atualizar(pos_px: Vector2, h: float, direcao: Vector2, salto := 0.0) -> void:
	position = Espaco.ponto(pos_px, h) + Vector3(0, salto, 0)
	if direcao.length_squared() > 0.000001:
		rotation.y = atan2(-direcao.x, -direcao.y)


## Estado lido da sim, nunca derivado do olhar (que também gira parada).
## Cada quadro avança em distância/PX_POR_UNIDADE/passada ciclos, sem
## dependência do fps: velocidade × duração_do_clipe / passada.
## A MARCHA vem da sim (`corpo.trotando()`): caminhada usa Walk, trote e
## corrida acelerada usam Gallop. Na imobilidade muda para Idle; pulo/ataque
## não recebem a velocidade de andar.
func animar(deslocamento_px: float, delta_s: float, no_ar: bool, atacando: bool, trotando: bool) -> void:
	var nome := "Idle"
	if atacando:
		nome = "Attack"
	elif no_ar:
		nome = "Gallop_Jump"
	elif delta_s > 0.0 and deslocamento_px > 0.01:
		nome = "Gallop" if trotando else "Walk"
	_tocar(nome)
	if nome == "Walk" or nome == "Gallop":
		var passada := PASSADA_WALK if nome == "Walk" else PASSADA_GALLOP
		_anim.speed_scale = (deslocamento_px / Cam3D.PX_POR_UNIDADE / delta_s) * (_anim.get_animation(nome).length / passada)
	else:
		_anim.speed_scale = 1.0


func _tocar(nome: String) -> void:
	if _clipe == nome:
		return
	assert(_anim.has_animation(nome), "clipe ausente: " + nome)
	_anim.play(nome, 0.12)
	_clipe = nome
