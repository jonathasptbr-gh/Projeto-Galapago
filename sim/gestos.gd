extends RefCounted
## Reconhecedor de GESTOS de um dedo — LÓGICA PURA.
##
## Recebe o dedo (iniciar / mover / tick / soltar) com o tempo em ms do
## relógio SIMULADO do jogo (não o do sistema: assim teste, demo e oráculo
## são determinísticos) e devolve EVENTOS:
##   toque · toque_duplo · segurar_inicio · segurar_fim · deslize ·
##   trajetoria · nada
## Cada evento: {gesto, inicio, fim, vetor, pontos, duracao_ms, na_criatura}.
## Posições em pixels de TELA. A tradução gesto → ação é da sim/comandos.gd.
##
## Ordem de decisão ao soltar (limiares em dados/gestos.json):
##  1. moveu pouco: se já virou "segurar" → segurar_fim; senão toque (e, se
##     houve outro toque perto e há pouco tempo, também toque_duplo);
##  2. rápido e longo o bastante → deslize (de onde começou, tanto faz);
##  3. começou na criatura e é longo → trajetoria;
##  4. senão → nada (não reconhecido; a HUD mostra).

var lim: Dictionary
var _ativo := false
var _segurando := false
var _pontos := PackedVector2Array()
var _t0 := 0.0
var _criatura := Vector2.ZERO
var _ultimo_toque_t := -1.0e9
var _ultimo_toque_pos := Vector2.ZERO


func _init(limiares: Dictionary = {}) -> void:
	lim = {
		"toque_max_px": 16.0, "toque_max_ms": 260.0, "toque_duplo_janela_ms": 340.0,
		"toque_duplo_dist_px": 70.0, "segurar_min_ms": 380.0, "deslize_min_px": 44.0,
		"deslize_max_ms": 380.0, "trajetoria_raio_inicio_px": 100.0,
		"trajetoria_min_px": 60.0, "na_criatura_raio_px": 70.0,
	}
	for k in limiares:
		lim[k] = float(limiares[k])


func ativo() -> bool:
	return _ativo


## Dedo encostou. `criatura` = onde a criatura está na TELA agora.
func iniciar(pos: Vector2, t_ms: float, criatura: Vector2) -> Array:
	_ativo = true
	_segurando = false
	_pontos = PackedVector2Array([pos])
	_t0 = t_ms
	_criatura = criatura
	return []


func mover(pos: Vector2, t_ms: float) -> Array:
	if not _ativo:
		return []
	_pontos.append(pos)
	return tick(t_ms)


## Chamar a cada quadro com o dedo parado: é o que transforma em "segurar".
func tick(t_ms: float) -> Array:
	if not _ativo or _segurando:
		return []
	if t_ms - _t0 >= lim["segurar_min_ms"] and _desvio_max() <= lim["toque_max_px"]:
		_segurando = true
		return [_evento("segurar_inicio", t_ms)]
	return []


func soltar(pos: Vector2, t_ms: float) -> Array:
	if not _ativo:
		return []
	if _pontos[_pontos.size() - 1] != pos:
		_pontos.append(pos)
	_ativo = false
	var dur := t_ms - _t0
	var vetor := pos - _pontos[0]
	if _segurando:
		_segurando = false
		return [_evento("segurar_fim", t_ms)]
	if _desvio_max() <= lim["toque_max_px"]:
		if dur > lim["toque_max_ms"]:
			return [_evento("nada", t_ms)]
		var saida := [_evento("toque", t_ms)]
		if t_ms - _ultimo_toque_t <= lim["toque_duplo_janela_ms"] and pos.distance_to(_ultimo_toque_pos) <= lim["toque_duplo_dist_px"]:
			saida.append(_evento("toque_duplo", t_ms))
			_ultimo_toque_t = -1.0e9  # o terceiro toque não vira outro duplo
		else:
			_ultimo_toque_t = t_ms
			_ultimo_toque_pos = pos
		return saida
	# QUALQUER arrasto começando perto da criatura é ROTA — mesmo rápido. Vem
	# ANTES do teste de deslize: é a mão do jogador desenhando o caminho.
	if _pontos[0].distance_to(_criatura) <= lim["trajetoria_raio_inicio_px"] and _comprimento() >= lim["trajetoria_min_px"]:
		return [_evento("trajetoria", t_ms)]
	if dur <= lim["deslize_max_ms"] and vetor.length() >= lim["deslize_min_px"]:
		return [_evento("deslize", t_ms)]
	return [_evento("nada", t_ms)]


func _evento(gesto: String, t_ms: float) -> Dictionary:
	var ini := _pontos[0]
	var fim := _pontos[_pontos.size() - 1]
	return {
		"gesto": gesto, "inicio": ini, "fim": fim, "vetor": fim - ini,
		"pontos": _pontos.duplicate(), "duracao_ms": t_ms - _t0,
		"na_criatura": ini.distance_to(_criatura) <= lim["na_criatura_raio_px"],
	}


func _desvio_max() -> float:
	var m := 0.0
	for p in _pontos:
		m = maxf(m, p.distance_to(_pontos[0]))
	return m


func _comprimento() -> float:
	var total := 0.0
	for i in range(1, _pontos.size()):
		total += _pontos[i - 1].distance_to(_pontos[i])
	return total
