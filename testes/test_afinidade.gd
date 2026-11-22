extends "res://testes/caso.gd"
## Propriedades da afinidade (P4): a mesma semente dá a mesma decisão; o
## vínculo aumenta a obediência; Sincronia e Autonomia diferem no MESMO estado;
## hesitar atrasa, reinterpretar desloca a intenção sem trocar a ação,
## desobedecer devolve {} — e o estado nunca sai de [0,1].

const A := preload("res://sim/afinidade.gd")

var cfg: Dictionary = A.config()


func _criar(doc := 0.55, teim := 0.35, cur := 0.6, afin := 0.4, humor := 0.55, modo := "sincronia") -> Variant:
	var a: Variant = A.novo(cfg)
	a.temperamento = {"docilidade": doc, "teimosia": teim, "curiosidade": cur}
	a.afinidade = afin
	a.humor = humor
	a.modo = modo
	return a


func _cmd_mover() -> Dictionary:
	return {
		"acao": "mover", "alvo": Vector2(100, 100),
		"pontos": PackedVector2Array([Vector2(10, 10), Vector2(50, 40), Vector2(120, 90)]),
		"direcao": Vector2.RIGHT, "alcance": 110.0, "gesto": "trajetoria",
	}


func _cmd_tiro() -> Dictionary:
	return {
		"acao": "tiro", "alvo": Vector2(200, 120),
		"pontos": PackedVector2Array(), "direcao": Vector2.RIGHT,
		"alcance": 110.0, "gesto": "toque",
	}


## Conta as decisões em `n` sementes seguidas (mesmo estado, sem registrar).
func _contar(a: Variant, n: int, cmd: Dictionary = {}) -> Dictionary:
	var conta := {"obedece": 0, "hesita": 0, "reinterpreta": 0, "desobedece": 0}
	for s in n:
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		var dec: Dictionary = a.decidir(cmd if not cmd.is_empty() else _cmd_mover(), rng)
		conta[str(dec["decisao"])] += 1
	return conta


## Primeira decisão igual a `alvo` varrendo sementes ({} se não houver).
func _achar(a: Variant, alvo: String, cmd: Dictionary, n := 300) -> Dictionary:
	for s in n:
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		var dec: Dictionary = a.decidir(cmd, rng)
		if str(dec["decisao"]) == alvo:
			return dec
	return {}


func test_config_e_estado_inicial() -> void:
	checar(not cfg.is_empty(), "dados/afinidade.json válido")
	for k in ["estado_inicial", "pesos", "afinidade_peso", "humor_peso", "modo_ajuste", "ganhos"]:
		checar(cfg.has(k), "bloco %s no JSON" % k)
	igual(A.config("res://dados/nao_existe.json"), {}, "arquivo ausente devolve {}")
	var a: Variant = A.novo({})
	for t in ["docilidade", "teimosia", "curiosidade"]:
		checar(a.temperamento.has(t), "traço padrão %s" % t)
	checar(str(a.modo) in ["sincronia", "autonomia"], "modo inicial válido")
	# traço novo no JSON (aqui à mão) entra na soma sem mudar o código
	a.temperamento["brincalhao"] = 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	checar(not a.decidir(_cmd_tiro(), rng).is_empty(), "traço extra não quebra a decisão")


func test_mesma_semente_mesma_decisao() -> void:
	for s in 100:
		var a: Variant = _criar(0.4, 0.6, 0.7, 0.3, 0.5, "autonomia")
		var b: Variant = _criar(0.4, 0.6, 0.7, 0.3, 0.5, "autonomia")
		var r1 := RandomNumberGenerator.new()
		var r2 := RandomNumberGenerator.new()
		r1.seed = s
		r2.seed = s
		for i in 3:
			var cmd := _cmd_mover() if i % 2 == 0 else _cmd_tiro()
			var d1: Dictionary = a.decidir(cmd, r1)
			var d2: Dictionary = b.decidir(cmd, r2)
			igual(d1["decisao"], d2["decisao"], "semente %d passo %d: decisão" % [s, i])
			igual(d1["atraso_s"], d2["atraso_s"], "semente %d passo %d: atraso" % [s, i])
			igual(d1["comando"], d2["comando"], "semente %d passo %d: comando" % [s, i])
			a.registrar(d1)
			b.registrar(d2)
		igual(a.afinidade, b.afinidade, "semente %d: afinidade depois de registrar" % s)


