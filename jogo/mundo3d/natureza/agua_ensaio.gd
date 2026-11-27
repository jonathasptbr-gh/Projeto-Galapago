extends Node2D
## ENSAIO da ÁGUA DE GRADE (P27), separado do jogo: uma encosta com vala
## sinuosa, uma bacia no meio e o riacho embaixo. Uma fonte jorra por
## `FONTE_S` s; a água desce a vala, enche a bacia, transborda até o riacho e
## evapora; o chão fica úmido e seca depois. Regra: sim/agua.gd (célula de
## 1 unidade); desenho: agua.gdshader (lâmina suave, borda orgânica) +
## natural.gdshader com `usar_umidade`. Câmera parada.
## Argumentos: padrão = perspectiva de perto; `--alta` = a vista alta
## ortográfica do jogo; `--pixel` = Pixel Pass; `--avancar=S` começa S s
## adiantado. `--demo` é ignorado.
## Filmar: QUADROS_CENA=res://jogo/mundo3d/natureza/agua_ensaio.tscn
##         QUADROS_FPS=10 tools/quadros.sh 100 <saída>

const Vista := preload("res://jogo/mundo3d/vista.gd")
const Agua := preload("res://sim/agua.gd")
const Mapa := preload("res://jogo/mundo3d/natureza/mapa.gd")
const Biblioteca := preload("res://jogo/mundo3d/natureza/malhas.gd")
const AGUA_SHADER := preload("res://jogo/mundo3d/natureza/agua.gdshader")

const LARGURA := 20
const ALTURA := 21
const LINHA_RIO := 19
const NIVEL_RIO := 0.22
const FONTE := Vector2i(10, 1)
const VAZAO := 3.2
const FONTE_INICIO := 0.3
const FONTE_S := 4.0
const EVAPORA := 0.03
const ESCALA_PROF := 2.0
const ESCALA_FLUXO := 1.5
## o desenho vai além da grade (a regra só vale dentro): margem em x e para o norte
const MARGEM_X := 12.0
const NORTE := -10.0

var vista: CanvasLayer
var grade: RefCounted
var imagem: Image
var textura: ImageTexture
var jato: CPUParticles3D
var _t := 0.0
var _impresso := -1


## A vala serpenteia; o chão desce para o sul até o barranco do riacho.
static func vala_x(z: float) -> float:
	return 10.0 + sin(z * 0.42) * 1.6


static func chao(x: float, z: float) -> float:
	var h := 1.5 - minf(z, 16.5) * 0.075
	h -= 0.2 * exp(-pow(x - vala_x(z), 2.0) / 3.0)
	h -= 0.3 * (1.0 - smoothstep(0.8, 2.6, Vector2(x - 9.0, z - 9.5).length()))
	h += sin(x * 0.9) * sin(z * 0.7) * 0.03
	# barranco: do pé da encosta ao leito do riacho
	h = lerpf(h, -0.25, smoothstep(17.6, 18.8, z))
	return h


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	vista = Vista.new()
	vista.pixel_pass = "--pixel" in args
	add_child(vista)
	vista.contorno.layers = 0
	Mapa.ambientar(vista.ambiente.environment, vista.sol, false)
	vista.sol.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	vista.sol.directional_shadow_max_distance = 60.0
	vista.sol.shadow_bias = 0.025

	grade = Agua.new(LARGURA, ALTURA)
	grade.evaporacao = EVAPORA
	for z in range(ALTURA):
		for x in range(LARGURA):
			grade.definir_chao(Vector2i(x, z), chao(x + 0.5, z + 0.5))
			if z >= LINHA_RIO:
				grade.rio(Vector2i(x, z), NIVEL_RIO)
	imagem = Image.create(LARGURA, ALTURA, false, Image.FORMAT_RGBA8)
	textura = ImageTexture.create_from_image(imagem)
	_atualizar_textura()

	var ret := Vector4(0.0, 0.0, 1.0 / LARGURA, 1.0 / ALTURA)
	var solo := Biblioteca.material()
	solo.set_shader_parameter("usar_umidade", true)
	solo.set_shader_parameter("campo_agua", textura)
	solo.set_shader_parameter("campo_ret", ret)
	vista.mundo_3d.add_child(_malha("Solo", _solo(), solo))
	var mat_agua := ShaderMaterial.new()
	mat_agua.shader = AGUA_SHADER
	mat_agua.set_shader_parameter("campo", textura)
	mat_agua.set_shader_parameter("campo_ret", ret)
	mat_agua.set_shader_parameter("escala_prof", ESCALA_PROF)
	var lamina := _malha("Agua", _lamina(), mat_agua)
	lamina.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	vista.mundo_3d.add_child(lamina)
	_enfeites()
	_jato()
	_camera("--alta" in args)
	# `--avancar=S`: começa S segundos adiantado (fotos do meio do ciclo)
	for a in args:
		if a.begins_with("--avancar="):
			var alvo := float(a.get_slice("=", 1))
			while _t < alvo:
				_avancar(0.1)
			_atualizar_textura()


