extends "res://testes/caso.gd"
## P25/1.2: janela real não é delta simulado nem cronômetro de CPU/GPU.
## P25/1.4: tempo de render da API só com o painel ligado; <=0 vira n/d.
## P25/1.5: painel curto, histórico de 60 s em anel, registro para copiar.
const Diagnostico := preload("res://jogo/diagnostico.gd")
const Hud := preload("res://jogo/hud.gd")
const Main := preload("res://jogo/main.gd")


func _painel() -> Label:
	var d := Diagnostico.new()
	Engine.get_main_loop().root.add_child(d)
	return d


## Linha de histórico injetada (sem GPU real).
func _linha(t: float, fps: float, max_ms: float, gpu3d: float, cpu3d: float,
		janela := 0.5, ncpu := 1, ngpu := 1) -> Dictionary:
	var nc := ncpu if cpu3d > 0.0 else 0
	var ng := ngpu if gpu3d > 0.0 else 0
	return {"t": t, "janela": janela, "quadros": roundi(fps * janela), "fps": fps,
		"intervalo_ms": 1000.0 / fps, "max_ms": max_ms, "delta_ms": 1000.0 / fps,
		"vps": [{"rotulo": Diagnostico.CURTO_3D, "cpu": cpu3d, "gpu": gpu3d,
			"ncpu": nc, "ngpu": ng, "soma_cpu": maxf(cpu3d, 0.0) * nc,
			"soma_gpu": maxf(gpu3d, 0.0) * ng},
			{"rotulo": Diagnostico.CURTO_TELA, "cpu": 0.5, "gpu": -1.0}],
		"calls": 345, "prim": 0}


func test_desligado_nao_coleta_e_nao_intercepta_mapa() -> void:
	var d := _painel()
	checar(not d.visible and not d.is_processing(), "padrão oculto e sem _process")
	igual(d.mouse_filter, Control.MOUSE_FILTER_IGNORE, "texto deixa eventos passarem")
	d.amostrar(100, 1.0)
	igual(d._anterior_us, 0, "amostra desligada ignorada")
	igual(d.historico().size(), 0, "desligado não grava histórico")
	d.free()


func test_janela_real_painel_curto_e_reinicio_sem_historia_da_pausa() -> void:
	var d := _painel()
	d.definir_ligado(true)
	d.amostrar(1000000, 0.01) # primeiro callback só fixa a origem
	d.amostrar(1250000, 0.02)
	checar(d.text.contains("aguardando"), "texto não muda antes de 0,5 s reais")
	d.definir_ligado(true) # sincronizar HUD não pode apagar janela em andamento
	d.amostrar(1500000, 0.04)
	checar(d.text.contains("janela 0,50 s"), "janela é relógio monotônico")
	checar(d.text.contains("FPS: 4,0"), "FPS conta intervalos, não inverte delta")
	checar(d.text.contains("Quadro: 250,0 ms · pior 250,0 ms"), "média/pior da janela")
	checar(d.text.contains("GPU 3D: n/d / 16,7 ms"), "sem 3D medido não estima GPU")
	checar(d.text.contains("CPU render 3D: n/d / 16,7 ms"), "sem 3D medido não estima CPU")
	checar(d.text.split("\n").size() <= 7, "painel curto (%d linhas)" % d.text.split("\n").size())
	for tecnico in ["Escopos", "Draw calls", "primitivas", "Render:", "API:", "Físico"]:
		checar(not d.text.contains(tecnico), "linha técnica '%s' saiu do painel" % tecnico)
	var h: Array = d.historico()
	igual(h.size(), 1, "uma linha por janela")
	igual(h[0]["delta_ms"], 30.0, "delta do motor guardado à parte")
	igual(h[0]["calls"], -1, "headless sem contador não vira zero")
	var texto := d.text
	d.definir_ligado(false)
	checar(not d.is_processing(), "desligar interrompe relógio e contadores")
	d.amostrar(9000000, 5.0)
	d.definir_ligado(true)
	d.amostrar(10000000, 0.5)
	checar(d.text != texto and d.text.contains("aguardando"), "religar não herda janela antiga")
	igual(d._intervalos, 0, "primeiro delta após pausa descartado")
	igual(d.historico().size(), 0, "religar zera o histórico (não mistura sessões)")
	d.free()


