extends RefCounted
## ESQUELETO 3D — juntas e ossos em 3D projetados ortograficamente em 2D
## (LÓGICA PURA). Fase A: matemática, sem camadas de pixel art.
##
## Convenção do mundo (a mesma do estudo e do rig 2D):
##   x = lateral (direita do cão positiva), y = altura, z = frente.
##   chão em y = 0; o pivô do canvas é o ponto do chão (34, 50).
## A câmera é ortográfica com yaw de 45° em 45° (8 setores de sim/direcao.gd)
## e pitch de 20° (LOW TOP-DOWN). O yaw NÃO gira o modelo: a câmera gira em
## volta dele. O desenho ordena do longe para o perto pela profundidade.
##
## O rig é DADO (`dados/rig/canino3d.json`); este arquivo valida fail-closed,
## avalia a pose por fase/clipe, projeta, resolve socket por NOME e devolve o
## MESMO formato de pose que `jogo/modulos.gd` e `jogo/pele_geometrica.gd`
## esperam: `juntas` (Vector2 no canvas) + `sockets` resolvidos. As peças 2D
## por osso (`pecas`) já são validadas, mas NÃO são desenhadas nesta fase.

const DIRECOES := ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
const YAW_GRAUS := {
	"south": 90.0, "south-east": 45.0, "east": 0.0, "north-east": 315.0,
	"north": 270.0, "north-west": 225.0, "west": 180.0, "south-west": 135.0,
}
const CLIPES := ["idle", "walk", "run", "jump_start", "jump_air", "jump_land", "charge", "shot",
	"bite", "slam", "dig", "hit", "stunned", "death", "get_up"]
const PITCH_GRAUS := 20.0
const JUNTAS_ESPERADAS := 22
const OSSOS_ESPERADOS := 21
const SOCKETS_OBRIGATORIOS := ["boca", "coroa", "base_cauda", "dorso"]
const Z := ["front", "back"]


## Lê o JSON e valida. Devolve {} (falha fechada) para texto ou rig inválido.
static func de_json(texto: String) -> Dictionary:
	var v: Variant = JSON.parse_string(texto)
	if not v is Dictionary:
		return {}
	var m: Dictionary = v
	if validar(m) != "":
		return {}
	return m


