extends Label
## P25/1.2 + 1.4 + 1.5: observação; não muda render, AA nem resolução.
## Time mede intervalos entre callbacks _process (inclui espera, VSync e limites).
## O delta recebido é tempo do motor, não tempo gasto processando este script.
## Contadores, resolução e texto só a cada >=0,5 s reais. Desligado/oculto
## (CONFIG, vista íntima): nem relógio, nem contadores, nem medição de render,
## nem histórico.
##
## 1.4 — tempo de render por viewport, da API (`RenderingServer.
## viewport_set_measure_render_time`): ligado SÓ com o painel visível, desligado
## (`false`) ao ocultar/desligar ou sair da árvore. Escopos, cada um o seu
## viewport (a API mede cada um à parte; a soma não é o quadro inteiro):
##   "3D (vista.sv)"     — o SubViewport do mundo 3D (sombras, mata, contorno);
##   "Chão (mapa)"       — o SubViewport 2D do mapa do chão (`chao.gd`);
##   "Tela (HUD+imagem)" — o viewport raiz: HUD e a imagem do 3D composta.
## Valor = MÉDIA das leituras >0 da janela (2 getters por viewport por quadro;
## leitura <=0 = ainda sem medida, fica fora da média); nenhuma leitura >0 na
## janela vira `n/d` (nada estimado). A medição segue o objeto Viewport e é
## conferida a cada janela (o Pixel Pass só redimensiona o mesmo `sv`).
##
## 1.5 — o PAINEL mostra só o útil (FPS, quadro médio/pior, GPU/CPU do 3D
## contra o orçamento de 60 FPS); o resto vai para o REGISTRO que o botão
## COPIAR REGISTRO da HUD põe na área de transferência. "Uso do processador"
## total em % não é medido aqui: CPU de render compara ms com orçamento (16,7 ms).
## HISTÓRICO: uma linha por janela num anel de no máximo `TETO_LINHAS`, cortado
## pelo tempo aos últimos `HISTORICO_S` segundos. Política: desligar, ocultar
## (CONFIG) ou entrar na vista íntima DESCARTA o histórico; ao religar ele
## começa vazio (uma sessão contínua por registro, sem misturar sessões).
const JANELA_US := 500000
const ROTULO_3D := "3D (vista.sv)"
const ROTULO_CHAO := "Chão (mapa)"
const ROTULO_TELA := "Tela (HUD+imagem)"
## nomes curtos (colunas da tabela do registro)
const CURTO_3D := "3D"
const CURTO_CHAO := "Chão"
const CURTO_TELA := "Tela"
## orçamento de um quadro a 60 FPS, em ms
const ORCAMENTO_MS := 1000.0 / 60.0
## histórico: últimos 60 s; 120 = 60 s ÷ janela mínima de 0,5 s (teto fixo)
const HISTORICO_S := 60.0
const TETO_LINHAS := 120

var _vista: CanvasLayer
var _chao: SubViewport
var _ligado := false
var _inicio_us := 0
var _anterior_us := 0
var _sessao_us := 0
var _intervalos := 0
var _delta_soma := 0.0
var _maior_us := 0
# viewports com medição LIGADA agora: [{rotulo, curto, vp}]; vazio = nada medindo
var _medidos: Array = []
var _soma_cpu := PackedFloat64Array()
var _soma_gpu := PackedFloat64Array()
var _n_cpu := PackedInt32Array()
var _n_gpu := PackedInt32Array()
# anel do histórico: `_hist` tem TETO_LINHAS posições; válidas de `_hist_ini`
# por `_hist_n` posições (as mais antigas primeiro)
var _hist: Array = []
var _hist_ini := 0
var _hist_n := 0
# Impede que o cabeçalho atual rotule janelas de outra configuração visual.
var _configuracao: Array = []
var _sombras := "COMPLETAS"


## A troca é síncrona: limpa inclusive a janela parcial antes de copiar/coletar.
func definir_sombras(nome: String) -> void:
	if _sombras == nome:
		return
	_sombras = nome
	_conferir_configuracao()



func _conferir_configuracao() -> void:
	var atual: Array = [get_window().size] if is_inside_tree() else []
	atual.append(_sombras)
	if is_instance_valid(_vista) and is_instance_valid(_vista.sv):
		atual.append_array([_vista.pixel_pass, _vista.tamanho_interno(),
			_vista.sv.size, _vista.sv.msaa_3d, _vista.resolucao_liso, _vista.msaa_liso,
			_vista.sv.scaling_3d_scale])
	if atual != _configuracao:
		_configuracao = atual
		_reiniciar()
		text = "DIAGNÓSTICO · aguardando 0,5 s"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	var ls := LabelSettings.new()
	ls.font_size = 20
	ls.outline_size = 5
	ls.outline_color = Color(0, 0, 0, 0.9)
	label_settings = ls
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.02, 0.03, 0.05, 0.88)
	fundo.set_content_margin_all(8)
	add_theme_stylebox_override("normal", fundo)
	visible = false
	set_process(false)