func test_indisponibilidade_e_resolucao_sem_zero_enganoso() -> void:
	igual(Diagnostico.contador(0), "n/d", "API não distingue zero de indisponível")
	igual(Diagnostico.contador(-1), "n/d")
	igual(Diagnostico.contador(341), "341", "contador positivo é número retornado, não lotes")
	igual(Diagnostico.dimensoes(Vector2i(1080, 2400)), "1080×2400 px")
	igual(Diagnostico.dimensoes(Vector2i.ZERO), "n/d")


func test_formato_orcamento_e_numero() -> void:
	igual(Diagnostico.ms_orcamento(23.18), "23,2 / 16,7 ms", "ms contra o orçamento de 60 FPS")
	igual(Diagnostico.ms_orcamento(0.78), "0,8 / 16,7 ms")
	igual(Diagnostico.ms_orcamento(0.0), "n/d / 16,7 ms", "0 da API = sem leitura")
	igual(Diagnostico.ms_orcamento(-1.0), "n/d / 16,7 ms")
	igual(Diagnostico.ms_orcamento(NAN), "n/d / 16,7 ms", "NaN não vira número")
	igual(Diagnostico.num(35.81, 1), "35,8", "vírgula decimal")
	igual(Diagnostico.num(INF, 1), "n/d")
	igual(Diagnostico.ms_ou_nd(-1.0), "n/d")


func test_config_e_intima_suspendem_painel_sem_reabrir_desligado() -> void:
	var h := Hud.new()
	Engine.get_main_loop().root.add_child(h)
	h._alternar_info()
	h._alternar_info()
	checar(not h.diagnostico.visible and not h.diagnostico.is_processing(), "CONFIG não liga diagnóstico")
	checar(not h._copiar_btn.visible, "COPIAR escondido com o painel desligado")
	h._diagnostico_btn.pressed.emit()
	checar(h.diagnostico.visible and h.diagnostico.is_processing(), "botão liga")
	checar(h._copiar_btn.visible, "COPIAR aparece com o painel ligado")
	checar(not h._leg.visible, "substitui legenda, não soma texto sobre ela")
	h._alternar_info()
	checar(not h.diagnostico.visible and not h.diagnostico.is_processing(), "CONFIG suspende coleta")
	checar(not h._copiar_btn.visible, "CONFIG oculto esconde o COPIAR")
	checar(h._config_btn.visible and h.atualizador.visible, "ações permanentes preservadas")
	h._alternar_info()
	checar(h.diagnostico.visible and h._copiar_btn.visible, "CONFIG restaura escolha ligada")
	h.definir_vista_intima(true)
	checar(not h.diagnostico.is_processing() and not h._copiar_btn.visible, "vista íntima suspende coleta e esconde o COPIAR")
	h.definir_vista_intima(false)
	checar(h.diagnostico.visible and h.diagnostico.is_processing() and h._copiar_btn.visible, "retorno restaura escolha")
	h._diagnostico_btn.pressed.emit()
	checar(h._leg.visible and not h.diagnostico.visible and not h._copiar_btn.visible, "botão desliga, devolve legenda e esconde o COPIAR")
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
	var reg: String = m.hud.diagnostico.registro()
	checar(reg.contains("3D interno (vista): " + Diagnostico.dimensoes(m.vista.tamanho_interno())), "resolução lida da vista efetiva")
	checar(reg.contains("MSAA 3D: "), "MSAA no registro")
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


func test_tempo_ms_n_d_sem_medida_e_ms_com_medida() -> void:
	igual(Diagnostico.tempo_ms(0.0), "n/d", "API devolve 0 sem medida")
	igual(Diagnostico.tempo_ms(-1.0), "n/d")
	igual(Diagnostico.tempo_ms(NAN), "n/d", "NaN não vira número")
	igual(Diagnostico.tempo_ms(4.214), "4.21 ms")
	igual(Diagnostico.media(9.0, 3), 3.0)
	igual(Diagnostico.media(0.0, 0), -1.0, "janela sem leitura >0 não é zero")