func _process(dt: float) -> void:
	_avancar(dt)
	_atualizar_textura()


func _avancar(dt: float) -> void:
	_t += dt
	var ligada := _t >= FONTE_INICIO and _t < FONTE_INICIO + FONTE_S
	grade.fonte(FONTE, VAZAO if ligada else 0.0)
	jato.emitting = ligada
	grade.passo(dt)
	var s := int(_t)
	if s != _impresso:
		_impresso = s
		var fora := 0.0
		for i in range(LINHA_RIO * LARGURA):
			fora += grade.agua[i]
		var bacia: float = grade.agua[grade.indice(Vector2i(8, 9))]
		var foz := 0.0
		for x in range(LARGURA):
			foz += grade.agua[grade.indice(Vector2i(x, LINHA_RIO - 2))]
		print("agua ensaio: t=%d s fonte=%s agua_fora_do_rio=%.3f bacia=%.3f perto_do_rio=%.3f" % [s, ligada, fora, bacia, foz])


func _atualizar_textura() -> void:
	for z in range(ALTURA):
		for x in range(LARGURA):
			var i: int = grade.indice(Vector2i(x, z))
			var f: Vector2 = grade.fluxo[i]
			if z >= LINHA_RIO:
				f = Vector2(0.25, 0.0)  # o riacho corre para leste
			imagem.set_pixel(x, z, Color(
				clampf(grade.agua[i] * ESCALA_PROF, 0.0, 1.0),
				clampf(0.5 + f.x * ESCALA_FLUXO * 0.5, 0.0, 1.0),
				clampf(0.5 + f.y * ESCALA_FLUXO * 0.5, 0.0, 1.0),
				grade.umidade[i]))
	textura.update(imagem)


func _malha(nome: String, o: RefCounted, mat: Material) -> MeshInstance3D:
	var m: ArrayMesh = o.malha()
	m.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = m
	return mi


## Chão contínuo (passo 0,25): terra e musgo, cascalho claro na vala, areia no
## barranco.
func _solo() -> RefCounted:
	var o := Biblioteca.Oficina.new()
	var passo := 0.25
	for iz in range(int((ALTURA - NORTE) / passo)):
		for ix in range(int((LARGURA + 2.0 * MARGEM_X) / passo)):
			var x := ix * passo - MARGEM_X
			var z := iz * passo + NORTE
			var p := [Vector3(x, 0, z), Vector3(x + passo, 0, z), Vector3(x, 0, z + passo), Vector3(x + passo, 0, z + passo)]
			for k in [0, 1, 2, 1, 3, 2]:
				var q: Vector3 = p[k]
				q.y = chao(q.x, q.z)
				o.vertices.append(q)
				var e := 0.08
				o.normais.append(Vector3(chao(q.x - e, q.z) - chao(q.x + e, q.z), 2.0 * e,
					chao(q.x, q.z - e) - chao(q.x, q.z + e)).normalized())
				o.cores.append(_cor(q.x, q.z))
	return o


static func _cor(x: float, z: float) -> Color:
	var r := clampf(0.5 + sin(x * 0.8 + sin(z * 0.4)) * 0.25 + cos(z * 0.66 - x * 0.3) * 0.2, 0.0, 1.0)
	var c := Color("#7d5a34").lerp(Color("#3f8a34"), r)
	c = c.lerp(Color("#9c8a68"), (1.0 - smoothstep(0.3, 1.2, absf(x - vala_x(z)))) * 0.55)
	return c.lerp(Color("#c2a978"), smoothstep(17.0, 18.2, z))


## Lâmina d'água: uma malha fina que já segue o chão; o shader a sobe pela
## profundidade e recorta a borda.
func _lamina() -> RefCounted:
	var o := Biblioteca.Oficina.new()
	var passo := 0.25
	for iz in range(int((ALTURA - NORTE) / passo)):
		for ix in range(int((LARGURA + 2.0 * MARGEM_X) / passo)):
			var x := ix * passo - MARGEM_X
			var z := iz * passo + NORTE
			var p := [Vector3(x, 0, z), Vector3(x + passo, 0, z), Vector3(x, 0, z + passo), Vector3(x + passo, 0, z + passo)]
			for k in [0, 1, 2, 1, 3, 2]:
				var q: Vector3 = p[k]
				q.y = chao(q.x, q.z)
				o.vertices.append(q)
				o.normais.append(Vector3.UP)
				o.cores.append(Color.WHITE)
	return o


