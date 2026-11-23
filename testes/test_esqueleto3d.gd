extends "res://testes/caso.gd"
## Contrato do esqueleto 3D do canino (Fase A): 22 juntas / 21 ossos em 3D,
## projeção ortográfica com pitch 20°, oito yaws, socket por nome e a mesma
## pose que módulos/VFX já consomem. Rig adulterado falha fechado; as peças 2D
## por osso (Fase B) são aceitas no dado, mas não desenhadas.

const E3 := preload("res://sim/esqueleto3d.gd")
const Esq := preload("res://sim/esqueleto.gd")
const Dir := preload("res://sim/direcao.gd")
const Rigs3D := preload("res://jogo/rigs3d.gd")
const Mods := preload("res://sim/modulos.gd")
const Criatura := preload("res://jogo/criatura.gd")
const CAMINHO := "res://dados/rig/canino3d.json"

const BOCA_OCULTA := ["north", "north-east", "north-west"]
const CAUDA_OCULTA := ["south", "south-east", "south-west"]
const PATAS := ["pata_fe", "pata_fd", "pata_te", "pata_td"]


func _rig() -> Dictionary:
	var texto := FileAccess.get_file_as_string(CAMINHO)
	checar(not texto.is_empty(), "rig 3D legível em " + CAMINHO)
	var m := E3.de_json(texto)
	checar(not m.is_empty(), "rig 3D válido (de_json)")
	return m


func _espelho_nome(nome: String) -> String:
	var n := nome
	if n.ends_with("_e"):
		return n.left(n.length() - 2) + "_d"
	if n.ends_with("_d"):
		return n.left(n.length() - 2) + "_e"
	for par in [["fe", "fd"], ["te", "td"]]:
		if n.ends_with(String(par[0])):
			return n.left(n.length() - 2) + String(par[1])
		if n.ends_with(String(par[1])):
			return n.left(n.length() - 2) + String(par[0])
	return n


func _direcao_espelho(dir: String) -> String:
	match dir:
		"east", "west":
			return "west" if dir == "east" else "east"
		"south-east", "south-west":
			return "south-west" if dir == "south-east" else "south-east"
		"north-east", "north-west":
			return "north-west" if dir == "north-east" else "north-east"
	return dir


func test_rig_3d_do_projeto_valida() -> void:
	var m := _rig()
	igual(E3.validar(m), "", "canino3d sem erro")
	igual(E3.direcoes(m).size(), 8, "oito direções")
	igual((m["juntas"] as Dictionary).size(), 22, "22 juntas")
	igual((m["ossos"] as Array).size(), 21, "21 ossos")
	igual((m["pecas"] as Array).size(), 0, "peças 2D desligadas nesta fase")
	perto(float(m["pivot_px"][0]), 34.0, 0.001, "pivô x do chão")
	perto(float(m["pivot_px"][1]), 50.0, 0.001, "pivô y do chão")
	perto(E3.yaw("east"), 0.0, 0.0001, "east = yaw 0")
	perto(E3.pitch(), deg_to_rad(20.0), 0.0001, "pitch low top-down 20°")
	# A convenção do rig 3D é a mesma dos 8 setores de sim/direcao.gd.
	for dir in E3.DIRECOES:
		var i := Dir.indice(dir)
		checar(i >= 0, "direção conhecida em sim/direcao.gd: " + dir)
		perto(E3.yaw(dir), deg_to_rad(float(i) * 45.0), 0.0001, "yaw do setor: " + dir)


