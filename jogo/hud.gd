extends CanvasLayer
## A HUD avisa o main quando o botão de HOSTILIDADE muda de estado; quem manda
## nos inimigos é o main (a regra é da `sim/adversario.gd`).
signal hostilidade_alternada(ligado: bool)
## P24: o botão PIXEL ART liga/desliga o Pixel Pass da vista 3D (quem manda é o main)
signal pixel_pass_alternado(ligado: bool)
signal sombras_alternadas(modo: int)
signal resolucao_liso_escolhida(percentual: int)
signal msaa_liso_escolhido(modo: int)

## HUD de desenvolvimento: título (versão/build), legenda dos gestos (a tabela
## v0.18 em linhas curtas + a linha do CONFIG), estado do corpo (rota/waypoints,
## barreira, camada, habilidade, alvo final, planejamento e CARGA do tiro),
## barra de energia e barra de carga, última relação gesto → ação, nota do último
## golpe/ataque, e o ESTADO DA ATUALIZAÇÃO com botão de verificar à mão.
## v0.19: SLIDER DA CARGA DO TIRO (0 a `corpo.tiro_carga_max_s()`, escreve em
## `corpo.carga_tiro_s`; o TAMANHO do tiro é da `sim/`, a HUD só escolhe o tempo)
## e o botão CONFIG, que esconde/mostra esta HUD de teste — o próprio botão, o
## `veu` (escurecimento do desenho) e o `atualizador` ficam sempre.
## Layout pensado para a tela em RETRATO (720×1280). P24: o bloco do alto
## começa em `TOPO` — os primeiros `TOPO` px são da BARRA DE GIRO
## (`jogo/barra_giro.gd`, o dedo lá gira a câmera 3D). Botão PIXEL ART
## (Pixel Pass ligado/desligado) logo abaixo do slider da carga.

## px do topo reservados à barra de giro (o mesmo `ALTURA_BARRA` do main)
const TOPO := 100.0
## P25/1.5: rótulo do botão de cópia e quanto tempo o "COPIADO" fica nele
const TEXTO_COPIAR := "COPIAR REGISTRO"
const COPIADO_S := 1.5

const Atualizador := preload("res://jogo/atualizador.gd")
const Mata := preload("res://jogo/mundo3d/natureza/mapa.gd")
const Diagnostico := preload("res://jogo/diagnostico.gd")
const Vista := preload("res://jogo/mundo3d/vista.gd")

var diagnostico: Label
var _diagnostico_btn: Button
var _diagnostico_ligado := false
# P25/1.5: COPIAR REGISTRO (só com o painel ligado) põe o registro completo na
# área de transferência. Injetável: o teste troca por um Callable que guarda o
# texto (o clipboard real não existe em headless).
var _copiar_btn: Button
var _copiado_t := 0.0
var area_transferencia := Callable(DisplayServer, "clipboard_set")
var _leg: Label

var atualizador: Control
var _gesto: Label
var _estado: Label
var _status: Label
var _nota: Label
var _nota_t := 0.0
var _energia_bg: ColorRect
var _energia: ColorRect
var _energia_largura := 180.0
# CARGA do tiro (v0.18): barra fina amarela logo acima da energia, visível só
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
# CARGA DO TIRO (v0.19): o slider escreve em `corpo.carga_tiro_s` (padrão 0,5 s);
# o tamanho/força do tiro é da `sim/` — a HUD só escolhe o TEMPO de carga.
var _carga_rotulo: Label
var _carga_slider: HSlider
var _slider_sincronizado := false
# CONFIG (v0.19): esconde/mostra a HUD de teste; ele mesmo, o `veu` (o
# escurecimento do desenho) e o `atualizador` (o aviso de atualização) ficam.
var _config_btn: Button
var _mostrar_info := true
var _intima := false
## Fração contínua da pinça (0 = vista alta, 1 = máxima aproximação), só para
## o registro do diagnóstico — não esconde nem muda botão nenhum.
var _zoom_fracao := 0.0
## Altura ortográfica atual do mundo visível (unidades), informada pelo main.
var _zoom_altura := 25.0
# PIXEL ART (P24): estado vem do main (`definir_pixel_pass`); padrão desligado
var _pixel_btn: Button
var _pixel := false
var _sombras_btn: Button
var _sombras := Mata.Sombras.COMPLETAS
var _resolucao_btn: Button
var _msaa_btn: Button
var _resolucao_status: Label
var _resolucao_liso := 100
var _msaa_liso := Viewport.MSAA_4X


