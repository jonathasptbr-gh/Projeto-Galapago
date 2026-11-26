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
## - `pixel_pass: bool` (trocável a qualquer hora; padrão DESLIGADO, o 3D liso):
##     ligado  → imagem interna de `altura_interna` px de altura, largura pelo
##               aspecto da tela (par), + `MARGEM` px em volta; sem MSAA; pós
##               pixel_pass.gdshader; ampliada nearest pelo fator
##               tela.y / altura_interna; câmera no `snap` e imagem deslocada
##               de −resto_px × fator (a margem cobre o deslocamento);
##     desligado → SubViewport do tamanho FÍSICO da janela (`get_window().size`,
##               não o canvas 720×1280 lógico), desenhado reduzido por
##               canvas/físico: 1 px renderizado = 1 px da tela do aparelho.
##               MSAA 4×, sem FXAA (`fxaa_liso`), sem pós, câmera suave.
## - `niveis`, `forca_dither`: parâmetros do pós (só no Pixel Pass).
## - `contorno: MeshInstance3D` — o CONTORNO DE TELA (contorno_tela.gdshader):
##   QuadMesh 2×2 em clip space, filho do SubViewport (mesmo mundo 3D),
##   `extra_cull_margin` máximo, sem sombra; visível só com
##   `Mat.contorno_tela()` (senão a casca antiga desenha a linha). Raio em px
##   renderizados: liso = `espessura_contorno` (px de canvas) × físico/canvas
##   — a mesma espessura na tela em qualquer aparelho; Pixel Pass = 1 px
##   interno, nítido (saturação 1). `limiar_contorno`: diferença de
##   profundidade (unidades de mundo) que dá linha cheia. O mesmo shader
##   soma a linha de VINCO (S7: mudança brusca de orientação, parede×chão,
##   quina até o chão): `limiar_vinco_graus`; saturação 2 no liso, 1 e um
##   lado só (`vinco_um_lado`) no Pixel Pass.
## - `aplicar_camera(cam3d)`: chamar TODO quadro, depois de `cam3d.seguir` /
##   `avancar`; `cam3d` = sim/camera3d.gd. Posiciona a Camera3D, o tamanho
##   ortográfico, near/far justos ao que a vista mostra (a sombra direcional
##   de câmera ortográfica cobre near..far: o Godot IGNORA
##   `directional_shadow_max_distance` em ortográfica) e a imagem.
## - `fator() -> float` (px de canvas por px interno; 1 sem Pixel Pass) e
##   `tamanho_interno() -> Vector2i` (sem margem; px físicos sem Pixel Pass).
## - Reage sozinha a `size_changed` da janela.
## "Tela" = retângulo visível do viewport raiz em unidades de canvas (com o
## stretch `canvas_items` do projeto, 720×1280 expandido).

const POS := preload("res://jogo/mundo3d/pixel_pass.gdshader")
const CONTORNO := preload("res://jogo/mundo3d/contorno_tela.gdshader")
const Mat := preload("res://jogo/mundo3d/materiais.gd")

## px internos de margem em cada borda (o deslocamento de subpixel é ≤ 0,5)
const MARGEM := 2
const COR_CEU := Color("#78b4dc")
## altura (unidades) acima do chão até onde o relevo/objetos podem subir, e
## folgas de near/far: a fatia near..far é o que a sombra cobre (ver aplicar_camera)
const ALTURA_RELEVO := 4.0
const FOLGA_PERTO := 3.0
const FOLGA_LONGE := 4.0

@export var altura_interna := 640
@export var pixel_pass := false:
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
## FXAA no 3D liso: avaliado e DESLIGADO — na resolução física o MSAA 4× já
## alisa as bordas de geometria (contornos, silhuetas) e as faixas do toon têm
## AA analítico no shader; o FXAA borraria os contornos de 3–4 px e custaria
## um passe de tela cheia a 1080×2400.
@export var fxaa_liso := false:
	set(v):
		fxaa_liso = v
		if is_inside_tree():
			_reconfigurar()

## espessura do contorno de tela no liso, em px de CANVAS (720×1280)
@export var espessura_contorno := 4.0:
	set(v):
		espessura_contorno = v
		if is_inside_tree():
			_reconfigurar()
@export var limiar_contorno := 0.25:
	set(v):
		limiar_contorno = v
		_mat_contorno.set_shader_parameter("limiar", v)
		_mat_contorno.set_shader_parameter("limiar_inicio", v * 0.32)
## ângulo (graus) entre as normais que dá a linha de VINCO (S7): acima das
## facetas da copa (~51°) e do tronco (60°)
@export var limiar_vinco_graus := 75.0:
	set(v):
		limiar_vinco_graus = v
		_mat_contorno.set_shader_parameter("limiar_vinco_graus", v)