func _exit_tree() -> void:
	# fora da árvore não se mede; religa na próxima janela se voltar ligado
	_aplicar_medicao([])


func configurar(vista: CanvasLayer, chao: SubViewport = null) -> void:
	if is_instance_valid(_vista):
		_vista.configuracao_alterada.disconnect(_conferir_configuracao)
	_vista = vista
	_chao = chao
	if is_instance_valid(_vista):
		_vista.configuracao_alterada.connect(_conferir_configuracao)
	_conferir_configuracao()
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
	text = "DIAGNÓSTICO · aguardando 0,5 s"


func ligado() -> bool:
	return _ligado


## Rótulos dos viewports com medição de render ligada agora (vazio = desligada).
func medindo() -> PackedStringArray:
	var r := PackedStringArray()
	for m in _medidos:
		r.append(m["rotulo"])
	return r


## O histórico gravado, da janela mais antiga para a mais nova (cópia).
func historico() -> Array:
	var r: Array = []
	for i in _hist_n:
		r.append(_hist[(_hist_ini + i) % TETO_LINHAS])
	return r


func _reiniciar() -> void:
	_inicio_us = 0
	_anterior_us = 0
	_sessao_us = 0
	_intervalos = 0
	_delta_soma = 0.0
	_maior_us = 0
	_zerar_tempos()
	_hist.clear()
	_hist_ini = 0
	_hist_n = 0


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
		r.append({"rotulo": ROTULO_3D, "curto": CURTO_3D, "vp": _vista.sv})
	if _chao != null and is_instance_valid(_chao):
		r.append({"rotulo": ROTULO_CHAO, "curto": CURTO_CHAO, "vp": _chao})
	if is_inside_tree():
		r.append({"rotulo": ROTULO_TELA, "curto": CURTO_TELA, "vp": get_viewport()})
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
## Contadores globais injetáveis (`calls`/`primitivas`); -2 = ler da API.
func amostrar(agora_us: int, delta: float, calls := -2, primitivas := -2) -> void:
	if not _ligado:
		return
	_conferir_configuracao()
	if _anterior_us == 0:
		_inicio_us = agora_us
		_anterior_us = agora_us
		_sessao_us = agora_us
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
	var pronto := DisplayServer.get_name() != "headless" and Engine.get_frames_drawn() >= 2
	if calls == -2:
		calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME) if pronto else -1
	if primitivas == -2:
		primitivas = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) if pronto else -1
	var janela := float(decorrido) / 1000000.0
	var vps: Array = []
	for i in _medidos.size():
		vps.append({"rotulo": _medidos[i]["curto"], "cpu": media(_soma_cpu[i], _n_cpu[i]),
			"gpu": media(_soma_gpu[i], _n_gpu[i]), "soma_cpu": _soma_cpu[i],
			"soma_gpu": _soma_gpu[i], "ncpu": _n_cpu[i], "ngpu": _n_gpu[i]})
	var linha := {
		"t": float(agora_us - _sessao_us) / 1000000.0,
		"janela": janela,
		"sombras": _sombras,
		"quadros": _intervalos,
		"fps": _intervalos / janela,
		"intervalo_ms": float(decorrido) / _intervalos / 1000.0,
		"max_ms": _maior_us / 1000.0,
		"delta_ms": _delta_soma / _intervalos * 1000.0,
		"vps": vps,
		"calls": calls,
		"prim": primitivas,
	}
	_guardar(linha)
	text = texto_painel(linha, historico())
	# Preserva o último instante como início da próxima janela; não mistura pausas.
	_inicio_us = agora_us
	_intervalos = 0
	_delta_soma = 0.0
	_maior_us = 0
	# confere se o conjunto medido ainda é o certo (vista trocada, árvore etc.)
	_sincronizar_medicao()
	_zerar_tempos()


