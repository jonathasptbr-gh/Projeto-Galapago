extends RefCounted
## ESQUELETO — contrato de pose e âncoras (LÓGICA PURA).
##
## Por que existe: a criatura desenhada por sprite e a criatura geométrica
## precisam responder às MESMAS perguntas — "onde está a boca?", "onde o pé?"
## — para que a mecânica não saiba qual pele está ativa. O rig é DADO
## (`dados/rig/<familia>.json`); este arquivo só valida, avalia a pose por fase
## e resolve âncora por NOME. Nada aqui decide regra de jogo: dano, alcance e
## tempo continuam em `sim/corpo.gd`. Socket decora, não decide.
##
## Oito direções: cardinais e diagonais; o desenho de 3/4 é perfil próprio.
##
## Unidades: px locais do canvas (origem no canto superior esquerdo); o pivô
## fica nos pés. Âncora ausente na direção NÃO existe naquele desenho — não
## herda posição do quadro anterior.

const DIRECOES := ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
const Z := ["front", "back"]
const CLIPES := ["idle", "walk", "run", "jump_start", "jump_air", "jump_land", "charge", "shot",
	"bite", "slam", "dig", "hit", "stunned", "death", "get_up"]


## Lê o JSON e valida. Devolve {} (falha fechada) para texto ou rig inválido.
static func de_json(texto: String) -> Dictionary:
	var v: Variant = JSON.parse_string(texto)
	if not v is Dictionary:
		return {}
	var m: Dictionary = v
	if validar(m) != "":
		return {}
	return m


## Primeiro erro encontrado; vazio = rig válido.
static func validar(m: Dictionary) -> String:
	if int(m.get("schema_version", 0)) != 1:
		return "schema_version != 1"
	if not m.get("id") is String or (m["id"] as String).is_empty():
		return "id ausente"
	if m.has("arquetipo") and not (m["arquetipo"] in ["quadrupede", "serpente", "ave", "slime"]):
		return "arquetipo desconhecido"
	for chave in ["canvas_px", "pivot_px"]:
		if not _par(m.get(chave)):
			return chave + " inválido"
		var par: Array = m[chave]
		if float(par[0]) <= 0.0 or float(par[1]) <= 0.0:
			return chave + " não positivo"
	var env: Variant = m.get("envelope_px")
	if not env is Dictionary:
		return "envelope_px ausente"
	for chave in ["altura", "comprimento", "largura"]:
		var valor: Variant = (env as Dictionary).get(chave)
		if not (valor is int or valor is float) or not is_finite(float(valor)) or float(valor) <= 0.0:
			return "envelope_px." + chave + " inválido"
	var perfis: Variant = m.get("profiles")
	if not perfis is Dictionary or (perfis as Dictionary).is_empty():
		return "profiles vazio"
	for nome in perfis:
		var erro := _validar_perfil(perfis[nome])
		if erro != "":
			return "perfil %s: %s" % [nome, erro]
	var dirs: Variant = m.get("directions")
	if not dirs is Dictionary or (dirs as Dictionary).is_empty():
		return "directions vazio"
	for dir in dirs:
		if dir not in DIRECOES:
			return "direção desconhecida: " + str(dir)
		var info: Variant = dirs[dir]
		if not info is Dictionary:
			return "direção %s não é objeto" % dir
		var d: Dictionary = info
		if not (perfis as Dictionary).has(d.get("profile")):
			return "direção %s sem perfil" % dir
		if not d.get("mirror") is bool or not d.get("costas") is bool:
			return "direção %s: mirror/costas" % dir
	var sockets: Variant = m.get("sockets")
	if not sockets is Dictionary:
		return "sockets inválido"
	for nome in sockets:
		var s: Variant = sockets[nome]
		if not s is Dictionary:
			return "socket %s não é objeto" % nome
		var item: Dictionary = s
		if not item.get("joint") is String:
			return "socket %s sem junta" % nome
		if not _par(item.get("offset")):
			return "socket %s com offset inválido" % nome
		if not (item.get("z") in Z):
			return "socket %s com z inválido" % nome
		if not item.get("oculto_em") is Array:
			return "socket %s sem oculto_em" % nome
		for oculta in item["oculto_em"]:
			if oculta not in DIRECOES:
				return "socket %s oculto em direção desconhecida" % nome
		if not _junta_existe(perfis, item["joint"]):
			return "socket %s aponta junta inexistente" % nome
	var clips: Variant = m.get("clips")
	if not clips is Dictionary:
		return "clips inválido"
	for clipe in CLIPES:
		if not (clips as Dictionary).has(clipe):
			return "clipe %s ausente" % clipe
		var c: Variant = clips[clipe]
		if not c is Dictionary or float((c as Dictionary).get("duracao_s", 0.0)) <= 0.0:
			return "clipe %s sem duração positiva" % clipe
	var motion: Variant = m.get("motion", {})
	if not motion is Dictionary:
		return "motion inválido"
	for chave in motion:
		var v2: Variant = motion[chave]
		if chave == "driver":
			if not v2 is String:
				return "motion.driver inválido"
			continue
		if not (v2 is int or v2 is float) or not is_finite(float(v2)):
			return "motion.%s inválido" % chave
	return ""


