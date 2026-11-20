extends Control
## O APK se atualiza sozinho — achar, baixar e entregar ao instalador. O mesmo
## método do Áudio Visual IASD (ShellUpdater.kt), em Godot:
##
## 1. ao abrir, lê o manifesto `versao.json` da Release `dev` do repositório
##    PÚBLICO (releases/download: sem API, sem limite, sem login);
## 2. se o build do manifesto é maior que o deste APK, oferece "Atualizar";
## 3. baixa o APK aqui dentro, com progresso, para user://atualizacao/ (a
##    pasta interna do app — coberta pelo FileProvider do Godot);
## 4. confere o tamanho e chama OS.shell_open(<arquivo>): no Android o Godot o
##    entrega por content:// ao instalador do sistema. A confirmação é do
##    sistema (sempre); na 1ª vez ele pede para permitir "instalar apps" deste
##    jogo (permissão REQUEST_INSTALL_PACKAGES, declarada no preset).
## A decisão em si é da sim/atualizacao.gd (testada); aqui só rede, arquivo e tela.

const A := preload("res://sim/atualizacao.gd")
const MANIFESTO := "https://github.com/jonathasptbr-gh/Projeto-Galapago/releases/download/dev/versao.json"
const PASTA := "user://atualizacao/"
const CABECALHOS := ["User-Agent: ProjetoGalapago"]

var manifesto: Dictionary = {}
var estado := "parado"  # parado | consultando | oferecendo | baixando | pronto | erro
var _build := 0
var _http: HTTPRequest
var _painel: PanelContainer
var _texto: Label
var _barra: ProgressBar
var _botoes: HBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build = int(ProjectSettings.get_setting("galapago/build", 0))
	if _build <= 0 or "--demo" in OS.get_cmdline_user_args():
		return
	_http = HTTPRequest.new()
	_http.timeout = 15.0
	add_child(_http)
	_consultar()


func _consultar() -> void:
	estado = "consultando"
	_http.download_file = ""
	_desligar()
	_http.request_completed.connect(_manifesto_chegou, CONNECT_ONE_SHOT)
	if _http.request(MANIFESTO, PackedStringArray(CABECALHOS)) != OK:
		estado = "parado"


func _manifesto_chegou(resultado: int, codigo: int, _cab: PackedStringArray, corpo: PackedByteArray) -> void:
	estado = "parado"
	if resultado != HTTPRequest.RESULT_SUCCESS or codigo != 200:
		return  # sem rede ou sem Release: tenta na próxima abertura, em silêncio
	manifesto = A.ler_manifesto(corpo.get_string_from_utf8())
	if not A.deve_atualizar(_build, manifesto):
		_faxina("")
		return
	estado = "oferecendo"
	_mostrar("Nova versão %s disponível (%s)" % [manifesto["versao_nome"], A.tamanho_legivel(int(manifesto["bytes"]))],
		[["Atualizar", _baixar], ["Depois", _fechar]])


func _baixar() -> void:
	var alvo := _arquivo()
	DirAccess.make_dir_recursive_absolute(PASTA)
	_faxina(alvo.get_file())
	if FileAccess.file_exists(alvo) and A.download_completo(_tamanho(alvo), manifesto):
		_instalar()  # já baixado antes (o instalador foi fechado sem instalar)
		return
	estado = "baixando"
	_mostrar("Baixando %s…" % manifesto["versao_nome"], [])
	_barra.visible = true
	_http.download_file = alvo + ".part"
	_http.body_size_limit = A.TETO_BYTES
	_http.timeout = 0.0  # download grande em rede lenta: sem teto de tempo total
	_desligar()
	_http.request_completed.connect(_download_chegou, CONNECT_ONE_SHOT)
	if _http.request(str(manifesto["apk"]), PackedStringArray(CABECALHOS)) != OK:
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
	estado = "pronto"
	_mostrar("Versão %s baixada. Confirme a instalação." % manifesto["versao_nome"],
		[["Instalar", _abrir_instalador], ["Depois", _fechar]])
	_abrir_instalador()


func _abrir_instalador() -> void:
	if OS.shell_open(ProjectSettings.globalize_path(_arquivo())) != OK:
		_falhou("não deu para abrir o instalador")


func _falhou(motivo: String) -> void:
	estado = "erro"
	_mostrar("Atualização: " + motivo, [["Tentar de novo", _baixar], ["Depois", _fechar]])


func _process(_delta: float) -> void:
	if estado == "baixando" and _barra and not manifesto.is_empty():
		_barra.value = 100.0 * _http.get_downloaded_bytes() / float(manifesto["bytes"])


# ---------- internos ----------

func _arquivo() -> String:
	return PASTA + "galapago-%d.apk" % int(manifesto.get("versao_codigo", 0))


## Apaga APKs de outras versões (dezenas de MB que não servem mais).
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
	for c in _http.request_completed.get_connections():
		_http.request_completed.disconnect(c["callable"])


func _fechar() -> void:
	if _painel:
		_painel.queue_free()
		_painel = null
	estado = "parado"


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
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 16)
		coluna.add_child(linha)
		_texto = Label.new()
		_texto.add_theme_font_size_override("font_size", 24)
		_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		linha.add_child(_texto)
		_botoes = HBoxContainer.new()
		_botoes.add_theme_constant_override("separation", 12)
		linha.add_child(_botoes)
		_barra = ProgressBar.new()
		_barra.custom_minimum_size = Vector2(0, 28)
		_barra.visible = false
		coluna.add_child(_barra)
	_texto.text = "  " + texto
	_barra.visible = estado == "baixando"
	for b in _botoes.get_children():
		b.queue_free()
	for par in botoes:
		var b := Button.new()
		b.text = par[0]
		b.custom_minimum_size = Vector2(170, 64)
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(par[1])
		_botoes.add_child(b)
