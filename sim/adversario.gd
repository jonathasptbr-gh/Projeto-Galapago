extends RefCounted
## ADVERSÁRIO — LÓGICA PURA. Desligado (hostilidade falsa) é o de sempre:
## vagueia pelo mapa, leva empurrão e PISCA. **HOSTIL** (v0.14, botão da HUD),
## ele CAÇA e ataca com PREPARAÇÃO + ÁREA DEMARCADA NO CHÃO:
##
## - **bote** (perto): um CÍRCULO no chão, no lugar onde o jogador estava. Quem
##   sai da área antes do fim do preparo não é atingido;
## - **esbarrão** (médio): uma FAIXA na direção do jogador; ele CORRE por ela e
##   quem estiver no caminho leva o empurrão mais forte;
## - **cuspe** (longe): uma LINHA fina; o projétil anda por ela e acerta quem
##   continuar nela;
## - **esconder** (especial): ao levar um golpe, ele afunda, fica **intocável**
##   por `fases[1]` s e reaparece perto do jogador. Não tem vida nem dano — o
##   efeito do golpe é **empurrão + atordoamento** (decisão do operador).
##
## A preparação é a MESMA ideia do `dados/acoes.json` da criatura: `fases` =
## [preparo, ativo, recuperação]. Três coisas ficam expostas para a tela:
## `perigos` (as áreas demarcadas), `efeitos` (o projétil do cuspe) e `eventos`.
##
## O ataque chama `corpo.levar_golpe(...)` (sim/corpo.gd) — a `sim/` inteira é
## pura e testável. Sem `corpo`, ele não caça (testes do passeio continuam).
##
## Sorteio com semente: a mesma semente dá sempre o mesmo passeio E a mesma
## caçada (testes e demo são determinísticos). Não entra na água: cada passo é
## cortado pelas regras do mundo.

const Mundo := preload("res://sim/mundo.gd")

const RAIO_ALVO := 14.0           # corpo do jogador, para o golpe acertar
const DASH_BOTE := 520.0          # px/s do avanço curto do bote

var pos := Vector2.ZERO
var raio := 15.0
var velocidade := 26.0
var olhar := Vector2.RIGHT
var rng := RandomNumberGenerator.new()

# hostilidade (o botão da HUD manda; a regra é daqui)
var hostil := false

# o que a tela desenha
var perigos: Array = []           # áreas demarcadas no chão (a preparação)
var efeitos: Array = []           # projéteis do cuspe
var eventos: Array[String] = []

var _defs: Dictionary = {}
var _mov: Dictionary = {}
var _acoes: Dictionary = {}

var _destino := Vector2.ZERO
var _espera := 0.0
var _limite := Rect2()
# resposta ao golpe
var _empurrao := Vector2.ZERO      # distância que ainda falta deslizar
var _pisca_t := 0.0
var forca_empurrao := 260.0        # px/s com que o empurrão sai
var pisca_dur := 0.24              # s

# máquina de estados: vagar | cacar | preparar | golpe | recuperar |
# esconder | escondido | emergir
var _estado := "vagar"
var _acao := ""
var _fase_t := 0.0
var _fase_dur := 0.0
var _perigo: Dictionary = {}
var _dash_dir := Vector2.RIGHT
var _dash_restante := 0.0
var _acertou := false
var _recargas := {}
var _tempo := 0.0
var _ronda_lado := 1.0
var _ronda_t := 0.0
var _quer_esconder := false
var _oculto := false


func _init(semente := 1, mapa_limite := Rect2(), definicoes: Dictionary = {}) -> void:
	rng.seed = semente
	_limite = mapa_limite
	_destino = pos
	_defs = definicoes
	_mov = definicoes.get("movimento", {})
	_acoes = definicoes.get("acoes", {})
	velocidade = float(_mov.get("velocidade", 26.0))
	if not _acoes.is_empty():
		_ronda_lado = 1.0 if rng.randf() < 0.5 else -1.0
		_ronda_t = rng.randf_range(1.8, 3.6)


