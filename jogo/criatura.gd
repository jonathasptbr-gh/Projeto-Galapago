extends Node2D
## A criatura na TELA (mockup 64×64 em xadrez). Só LÊ o corpo (sim/corpo.gd):
## posição no chão (a origem do nó, para o y-sort), altura do terreno
## (desnível), z do pulo, olhar, camada, ação e fase — e desenha cada fase:
## antecipação (encolhe), golpe ativo (arco do alcance), defesa (escudo),
## esquiva (rastros), pulo (sobe, a sombra fica), escavação (terra voando),
## subsolo (apagada, por cima da camada escura).

const Mock := preload("res://jogo/mock.gd")
const V := preload("res://sim/visibilidade.gd")

var corpo: RefCounted
var mundo: RefCounted
var _desnivel := 0.0
var _rastros: Array = []  # [pos, alfa]
var _tempo := 0.0
var _sprite: Texture2D


func _ready() -> void:
	_sprite = Mock.criatura(Color("#e8743b"), Color("#f4a259"), Color("#5a2a12"))


func _process(delta: float) -> void:
	if corpo == null:
		return
	_tempo += delta
	position = corpo.pos
	var alt: float = mundo.altura(mundo.celula_de(corpo.pos)) if corpo.camada == "superficie" else 1.0
	_desnivel = V.aproximar(_desnivel, Mock.desnivel(alt), delta, 14.0)
	var subsolo: bool = corpo.camada == "subsolo"
	z_as_relative = not subsolo
	z_index = 20 if subsolo else 0
	if corpo.acao == "esquiva" and corpo.fase == "ativo":
		_rastros.append([corpo.pos, 0.5])
	for r in _rastros:
		r[1] -= delta * 2.5
	_rastros = _rastros.filter(func(r): return r[1] > 0.0)
	queue_redraw()


## Onde ela aparece na tela (em mundo): chão + desnível − pulo.
func ponto_visual() -> Vector2:
	return corpo.pos + Vector2(0, _desnivel - corpo.z)


func _draw() -> void:
	if corpo == null:
		return
	var chao := Vector2(0, _desnivel)
	var corpo_y := chao - Vector2(0, corpo.z)
	var subsolo: bool = corpo.camada == "subsolo"
	# sombra: fica no chão e encolhe com a altura do pulo
	var s := clampf(1.0 - corpo.z / 60.0, 0.45, 1.0)
	draw_set_transform(chao, 0.0, Vector2(s, s * 0.35))
	draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.3), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	# rastros da esquiva
	for r in _rastros:
		var rp: Vector2 = r[0] - corpo.pos + chao
		draw_texture_rect(_sprite, Rect2(rp + Vector2(-32, -52), Vector2(64, 64)), false, Color(1, 1, 1, r[1] * 0.5))
	# corpo (o canvas 64×64 com a base do corpo ~ no chão)
	var escala := Vector2.ONE
	if corpo.fase == "antecipacao":
		escala = Vector2(1.08, 0.9)  # encolhe antes de agir
	var cor := Color(0.45, 0.45, 0.55, 0.85) if subsolo else Color.WHITE
	var tam := Vector2(64, 64) * escala
	draw_texture_rect(_sprite, Rect2(corpo_y + Vector2(-tam.x / 2.0, -tam.y + 12.0 * escala.y), tam), false, cor)
	# olhar: um nariz (triângulo) na frente do corpo
	var o: Vector2 = corpo.olhar
	var c := corpo_y + Vector2(0, -20)
	draw_colored_polygon(PackedVector2Array([c + o * 30.0, c + o * 18.0 + o.orthogonal() * 7.0, c + o * 18.0 - o.orthogonal() * 7.0]), Color(1, 1, 1, 0.9))
	_desenhar_acao(c)


func _desenhar_acao(c: Vector2) -> void:
	var g: Dictionary = corpo.golpe_ativo()
	if not g.is_empty():
		var d: Vector2 = g["dir"]
		var meio := d.angle()
		var arco := deg_to_rad(float(g["arco"])) / 2.0
		var pts := PackedVector2Array([c])
		for i in 17:
			pts.append(c + Vector2.from_angle(meio - arco + 2.0 * arco * i / 16.0) * float(g["alcance"]))
		draw_colored_polygon(pts, Color(1.0, 0.55, 0.15, 0.45))
		draw_polyline(pts.slice(1), Color(1.0, 0.85, 0.4, 0.95), 2.0, true)
	if corpo.defendendo():
		draw_arc(c, 34.0, 0.0, TAU, 48, Color(0.4, 0.75, 1.0, 0.9), 3.0, true)
		draw_circle(c, 34.0, Color(0.4, 0.75, 1.0, 0.15), true, -1.0, true)
	if corpo.acao == "escavar" and corpo.fase == "ativo":
		for i in 6:
			var a := _tempo * 9.0 + i * TAU / 6.0
			draw_circle(c + Vector2(cos(a) * 26.0, 18.0 + sin(a) * 8.0 - absf(sin(_tempo * 12.0 + i)) * 14.0), 3.0, Color("#7a5230"), true, -1.0, true)
	if corpo.acao == "investida" and corpo.fase == "ativo":
		var d2: Vector2 = corpo.dir
		for k in 3:
			var lado := d2.orthogonal() * (k - 1) * 12.0
			draw_line(c - d2 * 30.0 + lado, c - d2 * 60.0 + lado, Color(1, 1, 1, 0.6), 2.0, true)
