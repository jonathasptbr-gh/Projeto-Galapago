extends "res://testes/caso.gd"

const Main := preload("res://jogo/main.gd")
const AdversarioMock := preload("res://jogo/adversario_mock.gd")


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


func test_pinca_segundo_dedo_sobre_hud_e_saida() -> void:
	var m := _criar()
	var zoom: float = m.camera.zoom.x
	m._unhandled_input(_toque(0, Vector2(400, 500), true))
	m._input(_toque(1, Vector2(100, 245), true)) # sobre CONFIG
	checar(m.camera_toque.bloqueado, "segundo dedo inicia pinça antes da GUI")
	m.dedo_moveu(1, Vector2(-100, 245))
	checar(m.camera.zoom.x > zoom, "pinça amplia")
	checar(m.hud.visible and not m.hud._config_btn.visible, "controles ocultos na vista íntima")
	checar(m.hud.atualizador.is_visible_in_tree() and not m.hud._status.visible, "avisos disponíveis sem status comum")
	m.hud.atualizador.estado = "erro"
	m.hud._process(0.0)
	checar(m.hud._status.is_visible_in_tree(), "erro de atualização não fica invisível")
	m.hud.atualizador.estado = "dev"
	m.hud._process(0.0)
	checar(not m.hud._status.visible, "estado comum volta a desaparecer")
	m._input(_toque(1, Vector2(-100, 245), false))
	m._input(_toque(0, Vector2(400, 500), false))
	m.dedo_desceu(2, Vector2(400, 500))
	m.dedo_desceu(3, Vector2(600, 500))
	m.dedo_moveu(3, Vector2(450, 500))
	m.dedo_subiu(2, Vector2(400, 500))
	m.dedo_subiu(3, Vector2(450, 500))
	perto(m.camera.zoom.x, zoom, 0.001, "pinça retorna ao zoom original")
	checar(m.hud.visible and m.hud._config_btn.visible, "HUD restaurada")
	m.free()


func test_controle_para_na_soltura_cancelamento_e_foco() -> void:
	var m := _criar()
	m.dedo_desceu(0, Vector2(300, 500))
	m.dedo_desceu(1, Vector2(400, 500))
	m.dedo_moveu(1, Vector2(500, 500))
	m.dedo_subiu(0, Vector2(300, 500))
	m.dedo_subiu(1, Vector2(500, 500))
	var zoom: float = m.camera.zoom.x
	m.dedo_desceu(2, Vector2(400, 500))
	m.dedo_moveu(2, Vector2(490, 500))
	checar(m.corpo.direcao_relativa.length() > 0.9, "controle move")
	m._input(_toque(2, Vector2(490, 500), false))
	perto_v(m.corpo.direcao_relativa, Vector2.ZERO, 0.001, "soltura para")
	var pos: Vector2 = m.corpo.pos
	m.corpo.passo(0.5, m.mundo, m.alvos)
	perto_v(m.corpo.pos, pos, 0.001, "não retoma movimento")
	perto(m.camera.zoom.x, zoom, 0.001, "controle não altera câmera")
	m.dedo_desceu(3, Vector2(400, 500))
	m.dedo_moveu(3, Vector2(490, 500))
	m._input(_toque(3, Vector2(490, 500), false, true))
	perto_v(m.corpo.direcao_relativa, Vector2.ZERO, 0.001, "cancelamento para")
	m.dedo_desceu(4, Vector2(400, 500))
	m.dedo_moveu(4, Vector2(490, 500))
	m.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	perto_v(m.corpo.direcao_relativa, Vector2.ZERO, 0.001, "perda de foco para")
	checar(m.camera_toque.dedos.is_empty(), "contatos limpos")
	m.free()


func test_projecao_comum_para_efeitos_e_chao() -> void:
	var m := _criar()
	m.dedo_desceu(0, Vector2(300, 500))
	m.dedo_desceu(1, Vector2(400, 500))
	m.dedo_moveu(1, Vector2(500, 500))
	var p := Vector2(180, 220)
	var chao: Vector2 = m.chao.get_global_transform() * p
	var efeito: Vector2 = m.efeitos.get_global_transform() * p
	var mira: Vector2 = m.mira.get_global_transform() * p
	perto_v(efeito, chao, 0.001, "efeito acompanha projeção do chão")
	perto_v(mira, chao, 0.001, "mira acompanha projeção do chão")
	checar(m.mundo_visual.scale.y < 1.0, "plano inclinado")
	var inclinacao: float = m.camera_toque.inclinacao()
	var Mock := preload("res://jogo/mock.gd")
	perto(Mock.desnivel(2.0), -12.0, 0.001, "altura original preservada")
	checar(absf(Mock.desnivel(2.0, inclinacao) * inclinacao) > 12.0, "face projetada cresce")
	m.corpo.pos = m.mundo.centro(Vector2i(8, 8))
	m.criatura._process(1.0)
	var altura: float = m.mundo.altura(Vector2i(8, 8))
	perto(m.efeitos.inclinacao, inclinacao, 0.001, "efeitos recebem inclinação")
	perto(m.mira.inclinacao, inclinacao, 0.001, "mira recebe inclinação")
	perto(m.perigos.inclinacao, inclinacao, 0.001, "perigos recebem inclinação")
	var pos: Vector2 = m.corpo.pos
	perto_v(Mock.ponto_relevo(pos, m.mundo, 1.0), pos, 0.001, "marcas originais preservadas")
	perto(Mock.ponto_relevo(pos, m.mundo, inclinacao).y, pos.y + Mock.desnivel(altura, inclinacao), 0.001, "marcas sobre o planalto")
	var piso_tela: float = (m.corpo.pos.y + Mock.desnivel(altura, inclinacao)) * inclinacao
	var pe_tela: float = m.corpo.pos.y * inclinacao + m.criatura._desnivel
	perto(pe_tela, piso_tela, 0.001, "pé acompanha topo do planalto")
	# No zoom intermediário, a mesma coordenada local deve chegar ao topo real.
	m.camera_toque.zoom = 2.4
	m._aplicar_camera()
	inclinacao = m.camera_toque.inclinacao()
	var marca: Vector2 = Mock.ponto_relevo(pos, m.mundo, inclinacao)
	perto_v(m.mira.get_global_transform() * marca, m.efeitos.get_global_transform() * marca, 0.001, "mira e efeito compartilham transição")
	perto_v(m.perigos.get_global_transform() * marca, m.efeitos.get_global_transform() * marca, 0.001, "perigo compartilha transição")
	var quase_superior: Vector2 = Mock.ponto_relevo(pos, m.mundo, 0.99999)
	checar(quase_superior.distance_to(pos) < 0.01, "sem salto ao sair da vista superior")
	checar(marca.y < pos.y and marca.y > pos.y + Mock.desnivel(altura, inclinacao), "marca interpola entre posição histórica e topo")
	m.adversarios[0].pos = pos
	var no_adv: Node2D = null
	for no in m.objetos_visuais.get_children():
		if no is AdversarioMock:
			no_adv = no
			break
	no_adv._process(0.0)
	perto_v(no_adv.get_global_transform().origin, m.mira.get_global_transform() * marca, 0.001, "adversário acompanha transição das marcas")
	m.free()