## Primeiro erro encontrado; vazio = rig 3D válido.
static func validar(m: Dictionary) -> String:
	if int(m.get("schema_version", 0)) != 2:
		return "schema_version != 2"
	if not m.get("id") is String or (m["id"] as String).is_empty():
		return "id ausente"
	if m.get("arquetipo") != "quadrupede":
		return "arquetipo != quadrupede"
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

	var juntas: Variant = m.get("juntas")
	if not juntas is Dictionary:
		return "juntas inválido"
	if (juntas as Dictionary).size() != JUNTAS_ESPERADAS:
		return "juntas: esperado %d, veio %d" % [JUNTAS_ESPERADAS, (juntas as Dictionary).size()]
	for nome in juntas:
		if not _v3(juntas[nome]):
			return "junta %s inválida" % nome

	var ossos: Variant = m.get("ossos")
	if not ossos is Array:
		return "ossos inválido"
	if (ossos as Array).size() != OSSOS_ESPERADOS:
		return "ossos: esperado %d, veio %d" % [OSSOS_ESPERADOS, (ossos as Array).size()]
	var usados: Dictionary = {}
	for i in (ossos as Array).size():
		var b: Variant = (ossos as Array)[i]
		if not b is Dictionary:
			return "osso %d não é objeto" % i
		var osso: Dictionary = b
		var a: Variant = osso.get("a")
		var bb: Variant = osso.get("b")
		if not a is String or not (juntas as Dictionary).has(a):
			return "osso %d com junta A ausente" % i
		if not bb is String or not (juntas as Dictionary).has(bb):
			return "osso %d com junta B ausente" % i
		if a == bb:
			return "osso %d liga a junta a si mesma" % i
		var largura: Variant = osso.get("largura")
		if not (largura is int or largura is float) or not is_finite(float(largura)) or float(largura) <= 0.0:
			return "osso %d sem largura positiva" % i
		usados[a] = true
		usados[bb] = true
	for nome in juntas:
		if not usados.has(nome):
			return "junta %s não pertence a osso" % nome

	var corpo: Variant = m.get("corpo")
	if not corpo is Array or (corpo as Array).is_empty():
		return "corpo vazio"
	for nome in corpo:
		if not (juntas as Dictionary).has(nome):
			return "corpo com junta inexistente"

	var dirs: Variant = m.get("directions")
	if not dirs is Dictionary or (dirs as Dictionary).size() != 8:
		return "directions != 8"
	for dir in DIRECOES:
		if not (dirs as Dictionary).has(dir):
			return "direção ausente: " + dir
		var info: Variant = (dirs as Dictionary)[dir]
		if not info is Dictionary:
			return "direção %s não é objeto" % dir
		var d: Dictionary = info
		var y: Variant = d.get("yaw")
		if not (y is int or y is float) or not is_finite(float(y)):
			return "direção %s sem yaw" % dir
		if absf(float(y) - float(YAW_GRAUS[dir])) > 0.01:
			return "direção %s com yaw diferente do setor" % dir
		if not d.get("mirror") is bool or not d.get("costas") is bool:
			return "direção %s: mirror/costas" % dir
	for dir in dirs:
		if dir not in DIRECOES:
			return "direção desconhecida: " + str(dir)

	var sockets: Variant = m.get("sockets")
	if not sockets is Dictionary:
		return "sockets inválido"
	for obrig in SOCKETS_OBRIGATORIOS:
		if not (sockets as Dictionary).has(obrig):
			return "socket obrigatório ausente: " + obrig
	for nome in sockets:
		var s: Variant = (sockets as Dictionary)[nome]
		if not s is Dictionary:
			return "socket %s não é objeto" % nome
		var item: Dictionary = s
		if not item.get("joint") is String or not (juntas as Dictionary).has(item["joint"]):
			return "socket %s aponta junta inexistente" % nome
		if not _v3(item.get("offset")):
			return "socket %s com offset 3D inválido" % nome
		if not (item.get("z") in Z):
			return "socket %s com z inválido" % nome
		if item.has("uso") and item["uso"] != "vfx":
			return "socket %s com uso inválido" % nome
		if not item.get("oculto_em") is Array:
			return "socket %s sem oculto_em" % nome
		for oculta in item["oculto_em"]:
			if oculta not in DIRECOES:
				return "socket %s oculto em direção desconhecida" % nome

	var clips: Variant = m.get("clips")
	if not clips is Dictionary:
		return "clips inválido"
	for clipe in CLIPES:
		if not (clips as Dictionary).has(clipe):
			return "clipe %s ausente" % clipe
		var c: Variant = (clips as Dictionary)[clipe]
		if not c is Dictionary:
			return "clipe %s não é objeto" % clipe
		if not (c as Dictionary).get("loop") is bool:
			return "clipe %s sem loop" % clipe
		if float((c as Dictionary).get("duracao_s", 0.0)) <= 0.0:
			return "clipe %s sem duração positiva" % clipe

	var motion: Variant = m.get("motion")
	if not motion is Dictionary:
		return "motion inválido"
	for chave in motion:
		var v2: Variant = (motion as Dictionary)[chave]
		if not (v2 is int or v2 is float) or not is_finite(float(v2)):
			return "motion.%s inválido" % chave

	# Fase B: o modelo de dados já aceita peças 2D por osso; nada as desenha.
	var pecas: Variant = m.get("pecas", [])
	if not pecas is Array:
		return "pecas inválido"
	for i in (pecas as Array).size():
		var p: Variant = (pecas as Array)[i]
		if not p is Dictionary:
			return "peça %d não é objeto" % i
		var peca: Dictionary = p
		var osso: Variant = peca.get("osso")
		if osso is String:
			if not usados.has(osso):
				return "peça %d aponta osso inexistente" % i
		elif osso is int or osso is float:
			if int(osso) < 0 or int(osso) >= (ossos as Array).size():
				return "peça %d com índice de osso fora" % i
		else:
			return "peça %d sem osso" % i
		var poly: Variant = peca.get("poly")
		if not poly is Array or (poly as Array).size() < 3:
			return "peça %d com poly inválido" % i
		for q in poly:
			if not _par(q):
				return "peça %d com ponto inválido" % i
		if float(peca.get("w", 0.0)) <= 0.0:
			return "peça %d sem largura" % i
		for cor in ["fill", "outline"]:
			var texto: Variant = peca.get(cor)
			if not texto is String or not (texto as String).is_valid_html_color():
				return "peça %d com %s inválido" % [i, cor]
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