## Mata em volta (sem tocar o caminho da água): árvores, samambaias,
## sub-bosque e pedras na beira da vala e do riacho.
func _enfeites() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 20261126
	var folha := Biblioteca.material(true)
	var madeira := Biblioteca.material()
	var arvores: Array[Transform3D] = []
	for p in [Vector2(2.5, 4.0), Vector2(17.5, 3.0), Vector2(16.8, 12.5), Vector2(3.2, 13.5),
			Vector2(-3.0, 9.0), Vector2(23.0, 8.0), Vector2(-6.0, 1.0), Vector2(26.0, -1.0),
			Vector2(6.0, -4.0), Vector2(14.5, -6.0), Vector2(-1.0, -7.0), Vector2(21.0, 15.0), Vector2(-2.5, 15.5)]:
		arvores.append(_pose(p.x, p.y, r.randf_range(0, TAU), r.randf_range(0.85, 1.1)))
	var arv: Dictionary = Biblioteca.arvore(20261126)
	_lote(arv["madeira"], arvores, madeira)
	_lote(arv["folhas"], arvores, folha)
	var plantas: Array[Transform3D] = []
	var arbustos: Array[Transform3D] = []
	var pedras: Array[Transform3D] = []
	for i in range(420):
		var x := r.randf_range(-MARGEM_X + 0.5, LARGURA + MARGEM_X - 0.5)
		var z := r.randf_range(NORTE + 0.5, 16.8)
		if absf(x - vala_x(z)) < 2.4 or Vector2(x - 9.0, z - 9.5).length() < 3.0:
			continue
		if i % 2 == 0:
			plantas.append(_pose(x, z, r.randf_range(0, TAU), r.randf_range(0.6, 1.1)))
		else:
			arbustos.append(_pose(x, z, r.randf_range(0, TAU), r.randf_range(0.6, 1.2)))
	for i in range(26):
		var z := r.randf_range(1.0, 17.5)
		var lado := -1.0 if i % 2 == 0 else 1.0
		var x := vala_x(z) + lado * r.randf_range(1.3, 2.2)
		var e := r.randf_range(0.16, 0.34)
		pedras.append(Transform3D(Basis(Vector3.UP, r.randf_range(0, TAU)).scaled(Vector3(e * 1.3, e, e)),
			Vector3(x, chao(x, z) - 0.03, z)))
	_lote(Biblioteca.samambaia(3), plantas, folha)
	_lote(Biblioteca.sub_bosque(4), arbustos, folha)
	_lote(Biblioteca.rocha(5), pedras, madeira)


func _pose(x: float, z: float, yaw: float, esc: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * esc), Vector3(x, chao(x, z) - 0.05, z))


func _lote(m: ArrayMesh, ts: Array[Transform3D], mat: Material) -> void:
	m.surface_set_material(0, mat)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = m
	mm.instance_count = ts.size()
	for i in range(ts.size()):
		mm.set_instance_transform(i, ts[i])
	var no := MultiMeshInstance3D.new()
	no.multimesh = mm
	vista.mundo_3d.add_child(no)


## O jato: respingos claros onde a água nasce (só enquanto a fonte jorra).
func _jato() -> void:
	jato = CPUParticles3D.new()
	var gota := SphereMesh.new()
	gota.radius = 0.05
	gota.height = 0.1
	gota.radial_segments = 6
	gota.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("#d6f6ee")
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gota.material = m
	jato.mesh = gota
	jato.amount = 48
	jato.lifetime = 0.7
	jato.emitting = false
	jato.direction = Vector3.UP
	jato.spread = 28.0
	jato.initial_velocity_min = 1.6
	jato.initial_velocity_max = 2.6
	jato.gravity = Vector3(0, -9.0, 0)
	jato.position = Vector3(FONTE.x + 0.5, chao(FONTE.x + 0.5, FONTE.y + 0.5) + 0.05, FONTE.y + 0.5)
	vista.mundo_3d.add_child(jato)


func _camera(alta: bool) -> void:
	var cam: Camera3D = vista.camera
	var alvo := Vector3(9.4, 0.4, 7.0)
	if alta:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.keep_aspect = Camera3D.KEEP_HEIGHT
		cam.size = 25.0
		var dir := Vector3(0.0, sin(deg_to_rad(60.0)), cos(deg_to_rad(60.0)))
		cam.position = alvo + dir * 40.0
	else:
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.keep_aspect = Camera3D.KEEP_WIDTH
		cam.fov = 58.0
		cam.position = Vector3(12.8, 7.8, 21.5)
	cam.near = 0.1
	cam.far = 120.0
	cam.look_at(alvo, Vector3.UP)
