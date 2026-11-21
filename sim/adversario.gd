extends RefCounted
## ADVERSÁRIO de teste: vagueia pelo mapa e REAGE ao golpe — empurrão (sai
## deslizando na direção do golpe) e PISCADA. Não tem vida nem ataca de volta
## (por enquanto, decisão do operador na v0.9): o efeito do golpe é físico.
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
# resposta ao golpe
var _empurrao := Vector2.ZERO      # distância que ainda falta deslizar
var _pisca_t := 0.0
var forca_empurrao := 260.0        # px/s com que o empurrão sai
var pisca_dur := 0.24              # s


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


## Levou um golpe: sai empurrado `forca_px` na direção `dir` e PISCA. Empurrão
## de cima de outro soma; o mundo corta o passo (não atravessa parede).
func empurrar(dir: Vector2, forca_px: float) -> void:
	if dir.length() < 0.001:
		dir = -olhar if olhar.length() > 0.01 else Vector2.RIGHT
	_empurrao += dir.normalized() * maxf(forca_px, 0.0)
	_pisca_t = pisca_dur


func piscando() -> bool:
	return _pisca_t > 0.0


func empurrado() -> bool:
	return _empurrao.length() > 0.01


func passo(dt: float, mundo: RefCounted) -> void:
	_pisca_t = maxf(_pisca_t - dt, 0.0)
	if _empurrao.length() > 0.01:
		# empurrão: desliza reto até gastar o que levou; o passeio espera
		var dir := _empurrao.normalized()
		var quanto := minf(forca_empurrao * dt, _empurrao.length())
		var novo: Vector2 = mundo.limitar_segmento(pos, pos + dir * quanto, Mundo.SUPERFICIE)
		var andado := novo.distance_to(pos)
		pos = novo
		_empurrao -= dir * andado
		if andado < 0.01:
			_empurrao = Vector2.ZERO
		return
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