# ---------------------------------------------------------------- consultas

func drenar_eventos() -> Array[String]:
	var e := eventos
	eventos = []
	return e


## Ligado pela HUD: liga/desliga a hostilidade e limpa o que estava em curso.
func definir_hostil(v: bool) -> void:
	if hostil == v:
		return
	hostil = v
	_acao = ""
	_perigo = {}
	perigos.clear()
	_quer_esconder = false
	_fase_t = 0.0
	if v:
		_estado = "cacar"
		_espera = 0.0
		eventos.append("hostil:on")
	else:
		# sair da hostilidade tira o esconderijo e volta ao passeio
		_oculto = false
		_estado = "vagar"
		_destino = pos
		_espera = 0.0
		eventos.append("hostil:off")


func estado_atual() -> String:
	return _estado


func acao_atual() -> String:
	return _acao


func preparando() -> bool:
	return _estado == "preparar"


func oculto() -> bool:
	return _oculto


## Pode ser travado/marcado pelo jogador? Escondido, não.
func alvo_visivel() -> bool:
	return not _oculto


## Fase do preparo em 0..1 (a tela usa para encher a área demarcada).
func progresso_preparo() -> float:
	if _fase_dur <= 0.001:
		return 0.0
	return clampf(_fase_t / _fase_dur, 0.0, 1.0)


# ---------------------------------------------------------------- passeio

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
## Hostil: o golpe CANCELA um ataque em preparo e, se a recarga deixar, ele
## foge para o especial (ESCONDER) assim que o empurrão acabar.
func empurrar(dir: Vector2, forca_px: float) -> void:
	if dir.length() < 0.001:
		dir = -olhar if olhar.length() > 0.01 else Vector2.RIGHT
	_empurrao += dir.normalized() * maxf(forca_px, 0.0)
	_pisca_t = pisca_dur
	if _estado == "preparar" or _estado == "golpe":
		_acao = ""
		_perigo = {}
		perigos.clear()
		_estado = "recuperar"
		_fase_t = 0.0
		_fase_dur = 0.22
	if hostil and _pode_esconder():
		_quer_esconder = true


func piscando() -> bool:
	return _pisca_t > 0.0


func empurrado() -> bool:
	return _empurrao.length() > 0.01


# ---------------------------------------------------------------- passo

func passo(dt: float, mundo: RefCounted, corpo: Variant = null) -> void:
	_tempo += dt
	_pisca_t = maxf(_pisca_t - dt, 0.0)
	for k in _recargas.keys():
		_recargas[k] = maxf(0.0, float(_recargas[k]) - dt)
	_atualizar_cuspe(dt, corpo)
	if _empurrao.length() > 0.01:
		_deslizar_empurrao(dt, mundo)
		return
	if not hostil:
		if _estado != "vagar":
			_estado = "vagar"
			_oculto = false
			_acao = ""
			_perigo = {}
			perigos.clear()
		_vagar(dt, mundo)
		return
	# hostil sem alvo (jogador no subsolo, por exemplo): passeia
	if corpo == null and _estado in ["vagar", "cacar"]:
		_estado = "vagar"
		_vagar(dt, mundo)
		return
	if _estado == "vagar":
		_estado = "cacar"
	# reação ao golpe: esconder assim que o empurrão acabar
	if _quer_esconder and _pode_esconder():
		_quer_esconder = false
		_iniciar_esconder()
		return
	match _estado:
		"cacar":
			_cacar(dt, mundo, corpo)
		"preparar":
			_preparar(dt, mundo, corpo)
		"golpe":
			_golpe(dt, mundo, corpo)
		"recuperar":
			_recuperar(dt)
		"esconder":
			_esconder_fase(dt)
		"escondido":
			_escondido_fase(dt, mundo, corpo)
		"emergir":
			_emergir_fase(dt, mundo, corpo)


