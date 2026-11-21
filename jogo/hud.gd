extends CanvasLayer
## HUD de desenvolvimento: título (versão/build), legenda dos gestos (gerada da
## tabela), estado do corpo (rota/waypoints, barreira, alvo, camada,
## habilidade, alvo final, planejamento), última relação gesto → ação, nota do
## último golpe/ataque, e o ESTADO DA ATUALIZAÇÃO com botão de verificar à mão.
## Layout pensado para a tela em RETRATO (720×1280).

const Atualizador := preload("res://jogo/atualizador.gd")
const Alvos := preload("res://sim/alvos.gd")

var cfg: Dictionary = {}
var atualizador: Control
var _gesto: Label
var _estado: Label
var _status: Label
var _nota: Label
var _nota_t := 0.0
var _energia_bg: ColorRect
var _energia: ColorRect
var _energia_largura := 180.0


func _ready() -> void:
	var versao: String = ProjectSettings.get_setting("application/config/version", "local")
	var build := int(ProjectSettings.get_setting("galapago/build", 0))
	_rotulo("Projeto Galápago  ·  %s  ·  retrato (mockup)" % ("build local" if versao == "local" else "v" + versao), Vector2(20, 14), 22)
	var leg := _rotulo(_legenda(), Vector2.ZERO, 16)
	leg.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	leg.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	leg.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	leg.position.y += 34
	_status = _rotulo("", Vector2(20, 46), 16)
	_nota = _rotulo("", Vector2(20, 72), 18)
	_gesto = _rotulo("gesto: —", Vector2.ZERO, 20)
	_gesto.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 18)
	_gesto.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_gesto.position.y -= 62
	_estado = _rotulo("", Vector2.ZERO, 18)
	_estado.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 18)
	_estado.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_estado.position.y -= 34
	# BARRA DE ENERGIA do sprint (v0.11)
	_energia_bg = ColorRect.new()
	_energia_bg.color = Color(0, 0, 0, 0.45)
	_energia_bg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 18)
	_energia_bg.position.y -= 104
	_energia_bg.size = Vector2(_energia_largura, 8)
	_energia_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_energia_bg)
	_energia = ColorRect.new()
	_energia.color = Color(0.45, 0.85, 1.0, 0.9)
	_energia.position = Vector2.ZERO
	_energia.size = Vector2(_energia_largura, 8)
	_energia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_energia_bg.add_child(_energia)
	atualizador = Atualizador.new()
	add_child(atualizador)
	if build > 0 and atualizador.estado != "dev":
		var b := Button.new()
		b.text = "Verificar atualização"
		b.add_theme_font_size_override("font_size", 16)
		b.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
		b.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		b.position.y += 330
		b.pressed.connect(func(): atualizador.verificar())
		add_child(b)


func _process(delta: float) -> void:
	if atualizador and _status:
		_status.text = atualizador.texto_status()
	if _nota_t > 0.0:
		_nota_t = maxf(0.0, _nota_t - delta)
		if _nota_t <= 0.0 and _nota:
			_nota.text = ""


func _legenda() -> String:
	var m: Dictionary = cfg.get("mapa", {})
	var linhas := PackedStringArray(["GESTOS"])
	linhas.append("1 dedo arrastando → caminho")
	linhas.append("laço perto → ataque em área")
	linhas.append("fim do caminho no alvo → marca")
	linhas.append("toque → tiro (no alvo marcado ou na direção do toque)")
	linhas.append("toque duplo → pulo")
	linhas.append("passar por cima → batida")
	linhas.append("segurar no caminho → sprint")
	linhas.append("segurar parado → habilidade")
	return "\n".join(linhas)


func gesto(ev: Dictionary, cmd: Dictionary, resultado: String) -> void:
	_gesto.text = "gesto: %s → %s · %s" % [ev["gesto"], cmd.get("acao", "nada"), resultado]


## Nota do último golpe/ataque (onda, tiro, batida, acerto, alvo final).
func nota(texto: String) -> void:
	if _nota:
		_nota.text = texto
		_nota_t = 2.4


func estado(corpo: RefCounted, alvos: Array, planejando := false, escala := 1.0) -> void:
	var modo := ""
	if corpo.em_rota():
		var pct := roundi(100.0 * minf(corpo.rota_t, corpo.total_rota) / maxf(corpo.total_rota, 0.001))
		modo = "rota (%d%%)" % pct
		if corpo.barrado():
			modo = "rota PARADA na barreira (%d%%)" % pct
	else:
		modo = "autonomia: %s" % corpo.autonomia
	var alvo := "—"
	if corpo.alvo_id != "":
		alvo = "%s%s" % [corpo.alvo_tipo, (" a %d px" % roundi(corpo.pos.distance_to(Alvos.pos_de(alvos, corpo.alvo_id))))]
	var extra := ""
	if planejando:
		extra = " · DESENHANDO %d%%" % roundi(escala * 100.0)
	var final := ""
	if corpo.mira_final_id != "":
		final = " · ALVO MARCADO %s" % corpo.mira_final_id
	if _energia:
		var e := clampf(float(corpo.energia), 0.0, 1.0)
		_energia.size.x = _energia_largura * e
		_energia.color = Color(0.95, 0.5, 0.3, 0.95) if e < 0.25 else Color(0.45, 0.85, 1.0, 0.9)
	_estado.text = "estado: %s · alvo: %s · %s%s%s%s%s%s" % [modo, alvo, corpo.camada,
		(" · habilidade" if corpo.habilidade_ativa() else ""),
		(" · golpe: %s" % corpo.ataque if corpo.ataque != "" else ""),
		(" · no ar" if corpo.no_ar() else ""), final, extra]


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
