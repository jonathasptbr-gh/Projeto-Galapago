extends RefCounted
## O CORPO da criatura — LÓGICA PURA, avançado por `passo(dt, mundo, alvos)`.
##
## DUAS COISAS ANDAM JUNTAS (é o que este arquivo garante):
##
## - a **ROTA** (o traço riscado): a criatura segue até o fim. Só perde a rota
##   se o jogador riscar OUTRA ou se escavar (troca de camada, e a rota não
##   vale mais lá). A rota é uma SÉRIE DE PONTOS de referência
##   (sim/trajetoria.simplificar) procurados na ordem; a criatura pode se
##   desviar um pouco para contornar OBJETOS. Água, rocha e altura são
##   BARREIRAS: ela para e a rota continua guardada — um pulo durante a rota
##   passa por cima e retoma o percurso;
## - os **OVERLAYS** (pulo, golpes, onda de área, tiros e habilidade), que
##   acontecem POR CIMA da rota sem cancelá-la.
##
## v0.9 — O ATAQUE NASCE DO DESENHO (`sim/formas.gd`), não de um gesto de dois
## dedos; v0.9.1 afinou as três pontas:
##
## - **laço** desenhado → onda em ÁREA, com centro no centro do laço. Acende
##   quando a criatura está em qualquer parte da CIRCUNFERÊNCIA (o anel) —
##   laço que fecha com ela em cima já dispara;
## - **bico** (o "T"/"V" que sai da estrada e volta) → **v0.11: o bico é
##   andado** (o traço é obedecido como foi desenhado; nada é ignorado);
## - **toque simples** → TIRO no alvo marcado; **toque duplo** → PULO;
## - **segurar** durante um caminho → SPRINT (gasta a barra de ENERGIA); sem
##   caminho → habilidade em si mesmo (cavar), ativada no limiar do segurar;
## - **travessia** de um alvo → BATIDA/empurrão ao passar por cima;
## - **fim do caminho em cima do adversário** → ele é marcado como alvo do
##   GOLPE FINAL (a marca vai NELE, não no lugar final). Se ele andar demais
##   até a criatura chegar, a automira se perde e o golpe sai no vazio.
##
## A **ESQUIVA É O PRÓPRIO CAMINHAR** (com o tempo lento do desenho): não há
## efeito de esquiva. A **HABILIDADE É DE SI MESMO** e dura um tempo: segurar o
## dedo parado a ativa (hoje `cavar`).
##
## O **DESCONTO INICIAL** (sim/trajetoria.descontar_inicio) tira o vai-e-volta
## do começo do traço antes de a rota existir — MAS não quando esse vai-e-volta
## é um BICO desenhado de propósito (ele é ataque).
##
## v0.7 — **TRAÇO AO VIVO** (`tracar`): enquanto o dedo desenha, a rota é
## refeita a cada quadro com o traço até agora e a criatura JÁ ANDA por ela. A
## origem é fixa (onde ela estava quando o dedo desceu). O progresso nunca
## anda para trás.
##
## Sem rota, entra em **AUTONOMIA**: parada, vagueando devagar, indo até o alvo
## marcado ou rondando ao redor dele. A escolha é sorteio com semente.
##
## O ALVO marcado (`alvo_id`) é resolvido pela lista de sim/alvos.gd a cada
## quadro — mirar num adversário que anda funciona.

const Mundo := preload("res://sim/mundo.gd")
const Trajetoria := preload("res://sim/trajetoria.gd")
const Alvos := preload("res://sim/alvos.gd")
const Formas := preload("res://sim/formas.gd")

# --- estado ---
var defs: Dictionary = {}
var rota_cfg: Dictionary = {}
var pos := Vector2.ZERO          # posição no chão
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
var _desvio_lado := 0.0            # lado do desvio em curso (histerese no tronco)

# overlays
var _pulo_t := 0.0
var _pulo_dur := 0.0
var _pulo_altura := 0.0
var ataque := ""                 # "" = nenhum
var ataque_t := 0.0
var ataque_dir := Vector2.RIGHT
var escavando := false
var _recargas := {}

# v0.9 — o desenho CRU, as marcas de ataque e os efeitos vivos
var traco := PackedVector2Array()
var marcas: Array = []           # {tipo, ponto, chave, dir, ...} a acender
var efeitos: Array = []          # ondas e tiros vivos (o jogo desenha)
var mira_final_id := ""          # adversário marcado pelo fim do caminho
var _perseguindo := false        # perseguição final do alvo marcado
var _perseguir_t := 0.0
var habilidade := ""             # habilidade de si mesmo em curso ("" = nenhuma)
var habilidade_t := 0.0
var habilidade_dur := 0.0
var _formas_cfg: Dictionary = {}
var _combate: Dictionary = {}
var _embalo: Dictionary = {}
var _arcos_rota := PackedFloat32Array()  # arco acumulado em cada ponto da rota
var _fase1 := 0.0                   # fases do desvio orgânico (semente da rota)
var _fase2 := 0.0
var _pausa_t := 0.0                 # pausa curta ao disparar o tiro
# SPRINT (v0.11): segurar DURANTE um caminho acelera e gasta a ENERGIA
var energia := 1.0
var _sprint := false
var _sprint_cfg: Dictionary = {}
# EMBALO dos golpes físicos (v0.9.2): acelera curto na marcação e longo no
# empurrão, passando mais rápido pelo alvo e desacelerando depois
var _turbo_t := 0.0
var _turbo_dur := 0.0
var _turbo_fator := 1.0
var _embalo_final_feito := false
var _disparadas := {}            # chaves de marcas que já acenderam
var _traco_lido := 0             # pontos do traço já lidos (economia)

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
	rota_cfg = defs.get("rota", {})
	_formas_cfg = defs.get("formas", {})
	_combate = defs.get("combate", {})
	_embalo = defs.get("embalo", {})
	_sprint_cfg = defs.get("sprint", {})


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


