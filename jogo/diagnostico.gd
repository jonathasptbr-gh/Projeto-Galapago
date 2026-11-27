extends Label
## P25/1.2 + 1.4: observação; não muda render, AA, sombras nem resolução.
## Time mede intervalos entre callbacks _process (inclui espera, VSync e limites).
## O delta recebido é tempo do motor, não tempo gasto processando este script.
## Contadores, resolução e texto só a cada >=0,5 s reais. Não guarda histórico.
## Desligado/oculto (CONFIG, vista íntima): nem relógio, nem contadores, nem
## medição de render.
##
## 1.4 — tempo de render por viewport, da API (`RenderingServer.
## viewport_set_measure_render_time`): ligado SÓ com o painel visível, desligado
## (`false`) ao ocultar/desligar ou sair da árvore. Escopos, cada um o seu
## viewport (a API mede cada um à parte; a soma não é o quadro inteiro):
##   "3D (vista.sv)"     — o SubViewport do mundo 3D (sombras, mata, contorno);
##   "Chão (mapa)"       — o SubViewport 2D do mapa do chão (`chao.gd`);
##   "Tela (HUD+imagem)" — o viewport raiz: HUD e a imagem do 3D composta.
## Valor mostrado = MÉDIA das leituras >0 da janela (2 getters por viewport
## por quadro; leitura <=0 = ainda sem medida, fica fora da média). Uma
## leitura só do último quadro oscila demais para comparar; nenhuma leitura
## >0 na janela vira `n/d` (nada estimado). A medição segue o objeto
## Viewport: se a vista trocar de SubViewport, a cada janela o conjunto
## medido é conferido e religado (o Pixel Pass só redimensiona o mesmo `sv`).
const JANELA_US := 500000
const ROTULO_3D := "3D (vista.sv)"
const ROTULO_CHAO := "Chão (mapa)"
const ROTULO_TELA := "Tela (HUD+imagem)"

var _vista: CanvasLayer
var _chao: SubViewport
var _ligado := false
var _inicio_us := 0
var _anterior_us := 0
var _intervalos := 0
var _delta_soma := 0.0
var _maior_us := 0
# viewports com medição LIGADA agora: [{rotulo, vp}]; vazio = nada medindo
var _medidos: Array = []
var _soma_cpu := PackedFloat64Array()
var _soma_gpu := PackedFloat64Array()
var _n_cpu := PackedInt32Array()
var _n_gpu := PackedInt32Array()


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


func _exit_tree() -> void:
	# fora da árvore não se mede; religa na próxima janela se voltar ligado
	_aplicar_medicao([])


func configurar(vista: CanvasLayer, chao: SubViewport = null) -> void:
	_vista = vista
	_chao = chao
	_sincronizar_medicao()


func definir_ligado(ligado: bool) -> void:
	var mudou := _ligado != ligado
	_ligado = ligado
	visible = ligado
	set_process(ligado)
	_sincronizar_medicao()
	if not mudou:
		return
	_reiniciar()
	text = "DIAGNÓSTICO · aguardando janela >=0,5 s"


## Rótulos dos viewports com medição de render ligada agora (vazio = desligada).
func medindo() -> PackedStringArray:
	var r := PackedStringArray()
	for m in _medidos:
		r.append(m["rotulo"])
	return r


func _reiniciar() -> void:
	_inicio_us = 0
	_anterior_us = 0
	_intervalos = 0
	_delta_soma = 0.0
	_maior_us = 0
	_zerar_tempos()


func _zerar_tempos() -> void:
	var n := _medidos.size()
	_soma_cpu.resize(n)
	_soma_gpu.resize(n)
	_n_cpu.resize(n)
	_n_gpu.resize(n)
	_soma_cpu.fill(0.0)
	_soma_gpu.fill(0.0)
	_n_cpu.fill(0)
	_n_gpu.fill(0)


## Os viewports que DEVEM ser medidos com o painel ligado, na ordem do texto.
func _alvos() -> Array:
	var r: Array = []
	if _vista != null and is_instance_valid(_vista) and is_instance_valid(_vista.sv):
		r.append({"rotulo": ROTULO_3D, "vp": _vista.sv})
	if _chao != null and is_instance_valid(_chao):
		r.append({"rotulo": ROTULO_CHAO, "vp": _chao})
	if is_inside_tree():
		r.append({"rotulo": ROTULO_TELA, "vp": get_viewport()})
	return r


