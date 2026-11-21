extends RefCounted
## Reconhecedor de GESTOS MULTITOUCH — LÓGICA PURA (v0.8).
##
## Recebe os DEDOS (iniciar / mover / tick / soltar) com o tempo em ms do
## relógio SIMULADO do jogo e devolve EVENTOS:
##   toque · toque_duplo · segurar_inicio · segurar_fim · deslize ·
##   especial · trajetoria · caminho_cancelar · nada
##
## **UM DEDO É CAMINHO, DOIS SÃO AÇÃO.**
##
## - O PRIMEIRO dedo que desce é o do CAMINHO: arrastar além de
##   `desenho_min_px` já desenha a rota AO VIVO, sem espera.
## - Qualquer dedo EXTRA é um gesto de AÇÃO, lido SÓ NELE — o dedo do caminho
##   "desconta". Assim dá para DESENHAR e ATACAR ao mesmo tempo: o dedo do
##   caminho segue desenhando enquanto o segundo desliza.
##   - para CIMA → ataque (`deslize`);
##   - para BAIXO → defesa (`segurar_inicio` com `defesa`), sustentada até
##     soltar os dedos;
##   - espalhando (o dedo extra se afasta do dedo do caminho em
##     `especial_abre_px`) e sem dominância vertical → especial.
## - Se o segundo dedo chega ANTES de o caminho começar a desenhar (menos de
##   `desenho_min_ms`), o gesto inteiro é de AÇÃO: o traço é cancelado
##   (`caminho_cancelar`) e o dedo do caminho não desenha — dois dedos não
##   deixam passo para trás.
##
## Sozinho, o dedo do caminho ainda faz: toque (travar mira), toque duplo
## (pular) e segurar em cima dela parado (escavar).
##
## Cada evento: {gesto, inicio, fim, vetor, pontos, duracao_ms, na_criatura,
## defesa}. Posições em pixels de TELA.

var lim: Dictionary
var _agora := 0.0

# --- dedo do caminho ---
var _caminho := -1
var _caminho_pode := false
var _desenhando := false
var _t_desenho := 0.0
var _pontos := PackedVector2Array()
var _tempos: Array[float] = []
var _t0 := 0.0
var _inicio := Vector2.ZERO
var _na_criatura := false
var _segurando := false
var _criatura := Vector2.ZERO
var _um_dedo := true
var _ultimo_toque_t := -1.0e9
var _ultimo_toque_pos := Vector2.ZERO

# --- dedos de ação ---
var _acao_dedos: Array[int] = []
var _acao_inicio: Dictionary = {}
var _acao_t0 := 0.0
var _acao_feita := false
var _defendendo := false
var _pos: Dictionary = {}


func _init(limiares: Dictionary = {}) -> void:
	lim = {
		"toque_max_px": 16.0, "toque_max_ms": 260.0, "toque_duplo_janela_ms": 340.0,
		"toque_duplo_dist_px": 70.0, "segurar_min_ms": 380.0,
		"desenho_min_px": 16.0, "desenho_min_ms": 150.0,
		"acao_min_px": 44.0, "acao_max_ms": 700.0, "especial_abre_px": 70.0,
		"na_criatura_raio_px": 70.0,
	}
	for k in limiares:
		lim[k] = float(limiares[k])


func ativo() -> bool:
	return _caminho != -1 or not _acao_dedos.is_empty()


## O dedo do caminho já virou traço? (o jogo alimenta a rota ao vivo)
func desenhando() -> bool:
	return _desenhando


## O mundo está em "planejamento" (tempo lento)? Só o desenho CONFIRMADO
## (mais de `desenho_min_ms`) conta: um gesto de dois dedos não escurece a tela.
func planejando() -> bool:
	return (_desenhando and _agora - _t_desenho >= float(lim["desenho_min_ms"])) \
		or _defendendo or _segurando


func defendendo() -> bool:
	return _defendendo


## Ponto de TELA onde o dedo do caminho desceu (a origem, em mundo, é congelada
## por quem converte).
func inicio() -> Vector2:
	return _inicio


func pontos() -> PackedVector2Array:
	return _pontos.duplicate()


# ---------------------------------------------------------------- dedos

