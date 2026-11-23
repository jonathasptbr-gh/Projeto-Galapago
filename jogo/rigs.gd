extends RefCounted
## RIGS — carrega `dados/rig/<id>.json` com o avaliador de `sim/esqueleto.gd`.
## Só leitura e cache; quem desenha é `jogo/pele_geometrica.gd`.

const Esq := preload("res://sim/esqueleto.gd")
const PASTA := "res://dados/rig/"

static var _cache: Dictionary = {}


## {} = rig ausente ou inválido (falha fechada; não desenha).
static func carregar(id: String) -> Dictionary:
	if id.is_empty() or id.contains("/") or id.contains(".."):
		return {}
	if _cache.has(id):
		return _cache[id]
	var caminho := PASTA + id + ".json"
	if not FileAccess.file_exists(caminho):
		push_error("rig ausente: " + caminho)
		return {}
	var texto := FileAccess.get_file_as_string(caminho)
	var m := Esq.de_json(texto)
	if m.is_empty():
		var bruto: Variant = JSON.parse_string(texto)
		var erro := "JSON ilegível" if not bruto is Dictionary else Esq.validar(bruto)
		push_error("rig inválido: " + caminho + " — " + erro)
		return {}
	_cache[id] = m
	return m


static func limpar_cache() -> void:
	_cache.clear()