static func direcoes(m: Dictionary) -> PackedStringArray:
	var lista := PackedStringArray()
	if not m.get("directions") is Dictionary:
		return lista
	for dir in m["directions"]:
		lista.append(str(dir))
	return lista


static func envelope(m: Dictionary) -> Dictionary:
	var env: Variant = m.get("envelope_px", {})
	return env if env is Dictionary else {}


## Pose em px locais do canvas para (direção, fase 0..1, clipe).
## Devolve {} para direção/clipe desconhecido — nunca inventa pose.
static func pose(m: Dictionary, direcao: String, fase: float, clipe: String = "walk") -> Dictionary:
	if not m.get("directions") is Dictionary or not (m["directions"] as Dictionary).has(direcao):
		return {}
	if clipe not in CLIPES:
		return {}
	var d: Dictionary = m["directions"][direcao]
	var bruto: Dictionary = m["profiles"][d["profile"]]["joints"]
	var j: Dictionary = {}
	for nome in bruto:
		var p: Array = bruto[nome]
		j[nome] = Vector2(float(p[0]), float(p[1]))
	# Loop fecha em 0; clipe de uma vez PARA em 1 (a morte precisa chegar ao fim).
	var f := clampf(fase, 0.0, 1.0)
	var loop := true
	var clips: Variant = m.get("clips", {})
	if clips is Dictionary and (clips as Dictionary).has(clipe):
		loop = bool((clips as Dictionary)[clipe].get("loop", true))
	if loop:
		f = wrapf(fase, 0.0, 1.0)
	var frontal := String(d["profile"]) == "frontal"
	if clipe == "walk":
		_andar(m, j, d, f, 1.0)
	elif clipe == "run":
		_andar(m, j, d, f, 1.35)
	elif clipe == "bite":
		_ataque(j, f, frontal)
	elif clipe == "slam":
		_esbarrao(j, f, frontal)
	elif clipe == "shot":
		_tiro(j, f, frontal)
	elif clipe == "stunned":
		_tonto(j, f)
	elif clipe == "hit":
		_dano(j, f, frontal)
	elif clipe == "dig":
		_cava(j, f)
	elif clipe == "charge":
		_carrega(j, f, frontal)
	elif clipe == "jump_start":
		_pula_inicio(j, f)
	elif clipe == "jump_air":
		_pula_ar(j, f)
	elif clipe == "jump_land":
		_pula_pouso(j, f)
	elif clipe == "death":
		_tomba(m, j, f)
	elif clipe == "get_up":
		_levanta(m, j, f)
	else:
		_respira(m, j, f)
	if bool(d["mirror"]):
		var px := float(m["pivot_px"][0])
		for nome in j:
			j[nome] = Vector2(2.0 * px - j[nome].x, j[nome].y)
	return {"juntas": j, "direcao": direcao, "clipe": clipe, "fase": f}


