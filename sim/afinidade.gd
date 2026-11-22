extends RefCounted
## AFINIDADE — LÓGICA PURA: temperamento × humor × vínculo decidem o que a
## criatura faz do comando do jogador — obedece, hesita, reinterpreta ou
## desobedece. Mesma semente + mesmo estado = a MESMA decisão, sempre (o
## sorteio vem do `RandomNumberGenerator` recebido, nunca do global).
##
## Sincronia × Autonomia são modos do MESMO pipeline. Em **Sincronia**, com
## afinidade a partir de `sincronia_limiar`, a criatura obedece na hora — sem
## sorteio que a contrarie; abaixo disso o ajuste do modo ainda puxa para
## obedecer. Em **Autonomia**, o mesmo estado obedece menos: o ajuste do modo
## soma para reinterpretar e desobedecer, porque é a criatura que lê o campo e
## age com pouca microgestão.
##
## Todo número de balanceamento (pesos, limiar, atraso, desvio e ganhos) mora
## em `dados/afinidade.json`; traço novo no JSON entra na soma sem tocar neste
## arquivo. Ver docs/CONCEITO.md §"Afinidade como mecânica de controle" e
## docs/ARQUITETURA.md §"As duas camadas".

const CAMINHO := "res://dados/afinidade.json"
const DECISOES := ["obedece", "hesita", "reinterpreta", "desobedece"]
const MODOS := ["sincronia", "autonomia"]

var temperamento: Dictionary = {}
var humor := 0.0
var afinidade := 0.0
var modo := "sincronia"

var _cfg: Dictionary = {}


func _init(cfg: Dictionary = {}) -> void:
	_cfg = cfg if not cfg.is_empty() else config()
	if _cfg.is_empty():
		return
	var e: Dictionary = _cfg["estado_inicial"]
	temperamento = e["temperamento"].duplicate()
	humor = clampf(float(e["humor"]), 0.0, 1.0)
	afinidade = clampf(float(e["afinidade"]), 0.0, 1.0)
	modo = str(e["modo"])


## Fábrica: a instância nasce com o estado inicial do JSON. `cfg` vazio lê o
## arquivo padrão; config inválida devolve uma instância vazia (decidir = {}).
static func novo(cfg: Dictionary = {}):
	return load("res://sim/afinidade.gd").new(cfg)


## Lê e valida o JSON; {} em erro (arquivo ausente, JSON quebrado, bloco ou
## número faltando). Validação de ESTRUTURA: os nomes dos traços são livres.
static func config(caminho := CAMINHO) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var texto := FileAccess.get_file_as_string(caminho)
	if texto.is_empty():
		return {}
	var d = JSON.parse_string(texto)
	if typeof(d) != TYPE_DICTIONARY:
		return {}
	if not _cfg_valida(d):
		return {}
	return d


## Probabilidade de cada decisão agora: soma ponderada genérica
## (traço × peso) + afinidade + humor + ajuste do modo, normalizada.
func probabilidades() -> Dictionary:
	if _cfg.is_empty():
		return {}
	var bruto := {}
	var total := 0.0
	for d in DECISOES:
		var s := 0.0
		var pesos: Dictionary = _cfg["pesos"][d]
		for t in pesos:
			s += float(pesos[t]) * float(temperamento.get(t, 0.0))
		s += float(_cfg["afinidade_peso"][d]) * afinidade
		s += float(_cfg["humor_peso"][d]) * humor
		s += float(_cfg["modo_ajuste"].get(modo, {}).get(d, 0.0))
		s = maxf(0.0, s)
		bruto[d] = s
		total += s
	var p := {}
	for d in DECISOES:
		p[d] = float(bruto[d]) / total if total > 0.0 else 0.0
	return p


