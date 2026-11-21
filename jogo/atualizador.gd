extends Control
## O APK se atualiza sozinho — achar, baixar e entregar ao instalador.
##
## v0.5: o gatilho era o problema. Antes ele verificava SÓ no arranque a frio;
## no Android o app fica vivo em segundo plano, então quem estava aberto nunca
## reconsultava. Agora verifica:
##   1. ao abrir;
##   2. ao VOLTAR do segundo plano (sinal que o Android dá a cada retorno);
##   3. de 5 em 5 minutos enquanto está aberto;
##   4. sempre que o jogador toca em "Verificar" na HUD.
## E o resultado fica VISÍVEL (a HUD mostra o estado), em vez de falhar calado.
## Duas fontes: o `versao.json` da Release e, se ele falhar, a API da Release.
## Baixa com progresso, confere o tamanho e entrega ao instalador do sistema
## (OS.shell_open → FileProvider → Android pede a confirmação).

const A := preload("res://sim/atualizacao.gd")
const REPO := "jonathasptbr-gh/Projeto-Galapago"
const MANIFESTO := "https://github.com/%s/releases/download/dev/versao.json" % REPO
const API := "https://api.github.com/repos/%s/releases/tags/dev" % REPO
const PASTA := "user://atualizacao/"
const INTERVALO_S := 300.0
const MIN_ENTRE_CHECAGENS_S := 45.0

var estado := "inicio"   # inicio|consultando|em_dia|disponivel|baixando|baixado|erro|dev
var detalhe := ""
var manifesto: Dictionary = {}
var _build := 0
var _http: HTTPRequest
var _fonte := 0
var _tentativa := 0
var _acumulado := 0.0
var _ultima_checagem := -1.0e9
var _tempo := 0.0
var _painel: PanelContainer
var _texto: Label
var _barra: ProgressBar
var _botoes: HBoxContainer
var _botao_aviso: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build = int(ProjectSettings.get_setting("galapago/build", 0))
	if _build <= 0 or "--demo" in OS.get_cmdline_user_args():
		estado = "dev"
		detalhe = "build local"
		return
	_http = HTTPRequest.new()
	_http.timeout = 15.0
	add_child(_http)
	verificar()


## Chamado pela HUD (botão) e por eventos: força uma checagem.
func verificar() -> void:
	if _build <= 0 or estado == "baixando":
		return
	_ultima_checagem = _tempo
	_fonte = 0
	_tentativa = 0
	_pedir()


func _pedir() -> void:
	estado = "consultando"
	detalhe = "consultando…"
	_desligar()
	_http.download_file = ""
	_http.request_completed.connect(_chegou_manifesto, CONNECT_ONE_SHOT)
	var url := MANIFESTO if _fonte == 0 else API
	if _http.request(url, PackedStringArray(["User-Agent: ProjetoGalapago"])) != OK:
		_falhou_e_tenta("requisição não iniciou")


func _chegou_manifesto(resultado: int, codigo: int, _cab: PackedStringArray, corpo: PackedByteArray) -> void:
	if resultado != HTTPRequest.RESULT_SUCCESS or codigo != 200:
		_falhou_e_tenta("HTTP %d" % codigo)
		return
	var texto := corpo.get_string_from_utf8()
	var m: Dictionary
	if _fonte == 0:
		m = A.ler_manifesto(texto)
	else:
		var dados = JSON.parse_string(texto)
		m = A.manifesto_da_api(dados) if typeof(dados) == TYPE_DICTIONARY else {}
	if m.is_empty():
		_falhou_e_tenta("manifesto inválido")
		return
	manifesto = m
	if A.deve_atualizar(_build, manifesto):
		estado = "disponivel"
		detalhe = "nova versão %s" % manifesto["versao_nome"]
		_mostrar_aviso()
	else:
		estado = "em_dia"
		detalhe = "canal %s" % manifesto["versao_nome"]
		_faxina("")


func _falhou_e_tenta(motivo: String) -> void:
	if _fonte == 0:
		_fonte = 1  # tenta a API da Release
		_pedir.call_deferred()
		return
	if _tentativa < 2:
		_tentativa += 1
		_fonte = 0
		_esperando_para(8.0)  # tenta de novo em 8 s
		return
	estado = "erro"
	detalhe = motivo


func _esperando_para(seg: float) -> void:
	estado = "consultando"
	detalhe = "tentando de novo…"
	_acumulado = 0.0
	_proxima_tentativa = _tempo + seg


var _proxima_tentativa := -1.0


func _process(delta: float) -> void:
	_tempo += delta
	if _proxima_tentativa > 0.0 and _tempo >= _proxima_tentativa:
		_proxima_tentativa = -1.0
		_pedir()
	if estado == "baixando" and _barra and not manifesto.is_empty():
		_barra.value = 100.0 * _http.get_downloaded_bytes() / float(maxi(int(manifesto["bytes"]), 1))
	# rechecagem periódica (e ao voltar do segundo plano, via _notification)
	if _build > 0 and estado in ["em_dia", "erro", "disponivel"] and _tempo - _ultima_checagem > INTERVALO_S:
		verificar()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if _build > 0 and estado != "baixando" and _tempo - _ultima_checagem > MIN_ENTRE_CHECAGENS_S:
			verificar()


## Linha para a HUD: o que o atualizador está fazendo.
func texto_status() -> String:
	match estado:
		"dev":
			return "atualização: build local (sem verificação)"
		"consultando":
			return "atualização: " + detalhe
		"em_dia":
			return "atualização: em dia (" + detalhe + ")"
		"disponivel":
			return "atualização: " + detalhe + " — toque em ATUALIZAR"
		"baixando":
			return "atualização: baixando " + str(int(_barra.value)) + "%"
		"baixado":
			return "atualização: baixada, confirme a instalação"
		"erro":
			return "atualização: falhou (" + detalhe + ") — toque para tentar"
	return "atualização: " + estado