## Âncoras por NOME. Toda âncora do rig aparece; `visivel` diz se existe
## naquela direção/pose. Chamador não herda posição: invisível = não desenha.
static func sockets(m: Dictionary, p: Dictionary, direcao: String) -> Dictionary:
	var t: Dictionary = {}
	var j: Dictionary = p.get("juntas", {})
	if not m.get("sockets") is Dictionary or not m.get("directions") is Dictionary:
		return t
	if not (m["directions"] as Dictionary).has(direcao):
		return t
	for nome in m["sockets"]:
		var s: Dictionary = m["sockets"][nome]
		var visivel: bool = not (direcao in s["oculto_em"])
		var pos := Vector2.ZERO
		if j.has(s["joint"]):
			var off: Array = s["offset"]
			var o := Vector2(float(off[0]), float(off[1]))
			if bool(m["directions"][direcao]["mirror"]):
				o.x = -o.x
			pos = j[s["joint"]] + o
		else:
			visivel = false
		t[nome] = {"pos": pos, "z": s["z"], "visivel": visivel}
	return t


## Âncora específica; {} quando não existe naquela direção.
static func socket(m: Dictionary, p: Dictionary, direcao: String, nome: String) -> Dictionary:
	var t := sockets(m, p, direcao)
	if not t.has(nome) or not t[nome]["visivel"]:
		return {}
	return t[nome]


static func duracao(m: Dictionary, clipe: String) -> float:
	var clips: Variant = m.get("clips", {})
	if not clips is Dictionary:
		return 0.0
	return float((clips as Dictionary).get(clipe, {}).get("duracao_s", 0.0))


# --- validação de perfil ---

static func _validar_perfil(p: Variant) -> String:
	if not p is Dictionary:
		return "não é objeto"
	var perfil: Dictionary = p
	var juntas: Variant = perfil.get("joints")
	if not juntas is Dictionary or (juntas as Dictionary).size() < 4:
		return "joints insuficientes"
	for nome in juntas:
		if not _par(juntas[nome]):
			return "junta %s inválida" % nome
	var ossos: Variant = perfil.get("bones")
	if not ossos is Array or (ossos as Array).is_empty():
		return "bones vazio"
	for b in ossos:
		if not b is Dictionary:
			return "osso não é objeto"
		var osso: Dictionary = b
		if not (juntas as Dictionary).has(osso.get("a")) or not (juntas as Dictionary).has(osso.get("b")):
			return "osso com junta ausente"
		if float(osso.get("w", 0.0)) <= 0.0:
			return "osso sem espessura"
	return ""


static func _junta_existe(perfis: Variant, junta: Variant) -> bool:
	for nome in perfis:
		var p: Dictionary = perfis[nome]
		if (p["joints"] as Dictionary).has(junta):
			return true
	return false


static func _par(v: Variant) -> bool:
	if not v is Array or (v as Array).size() != 2:
		return false
	for i in 2:
		var n: Variant = v[i]
		if not (n is int or n is float) or not is_finite(float(n)):
			return false
	return true


## Serpente: onda que corre da cauda (s0) à cabeça pela cadeia de juntas.
static func _rasteja(m: Dictionary, j: Dictionary, fase: float, fator := 1.0) -> void:
	var c := _cfg(m)
	var amp: float = float(c["onda"]) * fator
	var passo_onda: float = c["onda_passo"]
	var cadeia: Array[String] = []
	for i in 8:
		var nome := "s%d" % i
		if j.has(nome):
			cadeia.append(nome)
	for extra in ["pescoco", "cabeca"]:
		if j.has(extra):
			cadeia.append(extra)
	var n := cadeia.size()
	if n < 3:
		return
	var base: Dictionary = {}
	for i in n:
		base[cadeia[i]] = j[cadeia[i]]
	for i in n:
		var ant: String = cadeia[maxi(i - 1, 0)]
		var prox: String = cadeia[mini(i + 1, n - 1)]
		var dir: Vector2 = (base[prox] as Vector2) - (base[ant] as Vector2)
		if dir.length() < 0.001:
			continue
		var perp := dir.normalized().orthogonal()
		var taper := 0.35 + 0.65 * float(i) / float(maxi(n - 1, 1))
		var desloc: float = sin(fase * TAU - float(i) * passo_onda) * amp * taper
		j[cadeia[i]] = (base[cadeia[i]] as Vector2) + perp * desloc
	if j.has("boca") and base.has("cabeca"):
		j["boca"] = (j["boca"] as Vector2) + ((j["cabeca"] as Vector2) - (base["cabeca"] as Vector2)) * 0.8