## Apenas registra a vista para diagnóstico; o zoom não muda os botões.
func definir_vista_intima(ativa: bool) -> void:
	_intima = ativa


## Posição contínua da pinça (0..1) para o registro do diagnóstico; a altura é
## a que a câmera está aplicando de fato (`cam3d.altura_mundo`).
func definir_zoom(fracao: float, altura_mundo := -1.0) -> void:
	_zoom_fracao = clampf(fracao, 0.0, 1.0)
	if altura_mundo > 0.0:
		_zoom_altura = altura_mundo
	_intima = _zoom_fracao > 0.00625


func _ready() -> void:
	var build := int(ProjectSettings.get_setting("galapago/build", 0))
	_rotulo("Projeto Galápago  ·  %s  ·  retrato (3D)" % texto_versao(), Vector2(20, TOPO + 8), 22)
	var leg := _rotulo(_legenda(), Vector2.ZERO, 16)
	leg.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	leg.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	leg.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	leg.position.y += TOPO + 34
	_leg = leg
	diagnostico = Diagnostico.new()
	add_child(diagnostico)
	diagnostico.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	diagnostico.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	diagnostico.position.y += TOPO + 34
	_status = _rotulo("", Vector2(20, TOPO + 40), 16)
	_nota = _rotulo("", Vector2(20, TOPO + 64), 18)
	# PULO AUTOMÁTICO (v0.13): botão de ligar/desligar (padrão em `pular.auto_padrao`).
	# É um Control de verdade — o toque nele é consumido pela HUD e não vira caminho.
	_pulo_auto = Button.new()
	_pulo_auto.text = "PULO AUTO: DESLIGADO"
	_pulo_auto.add_theme_font_size_override("font_size", 16)
	_pulo_auto.position = Vector2(20, TOPO + 96)
	_pulo_auto.custom_minimum_size = Vector2(240, 34)
	_pulo_auto.pressed.connect(_alternar_pulo_auto)
	add_child(_pulo_auto)
	# HOSTILIDADE (v0.14): o botão liga a caçada e os quatro ataques do bicho.
	_hostil_btn = Button.new()
	_hostil_btn.text = "HOSTILIDADE: DESLIGADA"
	_hostil_btn.add_theme_font_size_override("font_size", 16)
	_hostil_btn.position = Vector2(20, TOPO + 138)
	_hostil_btn.custom_minimum_size = Vector2(240, 34)
	_hostil_btn.pressed.connect(_alternar_hostilidade)
	add_child(_hostil_btn)
	_inimigo = _rotulo("", Vector2(20, TOPO + 180), 16)
	# CONFIG (v0.19): sempre visível, na coluna da ESQUERDA abaixo do `inimigo`
	# (a legenda fica à direita e o estado, embaixo). Ele esconde/mostra o resto.
	_config_btn = Button.new()
	_config_btn.text = "CONFIG"
	_config_btn.add_theme_font_size_override("font_size", 16)
	_config_btn.position = Vector2(20, TOPO + 222)
	_config_btn.custom_minimum_size = Vector2(240, 34)
	_config_btn.pressed.connect(_alternar_info)
	add_child(_config_btn)
	# CARGA DO TIRO (v0.19): rótulo + slider (0 a 1,5 s, passo 0,05). O teto
	# real vem de `corpo.tiro_carga_max_s()` na primeira `estado()`.
	_carga_rotulo = _rotulo(_texto_carga(0.5), Vector2(20, TOPO + 264), 16)
	_carga_slider = HSlider.new()
	_carga_slider.min_value = 0.0
	_carga_slider.max_value = 1.5
	_carga_slider.step = 0.05
	_carga_slider.value = 0.5
	_carga_slider.position = Vector2(20, TOPO + 288)
	_carga_slider.size = Vector2(240, 34)
	_carga_slider.custom_minimum_size = Vector2(240, 34)
	# o slider é um Control: o toque nele é CONSUMIDO (não vira caminho)
	_carga_slider.focus_mode = Control.FOCUS_NONE
	_carga_slider.value_changed.connect(_mudar_carga)
	add_child(_carga_slider)
	# PIXEL ART (P24): Pixel Pass ligado (imagem interna baixa + dither) ou
	# desligado (3D liso, MSAA). O main troca a vista e devolve o estado.
	_pixel_btn = Button.new()
	_pixel_btn.text = "PIXEL ART: DESLIGADO"
	_pixel_btn.add_theme_font_size_override("font_size", 16)
	_pixel_btn.position = Vector2(20, TOPO + 334)
	_pixel_btn.custom_minimum_size = Vector2(240, 34)
	_pixel_btn.focus_mode = Control.FOCUS_NONE
	_pixel_btn.pressed.connect(func(): pixel_pass_alternado.emit(not _pixel))
	add_child(_pixel_btn)
	# Painel ocupa o lugar da legenda, não o centro jogável. Só o botão recebe toque.
	_diagnostico_btn = Button.new()
	_diagnostico_btn.text = "DIAGNÓSTICO: DESLIGADO"
	_diagnostico_btn.add_theme_font_size_override("font_size", 16)
	_diagnostico_btn.position = Vector2(20, TOPO + 376)
	_diagnostico_btn.custom_minimum_size = Vector2(240, 34)
	_diagnostico_btn.focus_mode = Control.FOCUS_NONE
	_diagnostico_btn.pressed.connect(func(): definir_diagnostico(not _diagnostico_ligado))
	add_child(_diagnostico_btn)
	# P25/1.5: logo abaixo do DIAGNÓSTICO, na mesma coluna (nada sobre o painel
	# à direita nem sobre o centro jogável); visível só com o painel ligado.
	_copiar_btn = Button.new()
	_copiar_btn.text = TEXTO_COPIAR
	_copiar_btn.add_theme_font_size_override("font_size", 16)
	_copiar_btn.position = Vector2(20, TOPO + 418)
	_copiar_btn.custom_minimum_size = Vector2(240, 34)
	_copiar_btn.focus_mode = Control.FOCUS_NONE
	_copiar_btn.visible = false
	_copiar_btn.pressed.connect(copiar_registro)
	add_child(_copiar_btn)
	# P25/2.1: controle explícito de sessão. O main devolve o modo aplicado.
	_sombras_btn = Button.new()
	_sombras_btn.add_theme_font_size_override("font_size", 16)
	_sombras_btn.position = Vector2(20, TOPO + 460)
	_sombras_btn.custom_minimum_size = Vector2(240, 34)
	_sombras_btn.focus_mode = Control.FOCUS_NONE
	_sombras_btn.pressed.connect(func(): sombras_alternadas.emit((_sombras + 1) % 3))
	add_child(_sombras_btn)
	definir_sombras(_sombras)
	# Comparações independentes: nenhum botão muda a outra variável.
	_resolucao_btn = _botao_liso(TOPO + 502)
	_resolucao_btn.pressed.connect(func():
		var i := Vista.ESCALAS_LISO.find(_resolucao_liso)
		resolucao_liso_escolhida.emit(Vista.ESCALAS_LISO[(i + 1) % Vista.ESCALAS_LISO.size()]))
	_msaa_btn = _botao_liso(TOPO + 544)
	_msaa_btn.pressed.connect(func():
		var i := Vista.AA_LISO.find(_msaa_liso)
		msaa_liso_escolhido.emit(Vista.AA_LISO[(i + 1) % Vista.AA_LISO.size()]))
	_resolucao_status = _rotulo("", Vector2(20, TOPO + 586), 14)
	_resolucao_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	# BARRA DE CARGA do tiro (v0.18): só aparece enquanto carrega; some do resto
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
		_criar_verificar()


