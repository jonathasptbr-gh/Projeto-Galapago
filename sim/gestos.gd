extends RefCounted
## Reconhecedor de GESTOS de um dedo — LÓGICA PURA.
##
## Recebe o dedo (iniciar / mover / tick / soltar) com o tempo em ms do
## relógio SIMULADO do jogo (não o do sistema: assim teste, demo e oráculo
## são determinísticos) e devolve EVENTOS:
##   toque · toque_duplo · segurar_inicio · segurar_fim · deslize ·
##   trajetoria · nada
## Cada evento: {gesto, inicio, fim, vetor, pontos, duracao_ms, na_criatura,
## ancora, defesa}. Posições em pixels de TELA.
##
## v0.7 — SEM ESPERA: assim que o dedo anda mais que `desenho_min_px` o gesto
## JÁ É caminho (o jogo desenha a rota ao vivo, quadro a quadro). Acabou o
## "segurar parado antes de arrastar".
##
## As AÇÕES continuam em paralelo: um RISCO rápido (limiares `flick_*`)
## dispara o setor da tabela NO MEIO do arrasto e o caminho continua — no
## máximo um disparo por gesto (senão um desenho rápido viraria metralhadora).
##
## A ORIGEM do caminho é a posição da CRIATURA quando o dedo desceu. Aqui só se
## guarda o ponto de TELA do começo (`inicio()`); quem converte tela→mundo
## congela a origem, então a linha não anda junto com o animal.
##
## Defesa: deslizar para BAIXO e ficar parado (`segurar_estavel_ms`) sem
## soltar. Escavar: segurar em cima dela, sem arrastar, e soltar.
##
## Ordem de decisão ao soltar:
##  1. defendendo → segurar_fim;
##  2. desenhou (arrasto além da tolerância) → trajetoria (a rota desenhada ao
##     vivo é fechada aqui);
##  3. segurou nela sem arrastar → segurar_inicio (escavar);
##  4. sem arrasto → toque (e, se houve outro perto e há pouco tempo, também
##     toque_duplo);
##  5. senão → nada.

var lim: Dictionary
var _ativo := false
var _desenhando := false
var _defendendo := false
var _segurando := false
var _acao_disparada := false
var _pontos := PackedVector2Array()
var _tempos: Array[float] = []
var _t0 := 0.0
var _criatura := Vector2.ZERO
var _na_criatura := false
var _ultimo_movimento_t := 0.0
var _ultimo_toque_t := -1.0e9
var _ultimo_toque_pos := Vector2.ZERO


func _init(limiares: Dictionary = {}) -> void:
	lim = {
		"toque_max_px": 16.0, "toque_max_ms": 260.0, "toque_duplo_janela_ms": 340.0,
		"toque_duplo_dist_px": 70.0, "segurar_min_ms": 380.0, "segurar_estavel_ms": 180.0,
		"desenho_min_px": 16.0, "deslize_min_px": 44.0,
		"flick_vel_min_px_s": 700.0, "flick_max_ms": 260.0, "flick_reta_px": 24.0,
		"flick_janela_px": 170.0, "flick_vel_janela_ms": 90.0,
		"na_criatura_raio_px": 70.0,
	}
	for k in limiares:
		lim[k] = float(limiares[k])


func ativo() -> bool:
	return _ativo


## O arrasto já virou caminho? (o jogo alimenta a rota ao vivo e desacelera)
func desenhando() -> bool:
	return _desenhando


## O mundo está em "planejamento" (tempo lento)? Desenho, defesa ou escavação.
func planejando() -> bool:
	return _desenhando or _defendendo or _segurando


func defendendo() -> bool:
	return _defendendo


## Ponto de TELA onde o dedo desceu: é o começo do traço (a origem, em mundo,
## é congelada por quem converte).
func inicio() -> Vector2:
	return _pontos[0] if not _pontos.is_empty() else Vector2.ZERO


func pontos() -> PackedVector2Array:
	return _pontos.duplicate()


## Dedo encostou. `criatura` = onde a criatura está na TELA agora.
func iniciar(pos: Vector2, t_ms: float, criatura: Vector2) -> Array:
	_ativo = true
	_desenhando = false
	_defendendo = false
	_segurando = false
	_acao_disparada = false
	_pontos = PackedVector2Array([pos])
	_tempos = [t_ms]
	_t0 = t_ms
	_ultimo_movimento_t = t_ms
	_criatura = criatura
	_na_criatura = pos.distance_to(criatura) <= lim["na_criatura_raio_px"]
	return []


func mover(pos: Vector2, t_ms: float) -> Array:
	if not _ativo:
		return []
	if _pontos[_pontos.size() - 1].distance_to(pos) > 1.0:
		_ultimo_movimento_t = t_ms
		_pontos.append(pos)
		_tempos.append(t_ms)
	if _defendendo or _acao_disparada:
		return []
	if not _desenhando:
		if pos.distance_to(_pontos[0]) <= lim["desenho_min_px"]:
			return []
		_desenhando = true
	# RISCO rápido: a ação sai AGORA, no meio do desenho, sem parar o caminho.
	var ev := _risco(t_ms)
	if ev.is_empty():
		return []
	_acao_disparada = true
	return [ev]


