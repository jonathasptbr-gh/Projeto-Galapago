extends RefCounted
## RIGS 3D — carrega `dados/rig/<id>.json` com o validador de
## `sim/esqueleto3d.gd`. Só leitura e cache; quem desenha é
## `jogo/pele_geometrica3d.gd`. Fail-closed: rig inválido devolve {}.

const Esq3 := preload("res://sim/esqueleto3d.gd")
const PASTA := "res://dados/rig/"

static var _cache: Dictionary = {}


## {} = rig ausente ou inválido (não desenha).
static func carregar(id: String) -> Dictionary:
	if id.is_empty() or id.contains("/") or id.contains(".."):
		return {}
	if _cache.has(id):
		return _cache[id]
	var caminho := PASTA + id + ".json"
	if not FileAccess.file_exists(caminho):
		push_error("rig 3D ausente: " + caminho)
		return {}
	var texto := FileAccess.get_file_as_string(caminho)
	var m := Esq3.de_json(texto)
	if m.is_empty():
		var bruto: Variant = JSON.parse_string(texto)
		var erro := "JSON ilegível" if not bruto is Dictionary else Esq3.validar(bruto)
		push_error("rig 3D inválido: " + caminho + " — " + erro)
		return {}
	_cache[id] = m
	return m


static func limpar_cache() -> void:
	_cache.clear()
