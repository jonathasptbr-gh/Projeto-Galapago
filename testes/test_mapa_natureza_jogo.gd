extends "res://testes/caso.gd"
## O MAPA DE TESTES NATUREZA dentro do jogo (`jogo/main.gd`): a mata de
## sim/natureza.gd + jogo/mundo3d/natureza/, escolhida pelo botão MAPA da HUD.
## A Fundação continua o padrão; os controles são os mesmos.

const Main := preload("res://jogo/main.gd")
const Natureza := preload("res://sim/natureza.gd")
const Mundo := preload("res://sim/mundo.gd")
const Vista := preload("res://jogo/mundo3d/vista.gd")


func _criar(nome := "") -> Node:
	var main := Main.new()
	main.mapa_nome = nome
	Engine.get_main_loop().root.add_child(main)
	return main


func _limpar(m: Node) -> void:
	m.free()
	for meta in [Main.META_MAPA, Main.META_PIXEL]:
		if Engine.has_meta(meta):
			Engine.remove_meta(meta)


func test_fundacao_continua_o_padrao() -> void:
	var m := _criar()
	igual(m.mapa_nome, "fundacao", "sem escolha, a Fundação")
	checar(m.ilha != null and m.mata == null, "a ilha, sem a mata")
	checar(m.vista.contorno.layers != 0, "contorno de tela da Fundação intacto")
	perto(m.vista.altura_relevo, Vista.ALTURA_RELEVO, 0.0001, "fatia da câmera da Fundação intacta")
	igual(m.hud._mapa_btn.text, "MAPA: FUNDAÇÃO", "botão diz o mapa atual")
	_limpar(m)


func test_natureza_monta_a_mata_na_mesma_grade() -> void:
	var m := _criar("natureza")
	checar(m.mata != null and m.ilha == null, "a mata, sem a ilha")
	igual(m.mundo.largura, Natureza.LARGURA, "a sim é a grade da mata")
	igual(m.mundo.altura_grade, Natureza.ALTURA, "a sim é a grade da mata")
	igual(m.vista.contorno.layers, 0, "sem contorno de tela na mata")
	m.vista._reconfigurar()
	igual(m.vista.contorno.layers, 0, "redimensionar não religa o contorno")
	perto(m.vista.altura_relevo, Main.RELEVO_MATA, 0.0001, "fatia da câmera cabe as árvores")
	igual(m.hud._mapa_btn.text, "MAPA: NATUREZA", "botão diz o mapa atual")
	# os pés da criatura no chão da mata: chão andável local y = 0 → 0,4
	var c: Vector2i = m.mundo.celula_de(m.corpo.pos)
	checar(m.mundo.andavel(c, Mundo.SUPERFICIE), "a criatura começa em chão andável")
	perto(m.ator_criatura.position.y, Natureza.origem_3d().y, 0.01, "pés na altura do chão da mata")
	var local: Vector3 = m.ator_criatura.position - m.mata.position
	perto(m.mata.altura(local.x, local.z), 0.0, 0.001, "o desenho é plano onde a sim anda")
	# a árvore da sim está no mesmo lugar no desenho
	var a: Dictionary = Natureza.arvores()[0]
	var cel := Natureza.celula_local(a["x"], a["z"])
	checar(not m.mundo.andavel(cel, Mundo.SUPERFICIE), "a árvore desenhada bloqueia")
	_limpar(m)


func test_natureza_toque_e_chao_alinhados() -> void:
	var m := _criar("natureza")
	m._process(0.016)
	var tela: Vector2 = m.get_viewport_rect().size
	for d in [Vector2.ZERO, Vector2(-120, -80), Vector2(90, 140)]:
		var q: Vector2 = tela * 0.5 + d
		var p: Vector2 = m.mundo_de(q)
		perto_v(m.tela_de(p), q, 0.5, "toque → chão → tela volta ao dedo")
	# o mapa do chão pintado no SOLO da mata, na mesma afim do toque
	var solo: ShaderMaterial = m.mata._mat_solo
	checar(bool(solo.get_shader_parameter("usar_chao")), "trilha/mira pintadas no chão da mata")
	igual(solo.get_shader_parameter("chao_ret"), m.chao.ret_shader(), "mesma afim do mapa do chão")
	# copa vazada sobre a criatura
	for mat in m.mata._mats_foco:
		checar(bool(mat.get_shader_parameter("usar_foco")), "copa vazada ligada")
		perto(Vector3(mat.get_shader_parameter("foco")).distance_to(m.ator_criatura.position), Main.FOCO_COPA, 0.01, "foco na criatura")
	_limpar(m)


func test_natureza_caminho_desenhado_anda_sem_entrar_na_agua() -> void:
	var m := _criar("natureza")
	m._process(0.016)
	var inicio: Vector2 = m.corpo.pos
	# caminho pela trilha, para o norte (z menor): 3 células
	var alvo := inicio + Vector2(0, -96)
	var q0: Vector2 = m.tela_de(inicio)
	var q1: Vector2 = m.tela_de(alvo)
	m.dedo_desceu(0, q0)
	for i in range(1, 11):
		m.tempo_ms += 30.0
		m.dedo_moveu(0, q0.lerp(q1, i / 10.0))
		m._process(0.03)
	m.dedo_subiu(0, q1)
	for i in range(90):
		m._process(0.033)
		checar(m.mundo.andavel(m.mundo.celula_de(m.corpo.pos), Mundo.SUPERFICIE), "nunca em água nem tronco")
	checar(m.corpo.pos.distance_to(inicio) > 40.0, "a criatura andou pelo caminho (%.0f px)" % m.corpo.pos.distance_to(inicio))
	_limpar(m)


func test_botao_mapa_pede_o_outro_mapa() -> void:
	var m := _criar()
	m.hud._mapa_btn.pressed.emit()
	igual(String(Engine.get_meta(Main.META_MAPA, "")), "natureza", "escolha guardada para o recarregamento")
	checar(not m.trocar_mapa("fundacao"), "o mapa atual não recarrega")
	checar(not m.trocar_mapa("lua"), "mapa desconhecido é recusado")
	_limpar(m)
	# a escolha guardada vale para a próxima montagem do main
	Engine.set_meta(Main.META_MAPA, "natureza")
	var n := Main.new()
	Engine.get_main_loop().root.add_child(n)
	igual(n.mapa_nome, "natureza", "o main recarregado abre a Natureza")
	_limpar(n)