func test_rig_3d_adulterado_falha_fechado() -> void:
	var m := _rig()
	var copia := m.duplicate(true)
	copia["schema_version"] = 1
	checar(E3.validar(copia) != "", "schema 1 não vira rig 3D")

	copia = m.duplicate(true)
	copia["juntas"].erase("focinho")
	checar(E3.validar(copia) != "", "21 juntas quebra o contrato")

	copia = m.duplicate(true)
	copia["ossos"][0]["b"] = "fantasma"
	checar(E3.validar(copia) != "", "osso com junta fantasma")

	copia = m.duplicate(true)
	copia["ossos"][0]["largura"] = 0
	checar(E3.validar(copia) != "", "osso sem largura")

	copia = m.duplicate(true)
	copia["sockets"]["boca"]["joint"] = "inexistente"
	checar(E3.validar(copia) != "", "socket apontando junta inexistente")

	copia = m.duplicate(true)
	copia["sockets"]["boca"]["z"] = "meio"
	checar(E3.validar(copia) != "", "z fora de front/back")

	copia = m.duplicate(true)
	copia["sockets"]["boca"]["offset"] = [0, 0]
	checar(E3.validar(copia) != "", "offset sem 3 componentes")

	copia = m.duplicate(true)
	copia["sockets"].erase("coroa")
	checar(E3.validar(copia) != "", "socket obrigatório ausente")

	copia = m.duplicate(true)
	copia["clips"]["walk"]["duracao_s"] = 0
	checar(E3.validar(copia) != "", "clipe sem duração")

	copia = m.duplicate(true)
	copia["clips"].erase("get_up")
	checar(E3.validar(copia) != "", "clipe ausente")

	copia = m.duplicate(true)
	copia["directions"]["south"]["yaw"] = 0
	checar(E3.validar(copia) != "", "yaw diferente do setor")

	copia = m.duplicate(true)
	copia["directions"]["cima"] = {"yaw": 0, "mirror": false, "costas": false}
	checar(E3.validar(copia) != "", "direção desconhecida no rig")

	copia = m.duplicate(true)
	copia["envelope_px"]["altura"] = 0
	checar(E3.validar(copia) != "", "envelope sem altura")

	copia = m.duplicate(true)
	copia["motion"]["passo_px"] = "cinco"
	checar(E3.validar(copia) != "", "motion não numérico")


func test_json_3d_invalido_nao_vira_rig() -> void:
	igual(E3.de_json("{").size(), 0, "json quebrado")
	igual(E3.de_json("[]").size(), 0, "json que não é objeto")
	igual(E3.de_json("{}").size(), 0, "objeto vazio")
	# O rig 2D do canino tem outro schema e NÃO pode ser aceito como 3D.
	var bruto: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://dados/rig/canino.json"))
	checar(bruto is Dictionary and E3.validar(bruto) != "", "rig 2D recusado pelo validador 3D")


func test_pecas_2d_sao_modelo_valido_mas_nao_desenhado() -> void:
	# Fase B: o dado já aceita uma peça plana presa a um osso; nada a desenha.
	var m := _rig()
	var copia := m.duplicate(true)
	copia["pecas"] = [{"osso": 0, "poly": [[0.0, -1.0], [1.0, -1.0], [1.0, 1.0], [0.0, 1.0]],
		"w": 2.0, "fill": "#b98a5a", "outline": "#2b1c12"}]
	igual(E3.validar(copia), "", "peça 2D por osso é modelo válido")
	var p := E3.pose(copia, "east", 0.0, "idle")
	checar(not p.is_empty(), "pose ignora peças sem quebrar")
	checar(not (p["juntas"] as Dictionary).has("peca"), "peça não vira junta")

	copia = m.duplicate(true)
	copia["pecas"] = [{"osso": 99, "poly": [[0, 0], [1, 0], [1, 1]], "w": 1.0,
		"fill": "#ffffff", "outline": "#000000"}]
	checar(E3.validar(copia) != "", "peça com osso fora")

	copia = m.duplicate(true)
	copia["pecas"] = [{"osso": 0, "poly": [[0, 0], [1, 0]], "w": 1.0,
		"fill": "#ffffff", "outline": "#000000"}]
	checar(E3.validar(copia) != "", "peça com poly de menos de 3 pontos")

	copia = m.duplicate(true)
	copia["pecas"] = [{"osso": 0, "poly": [[0, 0], [1, 0], [1, 1]], "w": 1.0,
		"fill": "verde", "outline": "#000000"}]
	checar(E3.validar(copia) != "", "peça com cor inválida")


