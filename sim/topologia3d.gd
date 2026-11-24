extends RefCounted
## Compilador de topologia: grafo de repouso em unidades de mundo (1 px = 1 unidade).
## Schema 3 é adaptado sem mudar a arte canina; schema 4 exige papéis explícitos.
const ARQUETIPOS := ["quadrupede", "bipede", "ave", "serpente"]
const PAPEIS := ["root", "pelvis", "spine", "chest", "neck", "head", "muzzle", "ear", "tail", "limb_front", "limb_back", "limb_joint", "limb_end", "wing", "socket"]


static func compilar(m: Dictionary) -> Dictionary:
	var j: Variant = m.get("juntas")
	var ossos: Variant = m.get("ossos")
	if not j is Dictionary or not ossos is Array or (j as Dictionary).is_empty():
		return {}
	var arquetipo := String(m.get("arquetipo", ""))
	if arquetipo not in ARQUETIPOS:
		return {}
	var schema := int(m.get("schema_version", 0))
	if schema not in [3, 4] or (schema == 3 and arquetipo != "quadrupede"):
		return {}
	var papeis: Dictionary = m.get("papeis", {}) if schema == 4 else _papeis_canino(j)
	if papeis.size() != (j as Dictionary).size():
		return {}
	var pais: Dictionary = {}
	var filhos: Dictionary = {}
	for nome in j:
		var p: Variant = j[nome]
		if not _vetor(p) or not papeis.has(nome) or papeis[nome] not in PAPEIS:
			return {}
		filhos[nome] = []
	for osso in ossos:
		if not osso is Dictionary:
			return {}
		var a: Variant = osso.get("a")
		var b: Variant = osso.get("b")
		var w: Variant = osso.get("largura")
		if not a is String or not b is String or not j.has(a) or not j.has(b) or a == b:
			return {}
		if not (w is int or w is float) or not is_finite(float(w)) or float(w) <= 0.0:
			return {}
		if pais.has(b) or _v(j[a]).distance_to(_v(j[b])) < 0.001:
			return {}
		pais[b] = a
		filhos[a].append(b)
	var roots: Array = []
	for nome in j:
		if not pais.has(nome):
			roots.append(nome)
	if roots.size() != 1 or papeis[roots[0]] not in ["root", "pelvis"]:
		return {}
	var visitados: Dictionary = {}
	var fila: Array = [roots[0]]
	while not fila.is_empty():
		var nome: String = fila.pop_front()
		if visitados.has(nome):
			return {}
		visitados[nome] = true
		fila.append_array(filhos[nome])
	if visitados.size() != j.size() or ossos.size() != j.size() - 1:
		return {}
	var limites := {"quadrupede": {"limb_front": 2, "limb_back": 2, "head": 1},
		"bipede": {"limb_front": 2, "limb_back": 2, "head": 1},
		"ave": {"wing": 2, "limb_back": 2, "head": 1}, "serpente": {"head": 1}}
	var counts: Dictionary = {}
	for papel in papeis.values():
		counts[papel] = int(counts.get(papel, 0)) + 1
	for papel in limites[arquetipo]:
		if int(counts.get(papel, 0)) != int(limites[arquetipo][papel]):
			return {}
	if arquetipo == "serpente" and int(counts.get("spine", 0)) < 2:
		return {}
	var membros: Array = []
	if arquetipo == "quadrupede":
		var defs: Variant = m.get("membros", _membros_canino() if schema == 3 else null)
		if not defs is Array or (defs as Array).size() != 4:
			return {}
		var lados: Dictionary = {}
		for item in defs:
			if not item is Dictionary:
				return {}
			var cadeia: Variant = item.get("cadeia")
			var papel := String(item.get("papel", ""))
			var lado := String(item.get("lado", ""))
			var pole: Variant = item.get("pole")
			if papel not in ["limb_front", "limb_back"] or lado not in ["e", "d"]:
				return {}
			if not _vetor(pole) or _v(pole).length() < 0.001:
				return {}
			if not cadeia is Array or (cadeia as Array).size() != (3 if papel == "limb_front" else 4):
				return {}
			var chave := papel + lado
			if lados.has(chave):
				return {}
			lados[chave] = true
			for i in cadeia.size():
				if not j.has(cadeia[i]) or (i > 0 and pais.get(cadeia[i]) != cadeia[i - 1]):
					return {}
			if papeis[cadeia[0]] != papel:
				return {}
			membros.append(item)
		if lados.size() != 4:
			return {}
	return {"raiz": roots[0], "pais": pais, "papeis": papeis, "membros": membros,
		"arquetipo": arquetipo, "articulacoes": j.size(), "acima_recomendacao": j.size() > 20,
		"locomocao_suportada": arquetipo == "quadrupede"}


static func _membros_canino() -> Array:
	return [
		{"papel": "limb_front", "lado": "e", "cadeia": ["ombro_e", "joelho_fe", "pata_fe"], "pole": [0, 0, -1]},
		{"papel": "limb_front", "lado": "d", "cadeia": ["ombro_d", "joelho_fd", "pata_fd"], "pole": [0, 0, -1]},
		{"papel": "limb_back", "lado": "e", "cadeia": ["anca_e", "joelho_te", "jarrete_te", "pata_te"], "pole": [0, 0, 1]},
		{"papel": "limb_back", "lado": "d", "cadeia": ["anca_d", "joelho_td", "jarrete_td", "pata_td"], "pole": [0, 0, 1]},
	]


static func _papeis_canino(j: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for nome in j:
		var n := String(nome)
		var papel := "spine"
		if n == "quadril": papel = "pelvis"
		elif n == "peito": papel = "chest"
		elif n == "pescoco": papel = "neck"
		elif n == "cabeca": papel = "head"
		elif n == "focinho": papel = "muzzle"
		elif n.begins_with("orelha_"): papel = "ear"
		elif n.begins_with("cauda_"): papel = "tail"
		elif n.begins_with("ombro_"): papel = "limb_front"
		elif n.begins_with("anca_"): papel = "limb_back"
		out[nome] = papel
	return out


static func _vetor(a: Variant) -> bool:
	if not a is Array or (a as Array).size() != 3:
		return false
	for n in a:
		if not (n is int or n is float) or not is_finite(float(n)):
			return false
	return true


static func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
