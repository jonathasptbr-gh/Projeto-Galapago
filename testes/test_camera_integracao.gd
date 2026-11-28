extends "res://testes/caso.gd"
## Integração dedo × câmera no `jogo/main.gd` (P24: mundo 3D, `sim/camera3d.gd`).
## A pinça ajusta continuamente a projeção ortográfica, sem mudar os gestos;
## a barra gira o yaw sem virar gesto; o toque cai no chão sob o dedo.

const Main := preload("res://jogo/main.gd")
const Espaco := preload("res://jogo/mundo3d/espaco.gd")


func _criar() -> Node:
	var main := Main.new()
	Engine.get_main_loop().root.add_child(main)
	return main


func _toque(id: int, pos: Vector2, pressionado: bool, cancelado := false) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.index = id
	ev.position = pos
	ev.pressed = pressionado
	ev.canceled = cancelado
	return ev


func _arrasto(id: int, pos: Vector2) -> InputEventScreenDrag:
	var ev := InputEventScreenDrag.new()
	ev.index = id
	ev.position = pos
	return ev


## O caminho REAL do evento: `_input` → GUI → `_unhandled_input`.
func _enviar(m: Node, ev: InputEvent) -> void:
	m.get_viewport().push_input(ev, true)


func test_pinca_muda_projecao_continuamente_sem_ocultar_acoes() -> void:
	var m := _criar()
	var zoom: float = m.camera_toque.zoom
	m._unhandled_input(_toque(0, Vector2(400, 500), true))
	m._input(_toque(1, Vector2(100, 330), true)) # segundo dedo sobre CONFIG
	checar(m.camera_toque.bloqueado, "segundo dedo inicia pinça antes da GUI")
	m.dedo_moveu(1, Vector2(-134, 330))
	var intermediario: float = m.camera_toque.fracao()
	checar(intermediario > 0.5 and intermediario < 0.75, "pinça para numa fração arbitrária")
	perto(m.cam3d.altura_mundo, lerpf(25.0, 8.0, intermediario), 0.001, "zoom ortográfico contínuo")
	perto(m.hud._zoom_altura, m.cam3d.altura_mundo, 1e-6, "registro do diagnóstico lê a altura aplicada")
	perto(m.hud._zoom_fracao, intermediario, 1e-6, "registro do diagnóstico lê a fração da pinça")
	checar(m.hud.copiar_registro().contains("Aproximação"), "registro mostra a aproximação")
	checar(m.hud._config_btn.visible and m.hud._pulo_auto.visible, "ações seguem acessíveis")
	checar(m.barra.is_visible_in_tree(), "barra continua visível")
	m._input(_toque(1, Vector2(-134, 330), false))
	m._input(_toque(0, Vector2(400, 500), false))
	m._process(0.4)
	perto(m.cam3d.altura_mundo, lerpf(25.0, 8.0, intermediario), 0.001, "soltar conserva zoom intermediário")
	m.dedo_desceu(2, Vector2(400, 500))
	m.dedo_desceu(3, Vector2(600, 500))
	m.dedo_moveu(3, Vector2(500, 500))
	m.dedo_subiu(2, Vector2(400, 500))
	m.dedo_subiu(3, Vector2(500, 500))
	perto(m.camera_toque.zoom, zoom, 0.001, "pinça retorna ao zoom original")
	perto(m.cam3d.altura_mundo, 25.0, 0.001, "vista distante restaurada")
	m.free()


func test_desenho_e_toque_na_vista_proxima_e_distante() -> void:
	for fracao in [0.0, 1.0]:
		var m := _criar()
		m.camera_toque.zoom = lerpf(m.camera_toque.ZOOM_MIN, m.camera_toque.ZOOM_MAX, fracao)
		m._aplicar_camera()
		m.tempo_ms = 1000.0
		m.dedo_desceu(0, Vector2(360, 700))
		m.tempo_ms = 1080.0
		m.dedo_moveu(0, Vector2(400, 650))
		m.tempo_ms = 1160.0
		m.dedo_moveu(0, Vector2(450, 600))
		checar(m.reconhecedor.desenhando(), "arrastar desenha no zoom %s" % fracao)
		m._process(0.016)
		checar(m.corpo.em_rota(), "rota ativa durante arrasto no zoom %s" % fracao)
		m.tempo_ms = 1200.0
		m.dedo_subiu(0, Vector2(480, 570))
		checar(not m.reconhecedor.ativo(), "soltar fecha o gesto no zoom %s" % fracao)
		checar(m.corpo.em_rota(), "rota persiste após soltar no zoom %s" % fracao)
		m.tempo_ms = 2000.0
		m.dedo_desceu(1, Vector2(500, 700))
		m.tempo_ms = 2070.0
		m.dedo_subiu(1, Vector2(500, 700))
		m.tempo_ms = 2500.0
		m._process(0.016)
		checar(m.corpo.carregando(), "toque ainda inicia tiro no zoom %s" % fracao)
		m.free()


