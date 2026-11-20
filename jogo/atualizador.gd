extends Control
## Ao abrir o jogo: consulta o canal público (só o número da versão) e, se o
## CI publicou um build mais novo, mostra "Atualizar". O botão abre o APK do
## repositório PRIVADO no navegador — baixa se o navegador estiver logado no
## GitHub; o Android pede a confirmação da instalação (ninguém a contorna).
## A decisão em si é da sim/atualizacao.gd (testada); aqui só HTTP e tela.

const A := preload("res://sim/atualizacao.gd")
# 1º a API (resposta fresca; sem login: 60 consultas/hora por IP — sobra para
# uma por abertura). Reserva: o raw, que o CDN guarda até 5 min IGNORANDO
# query string (medido: x-cache HIT com parâmetro aleatório).
const FONTES := [
	["https://api.github.com/repos/jonathasptbr-gh/Projeto-Galapago-canal/contents/canal.json",
		["Accept: application/vnd.github.raw+json", "User-Agent: ProjetoGalapago"]],
	["https://raw.githubusercontent.com/jonathasptbr-gh/Projeto-Galapago-canal/main/canal.json",
		["User-Agent: ProjetoGalapago"]],
]

var canal: Dictionary = {}
var _http: HTTPRequest
var _build := 0
var _fonte := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build = int(ProjectSettings.get_setting("galapago/build", 0))
	if _build <= 0 or "--demo" in OS.get_cmdline_user_args():
		return
	_http = HTTPRequest.new()
	_http.timeout = 10.0
	add_child(_http)
	_http.request_completed.connect(_recebido)
	_pedir()


func _pedir() -> void:
	var f: Array = FONTES[_fonte]
	if _http.request(f[0], PackedStringArray(f[1])) != OK:
		_proxima()


func _proxima() -> void:
	_fonte += 1
	if _fonte < FONTES.size():
		_pedir.call_deferred()


func _recebido(resultado: int, codigo: int, _cab: PackedStringArray, corpo: PackedByteArray) -> void:
	if resultado != HTTPRequest.RESULT_SUCCESS or codigo != 200:
		_proxima()
		return
	canal = A.ler_canal(corpo.get_string_from_utf8())
	if canal.is_empty():
		_proxima()
	elif A.deve_atualizar(_build, canal):
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
