extends CanvasLayer
## HUD de DESENVOLVIMENTO: título, legenda dos gestos (gerada da tabela
## dados/gestos.json — muda a tabela, muda a legenda), o último gesto
## reconhecido → ação → resultado, e o estado do corpo. Mais o atualizador.

const Atualizador := preload("res://jogo/atualizador.gd")

var cfg: Dictionary = {}
var _gesto: Label
var _estado: Label


func _ready() -> void:
	var versao: String = ProjectSettings.get_setting("application/config/version", "local")
	_rotulo("Projeto Galápago  ·  %s  ·  fundação (mockup)" % ("build local" if versao == "local" else "v" + versao), Vector2(20, 14), 22)
	var leg := _rotulo(_legenda(), Vector2.ZERO, 17)
	leg.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	leg.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	leg.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_gesto = _rotulo("gesto: —", Vector2.ZERO, 20)
	_gesto.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 18)
	_gesto.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_gesto.position.y -= 34
	_estado = _rotulo("", Vector2.ZERO, 18)
	_estado.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 18)
	_estado.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(Atualizador.new())


func _legenda() -> String:
	var m: Dictionary = cfg.get("mapa", {})
	var linhas := PackedStringArray(["GESTOS"])
	for s in m.get("deslize", []):
		var l := "deslize %s → %s" % [s["nome"], s["acao"]]
		if not l in linhas:
			linhas.append(l)
	linhas.append("toque duplo → %s" % m.get("toque_duplo", "—"))
	linhas.append("segurar → %s" % m.get("segurar", "—"))
	linhas.append("segurar na criatura → %s" % m.get("segurar_na_criatura", "—"))
	linhas.append("traço a partir dela → %s" % m.get("trajetoria", "—"))
	linhas.append("toque → %s" % m.get("toque", "—"))
	return "\n".join(linhas)


func gesto(ev: Dictionary, cmd: Dictionary, resultado: String) -> void:
	var extra := ""
	if cmd.has("setor") and cmd["setor"] != "":
		extra = " (%s, %d°)" % [cmd["setor"], roundi(cmd.get("angulo", 0.0))]
	_gesto.text = "gesto: %s%s → %s · %s" % [ev["gesto"], extra, cmd.get("acao", "nada"), resultado]


func estado(corpo: RefCounted, altura: float) -> void:
	var a: String = corpo.estado
	if corpo.estado == "acao":
		a = "%s [%s]" % [corpo.acao, corpo.fase]
	var rec := PackedStringArray()
	for k in corpo.recargas:
		if float(corpo.recargas[k]) > 0.0:
			rec.append("%s %.1fs" % [k, corpo.recargas[k]])
	_estado.text = "estado: %s · %s · altura %s%s" % [a, corpo.camada, altura,
		("" if rec.is_empty() else " · recarga: " + ", ".join(rec))]


func _rotulo(texto: String, pos: Vector2, tamanho: int) -> Label:
	var l := Label.new()
	l.text = texto
	var ls := LabelSettings.new()
	ls.font_size = tamanho
	ls.outline_size = 6
	ls.outline_color = Color(0, 0, 0, 0.7)
	l.label_settings = ls
	l.position = pos
	add_child(l)
	return l
