extends RefCounted
## O CORPO da criatura — LÓGICA PURA, avançada por `passo(dt, mundo, alvos)`.
##
## DUAS COISAS ANDAM JUNTAS (é o que este arquivo garante):
##
## - a **ROTA** (o traço riscado): a criatura segue até o fim. Só perde a rota
##   se o jogador riscar OUTRA, se defender (que a PARA, sem apagar) ou se
##   escavar (troca de camada, e a rota não vale mais lá). v0.6: a rota é uma
##   SÉRIE DE PONTOS de referência (sim/trajetoria.simplificar) procurados na
##   ordem; a criatura pode se desviar um pouco para contornar OBJETOS. Água,
##   rocha e altura são BARREIRAS: ela para e a rota continua guardada — um
##   pulo durante a rota passa por cima e retoma o percurso;
## - os **OVERLAYS** (ataque, especial, esquiva, pulo), que acontecem POR CIMA
##   da rota sem cancelá-la: a esquiva desloca para a direção do gesto e volta;
##   o pulo é um arco enquanto ela continua andando; o ataque vira para o alvo
##   (ou para a direção da rota) e NÃO para o movimento; o especial sai para o
##   lado do gesto (esquerda/direita da TELA).
##
## O **DESCONTO INICIAL** (sim/trajetoria.descontar_inicio) tira o vai-e-volta
## do começo do traço antes de a rota existir: a criatura se alinha a uma
## distância do início e só então obedece o desenho.
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
var rota_cfg: Dictionary = {}
var pos := Vector2.ZERO          # posição no chão, já com o desvio da esquiva
var z := 0.0                     # altura no ar (pulo)
var olhar := Vector2.RIGHT
var camada := Mundo.SUPERFICIE
var velocidade := 110.0

# rota (pontos de referência; `_rota_i` = o próximo que ela procura)
var rota := PackedVector2Array()
var rota_t := 0.0
var total_rota := 0.0
var _rota_i := 0
var _barrado := false
var _desvios := 0

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
	var rc: Dictionary = defs.get("rota", {})
	rota_cfg = rc


# ---------------------------------------------------------------- consultas

func em_rota() -> bool:
	return rota.size() >= 2 and _rota_i < rota.size()


func em_autonomia() -> bool:
	return not em_rota()


## Está parada numa barreira de terreno (a rota continua guardada)?
func barrado() -> bool:
	return _barrado


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
		"especial":
			return _cmd_especial(cmd)
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
	if pts.size() < 2:
		return "recusado: caminho vazio"
	# DESCONTO INICIAL: o pequeno vai-e-volta do começo não é obedecido. A
	# criatura se alinha a uma distância do começo e segue o resto do desenho.
	var cortado := Trajetoria.descontar_inicio(pts, float(rota_cfg.get("desconto_raio_px", 44.0)),
		float(rota_cfg.get("desconto_janela_px", 140.0)))
	if cortado.size() < pts.size() and cortado.size() >= 2:
		# se a reta até o ponto de alinhamento atravessa parede, o desvio
		# inicial era necessário: não corta.
		if mundo.caminho_livre(pts[0], cortado[1], camada):
			pts = cortado
	# PONTOS DE REFERÊNCIA, não o traço inteiro: reta vira duas pontas, curva e
	# canto continuam com alguns pontos. O corpo procura um por um e pode se
	# desviar um pouco para contornar objetos.
	var nova := Trajetoria.simplificar(pts, float(rota_cfg.get("simplificar_px", 10.0)))
	if nova.size() < 2 or Trajetoria.comprimento(nova) < 6.0:
		return "recusado: caminho curto"
	rota = nova
	_rota_i = 1
	rota_t = 0.0
	total_rota = Trajetoria.comprimento(rota)
	_barrado = false
	_desvios = 0
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
	var dir: Vector2 = olhar
	# a direção do golpe NÃO vem do gesto: é o alvo marcado; sem alvo, a rota
	if alvo_id != "":
		var ap := alvo_pos(alvos)
		if ap != Vector2.ZERO and ap.distance_to(pos) > 1.0:
			dir = (ap - pos).normalized()
		elif em_rota():
			dir = (rota[_rota_i] - (pos - desvio)).normalized()
	else:
		if em_rota():
			dir = (rota[_rota_i] - (pos - desvio)).normalized()
		else:
			dir = olhar
	return _cmd_golpe("ataque", dir)