## Ave: duas pernas alternam e o corpo balança; asa dobrada não anima ainda.
static func _bipede(m: Dictionary, j: Dictionary, fase: float, fator := 1.0) -> void:
	var c := _cfg(m)
	var passo: float = float(c["passo"]) * fator
	var levanta: float = float(c["levanta"]) * minf(fator, 1.2)
	var p := fase * TAU
	var s := sin(p)
	for k in ["pata_e", "pata_d"]:
		if j.has(k):
			var f: float = s if k == "pata_e" else -s
			j[k] = j[k] + Vector2(f * passo * 0.4, -maxf(0.0, f) * levanta)
			var coxa := "coxa_e" if k == "pata_e" else "coxa_d"
			if j.has(coxa):
				j[coxa] = j[coxa] + Vector2(f * passo * 0.2, -maxf(0.0, f) * levanta * 0.5)
	var bob: float = -float(c["corpo"]) * (0.5 + 0.5 * cos(2.0 * p))
	for k in ["corpo", "peito", "pescoco", "cabeca", "bico"]:
		if j.has(k):
			j[k] = j[k] + Vector2(0.0, bob)
	if j.has("cauda_ponta"):
		j["cauda_ponta"] = j["cauda_ponta"] + Vector2(sin(p + 1.0) * float(c["cauda"]), bob)


# --- drivers geométricos das ações (provisórios; a arte futura troca por clipes) ---

static func _desloca(j: Dictionary, delta: Vector2) -> void:
	for k in j:
		j[k] = (j[k] as Vector2) + delta


## Move o corpo sem arrastar os pés (patas ficam plantadas e a perna estica).
static func _desloca_corpo(j: Dictionary, delta: Vector2) -> void:
	for k in j:
		if String(k).begins_with("pata"):
			continue
		j[k] = (j[k] as Vector2) + delta


## Mordida: o corpo avança na direção em que olha e volta (fase 0..1).
static func _ataque(j: Dictionary, fase: float, frontal: bool) -> void:
	var s := sin(PI * fase)
	var frente := Vector2(0.0, s * 9.0) if frontal else Vector2(s * 9.0, 0.0)
	_desloca_corpo(j, frente)
	if j.has("cabeca"):
		j["cabeca"] = (j["cabeca"] as Vector2) + frente * 0.8
	if j.has("focinho"):
		j["focinho"] = (j["focinho"] as Vector2) + frente * 1.1
	if j.has("bico"):
		j["bico"] = (j["bico"] as Vector2) + frente * 0.9


## Atordoado: treme e a cabeça pende.
static func _tonto(j: Dictionary, fase: float) -> void:
	_desloca(j, Vector2(sin(fase * TAU * 3.0) * 2.6, 0.0))
	if j.has("cabeca"):
		j["cabeca"] = (j["cabeca"] as Vector2) + Vector2(0.0, 3.0)
	if j.has("focinho"):
		j["focinho"] = (j["focinho"] as Vector2) + Vector2(0.0, 3.0)


## Cavar: o corpo abaixa e a cabeça desce, com tremor curto.
static func _cava(j: Dictionary, fase: float) -> void:
	_desloca_corpo(j, Vector2(sin(fase * TAU * 2.0) * 0.8, 5.0))


## Carga do tiro: encolhe e puxa a cabeça para trás.
static func _carrega(j: Dictionary, fase: float, frontal: bool) -> void:
	var tras := Vector2(0.0, -3.0) if frontal else Vector2(-3.0, 0.0)
	_desloca_corpo(j, Vector2(0.0, 2.5))
	if j.has("cabeca"):
		j["cabeca"] = (j["cabeca"] as Vector2) + tras
	if j.has("focinho"):
		j["focinho"] = (j["focinho"] as Vector2) + tras
	if j.has("bico"):
		j["bico"] = (j["bico"] as Vector2) + tras


