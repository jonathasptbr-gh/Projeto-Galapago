extends RefCounted
## MÓDULOS E EFEITOS — resolução por NOME de socket (LÓGICA PURA).
##
## Um módulo (asa, tufo, espinho) e um efeito (faísca) não sabem coordenada:
## pedem um socket ao rig (`sim/esqueleto.gd`) e recebem posição/z daquela
## direção/fase. Socket ausente na direção = módulo NÃO desenhado (fail-closed).
## Nada aqui concede habilidade: `concede_habilidade` precisa ser falso.

const E := preload("res://sim/esqueleto.gd")
const FORMAS := ["tufo", "espinho", "asa", "faisca", "onda"]
const Z := ["front", "back"]


static func de_json(texto: String) -> Dictionary:
	var v: Variant = JSON.parse_string(texto)
	if not v is Dictionary:
		return {}
	var m: Dictionary = v
	if validar(m) != "":
		return {}
	return m


static func validar(m: Dictionary) -> String:
	if int(m.get("schema_version", 0)) != 1:
		return "schema_version != 1"
	var mods: Variant = m.get("modulos")
	if not mods is Dictionary or (mods as Dictionary).is_empty():
		return "módulos vazios"
	for id in mods:
		var item: Variant = mods[id]
		if not item is Dictionary:
			return "módulo %s não é objeto" % id
		var e := _validar_item(item, true)
		if e != "":
			return "módulo %s: %s" % [id, e]
	var efeitos: Variant = m.get("efeitos")
	if not efeitos is Dictionary or (efeitos as Dictionary).is_empty():
		return "efeitos vazios"
	for id in efeitos:
		var item2: Variant = efeitos[id]
		if not item2 is Dictionary:
			return "efeito %s não é objeto" % id
		var e2 := _validar_item(item2, false)
		if e2 != "":
			return "efeito %s: %s" % [id, e2]
	return ""


static func _validar_item(item: Dictionary, modulo: bool) -> String:
	if modulo:
		if not item.get("socket") is String or (item["socket"] as String).is_empty():
			return "socket ausente"
		if not item.get("requer") is Array:
			return "requer inválido"
		if item.get("concede_habilidade") != false:
			return "módulo não pode conceder habilidade"
		if not item.get("provisorio") is bool:
			return "provisorio inválido"
	else:
		if item.get("concede_habilidade") != false:
			return "efeito não pode conceder habilidade"
	if not (item.get("z") in Z):
		return "z inválido"
	if not (item.get("forma") in FORMAS):
		return "forma inválida"
	var cor: Variant = item.get("cor")
	if not cor is String or not (cor as String).is_valid_html_color():
		return "cor inválida"
	return ""


## Módulo resolvido na direção/pose: {} se não houver socket visível.
static func resolver(m: Dictionary, id: String, rig: Dictionary, pose: Dictionary, direcao: String) -> Dictionary:
	var mods: Dictionary = m.get("modulos", {})
	if not mods.has(id):
		return {}
	var item: Dictionary = mods[id]
	if item.get("concede_habilidade") != false:
		return {}
	# Um ponto reservado ao impacto não concede uma peça/asa ao canino.
	var socket: Dictionary = rig.get("sockets", {}).get(String(item["socket"]), {})
	if socket.get("uso", "") == "vfx":
		return {}
	var s := E.socket(rig, pose, direcao, String(item["socket"]))
	if s.is_empty():
		return {}
	if String(item["socket"]) not in item.get("requer", []):
		return {}
	return {"pos": s["pos"], "z": item["z"], "forma": item["forma"], "cor": item["cor"]}


## Quais módulos o rig aceita nesta direção (socket visível).
static func aplicaveis(m: Dictionary, rig: Dictionary, pose: Dictionary, direcao: String) -> PackedStringArray:
	var out := PackedStringArray()
	for id in m.get("modulos", {}):
		if not resolver(m, id, rig, pose, direcao).is_empty():
			out.append(String(id))
	return out


static func efeito(m: Dictionary, evento: String) -> Dictionary:
	var efeitos: Dictionary = m.get("efeitos", {})
	return efeitos.get(evento, {})
