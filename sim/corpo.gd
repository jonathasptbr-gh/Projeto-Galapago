extends RefCounted
## O CORPO da criatura — LÓGICA PURA, avançada por `passo(dt, mundo, alvos)`.
##
## DUAS COISAS ANDAM JUNTAS (é o que este arquivo garante):
##
## - a **ROTA** (o traço riscado): a criatura segue até o fim. Só perde a rota
##   se o jogador riscar OUTRA, se defender (que a PARA, sem apagar) ou se
##   escavar (troca de camada, e a rota não vale mais lá);
## - os **OVERLAYS** (ataque, esquiva, pulo), que acontecem POR CIMA da rota
##   sem cancelá-la: a esquiva desloca para o lado e volta (corrige a rota); o
##   pulo é um arco enquanto ela continua andando; o ataque vira para o alvo (ou
##   para a direção da rota) e NÃO para o movimento.
##
## Sem rota, entra em **AUTONOMIA**: parada, vagueando devagar, indo até o alvo
## marcado ou rondando ao redor dele. A escolha é sorteio com semente
## (determinístico para teste, demo e oráculo).
##
## O ALVO marcado (`alvo_id`) é resolvido pela lista de sim/alvos.gd a cada
## quadro — mirar num adversário que anda funciona.

const Mundo := preload("res://sim/mundo.gd")
const Trajetoria := preload("res://sim/trajetoria.gd")
const Alvos := preload("res://sim/alvos.gd")

# --- estado ---
var defs: Dictionary = {}
var pos := Vector2.ZERO          # posição no chão, já com o desvio da esquiva
var z := 0.0                     # altura no ar (pulo)
var olhar := Vector2.RIGHT
var camada := Mundo.SUPERFICIE
var velocidade := 110.0

# rota
var rota := PackedVector2Array()
var rota_t := 0.0
var total_rota := 0.0

# overlays
var desvio := Vector2.ZERO
var _pulo_t := 0.0
var _pulo_dur := 0.0
var _pulo_altura := 0.0
var _esquiva_t := 0.0
var _esquiva_dur := 0.0
var _esquiva_lado := Vector2.ZERO
var _esquiva_amplitude := 0.0
var ataque := ""                 # "" = nenhum
var ataque_t := 0.0
var ataque_dir := Vector2.RIGHT
var defendendo := false
var escavando := false
var _recargas := {}

# alvo e autonomia
var alvo_id := ""
var alvo_tipo := ""
var autonomia := "parado"        # parado | vagar | aproximar | rondar
var _auto_t := 0.0
var _auto_destino := Vector2.ZERO
var _auto_espera := 0.0
var rng := RandomNumberGenerator.new()

var eventos: Array[String] = []


func _init(definicoes: Dictionary = {}) -> void:
	defs = definicoes
	velocidade = float(defs.get("mover", {}).get("velocidade", 110.0))


# ---------------------------------------------------------------- consultas

func em_rota() -> bool:
	return rota.size() >= 2 and rota_t < total_rota - 0.01


func em_autonomia() -> bool:
	return not em_rota()


## Golpe valendo agora (fase ativa)? A apresentação usa para desenhar o arco.
func golpe_ativo() -> Dictionary:
	if ataque == "":
		return {}
	var d: Dictionary = defs.get(ataque, {})
	var f: Array = d.get("fases", [0.1, 0.15, 0.2])
	if ataque_t < float(f[0]) or ataque_t > float(f[0]) + float(f[1]):
		return {}
	return {"alcance": float(d.get("alcance", 40.0)), "arco": float(d.get("arco", 80.0)), "dir": ataque_dir}


func no_ar() -> bool:
	return _pulo_t > 0.0


func drenar_eventos() -> Array[String]:
	var e := eventos
	eventos = []
	return e


func alvo_pos(alvos: Array) -> Vector2:
	return Alvos.pos_de(alvos, alvo_id)


# ---------------------------------------------------------------- comandos