## O passeio de sempre (mesma semente, mesmo caminho).
func _vagar(dt: float, mundo: RefCounted) -> void:
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
	var novo: Vector2 = mundo.limitar_segmento(pos, pos + passo_v, Mundo.SUPERFICIE)
	if novo.distance_to(pos) < 0.01:
		_espera = rng.randf_range(0.4, 1.0)
		return
	olhar = (novo - pos).normalized()
	pos = novo
	_limitar()


# ---------------------------------------------------------------- caçada

func _cacar(dt: float, mundo: RefCounted, corpo: Variant) -> void:
	var alvo: Vector2 = corpo.pos
	var para := alvo - pos
	var d := para.length()
	_olhar_para(para, dt)
	var nome := _escolher_acao(d)
	if nome != "":
		_comecar_acao(nome, d, alvo)
		return
	var caca := float(_mov.get("velocidade_hostil", 104.0))
	var ronda := float(_mov.get("ronda_px", 88.0))
	var recuo := float(_mov.get("recuo_px", 46.0))
	if para.length() < 0.01:
		return
	var dir := para.normalized()
	if d > ronda + 26.0:
		# aproxima em ZIGUE-ZAGUE (a caçada não é uma reta)
		var onda := deg_to_rad(float(_mov.get("serpentear_graus", 22.0))) \
			* sin(_tempo * TAU * float(_mov.get("serpentear_hz", 0.6)))
		_andar(dir.rotated(onda), caca, dt, mundo)
	elif d < recuo:
		# abre espaço de lado (não recua de costas)
		_andar((-dir + dir.orthogonal() * 0.7 * _ronda_lado).normalized(), caca, dt, mundo)
	else:
		# RONDA em volta do jogador, corrigindo o raio
		_ronda_t -= dt
		if _ronda_t <= 0.0:
			_ronda_lado *= -1.0
			_ronda_t = rng.randf_range(1.8, 3.6)
		var tang := dir.orthogonal() * _ronda_lado
		var radial := dir * clampf((d - ronda) / 36.0, -0.8, 0.8)
		_andar((tang + radial).normalized(), float(_mov.get("velocidade_ronda", 82.0)), dt, mundo)


## A ação que serve NESTA distância e está fora da recarga; sorteio entre as
## válidas (mais de uma quando as faixas se sobrepõem).
func _escolher_acao(d: float) -> String:
	var validas: Array[String] = []
	for nome in ["bote", "esbarrao", "cuspe"]:
		if _acao_valida(nome, d):
			validas.append(nome)
	if validas.is_empty():
		return ""
	if validas.size() == 1:
		return validas[0]
	return validas[rng.randi_range(0, validas.size() - 1)]


func _acao_valida(nome: String, d: float) -> bool:
	var a: Dictionary = _acoes.get(nome, {})
	if a.is_empty():
		return false
	if float(_recargas.get(nome, 0.0)) > 0.0:
		return false
	return d >= float(a.get("dist_min", 0.0)) and d <= float(a.get("dist_max", 1e9))


## Fixa a ÁREA DEMARCADA no chão e começa o preparo. O inimigo para e olha na
## direção do golpe — não persegue enquanto prepara (é a janela de esquiva).
func _comecar_acao(nome: String, d: float, alvo: Vector2) -> void:
	var a: Dictionary = _acoes[nome]
	var f: Array = a.get("fases", [0.6, 0.15, 0.4])
	_acao = nome
	_estado = "preparar"
	_fase_t = 0.0
	_fase_dur = maxf(float(f[0]), 0.05)
	_acertou = false
	var dir := alvo - pos
	if dir.length() < 0.01:
		dir = olhar if olhar.length() > 0.01 else Vector2.RIGHT
	dir = dir.normalized()
	olhar = dir
	var p := {
		"tipo": nome, "forma": "circulo", "pos": alvo, "dir": dir,
		"raio": float(a.get("raio", 30.0)), "alcance": 0.0, "largura": 0.0,
		"t": 0.0, "preparo": _fase_dur, "ativo": false,
	}
	match nome:
		"bote":
			p["forma"] = "circulo"
			p["pos"] = alvo
			p["raio"] = float(a.get("raio", 30.0))
		"esbarrao":
			p["forma"] = "faixa"
			p["pos"] = pos
			p["alcance"] = minf(float(a.get("alcance", 230.0)), d + 44.0)
			p["largura"] = float(a.get("largura", 34.0))
		"cuspe":
			p["forma"] = "linha"
			p["pos"] = pos
			p["alcance"] = float(a.get("alcance", 340.0))
			p["largura"] = float(a.get("raio", 9.0)) * 2.0
	_perigo = p
	perigos.clear()
	perigos.append(p)
	eventos.append("perigo:" + nome)