## Uma habilidade de si mesmo está em curso (cavar inclusive)?
func habilidade_ativa() -> bool:
	return escavando or habilidade != ""


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
			return _cmd_mover(cmd, mundo, alvos)
		"olhar":
			var v: Vector2 = cmd.get("alvo", pos) - pos
			if v.length() > 1.0:
				olhar = v.normalized()
			return "ok"
		"travar":
			return _cmd_travar(cmd, alvos)
		"ataque":
			return _cmd_ataque(cmd, alvos)
		"pular":
			return _cmd_pular(cmd)
		"habilidade":
			return _cmd_habilidade(mundo)
		"tiro":
			return _cmd_tiro(alvos)
		"segurar":
			return _cmd_segurar(mundo)
		"soltar_segurar":
			if _sprint:
				_sprint = false
				eventos.append("sprint:off")
			return "ok"
	if not defs.has(a):
		return "recusado: ação desconhecida (%s)" % a
	return "recusado: nada a fazer"


func _cmd_mover(cmd: Dictionary, mundo: RefCounted, alvos: Array) -> String:
	var pts := PackedVector2Array([pos])
	pts.append_array(cmd.get("pontos", PackedVector2Array()))
	if pts.size() < 2:
		return "recusado: caminho vazio"
	return _adotar_traco(pts, mundo, true, alvos)


## TRAÇO AO VIVO (v0.7): a rota é refeita a cada quadro com o desenho até
## agora; a criatura já caminha por ela. `pontos[0]` é a ORIGEM congelada (onde
## ela estava quando o dedo desceu) — quem chama põe esse ponto.
## `inicio` = primeiro quadro do gesto: se ela se mexeu até aqui, o traço
## ganha na frente o trecho que a traz de volta ao começo.
func tracar(pontos: PackedVector2Array, mundo: RefCounted, inicio := false, alvos: Array = []) -> String:
	return _adotar_traco(pontos, mundo, inicio, alvos)


## Guarda o traço cru, lê as FORMAS, monta a rota e as marcas. Devolve o texto
## para a HUD.
func _adotar_traco(pontos: PackedVector2Array, mundo: RefCounted, inicio: bool, alvos: Array) -> String:
	if pontos.size() < 2:
		return "recusado: caminho vazio"
	if inicio:
		_traco_lido = 0
	traco = pontos.duplicate()
	# ler as formas a cada poucos pontos (o RDP e os laços custam): a origem lê
	# sempre. v0.11: o traço é obedecido COMO FOI DESENHADO (o bico anda).
	var achadas: Array = []
	if inicio or traco.size() - _traco_lido >= 5:
		achadas = Formas.analisar(traco, _formas_cfg)
		_traco_lido = traco.size()
	var nova := _pontos_de_rota(traco, mundo)
	if nova.is_empty():
		return "recusado: caminho curto"
	if inicio:
		# ela andou enquanto o dedo descia: põe NA FRENTE o trecho que a traz de
		# volta ao começo do traço (depois da simplificação, senão um traço reto
		# engoliria a volta e ela "cortaria" o caminho).
		var base := pos
		if base.distance_to(nova[0]) > float(rota_cfg.get("chegada_px", 12.0)):
			var com_volta := PackedVector2Array([base])
			com_volta.append_array(nova)
			nova = com_volta
	_guardar_rota(nova, inicio)
	_montar_marcas(achadas, alvos)
	return "ok: rota de %d px" % int(total_rota)


## O traço vira PONTOS DE REFERÊNCIA: DESCONTO INICIAL (o vai-e-volta do
## começo não é obedecido) e Douglas-Peucker. O traço é o desenho inteiro.
func _pontos_de_rota(pts: PackedVector2Array, mundo: RefCounted) -> PackedVector2Array:
	if pts.size() < 2:
		return PackedVector2Array()
	var cortado := Trajetoria.descontar_inicio(pts, float(rota_cfg.get("desconto_raio_px", 44.0)),
		float(rota_cfg.get("desconto_janela_px", 140.0)))
	if cortado.size() < pts.size() and cortado.size() >= 2:
		# se a reta até o ponto de alinhamento atravessa parede, o desvio
		# inicial era necessário: não corta.
		if mundo.caminho_livre(pts[0], cortado[1], camada):
			pts = cortado
	var nova := Trajetoria.simplificar(pts, float(rota_cfg.get("simplificar_px", 10.0)))
	if nova.size() < 2 or Trajetoria.comprimento(nova) < 6.0:
		return PackedVector2Array()
	return nova