## Põe a linha no anel e corta o que passou dos últimos HISTORICO_S segundos.
func _guardar(linha: Dictionary) -> void:
	if _hist.size() != TETO_LINHAS:
		_hist.resize(TETO_LINHAS)
	var pos := (_hist_ini + _hist_n) % TETO_LINHAS
	if _hist_n == TETO_LINHAS:
		_hist_ini = (_hist_ini + 1) % TETO_LINHAS
	else:
		_hist_n += 1
	_hist[pos] = linha
	var fim := float(linha["t"])
	# Só janelas INTEIRAS dentro dos 60 s terminados em `fim`. Não rateia picos
	# nem leituras. Uma travada >60 s fica no painel atual, mas não no registro.
	while _hist_n > 0 and float(_hist[_hist_ini]["t"]) - float(_hist[_hist_ini]["janela"]) < fim - HISTORICO_S:
		_hist[_hist_ini] = null
		_hist_ini = (_hist_ini + 1) % TETO_LINHAS
		_hist_n -= 1


# --- texto: funções puras (recebem dados, devolvem string) --------------------

## Painel curto: a janela atual e quanto o registro já guardou.
static func texto_painel(linha: Dictionary, hist: Array) -> String:
	var t3 := tempos_de(linha, CURTO_3D)
	var linhas := PackedStringArray(["DIAGNÓSTICO · janela %s s" % num(linha["janela"], 2)])
	linhas.append("FPS: %s" % num(linha["fps"], 1))
	linhas.append("Quadro: %s ms · pior %s ms" % [num(linha["intervalo_ms"], 1), num(linha["max_ms"], 1)])
	linhas.append("GPU 3D: " + ms_orcamento(t3["gpu"]))
	linhas.append("CPU render 3D: " + ms_orcamento(t3["cpu"]))
	var gravado := 0.0
	for l in hist:
		gravado += float(l["janela"])
	linhas.append("Sombras: " + str(linha.get("sombras", "COMPLETAS")))
	linhas.append("Mais dados: COPIAR (%d s)" % roundi(gravado))
	return "\n".join(linhas)


## CPU/GPU (ms, -1 = sem leitura) do viewport de nome curto `curto` numa linha.
static func tempos_de(linha: Dictionary, curto: String) -> Dictionary:
	for v in linha.get("vps", []):
		if v["rotulo"] == curto:
			return v
	return {"cpu": -1.0, "gpu": -1.0, "soma_cpu": 0.0, "soma_gpu": 0.0, "ncpu": 0, "ngpu": 0}


## "23,2 / 16,7 ms" (leitura contra o orçamento de 60 FPS); sem leitura: n/d.
static func ms_orcamento(valor: float) -> String:
	var v := num(valor, 1) if valor > 0.0 else "n/d"
	return "%s / %s ms" % [v, num(ORCAMENTO_MS, 1)]


## Número com vírgula decimal (pt-BR); NaN/inf viram n/d.
static func num(valor: float, casas: int) -> String:
	if is_nan(valor) or is_inf(valor):
		return "n/d"
	return (("%." + str(casas) + "f") % valor).replace(".", ",")


## ms com 2 casas; <=0 = sem leitura.
static func ms_ou_nd(valor: float) -> String:
	return num(valor, 2) if valor > 0.0 else "n/d"


## Resumo: FPS = quadros ÷ segundos; quadro = segundos ÷ quadros.
## GPU/CPU de render: somas ÷ contagens exatas das leituras válidas, nunca
## média simples das janelas; pior = maior média de janela (-1 = sem leitura).
static func resumir(linhas: Array) -> Dictionary:
	var r := {"janelas": linhas.size(), "duracao": 0.0, "fps_medio": -1.0,
		"fps_min": -1.0, "fps_max": -1.0, "quadro_medio": -1.0, "pico": -1.0,
		"gpu3d_medio": -1.0, "gpu3d_pior": -1.0, "cpu3d_medio": -1.0, "cpu3d_pior": -1.0}
	if linhas.is_empty():
		return r
	var quadros := 0
	var soma_gpu := 0.0
	var n_gpu := 0
	var soma_cpu := 0.0
	var n_cpu := 0
	r["fps_min"] = INF
	for l in linhas:
		r["duracao"] += float(l["janela"])
		quadros += int(l["quadros"])
		r["fps_min"] = minf(r["fps_min"], float(l["fps"]))
		r["fps_max"] = maxf(r["fps_max"], float(l["fps"]))
		r["pico"] = maxf(r["pico"], float(l["max_ms"]))
		var t3 := tempos_de(l, CURTO_3D)
		if t3["gpu"] > 0.0:
			soma_gpu += float(t3["soma_gpu"])
			n_gpu += int(t3["ngpu"])
			r["gpu3d_pior"] = maxf(r["gpu3d_pior"], t3["gpu"])
		if t3["cpu"] > 0.0:
			soma_cpu += float(t3["soma_cpu"])
			n_cpu += int(t3["ncpu"])
			r["cpu3d_pior"] = maxf(r["cpu3d_pior"], t3["cpu"])
	if r["duracao"] > 0.0 and quadros > 0:
		r["fps_medio"] = quadros / r["duracao"]
		r["quadro_medio"] = r["duracao"] * 1000.0 / quadros
	r["gpu3d_medio"] = media(soma_gpu, n_gpu)
	r["cpu3d_medio"] = media(soma_cpu, n_cpu)
	return r