func test_medicao_liga_so_com_painel_e_media_da_janela() -> void:
	var d := _painel()
	igual(d.medindo().size(), 0, "padrão desligado não mede")
	d.definir_ligado(true)
	igual(d.medindo(), PackedStringArray([Diagnostico.ROTULO_TELA]), "ligado mede o viewport raiz")
	d.amostrar(1000000, 0.016) # origem
	d.registrar_tempos(0, 2.0, 0.0)
	d.registrar_tempos(0, 4.0, 6.0)
	d.registrar_tempos(0, -1.0, 0.0) # sem medida: fora da média
	d.amostrar(1500000, 0.016)
	var t: Dictionary = Diagnostico.tempos_de(d.historico()[0], Diagnostico.CURTO_TELA)
	igual(t["cpu"], 3.0, "média das leituras >0 da janela (CPU)")
	igual(t["gpu"], 6.0, "média das leituras >0 da janela (GPU)")
	d.amostrar(2000000, 0.016)
	t = Diagnostico.tempos_de(d.historico()[1], Diagnostico.CURTO_TELA)
	checar(t["cpu"] < 0.0 and t["gpu"] < 0.0, "janela nova não herda leituras")
	d.definir_ligado(false)
	igual(d.medindo().size(), 0, "desligar desliga a medição")
	d.registrar_tempos(0, 5.0, 5.0)
	d.definir_ligado(true)
	igual(d.medindo().size(), 1, "religar volta a medir")
	d.free()


func test_historico_em_anel_respeita_60_s() -> void:
	var d := _painel()
	d.definir_ligado(true)
	var agora := 1000000
	d.amostrar(agora, 0.016)
	for i in 300: # 150 s de janelas de 0,5 s
		agora += 500000
		d.amostrar(agora, 0.016, 100, 200)
	var h: Array = d.historico()
	checar(h.size() <= Diagnostico.TETO_LINHAS, "teto fixo de linhas (%d)" % h.size())
	igual(h.size(), 120, "60 s de janelas de 0,5 s")
	igual(d._hist.size(), Diagnostico.TETO_LINHAS, "o anel não cresce")
	checar(float(h[-1]["t"]) - float(h[0]["t"]) < Diagnostico.HISTORICO_S, "só os últimos 60 s")
	igual(h[-1]["t"], 150.0, "a mais nova por último")
	checar(float(h[0]["t"]) < float(h[1]["t"]), "ordem da mais antiga para a mais nova")
	# janelas mais longas (travadas): o corte é pelo TEMPO, não só pelo teto
	for i in 100:
		agora += 2000000
		d.amostrar(agora, 0.016, 100, 200)
	h = d.historico()
	checar(h.size() <= 30, "janelas de 2 s: só ~30 cabem em 60 s (%d)" % h.size())
	checar(float(h[-1]["t"]) - float(h[0]["t"]) < Diagnostico.HISTORICO_S, "corte pelo tempo")
	d.free()


func test_recorte_janelas_inteiras_desiguais_e_travada_longa() -> void:
	var d := _painel()
	d._guardar(_linha(0.5, 40, 30, 20, 1))
	d._guardar(_linha(1.5, 20, 60, 30, 2, 1.0))
	d._guardar(_linha(60.75, 4, 1000, -1, -1, 59.25))
	var h: Array = d.historico()
	igual(h.size(), 1, "janelas que começam antes de 0,75 s saem inteiras")
	igual(Diagnostico.resumir(h)["duracao"], 59.25, "não rotula >60 s como 60")
	d._guardar(_linha(130.75, 1, 70000, -1, -1, 70.0))
	igual(d.historico().size(), 0, "travada >60 s não cabe, nem sozinha")
	d._guardar(_linha(131.25, 40, 30, 20, 1))
	igual(d.historico().size(), 1, "retoma depois da travada sem herdar dados")
	d.free()