## Adota `nova` como rota. `reiniciar` zera o progresso (rota nova); sem ele o
## progresso é preservado (o traço ao vivo só CRESCE no fim). Nunca fica
## mirando um ponto que já está ao alcance.
func _guardar_rota(nova: PackedVector2Array, reiniciar: bool) -> void:
	rota = nova
	total_rota = Trajetoria.comprimento(rota)
	_arcos_rota = Formas.arcos(rota)
	_barrado = false
	autonomia = ""
	_auto_destino = Vector2.ZERO
	if reiniciar:
		_rota_i = 0
		rota_t = 0.0
		_desvios = 0
		_desvio_lado = 0.0
		_sprint = false
		marcas = []
		_disparadas = {}
		mira_final_id = ""
		_perseguindo = false
		_embalo_final_feito = false
		_turbo_t = 0.0
		# a "estrada" ganha fases próprias (mesma semente = mesmo passeio)
		_fase1 = rng.randf() * TAU
		_fase2 = rng.randf() * TAU
		eventos.append("rota:nova")
	if _rota_i >= rota.size():
		_rota_i = maxi(0, rota.size() - 1)


# ---------------------------------------------------------------- marcas (formas)

## Monta as marcas pendentes: as FORMAS do traço (laço) e as TRAVESSIAS
## de alvo na rota. O que já acendeu não volta.
func _montar_marcas(achadas: Array, alvos: Array) -> void:
	for m in achadas:
		var k: String = str(m["chave"])
		if _disparadas.has(k) or _tem_marca(k):
			continue
		marcas.append(m)
	# travessias: refeitas a cada atualização (a rota cresce)
	for m in marcas.duplicate():
		if str(m["tipo"]) == "batida":
			marcas.erase(m)
	_marcas_de_travessia(alvos)
	# a MARCA do alvo nasce durante o caminho: quando a PONTA do traço o alcança
	if rota.size() >= 2:
		_marcar_alvo_no_fim(alvos, rota[rota.size() - 1])


func _tem_marca(chave: String) -> bool:
	for m in marcas:
		if str(m["chave"]) == chave:
			return true
	return false


## Alvos que a ROTA atravessa (a linha passou por cima): marca de BATIDA no
## ponto mais perto da rota. Empurra quem sabe reagir (adversário); árvore só
## leva a batida.
func _marcas_de_travessia(alvos: Array) -> void:
	if rota.size() < 2 or alvos.is_empty():
		return
	var cruza := float(_combate.get("batida_cruza_px", 8.0))
	for a in alvos:
		if not a.get("travavel", false):
			continue
		var alvo_p: Vector2 = a["pos"]
		var limite := float(a["raio"]) + cruza
		var melhor := Vector2.ZERO
		var melhor_d := limite
		var melhor_dir := Vector2.ZERO
		for i in range(1, rota.size()):
			var a0 := rota[i - 1]
			var a1 := rota[i]
			var ab := a1 - a0
			var l2 := ab.length_squared()
			if l2 < 0.0001:
				continue
			var t := clampf((alvo_p - a0).dot(ab) / l2, 0.0, 1.0)
			var q := a0 + ab * t
			var d := q.distance_to(alvo_p)
			if d <= melhor_d:
				melhor_d = d
				melhor = q
				melhor_dir = ab.normalized()
		if melhor == Vector2.ZERO and melhor_d >= limite:
			continue
		var chave := "batida:%s:%d,%d" % [str(a["id"]), roundi(melhor.x), roundi(melhor.y)]
		if _disparadas.has(chave) or _tem_marca(chave):
			continue
		marcas.append({
			"tipo": "batida", "ponto": melhor, "alvo_id": str(a["id"]),
			"dir": melhor_dir, "chave": chave,
		})


## O gatilho: a criatura passou pelo ponto da marca. O LAÇO só acende no trecho
## que FECHA (a ida passa pelo mesmo nó, mas ao contrário). Devolve nada; o
## efeito entra em `efeitos` e os eventos na fila.
func _checar_marcas(alvos: Array) -> void:
	if marcas.is_empty():
		return
	var raio := float(_formas_cfg.get("gatilho_raio_px", 24.0))
	for m in marcas.duplicate():
		var p: Vector2 = m["ponto"]
		if str(m["tipo"]) == "laco":
			# v0.10: a trava é a DISTÂNCIA da criatura ao CENTRO da área — não
			# precisa chegar no anel: laço feito perto (até `area_gatilho_px`,
			# ~7× o corpo) já acende. O cooldown segura a marca (pendente).
			if float(_recargas.get("onda", 0.0)) > 0.0:
				continue
			if pos.distance_to(Vector2(m["centro"])) <= float(_combate.get("area_gatilho_px", 224.0)):
				_disparar(m, alvos)
			continue
		# batida: acende no ponto da travessia
		if pos.distance_to(p) <= raio:
			_disparar(m, alvos)


func _disparar(m: Dictionary, alvos: Array) -> void:
	marcas.erase(m)
	_disparadas[str(m["chave"])] = true
	match str(m["tipo"]):
		"laco":
			efeitos.append({
				"tipo": "onda", "centro": Vector2(m["centro"]), "raio": 0.0,
				"alvo_raio": float(m["raio"]),
				"velocidade": float(_combate.get("onda_velocidade", 140.0)),
				"atingidos": [],
			})
			_recargas["onda"] = float(_combate.get("onda_recarga_s", 1.0))
			eventos.append("laco:onda")
		"batida":
			var id := str(m["alvo_id"])
			var a := Alvos.por_id(alvos, id)
			if a.is_empty():
				return
			if pos.distance_to(Vector2(a["pos"])) > float(_combate.get("batida_tol_px", 34.0)) + float(a["raio"]):
				return
			Alvos.empurrar(alvos, id, Vector2(m["dir"]), float(_combate.get("batida_empurrao", 26.0)))
			_cmd_golpe("batida", Vector2(m["dir"]))
			# EMBALO LONGO do empurrão: passa mais rápido pelo alvo e desacelera
			_iniciar_embalo(float(_embalo.get("longo_s", 0.6)), float(_embalo.get("longo_fator", 2.0)))
			eventos.append("batida:" + id)
			eventos.append("acerto:" + id)