## O texto do REGISTRO (o que o COPIAR REGISTRO põe na área de transferência).
## `cab`: pares rótulo → valor do cabeçalho, na ordem; `linhas`: o histórico.
static func montar_registro(cab: Dictionary, linhas: Array) -> String:
	var o := PackedStringArray(["REGISTRO DO DIAGNÓSTICO — Projeto Galápago",
		"(n/d = sem leitura; nada é estimado)", "", "== Aparelho e jogo =="])
	for k in cab:
		o.append("%s: %s" % [k, cab[k]])
	var r := resumir(linhas)
	o.append("")
	o.append("== Resumo (até os últimos %d s com o painel ligado) ==" % roundi(HISTORICO_S))
	if linhas.is_empty():
		o.append("Sem janelas inteiras no recorte: aguarde uma janela ≥0,5 s e ≤60 s.")
	else:
		o.append("Duração: %s s · janelas: %d" % [num(r["duracao"], 1), r["janelas"]])
		o.append("FPS: médio %s · mín %s · máx %s" % [num(r["fps_medio"], 1), num(r["fps_min"], 1), num(r["fps_max"], 1)])
		o.append("Quadro: médio %s ms · pior pico %s ms (orçamento 60 FPS: %s ms)" % [
			num(r["quadro_medio"], 1), num(r["pico"], 1), num(ORCAMENTO_MS, 1)])
		o.append("GPU 3D: médio %s · pior janela %s" % [ms_orcamento(r["gpu3d_medio"]), ms_orcamento(r["gpu3d_pior"])])
		o.append("CPU render 3D: médio %s · pior janela %s" % [ms_orcamento(r["cpu3d_medio"]), ms_orcamento(r["cpu3d_pior"])])
	# colunas de viewport: todas as vistas no histórico, na ordem em que aparecem
	var cols := PackedStringArray()
	for l in linhas:
		for v in l.get("vps", []):
			if not cols.has(v["rotulo"]):
				cols.append(v["rotulo"])
	o.append("")
	o.append("== Tabela (uma linha por janela ≥0,5 s) ==")
	o.append("Colunas: t = s desde que o painel ligou (fim da janela) · FPS · quadro = intervalo médio (ms) · pico = intervalo máximo (ms) · delta = delta médio do motor (ms) · %s = render CPU/GPU médio (ms) · calls = draw calls · prim = primitivas (globais, último quadro da janela)" % (
		"/".join(cols) if not cols.is_empty() else "viewports"))
	var cab_tab := PackedStringArray(["t", "FPS", "quadro", "pico", "delta"])
	for c in cols:
		cab_tab.append(c + " cpu/gpu")
	cab_tab.append_array(["calls", "prim"])
	o.append(" | ".join(cab_tab))
	for l in linhas:
		var cel := PackedStringArray([num(l["t"], 1), num(l["fps"], 1), num(l["intervalo_ms"], 1),
			num(l["max_ms"], 1), num(l["delta_ms"], 1)])
		for c in cols:
			var t := tempos_de(l, c)
			cel.append("%s/%s" % [ms_ou_nd(t["cpu"]), ms_ou_nd(t["gpu"])])
		cel.append_array([contador(int(l["calls"])), contador(int(l["prim"]))])
		o.append(" | ".join(cel))
	o.append("")
	o.append("== Notas de escopo ==")
	o.append("- Orçamento de 60 FPS = %s ms por quadro: referência, não medição. CPU de render não é uso total do processador nem porcentagem de ocupação." % num(ORCAMENTO_MS, 1))
	o.append("- FPS e quadro: intervalos reais entre _process (Time), incluem espera de VSync e limites. Delta = tempo do motor. FPS mín/máx são de janelas.")
	o.append("- CPU de render/GPU: API do Godot (viewport_get_measured_render_time_*), média das leituras >0 por quadro na janela; resumo ponderado pelas contagens válidas, pior = maior média de janela. Cada viewport à parte: 3D = mundo 3D (vista.sv); Chão = mapa do chão (SubViewport 2D); Tela = viewport raiz (HUD + imagem do 3D). A soma ≠ o quadro inteiro.")
	o.append("- Draw calls e primitivas: globais, só o último quadro de cada janela. Primitivas ≠ só triângulos; calls ≠ MultiMesh.")
	o.append("- n/d = sem leitura (a API devolve 0 também quando indisponível).")
	o.append("- Histórico: só janelas inteiras dentro dos %d s terminados na última janela concluída (teto %d); janela que cruza o corte, inclusive travada >60 s, é descartada sem rateio. A duração real pode ser menor. Desligar, ocultar (CONFIG), vista íntima ou mudar modo/resolução/MSAA/sombras zeram o histórico." % [roundi(HISTORICO_S), TETO_LINHAS])
	o.append("- Cabeçalho lido na cópia. Instrumentação e captura de tela podem interferir; impacto desconhecido, inclusive possível pausa ao capturar. A cópia não entra nas janelas já congeladas, mas pode afetar as seguintes.")
	o.append("- Custo da instrumentação: relógio + 2 leituras por viewport por quadro, texto a cada ≥0,5 s; não medido à parte.")
	return "\n".join(o)