func iniciar(dedo: int, pos: Vector2, t_ms: float, criatura: Vector2) -> Array:
	_agora = t_ms
	_pos[dedo] = pos
	if _caminho == -1 and _acao_dedos.is_empty():
		return _iniciar_caminho(dedo, pos, t_ms, criatura)
	return _iniciar_acao(dedo, pos, t_ms)


func mover(dedo: int, pos: Vector2, t_ms: float) -> Array:
	_agora = t_ms
	_pos[dedo] = pos
	if dedo == _caminho:
		_mover_caminho(pos, t_ms)
		return []
	if dedo in _acao_dedos:
		return _ler_acao(t_ms)
	return []


func soltar(dedo: int, pos: Vector2, t_ms: float) -> Array:
	_agora = t_ms
	_pos[dedo] = pos
	var evs: Array = []
	if dedo in _acao_dedos:
		_acao_dedos.erase(dedo)
		_acao_inicio.erase(dedo)
		_pos.erase(dedo)
		if _defendendo and _acao_dedos.is_empty():
			_defendendo = false
			evs.append(_evento_acao("segurar_fim", Vector2.ZERO, t_ms))
		if _acao_dedos.is_empty():
			_acao_feita = false  # soltou tudo: um novo gesto de ação pode começar
		return evs
	if dedo == _caminho:
		evs.append_array(_soltar_caminho(pos, t_ms))
		_caminho = -1
		_desenhando = false
		_caminho_pode = false
		_pos.erase(dedo)
		# levantou o dedo do caminho: o gesto termina, inclusive a ação
		if not _acao_dedos.is_empty():
			if _defendendo:
				_defendendo = false
				evs.append(_evento_acao("segurar_fim", Vector2.ZERO, t_ms))
			_acao_dedos = []
			_acao_inicio = {}
			_acao_feita = false
		return evs
	return []


## Chamar a cada quadro com os dedos parados: escavar (segurar nela parado).
func tick(t_ms: float) -> Array:
	_agora = t_ms
	if _caminho == -1 or _desenhando or _defendendo or _segurando:
		return []
	if _um_dedo and _na_criatura and t_ms - _t0 >= float(lim["segurar_min_ms"]) \
			and _desvio_max() <= float(lim["toque_max_px"]):
		_segurando = true
	return []


# ---------------------------------------------------------------- caminho

func _iniciar_caminho(dedo: int, pos: Vector2, t_ms: float, criatura: Vector2) -> Array:
	_caminho = dedo
	_caminho_pode = true
	_desenhando = false
	_pontos = PackedVector2Array([pos])
	_tempos = [t_ms]
	_t0 = t_ms
	_inicio = pos
	_criatura = criatura
	_na_criatura = pos.distance_to(criatura) <= float(lim["na_criatura_raio_px"])
	_segurando = false
	_um_dedo = true
	return []


func _mover_caminho(pos: Vector2, t_ms: float) -> void:
	if not _caminho_pode:
		return
	if _pontos[_pontos.size() - 1].distance_to(pos) > 1.0:
		_pontos.append(pos)
		_tempos.append(t_ms)
	if not _desenhando and pos.distance_to(_inicio) > float(lim["desenho_min_px"]):
		_desenhando = true
		_t_desenho = t_ms


func _soltar_caminho(pos: Vector2, t_ms: float) -> Array:
	if _pontos[_pontos.size() - 1] != pos:
		_pontos.append(pos)
		_tempos.append(t_ms)
	var dur := t_ms - _t0
	if _desenhando:
		_desenhando = false
		return [_evento("trajetoria", t_ms)]
	if _segurando:
		_segurando = false
		return [_evento("segurar_inicio", t_ms)]
	if not _um_dedo:
		return []  # gesto de dois dedos nunca vira toque
	if _desvio_max() > float(lim["toque_max_px"]) or dur > float(lim["toque_max_ms"]):
		return [_evento("nada", t_ms)]
	var saida := [_evento("toque", t_ms)]
	if t_ms - _ultimo_toque_t <= float(lim["toque_duplo_janela_ms"]) and pos.distance_to(_ultimo_toque_pos) <= float(lim["toque_duplo_dist_px"]):
		saida.append(_evento("toque_duplo", t_ms))
		_ultimo_toque_t = -1.0e9  # o terceiro toque não vira outro duplo
	else:
		_ultimo_toque_t = t_ms
		_ultimo_toque_pos = pos
	return saida


