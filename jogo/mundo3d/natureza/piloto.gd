extends Node2D
## Ensaio visual isolado, sem sim, rig, HUD ou controles do jogo.
## Abrir res://jogo/mundo3d/natureza/piloto.tscn; 720x1280, 3D liso.
## --pixel: pós opcional; --vista-geral: ortográfica jogável, alta/3-4;
## --detalhe: perspectiva próxima ao rio; --verso: margem oposta.
## --demo não anima nem gira a câmera: quadros comparáveis de seed fixa.

const Vista := preload("res://jogo/mundo3d/vista.gd")
const Mapa := preload("res://jogo/mundo3d/natureza/mapa.gd")

var vista: CanvasLayer
var mapa: Node3D


static func configuracao(args: PackedStringArray) -> Dictionary:
	if "--vista-geral" in args:
		return {"posicao": Vector3(14.0, 23.0, 22.0), "foco": Vector3(0.0, 1.0, -5.0),
			"ortografica": true, "tamanho": 32.0, "nome": "geral"}
	if "--detalhe" in args:
		return {"posicao": Vector3(4.5, 3.8, 8.5), "foco": Vector3(-0.4, 1.2, -3.5),
			"ortografica": false, "tamanho": 63.0, "nome": "detalhe"}
	if "--verso" in args:
		return {"posicao": Vector3(-7.0, 6.3, -18.0), "foco": Vector3(0.0, 2.0, 1.0),
			"ortografica": false, "tamanho": 60.0, "nome": "verso"}
	return {"posicao": Vector3(7.0, 8.2, 14.0), "foco": Vector3(0.0, 1.0, -5.0),
		"ortografica": false, "tamanho": 62.0, "nome": "mata"}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	vista = Vista.new()
	vista.pixel_pass = "--pixel" in args
	vista.niveis = 12.0
	vista.forca_dither = 0.25
	add_child(vista)
	# layers=0 persiste inclusive quando Vista._reconfigurar() religa visible.
	# Não altera o modo global Mat, que pertence à cena principal.
	vista.contorno.layers = 0
	var env: Environment = vista.ambiente.environment
	env.background_color = Color("#859487")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#a5b6a2")
	env.ambient_light_energy = 0.72
	env.ambient_light_sky_contribution = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("#849588")
	env.fog_light_energy = 0.72
	env.fog_density = 0.0048
	vista.sol.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	vista.sol.light_color = Color("#fff1cd")
	vista.sol.light_energy = 1.45
	vista.sol.shadow_bias = 0.025
	vista.sol.shadow_normal_bias = 1.4
	vista.sol.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	vista.sol.directional_shadow_max_distance = 65.0
	mapa = Mapa.new()
	mapa.name = "Mata_umida"
	vista.mundo_3d.add_child(mapa)
	mapa.construir()
	var cfg := configuracao(args)
	var camera: Camera3D = vista.camera
	camera.near = 0.15
	camera.far = 85.0
	camera.position = cfg["posicao"]
	camera.look_at(cfg["foco"], Vector3.UP)
	if cfg["ortografica"]:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = cfg["tamanho"]
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = cfg["tamanho"]
	print("natureza piloto: vista=%s pixel=%s render=%s orcamento=%s nos_mapa=%d" % [
		cfg["nome"], vista.pixel_pass, RenderingServer.get_current_rendering_method(),
		JSON.stringify(mapa.estatisticas), mapa.get_child_count()])