static func yaw(direcao: String) -> float:
	if not YAW_GRAUS.has(direcao):
		return NAN
	return deg_to_rad(float(YAW_GRAUS[direcao]))


static func pitch() -> float:
	return deg_to_rad(PITCH_GRAUS)


## Pose 3D completa. Devolve {} para direção/clipe desconhecido — nunca
## inventa pose. `juntas` é o contrato 2D (Vector2 no canvas); `juntas_3d`,
## `profundidade` e `sockets` são o que o desenho 3D e os módulos consomem.
static func pose(m: Dictionary, direcao: String, fase: float, clipe: String = "walk",
		salto_correndo: bool = false) -> Dictionary:
	if m.is_empty() or not m.get("directions") is Dictionary:
		return {}
	if not (m["directions"] as Dictionary).has(direcao):
		return {}
	if clipe not in CLIPES:
		return {}
	var j := _juntas_rest(m)
	if j.is_empty():
		return {}
	var f := clampf(fase, 0.0, 1.0)
	var loop := true
	var clips: Variant = m.get("clips", {})
	if clips is Dictionary and (clips as Dictionary).has(clipe):
		loop = bool((clips as Dictionary)[clipe].get("loop", true))
	if loop:
		f = wrapf(fase, 0.0, 1.0)
	var mo: Dictionary = m.get("motion", {})
	var pernas := _pernas(m)
	var patas := _patas(pernas, clipe, f, mo)
	_mover_corpo(m, j, clipe, f, mo)
	for perna in pernas:
		var nome := String(perna["nome"])
		var upper := String(perna["upper"])
		var P: Vector3 = j[upper]
		var F: Vector3 = patas[nome]
		var K := _ik(P, F, float(perna["l1"]), float(perna["l2"]), float(perna["bend"]))
		j["joelho_" + nome] = K
		j["pata_" + nome] = F
	_extras(j, clipe, f, mo)
	if clipe == "death":
		_deitar(j, f)
	elif clipe == "get_up":
		_deitar(j, 1.0 - f)
	return _projetar_pose(m, j, direcao, clipe, f)


## Projeção ortográfica. Devolve Vector3(sx, sy_para_baixo, profundidade_longe).
## yaw gira em torno de Y; pitch é a elevação da câmera (0 = de lado,
## 90 = de cima). A profundidade é usada só para a ordenação do pintor.
static func projetar(p: Vector3, yaw_rad: float, pitch_rad: float) -> Vector3:
	var cy := cos(yaw_rad)
	var sy := sin(yaw_rad)
	var cp := cos(pitch_rad)
	var sp := sin(pitch_rad)
	var sx := -p.x * sy + p.z * cy
	var syd := p.x * cy * sp - p.y * cp + p.z * sy * sp
	var prof := -(p.x * cy * cp + p.y * sp + p.z * sy * cp)
	return Vector3(sx, syd, prof)