## EMBALO (v0.9.2): um "pico" de velocidade que sobe e desce suave
## (`sin(π·u)`). Curto na marcação do alvo final; longo no empurrão.
func _iniciar_embalo(duracao: float, fator: float) -> void:
	_turbo_dur = maxf(duracao, 0.05)
	_turbo_t = _turbo_dur
	_turbo_fator = maxf(fator, 1.0)


func _fator_embalo() -> float:
	if _turbo_t <= 0.0 or _turbo_dur <= 0.0:
		return 1.0
	var u := clampf(1.0 - _turbo_t / _turbo_dur, 0.0, 1.0)
	return 1.0 + (_turbo_fator - 1.0) * sin(PI * u)


# ---------------------------------------------------------------- efeitos

## Ondas e tiros: a onda CRESCE do centro e empurra quem ela varre; o tiro
## anda na direção do disparo e para no primeiro alvo. Um alvo é atingido uma vez
## por onda.
func _atualizar_efeitos(dt: float, alvos: Array) -> void:
	for e in efeitos.duplicate():
		if str(e["tipo"]) == "onda":
			var antes := float(e["raio"])
			var atual := minf(antes + float(e["velocidade"]) * dt, float(e["alvo_raio"]))
			e["raio"] = atual
			for a in alvos:
				if _atingidos_tem(e, str(a["id"])) or not Alvos.reage(a):
					continue
				var d: float = Vector2(a["pos"]).distance_to(Vector2(e["centro"]))
				if d <= atual + float(a["raio"]) and d >= antes - float(a["raio"]):
					e["atingidos"].append(str(a["id"]))
					var dir: Vector2 = Vector2(a["pos"]) - Vector2(e["centro"])
					if dir.length() < 0.01:
						dir = olhar
					Alvos.empurrar(alvos, str(a["id"]), dir, float(_combate.get("onda_empurrao", 30.0)))
					eventos.append("acerto:" + str(a["id"]))
			if atual >= float(e["alvo_raio"]):
				efeitos.erase(e)
		elif str(e["tipo"]) == "tiro":
			var quanto := float(e["velocidade"]) * dt
			e["pos"] = Vector2(e["pos"]) + Vector2(e["dir"]) * quanto
			e["andado"] = float(e["andado"]) + quanto
			var bateu := ""
			for a in alvos:
				if not Alvos.reage(a):
					continue
				if Vector2(e["pos"]).distance_to(Vector2(a["pos"])) <= float(e["raio"]) + float(a["raio"]):
					bateu = str(a["id"])
					break
			if bateu != "":
				Alvos.empurrar(alvos, bateu, Vector2(e["dir"]), float(_combate.get("tiro_empurrao", 24.0)))
				eventos.append("acerto:" + bateu)
				efeitos.erase(e)
			elif float(e["andado"]) >= float(e["alcance"]):
				efeitos.erase(e)


func _atingidos_tem(onda: Dictionary, id: String) -> bool:
	for x in onda["atingidos"]:
		if str(x) == id:
			return true
	return false


## O FIM do traço: se ele terminou EM CIMA de um adversário, ele fica marcado
## como alvo do golpe final — a marca vai NELE (e anda com ele!) até a criatura
## chegar. Devolve o texto para a HUD.
func finalizar_rota(alvos: Array) -> String:
	# o último quadro pode ter fechado um laço: lê tudo uma vez mais
	var achadas := Formas.analisar(traco, _formas_cfg)
	_montar_marcas(achadas, alvos)
	_checar_marcas(alvos)
	if rota.is_empty():
		return ""
	return _marcar_alvo_no_fim(alvos, rota[rota.size() - 1])


## A MARCA do alvo (v0.10): o FIM do caminho alcançou um adversário? Ele fica
## marcado — a marca ANDA com ele e vale para o TIRO (toque duplo) e para o
## GOLPE FINAL. Ela está ligada ao CAMINHO: sai no golpe físico (ou quando o
## caminho é trocado). Chamada também a cada quadro do desenho (marca viva).
func _marcar_alvo_no_fim(alvos: Array, fim: Vector2) -> String:
	var melhor := {}
	var melhor_d := float(_combate.get("mira_final_raio", 34.0))
	for a in alvos:
		if not Alvos.reage(a):
			continue
		var d: float = fim.distance_to(Vector2(a["pos"])) - float(a["raio"])
		if d <= melhor_d:
			melhor = a
			melhor_d = d
	if melhor.is_empty():
		return ""
	if mira_final_id == str(melhor["id"]):
		return "ok: alvo marcado"
	mira_final_id = str(melhor["id"])
	_embalo_final_feito = false
	eventos.append("mira_final:" + mira_final_id)
	return "ok: alvo marcado"


