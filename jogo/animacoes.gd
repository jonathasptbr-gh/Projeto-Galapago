extends RefCounted
## CATÁLOGO DE ANIMAÇÕES — carrega `dados/animacoes.json` com o validador puro.
## Só leitura e cache; quem escolhe o clipe é `sim/animacao.gd`.

const Anim := preload("res://sim/animacao.gd")
const CAMINHO := "res://dados/animacoes.json"

static var _cache: Dictionary = {}


static func carregar() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	if not FileAccess.file_exists(CAMINHO):
		push_error("catálogo de animações ausente: " + CAMINHO)
		return {}
	var texto := FileAccess.get_file_as_string(CAMINHO)
	var m := Anim.de_json(texto)
	if m.is_empty():
		var bruto: Variant = JSON.parse_string(texto)
		var erro := "JSON ilegível" if not bruto is Dictionary else Anim.validar(bruto)
		push_error("catálogo de animações inválido: " + erro)
		return {}
	_cache = m
	return m


static func limpar_cache() -> void:
	_cache.clear()