## Ponto do mundo → px do canvas (pivô do chão em `pivot_px`).
static func para_canvas(projetado: Vector3, m: Dictionary) -> Vector2:
	var piv: Array = m["pivot_px"]
	return Vector2(float(piv[0]) + projetado.x, float(piv[1]) + projetado.y)


## Ordem do pintor: longe → perto. Determinística (empate por id estável),
## usada pelo desenho e testável sem nó.
static func ordem_pintor(rig: Dictionary, p: Dictionary) -> Array:
	var itens: Array = []
	var juntas: Dictionary = p.get("juntas", {})
	var prof: Dictionary = p.get("profundidade", {})
	if juntas.is_empty() or prof.is_empty():
		return itens
	var ossos: Array = rig.get("ossos", [])
	for i in ossos.size():
		var b: Dictionary = ossos[i]
		var a := String(b["a"])
		var bb := String(b["b"])
		if not prof.has(a) or not prof.has(bb):
			continue
		itens.append({"tipo": "osso", "id": "osso:%03d:%s>%s" % [i, a, bb],
			"a": a, "b": bb, "largura": float(b.get("largura", 2.0)),
			"profundidade": (float(prof[a]) + float(prof[bb])) * 0.5})
	for nome in rig.get("juntas", {}):
		if not juntas.has(nome) or not prof.has(nome):
			continue
		itens.append({"tipo": "junta", "id": "junta:" + String(nome),
			"nome": String(nome), "profundidade": float(prof[nome])})
	itens.sort_custom(func(x, y):
		var dx := float(x["profundidade"])
		var dy := float(y["profundidade"])
		if absf(dx - dy) < 0.000001:
			return String(x["id"]) < String(y["id"])
		return dx > dy)
	return itens


## Adaptador: devolve um rig/pose no formato EXATO que `jogo/modulos.gd` e
## `sim/modulos.gd` já consomem (socket por nome via sim/esqueleto.gd), sem
## mudar uma linha deles. Os sockets viram juntas sintéticas na pose 2D.
static func adaptar_modulos(rig: Dictionary, p: Dictionary, direcao: String) -> Dictionary:
	var juntas_mod: Dictionary = (p.get("juntas", {}) as Dictionary).duplicate()
	var sockets: Dictionary = p.get("sockets", {})
	var nomes: Dictionary = {}
	for nome in sockets:
		var chave := "sock__" + String(nome)
		nomes[nome] = chave
		juntas_mod[chave] = sockets[nome]["pos"]
	var dirs: Dictionary = {}
	for dir in DIRECOES:
		dirs[dir] = {"profile": "mod", "mirror": false, "costas": false}
	var socks_mod: Dictionary = {}
	for nome in sockets:
		var s: Dictionary = sockets[nome]
		var item := {"joint": String(nomes[nome]), "offset": [0, 0], "z": s["z"],
			"oculto_em": [] if bool(s["visivel"]) else DIRECOES.duplicate()}
		if s.has("uso"):
			item["uso"] = s["uso"]
		socks_mod[nome] = item
	var rig_mod := {
		"pivot_px": rig.get("pivot_px", [34, 50]),
		"directions": dirs,
		"sockets": socks_mod,
		"profiles": {"mod": {"joints": juntas_mod, "bones": []}},
	}
	var pose_mod := {
		"juntas": juntas_mod,
		"sockets": sockets,
		"direcao": direcao,
		"clipe": p.get("clipe", ""),
		"fase": p.get("fase", 0.0),
	}
	return {"rig": rig_mod, "pose": pose_mod}


# --- pose: montagem ---

static func _juntas_rest(m: Dictionary) -> Dictionary:
	var j: Dictionary = {}
	var bruto: Variant = m.get("juntas", {})
	if not bruto is Dictionary:
		return j
	for nome in bruto:
		j[nome] = _vec(bruto[nome])
	return j