## Decide o que fazer do comando. {} = não há comando (ou config inválida).
## Devolve {decisao, atraso_s, comando}. Em Sincronia com afinidade alta a
## obediência é imediata e não sorteia.
func decidir(comando: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if comando.is_empty() or rng == null or _cfg.is_empty():
		return {}
	if modo == "sincronia" and afinidade >= float(_cfg["sincronia_limiar"]):
		return {"decisao": "obedece", "atraso_s": 0.0, "comando": comando}
	var p := probabilidades()
	var total := 0.0
	for d in DECISOES:
		total += float(p[d])
	if total <= 0.0:
		return {"decisao": "obedece", "atraso_s": 0.0, "comando": comando}
	var r := rng.randf()
	var acumulado := 0.0
	for d in DECISOES:
		acumulado += float(p[d])
		if r <= acumulado:
			return _executar(d, comando, rng)
	return _executar("obedece", comando, rng)


func _executar(decisao: String, comando: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	match decisao:
		"hesita":
			return {"decisao": "hesita", "atraso_s": float(_cfg["hesita_atraso_s"]), "comando": comando}
		"reinterpreta":
			return {"decisao": "reinterpreta", "atraso_s": 0.0, "comando": _reinterpretar(comando, rng)}
		"desobedece":
			return {"decisao": "desobedece", "atraso_s": 0.0, "comando": {}}
		_:
			return {"decisao": "obedece", "atraso_s": 0.0, "comando": comando}


## Reinterpretar é deslocar a intenção, não trocar de ação: numa trajetória
## ("mover") a ponta do caminho anda `reinterpreta_desvio_px` numa direção
## sorteada; nos outros comandos, o alvo. O comando do jogador não é tocado.
func _reinterpretar(comando: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var c := comando.duplicate(true)
	var angulo := rng.randf() * TAU
	var desvio := Vector2(cos(angulo), sin(angulo)) * float(_cfg["reinterpreta_desvio_px"])
	if str(c.get("acao", "")) == "mover":
		var pontos: PackedVector2Array = c.get("pontos", PackedVector2Array())
		if pontos.is_empty():
			c["alvo"] = Vector2(c.get("alvo", Vector2.ZERO)) + desvio
		else:
			var novos := pontos.duplicate()
			novos[novos.size() - 1] = novos[novos.size() - 1] + desvio
			c["pontos"] = novos
	else:
		c["alvo"] = Vector2(c.get("alvo", Vector2.ZERO)) + desvio
	return c


## O que a decisão ensina ao vínculo: obedecer aproxima, desobedecer afasta.
## Sempre dentro de [0,1]; decisão desconhecida não mexe em nada.
func registrar(dec: Dictionary) -> void:
	if _cfg.is_empty() or dec.is_empty():
		return
	var d := str(dec.get("decisao", ""))
	if not (_cfg["ganhos"].has(d)):
		return
	afinidade = clampf(afinidade + float(_cfg["ganhos"][d]["afinidade"]), 0.0, 1.0)
	humor = clampf(humor + float(_cfg["ganhos"][d]["humor"]), 0.0, 1.0)


static func _num(d: Dictionary, chave: String) -> bool:
	return d.has(chave) and typeof(d[chave]) in [TYPE_INT, TYPE_FLOAT]


static func _bloco_dec(d: Variant, chaves: Array) -> bool:
	if typeof(d) != TYPE_DICTIONARY:
		return false
	for c in chaves:
		if typeof(d.get(c)) != TYPE_DICTIONARY:
			return false
	return true


static func _num_dec(d: Variant, chaves: Array) -> bool:
	if typeof(d) != TYPE_DICTIONARY:
		return false
	for c in chaves:
		if not _num(d, c):
			return false
	return true


static func _cfg_valida(d: Dictionary) -> bool:
	for k in ["estado_inicial", "pesos", "afinidade_peso", "humor_peso", "modo_ajuste", "ganhos"]:
		if typeof(d.get(k)) != TYPE_DICTIONARY:
			return false
	var e: Dictionary = d["estado_inicial"]
	if typeof(e.get("temperamento")) != TYPE_DICTIONARY or e["temperamento"].is_empty():
		return false
	for t in e["temperamento"]:
		if not _num(e["temperamento"], t):
			return false
	if not _num(e, "humor") or not _num(e, "afinidade") or not (str(e.get("modo", "")) in MODOS):
		return false
	if not _bloco_dec(d["pesos"], DECISOES):
		return false
	for decisao in DECISOES:
		# traço novo no JSON é bem-vindo: o que se exige é valor numérico.
		for t in d["pesos"][decisao]:
			if not _num(d["pesos"][decisao], t):
				return false
	for bloco in ["afinidade_peso", "humor_peso"]:
		if not _num_dec(d[bloco], DECISOES):
			return false
	if not _bloco_dec(d["ganhos"], DECISOES):
		return false
	for g in DECISOES:
		if not _num(d["ganhos"][g], "afinidade") or not _num(d["ganhos"][g], "humor"):
			return false
	var m: Dictionary = d["modo_ajuste"]
	for mo in MODOS:
		if not _num_dec(m.get(mo), DECISOES):
			return false
	if not _num(d, "hesita_atraso_s") or float(d["hesita_atraso_s"]) <= 0.0:
		return false
	if not _num(d, "reinterpreta_desvio_px") or float(d["reinterpreta_desvio_px"]) <= 0.0:
		return false
	if not _num(d, "sincronia_limiar"):
		return false
	var limiar := float(d["sincronia_limiar"])
	return limiar >= 0.0 and limiar <= 1.0
