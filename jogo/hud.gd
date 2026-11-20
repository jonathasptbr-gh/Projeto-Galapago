extends CanvasLayer
## HUD de desenvolvimento: título (versão/build), legenda dos gestos (gerada da
## tabela), estado do corpo (rota/autonomia, alvo, camada), última relação
## gesto → ação, e o ESTADO DA ATUALIZAÇÃO com botão de verificar à mão.

const Atualizador := preload("res://jogo/atualizador.gd")
const Alvos := preload("res://sim/alvos.gd")

var cfg: Dictionary = {}
var atualizador: Control
var _gesto: Label
var _estado: Label
var _status: Label


func _ready() -> void:
	var versao: String = ProjectSettings.get_setting("application/config/version", "local")
	var build := int(ProjectSettings.get_setting("galapago/build", 0))
	_rotulo("Projeto Galápago  ·  %s  ·  fundação (mockup)" % ("build local" if versao == "local" else "v" + versao), Vector2(20, 14), 22)
	var leg := _rotulo(_legenda(), Vector2.ZERO, 16)
	leg.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	leg.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	leg.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	leg.position.y += 34
	_status = _rotulo("", Vector2(20, 46), 16)
	_gesto = _rotulo("gesto: —", Vector2.ZERO, 20)
	_gesto.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 18)
	_gesto.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_gesto.position.y -= 62
	_estado = _rotulo("", Vector2.ZERO, 18)
	_estado.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 18)
	_estado.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_estado.position.y -= 34
	atualizador = Atualizador.new()
	add_child(atualizador)
	if build > 0 and atualizador.estado != "dev":
		var b := Button.new()
		b.text = "Verificar atualização"
		b.add_theme_font_size_override("font_size", 16)
		b.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
		b.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		b.position.y += 210
		b.pressed.connect(func(): atualizador.verificar())
		add_child(b)


func _process(_delta: float) -> void:
	if atualizador and _status:
		_status.text = atualizador.texto_status()


func _legenda() -> String:
	var m: Dictionary = cfg.get("mapa", {})
	var linhas := PackedStringArray(["v0.5 · GESTOS"])
	linhas.append("arrasto PERTO dela → mover (rota)")
	for s in m.get("deslize", []):
		var l := "longe, %s → %s" % [s["nome"], s["acao"]]
		if not l in linhas:
			linhas.append(l)
	linhas.append("toque → %s" % m.get("toque", "—"))
	linhas.append("toque duplo → %s" % m.get("toque_duplo", "—"))
	linhas.append("segurar → %s" % m.get("segurar", "—"))
	linhas.append("segurar nela → %s" % m.get("segurar_na_criatura", "—"))
	return "\n".join(linhas)


func gesto(ev: Dictionary, cmd: Dictionary, resultado: String) -> void:
	var extra := ""
	if cmd.has("setor") and cmd["setor"] != "":
		extra = " (%s, %d°)" % [cmd["setor"], roundi(cmd.get("angulo", 0.0))]
	_gesto.text = "gesto: %s%s → %s · %s" % [ev["gesto"], extra, cmd.get("acao", "nada"), resultado]


func estado(corpo: RefCounted, alvos: Array) -> void:
	var modo := "rota (%d%%)" % roundi(100.0 * corpo.rota_t / maxf(corpo.total_rota, 0.001)) if corpo.em_rota() else "autonomia: %s" % corpo.autonomia
	var alvo := "—"
	if corpo.alvo_id != "":
		alvo = "%s%s" % [corpo.alvo_tipo, (" a %d px" % roundi(corpo.pos.distance_to(Alvos.pos_de(alvos, corpo.alvo_id))))]
	_estado.text = "estado: %s · alvo: %s · %s%s%s" % [modo, alvo, corpo.camada,
		(" · defendendo" if corpo.defendendo else ""), (" · no ar" if corpo.no_ar() else "")]


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
