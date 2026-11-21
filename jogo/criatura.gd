extends Node2D
## A criatura na TELA (mockup 64×64 em xadrez). Só LÊ o corpo (sim/corpo.gd):
## posição (já com o desvio da esquiva), altura do terreno, z do pulo, olhar,
## camada, ataque/defesa/escavação. Desenha:
## - sombra que encolhe no pulo; corpo que sobe no arco;
## - nariz (olhar);
## - golpe: cone na direção do alvo/rota (não para o movimento);
## - defesa: anel azul; escavação: terra voando; esquiva: rastro;
## - subsolo: apagada, por cima da camada escura.

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
	# rastro da esquiva (o desvio é lateral e volta)
	if corpo.desvio.length() > 1.0:
		draw_texture_rect(_sprite, Rect2(chao + Vector2(-32, -52) - corpo.desvio * 0.6, Vector2(64, 64)), false, Color(1, 1, 1, 0.25))
	var cor := Color(0.45, 0.45, 0.55, 0.85) if subsolo else Color.WHITE
	draw_texture_rect(_sprite, Rect2(meu + Vector2(-32, -52), Vector2(64, 64)), false, cor)
	var c := meu + Vector2(0, -20)
	var o: Vector2 = corpo.olhar if corpo.olhar.length() > 0.01 else Vector2.RIGHT
	draw_colored_polygon(PackedVector2Array([c + o * 30.0, c + o * 18.0 + o.orthogonal() * 7.0, c + o * 18.0 - o.orthogonal() * 7.0]), Color(1, 1, 1, 0.9))
	_desenhar_acoes(c)


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
	if corpo.defendendo:
		draw_arc(c, 32.0, 0.0, TAU, 40, Color(0.4, 0.75, 1.0, 0.9), 3.0, true)
		draw_circle(c, 32.0, Color(0.4, 0.75, 1.0, 0.15), true, -1.0, true)
	if corpo.escavando:
		for i in 6:
			var a := _tempo * 9.0 + i * TAU / 6.0
			draw_circle(c + Vector2(cos(a) * 26.0, 18.0 + sin(a) * 8.0 - absf(sin(_tempo * 12.0 + i)) * 14.0), 3.0, Color("#7a5230"), true, -1.0, true)