## Esbarrão: o corpo avança baixo, sem arrastar os pés.
static func _esbarrao(j: Dictionary, fase: float, frontal: bool) -> void:
	var s := sin(PI * fase)
	var frente := Vector2(0.0, s * 7.0) if frontal else Vector2(s * 7.0, 0.0)
	_desloca_corpo(j, frente + Vector2(0.0, 1.0))
	if j.has("cabeca"):
		j["cabeca"] = (j["cabeca"] as Vector2) + Vector2(0.0, 1.0)


## Tiro: recuo curto da cabeça e do tronco.
static func _tiro(j: Dictionary, fase: float, frontal: bool) -> void:
	var r := -2.5 * sin(PI * fase)
	var tras := Vector2(0.0, r) if frontal else Vector2(r, 0.0)
	_desloca_corpo(j, tras)


## Dano: recuo e cabeça baixa.
static func _dano(j: Dictionary, fase: float, frontal: bool) -> void:
	var r := -3.0 * sin(PI * fase)
	var tras := Vector2(0.0, r) if frontal else Vector2(r, 0.0)
	_desloca_corpo(j, tras)
	if j.has("cabeca"):
		j["cabeca"] = (j["cabeca"] as Vector2) + Vector2(0.0, 1.5)


## Início do pulo: agacha para pegar impulso.
static func _pula_inicio(j: Dictionary, fase: float) -> void:
	_desloca_corpo(j, Vector2(0.0, 2.5 * sin(PI * fase)))


## No ar: recolhe as patas (o nó já sobe com `corpo.z`).
static func _pula_ar(j: Dictionary, fase: float) -> void:
	for k in j:
		var nome := String(k)
		if nome.begins_with("pata"):
			j[k] = (j[k] as Vector2) + Vector2(0.0, -4.0)
		elif nome.begins_with("joelho") or nome.begins_with("coxa"):
			j[k] = (j[k] as Vector2) + Vector2(0.0, -2.5)
	_desloca_corpo(j, Vector2(0.0, -1.0 + sin(PI * fase) * 0.5))
	if j.has("cauda_ponta"):
		j["cauda_ponta"] = (j["cauda_ponta"] as Vector2) + Vector2(0.0, -2.0)


## Pouso: amortece (agacha).
static func _pula_pouso(j: Dictionary, fase: float) -> void:
	_desloca_corpo(j, Vector2(0.0, 3.0 * sin(PI * fase)))


## Tomba em torno dos pés (morte): 80° na direção em que olha.
static func _tomba(m: Dictionary, j: Dictionary, fase: float) -> void:
	_gira(j, Vector2(float(m["pivot_px"][0]), float(m["pivot_px"][1])), 80.0 * fase)


## Levanta: o inverso de tombar.
static func _levanta(m: Dictionary, j: Dictionary, fase: float) -> void:
	_gira(j, Vector2(float(m["pivot_px"][0]), float(m["pivot_px"][1])), 80.0 * (1.0 - fase))


static func _gira(j: Dictionary, piv: Vector2, graus: float) -> void:
	var rad := deg_to_rad(graus)
	var c := cos(rad)
	var s := sin(rad)
	for k in j:
		var p: Vector2 = (j[k] as Vector2) - piv
		j[k] = piv + Vector2(p.x * c - p.y * s, p.x * s + p.y * c)


# --- marcha provisória (dois perfis); a arte futura substitui por clipes ---

static func _cfg(m: Dictionary) -> Dictionary:
	var mo: Variant = m.get("motion", {})
	var d: Dictionary = mo if mo is Dictionary else {}
	return {
		"passo": float(d.get("passo_px", 5.0)),
		"levanta": float(d.get("levanta_px", 3.0)),
		"corpo": float(d.get("corpo_px", 1.0)),
		"cauda": float(d.get("cauda_px", 1.5)),
		"respira": float(d.get("respira_px", 0.5)),
		"onda": float(d.get("onda_px", 3.0)),
		"onda_passo": float(d.get("onda_passo", 0.9)),
	}