## P25/1.4: "Verificar atualização" mora na coluna da ESQUERDA, abaixo do
## DIAGNÓSTICO; no canto direito (`TOPO + 350`) ficava por cima do painel ligado
## (captura do S24 Ultra, 2026-11-27). Some com o CONFIG, como os outros botões.
## Controles de resolução/AA e status acima; não ocupa o centro nem o painel.
func _criar_verificar() -> Button:
	var b := Button.new()
	b.text = "Verificar atualização"
	b.add_theme_font_size_override("font_size", 16)
	b.position = Vector2(20, TOPO + 660)
	b.custom_minimum_size = Vector2(240, 34)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): atualizador.verificar())
	add_child(b)
	return b


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
	if _pixel_btn:
		_pixel_btn.text = "PIXEL ART: %s" % ("LIGADO" if _pixel else "DESLIGADO")
		_pixel_btn.modulate = Color(0.7, 0.9, 1.0) if _pixel else Color.WHITE
	if _copiado_t > 0.0:
		_copiado_t = maxf(0.0, _copiado_t - delta)
		if _copiado_t <= 0.0 and _copiar_btn:
			_copiar_btn.text = TEXTO_COPIAR
	if _nota_t > 0.0:
		_nota_t = maxf(0.0, _nota_t - delta)
		if _nota_t <= 0.0 and _nota:
			_nota.text = ""


