extends CanvasLayer
## A HUD avisa o main quando o botão de HOSTILIDADE muda de estado; quem manda
## nos inimigos é o main (a regra é da `sim/adversario.gd`).
signal hostilidade_alternada(ligado: bool)

## HUD de desenvolvimento: título (versão/build), legenda dos gestos (a tabela
## v0.17 em linhas curtas), estado do corpo (rota/waypoints, barreira, alvo,
## camada, habilidade, alvo final, planejamento, PAUSA DE SAÍDA e CARGA do
## tiro), barra de energia e barra de carga, última relação gesto → ação, nota
## do último golpe/ataque, e o ESTADO DA ATUALIZAÇÃO com botão de verificar à
## mão. Layout pensado para a tela em RETRATO (720×1280).

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
# CARGA do tiro (v0.17): barra fina amarela logo acima da energia, visível só
# enquanto o corpo carrega (`corpo.carregando()`), preenchida por `corpo.carga()`
var _carga_bg: ColorRect
var _carga: ColorRect
# PULO AUTOMÁTICO (v0.13): o botão manda no `corpo.pulo_auto` (a regra é da sim)
var _corpo: RefCounted
var _pulo_auto: Button
# HOSTILIDADE (v0.14): liga os ataques do adversário; estado vem do main
var _hostil_btn: Button
var _hostil := false
var _inimigo: Label


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
	# PULO AUTOMÁTICO (v0.13): botão de ligar/desligar (padrão em `pular.auto_padrao`).
	# É um Control de verdade — o toque nele é consumido pela HUD e não vira caminho.
	_pulo_auto = Button.new()
	_pulo_auto.text = "PULO AUTO: DESLIGADO"
	_pulo_auto.add_theme_font_size_override("font_size", 16)
	_pulo_auto.position = Vector2(20, 104)
	_pulo_auto.custom_minimum_size = Vector2(240, 34)
	_pulo_auto.pressed.connect(_alternar_pulo_auto)
	add_child(_pulo_auto)
	# HOSTILIDADE (v0.14): o botão liga a caçada e os quatro ataques do bicho.
	_hostil_btn = Button.new()
	_hostil_btn.text = "HOSTILIDADE: DESLIGADA"
	_hostil_btn.add_theme_font_size_override("font_size", 16)
	_hostil_btn.position = Vector2(20, 146)
	_hostil_btn.custom_minimum_size = Vector2(240, 34)
	_hostil_btn.pressed.connect(_alternar_hostilidade)
	add_child(_hostil_btn)
	_inimigo = _rotulo("", Vector2(20, 188), 16)
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
	# BARRA DE CARGA do tiro (v0.17): só aparece enquanto carrega; some do resto
	_carga_bg = ColorRect.new()
	_carga_bg.color = Color(0, 0, 0, 0.45)
	_carga_bg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 18)
	_carga_bg.position.y -= 118
	_carga_bg.size = Vector2(_energia_largura, 8)
	_carga_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carga_bg.visible = false
	add_child(_carga_bg)
	_carga = ColorRect.new()
	_carga.color = Color(1.0, 0.85, 0.25, 0.95)
	_carga.position = Vector2.ZERO
	_carga.size = Vector2(_energia_largura, 8)
	_carga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carga_bg.add_child(_carga)
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
	if _pulo_auto and _corpo:
		var ligado: bool = bool(_corpo.pulo_auto)
		_pulo_auto.text = "PULO AUTO: %s" % ("LIGADO" if ligado else "DESLIGADO")
		_pulo_auto.modulate = Color(0.65, 1.0, 0.7) if ligado else Color.WHITE
	if _hostil_btn:
		_hostil_btn.text = "HOSTILIDADE: %s" % ("LIGADA" if _hostil else "DESLIGADA")
		_hostil_btn.modulate = Color(1.0, 0.62, 0.5) if _hostil else Color.WHITE
	if _nota_t > 0.0:
		_nota_t = maxf(0.0, _nota_t - delta)
		if _nota_t <= 0.0 and _nota:
			_nota.text = ""