func test_resumo_pondera_leituras_validas_com_duracao_fps_e_ausencia_distintos() -> void:
	var linhas := [_linha(0.5, 40, 30, 10, 2, 0.5, 2, 20),
		_linha(2.5, 10, 200, 30, 6, 2.0, 6, 5),
		_linha(3.5, 30, 50, -1, -1, 1.0)]
	var r := Diagnostico.resumir(linhas)
	igual(r["gpu3d_medio"], 14.0, "(10*20+30*5)/25, não média de janelas")
	igual(r["cpu3d_medio"], 5.0, "CPU tem contagem independente da GPU")
	igual(r["fps_medio"], 20.0, "70 quadros/3,5 s")
	igual(r["quadro_medio"], 50.0)
	igual(r["gpu3d_pior"], 30.0, "pior média de janela, não pico por quadro")
	var d := _painel()
	d.definir_ligado(true)
	d.amostrar(1000000, 0.01)
	d.registrar_tempos(0, 2, 10)
	d.registrar_tempos(0, 0, 30)
	d.amostrar(1500000, 0.01)
	var t: Dictionary = d.historico()[0]["vps"][0]
	igual(t["soma_gpu"], 40.0, "soma original preservada")
	igual(t["ngpu"], 2)
	igual(t["ncpu"], 1, "ausência não conta como zero")
	d.free()


func test_mudar_configuracao_visual_limpa_registro_antes_da_copia() -> void:
	var m := Main.new()
	Engine.get_main_loop().root.add_child(m)
	var d = m.hud.diagnostico
	m.hud._diagnostico_btn.pressed.emit()
	d.amostrar(1000000, 0.01)
	d.amostrar(1500000, 0.01)
	igual(d.historico().size(), 1)
	m.definir_pixel_pass(not m.vista.pixel_pass)
	checar(d.registro().contains("Sem janelas inteiras"), "cópia não mistura modos")
	igual(d.historico().size(), 0)
	igual(d._anterior_us, 0, "janela incompleta também sai")
	m.free()


func test_resumo_media_min_max_com_dados_injetados() -> void:
	var linhas := [_linha(0.5, 40.0, 30.0, 20.0, 1.0), _linha(1.0, 30.0, 45.0, 26.0, -1.0),
		_linha(1.5, 50.0, 22.0, -1.0, 0.6)]
	var r := Diagnostico.resumir(linhas)
	igual(r["janelas"], 3)
	igual(r["duracao"], 1.5)
	igual(r["fps_min"], 30.0, "FPS mínimo")
	igual(r["fps_max"], 50.0, "FPS máximo")
	igual(r["fps_medio"], 40.0, "FPS médio = quadros ÷ segundos")
	igual(r["quadro_medio"], 25.0, "quadro médio ponderado")
	igual(r["pico"], 45.0, "pior pico")
	igual(r["gpu3d_medio"], 23.0, "GPU 3D: média só das janelas com leitura")
	igual(r["gpu3d_pior"], 26.0)
	igual(r["cpu3d_medio"], 0.8)
	igual(r["cpu3d_pior"], 1.0)
	var vazio := Diagnostico.resumir([])
	igual(vazio["gpu3d_medio"], -1.0, "sem janelas: nada estimado")


func test_registro_tem_cabecalho_resumo_tabela_e_notas() -> void:
	var cab := {"Jogo": "Projeto Galápago", "Versão": "v0.40.0-b1", "Aparelho": "n/d"}
	var linhas := [_linha(0.5, 40.0, 30.0, 20.0, 1.0), _linha(1.0, 30.0, 45.0, 26.0, -1.0)]
	var txt := Diagnostico.montar_registro(cab, linhas)
	for parte in ["== Aparelho e jogo ==", "Versão: v0.40.0-b1", "Aparelho: n/d",
			"== Resumo", "FPS: médio 35,0 · mín 30,0 · máx 40,0", "pior pico 45,0 ms",
			"GPU 3D: médio 23,0 / 16,7 ms · pior janela 26,0 / 16,7 ms",
			"== Tabela", "t | FPS | quadro | pico | delta | 3D cpu/gpu | Tela cpu/gpu | calls | prim",
			"0,5 | 40,0 | 25,0 | 30,0 | 25,0 | 1,00/20,00 | 0,50/n/d | 345 | n/d",
			"1,0 | 30,0 | 33,3 | 45,0 | 33,3 | n/d/26,00 | 0,50/n/d | 345 | n/d",
			"== Notas de escopo ==", "soma ≠ o quadro", "Primitivas ≠ só triângulos",
			"n/d = sem leitura", "Custo da instrumentação"]:
		checar(txt.contains(parte), "registro contém '%s'" % parte)
	var vazio := Diagnostico.montar_registro(cab, [])
	checar(vazio.contains("Sem janelas inteiras"), "registro vazio diz que não há janelas")


