extends "res://testes/caso.gd"
## sim/camera3d.gd — matemática da câmera ortográfica orbital.
const Camera3DSim := preload("res://sim/camera3d.gd")

const TELA := Vector2(720, 1280)


func _cfg() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://dados/camera3d.json"))


func _cam() -> Camera3DSim:
	return Camera3DSim.new(_cfg())


func test_carrega_json() -> void:
	var cfg := _cfg()
	checar(cfg.has("_leia"), "json tem _leia")
	var c := Camera3DSim.new(cfg)
	igual(c.vista, "alta", "vista inicial")
	perto(c.pitch, deg_to_rad(-60.0), 1e-6, "pitch alta")
	perto(c.altura_mundo, 25.0, 1e-6, "altura alta")
	perto(c.distancia(), 60.0, 1e-6, "distância")
	igual(int(c.snap()["texel"] * 640.0 + 0.5), 25, "altura interna padrão 640")


func test_espacos_ida_e_volta() -> void:
	var q := Vector2(96.0, -40.0)
	var p := Camera3DSim.para_3d(q, 2.0)
	perto(p.x, 3.0, 1e-6, "x")
	perto(p.y, 2.0, 1e-6, "h")
	perto(p.z, -1.25, 1e-6, "z")
	perto_v(Camera3DSim.para_plano(p), q, 1e-4, "volta ao plano")


func test_foco_no_centro_da_tela() -> void:
	var c := _cam()
	for yaw_g in [0.0, 37.0, -120.0, 179.0]:
		c.yaw = deg_to_rad(yaw_g)
		c.posicionar(Vector3(5.5, 1.0, -3.25))
		var q := Camera3DSim.para_plano(c.foco)
		perto_v(c.chao_para_tela(TELA, 1.0) * q, TELA * 0.5, 1e-3, "foco no centro yaw %s" % yaw_g)
		perto_v(c.ponto_para_tela(c.foco, TELA), TELA * 0.5, 1e-3, "ponto_para_tela")
	# com a câmera posta: a posição fica atrás do foco ao longo de base.z
	var t: Transform3D = c.transform_camera()
	perto((t.origin - c.foco).length(), 60.0, 1e-4, "distância da câmera")
	checar(t.origin.y > c.foco.y, "câmera acima do foco (pitch negativo)")


func test_ida_e_volta_chao_tela_chao() -> void:
	var c := _cam()
	c.posicionar(Vector3(2.0, 0.0, 7.0))
	var pontos := [Vector2(0, 0), Vector2(100, -50), Vector2(-333.3, 812.0), Vector2(64, 224)]
	for pitch_g in [-60.0, -35.0, -80.0]:
		for yaw_g in [0.0, 45.0, 90.0, -150.0]:
			c.pitch = deg_to_rad(pitch_g)
			c.yaw = deg_to_rad(yaw_g)
			for h in [0.0, 1.5]:
				var ida: Transform2D = c.chao_para_tela(TELA, h)
				var volta: Transform2D = c.tela_para_chao(TELA, h)
				for q in pontos:
					var tela: Vector2 = ida * q
					perto_v(volta * tela, q, 1e-3, "ida-volta p%s y%s h%s" % [pitch_g, yaw_g, h])
					# coerente com a projeção 3D genérica
					perto_v(c.ponto_para_tela(Camera3DSim.para_3d(q, h), TELA), tela, 1e-3, "afim = projeção")


func test_yaw_troca_eixos() -> void:
	var c := _cam()
	var s := TELA.y / c.altura_mundo
	var seno := absf(sin(c.pitch))
	# yaw 0: leste (+x) vai para a direita; sul (+q.y) desce, encurtado
	var t0: Transform2D = c.chao_para_tela(TELA)
	perto_v(t0.basis_xform(Vector2(32, 0)), Vector2(s, 0), 1e-3, "yaw0 leste → direita")
	perto_v(t0.basis_xform(Vector2(0, 32)), Vector2(0, s * seno), 1e-3, "yaw0 sul → baixo")
	# yaw +90: leste desce (vem para a câmera); sul vai para a esquerda
	c.yaw = deg_to_rad(90.0)
	var t90: Transform2D = c.chao_para_tela(TELA)
	perto_v(t90.basis_xform(Vector2(32, 0)), Vector2(0, s * seno), 1e-3, "yaw90 leste → baixo")
	perto_v(t90.basis_xform(Vector2(0, 32)), Vector2(-s, 0), 1e-3, "yaw90 sul → esquerda")