func _legenda() -> String:
	var linhas := PackedStringArray(["GESTOS"])
	linhas.append("1 dedo arrastando → caminho")
	linhas.append("fim do caminho no alvo → marca")
	linhas.append("toque → tiro carregado (alvo/fim)")
	linhas.append("toque duplo → pulo")
	linhas.append("segurar no caminho → correr")
	linhas.append("segurar parado → habilidade (cavar)")
	linhas.append("passar por cima → batida")
	linhas.append("botão PULO AUTO → sobe degrau de 1 nível")
	linhas.append("botão HOSTILIDADE → o bicho caça e ataca")
	linhas.append("barra do topo → gira a câmera")
	linhas.append("PIXEL ART → liga o pixel art (padrão: 3D liso)")
	linhas.append("CONFIG → esconde esta HUD")
	return "\n".join(linhas)


## Modo de sombra aplicado pelo main (sessão, sem persistência).
func definir_sombras(modo: int) -> void:
	_sombras = modo
	_sombras_btn.text = "SOMBRAS: " + Mata.NOMES_SOMBRAS[modo]
	diagnostico.definir_sombras(Mata.NOMES_SOMBRAS[modo])
	# Uma cópia anterior não pode continuar anunciada após a troca.
	_copiado_t = 0.0
	_copiar_btn.text = TEXTO_COPIAR


## Estado do Pixel Pass (o main chama na partida e a cada troca).
func definir_pixel_pass(ligado: bool) -> void:
	_pixel = ligado


func _botao_liso(y: float) -> Button:
	var b := Button.new()
	b.position = Vector2(20, y)
	b.custom_minimum_size = Vector2(240, 34)
	b.add_theme_font_size_override("font_size", 16)
	b.focus_mode = Control.FOCUS_NONE
	add_child(b)
	return b


## Estado aplicado, não antecipado pelo botão. Chamado também ao resize.
func definir_render_liso(vista: CanvasLayer) -> void:
	_resolucao_liso = vista.resolucao_liso
	_msaa_liso = vista.msaa_liso
	_pixel = vista.pixel_pass
	_resolucao_btn.text = "3D LISO: %d%%" % _resolucao_liso
	_msaa_btn.text = "MSAA LISO: " + ["DESLIGADO", "2×", "4×"][_msaa_liso]
	_resolucao_btn.disabled = _pixel
	_msaa_btn.disabled = _pixel
	var px: Vector2i = vista.tamanho_interno()
	if _pixel:
		_resolucao_status.text = "PIXEL ART: %d×%d px\nAA desligado · liso suspenso\nEscolhas do liso preservadas" % [px.x, px.y]
	else:
		var fisico: Vector2i = get_window().size
		_resolucao_status.text = "%d×%d px internos\nEfetivo: %s%% × %s%%\nMSAA efetivo: %s" % [px.x, px.y,
			Diagnostico.num(100.0 * px.x / maxf(fisico.x, 1), 1),
			Diagnostico.num(100.0 * px.y / maxf(fisico.y, 1), 1), vista.texto_aa()]
	_copiado_t = 0.0
	_copiar_btn.text = TEXTO_COPIAR


func gesto(ev: Dictionary, cmd: Dictionary, resultado: String) -> void:
	_gesto.text = "gesto: %s → %s · %s" % [ev["gesto"], cmd.get("acao", "nada"), resultado]


## Nota do último golpe/ataque (tiro, batida, acerto, alvo final).
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


## Texto do rótulo da CARGA (vírgula decimal); 0 s é o tiro INSTANTÂNEO (base).
func _texto_carga(s: float) -> String:
	if s <= 0.001:
		return "CARGA DO TIRO: instantâneo"
	return "CARGA DO TIRO: %s s" % ("%.2f" % s).replace(".", ",")


## O dedo no slider escolhe o TEMPO de carga; o tamanho/força é da `sim/`.
func _mudar_carga(valor: float) -> void:
	if _carga_rotulo:
		_carga_rotulo.text = _texto_carga(valor)
	if _corpo == null:
		return
	_corpo.carga_tiro_s = valor


## CONFIG (v0.19): esconde/mostra a HUD de teste. SEMPRE ficam: o próprio botão,
## o `veu` (ColorRect de tela cheia que o main põe no índice 0; escurece o
## desenho) e o `atualizador` (o prompt de atualização do app).
func _alternar_info() -> void:
	_mostrar_info = not _mostrar_info
	for no in get_children():
		if not (no is Control):
			continue
		var filho := no as Control
		if filho == _config_btn or filho == atualizador:
			continue
		if _e_veu(filho):
			continue
		filho.visible = _mostrar_info
	# a barra de carga é reaberta pelo `estado()` só enquanto carrega
	if _mostrar_info and _carga_bg and _corpo:
		_carga_bg.visible = _corpo.carregando()
	_config_btn.text = "CONFIG" if _mostrar_info else "MOSTRAR"
	_sincronizar_diagnostico()