func _cmd_especial(cmd: Dictionary) -> String:
	# o especial sai para o LADO do gesto na tela (esquerda/direita)
	var dir: Vector2 = cmd.get("direcao", olhar)
	if dir.length() < 0.01:
		dir = olhar
	return _cmd_golpe("especial", dir)


## Golpe genérico (ataque físico ou especial): mesma máquina de fases, mesma
## recarga por nome. O `ataque` guarda QUAL golpe está em curso.
func _cmd_golpe(nome: String, dir: Vector2) -> String:
	if not defs.has(nome):
		return "recusado: sem %s definido" % nome
	if float(_recargas.get(nome, 0.0)) > 0.0:
		return "recusado: recarga"
	if ataque != "":
		return "recusado: golpe em curso"
	if dir.length() < 0.01:
		dir = olhar
	ataque = nome
	ataque_t = 0.0
	ataque_dir = dir.normalized()
	olhar = ataque_dir
	eventos.append("golpe:" + nome)
	return "ok: %s" % ("atacando" if nome == "ataque" else "especial")


func _cmd_esquiva(cmd: Dictionary) -> String:
	if float(_recargas.get("esquiva", 0.0)) > 0.0:
		return "recusado: recarga"
	var d: Dictionary = defs.get("esquiva", {"fases": [0.0, 0.18, 0.12], "deslocamento": 34.0})
	# v0.6: a esquiva vai para a direção do GESTO na tela (para baixo = para
	# trás). O `lado` continua aceito para comandos antigos/testes.
	var dir: Vector2 = cmd.get("direcao", Vector2.ZERO)
	if dir.length() < 0.01:
		var lado := float(cmd.get("lado", 0.0))
		if lado == 0.0:
			return "recusado: esquiva sem direção"
		var frente: Vector2 = olhar if olhar.length() > 0.01 else Vector2.RIGHT
		dir = Vector2(-frente.y, frente.x) * signf(lado)
	_esquiva_lado = dir.normalized()
	_esquiva_amplitude = float(d.get("deslocamento", 34.0))
	_esquiva_dur = maxf(float(d.get("fases", [0.0, 0.18, 0.12])[1]), 0.05)
	_esquiva_t = _esquiva_dur
	eventos.append("esquiva:on")
	return "ok: esquiva"


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


## Avança a rota e devolve a posição no CHÃO (sem o desvio). A rota é uma
## série de pontos de referência: procura o próximo, avança até ele e passa
## para o seguinte. Se um passo for barrado, a rota NÃO é apagada: ela para
## (`barrado()`) e espera — um pulo durante a rota passa por cima e retoma.
func _avancar_rota(dt: float, mundo: RefCounted) -> Vector2:
	if rota.is_empty() or _rota_i >= rota.size():
		return _terminar_rota()
	var base := pos - desvio
	var restante := velocidade * dt
	var voltas := 0
	while restante > 0.001 and _rota_i < rota.size() and voltas < 4:
		voltas += 1
		var alvo := rota[_rota_i]
		var para := alvo - base
		var dist := para.length()
		var chegada := float(rota_cfg.get("chegada_px", 12.0))
		# um ponto de referência DENTRO de um tronco não é alcançável no centro;
		# chegar perto dele já conta (a criatura contorna o objeto e segue).
		if mundo.bloqueio(mundo.celula_de(alvo), camada) == "objeto":
			chegada = maxf(chegada, 24.0)
		if dist <= chegada:
			_rota_i += 1
			_desvios = 0
			if _rota_i >= rota.size():
				return _terminar_rota()
			continue
		var dir := para / dist
		var passo := minf(restante, dist)
		var novo := _passo_com_desvio(base, dir, passo, alvo, mundo)
		var andado := novo.distance_to(base)
		if andado < 0.001:
			_barrado = true
			return base
		_barrado = false
		rota_t += andado
		restante -= andado
		olhar = (novo - base).normalized() if andado > 0.001 else olhar
		base = novo
		if base.distance_to(alvo) <= chegada:
			_rota_i += 1
			_desvios = 0
			if _rota_i >= rota.size():
				return _terminar_rota()
	return base


