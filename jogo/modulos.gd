extends RefCounted
## MÓDULOS E EFEITOS na tela — só desenho. Quem resolve socket é sim/modulos.gd.

const Mods := preload("res://sim/modulos.gd")
const E := preload("res://sim/esqueleto.gd")
const CAMINHO := "res://dados/modulos.json"
const TINTA := Color("#2a1a10")

static var _cache: Dictionary = {}


static func catalogo() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	if not FileAccess.file_exists(CAMINHO):
		push_error("módulos ausentes: " + CAMINHO)
		return {}
	var texto := FileAccess.get_file_as_string(CAMINHO)
	var m := Mods.de_json(texto)
	if m.is_empty():
		var bruto: Variant = JSON.parse_string(texto)
		var erro := "JSON ilegível" if not bruto is Dictionary else Mods.validar(bruto)
		push_error("módulos inválidos: " + erro)
		return {}
	_cache = m
	return m


static func desenhar(c: CanvasItem, rig: Dictionary, pose: Dictionary, direcao: String, base: Vector2,
		cat: Dictionary, ids: PackedStringArray, camada: String) -> void:
	if cat.is_empty():
		return
	var piv := Vector2(float(rig["pivot_px"][0]), float(rig["pivot_px"][1]))
	for id in ids:
		var r := Mods.resolver(cat, String(id), rig, pose, direcao)
		if r.is_empty() or String(r["z"]) != camada:
			continue
		var p: Vector2 = base + ((r["pos"] as Vector2) - piv)
		_forma(c, r, p)


static func desenhar_efeito(c: CanvasItem, rig: Dictionary, pose: Dictionary, direcao: String,
		base: Vector2, socket: String, evento: String, cat: Dictionary, alfa := 1.0) -> void:
	if cat.is_empty():
		return
	var e := Mods.efeito(cat, evento)
	if e.is_empty():
		return
	var s := E.socket(rig, pose, direcao, socket)
	if s.is_empty():
		return
	var piv := Vector2(float(rig["pivot_px"][0]), float(rig["pivot_px"][1]))
	var p: Vector2 = base + ((s["pos"] as Vector2) - piv)
	var cor := Color(String(e["cor"]))
	cor.a = clampf(alfa, 0.0, 1.0)
	_forma(c, e, p, cor)


static func _forma(c: CanvasItem, item: Dictionary, p: Vector2, cor := Color.WHITE) -> void:
	var tom := cor if cor.a < 0.999 else Color(String(item["cor"]))
	var tinta := TINTA
	tinta.a = tom.a
	match String(item["forma"]):
		"tufo":
			for i in 3:
				var dx := -3.0 + i * 3.0
				c.draw_colored_polygon(PackedVector2Array([p + Vector2(dx - 1.4, 0),
					p + Vector2(dx + 1.4, 0), p + Vector2(dx, -6.0 - i)]), tom)
		"espinho":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-2.4, 0), p + Vector2(2.4, 0),
				p + Vector2(0, -8.0)]), tinta)
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-1.8, 0), p + Vector2(1.8, 0),
				p + Vector2(0, -6.6)]), tom)
		"asa":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-13, 0), p + Vector2(0, -9),
				p + Vector2(13, 0), p + Vector2(0, 5)]), tinta)
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-11, 0), p + Vector2(0, -7.4),
				p + Vector2(11, 0), p + Vector2(0, 3.6)]), tom)
		"faisca":
			var pts := PackedVector2Array([p + Vector2(0, -8), p + Vector2(2, -2), p + Vector2(8, 0),
				p + Vector2(2, 2), p + Vector2(0, 8), p + Vector2(-2, 2), p + Vector2(-8, 0),
				p + Vector2(-2, -2)])
			c.draw_colored_polygon(pts, tom)
		"onda":
			c.draw_arc(p, 8.0, 0.0, TAU, 24, tom, 2.0, true)
			c.draw_arc(p, 12.0, 0.0, TAU, 24, Color(tom, tom.a * 0.5), 1.5, true)