func test_encurtamento_vertical_e_seno_do_pitch() -> void:
	var c := _cam()
	for pitch_g in [-60.0, -35.0, -20.0, -89.0]:
		for yaw_g in [0.0, 30.0, -100.0]:
			c.pitch = deg_to_rad(pitch_g)
			c.yaw = deg_to_rad(yaw_g)
			var b: Basis = c.base()
			# um passo de 1 unidade no chão ao longo da profundidade (−z da
			# câmera projetado no chão) e outro ao longo da direita
			var prof := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
			var dir := Vector3(b.x.x, 0.0, b.x.z).normalized()
			var t: Transform2D = c.chao_para_tela(TELA)
			var s := TELA.y / c.altura_mundo
			var dv: Vector2 = t.basis_xform(Vector2(prof.x, prof.z) * 32.0)
			var dh: Vector2 = t.basis_xform(Vector2(dir.x, dir.z) * 32.0)
			perto(dv.length() / s, absf(sin(c.pitch)), 1e-4, "encurtamento p%s y%s" % [pitch_g, yaw_g])
			checar(dv.y < 0.0, "ir para o fundo sobe na tela")
			perto(dh.length() / s, 1.0, 1e-4, "horizontal sem encurtar")


func test_snap_resto_reconstroi() -> void:
	var c := _cam()
	var focos := [Vector3(0.123, 0.0, 4.567), Vector3(-17.31, 2.0, 9.99), Vector3(3.3333, 0.5, -8.0)]
	for yaw_g in [0.0, 33.0, -140.0]:
		c.yaw = deg_to_rad(yaw_g)
		for f in focos:
			c.posicionar(f)
			var sn: Dictionary = c.snap(640)
			var texel: float = sn["texel"]
			perto(texel, c.altura_mundo / 640.0, 1e-9, "texel")
			var r: Vector2 = sn["resto_px"]
			checar(absf(r.x) <= 0.5 + 1e-6 and absf(r.y) <= 0.5 + 1e-6, "|resto| ≤ 0,5 texel: %s" % r)
			var b: Basis = c.base()
			var t: Transform3D = sn["transform"]
			# posição arredondada + resto (direita, cima = −y de tela) = suave
			var reconst: Vector3 = t.origin + b.x * (r.x * texel) - b.y * (r.y * texel)
			perto((reconst - c.transform_camera().origin).length(), 0.0, 1e-5, "reconstrói a suave")
			checar(t.basis.is_equal_approx(b), "mesma base")
			# o foco arredondado cai exatamente no grid de texel
			var fs: Vector3 = t.origin - b.z * c.distancia()
			var cel: Vector2i = sn["celula_trama"]
			perto(fs.dot(b.x) / texel, float(cel.x), 1e-3, "grid x")
			perto(-fs.dot(b.y) / texel, float(cel.y), 1e-3, "grid y (baixo)")
			# sinal do resto: a imagem do snap põe o ponto `resto_px` à frente
			var p: Vector3 = f + Vector3(1.7, 0.0, -2.2)
			var s_int := 640.0 / c.altura_mundo
			var d_snap: Vector3 = p - fs
			var na_snap := Vector2(d_snap.dot(b.x), -d_snap.dot(b.y)) * s_int
			var d_suave: Vector3 = p - c.foco
			var na_suave := Vector2(d_suave.dot(b.x), -d_suave.dot(b.y)) * s_int
			perto_v(na_snap - r, na_suave, 1e-3, "deslocar a imagem de −resto dá a suave")


func test_snap_um_texel_a_direita() -> void:
	var c := _cam()
	c.yaw = deg_to_rad(25.0)
	c.posicionar(Vector3(1.2345, 0.0, 6.789))
	var a: Dictionary = c.snap(640)
	var b: Basis = c.base()
	c.posicionar(c.foco + b.x * float(a["texel"]))
	var d: Dictionary = c.snap(640)
	igual(d["celula_trama"] - a["celula_trama"], Vector2i(1, 0), "1 texel à direita")
	perto_v(d["resto_px"], a["resto_px"], 1e-3, "resto mantido")
	# 1 texel para CIMA ⇒ celula_trama.y diminui (y de tela para baixo)
	c.posicionar(c.foco + b.y * float(a["texel"]))
	var e: Dictionary = c.snap(640)
	igual(e["celula_trama"] - d["celula_trama"], Vector2i(0, -1), "1 texel acima")