## Recebe um comando (sim/comandos.gd). Devolve "ok", "ok: <detalhe>" ou
## "recusado: <motivo>" — quem mostra é a HUD.
func comandar(cmd: Dictionary, mundo: RefCounted, alvos: Array = []) -> String:
	var a: String = cmd.get("acao", "")
	match a:
		"mover":
			return _cmd_mover(cmd, mundo)
		"olhar":
			var v: Vector2 = cmd.get("alvo", pos) - pos
			if v.length() > 1.0:
				olhar = v.normalized()
			return "ok"
		"travar":
			return _cmd_travar(cmd, alvos)
		"ataque":
			return _cmd_ataque(cmd, alvos)
		"esquiva":
			return _cmd_esquiva(cmd)
		"pular":
			return _cmd_pular(cmd)
		"defender":
			defendendo = true
			eventos.append("defesa:on")
			return "ok: parado defendendo"
		"soltar":
			if defendendo:
				defendendo = false
				eventos.append("defesa:off")
			return "ok"
		"escavar":
			return _cmd_escavar(mundo)
	if not defs.has(a):
		return "recusado: ação desconhecida (%s)" % a
	return "recusado: nada a fazer"


func _cmd_mover(cmd: Dictionary, mundo: RefCounted) -> String:
	var pts := PackedVector2Array([pos - desvio])
	pts.append_array(cmd.get("pontos", PackedVector2Array()))
	var lim: PackedVector2Array = mundo.limitar_caminho(Trajetoria.amostrar(pts, 3.0), camada)
	if lim.size() < 2 or Trajetoria.comprimento(lim) < 6.0:
		return "recusado: caminho bloqueado"
	rota = lim
	rota_t = 0.0
	total_rota = Trajetoria.comprimento(lim)
	autonomia = ""
	_auto_destino = Vector2.ZERO
	eventos.append("rota:nova")
	return "ok: rota de %d px" % int(total_rota)


func _cmd_travar(cmd: Dictionary, alvos: Array) -> String:
	var ponto: Vector2 = cmd.get("alvo", pos)
	var achado := Alvos.mais_proximo(alvos, ponto, float(cmd.get("alcance", 110.0)))
	if achado.is_empty():
		if alvo_id != "":
			alvo_id = ""
			alvo_tipo = ""
			eventos.append("alvo:")
			return "ok: mira solta"
		return "ok: nada para travar aqui"
	if achado["id"] == alvo_id:
		alvo_id = ""
		alvo_tipo = ""
		eventos.append("alvo:")
		return "ok: mira solta"
	if achado["interativo"]:
		eventos.append("interagir:" + str(achado["id"]))
		return "ok: interagiu com %s" % achado["tipo"]
	if not achado["travavel"]:
		return "recusado: %s não é alvo" % achado["tipo"]
	alvo_id = str(achado["id"])
	alvo_tipo = str(achado["tipo"])
	eventos.append("alvo:" + alvo_id)
	return "ok: mira em %s" % alvo_tipo


func _cmd_ataque(cmd: Dictionary, alvos: Array) -> String:
	if not defs.has("ataque"):
		return "recusado: sem ataque definido"
	if float(_recargas.get("ataque", 0.0)) > 0.0:
		return "recusado: recarga"
	if ataque != "":
		return "recusado: golpe em curso"
	var d: Dictionary = defs["ataque"]
	# a direção do golpe NÃO vem do gesto: é o alvo marcado; sem alvo, a rota
	if alvo_id != "":
		var ap := alvo_pos(alvos)
		if ap != Vector2.ZERO and ap.distance_to(pos) > 1.0:
			ataque_dir = (ap - pos).normalized()
		else:
			ataque_dir = cmd.get("direcao", olhar)
	else:
		ataque_dir = Trajetoria.ponto_em(rota, minf(rota_t + 8.0, total_rota)) - Trajetoria.ponto_em(rota, rota_t) if em_rota() else olhar
		if ataque_dir.length() < 0.01:
			ataque_dir = olhar
		ataque_dir = ataque_dir.normalized()
	olhar = ataque_dir
	ataque = "ataque"
	ataque_t = 0.0
	eventos.append("golpe:" + ("alvo" if alvo_id != "" else "rota"))
	return "ok: atacando %s" % ("o alvo" if alvo_id != "" else "em frente")


func _cmd_esquiva(cmd: Dictionary) -> String:
	if float(_recargas.get("esquiva", 0.0)) > 0.0:
		return "recusado: recarga"
	var d: Dictionary = defs.get("esquiva", {"fases": [0.0, 0.18, 0.12], "deslocamento": 34.0})
	var lado := float(cmd.get("lado", 0.0))
	if lado == 0.0:
		return "recusado: esquiva sem lado"
	var frente: Vector2 = olhar if olhar.length() > 0.01 else Vector2.RIGHT
	_esquiva_lado = Vector2(-frente.y, frente.x) * signf(lado)
	_esquiva_amplitude = float(d.get("deslocamento", 34.0))
	_esquiva_dur = maxf(float(d.get("fases", [0.0, 0.18, 0.12])[1]), 0.05)
	_esquiva_t = _esquiva_dur
	eventos.append("esquiva:esq" if lado < 0.0 else "esquiva:dir")
	return "ok: esquiva para %s" % ("a esquerda" if lado < 0.0 else "a direita")