func test_pose_nao_vazia_nos_oito_yaws_e_clipes() -> void:
	var m := _rig()
	for dir in E3.DIRECOES:
		for clipe in E3.CLIPES:
			for fase in [0.0, 0.17, 0.42, 0.73, 1.0]:
				var p := E3.pose(m, dir, fase, clipe)
				checar(not p.is_empty(), "pose %s/%s/%.2f" % [dir, clipe, fase])
				if p.is_empty():
					continue
				var j: Dictionary = p["juntas"]
				var j3: Dictionary = p["juntas_3d"]
				igual(j.size(), 22, "22 juntas projetadas %s/%s" % [dir, clipe])
				igual(j3.size(), 22, "22 juntas 3D %s/%s" % [dir, clipe])
				igual((p["sockets"] as Dictionary).size(), 4, "4 sockets %s/%s" % [dir, clipe])
				for nome in j:
					checar((j[nome] as Vector2).is_finite(), "ponto 2D finito %s/%s/%s" % [dir, clipe, nome])
					checar((j3[nome] as Vector3).is_finite(), "ponto 3D finito %s/%s/%s" % [dir, clipe, nome])


func test_pata_no_chao_do_mundo_e_projecao() -> void:
	var m := _rig()
	var pitch_rad := E3.pitch()
	for dir in E3.DIRECOES:
		var yaw_rad := E3.yaw(dir)
		var p := E3.pose(m, dir, 0.0, "idle")
		checar(not p.is_empty(), "pose idle: " + dir)
		var j2: Dictionary = p["juntas"]
		var j3: Dictionary = p["juntas_3d"]
		for k in PATAS:
			perto((j3[k] as Vector3).y, 0.0, 0.000001, "pata no chão do MUNDO %s/%s" % [dir, k])
		# A projeção usada pela pose é exatamente a função pública.
		for nome in j3:
			var pr := E3.projetar(j3[nome], yaw_rad, pitch_rad)
			perto_v(E3.para_canvas(pr, m), j2[nome], 0.000001,
				"projeção coerente %s/%s" % [dir, nome])


func test_marcha_tem_apoio_no_chao() -> void:
	# No passo de 4 tempos, a cada quarto do ciclo UMA pata sai do chão e as
	# outras três ficam plantadas no plano y=0 do mundo.
	var m := _rig()
	var esperadas := {0.25: "pata_td", 0.5: "pata_fd", 0.75: "pata_te", 1.0: "pata_fe"}
	for dir in E3.DIRECOES:
		for fase in esperadas:
			var p := E3.pose(m, dir, float(fase), "walk")
			var j3: Dictionary = p["juntas_3d"]
			for k in PATAS:
				var y := (j3[k] as Vector3).y
				if k == String(esperadas[fase]):
					checar(y > 0.5, "%s levanta na fase %.2f (%s)" % [k, fase, dir])
				else:
					perto(y, 0.0, 0.000001, "%s plantada na fase %.2f (%s)" % [k, fase, dir])


func test_espelho_yaw_180_e_pares() -> void:
	var m := _rig()
	# Leste/oeste é o par yaw 0 / yaw 180: a silhueta é a mesma com x trocado.
	var leste: Dictionary = E3.pose(m, "east", 0.0, "idle")["juntas"]
	var oeste: Dictionary = E3.pose(m, "west", 0.0, "idle")["juntas"]
	for nome in leste:
		var esp := _espelho_nome(nome)
		perto((leste[nome] as Vector2).x + (oeste[esp] as Vector2).x, 68.0, 0.001,
			"espelho yaw 0/180 em x: " + nome)
		perto((leste[nome] as Vector2).y, (oeste[esp] as Vector2).y, 0.001,
			"espelho yaw 0/180 em y: " + nome)
	# Os demais pares espelhados do contrato de 8 setores (o eixo de simetria
	# da câmera é o do plano sagital, não o yaw+180 de uma diagonal).
	for dir in ["south-east", "north-east", "south", "north"]:
		var outro := _direcao_espelho(dir)
		var a: Dictionary = E3.pose(m, dir, 0.0, "idle")["juntas"]
		var b: Dictionary = E3.pose(m, outro, 0.0, "idle")["juntas"]
		for nome in a:
			var esp := _espelho_nome(nome)
			perto((a[nome] as Vector2).x + (b[esp] as Vector2).x, 68.0, 0.001,
				"par %s/%s em x: %s" % [dir, outro, nome])
			perto((a[nome] as Vector2).y, (b[esp] as Vector2).y, 0.001,
				"par %s/%s em y: %s" % [dir, outro, nome])


