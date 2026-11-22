extends Node2D
## ADVERSÁRIO na tela (mockup roxo). Só LÊ o que a `sim/adversario.gd` decide:
## posição, olhar, piscada, hostilidade, preparo e esconderijo.
##
## v0.14: hostil fica com a AURA vermelha e os olhos acesos; preparando, um
## "!" pisca em cima dele; ESCONDIDO, o corpo afunda e fica o montinho de terra
## com bolhas (ele está intocável — o alvo some da lista, a `sim/` decide).

const Mock := preload("res://jogo/mock.gd")

var adv: RefCounted
var mundo: RefCounted
var inclinacao := 1.0
var _tempo := 0.0
var _sprite: Texture2D
var _oculto_vis := 0.0


func _ready() -> void:
	_sprite = Mock.xadrez(32, 8, Color("#8b5cf6"), Color("#a78bfa"))


func _process(delta: float) -> void:
	if adv == null:
		return
	_tempo += delta
	position = Mock.ponto_relevo(adv.pos, mundo, inclinacao)
	var alvo := 1.0 if adv.oculto() else 0.0
	_oculto_vis = lerpf(_oculto_vis, alvo, clampf(delta * 9.0, 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	if adv == null:
		return
	var vis := 1.0 - _oculto_vis
	var pulo := absf(sin(_tempo * 4.0)) * 2.0 * vis
	# sombra (fica um pouco mesmo escondido)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.28), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	if _oculto_vis > 0.02:
		_desenhar_montinho()
	if vis < 0.03:
		return
	# aura hostil
	if adv.hostil:
		var pulso := 0.5 + 0.5 * sin(_tempo * 6.0)
		draw_arc(Vector2(0, -3), 20.0 + pulso * 3.0, 0.0, TAU, 28,
			Color(1.0, 0.36, 0.28, 0.35 + 0.25 * pulso), 2.0, true)
	var cor := Color.WHITE
	if adv.hostil:
		cor = Color(1.0, 0.86, 0.84)
	if adv.piscando():
		cor = Color(1.0, 0.55, 0.45)
	cor.a = vis
	var desce := _oculto_vis * 9.0
	draw_texture_rect(_sprite, Rect2(Vector2(-16, -30 - pulo + desce), Vector2(32, 30)), false, cor)
	var o: Vector2 = adv.olhar if adv.olhar.length() > 0.01 else Vector2.RIGHT
	var olho := Color("#ff4a3d") if adv.hostil else Color("#22113f")
	draw_circle(Vector2(-6, -30 - pulo + desce) + o * 4.0, 2.0, Color(olho, vis))
	draw_circle(Vector2(6, -30 - pulo + desce) + o * 4.0, 2.0, Color(olho, vis))
	if adv.piscando():
		draw_arc(Vector2(0, -15), 20.0, 0.0, TAU, 24, Color(1.0, 0.7, 0.5, 0.9 * vis), 2.0, true)
	if adv.preparando():
		_desenhar_aviso()


func _desenhar_aviso() -> void:
	var u: float = adv.progresso_preparo()
	var pisca := 0.55 + 0.45 * sin(_tempo * 28.0)
	var cor := Color(1.0, 0.85, 0.3, 0.65 + 0.3 * pisca)
	if u > 0.8:
		cor = Color(1.0, 0.35, 0.25, 0.95)
	# "!" acima do corpo
	draw_rect(Rect2(Vector2(-2.0, -70.0), Vector2(4.0, 11.0)), cor, true)
	draw_circle(Vector2(0, -55.0), 2.2, cor, true, -1.0, true)
	# anel de carga em volta
	var raio := 21.0
	draw_arc(Vector2(0, -14), raio, -PI / 2.0, -PI / 2.0 + TAU * u, 32,
		Color(cor.r, cor.g, cor.b, 0.95), 2.5, true)


func _desenhar_montinho() -> void:
	var a: float = _oculto_vis
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 17.0 * a, Color(0.30, 0.21, 0.13, 0.9), true, -1.0, true)
	draw_circle(Vector2.ZERO, 10.0 * a, Color(0.45, 0.32, 0.19, 0.9), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	# bolhas de terra subindo
	for i in 3:
		var t := fmod(_tempo * 1.8 + i * 0.33, 1.0)
		var y := -8.0 - t * 16.0
		var x := sin(_tempo * 3.0 + i * 2.1) * 6.0 * a
		draw_circle(Vector2(x, y), 1.6 * a, Color(0.55, 0.42, 0.26, 0.8 * (1.0 - t)), true, -1.0, true)