## As quatro pernas, derivadas das juntas de repouso (sem metadado extra):
## `upper` → `joelho` → `pata`; o comprimento de cada osso sai do próprio rig.
static func _pernas(m: Dictionary) -> Array:
	var out: Array = []
	var j: Dictionary = m.get("juntas", {})
	var defs := [["fe", "ombro_e"], ["fd", "ombro_d"], ["te", "anca_e"], ["td", "anca_d"]]
	for d in defs:
		var nome := String(d[0])
		var upper := String(d[1])
		var joelho := "joelho_" + nome
		var pata := "pata_" + nome
		if not j.has(upper) or not j.has(joelho) or not j.has(pata):
			continue
		var pu := _vec(j[upper])
		var pk := _vec(j[joelho])
		var pp := _vec(j[pata])
		out.append({"nome": nome, "upper": upper, "x": pp.x, "rest_z": pp.z,
			"l1": pu.distance_to(pk), "l2": pk.distance_to(pp),
			"bend": 1.0 if upper.begins_with("ombro") else -1.0})
	return out


## Alvos de pata. Apoio = y 0 (chão do MUNDO); balanço = arco em y. A marcha
## de 4 tempos usa LH→LF→RH→RF; o galope usa o par traseiro e depois o
## dianteiro, com suspensão. Nos clipes de ação as patas ficam plantadas.
static func _patas(pernas: Array, clipe: String, f: float, mo: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for perna in pernas:
		var nome := String(perna["nome"])
		var x := float(perna["x"])
		var z := float(perna["rest_z"])
		var y := 0.0
		if clipe == "walk":
			var duty := float(mo.get("duty_walk", 0.65))
			var offs := {"te": 0.0, "fe": 0.25, "td": 0.5, "fd": 0.75}
			var passo := float(mo.get("passo_px", 5.0))
			var c := fposmod(f - float(offs.get(nome, 0.0)), 1.0)
			if c < duty:
				z += passo * 0.5 - passo * (c / duty)
			else:
				var t := (c - duty) / (1.0 - duty)
				z += -passo * 0.5 + passo * t
				y = float(mo.get("levanta_px", 3.0)) * sin(PI * t)
		elif clipe == "run":
			var duty := float(mo.get("duty_galope", 0.25))
			var off := 0.0 if nome in ["te", "td"] else 0.5
			var passo := float(mo.get("galope_passo_px", 9.0))
			var c := fposmod(f - off, 1.0)
			if c < duty:
				z += passo * 0.5 - passo * (c / duty)
			else:
				var t := (c - duty) / (1.0 - duty)
				z += -passo * 0.5 + passo * t
				y = float(mo.get("galope_levanta_px", 5.0)) * sin(PI * t)
		elif clipe == "jump_air":
			var arco := sin(PI * f)
			y = 3.5 + 1.5 * arco
			z += (1.5 if String(perna["upper"]).begins_with("ombro") else -1.0) * arco
		elif clipe == "slam":
			z -= 2.0 * sin(PI * f)
		out[nome] = Vector3(x, y, z)
	return out


## Movimento do tronco por clipe. Só as juntas do corpo; as patas são alvos
## no chão e a IK resolve a perna depois.
static func _mover_corpo(m: Dictionary, j: Dictionary, clipe: String, f: float, mo: Dictionary) -> void:
	var dy := 0.0
	var dz := 0.0
	var dx := 0.0
	var pitch_corpo := 0.0
	match clipe:
		"idle":
			dy = float(mo.get("respira_px", 0.6)) * sin(TAU * f)
		"walk":
			dy = float(mo.get("corpo_px", 1.1)) * sin(TAU * f * 2.0 + 0.8)
		"run":
			var susp := 0.0
			for inicio in [0.25, 0.75]:
				var t := (f - float(inicio)) / 0.25
				if t >= 0.0 and t <= 1.0:
					susp = maxf(susp, float(mo.get("galope_suspensao_px", 2.4)) * sin(PI * t))
			dy = susp + 1.2 * sin(TAU * f * 2.0)
			pitch_corpo = deg_to_rad(float(mo.get("galope_pitch_graus", 5.0))) * sin(TAU * f + 0.6)
		"jump_start":
			dy = -2.5 * sin(PI * f)
		"jump_air":
			dy = 1.0 + 0.5 * sin(PI * f)
		"jump_land":
			dy = -3.0 * sin(PI * f)
		"charge":
			dy = -2.5
		"shot":
			dz = -2.5 * sin(PI * f)
		"hit":
			dz = -3.0 * sin(PI * f)
		"dig":
			dy = -5.0
		"stunned":
			dx = 2.6 * sin(TAU * f * 3.0)
		"slam":
			# O esbarrão avança mais do que agacha: em north (câmera dorsal) o
			# +z projeta para CIMA e um agachamento fundo cancelaria o sentido.
			dy = -0.8 * sin(PI * f)
			dz = 11.0 * sin(PI * f)
	var centro := Vector3(0.0, 18.0, -2.0)
	for nome in m.get("corpo", []):
		if not j.has(nome):
			continue
		var q: Vector3 = j[nome]
		q += Vector3(dx, dy, dz)
		if absf(pitch_corpo) > 0.00001:
			var ry := q.y - centro.y
			var rz := q.z - centro.z
			q.y = centro.y + ry * cos(pitch_corpo) - rz * sin(pitch_corpo)
			q.z = centro.z + ry * sin(pitch_corpo) + rz * cos(pitch_corpo)
		j[nome] = q
	if clipe == "slam":
		var extra := 3.0 * sin(PI * f)
		for nome in ["quadril", "peito", "ombro_e", "ombro_d", "anca_e", "anca_d"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) + Vector3(0, 0, extra)


## Cabeça, cauda e orelhas: gesto de leitura do clipe (não mexe em regra).
static func _extras(j: Dictionary, clipe: String, f: float, mo: Dictionary) -> void:
	if j.has("cauda_ponta") and clipe in ["idle", "walk", "run"]:
		var a := float(mo.get("cauda_px", 1.8)) * sin(TAU * f)
		j["cauda_base"] = (j["cauda_base"] as Vector3) + Vector3(a * 0.25, 0, 0)
		j["cauda_ponta"] = (j["cauda_ponta"] as Vector3) + Vector3(a * 0.85, 0, 0)
	if clipe == "idle":
		var resp := float(mo.get("respira_px", 0.6))
		for nome in ["cabeca", "focinho"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) + Vector3(0, sin(TAU * f + 0.4) * resp * 1.4, 0)
	elif clipe == "bite":
		var a := 6.0 * sin(PI * f)
		for nome in ["pescoco", "cabeca", "focinho", "orelha_e", "orelha_d"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) + Vector3(0, 0, a)
		if j.has("focinho"):
			j["focinho"] = (j["focinho"] as Vector3) + Vector3(0, 0, 2.0 * sin(PI * f * 3.0))
	elif clipe == "slam":
		var a := 3.0 * sin(PI * f)
		for nome in ["pescoco", "cabeca", "focinho", "orelha_e", "orelha_d"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) - Vector3(0, 0, a)
	elif clipe == "shot":
		var a := 2.5 * sin(PI * f)
		for nome in ["cabeca", "focinho"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) - Vector3(0, 0, a)
	elif clipe == "charge":
		var a := 3.0 * sin(PI * f)
		for nome in ["cabeca", "focinho"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) - Vector3(0, 0, a)
	elif clipe == "hit":
		var a := 1.5 * sin(PI * f)
		for nome in ["cabeca", "focinho"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) - Vector3(0, a, 0)
	elif clipe == "stunned":
		for nome in ["cabeca", "focinho"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) - Vector3(0, 3.0, 0)
	elif clipe == "jump_air":
		if j.has("cauda_ponta"):
			j["cauda_ponta"] = (j["cauda_ponta"] as Vector3) + Vector3(0, 2.0, 0)
		for nome in ["orelha_e", "orelha_d"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) + Vector3(0, 1.0, 0)


## Tomba/levanta: baixa o corpo e estende o focinho no chão, sem sair do
## canvas. A morte vai de f=0 (em pé) a f=1 (deitado); get_up faz o inverso.
static func _deitar(j: Dictionary, f: float) -> void:
	var q := clampf(f, 0.0, 1.0)
	for nome in j:
		var p: Vector3 = j[nome]
		var y := p.y * (1.0 - 0.82 * q)
		var z := p.z + (p.y - y) * 0.35
		j[nome] = Vector3(p.x, y, z)


## IK de dois ossos no plano y–z de cada lado; mantém o x do ombro/anca.
static func _ik(P: Vector3, F: Vector3, l1: float, l2: float, bend: float) -> Vector3:
	var dz := F.z - P.z
	var dy := F.y - P.y
	var d := sqrt(dz * dz + dy * dy)
	d = clampf(d, absf(l1 - l2) + 0.001, l1 + l2 - 0.001)
	var dir := Vector2(dz, dy) / d
	var a := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(0.0, l1 * l1 - a * a))
	var perp := Vector2(-dir.y, dir.x) * bend
	return Vector3(P.x, P.y + dir.y * a + perp.y * h, P.z + dir.x * a + perp.x * h)