## O golpe físico que FECHA o caminho: perto do alvo marcado, bate e empurra,
## e a MARCA SAI (ela está ligada ao caminho). O animal só bate se chegou
## perto — quem persegue é `_perseguir`.
func _golpe_final(alvos: Array) -> void:
	var id := mira_final_id
	mira_final_id = ""
	_perseguindo = false
	if id == "":
		return
	var a := Alvos.por_id(alvos, id)
	if a.is_empty():
		eventos.append("mira_final:perde")
		return
	var dir: Vector2 = Vector2(a["pos"]) - pos
	if dir.length() < 0.5:
		dir = olhar
	dir = dir.normalized()
	_cmd_golpe("ataque", dir)
	Alvos.empurrar(alvos, id, dir, float(_combate.get("mira_final_empurrao", 44.0)))
	eventos.append("acerto:" + id)
	eventos.append("golpe_final:" + id)


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
	# a direção do golpe NÃO vem do gesto: é o alvo marcado; sem alvo, a ROTA
	var para: Vector2 = olhar
	if alvo_id != "":
		var ap := alvo_pos(alvos)
		if ap != Vector2.ZERO and ap.distance_to(pos) > 1.0:
			para = (ap - pos).normalized()
		elif em_rota():
			para = _tangente_em_rota(rota_t)
	elif em_rota():
		para = _tangente_em_rota(rota_t)
	return _cmd_golpe("ataque", para)


## Golpe genérico (ataque físico ou batida): mesma máquina de fases, mesma
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
	return "ok: %s" % ("atacando" if nome == "ataque" else "batendo")


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


## TIRO (v0.10): o TOQUE DUPLO dispara no ALVO MARCADO (a marca vem do fim do
## caminho). O animal PARA para atirar (`tiro_pausa_s`) e depois segue a rota;
## a marca NÃO sai no disparo. Tem recarga (`tiro_recarga_s`, 1 s).
func _cmd_tiro(alvos: Array) -> String:
	if mira_final_id == "":
		return "recusado: sem alvo marcado"
	if float(_recargas.get("tiro", 0.0)) > 0.0:
		return "recusado: recarga"
	var a := Alvos.por_id(alvos, mira_final_id)
	if a.is_empty():
		mira_final_id = ""
		return "recusado: o alvo sumiu"
	var dir: Vector2 = (Vector2(a["pos"]) - pos)
	if dir.length() < 0.5:
		dir = olhar
	dir = dir.normalized()
	olhar = dir
	_atirar(dir)
	_recargas["tiro"] = float(_combate.get("tiro_recarga_s", 1.0))
	_pausa_t = maxf(_pausa_t, float(_combate.get("tiro_pausa_s", 0.25)))
	eventos.append("tiro:disparo")
	return "ok: tiro"


## Cria o projétil. Quem chama decide a direção (o tiro vai no alvo marcado).
func _atirar(dir: Vector2) -> void:
	efeitos.append({
		"tipo": "tiro", "pos": pos, "dir": dir,
		"raio": float(_combate.get("tiro_raio", 9.0)), "andado": 0.0,
		"alcance": float(_combate.get("tiro_alcance", 280.0)),
		"velocidade": float(_combate.get("tiro_velocidade", 420.0)),
	})


## SEGURAR (v0.11): com um CAMINHO em curso → **SPRINT** (acelera e gasta a
## barra de energia); **sem caminho** → a HABILIDADE em si mesmo (cavar), que
## agora é ativada **no limiar do segurar** (não espera soltar).
func _cmd_segurar(mundo: RefCounted) -> String:
	if em_rota():
		if energia <= float(_sprint_cfg.get("minimo", 0.08)):
			return "recusado: sem energia"
		if _sprint:
			return "ok: já em sprint"
		_sprint = true
		eventos.append("sprint:on")
		return "ok: sprint"
	_sprint = false
	return _cmd_habilidade(mundo)


## HABILIDADE EM SI MESMO (v0.9): o que era o gesto de escavar virou a
## habilidade do segurar parado. Ela dura um tempo e acontece sem sair do lugar.
## A primeira é `cavar` (a que existia); outras entram em `dados/acoes.json`
## com "duracao".
func _cmd_habilidade(mundo: RefCounted) -> String:
	if habilidade_ativa():
		return "recusado: habilidade em curso"
	if float(_recargas.get("habilidade", 0.0)) > 0.0:
		return "recusado: recarga"
	var nome: String = str(defs.get("habilidade", {}).get("nome", "cavar"))
	if nome == "cavar":
		return _cmd_cavar(mundo)
	if not defs.has(nome):
		return "recusado: habilidade desconhecida (%s)" % nome
	var d: Dictionary = defs[nome]
	habilidade = nome
	habilidade_dur = maxf(float(d.get("duracao", 1.0)), 0.1)
	habilidade_t = 0.0
	eventos.append("habilidade:on")
	return "ok: %s" % nome


func _cmd_cavar(mundo: RefCounted) -> String:
	if escavando:
		return "recusado: cavando"
	var c: Vector2i = mundo.celula_de(pos)
	if not mundo.pode_escavar(c, camada):
		return "recusado: aqui não dá para cavar"
	escavando = true
	var d: Dictionary = defs.get("cavar", {"fases": [0.15, 0.55, 0.15]})
	_escavar_dur = maxf(float(d.get("fases", [0.15, 0.55, 0.15])[1]), 0.1)
	_escavar_t = 0.0
	_escavar_celula = c
	eventos.append("habilidade:on")
	return "ok: cavando"