func _preparar(dt: float, _mundo: RefCounted, corpo: Variant) -> void:
	_fase_t += dt
	if not _perigo.is_empty():
		_perigo["t"] = _fase_t
	if _fase_t < _fase_dur:
		return
	var a: Dictionary = _acoes[_acao]
	var f: Array = a.get("fases", [0.6, 0.15, 0.4])
	_estado = "golpe"
	_fase_t = 0.0
	_fase_dur = maxf(float(f[1]), 0.03)
	if not _perigo.is_empty():
		_perigo["ativo"] = true
	_recargas[_acao] = float(a.get("recarga", 2.0))
	match _acao:
		"bote":
			_bater_bote(corpo, a)
		"esbarrao":
			_dash_dir = Vector2(_perigo.get("dir", olhar))
			_dash_restante = float(_perigo.get("alcance", 0.0))
			# a CORRIDA dura o que a faixa demarca (não corta no meio do caminho)
			var vel := maxf(float(a.get("velocidade", 380.0)), 1.0)
			_fase_dur = maxf(_fase_dur, _dash_restante / vel)
		"cuspe":
			_cuspir(a)


## O bote acerta quem ainda estiver DENTRO do círculo no fim do preparo.
func _bater_bote(corpo: Variant, a: Dictionary) -> void:
	var centro := Vector2(_perigo.get("pos", pos))
	var raio_golpe := float(_perigo.get("raio", 30.0))
	var dir := Vector2(_perigo.get("dir", olhar))
	if corpo != null and corpo.pos.distance_to(centro) <= raio_golpe + RAIO_ALVO:
		var empurro: Vector2 = corpo.pos - centro
		if empurro.length() < 0.5:
			empurro = corpo.pos - pos
		if empurro.length() < 0.5:
			empurro = dir
		if corpo.levar_golpe(empurro, float(a.get("empurrao", 70.0)), float(a.get("atordoamento", 0.45))):
			_acertou = true
			eventos.append("acerta:bote")
	# avança até o círculo (dá a leitura de que ele "deu o bote")
	var para := centro - pos
	_dash_dir = para.normalized() if para.length() > 1.0 else dir
	_dash_restante = float(a.get("avanca_px", 34.0))


func _golpe(dt: float, mundo: RefCounted, corpo: Variant) -> void:
	_fase_t += dt
	var a: Dictionary = _acoes.get(_acao, {})
	match _acao:
		"bote":
			if _dash_restante > 0.01:
				_dash_restante -= _deslizar(_dash_dir, minf(DASH_BOTE * dt, _dash_restante), mundo)
		"esbarrao":
			if _dash_restante > 0.01:
				var antes := pos
				var quanto := minf(float(a.get("velocidade", 380.0)) * dt, _dash_restante)
				var andado := _deslizar(_dash_dir, quanto, mundo)
				_dash_restante -= andado
				if corpo != null and not _acertou \
						and _dist_segmento(corpo.pos, antes, pos) <= float(_perigo.get("largura", 34.0)) * 0.5 + RAIO_ALVO:
					if corpo.levar_golpe(_dash_dir, float(a.get("empurrao", 96.0)), float(a.get("atordoamento", 0.65))):
						_acertou = true
						eventos.append("acerta:esbarrao")
						_dash_restante = 0.0
				if andado < 0.01:
					_dash_restante = 0.0
		"cuspe":
			pass
	if _fase_t >= _fase_dur:
		_terminar_golpe()


