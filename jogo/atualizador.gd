extends Control
## Ao abrir o jogo: consulta o canal público (só o número da versão) e, se o
## CI publicou um build mais novo, mostra "Atualizar". O botão abre o APK do
## repositório PRIVADO no navegador — baixa se o navegador estiver logado no
## GitHub; o Android pede a confirmação da instalação (ninguém a contorna).
## A decisão em si é da sim/atualizacao.gd (testada); aqui só HTTP e tela.

const A := preload("res://sim/atualizacao.gd")
const URL_CANAL := "https://raw.githubusercontent.com/jonathasptbr-gh/Projeto-Galapago-canal/main/canal.json"

var canal: Dictionary = {}
var _http: HTTPRequest


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var build := int(ProjectSettings.get_setting("galapago/build", 0))
	if build <= 0 or "--demo" in OS.get_cmdline_user_args():
		return
	_http = HTTPRequest.new()
	_http.timeout = 10.0
	add_child(_http)
	_http.request_completed.connect(_recebido.bind(build))
	_http.request("%s?t=%d" % [URL_CANAL, int(Time.get_unix_time_from_system())])


func _recebido(resultado: int, codigo: int, _cab: PackedStringArray, corpo: PackedByteArray, build: int) -> void:
	if resultado != HTTPRequest.RESULT_SUCCESS or codigo != 200:
		return
	canal = A.ler_canal(corpo.get_string_from_utf8())
	if A.deve_atualizar(build, canal):
		_mostrar_aviso()


func _mostrar_aviso() -> void:
	var painel := PanelContainer.new()
	painel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 24)
	painel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	painel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(painel)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 16)
	painel.add_child(linha)
	var texto := Label.new()
	texto.text = "  Nova versão %s disponível" % canal["versao_nome"]
	texto.add_theme_font_size_override("font_size", 24)
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(texto)
	var atualizar := _botao("Atualizar")
	atualizar.pressed.connect(func() -> void: OS.shell_open(str(canal["apk"])))
	linha.add_child(atualizar)
	var depois := _botao("Depois")
	depois.pressed.connect(painel.queue_free)
	linha.add_child(depois)


func _botao(rotulo: String) -> Button:
	var b := Button.new()
	b.text = rotulo
	b.custom_minimum_size = Vector2(170, 64)
	b.add_theme_font_size_override("font_size", 24)
	return b