static func _vps(lista: Array) -> Array:
	var r: Array = []
	for m in lista:
		r.append(m["vp"])
	return r


## Liga a medição nos alvos se o painel está ligado; senão desliga tudo.
## Só mexe no RenderingServer quando o conjunto muda.
func _sincronizar_medicao() -> void:
	var desejados: Array = _alvos() if _ligado else []
	if _vps(desejados) == _vps(_medidos):
		return
	_aplicar_medicao(desejados)


func _aplicar_medicao(desejados: Array) -> void:
	var novos := _vps(desejados)
	for m in _medidos:
		var vp: Viewport = m["vp"]
		if is_instance_valid(vp) and not novos.has(vp):
			RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), false)
	for m in desejados:
		var vp: Viewport = m["vp"]
		RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
	_medidos = desejados
	_zerar_tempos()


## Leitura de um quadro do viewport `i` de `medindo()`; <=0 fica fora da média.
## Público para o teste injetar valores sem depender de GPU real.
func registrar_tempos(i: int, cpu_ms: float, gpu_ms: float) -> void:
	if i < 0 or i >= _medidos.size():
		return
	if cpu_ms > 0.0:
		_soma_cpu[i] += cpu_ms
		_n_cpu[i] += 1
	if gpu_ms > 0.0:
		_soma_gpu[i] += gpu_ms
		_n_gpu[i] += 1


func _process(delta: float) -> void:
	if not _ligado:
		return
	for i in _medidos.size():
		var vp: Viewport = _medidos[i]["vp"]
		if not is_instance_valid(vp):
			continue
		var rid := vp.get_viewport_rid()
		registrar_tempos(i, RenderingServer.viewport_get_measured_render_time_cpu(rid),
			RenderingServer.viewport_get_measured_render_time_gpu(rid))
	amostrar(Time.get_ticks_usec(), delta)


## Relógio injetável para conferir a janela sem medir velocidade do host de teste.
func amostrar(agora_us: int, delta: float) -> void:
	if not _ligado:
		return
	if _anterior_us == 0:
		_inicio_us = agora_us
		_anterior_us = agora_us
		_zerar_tempos()
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
	linhas.append("Render API · média/quadro na janela:")
	for i in _medidos.size():
		linhas.append("%s: CPU %s · GPU %s" % [_medidos[i]["rotulo"],
			tempo_ms(media(_soma_cpu[i], _n_cpu[i])), tempo_ms(media(_soma_gpu[i], _n_gpu[i]))])
	if _medidos.is_empty():
		linhas.append("CPU/GPU: n/d (sem viewport medido)")
	linhas.append("Escopos à parte; soma ≠ quadro")
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
	linhas.append("Custo: relógio+tempos/quadro; texto >=0,5 s")
	if Engine.get_write_movie_path() != "":
		linhas.append("MOVIE fixo · prévia, não benchmark")
	text = "\n".join(linhas)
	# Preserva o último instante como início da próxima janela; não mistura pausas.
	_inicio_us = agora_us
	_intervalos = 0
	_delta_soma = 0.0
	_maior_us = 0
	# confere se o conjunto medido ainda é o certo (vista trocada, árvore etc.)
	_sincronizar_medicao()
	_zerar_tempos()


static func dimensoes(tamanho: Vector2i) -> String:
	if tamanho.x <= 0 or tamanho.y <= 0:
		return "n/d"
	return "%d×%d px" % [tamanho.x, tamanho.y]


## A API retorna 0 também quando indisponível, sem flag de suporte: não adivinhar.
## Nesta cena não vazia, preferimos omitir um zero legítimo a inventar suporte.
static func contador(valor: int) -> String:
	return str(valor) if valor > 0 else "n/d"


## Média das leituras positivas; sem leitura = -1 (vira n/d em `tempo_ms`).
static func media(soma: float, n: int) -> float:
	return soma / n if n > 0 else -1.0


## Tempo da API em ms; <=0 (ou NaN) = sem medida: `n/d`, nunca estimado.
static func tempo_ms(valor: float) -> String:
	if not (valor > 0.0):
		return "n/d"
	return "%.2f ms" % valor