func _terminar_golpe() -> void:
	perigos.clear()
	_perigo = {}
	_estado = "recuperar"
	_fase_t = 0.0
	var a: Dictionary = _acoes.get(_acao, {})
	var f: Array = a.get("fases", [0.6, 0.15, 0.4])
	_fase_dur = maxf(float(f[2]), 0.05)


func _recuperar(dt: float) -> void:
	_fase_t += dt
	if _fase_t >= _fase_dur:
		_estado = "cacar"
		_acao = ""
		_fase_t = 0.0


## O projétil do cuspe anda sozinho (a `sim/` decide o acerto). Quem estiver
## fora da linha não é atingido.
func _cuspir(a: Dictionary) -> void:
	var dir := Vector2(_perigo.get("dir", olhar))
	efeitos.append({
		"tipo": "cuspe", "pos": pos + dir * 16.0, "dir": dir,
		"raio": float(a.get("raio", 9.0)),
		"velocidade": float(a.get("velocidade", 280.0)),
		"alcance": float(a.get("alcance", 340.0)),
		"andado": 0.0,
	})


func _atualizar_cuspe(dt: float, corpo: Variant) -> void:
	for e in efeitos.duplicate():
		var quanto := float(e["velocidade"]) * dt
		e["pos"] = Vector2(e["pos"]) + Vector2(e["dir"]) * quanto
		e["andado"] = float(e["andado"]) + quanto
		var bateu := false
		if corpo != null and Vector2(e["pos"]).distance_to(corpo.pos) <= float(e["raio"]) + RAIO_ALVO:
			var a: Dictionary = _acoes.get("cuspe", {})
			if corpo.levar_golpe(Vector2(e["dir"]), float(a.get("empurrao", 40.0)), float(a.get("atordoamento", 0.3))):
				eventos.append("acerta:cuspe")
			bateu = true
		if bateu or float(e["andado"]) >= float(e["alcance"]):
			efeitos.erase(e)


# ---------------------------------------------------------------- esconder

func _pode_esconder() -> bool:
	if not _acoes.has("esconder"):
		return false
	if float(_recargas.get("esconder", 0.0)) > 0.0:
		return false
	return _estado != "esconder" and _estado != "escondido" and _estado != "emergir"


func _iniciar_esconder() -> void:
	var a: Dictionary = _acoes.get("esconder", {})
	var f: Array = a.get("fases", [0.35, 2.0, 0.45])
	_acao = "esconder"
	_estado = "esconder"
	_fase_t = 0.0
	_fase_dur = maxf(float(f[0]), 0.05)
	_oculto = true
	_perigo = {}
	perigos.clear()
	eventos.append("esconde:prepara")


func _esconder_fase(dt: float) -> void:
	_fase_t += dt
	if _fase_t < _fase_dur:
		return
	var c: Dictionary = _acoes.get("esconder", {})
	var f: Array = c.get("fases", [0.35, 2.0, 0.45])
	_estado = "escondido"
	_fase_t = 0.0
	_fase_dur = maxf(float(f[1]), 0.1)
	eventos.append("esconde:on")


func _escondido_fase(dt: float, mundo: RefCounted, corpo: Variant) -> void:
	_fase_t += dt
	if _fase_t < _fase_dur:
		return
	var c: Dictionary = _acoes.get("esconder", {})
	var f: Array = c.get("fases", [0.35, 2.0, 0.45])
	_estado = "emergir"
	_fase_t = 0.0
	_fase_dur = maxf(float(f[2]), 0.05)
	_reaparecer(mundo, corpo)
	eventos.append("esconde:sai")


func _emergir_fase(dt: float, _mundo: RefCounted, _corpo: Variant) -> void:
	_fase_t += dt
	if _fase_t < _fase_dur:
		return
	_oculto = false
	_estado = "cacar"
	_acao = ""
	_fase_t = 0.0
	var c: Dictionary = _acoes.get("esconder", {})
	_recargas["esconder"] = float(c.get("recarga", 7.0))
	eventos.append("esconde:off")


