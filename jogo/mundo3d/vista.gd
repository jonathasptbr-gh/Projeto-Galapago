extends CanvasLayer
## O PALCO 3D: SubViewport com o mundo 3D + a imagem dele na tela, com ou sem
## o Pixel Pass. É um CanvasLayer (`layer = -1` por padrão): a imagem fica
## atrás do canvas normal e não segue a Camera2D de quem a usar.
##
## Contrato:
## - `mundo_3d: Node3D` — a raiz do mundo (dentro do SubViewport, mundo 3D
##   próprio). Ponha aqui a ilha, os atores, o que vier.
## - `camera: Camera3D` (ortográfica, KEEP_HEIGHT), `sol: DirectionalLight3D`
##   (sombra ligada), `ambiente: WorldEnvironment`, `sv: SubViewport`,
##   `imagem: Sprite2D` — expostos para ajuste fino; quem manda neles é a vista.
## - `pixel_pass: bool` (trocável a qualquer hora):
##     ligado  → imagem interna de `altura_interna` px de altura, largura pelo
##               aspecto da tela (par), + `MARGEM` px em volta; sem MSAA; pós
##               pixel_pass.gdshader; ampliada nearest pelo fator
##               tela.y / altura_interna; câmera no `snap` e imagem deslocada
##               de −resto_px × fator (a margem cobre o deslocamento);
##     desligado → SubViewport do tamanho da tela, MSAA 4×, sem pós, câmera suave.
## - `niveis`, `forca_dither`: parâmetros do pós (só no Pixel Pass).
## - `aplicar_camera(cam3d)`: chamar TODO quadro, depois de `cam3d.seguir` /
##   `avancar`; `cam3d` = sim/camera3d.gd. Posiciona a Camera3D, o tamanho
##   ortográfico, near/far, o alcance da sombra e a imagem.
## - `fator() -> float` (px de tela por px interno; 1 sem Pixel Pass) e
##   `tamanho_interno() -> Vector2i` (sem margem).
## - Reage sozinha a `size_changed` da janela.
## "Tela" = retângulo visível do viewport raiz em unidades de canvas (com o
## stretch `canvas_items` do projeto, 720×1280 expandido): sem Pixel Pass a
## imagem 3D é renderizada nesse tamanho, não no da janela física.

const POS := preload("res://jogo/mundo3d/pixel_pass.gdshader")

## px internos de margem em cada borda (o deslocamento de subpixel é ≤ 0,5)
const MARGEM := 2
const COR_CEU := Color("#78b4dc")

@export var altura_interna := 640
@export var pixel_pass := true:
	set(v):
		pixel_pass = v
		if is_inside_tree():
			_reconfigurar()
@export var niveis := 6.0:
	set(v):
		niveis = v
		_pos.set_shader_parameter("niveis", v)
@export var forca_dither := 0.7:
	set(v):
		forca_dither = v
		_pos.set_shader_parameter("forca", v)

var sv: SubViewport
var mundo_3d: Node3D
var camera: Camera3D
var sol: DirectionalLight3D
var ambiente: WorldEnvironment
var imagem: Sprite2D

var _pos: ShaderMaterial
var _tela := Vector2(720, 1280)
var _interno := Vector2i(360, 640)
var _fator := 1.0
var _ultima_cam: RefCounted = null


func _init() -> void:
	layer = -1
	_pos = ShaderMaterial.new()
	_pos.shader = POS
	_pos.set_shader_parameter("niveis", niveis)
	_pos.set_shader_parameter("forca", forca_dither)

	sv = SubViewport.new()
	sv.name = "SubViewport"
	sv.own_world_3d = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	add_child(sv)

	mundo_3d = Node3D.new()
	mundo_3d.name = "Mundo3D"
	sv.add_child(mundo_3d)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = COR_CEU
	# a luz ambiente mora no toon.gdshader (`ambiente`): aqui fica desligada
	env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	# sem reflexo do fundo: o céu claro clareava (e azulava) todo o toon
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	ambiente = WorldEnvironment.new()
	ambiente.environment = env
	sv.add_child(ambiente)

	sol = DirectionalLight3D.new()
	sol.name = "Sol"
	sol.rotation_degrees = Vector3(-52.0, 35.0, 0.0)
	# energia 1 e branco: o brilho das faixas é todo do toon.gdshader
	sol.light_energy = 1.0
	sol.light_color = Color.WHITE
	sol.shadow_enabled = true
	sol.shadow_blur = 0.0
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sv.add_child(sol)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.current = true
	sv.add_child(camera)

	imagem = Sprite2D.new()
	imagem.name = "Imagem"
	imagem.centered = false
	imagem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagem.texture = sv.get_texture()
	add_child(imagem)


func _ready() -> void:
	get_viewport().size_changed.connect(_reconfigurar)
	_reconfigurar()


func fator() -> float:
	return _fator


func tamanho_interno() -> Vector2i:
	return _interno


func _reconfigurar() -> void:
	_tela = get_viewport().get_visible_rect().size
	if pixel_pass:
		_fator = _tela.y / float(altura_interna)
		var w := int(ceil(_tela.x / _fator))
		w += w % 2
		_interno = Vector2i(w, altura_interna)
		sv.size = _interno + Vector2i(2 * MARGEM, 2 * MARGEM)
		sv.msaa_3d = Viewport.MSAA_DISABLED
		imagem.material = _pos
		imagem.scale = Vector2(_fator, _fator)
		_pos.set_shader_parameter("tam", Vector2(sv.size))
	else:
		_fator = 1.0
		_interno = Vector2i(_tela.round())
		sv.size = _interno
		sv.msaa_3d = Viewport.MSAA_4X
		imagem.material = null
		imagem.scale = Vector2.ONE
		imagem.position = Vector2.ZERO
	if _ultima_cam != null:
		aplicar_camera(_ultima_cam)


func aplicar_camera(cam3d: RefCounted) -> void:
	_ultima_cam = cam3d
	var dist: float = cam3d.distancia()
	camera.near = maxf(0.05, dist - 40.0)
	camera.far = dist + 60.0
	sol.directional_shadow_max_distance = camera.far
	if pixel_pass:
		camera.size = cam3d.altura_mundo * float(sv.size.y) / float(altura_interna)
		var s: Dictionary = cam3d.snap(altura_interna)
		camera.transform = s["transform"]
		var resto: Vector2 = s["resto_px"]
		imagem.position = _tela * 0.5 - Vector2(sv.size) * 0.5 * _fator - resto * _fator
		_pos.set_shader_parameter("celula_trama", Vector2(s["celula_trama"]))
	else:
		camera.size = cam3d.altura_mundo
		camera.transform = cam3d.transform_camera()