## Um passo em direção a `dir`. No ar (pulo) ignora o chão — é o que permite
## pular por cima da barreira e seguir a rota. No chão, OBJETO (tronco) pode
## ser contornado com um pequeno desvio angular; TERRENO (água, rocha, altura)
## para a criatura.
func _passo_com_desvio(base: Vector2, dir: Vector2, passo: float, alvo: Vector2, mundo: RefCounted) -> Vector2:
	var ideal := base + dir * passo
	if no_ar():
		if mundo.dentro(mundo.celula_de(ideal)):
			return ideal
		return base
	# caiu na água/rocha? só outro pulo sai de lá; andar não atravessa a barreira
	if mundo.bloqueio(mundo.celula_de(base), camada) == "terreno":
		return base
	var fim: Vector2 = mundo.limitar_segmento(base, ideal, camada)
	if fim.distance_to(ideal) < 0.01:
		_desvios = 0
		return fim
	var bloq: Dictionary = _primeiro_bloqueio(base, ideal, mundo)
	if bloq.is_empty() or str(bloq.get("tipo", "")) != "objeto":
		return base
	if _desvios >= int(rota_cfg.get("desvios_max", 80)):
		return base
	# leque de pequenos desvios: escolhe o que chega mais perto do alvo
	var melhor := base
	var melhor_d := INF
	var angulos: Array = rota_cfg.get("desvio_angulos", [20.0, -20.0, 40.0, -40.0, 60.0, -60.0, 80.0, -80.0, 100.0, -100.0, 120.0, -120.0])
	for a in angulos:
		var cand_ideal := base + dir.rotated(deg_to_rad(float(a))) * passo
		var cand: Vector2 = mundo.limitar_segmento(base, cand_ideal, camada)
		if cand.distance_to(cand_ideal) > 0.01:
			continue
		var d: float = cand.distance_to(alvo)
		if d < melhor_d:
			melhor = cand
			melhor_d = d
	if melhor == base:
		return base
	_desvios += 1
	return melhor


## A primeira célula DIFERENTE da atual que o passo encontraria e que está
## bloqueada: devolve {"tipo": "objeto"|"terreno", "celula": ...}. É o que
## decide entre contornar (objeto) e parar (terreno/altura).
func _primeiro_bloqueio(base: Vector2, ideal: Vector2, mundo: RefCounted) -> Dictionary:
	var dist := base.distance_to(ideal)
	if dist < 0.01:
		return {}
	var passos := maxi(1, ceili(dist))
	var c0: Vector2i = mundo.celula_de(base)
	for i in range(1, passos + 1):
		var p := base.lerp(ideal, float(i) / passos)
		var c: Vector2i = mundo.celula_de(p)
		if c == c0:
			continue
		var b: String = mundo.bloqueio(c, camada)
		if b != "":
			return {"tipo": b, "celula": c}
		if not mundo.pode_andar(c0, c, camada):
			return {"tipo": "terreno", "celula": c}
	return {}

## Fim da rota: guarda o destino para a autonomia e limpa a rota — a posição
## final é calculada ANTES de limpar (era o defeito da v0.5).
func _terminar_rota() -> Vector2:
	var fim: Vector2 = rota[rota.size() - 1] if not rota.is_empty() else (pos - desvio)
	rota = PackedVector2Array()
	_rota_i = 0
	rota_t = 0.0
	total_rota = 0.0
	_barrado = false
	_desvios = 0
	_auto_destino = fim
	_auto_t = 3.3  # decide JÁ no primeiro passo de autonomia
	_auto_espera = 0.0
	eventos.append("rota:fim")
	return fim


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
	var f: Array = defs.get(ataque, {}).get("fases", [0.1, 0.15, 0.2])
	var total := float(f[0]) + float(f[1]) + float(f[2])
	if ataque_t >= total:
		var nome := ataque
		ataque = ""
		ataque_t = 0.0
		_recargas[nome] = float(defs.get(nome, {}).get("recarga", 0.15))
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
		_rota_i = 0
		rota_t = 0.0
		total_rota = 0.0
		_barrado = false
		_desvios = 0
		_recargas["escavar"] = float(d.get("recarga", 0.4))
		eventos.append("camada:" + camada)