func _cmd_pular(cmd: Dictionary) -> String:
	if camada == Mundo.SUBSOLO:
		return "recusado: no subsolo não dá para pular"
	if float(_recargas.get("pular", 0.0)) > 0.0:
		return "recusado: recarga"
	if no_ar():
		return "recusado: já está no ar"
	var d: Dictionary = defs.get("pular", {"fases": [0.06, 0.42, 0.06], "altura": 26.0})
	_pulo_dur = maxf(float(d.get("fases", [0.06, 0.42, 0.06])[1]), 0.1)
	_pulo_t = _pulo_dur
	_pulo_altura = float(d.get("altura", 26.0))
	eventos.append("pulo:on")
	return "ok: pulando"


func _cmd_escavar(mundo: RefCounted) -> String:
	if escavando:
		return "recusado: escavando"
	var c: Vector2i = mundo.celula_de(pos - desvio)
	if not mundo.pode_escavar(c, camada):
		return "recusado: aqui não dá para escavar"
	escavando = true
	var d: Dictionary = defs.get("escavar", {"fases": [0.15, 0.55, 0.15]})
	_escavar_dur = maxf(float(d.get("fases", [0.15, 0.55, 0.15])[1]), 0.1)
	_escavar_t = 0.0
	_escavar_celula = c
	eventos.append("escavar:on")
	return "ok: escavando"


var _escavar_t := 0.0
var _escavar_dur := 0.0
var _escavar_celula := Vector2i.ZERO


# ---------------------------------------------------------------- avanço

func passo(dt: float, mundo: RefCounted, alvos: Array = []) -> void:
	for k in _recargas.keys():
		_recargas[k] = maxf(0.0, float(_recargas[k]) - dt)
	_atualizar_pulo(dt)
	_atualizar_esquiva(dt)
	_atualizar_ataque(dt)
	if escavando:
		_atualizar_escavar(dt, mundo)
		pos = mundo.centro(_escavar_celula) + desvio
		return
	if defendendo:
		return
	if em_rota():
		pos = _avancar_rota(dt, mundo) + desvio
	else:
		_autonomia(dt, mundo, alvos)


## Avança a rota e devolve a posição no CHÃO (sem o desvio). Quando a rota
## termina, a posição final vira o ponto de partida da autonomia — nunca
## Vector2.ZERO (era o defeito: limpar `rota` antes de ler a posição).
func _avancar_rota(dt: float, mundo: RefCounted) -> Vector2:
	rota_t = minf(rota_t + velocidade * dt, total_rota)
	var a := Trajetoria.ponto_em(rota, rota_t)
	var b := Trajetoria.ponto_em(rota, minf(rota_t + 10.0, total_rota))
	var d := b - a
	if d.length() > 0.01:
		olhar = d.normalized()
	if rota_t >= total_rota - 0.001:
		var fim := Trajetoria.ponto_em(rota, total_rota)
		rota = PackedVector2Array()
		rota_t = 0.0
		total_rota = 0.0
		_auto_destino = fim
		_auto_t = 3.3  # decide JÁ no primeiro passo de autonomia
		_auto_espera = 0.0
		eventos.append("rota:fim")
		return fim
	return a


