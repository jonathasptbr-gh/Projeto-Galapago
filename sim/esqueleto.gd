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
## Unidades: px locais do canvas (origem no canto superior esquerdo); o pivô
## fica nos pés. Âncora ausente na direção NÃO existe naquele desenho — não
## herda posição do quadro anterior.

const DIRECOES := ["south", "west", "east", "north"]
const Z := ["front", "back"]
const CLIPES := ["idle", "walk"]


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
	var f := wrapf(fase, 0.0, 1.0)
	if clipe == "walk":
		if d["profile"] == "lateral":
			_ande_lateral(m, j, f)
		else:
			_ande_frontal(m, j, f)
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
	}


static func _ande_lateral(m: Dictionary, j: Dictionary, fase: float) -> void:
	var c := _cfg(m)
	var passo: float = c["passo"]
	var levanta: float = c["levanta"]
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


static func _ande_frontal(m: Dictionary, j: Dictionary, fase: float) -> void:
	var c := _cfg(m)
	var p := fase * TAU
	var s := sin(p)
	var bob: float = -float(c["corpo"]) * absf(s)
	for k in ["pata_e", "pata_d"]:
		if j.has(k):
			var f: float = s if k == "pata_e" else -s
			j[k] = j[k] + Vector2(0.0, -maxf(0.0, f) * float(c["levanta"]))
	for k in ["quadril", "lombo", "peito", "pescoco", "cabeca", "focinho", "orelha_e", "orelha_d", "cauda_base"]:
		if j.has(k):
			j[k] = j[k] + Vector2(0.0, bob)
	if j.has("cauda_ponta"):
		j["cauda_ponta"] = j["cauda_ponta"] + Vector2(sin(p + 1.2) * float(c["cauda"]), bob)


static func _respira(m: Dictionary, j: Dictionary, fase: float) -> void:
	var c := _cfg(m)
	var p := fase * TAU
	var respira: float = c["respira"]
	for k in ["quadril", "lombo", "peito", "pescoco"]:
		if j.has(k):
			j[k] = j[k] + Vector2(0.0, sin(p) * respira)
	if j.has("cabeca"):
		j["cabeca"] = j["cabeca"] + Vector2(0.0, sin(p + 0.4) * respira * 1.4)
	if j.has("focinho"):
		j["focinho"] = j["focinho"] + Vector2(0.0, sin(p + 0.4) * respira * 1.4)
	if j.has("cauda_ponta"):
		j["cauda_ponta"] = j["cauda_ponta"] + Vector2(sin(p * 0.5) * float(c["cauda"]) * 0.8, 0.0)