func _legenda() -> String:
	var linhas := PackedStringArray(["GESTOS"])
	linhas.append("1 dedo arrastando → caminho")
	linhas.append("fim do caminho no alvo → marca")
	linhas.append("toque → correr (arrancada)")
	linhas.append("toque duplo → pulo")
	linhas.append("segurar → tiro carregado (alvo/fim)")
	linhas.append("segurar sem caminho/alvo → habilidade")
	linhas.append("na pausa, toque → sai correndo")
	linhas.append("na pausa, segurar → atira e cancela")
	linhas.append("passar por cima → batida")
	linhas.append("botão PULO AUTO → sobe degrau de 1 nível")
	linhas.append("botão HOSTILIDADE → o bicho caça e ataca")
	return "\n".join(linhas)


func gesto(ev: Dictionary, cmd: Dictionary, resultado: String) -> void:
	_gesto.text = "gesto: %s → %s · %s" % [ev["gesto"], cmd.get("acao", "nada"), resultado]


## Nota do último golpe/ataque (onda, tiro, batida, acerto, alvo final).
func nota(texto: String) -> void:
	if _nota:
		_nota.text = texto
		_nota_t = 2.4


func _alternar_hostilidade() -> void:
	hostilidade_alternada.emit(not _hostil)


func _alternar_pulo_auto() -> void:
	if _corpo == null:
		return
	_corpo.pulo_auto = not bool(_corpo.pulo_auto)
	nota("PULO AUTO %s" % ("ligado" if _corpo.pulo_auto else "desligado"))


func estado(corpo: RefCounted, alvos: Array, planejando := false, escala := 1.0,
		adversarios: Array = [], hostil := false) -> void:
	_corpo = corpo
	_hostil = hostil
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
	# CARGA do tiro (v0.17): a barra fina só existe enquanto o corpo carrega
	var carga := clampf(corpo.carga(), 0.0, 1.0)
	if _carga_bg and _carga:
		_carga_bg.visible = corpo.carregando()
		_carga.size.x = _energia_largura * carga
		_carga.color = Color(1.0, 0.7, 0.2, 0.95) if carga >= 0.999 else Color(1.0, 0.85, 0.25, 0.95)
	# a PAUSA DE SAÍDA e a CARGA em primeiro plano: é o que o dedo precisa ver
	var fio := ""
	if corpo.em_atraso():
		fio = "PAUSA %s s" % _decimal(corpo.atraso_restante_s())
	elif corpo.carregando():
		fio = "CARREGANDO %d%%" % roundi(carga * 100.0)
	var linha := "estado: %s · alvo: %s · %s%s%s%s%s%s%s" % [modo, alvo, corpo.camada,
		(" · habilidade" if corpo.habilidade_ativa() else ""),
		(" · golpe: %s" % corpo.ataque if corpo.ataque != "" else ""),
		(" · no ar" if corpo.no_ar() else ""), final, extra,
		(" · ATORDOADA" if corpo.atordoado() else "")]
	_estado.text = linha if fio == "" else "%s · %s" % [fio, linha]
	# linha do inimigo: o que ele está fazendo (preparo é o mais importante)
	if _inimigo:
		if adversarios.is_empty():
			_inimigo.text = ""
		else:
			var a: RefCounted = adversarios[0]
			var txt := "inimigo: %s" % a.estado_atual()
			if a.preparando():
				txt = "inimigo: PREPARANDO %s (%d%%)" % [str(a.acao_atual()).to_upper(), roundi(a.progresso_preparo() * 100.0)]
			elif a.oculto():
				txt = "inimigo: ESCONDIDO"
			elif a.hostil:
				txt = "inimigo: HOSTIL · %s" % a.estado_atual()
			_inimigo.text = txt


## Número com VÍRGULA decimal: a HUD fala com o jogador, em português.
func _decimal(v: float, casas := 1) -> String:
	return String.num(v, casas).replace(".", ",")


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
