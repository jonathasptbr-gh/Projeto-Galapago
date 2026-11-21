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
## v0.6 — os SETORES são relativos à TELA, não ao olhar (a tradução para ação é
## da sim/comandos.gd): para cima = ataque físico, lados = especiais, para
## baixo = esquiva. O CAMINHO exige SEGURAR parado: o ponto segurado vira a
## ÂNCORA (o "animal virtual") e o arrasto a partir dela desenha a rota. Assim
## o dedo não fica em cima da criatura. Arrastar para baixo e CONTINUAR
## segurando = defesa. Segurar em cima dela sem arrastar = escavar.
##
## Ordem de decisão ao soltar:
##  1. estava defendendo → segurar_fim;
##  2. estava ancorado → trajetoria (se desenhou) / segurar em cima dela
##     (escavar) / nada;
##  3. moveu pouco → toque (e, se houve outro perto e há pouco tempo, também
##     toque_duplo);
##  4. rápido e longo o bastante → deslize (ação);
##  5. senão → nada (não reconhecido; a HUD mostra).

var lim: Dictionary
var _ativo := false
var _ancorado := false
var _defendendo := false
var _pontos := PackedVector2Array()
var _t0 := 0.0
var _criatura := Vector2.ZERO
var _na_criatura := false
var _ancora := Vector2.ZERO
var _ultimo_movimento_t := 0.0
var _ultimo_toque_t := -1.0e9
var _ultimo_toque_pos := Vector2.ZERO


func _init(limiares: Dictionary = {}) -> void:
	lim = {
		"toque_max_px": 16.0, "toque_max_ms": 260.0, "toque_duplo_janela_ms": 340.0,
		"toque_duplo_dist_px": 70.0, "segurar_min_ms": 380.0, "segurar_estavel_ms": 180.0,
		"deslize_min_px": 44.0, "deslize_max_ms": 380.0,
		"trajetoria_min_px": 40.0, "na_criatura_raio_px": 70.0,
	}
	for k in limiares:
		lim[k] = float(limiares[k])


func ativo() -> bool:
	return _ativo


## A âncora do caminho já foi criada? (o jogo entra em tempo lento enquanto sim)
func ancorado() -> bool:
	return _ancorado


func defendendo() -> bool:
	return _defendendo


func ancora() -> Vector2:
	return _ancora


func pontos() -> PackedVector2Array:
	return _pontos.duplicate()


## Dedo encostou. `criatura` = onde a criatura está na TELA agora.
func iniciar(pos: Vector2, t_ms: float, criatura: Vector2) -> Array:
	_ativo = true
	_ancorado = false
	_defendendo = false
	_pontos = PackedVector2Array([pos])
	_t0 = t_ms
	_ultimo_movimento_t = t_ms
	_criatura = criatura
	_ancora = pos
	_na_criatura = pos.distance_to(criatura) <= lim["na_criatura_raio_px"]
	return []


func mover(pos: Vector2, t_ms: float) -> Array:
	if not _ativo:
		return []
	if _pontos[_pontos.size() - 1].distance_to(pos) > 1.0:
		_ultimo_movimento_t = t_ms
	_pontos.append(pos)
	# Com âncora ou defesa em curso, o gesto já está decidido: nada a fazer.
	if _ancorado or _defendendo:
		return []
	return tick(t_ms)


## Chamar a cada quadro com o dedo parado: é o que transforma em "segurar".
func tick(t_ms: float) -> Array:
	if not _ativo or _ancorado or _defendendo:
		return []
	if t_ms - _t0 < lim["segurar_min_ms"]:
		return []
	# Dedo praticamente parado no lugar de onde desceu = âncora do caminho.
	if _desvio_max() <= lim["toque_max_px"]:
		_ancorado = true
		_ancora = _pontos[0]
		return []
	# Deslize para baixo e depois PARADO = defesa (sustentada até soltar).
	var desloc := _pontos[_pontos.size() - 1] - _pontos[0]
	if _eh_baixo(desloc) and t_ms - _ultimo_movimento_t >= lim["segurar_estavel_ms"]:
		_defendendo = true
		return [_evento("segurar_inicio", t_ms)]
	return []


func soltar(pos: Vector2, t_ms: float) -> Array:
	if not _ativo:
		return []
	if _pontos[_pontos.size() - 1] != pos:
		_pontos.append(pos)
	_ativo = false
	var ini := _pontos[0]
	var vetor := pos - ini
	var dur := t_ms - _t0
	if _defendendo:
		_defendendo = false
		return [_evento("segurar_fim", t_ms)]
	if _ancorado:
		var desenhou: bool = _comprimento() >= lim["trajetoria_min_px"]
		_ancorado = false
		if desenhou:
			return [_evento("trajetoria", t_ms)]
		if _na_criatura and _desvio_max() <= lim["toque_max_px"]:
			# segurar nela SEM arrastar = escavar (o evento sem `defesa`)
			return [_evento("segurar_inicio", t_ms)]
		return [_evento("nada", t_ms)]
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
	# Qualquer arrasto que NÃO passou pela âncora é gesto de ação (não é mais
	# "arrasto perto = rota": o caminho agora exige segurar antes).
	if dur <= lim["deslize_max_ms"] and vetor.length() >= lim["deslize_min_px"]:
		return [_evento("deslize", t_ms)]
	return [_evento("nada", t_ms)]


## O deslocamento é predominantemente para BAIXO na tela? (setor de esquiva)
func _eh_baixo(v: Vector2) -> bool:
	return v.length() > 4.0 and v.y > 0.0 and absf(v.x) <= absf(v.y) * 1.2


func _evento(gesto: String, t_ms: float) -> Dictionary:
	var ini := _pontos[0]
	var fim := _pontos[_pontos.size() - 1]
	return {
		"gesto": gesto, "inicio": ini, "fim": fim, "vetor": fim - ini,
		"pontos": _pontos.duplicate(), "duracao_ms": t_ms - _t0,
		"na_criatura": _na_criatura, "ancora": _ancora, "defesa": _defendendo,
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