func test_pinca_cancelamento_e_foco_nao_criam_comando_residual() -> void:
	var m := _criar()
	m.dedo_desceu(0, Vector2(300, 500))
	m.dedo_desceu(1, Vector2(400, 500))
	m.dedo_moveu(1, Vector2(500, 500))
	m.dedo_subiu(0, Vector2(300, 500))
	m.dedo_subiu(1, Vector2(500, 500))
	var zoom: float = m.camera_toque.zoom
	m.tempo_ms = 800.0
	m.dedo_desceu(2, Vector2(400, 500))
	m._input(_toque(2, Vector2(400, 500), false, true))
	checar(not m.reconhecedor.ativo(), "cancelamento encerra toque")
	m.tempo_ms = 1200.0
	m.dedo_desceu(3, Vector2(400, 500))
	m.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	checar(m.camera_toque.dedos.is_empty(), "perda de foco limpa contatos")
	checar(not m.reconhecedor.ativo(), "sem gesto residual")
	perto(m.camera_toque.zoom, zoom, 0.001, "limpeza conserva zoom")
	m.free()


## P24 — o ponto de tela tocado cai no chão 3D SOB o dedo (ida e volta
## `mundo_de` → `tela_de`) em qualquer yaw. S5b — as MARCAS DE CHÃO (trilha,
## perigos, mira) moram no mapa do chão: o ponto `p` (px da sim) vira o
## texel `chao.raiz · p`; o terreno, pelo `chao_ret` do SEU material, lê esse
## texel exatamente no topo 3D da célula de `p` — e esse ponto 3D cai na tela
## sob o dedo. Os projéteis (no ar) seguem na afim da câmera com `relevo`.
func test_projecao_comum_para_efeitos_e_chao() -> void:
	var m := _criar()
	var tela: Vector2 = m.get_viewport_rect().size
	var centro := tela * 0.5
	var toques := [centro, centro + Vector2(-140, -90), centro + Vector2(120, 160),
		centro + Vector2(60, -220), centro + Vector2(-200, 240)]
	var alturas_vistas := {}
	# o mapa do chão: tamanho, afim fixa e a textura ligada a TODO o terreno
	var chao: SubViewport = m.chao
	checar(chao.size.x <= chao.LADO_MAX and chao.size.y <= chao.LADO_MAX, "textura do chão até %d px (%s)" % [chao.LADO_MAX, chao.size])
	checar(chao.transparent_bg and chao.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "mapa do chão transparente e sempre atualizado")
	checar(chao.raiz.transform.is_equal_approx(chao.transform_chao()), "raiz do chão na afim fixa")
	var mats: Array = [m.mata._mat_solo]
	checar(mats[0] != null, "o solo da mata tem material")
	var tex: Texture2D = chao.get_texture()
	for mat in mats:
		checar(bool(mat.get_shader_parameter("usar_chao")), "terreno lê o mapa do chão")
		checar(mat.get_shader_parameter("chao") == tex, "terreno lê ESTA textura")
	var ret: Vector4 = mats[0].get_shader_parameter("chao_ret")
	checar(ret.is_equal_approx(chao.ret_shader()), "chao_ret do material = o do mapa")
	for no in [m.trilha, m.perigos, m.mira]:
		checar(no.get_parent() == chao.raiz and no.transform == Transform2D.IDENTITY,
			"%s no mapa do chão sem transformação própria" % no.get_class())
		checar(no.get_viewport() == chao, "%s desenha na textura do chão" % no.get_class())
	checar(not m.perigos.no_ar and m.perigos_ar.no_ar, "marcas de chão não desenham projéteis; o cuspe no ar, sim")
	for graus in [0.0, 90.0, 180.0]:
		m.cam3d.yaw = 0.0
		m.cam3d.girar(deg_to_rad(graus))
		m._atualizar_camera(0.0)
		var rot := " (yaw %d°)" % int(graus)
		perto(absf(angle_difference(m.cam3d.yaw, deg_to_rad(graus))), 0.0, 0.0001, "yaw aplicado" + rot)
		var ref: Transform2D = m.cam3d.chao_para_tela(tela, Espaco.altura_3d(Main.NIVEL_REF))
		checar(m.sobre.transform.is_equal_approx(ref), "projéteis na afim da câmera" + rot)
		checar(m.chao_tela().is_equal_approx(ref), "chao_tela é a mesma afim" + rot)
		checar(chao.raiz.transform.is_equal_approx(chao.transform_chao()), "o giro não mexe no mapa do chão" + rot)
		for no in [m.efeitos_ar, m.perigos_ar]:
			checar(no.get_parent() == m.sobre and no.transform == Transform2D.IDENTITY,
				"%s (no ar) herda a afim sem transformação própria%s" % [no.get_class(), rot])
		for t in toques:
			var p: Vector2 = m.mundo_de(t)
			var c: Vector2i = m.mundo.celula_de(p)
			checar(m.mundo.dentro(c), "toque %s cai dentro do mapa%s" % [t, rot])
			alturas_vistas[m.mundo.altura(c)] = true
			perto_v(m.tela_de(p), t, 0.01, "toque %s cai sob o dedo%s" % [t, rot])
			# a marca da trilha em p: texel no mapa do chão…
			var texel: Vector2 = m.trilha.get_global_transform() * p
			checar(Rect2(Vector2.ZERO, Vector2(chao.size)).has_point(texel), "texel %s dentro da textura%s" % [texel, rot])
			# …que o terreno lê no topo 3D da célula de p (conta do toon.gdshader)…
			var topo := Espaco.ponto(p, m.mundo.altura(c))
			var uv := Vector2((topo.x - ret.x) * ret.z, (topo.z - ret.y) * ret.w)
			perto_v(uv * Vector2(chao.size), texel, 0.001, "o terreno lê o texel da marca no topo da célula%s" % rot)
			perto_v(chao.uv_de_3d(topo), uv, 0.000001, "uv_de_3d = a conta do shader" + rot)
			# …e esse topo cai na tela sob o dedo
			perto_v(m.cam3d.ponto_para_tela(topo, tela), t, 0.01, "marca do chão sob o dedo%s" % rot)
			# os projéteis (no ar): relevo na afim da câmera, também sob o dedo
			perto_v(m.efeitos_ar.get_global_transform() * m.relevo(p), t, 0.01, "projétil sob o dedo%s" % rot)
			perto_v(m.perigos_ar.get_global_transform() * m.relevo(p), t, 0.01, "cuspe e tiro compartilham projeção" + rot)
		# a criatura: o pé dela (ator 3D) projeta onde a trilha marca o corpo
		var pe: Vector2 = m.cam3d.ponto_para_tela(m.ator_criatura.position, tela)
		perto_v(m.tela_de(m.corpo.pos), pe, 0.5, "trilha no pé da criatura" + rot)
		var topo_cria := Espaco.ponto(m.corpo.pos, m.mundo.altura(m.mundo.celula_de(m.corpo.pos)))
		perto_v(m.cam3d.ponto_para_tela(topo_cria, tela), pe, 0.5, "marca do chão no pé da criatura" + rot)
	checar(alturas_vistas.size() >= 2, "a amostra cobre mais de uma altura de terreno (%s)" % [alturas_vistas.keys()])
	# girar muda a afim: o mesmo ponto de mundo sai em outro lugar da tela
	m.cam3d.yaw = 0.0
	m._atualizar_camera(0.0)
	var q: Vector2 = m.mundo_de(centro + Vector2(0, -200))
	var a0: Vector2 = m.tela_de(q)
	m.cam3d.girar(PI)
	m._atualizar_camera(0.0)
	checar(m.tela_de(q).distance_to(a0) > 100.0, "giro de 180° move o ponto na tela")
	m.free()