# ---------------------------------------------------------------- ação

func _iniciar_acao(dedo: int, pos: Vector2, t_ms: float) -> Array:
	_um_dedo = false
	_acao_dedos.append(dedo)
	_acao_inicio[dedo] = pos
	if _acao_dedos.size() == 1:
		_acao_t0 = t_ms
		_acao_feita = false
	# Segundo dedo ANTES de o caminho desenhar: o gesto é de AÇÃO, o traço cai.
	if _caminho != -1 and _desenhando and t_ms - _t_desenho < float(lim["desenho_min_ms"]):
		_desenhando = false
		_caminho_pode = false
		return [{"gesto": "caminho_cancelar", "inicio": _inicio, "fim": pos,
			"vetor": pos - _inicio, "pontos": PackedVector2Array([_inicio, pos]),
			"duracao_ms": t_ms - _t0, "na_criatura": false, "defesa": false}]
	if not _desenhando:
		_caminho_pode = false
	return []


## O gesto de ação é lido no DEDO EXTRA (o do caminho desconta). Um gesto
## dispara uma vez; a defesa fica até soltar.
func _ler_acao(t_ms: float) -> Array:
	if _defendendo or _acao_feita:
		return []
	var d := _deslocamento()
	if d.length() < float(lim["acao_min_px"]):
		return []
	var rapido: bool = t_ms - _acao_t0 <= float(lim["acao_max_ms"])
	if absf(d.y) >= absf(d.x):
		if d.y < 0.0:
			if not rapido:
				return []
			_acao_feita = true
			return [_evento_acao("deslize", d, t_ms)]
		_defendendo = true
		return [_evento_acao("segurar_inicio", d, t_ms, true)]
	# lateral: espalhou para fora? (o dedo extra afastou-se do do caminho)
	if rapido and _abriu() >= float(lim["especial_abre_px"]):
		_acao_feita = true
		return [_evento_acao("especial", d, t_ms)]
	return []


## Deslocamento médio dos dedos de ação desde que desceram.
func _deslocamento() -> Vector2:
	if _acao_dedos.is_empty():
		return Vector2.ZERO
	var soma := Vector2.ZERO
	for i in _acao_dedos:
		soma += Vector2(_pos[i]) - Vector2(_acao_inicio[i])
	return soma / float(_acao_dedos.size())


## Quanto os dedos de ação se afastaram do dedo do caminho desde o começo.
func _abriu() -> float:
	if _caminho == -1 or _acao_dedos.is_empty():
		return 0.0
	var p := Vector2(_pos[_caminho])
	var atual := 0.0
	var inicial := 0.0
	for i in _acao_dedos:
		atual = maxf(atual, Vector2(_pos[i]).distance_to(p))
		inicial = maxf(inicial, Vector2(_acao_inicio[i]).distance_to(_inicio))
	return atual - inicial


func _evento_acao(gesto: String, d: Vector2, t_ms: float, defesa := false) -> Dictionary:
	var ini := Vector2.ZERO
	var fim := Vector2.ZERO
	for i in _acao_dedos:
		ini += Vector2(_acao_inicio[i])
		fim += Vector2(_pos[i])
	var n := maxf(float(_acao_dedos.size()), 1.0)
	ini /= n
	fim /= n
	return {
		"gesto": gesto, "inicio": ini, "fim": fim,
		"vetor": d if d != Vector2.ZERO else (fim - ini),
		"pontos": PackedVector2Array([ini, fim]), "duracao_ms": t_ms - _acao_t0,
		"na_criatura": false, "defesa": defesa,
	}


# ---------------------------------------------------------------- interno

func _evento(gesto: String, t_ms: float) -> Dictionary:
	var ini := _pontos[0]
	var fim := _pontos[_pontos.size() - 1]
	return {
		"gesto": gesto, "inicio": ini, "fim": fim, "vetor": fim - ini,
		"pontos": _pontos.duplicate(), "duracao_ms": t_ms - _t0,
		"na_criatura": _na_criatura, "defesa": false,
	}


func _desvio_max() -> float:
	var m := 0.0
	for p in _pontos:
		m = maxf(m, p.distance_to(_pontos[0]))
	return m