func test_afinidade_alta_obedece() -> void:
	var a: Variant = _criar(0.95, 0.05, 0.5, 1.0, 0.7, "autonomia")
	var conta := _contar(a, 200)
	checar(int(conta["obedece"]) >= 180,
		"afinidade alta: %d/200 obedece (esperado ≥ 90%%)" % int(conta["obedece"]))


func test_afinidade_baixa_desobedece() -> void:
	var a: Variant = _criar(0.2, 0.9, 0.7, 0.0, 0.4, "autonomia")
	var conta := _contar(a, 200)
	checar(int(conta["obedece"]) <= 40,
		"afinidade baixa: %d/200 obedece (esperado ≤ 20%%)" % int(conta["obedece"]))
	checar(int(conta["desobedece"]) >= 1,
		"afinidade baixa: ao menos uma desobediência (%d)" % int(conta["desobedece"]))


func test_obediencia_nao_cai_com_afinidade() -> void:
	var taxas: Array[int] = []
	for afin in [0.0, 0.5, 1.0]:
		var a: Variant = _criar(0.9, 0.1, 0.6, afin, 0.6, "autonomia")
		taxas.append(int(_contar(a, 200)["obedece"]))
	checar(taxas[1] >= taxas[0] - 10,
		"afinidade 0,5 não obedece menos que 0,0 (%d ≥ %d)" % [taxas[1], taxas[0]])
	checar(taxas[2] >= taxas[1] - 10,
		"afinidade 1,0 não obedece menos que 0,5 (%d ≥ %d)" % [taxas[2], taxas[1]])


func test_registrar_mantem_limites() -> void:
	var a: Variant = _criar(0.55, 0.35, 0.6, 0.5, 0.5, "autonomia")
	var ordem := ["obedece", "desobedece", "hesita", "reinterpreta"]
	for i in 500:
		a.registrar({"decisao": ordem[i % ordem.size()]})
		checar(a.afinidade >= 0.0 and a.afinidade <= 1.0, "afinidade no passo %d" % i)
		checar(a.humor >= 0.0 and a.humor <= 1.0, "humor no passo %d" % i)
	var sobe: Variant = _criar(0.55, 0.35, 0.6, 0.4, 0.5, "autonomia")
	for i in 500:
		sobe.registrar({"decisao": "obedece"})
	perto(float(sobe.afinidade), 1.0, 0.0, "obedecer aproxima até o teto")
	var desce: Variant = _criar(0.55, 0.35, 0.6, 0.6, 0.5, "autonomia")
	for i in 500:
		desce.registrar({"decisao": "desobedece"})
	perto(float(desce.afinidade), 0.0, 0.0, "desobedecer afasta até o piso")


func test_sincronia_x_autonomia() -> void:
	var sin: Variant = _criar(0.95, 0.05, 0.5, 1.0, 0.7, "sincronia")
	var aut: Variant = _criar(0.95, 0.05, 0.5, 1.0, 0.7, "autonomia")
	var cs := _contar(sin, 200)
	var ca := _contar(aut, 200)
	igual(int(cs["obedece"]), 200, "Sincronia com afinidade alta obedece 100%")
	checar(int(ca["obedece"]) < int(cs["obedece"]),
		"Autonomia obedece menos no mesmo estado (%d < %d)" % [int(ca["obedece"]), int(cs["obedece"])])