## Marcha por arquétipo (walk 1,0×; run 1,35×).
static func _andar(m: Dictionary, j: Dictionary, d: Dictionary, fase: float, fator: float) -> void:
	var tipo := String(m.get("arquetipo", "quadrupede"))
	if tipo == "serpente":
		_rasteja(m, j, fase, fator)
	elif tipo == "ave":
		_bipede(m, j, fase, fator)
	elif String(d["profile"]) == "frontal":
		_ande_frontal(m, j, fase, fator)
	else:
		_ande_lateral(m, j, fase, fator)


static func _ande_lateral(m: Dictionary, j: Dictionary, fase: float, fator := 1.0) -> void:
	var c := _cfg(m)
	var passo: float = float(c["passo"]) * fator
	var levanta: float = float(c["levanta"]) * minf(fator, 1.2)
	var p := fase * TAU
	var s := sin(p)
	var t := sin(p + PI)
	for lado in [["f", s], ["t", t]]:
		var suf: String = lado[0]
		var f: float = lado[1]
		for parte in ["pata_", "joelho_"]:
			var k: String = parte + suf
			if j.has(k):
				var escala: float = 1.0 if parte == "pata_" else 0.5
				j[k] = j[k] + Vector2(f * passo * escala, -maxf(0.0, f) * levanta * (1.0 if parte == "pata_" else 0.6))
		for parte in ["pata_", "joelho_"]:
			var k2: String = parte + suf + "2"
			if j.has(k2):
				var escala2: float = 1.0 if parte == "pata_" else 0.5
				j[k2] = j[k2] + Vector2(f * passo * 0.7 * escala2, -maxf(0.0, f) * levanta * 0.55)
	var bob: float = -float(c["corpo"]) * (0.5 + 0.5 * cos(2.0 * p))
	for k in ["quadril", "lombo", "peito", "pescoco", "cabeca", "focinho", "orelha", "cauda_base"]:
		if j.has(k):
			j[k] = j[k] + Vector2(0.0, bob)
	if j.has("cauda_ponta"):
		j["cauda_ponta"] = j["cauda_ponta"] + Vector2(sin(p + 0.8) * float(c["cauda"]), cos(p) * float(c["cauda"]) * 0.5 + bob)


static func _ande_frontal(m: Dictionary, j: Dictionary, fase: float, fator := 1.0) -> void:
	var c := _cfg(m)
	var p := fase * TAU
	var s := sin(p)
	var bob: float = -float(c["corpo"]) * absf(s)
	for k in ["pata_e", "pata_d"]:
		if j.has(k):
			var f: float = s if k == "pata_e" else -s
			j[k] = j[k] + Vector2(0.0, -maxf(0.0, f) * float(c["levanta"]) * minf(fator, 1.2))
	for k in ["quadril", "lombo", "peito", "pescoco", "cabeca", "focinho", "orelha_e", "orelha_d", "cauda_base"]:
		if j.has(k):
			j[k] = j[k] + Vector2(0.0, bob)
	if j.has("cauda_ponta"):
		j["cauda_ponta"] = j["cauda_ponta"] + Vector2(sin(p + 1.2) * float(c["cauda"]), bob)


static func _respira(m: Dictionary, j: Dictionary, fase: float) -> void:
	var c := _cfg(m)
	var p := fase * TAU
	var respira: float = c["respira"]
	for k in ["quadril", "lombo", "peito", "corpo", "pescoco"]:
		if j.has(k):
			j[k] = j[k] + Vector2(0.0, sin(p) * respira)
	if j.has("cabeca"):
		j["cabeca"] = j["cabeca"] + Vector2(0.0, sin(p + 0.4) * respira * 1.4)
	if j.has("focinho"):
		j["focinho"] = j["focinho"] + Vector2(0.0, sin(p + 0.4) * respira * 1.4)
	if j.has("bico"):
		j["bico"] = j["bico"] + Vector2(0.0, sin(p + 0.4) * respira * 1.4)
	if j.has("s0"):
		j["s0"] = j["s0"] + Vector2(sin(p * 0.5) * float(c["onda"]) * 0.4, 0.0)
	if j.has("cauda_ponta"):
		j["cauda_ponta"] = j["cauda_ponta"] + Vector2(sin(p * 0.5) * float(c["cauda"]) * 0.8, 0.0)