var sv: SubViewport
var mundo_3d: Node3D
var contorno: MeshInstance3D
var _mat_contorno: ShaderMaterial
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
	# shadow_blur > 0 é OBRIGATÓRIO no Mobile (RD): lá o recuo da sombra é
	# shadow_bias/100 × (2·raio + pancake) × shadow_blur × raio do filtro
	# (2 no soft_low) — com blur 0 o bias vira ZERO e a sombra se acne-ia (as
	# manchas escuras nas copas no Vulkan). O Compatibility não multiplica pelo
	# blur (metade do recuo). 0,06 ⇒ ~0,07 unidade no Mobile (vista alta), sem
	# descolar a sombra do pé; normal_bias em texels do atlas.
	sol.shadow_blur = 1.0
	sol.shadow_bias = 0.06
	sol.shadow_normal_bias = 2.0
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sv.add_child(sol)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.current = true
	sv.add_child(camera)

	_mat_contorno = ShaderMaterial.new()
	_mat_contorno.shader = CONTORNO
	_mat_contorno.set_shader_parameter("limiar", limiar_contorno)
	_mat_contorno.set_shader_parameter("limiar_inicio", limiar_contorno * 0.32)
	_mat_contorno.set_shader_parameter("limiar_vinco_graus", limiar_vinco_graus)
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	contorno = MeshInstance3D.new()
	contorno.name = "ContornoTela"
	contorno.mesh = quad
	contorno.material_override = _mat_contorno
	contorno.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# a CPU não sabe que o vértice já está em clip space: sem isto o quad
	# sai do frustum quando a câmera se afasta da origem
	contorno.extra_cull_margin = 16384.0
	contorno.visible = Mat.contorno_tela()
	sv.add_child(contorno)

	imagem = Sprite2D.new()
	imagem.name = "Imagem"
	imagem.centered = false
	imagem.texture = sv.get_texture()
	add_child(imagem)


func _ready() -> void:
	# o viewport raiz É a janela: um sinal só cobre canvas e tamanho físico
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
		# resolução FÍSICA: canvas_items+expand ⇒ janela = tela × k, k igual
		# nos dois eixos; renderiza k× maior e desenha 1/k (1:1 no pixel físico)
		var fisico := get_window().size
		if fisico.x <= 0 or fisico.y <= 0:
			fisico = Vector2i(_tela.round())
		var k := float(fisico.y) / _tela.y
		_fator = 1.0
		_interno = fisico
		sv.size = fisico
		sv.msaa_3d = Viewport.MSAA_4X
		imagem.material = null
		imagem.scale = Vector2(1.0 / k, 1.0 / k)
		imagem.position = Vector2.ZERO
	contorno.visible = Mat.contorno_tela()
	if pixel_pass:
		_mat_contorno.set_shader_parameter("raio", 1.0)
		_mat_contorno.set_shader_parameter("saturacao", 1.0)
		_mat_contorno.set_shader_parameter("saturacao_vinco", 1.0)
		_mat_contorno.set_shader_parameter("vinco_um_lado", true)
	else:
		var kf := float(sv.size.y) / maxf(_tela.y, 1.0)
		_mat_contorno.set_shader_parameter("raio", maxf(espessura_contorno * kf, 1.0))
		_mat_contorno.set_shader_parameter("saturacao", 3.0)
		_mat_contorno.set_shader_parameter("saturacao_vinco", 2.0)
		_mat_contorno.set_shader_parameter("vinco_um_lado", false)
	sv.screen_space_aa = (Viewport.SCREEN_SPACE_AA_FXAA if fxaa_liso and not pixel_pass
		else Viewport.SCREEN_SPACE_AA_DISABLED)
	# nearest no Pixel Pass (ampliação inteira do pixel art); linear no liso
	# (já 1:1: linear só evita perder linha se o arredondamento sair do grid)
	imagem.texture_filter = (CanvasItem.TEXTURE_FILTER_NEAREST if pixel_pass
		else CanvasItem.TEXTURE_FILTER_LINEAR)
	if _ultima_cam != null:
		aplicar_camera(_ultima_cam)


func aplicar_camera(cam3d: RefCounted) -> void:
	_ultima_cam = cam3d
	var dist: float = cam3d.distancia()
	# near/far JUSTOS ao que a vista mostra: em ortográfica a sombra do sol
	# cobre exatamente a fatia near..far (o max_distance é ignorado), então a
	# fatia enxuta é resolução de sombra. O chão visível vai de
	# −(h/2·cos p + relevo)/sen p a +(h/2·cos p + 0,5)/sen p em torno do foco
	# (h = altura_mundo, p = inclinação); +folgas.
	var sp := maxf(absf(sin(cam3d.pitch)), 0.2)
	var meia: float = cam3d.altura_mundo * 0.5 * absf(cos(cam3d.pitch))
	var perto := (meia + ALTURA_RELEVO) / sp + FOLGA_PERTO
	var longe := (meia + 0.5) / sp
	camera.near = maxf(0.05, dist - perto)
	camera.far = dist + longe + FOLGA_LONGE
	sol.directional_shadow_max_distance = camera.far
	# o esmaecimento da sombra começa em fade_start × far (da câmera): só
	# depois do último chão visível
	sol.directional_shadow_fade_start = clampf((dist + longe + 1.0) / camera.far, 0.8, 0.99)
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