var _escavar_t := 0.0
var _escavar_dur := 0.0
var _escavar_celula := Vector2i.ZERO


# ---------------------------------------------------------------- avanço

func passo(dt: float, mundo: RefCounted, alvos: Array = []) -> void:
	for k in _recargas.keys():
		_recargas[k] = maxf(0.0, float(_recargas[k]) - dt)
	_atualizar_pulo(dt)
	_atualizar_ataque(dt)
	_atualizar_habilidade(dt)
	_atualizar_efeitos(dt, alvos)
	_turbo_t = maxf(_turbo_t - dt, 0.0)
	# ENERGIA do sprint: gasta acelerando no caminho, recupera parada/andando
	if _sprint and em_rota() and energia > 0.0:
		energia = maxf(0.0, energia - float(_sprint_cfg.get("gasto_s", 0.45)) * dt)
		if energia <= 0.0:
			_sprint = false
			eventos.append("sprint:off")
	else:
		energia = minf(1.0, energia + float(_sprint_cfg.get("recarga_s", 0.22)) * dt)
	if escavando:
		_atualizar_escavar(dt, mundo)
		pos = mundo.centro(_escavar_celula)
		return
	# pausa curta do tiro: para para atirar e depois segue
	if _pausa_t > 0.0:
		_pausa_t = maxf(_pausa_t - dt, 0.0)
		_checar_marcas(alvos)
		return
	if em_rota():
		pos = _avancar_rota(dt, mundo, alvos)
	elif _perseguindo:
		_perseguir(dt, mundo, alvos)
	else:
		_autonomia(dt, mundo, alvos)
	_checar_marcas(alvos)


## Avança a rota como uma ESTRADA (v0.9.1): a criatura segue o traço por
## dentro de uma FAIXA (pode ir mais à esquerda, à direita ou no centro), mira
## um ponto À FRENTE (o caminho fica curvo, não retilíneo) e FREIA nos últimos
## `freio_px` (zona de freio), para parar macio. Se um passo for barrado, a rota
## NÃO é apagada: para (`barrado()`) e espera — um pulo passa por cima e retoma.
func _avancar_rota(dt: float, mundo: RefCounted, alvos: Array) -> Vector2:
	if rota.is_empty() or total_rota <= 0.001:
		return _terminar_rota(alvos)
	var base := pos
	var proj := _projetar(base)
	rota_t = float(proj["s"])
	_rota_i = int(proj["i"])
	if rota_t >= total_rota - float(rota_cfg.get("parada_px", 4.0)):
		return _terminar_rota(alvos)
	# EMBALO CURTO da marcação: ao chegar perto do alvo final, acelera para o
	# golpe (logo antes de bater), uma vez por marca.
	if mira_final_id != "" and not _embalo_final_feito:
		var alvo_f := Alvos.pos_de(alvos, mira_final_id)
		if alvo_f != Vector2.ZERO and pos.distance_to(alvo_f) <= float(_embalo.get("gatilho_px", 70.0)):
			_iniciar_embalo(float(_embalo.get("curto_s", 0.25)), float(_embalo.get("curto_fator", 1.7)))
			_embalo_final_feito = true
	# FREIO: perde velocidade perto do fim
	var restante := total_rota - rota_t
	var freio_px := maxf(float(rota_cfg.get("freio_px", 44.0)), 1.0)
	var f := clampf(restante / freio_px, 0.0, 1.0)
	f = f * f * (3.0 - 2.0 * f)
	f = maxf(f, float(rota_cfg.get("freio_min", 0.12)))
	# v0.10: com ALVO MARCADO não há zona de freio no fim — o animal segue em
	# velocidade cheia para perseguir/bater no alvo.
	if mira_final_id != "":
		f = 1.0
	var fator_sprint := 1.0
	if _sprint and energia > 0.0:
		fator_sprint = float(_sprint_cfg.get("fator", 1.7))
	var passo := velocidade * f * _fator_embalo() * fator_sprint * dt
	# ALVO: um ponto À FRENTE na estrada + o desvio orgânico lateral
	var olhar_px := maxf(float(rota_cfg.get("olhar_px", 22.0)), 1.0)
	var s_alvo := minf(rota_t + olhar_px, total_rota)
	# um ponto de referência DENTRO de um tronco não é alcançável: mira ADIANTE
	# (a criatura contorna o objeto e a rota segue)
	var pulos := 0
	while pulos < 8 and s_alvo < total_rota - 0.01 \
			and mundo.bloqueio(mundo.celula_de(_ponto_em_rota(s_alvo)), camada) == "objeto":
		s_alvo = minf(s_alvo + 18.0, total_rota)
		pulos += 1
	var centro := _ponto_em_rota(s_alvo)
	var tang := _tangente_em_rota(s_alvo)
	if tang.length() < 0.01:
		tang = olhar if olhar.length() > 0.01 else Vector2.RIGHT
	var meia := maxf(float(rota_cfg.get("estrada_largura_px", 30.0)) * 0.5, 0.0)
	var desvio := clampf(_desvio_organico(s_alvo), -meia, meia)
	var destino := centro + tang.orthogonal() * desvio
	var para := destino - base
	if para.length() < 0.01:
		para = tang
	var dir := para.normalized()
	var novo := _passo_com_desvio(base, dir, passo, destino, mundo)
	if novo.distance_to(base) < 0.001:
		_barrado = true
		return base
	_barrado = false
	olhar = (novo - base).normalized()
	return novo


