extends Node2D
## A criatura na TELA (mockup 64×64 em xadrez). Só LÊ o corpo (sim/corpo.gd):
## posição, altura do terreno, z do pulo, olhar, camada, golpe e habilidade.
## Desenha:
## - sombra que encolhe no pulo; corpo que sobe no arco;
## - nariz (olhar);
## - golpe: cone na direção do golpe (o ataque final vai no inimigo marcado);
## - habilidade: terra voando quando cava; anel quando é outra habilidade;
## - carga do tiro: arco amarelo que fecha em volta dela (`corpo.carga()`);
## - subsolo: apagada, por cima da camada escura.
## v0.9: não há mais rastro de esquiva nem anel de defesa — a esquiva é o
## próprio caminhar e não existe gesto de defesa.

const Mock := preload("res://jogo/mock.gd")
const V := preload("res://sim/visibilidade.gd")

var corpo: RefCounted
var mundo: RefCounted
var _desnivel := 0.0
var _tempo := 0.0
var _sprite: Texture2D


func _ready() -> void:
	_sprite = Mock.criatura(Color("#d9752f"), Color("#f2a45c"), Color("#4a2010"))


func _process(delta: float) -> void:
	if corpo == null:
		return
	_tempo += delta
	position = corpo.pos
	var celula: Vector2i = mundo.celula_de(corpo.pos)
	var alt: float = mundo.altura(celula) if corpo.camada == "superficie" else 1.0
	_desnivel = V.aproximar(_desnivel, Mock.desnivel(alt), delta, 14.0)
	var subsolo: bool = corpo.camada == "subsolo"
	z_as_relative = not subsolo
	z_index = 20 if subsolo else 0
	queue_redraw()


## Onde aparece na tela (mundo): chão + desnível − altura do pulo.
func ponto_visual() -> Vector2:
	return corpo.pos + Vector2(0, _desnivel - corpo.z)


func _draw() -> void:
	if corpo == null:
		return
	var chao := Vector2(0, _desnivel)
	var meu := chao - Vector2(0, corpo.z)
	var subsolo: bool = corpo.camada == "subsolo"
	var s := clampf(1.0 - corpo.z / 70.0, 0.4, 1.0)
	draw_set_transform(chao, 0.0, Vector2(s, s * 0.35))
	draw_circle(Vector2.ZERO, 20.0, Color(0, 0, 0, 0.3), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	var cor := Color(0.45, 0.45, 0.55, 0.85) if subsolo else Color.WHITE
	# ATORDOADA (v0.14): o bicho treme e fica avermelhado — o golpe tira o comando
	var tonta: bool = corpo.atordoado()
	if tonta:
		cor = Color(1.0, 0.58, 0.52)
		meu += Vector2(sin(_tempo * 57.0) * 2.2, 0.0)
	draw_texture_rect(_sprite, Rect2(meu + Vector2(-32, -52), Vector2(64, 64)), false, cor)
	var c := meu + Vector2(0, -20)
	var o: Vector2 = corpo.olhar if corpo.olhar.length() > 0.01 else Vector2.RIGHT
	draw_colored_polygon(PackedVector2Array([c + o * 30.0, c + o * 18.0 + o.orthogonal() * 7.0, c + o * 18.0 - o.orthogonal() * 7.0]), Color(1, 1, 1, 0.9))
	_desenhar_acoes(c)
	if tonta:
		_desenhar_estrelas(Vector2(0, -66))


## Estrelinhas girando sobre a cabeça: o corpo não obedece enquanto isso.
func _desenhar_estrelas(base: Vector2) -> void:
	for i in 3:
		var a := _tempo * 7.0 + i * TAU / 3.0
		var p := base + Vector2(cos(a) * 15.0, sin(a) * 4.0 - 4.0)
		draw_circle(p, 2.4, Color(1.0, 0.9, 0.4, 0.95), true, -1.0, true)


func _desenhar_acoes(c: Vector2) -> void:
	var g: Dictionary = corpo.golpe_ativo()
	if not g.is_empty():
		var d: Vector2 = g["dir"]
		var meio := d.angle()
		var arco := deg_to_rad(float(g["arco"])) / 2.0
		var alcance := float(g["alcance"])
		var pts := PackedVector2Array([c])
		for i in 17:
			pts.append(c + Vector2.from_angle(meio - arco + 2.0 * arco * i / 16.0) * alcance)
		var especial: bool = corpo.ataque == "especial"
		var cor_cone := Color(0.4, 0.6, 1.0, 0.45) if especial else Color(1.0, 0.5, 0.12, 0.45)
		var cor_linha := Color(0.6, 0.9, 1.0, 0.95) if especial else Color(1.0, 0.85, 0.4, 0.95)
		draw_colored_polygon(pts, cor_cone)
		draw_polyline(pts.slice(1), cor_linha, 2.0, true)
	if corpo.carregando():
		# CARGA do tiro (v0.17): o aro vai de 20 a 30 px e o arco fecha com a
		# carga — o corpo só diz quanto (0..1), o desenho é daqui.
		var cg := clampf(corpo.carga(), 0.0, 1.0)
		var raio := lerpf(20.0, 30.0, cg)
		draw_arc(c, 30.0, 0.0, TAU, 40, Color(1.0, 0.85, 0.25, 0.22), 2.0, true)
		draw_arc(c, raio, -PI / 2.0, -PI / 2.0 + TAU * cg, 40,
			Color(1.0, 0.9, 0.3, 0.95), 3.0, true)
	if corpo.habilidade_ativa() and not corpo.escavando:
		# habilidade de si mesmo que não é a cavar: anel pulsando em volta
		var raio := 30.0 + 4.0 * sin(_tempo * 10.0)
		draw_arc(c, raio, 0.0, TAU, 40, Color(0.55, 1.0, 0.6, 0.9), 3.0, true)
		draw_circle(c, raio, Color(0.55, 1.0, 0.6, 0.12), true, -1.0, true)
	if corpo.escavando:
		for i in 6:
			var a := _tempo * 9.0 + i * TAU / 6.0
			draw_circle(c + Vector2(cos(a) * 26.0, 18.0 + sin(a) * 8.0 - absf(sin(_tempo * 12.0 + i)) * 14.0), 3.0, Color("#7a5230"), true, -1.0, true)