func test_sockets_por_direcao() -> void:
	var m := _rig()
	for dir in E3.DIRECOES:
		var p := E3.pose(m, dir, 0.0, "idle")
		var socks: Dictionary = p["sockets"]
		checar(socks.has("boca") and socks.has("coroa") and socks.has("base_cauda") and socks.has("dorso"),
			"os quatro sockets existem: " + dir)
		igual(bool(socks["boca"]["visivel"]), not (dir in BOCA_OCULTA), "boca esconde no norte: " + dir)
		igual(bool(socks["base_cauda"]["visivel"]), not (dir in CAUDA_OCULTA), "cauda esconde no sul: " + dir)
		checar(bool(socks["coroa"]["visivel"]), "coroa sempre existe: " + dir)
		checar(bool(socks["dorso"]["visivel"]), "dorso sempre existe: " + dir)
		for nome in socks:
			if not bool(socks[nome]["visivel"]):
				continue
			var q: Vector2 = socks[nome]["pos"]
			checar(q.x >= 0.0 and q.x <= 68.0 and q.y >= 0.0 and q.y <= 68.0,
				"socket dentro do canvas %s/%s" % [dir, nome])
		var j: Dictionary = p["juntas"]
		if bool(socks["boca"]["visivel"]):
			checar((socks["boca"]["pos"] as Vector2).distance_to(j["focinho"]) < 1.0,
				"boca colada no focinho: " + dir)
		# Coroa acima da cabeça na projeção (offset +y do mundo).
		checar((socks["coroa"]["pos"] as Vector2).y < (j["cabeca"] as Vector2).y,
			"coroa acima da cabeça: " + dir)


func test_bite_e_slam_apontam_para_o_setor() -> void:
	var m := _rig()
	var sinp := sin(E3.pitch())
	for dir in E3.DIRECOES:
		var yaw_rad := E3.yaw(dir)
		# +z do mundo na tela: (cos yaw, sin yaw · sin pitch).
		var frente := Vector2(cos(yaw_rad), sin(yaw_rad) * sinp)
		var base: Vector2 = (E3.pose(m, dir, 0.5, "idle")["juntas"] as Dictionary)["cabeca"]
		for clipe in ["bite", "slam"]:
			var cabeca: Vector2 = (E3.pose(m, dir, 0.5, clipe)["juntas"] as Dictionary)["cabeca"]
			var d := cabeca - base
			checar(d.dot(frente) > 0.4, "%s avança no setor %s (d=%s)" % [clipe, dir, d])
		# O caso explícito do briefing: norte avança para CIMA na tela.
		if dir == "north":
			for clipe in ["bite", "slam"]:
				var c: Vector2 = (E3.pose(m, dir, 0.5, clipe)["juntas"] as Dictionary)["cabeca"]
				checar(c.y < base.y, clipe + " norte para cima")


func test_ordem_de_profundidade_deterministica() -> void:
	var m := _rig()
	for dir in ["east", "south-east", "north"]:
		var p := E3.pose(m, dir, 0.42, "run")
		var a := E3.ordem_pintor(m, p)
		var b := E3.ordem_pintor(m, p)
		igual(a.size(), 43, "21 ossos + 22 juntas no pintor: " + dir)
		igual(a.size(), b.size(), "mesmo tamanho de ordem: " + dir)
		for i in a.size():
			igual(String(a[i]["id"]), String(b[i]["id"]), "ordem estável %s/%d" % [dir, i])
		for i in range(1, a.size()):
			checar(float(a[i]["profundidade"]) <= float(a[i - 1]["profundidade"]) + 0.000001,
				"longe→perto %s/%d" % [dir, i])
		# Todo item pertence ao rig; nada inventado.
		for item in a:
			checar(String(item["tipo"]) in ["osso", "junta"], "tipo de item do pintor")
			if String(item["tipo"]) == "osso":
				checar((p["juntas"] as Dictionary).has(item["a"]) and (p["juntas"] as Dictionary).has(item["b"]),
					"osso do pintor tem as duas juntas")