func _autonomia(dt: float, mundo: RefCounted, alvos: Array) -> void:
	_auto_t += dt
	# `base` = posição no chão, sem o desvio da esquiva (que é só visual/lateral)
	var base: Vector2 = pos - desvio
	if _auto_espera > 0.0:
		_auto_espera -= dt
		autonomia = "parado"
		return
	# a cada ~3 s, ou ao chegar no destino, decide de novo
	if _auto_t >= 3.2 or _auto_destino.distance_to(base) < 6.0:
		_auto_t = 0.0
		_decidir_autonomia(mundo, alvos)
		base = pos - desvio
	var alvo_p := alvo_pos(alvos) if alvo_id != "" else Vector2.ZERO
	var destino := _auto_destino
	if autonomia == "aproximar":
		if alvo_p == Vector2.ZERO:
			autonomia = "vagar"
		else:
			destino = alvo_p
	elif autonomia == "rondar":
		if alvo_p == Vector2.ZERO or _auto_destino == Vector2.ZERO:
			autonomia = "vagar"
	if autonomia == "parado":
		return
	var v := destino - base
	if v.length() < 3.0:
		_auto_espera = 0.6
		return
	# vaguear e rondar são DEVAGAR; aproximar é mais rápido
	var vel := velocidade * (0.55 if autonomia == "aproximar" else 0.35)
	var passo_v := v.normalized() * minf(vel * dt, v.length())
	var novo: Vector2 = mundo.limitar_segmento(base, base + passo_v, camada)
	if novo.distance_to(base) < 0.01:
		_auto_espera = 0.5
		return
	olhar = (novo - base).normalized()
	pos = novo + desvio


func _decidir_autonomia(mundo: RefCounted, alvos: Array) -> void:
	var alvo_p := alvo_pos(alvos) if alvo_id != "" else Vector2.ZERO
	var dado := rng.randf()
	if alvo_p != Vector2.ZERO:
		var dist := (pos - desvio).distance_to(alvo_p)
		if dist > 70.0 and dado < 0.7:
			autonomia = "aproximar"
			_auto_destino = alvo_p
			return
		autonomia = "rondar" if dado < 0.8 else "parado"
		if autonomia == "rondar":
			var ang := rng.randf_range(0.0, TAU)
			_auto_destino = alvo_p + Vector2.from_angle(ang) * rng.randf_range(40.0, 70.0)
		return
	if dado < 0.45:
		autonomia = "parado"
		_auto_espera = rng.randf_range(0.8, 2.0)
		return
	autonomia = "vagar"
	for _i in 8:
		var ang := rng.randf_range(0.0, TAU)
		var p: Vector2 = (pos - desvio) + Vector2.from_angle(ang) * rng.randf_range(30.0, 80.0)
		if mundo.andavel(mundo.celula_de(p), camada):
			_auto_destino = p
			return
	autonomia = "parado"
	_auto_espera = 1.0


func _atualizar_pulo(dt: float) -> void:
	if _pulo_t <= 0.0:
		z = 0.0
		return
	_pulo_t = maxf(_pulo_t - dt, 0.0)
	var u := 1.0 - _pulo_t / maxf(_pulo_dur, 0.001)
	z = sin(PI * u) * _pulo_altura
	if _pulo_t <= 0.0:
		z = 0.0
		_recargas["pular"] = float(defs.get("pular", {}).get("recarga", 0.3))
		eventos.append("pulo:off")


func _atualizar_esquiva(dt: float) -> void:
	if _esquiva_t <= 0.0:
		desvio = Vector2.ZERO
		return
	_esquiva_t = maxf(_esquiva_t - dt, 0.0)
	var u := 1.0 - _esquiva_t / maxf(_esquiva_dur, 0.001)
	desvio = _esquiva_lado * sin(PI * u) * _esquiva_amplitude
	if _esquiva_t <= 0.0:
		desvio = Vector2.ZERO
		_recargas["esquiva"] = float(defs.get("esquiva", {}).get("recarga", 0.35))
		eventos.append("esquiva:off")


func _atualizar_ataque(dt: float) -> void:
	if ataque == "":
		return
	ataque_t += dt
	var f: Array = defs.get("ataque", {}).get("fases", [0.1, 0.15, 0.2])
	var total := float(f[0]) + float(f[1]) + float(f[2])
	if ataque_t >= total:
		ataque = ""
		ataque_t = 0.0
		_recargas["ataque"] = float(defs.get("ataque", {}).get("recarga", 0.15))
		eventos.append("golpe:fim")


func _atualizar_escavar(dt: float, mundo: RefCounted) -> void:
	_escavar_t += dt
	var d: Dictionary = defs.get("escavar", {"fases": [0.15, 0.55, 0.15]})
	var f: Array = d.get("fases", [0.15, 0.55, 0.15])
	var total := float(f[0]) + float(f[1]) + float(f[2])
	if _escavar_t >= total:
		escavando = false
		camada = mundo.escavar(_escavar_celula, camada)
		pos = mundo.centro(_escavar_celula) + desvio
		rota = PackedVector2Array()
		rota_t = 0.0
		total_rota = 0.0
		_recargas["escavar"] = float(d.get("recarga", 0.4))
		eventos.append("camada:" + camada)