## Chamar a cada quadro com o dedo parado: é o que transforma em "segurar".
func tick(t_ms: float) -> Array:
	if not _ativo or _defendendo:
		return []
	if _desenhando:
		# deslize para BAIXO e depois PARADO = defesa (sustentada até soltar)
		if not _eh_baixo(_pontos[_pontos.size() - 1] - _pontos[0]):
			return []
		if t_ms - _ultimo_movimento_t < lim["segurar_estavel_ms"]:
			return []
		_defendendo = true
		_segurando = false
		return [_evento("segurar_inicio", t_ms)]
	# segurar em cima dela, parado = escavar (decidido no soltar)
	if _na_criatura and not _segurando and t_ms - _t0 >= lim["segurar_min_ms"] \
			and _desvio_max() <= lim["toque_max_px"]:
		_segurando = true
	return []


func soltar(pos: Vector2, t_ms: float) -> Array:
	if not _ativo:
		return []
	if _pontos[_pontos.size() - 1] != pos:
		_pontos.append(pos)
		_tempos.append(t_ms)
	_ativo = false
	var dur := t_ms - _t0
	if _defendendo:
		_defendendo = false
		return [_evento("segurar_fim", t_ms)]
	if _desenhando:
		_desenhando = false
		return [_evento("trajetoria", t_ms)]
	if _segurando:
		_segurando = false
		return [_evento("segurar_inicio", t_ms)]
	if _desvio_max() > lim["toque_max_px"] or dur > lim["toque_max_ms"]:
		return [_evento("nada", t_ms)]
	var saida := [_evento("toque", t_ms)]
	if t_ms - _ultimo_toque_t <= lim["toque_duplo_janela_ms"] and pos.distance_to(_ultimo_toque_pos) <= lim["toque_duplo_dist_px"]:
		saida.append(_evento("toque_duplo", t_ms))
		_ultimo_toque_t = -1.0e9  # o terceiro toque não vira outro duplo
	else:
		_ultimo_toque_t = t_ms
		_ultimo_toque_pos = pos
	return saida


# ---------------------------------------------------------------- interno

## O traço até agora é um RISCO de ação? Curto, reto, rápido e no começo do
## gesto — o que um desenho (curva, lento, longo) nunca é.
func _risco(t_ms: float) -> Dictionary:
	var comp := _comprimento()
	if t_ms - _t0 > lim["flick_max_ms"]:
		return {}
	if comp < lim["deslize_min_px"] or comp > lim["flick_janela_px"]:
		return {}
	if _desvio_corda() > lim["flick_reta_px"]:
		return {}
	if _velocidade(t_ms) < lim["flick_vel_min_px_s"]:
		return {}
	return _evento("deslize", t_ms)


## Velocidade na janela final do traço (px/s), para o risco não depender do
## espaçamento dos eventos de toque.
func _velocidade(t_ms: float) -> float:
	var i := _tempos.size() - 1
	var janela: float = t_ms - float(lim["flick_vel_janela_ms"])
	while i > 0 and _tempos[i - 1] >= janela:
		i -= 1
	var dt := (t_ms - _tempos[i]) / 1000.0
	if dt <= 0.0:
		return 0.0
	return _pontos[i].distance_to(_pontos[_pontos.size() - 1]) / dt


## O deslocamento é predominantemente para BAIXO na tela? (setor de esquiva)
func _eh_baixo(v: Vector2) -> bool:
	return v.length() > 4.0 and v.y > 0.0 and absf(v.x) <= absf(v.y) * 1.2


func _evento(gesto: String, t_ms: float) -> Dictionary:
	var ini := _pontos[0]
	var fim := _pontos[_pontos.size() - 1]
	return {
		"gesto": gesto, "inicio": ini, "fim": fim, "vetor": fim - ini,
		"pontos": _pontos.duplicate(), "duracao_ms": t_ms - _t0,
		"na_criatura": _na_criatura, "ancora": ini, "defesa": _defendendo,
	}


func _desvio_max() -> float:
	var m := 0.0
	for p in _pontos:
		m = maxf(m, p.distance_to(_pontos[0]))
	return m


## Quanto o traço se afasta da CORDA (reta do começo ao fim, agora).
func _desvio_corda() -> float:
	var a := _pontos[0]
	var b := _pontos[_pontos.size() - 1]
	var d := a.distance_to(b)
	if d < 1.0:
		return 0.0
	var m := 0.0
	for p in _pontos:
		m = maxf(m, absf((p - a).cross(b - a)) / d)
	return m


func _comprimento() -> float:
	var total := 0.0
	for i in range(1, _pontos.size()):
		total += _pontos[i - 1].distance_to(_pontos[i])
	return total