func test_adaptador_resolve_modulos() -> void:
	var m := _rig()
	var cat := Mods.de_json(FileAccess.get_file_as_string("res://dados/modulos.json"))
	checar(not cat.is_empty(), "catálogo de módulos válido")
	var p := E3.pose(m, "east", 0.0, "idle")
	var adapt := E3.adaptar_modulos(m, p, "east")
	checar(not (adapt["rig"] as Dictionary).is_empty(), "adaptador devolve rig")
	checar(not (adapt["pose"] as Dictionary).is_empty(), "adaptador devolve pose")
	var pose_mod: Dictionary = adapt["pose"]
	checar((pose_mod["juntas"] as Dictionary).size() > 22, "pose adaptada tem as juntas sintéticas dos sockets")
	checar((pose_mod["sockets"] as Dictionary).size() == 4, "pose adaptada preserva sockets resolvidos")
	var rig_mod: Dictionary = adapt["rig"]
	var tufo := Mods.resolver(cat, "tufo", rig_mod, pose_mod, "east")
	checar(not tufo.is_empty(), "módulo tufo resolve no socket coroa")
	checar((tufo["pos"] as Vector2).distance_to(((p["sockets"] as Dictionary)["coroa"]["pos"] as Vector2)) < 0.001,
		"posição do módulo = posição do socket")
	var espinho := Mods.resolver(cat, "espinho_cauda", rig_mod, pose_mod, "east")
	checar(not espinho.is_empty(), "módulo espinho resolve no socket base_cauda")
	# `dorso` é reservado a VFX: módulo não pode virar asa por ele.
	var asa := Mods.resolver(cat, "asa_membrana", rig_mod, pose_mod, "east")
	checar(asa.is_empty(), "dorso vfx não concede asa")
	var norte := E3.pose(m, "north", 0.0, "idle")
	var adapt_n := E3.adaptar_modulos(m, norte, "north")
	var tufo_n := Mods.resolver(cat, "tufo", adapt_n["rig"], adapt_n["pose"], "north")
	checar(not tufo_n.is_empty(), "coroa resolve no norte")


func test_canino_usa_o_skin_3d() -> void:
	checar(not Rigs3D.carregar("canino3d").is_empty(), "loader 3D carrega o canino3d")
	igual(Rigs3D.carregar("inexistente").size(), 0, "rig 3D ausente devolve vazio")
	igual(Rigs3D.carregar("../canino3d").size(), 0, "traversal não carrega no 3D")
	var c := Criatura.new()
	c._ready()
	checar(c.esqueleto3d_ativo(), "canino nasce no esqueleto 3D")
	checar(c.pele_geometrica_ativa(), "pele ativa com o rig 3D")
	var p := E3.pose(c._rig3d, "south", 0.0, "idle")
	checar(not p.is_empty(), "criatura entrega pose 3D")
	# Troca explícita para o 2D (debug/fallback) e volta.
	checar(c.ativar_pele_geometrica("canino"), "rig 2D ainda carrega")
	checar(not c.esqueleto3d_ativo(), "2D desliga o esqueleto 3D")
	checar(c.ativar_esqueleto3d("canino3d"), "volta ao esqueleto 3D")
	checar(c.esqueleto3d_ativo(), "3D religado")
	c.free()


func test_silhueta_cabe_no_canvas_68() -> void:
	var m := _rig()
	for dir in E3.DIRECOES:
		for clipe in E3.CLIPES:
			for fase in [0.0, 0.17, 0.42, 0.73, 1.0]:
				var p := E3.pose(m, dir, fase, clipe)
				for nome in p["juntas"]:
					var q: Vector2 = p["juntas"][nome]
					# Margem de meio pixel para o traço de 2 px não encostar na borda.
					checar(q.x >= 0.5 and q.x <= 67.5 and q.y >= 0.5 and q.y <= 67.5,
						"silhueta dentro de 68×68: %s/%s/%.2f/%s = %s" % [dir, clipe, fase, nome, q])
