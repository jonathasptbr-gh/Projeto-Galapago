extends "res://testes/caso.gd"
## Controles manuais: projeção real Camera3D → imagem composta, não só a sim.
const Vista := preload("res://jogo/mundo3d/vista.gd")
const Cam := preload("res://sim/camera3d.gd")
const Main := preload("res://jogo/main.gd")
const Hud := preload("res://jogo/hud.gd")


func test_pixels_fisicos_conhecidos_e_arredondamento() -> void:
	var tela := Vector2(720, 1560)
	var esperados := [Vector2i(1440, 3120), Vector2i(1224, 2652),
		Vector2i(1080, 2340), Vector2i(966, 2091), Vector2i(720, 1560)]
	for i in Vista.ESCALAS_LISO.size():
		var px := Vista.pixels_liso(Vector2i(1440, 3120), tela, Vista.ESCALAS_LISO[i])
		igual(px, esperados[i], "pixels reais; 67% arredondado, não anunciado como exato")
		checar(px.x >= 2 and px.y >= 2, "dimensões válidas")
		checar(absf(float(px.x) / px.y - tela.x / tela.y) <= 1.0 / px.y, "erro só de arredondamento")
	igual(Vista.pixels_liso(Vector2i.ONE, Vector2.ONE, 50), Vector2i(2, 2), "mínimo do SubViewport")


func test_projecao_real_centro_cantos_resize_e_contorno() -> void:
	var raiz: Window = Engine.get_main_loop().root
	var original := raiz.size
	var v := Vista.new()
	raiz.add_child(v)
	var cam := Cam.new()
	cam.foco = Vector3(12.31, 1.7, 18.19)
	var sinais := []
	v.configuracao_alterada.connect(func(): sinais.append(true))
	for fisico in [Vector2i(1440, 3120), Vector2i(1080, 2400), Vector2i(721, 1281),
			Vector2i(3120, 1440), Vector2i(720, 1280)]:
		raiz.size = fisico
		# Mesmo caminho do sinal: não injeta tamanho interno nem escala de imagem.
		v._reconfigurar()
		igual(raiz.size, fisico, "janela física conhecida")
		var tela := raiz.get_visible_rect().size
		for p in Vista.ESCALAS_LISO:
			v.resolucao_liso = p
			igual(v.sv.size, Vista.pixels_liso(fisico, tela, p))
			if p == 100:
				igual(v.sv.size, fisico, "100% sempre é a resolução física, sem arredondamento extra")
			igual(v.tamanho_interno(), v.sv.size, "buffer interno = alvo (escala nativa 1)")
			igual(v.sv.scaling_3d_scale, 1.0, "sem redução dupla")
			perto(v.imagem.scale.x, v.imagem.scale.y, 0.000001, "sem esticar eixos")
			var ret := Rect2(v.imagem.position, Vector2(v.sv.size) * v.imagem.scale)
			checar(ret.position.x <= 0.001 and ret.position.y <= 0.001, "cobre topo/esquerda")
			checar(ret.end.x >= tela.x - 0.001 and ret.end.y >= tela.y - 0.001, "cobre baixo/direita")
			for yaw in [0.0, 0.73, PI]:
				cam.yaw = yaw
				for altura in [12.0, 25.0]:
					cam.altura_mundo = altura
					v.aplicar_camera(cam)
					for uv in [Vector2.ZERO, Vector2.ONE, Vector2(1, 0), Vector2(0, 1), Vector2(0.5, 0.5)]:
						var toque: Vector2 = uv * tela
						var q: Vector2 = cam.tela_para_chao(tela, 0.0) * toque
						var ponto := Cam.para_3d(q)
						var interno := v.camera.unproject_position(ponto)
						var composto := v.imagem.position + interno * v.imagem.scale
						perto_v(composto, toque, 0.02, "canvas→chão→Camera3D→imagem %s/%s" % [fisico, p])
			var mat: ShaderMaterial = v.contorno.material_override
			perto(mat.get_shader_parameter("raio") * v.imagem.scale.y,
				v.espessura_contorno, 0.001, "contorno conserva espessura de canvas")
	checar(sinais.size() > 5, "resize/escolha notificam na hora")
	v.free()
	raiz.size = original


