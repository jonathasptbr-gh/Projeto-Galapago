extends "res://testes/caso.gd"
## P25/1.2: janela real não é delta simulado nem cronômetro de CPU/GPU.
const Diagnostico := preload("res://jogo/diagnostico.gd")
const Hud := preload("res://jogo/hud.gd")
const Main := preload("res://jogo/main.gd")


func _painel() -> Label:
	var d := Diagnostico.new()
	Engine.get_main_loop().root.add_child(d)
	return d


func test_desligado_nao_coleta_e_nao_intercepta_mapa() -> void:
	var d := _painel()
	checar(not d.visible and not d.is_processing(), "padrão oculto e sem _process")
	igual(d.mouse_filter, Control.MOUSE_FILTER_IGNORE, "texto deixa eventos passarem")
	d.amostrar(100, 1.0)
	igual(d._anterior_us, 0, "amostra desligada ignorada")
	d.free()


func test_janela_real_delta_e_reinicio_sem_historia_da_pausa() -> void:
	var d := _painel()
	d.definir_ligado(true)
	d.amostrar(1000000, 0.01) # primeiro callback só fixa a origem
	d.amostrar(1250000, 0.02)
	checar(d.text.contains("aguardando"), "texto não muda antes de 0,5 s reais")
	d.definir_ligado(true) # sincronizar HUD não pode apagar janela em andamento
	d.amostrar(1500000, 0.04)
	checar(d.text.contains("janela real 0.50 s"), "janela é relógio monotônico")
	checar(d.text.contains("FPS (callbacks/Time): 4.0"), "FPS conta intervalos, não inverte delta")
	checar(d.text.contains("Intervalo real: 250.0 ms · máx 250.0"), "média/máximo da janela")
	checar(d.text.contains("Delta _process médio: 30.0 ms (motor)"), "delta rotulado separadamente")
	checar(d.text.contains("CPU/GPU: n/d"), "sem estimativa CPU/GPU")
	checar(d.text.contains("RS global · último quadro disponível"), "não atribui global só ao mundo 3D")
	checar(d.text.contains("Draw calls: n/d · primitivas: n/d"), "headless sem contador não vira zero")
	var texto := d.text
	d.definir_ligado(false)
	checar(not d.is_processing(), "desligar interrompe relógio e contadores")
	d.amostrar(9000000, 5.0)
	d.definir_ligado(true)
	d.amostrar(10000000, 0.5)
	checar(d.text != texto and d.text.contains("aguardando"), "religar não herda janela antiga")
	igual(d._intervalos, 0, "primeiro delta após pausa descartado")
	d.free()


func test_indisponibilidade_e_resolucao_sem_zero_enganoso() -> void:
	igual(Diagnostico.contador(0), "n/d", "API não distingue zero de indisponível")
	igual(Diagnostico.contador(-1), "n/d")
	igual(Diagnostico.contador(341), "341", "contador positivo é número retornado, não lotes")
	igual(Diagnostico.dimensoes(Vector2i(1080, 2400)), "1080×2400 px")
	igual(Diagnostico.dimensoes(Vector2i.ZERO), "n/d")


func test_config_e_intima_suspendem_painel_sem_reabrir_desligado() -> void:
	var h := Hud.new()
	Engine.get_main_loop().root.add_child(h)
	h._alternar_info()
	h._alternar_info()
	checar(not h.diagnostico.visible and not h.diagnostico.is_processing(), "CONFIG não liga diagnóstico")
	h._diagnostico_btn.pressed.emit()
	checar(h.diagnostico.visible and h.diagnostico.is_processing(), "botão liga")
	checar(not h._leg.visible, "substitui legenda, não soma texto sobre ela")
	h._alternar_info()
	checar(not h.diagnostico.visible and not h.diagnostico.is_processing(), "CONFIG suspende coleta")
	checar(h._config_btn.visible and h.atualizador.visible, "ações permanentes preservadas")
	h._alternar_info()
	checar(h.diagnostico.visible, "CONFIG restaura escolha ligada")
	h.definir_vista_intima(true)
	checar(not h.diagnostico.is_processing(), "vista íntima suspende coleta")
	h.definir_vista_intima(false)
	checar(h.diagnostico.visible and h.diagnostico.is_processing(), "retorno restaura escolha")
	h._diagnostico_btn.pressed.emit()
	checar(h._leg.visible and not h.diagnostico.visible, "botão desliga e devolve legenda")
	checar(h._pixel_btn.visible and h._hostil_btn.visible and h._carga_slider.visible and h._pulo_auto.visible, "controles existentes continuam disponíveis")
	h.free()


func test_main_integra_vista_sem_alterar_render_ou_acoes() -> void:
	var m := Main.new()
	Engine.get_main_loop().root.add_child(m)
	var interno: Vector2i = m.vista.sv.size
	var msaa: int = m.vista.sv.msaa_3d
	var pixel: bool = m.vista.pixel_pass
	var sombra: bool = m.vista.sol.shadow_enabled
	m.hud._diagnostico_btn.pressed.emit()
	m.hud.diagnostico.amostrar(1000000, 0.1)
	m.hud.diagnostico.amostrar(1500000, 0.1)
	checar(m.hud.diagnostico.text.contains("3D interno (vista): " + Diagnostico.dimensoes(m.vista.tamanho_interno())), "resolução lida da vista efetiva")
	igual(m.vista.sv.size, interno, "não muda resolução")
	igual(m.vista.sv.msaa_3d, msaa, "não muda AA")
	igual(m.vista.pixel_pass, pixel, "não muda Pixel Pass")
	igual(m.vista.sol.shadow_enabled, sombra, "não muda sombras")
	# Os sinais originais continuam conectados aos mesmos destinos no main.
	m.hud._pixel_btn.pressed.emit()
	igual(m.vista.pixel_pass, not pixel, "ação PIXEL ART preservada")
	m.hud._hostil_btn.pressed.emit()
	checar(m.hostilidade, "ação HOSTILIDADE preservada")
	m.free()