# ---------- aviso e download ----------

func _mostrar_aviso() -> void:
	if _botao_aviso and is_instance_valid(_botao_aviso):
		_botao_aviso.text = "ATUALIZAR %s" % manifesto["versao_nome"]
		return
	_botao_aviso = Button.new()
	_botao_aviso.text = "ATUALIZAR %s" % manifesto["versao_nome"]
	_botao_aviso.add_theme_font_size_override("font_size", 22)
	_botao_aviso.custom_minimum_size = Vector2(240, 56)
	_botao_aviso.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
	_botao_aviso.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_botao_aviso.pressed.connect(_abrir_painel)
	add_child(_botao_aviso)


func _abrir_painel() -> void:
	_mostrar("Nova versão %s disponível (%s)" % [manifesto["versao_nome"], A.tamanho_legivel(int(manifesto["bytes"]))],
		[["Baixar agora", _baixar], ["Depois", _fechar]])


func _baixar() -> void:
	var alvo := _arquivo()
	DirAccess.make_dir_recursive_absolute(PASTA)
	_faxina(alvo.get_file())
	if FileAccess.file_exists(alvo) and A.download_completo(_tamanho(alvo), manifesto):
		_instalar()  # já baixado (instalador foi fechado sem instalar)
		return
	estado = "baixando"
	_mostrar("Baixando %s…" % manifesto["versao_nome"], [])
	_barra.visible = true
	_http.download_file = alvo + ".part"
	_http.body_size_limit = A.TETO_BYTES
	_http.timeout = 0.0
	_desligar()
	_http.request_completed.connect(_download_chegou, CONNECT_ONE_SHOT)
	if _http.request(str(manifesto["apk"]), PackedStringArray(["User-Agent: ProjetoGalapago"])) != OK:
		_falhou("não deu para começar o download")


func _download_chegou(resultado: int, codigo: int, _cab: PackedStringArray, _corpo: PackedByteArray) -> void:
	var parcial := _arquivo() + ".part"
	if resultado != HTTPRequest.RESULT_SUCCESS or codigo != 200:
		DirAccess.remove_absolute(parcial)
		_falhou("download falhou (%s)" % (codigo if codigo != 0 else resultado))
		return
	var lidos := _tamanho(parcial)
	if not A.download_completo(lidos, manifesto):
		DirAccess.remove_absolute(parcial)
		_falhou("download incompleto (%d de %d bytes)" % [lidos, int(manifesto["bytes"])])
		return
	DirAccess.rename_absolute(parcial, _arquivo())
	_instalar()


func _instalar() -> void:
	estado = "baixado"
	_mostrar("Versão %s baixada. Confirme a instalação." % manifesto["versao_nome"],
		[["Instalar", _abrir_instalador], ["Abrir no navegador", _abrir_navegador], ["Depois", _fechar]])
	_abrir_instalador()


func _abrir_instalador() -> void:
	if OS.shell_open(ProjectSettings.globalize_path(_arquivo())) != OK:
		_falhou("não deu para abrir o instalador — use 'Abrir no navegador'")


func _abrir_navegador() -> void:
	OS.shell_open(str(manifesto["apk"]))


func _falhou(motivo: String) -> void:
	estado = "erro"
	detalhe = motivo
	_mostrar("Atualização: " + motivo,
		[["Tentar de novo", _baixar], ["Abrir no navegador", _abrir_navegador], ["Depois", _fechar]])


# ---------- internos ----------

func _arquivo() -> String:
	return PASTA + "galapago-%d.apk" % int(manifesto.get("versao_codigo", 0))


func _faxina(manter: String) -> void:
	var d := DirAccess.open(PASTA)
	if d == null:
		return
	for f in d.get_files():
		if f != manter:
			d.remove(f)


func _tamanho(caminho: String) -> int:
	var f := FileAccess.open(caminho, FileAccess.READ)
	return f.get_length() if f else -1


func _desligar() -> void:
	if _http == null:
		return
	for c in _http.request_completed.get_connections():
		_http.request_completed.disconnect(c["callable"])


func _fechar() -> void:
	if _painel:
		_painel.queue_free()
		_painel = null


func _mostrar(texto: String, botoes: Array) -> void:
	if _painel == null:
		_painel = PanelContainer.new()
		_painel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 24)
		_painel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_painel.grow_vertical = Control.GROW_DIRECTION_BEGIN
		add_child(_painel)
		var coluna := VBoxContainer.new()
		coluna.add_theme_constant_override("separation", 10)
		_painel.add_child(coluna)
		# RETRATO: texto em cima (com quebra de linha), botões embaixo — na
		# paisagem o texto e os botões ficavam lado a lado e estouravam a tela.
		_texto = Label.new()
		_texto.add_theme_font_size_override("font_size", 22)
		_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_texto.custom_minimum_size = Vector2(320, 0)
		coluna.add_child(_texto)
		_botoes = HBoxContainer.new()
		_botoes.add_theme_constant_override("separation", 12)
		coluna.add_child(_botoes)
		_barra = ProgressBar.new()
		_barra.custom_minimum_size = Vector2(0, 26)
		_barra.visible = false
		coluna.add_child(_barra)
	_texto.text = "  " + texto
	_barra.visible = estado == "baixando"
	for b in _botoes.get_children():
		b.queue_free()
	for par in botoes:
		var b := Button.new()
		b.text = par[0]
		b.custom_minimum_size = Vector2(0, 60)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(par[1])
		_botoes.add_child(b)