func test_msaa_independente_pixel_pass_e_nova_partida() -> void:
	var raiz: Window = Engine.get_main_loop().root
	var v := Vista.new()
	raiz.add_child(v)
	igual(v.resolucao_liso, 100)
	igual(v.sv.msaa_3d, Viewport.MSAA_4X)
	for p in Vista.ESCALAS_LISO:
		v.resolucao_liso = p
		var tamanho := v.sv.size
		for aa in Vista.AA_LISO:
			v.msaa_liso = aa
			igual(v.sv.size, tamanho, "MSAA não muda resolução")
			igual(v.sv.msaa_3d, aa, "AA efetivo")
			igual(v.sv.screen_space_aa, Viewport.SCREEN_SPACE_AA_DISABLED, "sem FXAA substituto")
			var mat: ShaderMaterial = v.contorno.material_override
			igual(mat.get_shader_parameter("profundidade_msaa"), aa != Viewport.MSAA_DISABLED)
			v.pixel_pass = true
			igual(v.tamanho_interno().y, 640)
			igual(v.sv.size.y, 644, "margem Pixel Pass intacta")
			igual(v.sv.msaa_3d, Viewport.MSAA_DISABLED)
			igual(v.sv.scaling_3d_scale, 1.0)
			igual(v.imagem.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
			v.pixel_pass = false
			igual(v.resolucao_liso, p, "preferência de sessão preservada")
			igual(v.sv.size, tamanho, "não recebe escala Pixel Pass dupla")
			igual(v.sv.msaa_3d, aa, "AA restaurado")
	v.free()
	v = Vista.new()
	raiz.add_child(v)
	igual(v.resolucao_liso, 100, "não persiste")
	igual(v.msaa_liso, Viewport.MSAA_4X)
	v.free()


func test_hud_cicla_uma_variavel_e_preserva_chao_toque() -> void:
	var m := Main.new()
	Engine.get_main_loop().root.add_child(m)
	var h = m.hud
	var chao: Vector2i = m.chao.size
	var transform_chao: Transform2D = m.chao.raiz.transform
	var camera: Transform3D = m.vista.camera.transform
	var corpo: Vector2 = m.corpo.pos
	var tela: Vector2 = m.get_viewport_rect().size
	for p in [85, 75, 67, 50, 100]:
		h._resolucao_btn.pressed.emit()
		igual(m.vista.resolucao_liso, p)
		igual(m.vista.msaa_liso, Viewport.MSAA_4X, "botão resolução só muda resolução")
		igual(h._resolucao_btn.text, "3D LISO: %d%%" % p)
		checar(h._resolucao_status.text.contains("%d×%d px" % [m.vista.sv.size.x, m.vista.sv.size.y]), "pixels efetivos visíveis")
		for uv in [Vector2(0.5, 0.5), Vector2(0.1, 0.1), Vector2(0.9, 0.9)]:
			var toque: Vector2 = uv * tela
			var q: Vector2 = m.mundo_de(toque)
			perto_v(m.tela_de(q), toque, 0.01, "mira/caminho continuam no chão sob o dedo")
		igual(m.vista.camera.transform, camera, "não move câmera")
		igual(m.corpo.pos, corpo, "não move criatura")
		igual(m.chao.size, chao, "mapa do chão não reduz")
		igual(m.chao.raiz.transform, transform_chao, "marcas mantêm afim")
		checar(h.get_viewport() == m.get_viewport(), "HUD na tela normal, não no sv")
	for aa in [Viewport.MSAA_2X, Viewport.MSAA_DISABLED, Viewport.MSAA_4X]:
		h._msaa_btn.pressed.emit()
		igual(m.vista.msaa_liso, aa)
		igual(m.vista.resolucao_liso, 100)
	m.definir_pixel_pass(true)
	checar(h._resolucao_btn.disabled and h._msaa_btn.disabled, "Pixel Pass suspende controles liso")
	checar(h._resolucao_status.text.contains("liso suspenso"), "explicação visível")
	m.definir_pixel_pass(false)
	checar(not h._resolucao_btn.disabled and not h._msaa_btn.disabled, "volta habilita liso")
	h._alternar_info()
	checar(not h._resolucao_btn.visible and not h._msaa_btn.visible and not h._resolucao_status.visible, "CONFIG oculta todos")
	h._alternar_info()
	h.definir_vista_intima(true)
	checar(h._resolucao_btn.visible and h._msaa_btn.visible, "zoom próximo mantém controles")
	h.definir_vista_intima(false)
	checar(h._resolucao_btn.visible and h._msaa_btn.visible, "retorno restaura")
	m.free()


func test_registro_limpa_imediato_escala_aa_pixel_resize() -> void:
	var m := Main.new()
	var raiz: Window = Engine.get_main_loop().root
	raiz.add_child(m)
	var original := raiz.size
	var h = m.hud
	var d = h.diagnostico
	h.definir_diagnostico(true)
	var agora := 1000000
	for mudar in [func(): m.vista.resolucao_liso = 75,
			func(): m.vista.msaa_liso = Viewport.MSAA_DISABLED,
			func(): m.definir_pixel_pass(true),
			func(): m.definir_pixel_pass(false),
			func(): raiz.size = Vector2i(1440, 3120)]:
		d.amostrar(agora, 0.016)
		d.amostrar(agora + 500000, 0.016)
		d.amostrar(agora + 700000, 0.016)
		igual(d.historico().size(), 1, "há histórico antes da mudança")
		mudar.call()
		igual(d.historico().size(), 0, "sinal limpa antes da cópia")
		igual(d._anterior_us, 0, "janela parcial descartada")
		igual(d._intervalos, 0)
		igual(d._soma_gpu[0], 0.0, "somas zeradas")
		var registro: String = d.registro()
		checar(registro.contains("Sem janelas inteiras"), "cópia nunca rotula dados antigos")
		checar(registro.contains("Escolha liso (sessão): 75%"), "solicitada separada")
		checar(registro.contains("MSAA 3D: " + m.vista.texto_aa()), "AA efetivo")
		checar(registro.contains("Resolução efetiva: " + m.vista.texto_resolucao()), "pixels/escala reais")
		agora += 2000000
	m.free()
	raiz.size = original


func test_layout_inteiro_inclusive_update_alturas_variadas() -> void:
	var m := Main.new()
	Engine.get_main_loop().root.add_child(m)
	var h = m.hud
	var update: Button = h._criar_verificar()
	h.definir_diagnostico(true)
	h.diagnostico.amostrar(1000000, 0.016)
	h.diagnostico.amostrar(1500000, 0.016)
	for pixel in [false, true]:
		m.definir_pixel_pass(pixel)
		var controles: Array = [h._pulo_auto, h._hostil_btn, h._config_btn, h._carga_rotulo,
			h._carga_slider, h._pixel_btn, h._diagnostico_btn, h._copiar_btn,
			h._sombras_btn, h._resolucao_btn, h._msaa_btn, h._resolucao_status, update]
		var rets: Array = []
		for c in controles:
			var ret := Rect2(c.position, c.get_combined_minimum_size())
			checar(ret.end.x <= 260.0, "%s cabe na coluna esquerda: %s" % [c.get_class(), ret])
			for altura in [1280.0, 1440.0, 1560.0, 1600.0]:
				checar(ret.end.y < altura - 140.0, "não cobre rodapé em altura %s" % altura)
			for anterior in rets:
				checar(not ret.intersects(anterior), "controles sem sobreposição %s/%s" % [ret, anterior])
			rets.append(ret)
		var tam: Vector2 = h.diagnostico.get_combined_minimum_size()
		var painel := Rect2(Vector2(720.0 - 16.0 - tam.x, Hud.TOPO + 34), tam)
		for ret in rets:
			checar(not painel.intersects(ret), "não cobre diagnóstico")
		checar(not Rect2(h._resolucao_btn.position, h._resolucao_btn.size).has_point(Vector2(360, 700)), "centro de toque livre")
	m.free()
