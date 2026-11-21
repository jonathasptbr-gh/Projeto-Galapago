extends RefCounted
## Reconhecedor de GESTOS DE UM DEDO — LÓGICA PURA (v0.9).
##
## **UM DEDO FAZ TUDO.** O primeiro dedo que desce é o do CAMINHO:
##
## - arrastar além de `desenho_min_px` já desenha a rota AO VIVO, sem espera.
##   A FORMA do desenho é lida por `sim/formas.gd`: laço → ataque em área,
##   bico → tiro. O gesto não tem de decidir isso.
## - soltar sem arrastar = **toque** (PULO); dois toques = **toque duplo**
##   (TIRO no alvo marcado). Para o primeiro toque de um duplo não pular, o
##   toque simples fica PENDENTE até a janela do duplo fechar (o `tick` solta).
## - parado sem arrastar por `segurar_min_ms` = **segurar**: o gesto vira uma
##   HABILIDADE em si mesmo (cavar), decidida no soltar.
##
## `dados/gestos.json` guarda a tabela gesto → ação (`mapa`).
##
## Um SEGUNDO dedo não é ação: o gesto continua no primeiro dedo, mas toque,
## toque duplo e segurar ficam DESARMADOS (dois dedos não são um toque — é o
## que evita pular/travar sem querer num toque de mão).
##
## Cada evento: {gesto, inicio, fim, vetor, pontos, duracao_ms}. Posições em
## pixels de TELA.

var lim: Dictionary
var _agora := 0.0

var _caminho := -1
var _desenhando := false
var _t_desenho := 0.0
var _pontos := PackedVector2Array()
var _t0 := 0.0
var _inicio := Vector2.ZERO
var _segurando := false
var _um_dedo := true
# o toque simples fica pendente para não pular no 1º toque de um duplo
var _pendente_ev: Dictionary = {}
var _pendente_t := -1.0
var _pendente_pos := Vector2.ZERO


func _init(limiares: Dictionary = {}) -> void:
	lim = {
		"toque_max_px": 16.0, "toque_max_ms": 260.0, "toque_duplo_janela_ms": 340.0,
		"toque_duplo_dist_px": 70.0, "segurar_min_ms": 380.0,
		"desenho_min_px": 16.0, "desenho_min_ms": 150.0,
	}
	for k in limiares:
		lim[k] = float(limiares[k])


func ativo() -> bool:
	return _caminho != -1


## O dedo do caminho já virou traço? (o jogo alimenta a rota ao vivo)
func desenhando() -> bool:
	return _desenhando


## O mundo está em "planejamento" (tempo lento)? Só o desenho CONFIRMADO
## (mais de `desenho_min_ms`) conta: um toque de mão não escurece a tela.
func planejando() -> bool:
	return _desenhando and _agora - _t_desenho >= float(lim["desenho_min_ms"])


## Ponto de TELA onde o dedo do caminho desceu (a origem, em mundo, é congelada
## por quem converte).
func inicio() -> Vector2:
	return _inicio


func pontos() -> PackedVector2Array:
	return _pontos.duplicate()


# ---------------------------------------------------------------- dedos

func iniciar(dedo: int, pos: Vector2, t_ms: float, _criatura := Vector2.ZERO) -> Array:
	_agora = t_ms
	if _caminho == -1:
		return _iniciar_caminho(dedo, pos, t_ms)
	# segundo dedo (ou mais): não é ação; o caminho segue no primeiro
	_um_dedo = false
	return []


func mover(dedo: int, pos: Vector2, t_ms: float) -> Array:
	_agora = t_ms
	if dedo == _caminho:
		_mover_caminho(pos, t_ms)
	return []


func soltar(dedo: int, pos: Vector2, t_ms: float) -> Array:
	_agora = t_ms
	if dedo != _caminho:
		return []
	var evs := _soltar_caminho(pos, t_ms)
	_caminho = -1
	_desenhando = false
	return evs


## Chamar a cada quadro com os dedos parados: solta o TOQUE pendente (depois
## da janela do duplo) e arma o "segurar".
func tick(t_ms: float) -> Array:
	_agora = t_ms
	var out: Array = []
	# janela do duplo fechou sem um segundo toque: era um TOQUE simples (pulo)
	if _pendente_t >= 0.0 and t_ms - _pendente_t > float(lim["toque_duplo_janela_ms"]):
		out.append(_pendente_ev)
		_pendente_t = -1.0
	if _caminho == -1 or _desenhando or _segurando:
		return out
	if _um_dedo and t_ms - _t0 >= float(lim["segurar_min_ms"]) \
			and _desvio_max() <= float(lim["toque_max_px"]):
		_segurando = true
	return out


# ---------------------------------------------------------------- caminho

func _iniciar_caminho(dedo: int, pos: Vector2, t_ms: float) -> Array:
	_caminho = dedo
	_desenhando = false
	_pontos = PackedVector2Array([pos])
	_t0 = t_ms
	_inicio = pos
	_um_dedo = true
	_segurando = false
	return []


func _mover_caminho(pos: Vector2, t_ms: float) -> void:
	if _pontos[_pontos.size() - 1].distance_to(pos) > 1.0:
		_pontos.append(pos)
	if not _desenhando and pos.distance_to(_inicio) > float(lim["desenho_min_px"]):
		_desenhando = true
		_t_desenho = t_ms


func _soltar_caminho(pos: Vector2, t_ms: float) -> Array:
	if _pontos[_pontos.size() - 1] != pos:
		_pontos.append(pos)
	var dur := t_ms - _t0
	if _desenhando:
		return [_evento("trajetoria", t_ms)]
	if _segurando:
		_segurando = false
		return [_evento("segurar_inicio", t_ms)]
	if not _um_dedo:
		return []  # dois dedos nunca viram toque
	if _desvio_max() > float(lim["toque_max_px"]) or dur > float(lim["toque_max_ms"]):
		return [_evento("nada", t_ms)]
	# SEGUNDO toque dentro da janela e perto do primeiro: é TOQUE DUPLO (tiro).
	# O toque simples pendente é descartado (não pula).
	if _pendente_t >= 0.0 and t_ms - _pendente_t <= float(lim["toque_duplo_janela_ms"]) \
			and pos.distance_to(_pendente_pos) <= float(lim["toque_duplo_dist_px"]):
		_pendente_t = -1.0
		return [_evento("toque_duplo", t_ms)]
	# primeiro toque: fica pendente; o `tick` solta como TOQUE (pulo) se a
	# janela fechar sem o segundo.
	_pendente_ev = _evento("toque", t_ms)
	_pendente_t = t_ms
	_pendente_pos = pos
	return []


# ---------------------------------------------------------------- interno

func _evento(gesto: String, t_ms: float) -> Dictionary:
	var ini := _pontos[0]
	var fim := _pontos[_pontos.size() - 1]
	return {
		"gesto": gesto, "inicio": ini, "fim": fim, "vetor": fim - ini,
		"pontos": _pontos.duplicate(), "duracao_ms": t_ms - _t0,
	}


func _desvio_max() -> float:
	var m := 0.0
	for p in _pontos:
		m = maxf(m, p.distance_to(_pontos[0]))
	return m
