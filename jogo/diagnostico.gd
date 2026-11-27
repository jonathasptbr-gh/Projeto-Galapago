extends Label
## P25/1.2: observação somente, sem configurar render ou cronometrar CPU/GPU.
## Time mede intervalos entre callbacks _process (inclui espera, VSync e limites).
## O delta recebido é tempo do motor, não tempo gasto processando este script.
## Uma leitura simples por quadro; contadores, resolução e texto só a cada >=0,5 s
## reais. Não guarda histórico. Desligado/oculto: nem relógio nem contadores.
const JANELA_US := 500000

var _vista: CanvasLayer
var _ligado := false
var _inicio_us := 0
var _anterior_us := 0
var _intervalos := 0
var _delta_soma := 0.0
var _maior_us := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	var ls := LabelSettings.new()
	ls.font_size = 16
	ls.outline_size = 4
	ls.outline_color = Color(0, 0, 0, 0.9)
	label_settings = ls
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.02, 0.03, 0.05, 0.88)
	add_theme_stylebox_override("normal", fundo)
	visible = false
	set_process(false)


func configurar(vista: CanvasLayer) -> void:
	_vista = vista


func definir_ligado(ligado: bool) -> void:
	var mudou := _ligado != ligado
	_ligado = ligado
	visible = ligado
	set_process(ligado)
	if not mudou:
		return
	_reiniciar()
	text = "DIAGNÓSTICO · aguardando janela >=0,5 s"


func _reiniciar() -> void:
	_inicio_us = 0
	_anterior_us = 0
	_intervalos = 0
	_delta_soma = 0.0
	_maior_us = 0


func _process(delta: float) -> void:
	if not _ligado:
		return
	amostrar(Time.get_ticks_usec(), delta)


## Relógio injetável para conferir a janela sem medir velocidade do host de teste.
func amostrar(agora_us: int, delta: float) -> void:
	if not _ligado:
		return
	if _anterior_us == 0:
		_inicio_us = agora_us
		_anterior_us = agora_us
		return
	var intervalo := agora_us - _anterior_us
	_anterior_us = agora_us
	_intervalos += 1
	_delta_soma += delta
	_maior_us = maxi(_maior_us, intervalo)
	var decorrido := agora_us - _inicio_us
	if decorrido < JANELA_US:
		return
	var janela := float(decorrido) / 1000000.0
	var linhas := PackedStringArray(["DIAGNÓSTICO · janela real %.2f s" % janela])
	linhas.append("FPS (callbacks/Time): %.2f" % (_intervalos / janela))
	linhas.append("Intervalo real: %.1f ms · máx %.1f" % [float(decorrido) / _intervalos / 1000.0, _maior_us / 1000.0])
	linhas.append("Delta _process médio: %.1f ms (motor)" % (_delta_soma / _intervalos * 1000.0))
	linhas.append("CPU/GPU: n/d · intervalo/delta ≠ custo")
	linhas.append("Render: " + RenderingServer.get_current_rendering_method())
	linhas.append("API: " + RenderingServer.get_current_rendering_driver_name())
	if _vista != null:
		linhas.append("3D interno (vista): " + dimensoes(_vista.tamanho_interno()))
		linhas.append("Alvo 3D c/margem (sv): " + dimensoes(_vista.sv.size))
	linhas.append("Físico (Window.size): " + dimensoes(get_window().size))
	linhas.append("RS global · último quadro disponível:")
	var pronto := DisplayServer.get_name() != "headless" and Engine.get_frames_drawn() >= 2
	var calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME) if pronto else -1
	var primitivas := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) if pronto else -1
	linhas.append("Draw calls: %s · primitivas: %s" % [contador(calls), contador(primitivas)])
	linhas.append("Primitivas ≠ só triângulos; calls ≠ MM")
	linhas.append("n/d: sem confirmação (inclusive zero)")
	linhas.append("Custo: relógio/quadro; texto/RS >=0,5 s")
	if Engine.get_write_movie_path() != "":
		linhas.append("MOVIE fixo · prévia, não benchmark")
	text = "\n".join(linhas)
	# Preserva o último instante como início da próxima janela; não mistura pausas.
	_inicio_us = agora_us
	_intervalos = 0
	_delta_soma = 0.0
	_maior_us = 0


static func dimensoes(tamanho: Vector2i) -> String:
	if tamanho.x <= 0 or tamanho.y <= 0:
		return "n/d"
	return "%d×%d px" % [tamanho.x, tamanho.y]


## A API retorna 0 também quando indisponível, sem flag de suporte: não adivinhar.
## Nesta cena não vazia, preferimos omitir um zero legítimo a inventar suporte.
static func contador(valor: int) -> String:
	return str(valor) if valor > 0 else "n/d"