func test_seguir_converge_e_independe_do_fps() -> void:
	var c := _cam()
	var alvo := Vector3(10.0, 0.0, -4.0)
	c.posicionar(Vector3.ZERO)
	for _i in 300:
		c.seguir(alvo, 1.0 / 60.0)
	perto((c.foco - alvo).length(), 0.0, 1e-3, "converge")
	var um := _cam()
	var dois := _cam()
	um.seguir(alvo, 0.1)
	dois.seguir(alvo, 0.05)
	dois.seguir(alvo, 0.05)
	perto((um.foco - dois.foco).length(), 0.0, 1e-4, "2×dt/2 = 1×dt")
	checar(um.foco.length() > 0.0 and um.foco.length() < alvo.length(), "aproximou sem chegar")
	var p := _cam()
	p.posicionar(alvo)
	perto((p.foco - alvo).length(), 0.0, 1e-9, "posicionar não suaviza")


func test_transicao_de_vista() -> void:
	var c := _cam()
	var dur := 0.35
	checar(c.definir_vista("intima"), "vista conhecida")
	checar(not c.definir_vista("inexistente"), "vista desconhecida recusada")
	igual(c.vista, "intima", "nome trocou")
	checar(c.em_transicao(), "transição em curso")
	c.avancar(dur * 0.5)
	var meio_p := lerpf(deg_to_rad(-60.0), deg_to_rad(-35.0), 0.5)
	perto(c.pitch, meio_p, 1e-4, "smoothstep na metade")
	perto(c.altura_mundo, 16.5, 1e-4, "altura na metade")
	c.avancar(dur * 0.25)
	checar(c.em_transicao(), "ainda em curso")
	c.avancar(dur * 0.25 + 1e-4)
	checar(not c.em_transicao(), "terminou no tempo")
	perto(c.pitch, deg_to_rad(-35.0), 1e-6, "pitch alvo")
	perto(c.altura_mundo, 8.0, 1e-6, "altura alvo mais próxima")
	igual(c.alternar_vista(), "alta", "alternar volta à alta")
	c.avancar(1.0)
	perto(c.pitch, deg_to_rad(-60.0), 1e-6, "pitch alta")
	perto(c.altura_mundo, 25.0, 1e-6, "altura alta")


func test_zoom_ortografico_continuo_sem_movimento_residual() -> void:
	var c := _cam()
	c.definir_vista("intima")
	c.avancar(0.1)
	c.definir_zoom(0.37)
	var altura := lerpf(25.0, 8.0, 0.37)
	perto(c.altura_mundo, altura, 1e-5, "posição fracionária da pinça")
	perto(c.pitch, lerpf(deg_to_rad(-60.0), deg_to_rad(-35.0), 0.37), 1e-5, "pitch contínuo")
	checar(not c.em_transicao(), "pinça cancela transição programática")
	c.avancar(4.0)
	perto(c.altura_mundo, altura, 1e-5, "sem salto após soltar")
	c.definir_zoom(1.0)
	perto(c.altura_mundo, 8.0, 1e-5, "aproxima além da antiga altura 12")
	perto(c.px_por_unidade(TELA), 160.0, 1e-5, "maior escala ortográfica")
	c.definir_zoom(-2.0)
	perto(c.altura_mundo, 25.0, 1e-5, "clamp distante")
	c.definir_zoom(2.0)
	perto(c.altura_mundo, 8.0, 1e-5, "clamp próximo")


func test_giro_normaliza_sem_salto() -> void:
	var c := _cam()
	igual(c.vista, "alta", "base")
	c.girar_px(100.0)
	perto(c.yaw, deg_to_rad(35.0), 1e-6, "arrastar à direita aumenta o yaw")
	c.yaw = deg_to_rad(178.0)
	var antes: Basis = c.base()
	var tela_antes: Vector2 = c.chao_para_tela(TELA) * Vector2(200, 50)
	c.girar(deg_to_rad(4.0))
	checar(c.yaw >= -PI and c.yaw < PI, "yaw em [-PI, PI): %s" % c.yaw)
	perto(c.yaw, deg_to_rad(-178.0), 1e-5, "deu a volta")
	c.girar(deg_to_rad(-4.0))
	checar(c.base().is_equal_approx(antes), "voltar dá a mesma base")
	perto_v(c.chao_para_tela(TELA) * Vector2(200, 50), tela_antes, 1e-3, "sem salto na tela")
	# um passo pequeno atravessando ±PI muda pouco a imagem
	c.yaw = deg_to_rad(179.9)
	var a: Vector2 = c.chao_para_tela(TELA) * Vector2(200, 50)
	c.girar(deg_to_rad(0.2))
	var b: Vector2 = c.chao_para_tela(TELA) * Vector2(200, 50)
	checar(a.distance_to(b) < 2.0, "atravessar ±PI é contínuo: %s" % a.distance_to(b))