func definir_diagnostico(ligado: bool) -> void:
	_diagnostico_ligado = ligado
	_diagnostico_btn.text = "DIAGNÓSTICO: %s" % ("LIGADO" if ligado else "DESLIGADO")
	_sincronizar_diagnostico()


func _sincronizar_diagnostico() -> void:
	if diagnostico == null:
		return
	var mostrar := _mostrar_info
	# Ocultar CONFIG suspende TODA coleta. Reabrir limpa a janela.
	diagnostico.definir_ligado(mostrar and _diagnostico_ligado)
	_leg.visible = mostrar and not _diagnostico_ligado
	if _copiar_btn:
		_copiar_btn.visible = mostrar and _diagnostico_ligado


## Monta o registro completo e o põe na área de transferência; o botão avisa
## por ~1,5 s. Devolve o texto (o teste confere sem clipboard real).
func copiar_registro() -> String:
	var txt: String = diagnostico.registro({
		"Versão": texto_versao(),
		"Vista": "íntima" if _intima else "alta",
		"Aproximação": "%d%% (altura do mundo %.1f)" % [roundi(_zoom_fracao * 100.0), _zoom_altura],
		"Hostilidade": "ligada" if _hostil else "desligada",
	})
	area_transferencia.call(txt)
	_copiar_btn.text = "COPIADO: %d janelas" % diagnostico.historico().size()
	_copiado_t = COPIADO_S
	return txt


## A mesma string de versão do título da HUD ("v0.40.0-b140" ou "build local").
static func texto_versao() -> String:
	var versao: String = ProjectSettings.get_setting("application/config/version", "local")
	return "build local" if versao == "local" else "v" + versao


## O `veu` é o ColorRect de TELA CHEIA que o main acrescenta e move para o
## índice 0 — os ColorRects desta HUD (energia/carga) são ancorados embaixo.
func _e_veu(no: Node) -> bool:
	if not (no is ColorRect):
		return false
	var cr := no as ColorRect
	return cr.anchor_right == 1.0 and cr.anchor_bottom == 1.0


func estado(corpo: RefCounted, _alvos: Array, planejando := false, escala := 1.0,
		adversarios: Array = [], hostil := false) -> void:
	_corpo = corpo
	_hostil = hostil
	# CARGA DO TIRO (v0.19): a PRIMEIRA `estado()` acerta o slider com a sim
	# (teto e valor); depois quem manda é o dedo no slider. `set_value_no_signal`
	# evita que a sincronização escreva de volta em `corpo.carga_tiro_s`.
	if not _slider_sincronizado and _carga_slider:
		_slider_sincronizado = true
		var teto: float = corpo.tiro_carga_max_s()
		_carga_slider.set_value_no_signal(minf(float(corpo.carga_tiro_s), teto))
		_carga_slider.max_value = teto
		if _carga_rotulo:
			_carga_rotulo.text = _texto_carga(_carga_slider.value)
	var modo := ""
	if corpo.em_rota():
		var pct := roundi(100.0 * minf(corpo.rota_t, corpo.total_rota) / maxf(corpo.total_rota, 0.001))
		modo = "rota (%d%%)" % pct
		if corpo.barrado():
			modo = "rota PARADA na barreira (%d%%)" % pct
	else:
		modo = "autonomia: %s" % corpo.autonomia
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
	# CARGA do tiro (v0.18): a barra fina só existe enquanto o corpo carrega
	# (e some junto com o resto quando o CONFIG esconde a HUD de teste).
	var carga := clampf(corpo.carga(), 0.0, 1.0)
	if _carga_bg and _carga:
		_carga_bg.visible = _mostrar_info and corpo.carregando()
		_carga.size.x = _energia_largura * carga
		_carga.color = Color(1.0, 0.7, 0.2, 0.95) if carga >= 0.999 else Color(1.0, 0.85, 0.25, 0.95)
	# a CARGA em primeiro plano: é o preparo do tiro que o dedo precisa ver
	var fio := ""
	if corpo.carregando():
		fio = "CARREGANDO %d%%" % roundi(carga * 100.0)
	var linha := "estado: %s · %s%s%s%s%s%s%s" % [modo, corpo.camada,
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