## P24 — BARRA DE GIRO: o dedo que DESCE na faixa do topo gira a câmera e NÃO
## vira gesto, pinça nem caminho (nem se depois sair da faixa); o dedo que
## desce fora dela desenha como sempre, mesmo passando pela faixa.
func test_barra_gira_sem_gesto_e_dedo_fora_desenha() -> void:
	var m := _criar()
	checar(m.barra.is_visible_in_tree(), "barra visível")
	perto(m.barra.size.y, Main.ALTURA_BARRA, 0.001, "barra com a altura da faixa")
	var yaw0: float = m.cam3d.yaw
	var y_barra := Main.ALTURA_BARRA * 0.5
	checar(m.na_barra(Vector2(300, y_barra)) and not m.na_barra(Vector2(300, Main.ALTURA_BARRA + 1.0)), "faixa da barra")
	_enviar(m, _toque(0, Vector2(300, y_barra), true))
	m.tempo_ms = 300.0
	_enviar(m, _arrasto(0, Vector2(400, y_barra)))
	var esperado := deg_to_rad(100.0 * float(m.cam3d.cfg["giro"]["graus_por_px"]))
	perto(angle_difference(yaw0, m.cam3d.yaw), esperado, 0.0001, "arrastar 100 px gira o yaw")
	# o mesmo dedo descendo para o mundo continua sendo da barra
	_enviar(m, _arrasto(0, Vector2(400, 700)))
	checar(m._dedos.is_empty() and m.camera_toque.dedos.is_empty(), "dedo da barra não entra no gesto nem na pinça")
	checar(not m.reconhecedor.ativo(), "dedo da barra não inicia gesto")
	m._process(0.016)
	checar(m.barra.ativa, "barra realça com o dedo nela")
	checar(not m.corpo.em_rota() and m.corpo.traco.is_empty(), "dedo da barra não gera caminho")
	_enviar(m, _toque(0, Vector2(400, 700), false))
	checar(m._dedos_barra.is_empty(), "soltar libera a barra")
	m._process(0.016)
	checar(not m.barra.ativa, "barra apaga ao soltar")
	var yaw1: float = m.cam3d.yaw
	# dedo FORA da barra: desenha (e não gira), mesmo passando pela faixa
	m.tempo_ms = 1000.0
	_enviar(m, _toque(1, Vector2(360, 700), true))
	checar(m._dedos.has(1) and m.reconhecedor.ativo(), "dedo fora da barra inicia gesto")
	m.tempo_ms = 1200.0
	_enviar(m, _arrasto(1, Vector2(360, 560)))
	m.tempo_ms = 1300.0
	_enviar(m, _arrasto(1, Vector2(460, 420)))
	checar(m.reconhecedor.desenhando(), "dedo fora da barra desenha")
	m._process(0.016)
	checar(m.corpo.em_rota() and m.corpo.traco.size() >= 2, "o desenho vira caminho")
	m.tempo_ms = 1350.0
	_enviar(m, _arrasto(1, Vector2(500, y_barra)))
	perto(m.cam3d.yaw, yaw1, 0.000001, "dedo do desenho que passa pela faixa não gira")
	checar(m.reconhecedor.desenhando(), "o desenho segue dentro da faixa")
	# um segundo dedo na barra enquanto o primeiro desenha: gira, sem pinça
	_enviar(m, _toque(2, Vector2(200, y_barra), true))
	_enviar(m, _arrasto(2, Vector2(150, y_barra)))
	checar(not m.camera_toque.bloqueado, "dedo na barra não vira pinça")
	checar(absf(angle_difference(yaw1, m.cam3d.yaw)) > 0.1, "segundo dedo na barra gira durante o desenho")
	checar(m.reconhecedor.desenhando(), "o desenho não é interrompido pelo giro")
	_enviar(m, _toque(2, Vector2(150, y_barra), false))
	_enviar(m, _toque(1, Vector2(500, y_barra), false))
	checar(m._dedos.is_empty() and m._dedos_barra.is_empty(), "contatos liberados")
	m.free()