## Projeta a criatura na rota (busca LOCAL em volta do segmento atual, para um
## laço não "pular" de braço). Devolve {s, i, d}.
func _projetar(q: Vector2) -> Dictionary:
	if rota.size() < 2 or _arcos_rota.size() < 2:
		return {"s": 0.0, "i": 0, "d": INF}
	var melhor_s := 0.0
	var melhor_d := INF
	var melhor_i := 0
	var i0 := maxi(0, _rota_i - 2)
	var i1 := mini(rota.size() - 1, _rota_i + 12)
	for i in range(i0, i1):
		var a := rota[i]
		var b := rota[i + 1]
		var ab := b - a
		var l2 := ab.length_squared()
		var t := 0.0
		if l2 > 0.0001:
			t = clampf((q - a).dot(ab) / l2, 0.0, 1.0)
		var p := a + ab * t
		var d := p.distance_to(q)
		if d < melhor_d:
			melhor_d = d
			melhor_i = i
			melhor_s = _arcos_rota[i] + ab.length() * t
	return {"s": melhor_s, "i": melhor_i, "d": melhor_d}


## Ponto da rota a `s` px de arco do começo.
func _ponto_em_rota(s: float) -> Vector2:
	if rota.is_empty():
		return Vector2.ZERO
	if s <= 0.0:
		return rota[0]
	if s >= total_rota or _arcos_rota.size() < 2:
		return rota[rota.size() - 1]
	for i in range(1, rota.size()):
		if _arcos_rota[i] >= s:
			var seg := _arcos_rota[i] - _arcos_rota[i - 1]
			var t := (s - _arcos_rota[i - 1]) / maxf(seg, 0.0001)
			return rota[i - 1].lerp(rota[i], t)
	return rota[rota.size() - 1]


## Direção da rota a `s` px de arco.
func _tangente_em_rota(s: float) -> Vector2:
	if rota.size() < 2 or _arcos_rota.size() < 2:
		return olhar
	var i := 0
	while i < rota.size() - 2 and _arcos_rota[i + 1] < s:
		i += 1
	var d := rota[i + 1] - rota[i]
	return d.normalized() if d.length() > 0.01 else olhar


## Desvio lateral do "caminho orgânico": duas senoides de fases sorteadas (a
## mesma semente dá o mesmo passeio). A criatura anda ora mais à esquerda, ora
## mais à direita da linha, dentro da estrada — o caminho não fica retilíneo.
func _desvio_organico(s: float) -> float:
	var o1 := maxf(float(rota_cfg.get("estrada_onda_px", 120.0)), 1.0)
	var o2 := maxf(float(rota_cfg.get("estrada_onda2_px", 47.0)), 1.0)
	var amp := float(rota_cfg.get("estrada_desvio_px", 9.0))
	return amp * (0.68 * sin(TAU * s / o1 + _fase1) + 0.32 * sin(TAU * s / o2 + _fase2))


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
		_desvio_lado = 0.0  # o caminho está livre: o desvio acabou
		return fim
	var bloq: Dictionary = _primeiro_bloqueio(base, ideal, mundo)
	if bloq.is_empty() or str(bloq.get("tipo", "")) != "objeto":
		return base
	if _desvios >= int(rota_cfg.get("desvios_max", 80)):
		return base
	# leque de pequenos desvios: escolhe o que chega mais perto do alvo. O LADO
	# escolhido uma vez é mantido (histerese): sem isso a criatura fica
	# oscilando de um lado para o outro na beirada do tronco.
	var angulos: Array = rota_cfg.get("desvio_angulos", [20.0, -20.0, 40.0, -40.0, 60.0, -60.0, 80.0, -80.0, 100.0, -100.0, 120.0, -120.0])
	var lados: Array = [angulos]
	if _desvio_lado != 0.0:
		var mesmo: Array = []
		for a in angulos:
			if signf(float(a)) == _desvio_lado:
				mesmo.append(a)
		if not mesmo.is_empty():
			lados = [mesmo]
	var melhor := base
	var melhor_d := INF
	var escolhido := 0.0
	for lista in lados:
		for a in lista:
			var cand_ideal := base + dir.rotated(deg_to_rad(float(a))) * passo
			var cand: Vector2 = mundo.limitar_segmento(base, cand_ideal, camada)
			if cand.distance_to(cand_ideal) > 0.01:
				continue
			var d: float = cand.distance_to(alvo)
			if d < melhor_d:
				melhor = cand
				melhor_d = d
				escolhido = float(a)
		if melhor != base:
			break
	if melhor == base:
		return base
	_desvio_lado = signf(escolhido)
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