## Reaparece a uma distância do jogador, em chão andável (sorteio com semente).
func _reaparecer(mundo: RefCounted, corpo: Variant) -> void:
	var alvo := pos
	if corpo != null:
		alvo = Vector2(corpo.pos)
	var c: Dictionary = _acoes.get("esconder", {})
	var dist := float(c.get("reaparecer_px", 110.0))
	for _i in 16:
		var ang := rng.randf_range(0.0, TAU)
		var d := rng.randf_range(dist * 0.7, dist * 1.3)
		var p: Vector2 = alvo + Vector2.from_angle(ang) * d
		if mundo.andavel(mundo.celula_de(p), Mundo.SUPERFICIE):
			pos = p
			if alvo.distance_to(p) > 1.0:
				olhar = (alvo - p).normalized()
			_limitar()
			return


# ---------------------------------------------------------------- movimento

## Anda `velocidade_px` na direção pedida; se o passo for barrado, contorna.
## Não mexe no `olhar` (a caçada olha para o jogador; o passeio, para onde anda).
func _andar(direcao: Vector2, velocidade_px: float, dt: float, mundo: RefCounted) -> bool:
	if direcao.length() < 0.01:
		return false
	var d := direcao.normalized()
	var quanto := maxf(velocidade_px * dt, 0.0)
	var novo: Vector2 = mundo.limitar_segmento(pos, pos + d * quanto, Mundo.SUPERFICIE)
	if novo.distance_to(pos) < 0.01:
		for ang in [35.0, -35.0, 70.0, -70.0, 110.0, -110.0]:
			var alt := d.rotated(deg_to_rad(ang))
			novo = mundo.limitar_segmento(pos, pos + alt * quanto, Mundo.SUPERFICIE)
			if novo.distance_to(pos) > 0.01:
				break
	if novo.distance_to(pos) < 0.01:
		return false
	pos = novo
	_limitar()
	return true


## Desliza `quanto` px e devolve o que andou (bote/esbarrão).
func _deslizar(dir: Vector2, quanto: float, mundo: RefCounted) -> float:
	if quanto <= 0.0:
		return 0.0
	var antes := pos
	pos = mundo.limitar_segmento(pos, pos + dir * quanto, Mundo.SUPERFICIE)
	var andado := pos.distance_to(antes)
	_limitar()
	return andado


func _deslizar_empurrao(dt: float, mundo: RefCounted) -> void:
	var dir := _empurrao.normalized()
	var quanto := minf(forca_empurrao * dt, _empurrao.length())
	var novo: Vector2 = mundo.limitar_segmento(pos, pos + dir * quanto, Mundo.SUPERFICIE)
	var andado := novo.distance_to(pos)
	pos = novo
	_empurrao -= dir * andado
	if andado < 0.01:
		_empurrao = Vector2.ZERO
	_limitar()


func _limitar() -> void:
	if _limite.size != Vector2.ZERO:
		pos = pos.clamp(_limite.position, _limite.end - Vector2.ONE)


## Olhar suavizado (o jogador pode andar 2 px por quadro; o bicho não pisca).
func _olhar_para(dir: Vector2, dt: float) -> void:
	if dir.length() < 0.01:
		return
	var desejado := dir.normalized().angle()
	var atual := olhar.angle() if olhar.length() > 0.01 else desejado
	var avanco := wrapf(desejado - atual, -PI, PI) \
		* clampf(dt * float(_mov.get("giro_suavidade", 7.0)), 0.0, 1.0)
	var teto := deg_to_rad(float(_mov.get("giro_max_graus_s", 540.0))) * dt
	if teto > 0.0:
		avanco = clampf(avanco, -teto, teto)
	olhar = Vector2.from_angle(atual + avanco)


static func _dist_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	if ab.length_squared() < 1e-6:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)