# --- projeção, sockets e pose 2D ---

static func _projetar_pose(m: Dictionary, j: Dictionary, direcao: String, clipe: String, f: float) -> Dictionary:
	var yaw_rad := yaw(direcao)
	var pitch_rad := pitch()
	var pr: Dictionary = {}
	var prof: Dictionary = {}
	for nome in j:
		var p := projetar(j[nome], yaw_rad, pitch_rad)
		pr[nome] = para_canvas(p, m)
		prof[nome] = p.z
	var sockets := _sockets(m, j, pr, prof, direcao)
	return {"juntas": pr, "juntas_3d": j, "profundidade": prof, "sockets": sockets,
		"direcao": direcao, "clipe": clipe, "fase": f, "yaw": yaw_rad}


static func _sockets(m: Dictionary, j: Dictionary, pr: Dictionary, prof: Dictionary,
		direcao: String) -> Dictionary:
	var out: Dictionary = {}
	var socks: Variant = m.get("sockets", {})
	if not socks is Dictionary:
		return out
	var yaw_rad := yaw(direcao)
	var pitch_rad := pitch()
	for nome in socks:
		var s: Dictionary = socks[nome]
		var visivel: bool = not (direcao in s["oculto_em"])
		var pos := Vector2.ZERO
		var dep := 0.0
		if j.has(s["joint"]):
			var p3: Vector3 = (j[s["joint"]] as Vector3) + _vec(s["offset"])
			var p := projetar(p3, yaw_rad, pitch_rad)
			pos = para_canvas(p, m)
			dep = p.z
		else:
			visivel = false
		var item := {"pos": pos, "z": s["z"], "visivel": visivel, "profundidade": dep}
		if s.has("uso"):
			item["uso"] = s["uso"]
		out[nome] = item
	return out


# --- validação auxiliar ---

static func _vec(v: Variant) -> Vector3:
	if _v3(v):
		var a: Array = v
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO


static func _v3(v: Variant) -> bool:
	if not v is Array or (v as Array).size() != 3:
		return false
	for i in 3:
		var n: Variant = (v as Array)[i]
		if not (n is int or n is float) or not is_finite(float(n)):
			return false
	return true


static func _par(v: Variant) -> bool:
	if not v is Array or (v as Array).size() != 2:
		return false
	for i in 2:
		var n: Variant = (v as Array)[i]
		if not (n is int or n is float) or not is_finite(float(n)):
			return false
	return true