func test_hesita_atrasa_e_mantem_comando() -> void:
	var a: Variant = _criar(0.1, 0.9, 0.05, 0.3, 0.35, "autonomia")
	var cmd := _cmd_tiro()
	var dec := _achar(a, "hesita", cmd)
	checar(not dec.is_empty(), "alguma semente hesita")
	if dec.is_empty():
		return
	checar(float(dec["atraso_s"]) > 0.0, "hesitar atrasa (%s)" % dec["atraso_s"])
	perto(float(dec["atraso_s"]), float(cfg["hesita_atraso_s"]), 0.0, "atraso vem do JSON")
	igual(dec["comando"], cmd, "hesitar não muda o comando")


func test_reinterpreta_desloca_sem_trocar_acao() -> void:
	var a: Variant = _criar(0.1, 0.2, 1.0, 0.4, 0.6, "autonomia")
	var cmd := _cmd_mover()
	var dec := _achar(a, "reinterpreta", cmd)
	checar(not dec.is_empty(), "alguma semente reinterpreta o caminho")
	if not dec.is_empty():
		var c: Dictionary = dec["comando"]
		igual(str(c["acao"]), "mover", "reinterpretar mantém a ação")
		igual(c["alvo"], cmd["alvo"], "em mover, o alvo não se mexe")
		var antes: PackedVector2Array = cmd["pontos"]
		var depois: PackedVector2Array = c["pontos"]
		igual(depois.size(), antes.size(), "o caminho continua com os mesmos pontos")
		if depois.size() == antes.size() and depois.size() > 0:
			perto(depois[depois.size() - 1].distance_to(antes[antes.size() - 1]),
				float(cfg["reinterpreta_desvio_px"]), 0.001, "a ponta anda o desvio do JSON")
			for i in antes.size() - 1:
				igual(depois[i], antes[i], "só a ponta muda (ponto %d)" % i)
		igual(cmd, _cmd_mover(), "o comando do jogador não é tocado")
	var tiro := _cmd_tiro()
	var dec2 := _achar(a, "reinterpreta", tiro)
	checar(not dec2.is_empty(), "alguma semente reinterpreta o tiro")
	if not dec2.is_empty():
		var c2: Dictionary = dec2["comando"]
		igual(str(c2["acao"]), "tiro", "reinterpretar mantém a ação do tiro")
		perto(Vector2(c2["alvo"]).distance_to(tiro["alvo"]),
			float(cfg["reinterpreta_desvio_px"]), 0.001, "fora de mover, o alvo anda o desvio")
		igual(c2["pontos"], tiro["pontos"], "o alvo deslocado não inventa caminho")


func test_obedece_devolve_comando_identico() -> void:
	var a: Variant = _criar(0.95, 0.05, 0.5, 1.0, 0.7, "sincronia")
	var cmd := _cmd_mover()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var dec: Dictionary = a.decidir(cmd, rng)
	igual(str(dec["decisao"]), "obedece", "Sincronia com afinidade alta obedece")
	perto(float(dec["atraso_s"]), 0.0, 0.0, "obedecer não atrasa")
	igual(dec["comando"], cmd, "obedecer devolve o mesmo comando")


func test_desobedece_devolve_vazio() -> void:
	var a: Variant = _criar(0.2, 0.9, 0.7, 0.0, 0.4, "autonomia")
	var dec := _achar(a, "desobedece", _cmd_mover())
	checar(not dec.is_empty(), "alguma semente desobedece")
	if not dec.is_empty():
		igual(dec["comando"], {}, "desobedecer devolve comando vazio")
		perto(float(dec["atraso_s"]), 0.0, 0.0, "desobedecer não agenda atraso")


func test_comando_vazio_devolve_vazio() -> void:
	var a: Variant = _criar(0.95, 0.05, 0.5, 1.0, 0.7, "sincronia")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	igual(a.decidir({}, rng), {}, "sem comando, sem decisão")