func test_copiar_registro_injeta_area_de_transferencia_e_avisa() -> void:
	var m := Main.new()
	Engine.get_main_loop().root.add_child(m)
	var h = m.hud
	var copiado := []
	h.area_transferencia = func(t: String) -> void: copiado.append(t)
	h._diagnostico_btn.pressed.emit()
	h.diagnostico.amostrar(1000000, 0.1)
	h.diagnostico.amostrar(1500000, 0.1)
	h.diagnostico.amostrar(2000000, 0.1)
	h._copiar_btn.pressed.emit()
	igual(copiado.size(), 1, "um toque, uma cópia")
	var txt: String = copiado[0]
	checar(txt.contains("Versão: " + Hud.texto_versao()), "a mesma versão do título da HUD")
	checar(txt.contains("Vista: alta") and txt.contains("Hostilidade: desligada"), "estado da HUD no cabeçalho")
	checar(txt.contains("Modo: PIXEL ART"), "modo visual no cabeçalho")
	checar(txt.contains("janelas: 2"), "resumo das janelas gravadas")
	igual(h._copiar_btn.text, "COPIADO: 2 janelas", "aviso no próprio botão")
	h._process(1.0)
	igual(h._copiar_btn.text, "COPIADO: 2 janelas", "aviso dura ~1,5 s")
	h._process(0.6)
	igual(h._copiar_btn.text, Hud.TEXTO_COPIAR, "volta ao rótulo")
	m.free()


func test_hud_oculta_desliga_medicao_e_botoes_fora_do_painel() -> void:
	var m := Main.new()
	Engine.get_main_loop().root.add_child(m)
	var h = m.hud
	igual(h.diagnostico.medindo().size(), 0, "jogo começa sem medir")
	h._diagnostico_btn.pressed.emit()
	igual(h.diagnostico.medindo(), PackedStringArray([Diagnostico.ROTULO_3D, Diagnostico.ROTULO_CHAO, Diagnostico.ROTULO_TELA]), "3D, chão e tela, cada um com rótulo")
	m.definir_pixel_pass(not m.vista.pixel_pass) # mesmo sv: a medição continua no viewport certo
	h.diagnostico.amostrar(1000000, 0.1)
	h.diagnostico.amostrar(1500000, 0.1)
	igual(h.diagnostico.medindo().size(), 3, "troca do Pixel Pass mantém os três")
	h._alternar_info()
	igual(h.diagnostico.medindo().size(), 0, "CONFIG oculto desliga a medição")
	h._alternar_info()
	h.definir_vista_intima(true)
	igual(h.diagnostico.medindo().size(), 0, "vista íntima desliga a medição")
	h.definir_vista_intima(false)
	igual(h.diagnostico.medindo().size(), 3, "volta a medir")
	# botões da coluna esquerda (Verificar só existe em build publicado: criado
	# aqui) fora do retângulo do painel ancorado à direita, com o texto cheio
	h.diagnostico.amostrar(3000000, 0.1) # religar limpou o texto: janela nova cheia
	h.diagnostico.amostrar(3500000, 0.1)
	var b: Button = h._criar_verificar()
	var largura := 720.0
	var tam: Vector2 = h.diagnostico.get_combined_minimum_size()
	var painel := Rect2(Vector2(largura - 16.0 - tam.x, Hud.TOPO + 34.0), tam)
	checar(tam.y > 150.0, "painel com texto cheio medido (%s)" % tam)
	var botoes: Array = [h._pulo_auto, h._hostil_btn, h._config_btn, h._pixel_btn,
		h._diagnostico_btn, h._copiar_btn, b]
	var rets: Array = []
	for bt in botoes:
		var r := Rect2(bt.position, bt.get_combined_minimum_size())
		checar(not painel.intersects(r), "%s não cobre o painel (%s × %s)" % [bt.text, painel, r])
		checar(r.position.x <= 20.0 and r.end.x <= 260.0, "%s na coluna esquerda, longe do centro" % bt.text)
		rets.append(r)
	for i in rets.size():
		for j in range(i + 1, rets.size()):
			checar(not rets[i].intersects(rets[j]), "%s × %s sem sobreposição" % [botoes[i].text, botoes[j].text])
	h._diagnostico_btn.pressed.emit()
	igual(h.diagnostico.medindo().size(), 0, "botão desliga a medição")
	m.free()