## Cabeçalho medido agora (só leituras baratas da API); `extra` acrescenta o
## que a HUD conhece (versão, vista, hostilidade).
func cabecalho(extra: Dictionary = {}) -> Dictionary:
	var c := {"Jogo": "Projeto Galápago", "Versão": extra.get("Versão", "n/d"),
		"Data/hora": Time.get_datetime_string_from_system(false, true)}
	c["Aparelho"] = _ou_nd(OS.get_model_name())
	c["Sistema"] = _ou_nd(("%s %s" % [OS.get_name(), OS.get_version()]).strip_edges())
	# a API documenta nome do processador vazio no Android e na Web: n/d sem chamar
	var cpu := "" if OS.get_name() in ["Android", "Web"] else OS.get_processor_name()
	c["Processador"] = "%s · %d núcleos" % [_ou_nd(cpu), OS.get_processor_count()]
	c["GPU"] = _ou_nd(("%s %s" % [RenderingServer.get_video_adapter_vendor(),
		RenderingServer.get_video_adapter_name()]).strip_edges())
	c["Renderizador / API"] = "%s / %s %s" % [RenderingServer.get_current_rendering_method(),
		RenderingServer.get_current_rendering_driver_name(), RenderingServer.get_video_adapter_api_version()]
	var hz := DisplayServer.screen_get_refresh_rate()
	c["Tela"] = "%s Hz · VSync %s · limite de FPS %s" % [num(hz, 0) if hz > 0.0 else "n/d",
		["desligado", "ligado", "adaptativo", "mailbox"][clampi(DisplayServer.window_get_vsync_mode(), 0, 3)],
		str(Engine.max_fps) if Engine.max_fps > 0 else "nenhum"]
	if _vista != null and is_instance_valid(_vista):
		c["Modo"] = "PIXEL ART " + ("ligado" if _vista.pixel_pass else "desligado (3D liso)")
		c["MSAA 3D"] = ["desligado", "2×", "4×", "8×"][clampi(_vista.sv.msaa_3d, 0, 3)]
		c["3D interno (vista)"] = dimensoes(_vista.tamanho_interno())
		c["Alvo 3D c/margem (sv)"] = dimensoes(_vista.sv.size)
		c["Escolha liso (sessão)"] = "%d%% · MSAA %s%s" % [_vista.resolucao_liso,
			["desligado", "2×", "4×"][_vista.msaa_liso],
			" (suspensa pelo PIXEL ART)" if _vista.pixel_pass else ""]
		c["Resolução efetiva"] = _vista.texto_resolucao()
		c["Escala 3D nativa"] = "%s (sem escala dupla; interno = sv, salvo margem Pixel Pass)" % num(_vista.sv.scaling_3d_scale, 2)
	c["Sombras"] = _sombras + (" (luz direcional sem sombras em toda a cena)" if _sombras == "DESLIGADAS" else " (copas proxy; troncos mantidos)" if _sombras == "SIMPLIFICADAS" else " (folhas reais e troncos)")
	c["Janela física"] = dimensoes(get_window().size) if is_inside_tree() else "n/d"
	for k in extra:
		if not c.has(k):
			c[k] = extra[k]
	if Engine.get_write_movie_path() != "":
		c["Gravação"] = "MOVIE com tempo fixo: prévia, não benchmark"
	return c


## O registro completo desta sessão (texto para colar no chat).
func registro(extra: Dictionary = {}) -> String:
	_conferir_configuracao()
	var congelado := historico()
	return montar_registro(cabecalho(extra), congelado)


static func _ou_nd(s: String) -> String:
	return s if s.strip_edges() != "" else "n/d"


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