## Fim da rota: o GOLPE FINAL (se o fim caiu em cima de um adversário) e a
## autonomia. O fim é calculado ANTES de limpar; a criatura PARA onde está (a
## zona de freio já a desacelerou — não há salto para o último ponto).
func _terminar_rota(alvos: Array) -> Vector2:
	var fim: Vector2 = rota[rota.size() - 1] if not rota.is_empty() else pos
	# a rota pode acabar DURANTE o desenho (traço ao vivo): a marca é feita
	# aqui também, com o adversário onde ele está agora.
	if mira_final_id == "" and not rota.is_empty():
		_marcar_alvo_no_fim(alvos, fim)
	if mira_final_id != "":
		_iniciar_final(alvos)
	rota = PackedVector2Array()
	_arcos_rota = PackedFloat32Array()
	_rota_i = 0
	rota_t = 0.0
	total_rota = 0.0
	_barrado = false
	_desvios = 0
	_desvio_lado = 0.0
	_sprint = false
	marcas = []
	_auto_destino = fim
	_auto_t = 3.3  # decide JÁ no primeiro passo de autonomia
	_auto_espera = 0.0
	eventos.append("rota:fim")
	return pos


## O alcance de um golpe físico no alvo `a` (a criatura precisa CHEGAR perto).
func _alcance_final(a: Dictionary) -> float:
	return float(defs.get("ataque", {}).get("alcance", 40.0)) + float(a.get("raio", 15.0)) + 10.0


## O caminho acabou com alvo marcado: se já está no alcance, bate; senão, VAI
## ATRÁS dele (perseguição final) com o embalo curto.
func _iniciar_final(alvos: Array) -> void:
	var a := Alvos.por_id(alvos, mira_final_id)
	if a.is_empty():
		mira_final_id = ""
		eventos.append("mira_final:perde")
		return
	if pos.distance_to(Vector2(a["pos"])) <= _alcance_final(a):
		_golpe_final(alvos)
		return
	_perseguindo = true
	_perseguir_t = maxf(float(_embalo.get("perseguir_s", 3.0)), 0.3)
	_iniciar_embalo(float(_embalo.get("curto_s", 0.25)), float(_embalo.get("curto_fator", 1.7)))


## PERSEGUIÇÃO FINAL (v0.10): o animal VAI ATRÁS do alvo marcado a pé (em vez de
## atacar de longe), com o embalo curto. Ao chegar no alcance, o golpe físico;
## se for barrado/tempo esgotar, a marca se perde.
func _perseguir(dt: float, mundo: RefCounted, alvos: Array) -> void:
	_perseguir_t -= dt
	var a := Alvos.por_id(alvos, mira_final_id)
	if a.is_empty() or _perseguir_t <= 0.0:
		_perseguindo = false
		mira_final_id = ""
		eventos.append("mira_final:perde")
		return
	var alvo: Vector2 = Vector2(a["pos"])
	if pos.distance_to(alvo) <= _alcance_final(a):
		_golpe_final(alvos)
		return
	var dir := alvo - pos
	if dir.length() < 0.01:
		_golpe_final(alvos)
		return
	dir = dir.normalized()
	var passo := velocidade * _fator_embalo() * dt
	var novo := _passo_com_desvio(pos, dir, passo, alvo, mundo)
	if novo.distance_to(pos) < 0.001:
		_barrado = true
		return
	_barrado = false
	olhar = (novo - pos).normalized()
	pos = novo


func _autonomia(dt: float, mundo: RefCounted, alvos: Array) -> void:
	_auto_t += dt
	var base: Vector2 = pos
	if _auto_espera > 0.0:
		_auto_espera -= dt
		autonomia = "parado"
		return
	# a cada ~3 s, ou ao chegar no destino, decide de novo
	if _auto_t >= 3.2 or _auto_destino.distance_to(base) < 6.0:
		_auto_t = 0.0
		_decidir_autonomia(mundo, alvos)
		base = pos
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
	pos = novo


func _decidir_autonomia(mundo: RefCounted, alvos: Array) -> void:
	var alvo_p := alvo_pos(alvos) if alvo_id != "" else Vector2.ZERO
	var dado := rng.randf()
	if alvo_p != Vector2.ZERO:
		var dist := pos.distance_to(alvo_p)
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
		var p: Vector2 = pos + Vector2.from_angle(ang) * rng.randf_range(30.0, 80.0)
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


## Habilidade de si mesmo que NÃO é a cavar (a cavar tem fases próprias).
func _atualizar_habilidade(dt: float) -> void:
	if habilidade == "":
		return
	habilidade_t += dt
	if habilidade_t >= habilidade_dur:
		var nome := habilidade
		habilidade = ""
		_recargas[nome] = float(defs.get(nome, {}).get("recarga", 0.4))
		eventos.append("habilidade:off")


func _atualizar_escavar(dt: float, mundo: RefCounted) -> void:
	_escavar_t += dt
	var d: Dictionary = defs.get("cavar", {"fases": [0.15, 0.55, 0.15]})
	var f: Array = d.get("fases", [0.15, 0.55, 0.15])
	var total := float(f[0]) + float(f[1]) + float(f[2])
	if _escavar_t >= total:
		escavando = false
		camada = mundo.escavar(_escavar_celula, camada)
		pos = mundo.centro(_escavar_celula)
		rota = PackedVector2Array()
		_rota_i = 0
		rota_t = 0.0
		total_rota = 0.0
		_barrado = false
		_desvios = 0
		marcas = []
		mira_final_id = ""
		_perseguindo = false
		_arcos_rota = PackedFloat32Array()
		_recargas["habilidade"] = float(defs.get("habilidade", {}).get("recarga", 0.4))
		eventos.append("camada:" + camada)
		eventos.append("habilidade:off")
