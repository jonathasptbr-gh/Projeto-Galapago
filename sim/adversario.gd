extends RefCounted
## ADVERSÁRIO de teste: só VAGUEIA pelo mapa — sem reação, sem dano, sem
## contato. Serve para exercitar a mira (travar alvo móvel).
##
## Sorteio com semente: a mesma semente dá sempre o mesmo passeio (testes e
## demo são determinísticos). Não entra na água: cada passo é cortado pelas
## regras do mundo.

const Mundo := preload("res://sim/mundo.gd")

var pos := Vector2.ZERO
var raio := 15.0
var velocidade := 26.0
var olhar := Vector2.RIGHT
var rng := RandomNumberGenerator.new()

var _destino := Vector2.ZERO
var _espera := 0.0
var _limite := Rect2()


func _init(semente := 1, mapa_limite := Rect2()) -> void:
	rng.seed = semente
	_limite = mapa_limite
	_destino = pos


## Escolhe um novo destino perto (dentro de `alcance`) e andável.
func decidir(mundo: RefCounted, alcance := 90.0) -> void:
	for _i in 8:
		var ang := rng.randf_range(0.0, TAU)
		var d := rng.randf_range(alcance * 0.35, alcance)
		var p: Vector2 = pos + Vector2.from_angle(ang) * d
		if mundo.andavel(mundo.celula_de(p), Mundo.SUPERFICIE):
			_destino = p
			return
	_destino = pos


func passo(dt: float, mundo: RefCounted) -> void:
	if _espera > 0.0:
		_espera -= dt
		if _espera <= 0.0:
			decidir(mundo)
		return
	var v := (_destino - pos)
	if v.length() < 3.0:
		_espera = rng.randf_range(0.8, 2.2)
		return
	var passo_v := v.normalized() * minf(velocidade * dt, v.length())
	# o mundo corta o passo (não entra na água nem em parede)
	var novo: Vector2 = mundo.limitar_segmento(pos, pos + passo_v, Mundo.SUPERFICIE)
	if novo.distance_to(pos) < 0.01:
		_espera = rng.randf_range(0.4, 1.0)
		return
	olhar = (novo - pos).normalized()
	pos = novo
	if _limite.size != Vector2.ZERO:
		pos = pos.clamp(_limite.position, _limite.end - Vector2.ONE)
