extends "res://testes/caso.gd"
## Contrato do esqueleto 3D do canino (Fase A): 24 juntas / 23 ossos em 3D,
## projeção ortográfica com pitch 20°, oito yaws, socket por nome e a mesma
## pose que módulos/VFX já consomem. Rig adulterado falha fechado; as peças 2D
## por osso (Fase B) são aceitas no dado, mas não desenhadas.

const E3 := preload("res://sim/esqueleto3d.gd")
const Esq := preload("res://sim/esqueleto.gd")
const Dir := preload("res://sim/direcao.gd")
const Rigs3D := preload("res://jogo/rigs3d.gd")
const Mods := preload("res://sim/modulos.gd")
const Corpo := preload("res://sim/corpo.gd")
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


## Alvo EFETIVO da pata: o da marcha passado pelo LIMITE DE COMPRESSÃO
## (`E3._alvo_compressao`). Em APOIO devolve o próprio alvo — o clamp é regra
## de BALANÇO —, então o contato continua exatamente onde o dado manda.
func _alvo_efetivo(perna: Dictionary, P: Vector3, alvo: Vector3) -> Vector3:
	return E3._alvo_compressao(P, alvo, alvo.y > 0.0, E3._dmin_perna(perna))


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


func _j3(p: Dictionary, nome: String) -> Vector3:
	return p["juntas_3d"][nome]


## Inclinação do tronco (quadril→peito) em graus, com sinal de nariz para
## baixo positivo. É a leitura usada no teste do galope.
func _pitch_corpo(p: Dictionary) -> float:
	var a := _j3(p, "quadril")
	var b := _j3(p, "peito")
	return -rad_to_deg(atan2(b.y - a.y, b.z - a.z))


func test_rig_3d_do_projeto_valida() -> void:
	var m := _rig()
	igual(E3.validar(m), "", "canino3d sem erro")
	igual(E3.direcoes(m).size(), 8, "oito direções")
	igual((m["juntas"] as Dictionary).size(), 24, "24 juntas")
	igual((m["ossos"] as Array).size(), 23, "23 ossos")
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
	copia["schema_version"] = 2
	checar(E3.validar(copia) != "" and E3.de_json(JSON.stringify(copia)).is_empty(),
		"schema anterior 2 recusado sem adaptação silenciosa")
	igual(int(m["schema_version"]), 3, "topologia traseira define schema 3")

	for nome in ["anca_e", "joelho_te", "jarrete_te", "pata_te",
		"anca_d", "joelho_td", "jarrete_td", "pata_td"]:
		copia = m.duplicate(true)
		copia["juntas"].erase(nome)
		copia["juntas"]["fantasma"] = [0, 0, 0]
		checar(E3.validar(copia) != "", "junta traseira obrigatória %s" % nome)

	copia = m.duplicate(true)
	copia["ossos"][18]["b"] = "pata_te"
	checar(E3.validar(copia) != "", "cadeia traseira não pode saltar o jarrete")

	copia = m.duplicate(true)
	copia["juntas"].erase("focinho")
	checar(E3.validar(copia) != "", "23 juntas quebra o contrato")

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
				igual(j.size(), 24, "24 juntas projetadas %s/%s" % [dir, clipe])
				igual(j3.size(), 24, "24 juntas 3D %s/%s" % [dir, clipe])
				igual((p["sockets"] as Dictionary).size(), 4, "4 sockets %s/%s" % [dir, clipe])
				for nome in j:
					checar((j[nome] as Vector2).is_finite(), "ponto 2D finito %s/%s/%s" % [dir, clipe, nome])
					checar((j3[nome] as Vector3).is_finite(), "ponto 3D finito %s/%s/%s" % [dir, clipe, nome])


## Dobra anatômica no plano y–z (z cresce para a frente): dianteiras
## para trás, traseiras para a frente. O sinal usa a reta ombro/anca→pata,
## sem exigir que uma junta fique sempre atrás/à frente do quadril em corrida.
func test_dobra_anatomica_em_repouso_idle_walk_run() -> void:
	var m := _rig()
	var rest: Dictionary = m["juntas"]
	checar(float(rest["joelho_fe"][2]) < float(rest["ombro_e"][2]), "cotovelo dianteiro atrás do ombro em repouso")
	checar(float(rest["joelho_fd"][2]) < float(rest["ombro_d"][2]), "outro cotovelo atrás do ombro")
	checar(float(rest["joelho_te"][2]) > float(rest["anca_e"][2]), "joelho traseiro à frente da anca em repouso")
	checar(float(rest["joelho_td"][2]) > float(rest["anca_d"][2]), "outro joelho à frente da anca")
	for lado in ["te", "td"]:
		var K := E3._vec(rest["joelho_" + lado])
		var H := E3._vec(rest["jarrete_" + lado])
		var F := E3._vec(rest["pata_" + lado])
		checar(H.z < K.z and H.z < F.z and H.y > 0.0,
			"zigzag traseiro no repouso: jarrete atrás e alto " + lado)
		# Lote 3C: o metatarso passou de 6,73 para 7,60 px e a tíbia de 9,84
		# para 8,97 (tíbia/metatarso 1,18, medido na prancha do galope) — a
		# soma traseira fica igual, o jarrete sobe 1,3 px.
		perto(H.distance_to(F), 7.6, 0.001, "metatarso longo " + lado)
	for clipe in ["idle", "walk", "run"]:
		for i in 40:
			var fase := float(i) / 40.0
			var p := E3.pose(m, "east", fase, clipe)
			for par in [["ombro_e", "fe", -1.0], ["ombro_d", "fd", -1.0],
				["anca_e", "te", 1.0], ["anca_d", "td", 1.0]]:
				var P := _j3(p, String(par[0]))
				var K := _j3(p, "joelho_" + String(par[1]))
				var fim := "pata_" if String(par[1]).begins_with("f") else "jarrete_"
				var F := _j3(p, fim + String(par[1]))
				var cruz := (F.z - P.z) * (K.y - P.y) - (F.y - P.y) * (K.z - P.z)
				checar(cruz * float(par[2]) >= -0.001,
					"dobra %s/%s/%.3f: %.3f" % [clipe, par[1], fase, cruz])


func test_ik_preserva_ossos_e_alvos_alcancaveis_em_3d() -> void:
	var m := _rig()
	var rest: Dictionary = m["juntas"]
	for clipe in ["idle", "walk", "run"]:
		for i in 40:
			var fase := float(i) / 40.0
			var p := E3.pose(m, "east", fase, clipe)
			var pernas := E3._pernas(m)
			var alvos := E3._patas(pernas, clipe, fase, m["motion"])
			for perna in pernas:
				var nome := String(perna["nome"])
				var P := _j3(p, String(perna["upper"]))
				var K := _j3(p, "joelho_" + nome)
				var F := _j3(p, "pata_" + nome)
				var alvo: Vector3 = _alvo_efetivo(perna, P, alvos[nome])
				var l1 := float(perna["l1"])
				var l2 := float(perna["l2"])
				perto(P.distance_to(K), l1, 0.001, "osso superior %s/%s/%.3f" % [clipe, nome, fase])
				if perna.has("l3"):
					var H := _j3(p, "jarrete_" + nome)
					perto(K.distance_to(H), l2, 0.001, "tíbia rígida %s/%s/%.3f" % [clipe, nome, fase])
					perto(H.distance_to(F), float(perna["l3"]), 0.001,
						"metatarso rígido %s/%s/%.3f" % [clipe, nome, fase])
					checar(H.z < K.z + 0.5 and H.y > -1.0,
						"jarrete não inverte grosseiramente %s/%s/%.3f" % [clipe, nome, fase])
					var esperado := E3._jarrete_alcancavel(P, alvo, l1, l2,
						float(perna["l3"]), perna["offset_jarr"])
					if P.distance_to(esperado) <= l1 + l2 + 0.0001 and P.distance_to(esperado) >= absf(l1 - l2) - 0.0001:
						checar(F.distance_to(alvo) < 0.001,
							"contato alcançável preservado %s/%s/%.3f (%.4f)" % [clipe, nome, fase, F.distance_to(alvo)])
				else:
					var antigo := E3._ik(P, alvo, l1, l2, E3._sentido_polo(perna, false))
					checar(K.distance_to(antigo["joelho"]) < 0.00001 and
						F.distance_to(antigo["pata"]) < 0.00001,
						"dianteira usa a mesma IK %s/%s/%.3f" % [clipe, nome, fase])
					perto(K.distance_to(F), l2, 0.001, "dianteiro inferior %s/%s/%.3f" % [clipe, nome, fase])
					checar(K.x >= minf(P.x, F.x) - 0.001 and K.x <= maxf(P.x, F.x) + 0.001,
						"x do joelho dianteiro %s/%s/%.3f" % [clipe, nome, fase])
					if P.distance_to(alvo) >= absf(l1 - l2) + 0.001 and P.distance_to(alvo) <= l1 + l2 - 0.001:
						checar(F.distance_to(alvo) < 0.0001, "dianteira no alvo %s/%s/%.3f" % [clipe, nome, fase])
	# Repouso conserva os dois ossos dianteiros e os três traseiros.
	for perna in E3._pernas(m):
		var nome := String(perna["nome"])
		var P := E3._vec(rest[perna["upper"]])
		var K := E3._vec(rest["joelho_" + nome])
		var F := E3._vec(rest["pata_" + nome])
		# Lote 3C: repartição de referência (úmero:antebraço+metacarpo =
		# 0,393:0,607; tíbia:metatarso = 1:1,18) com a SOMA de cada perna
		# mantida — é a soma que a passada 13,8/17,0 exige.
		perto(P.distance_to(K), 8.253 if nome.begins_with("f") else 11.0, 0.001,
			"comprimento superior original " + nome)
		if perna.has("l3"):
			var H := E3._vec(rest["jarrete_" + nome])
			perto(K.distance_to(H), 8.97000, 0.001, "tíbia original " + nome)
			perto(H.distance_to(F), 7.6, 0.001, "metatarso original " + nome)
		else:
			perto(K.distance_to(F), 12.747, 0.001, "antebraço original " + nome)


func test_jarrete_todos_os_yaws_clipes_e_saltos_sem_stretch() -> void:
	var m := _rig()
	var pernas := E3._pernas(m)
	for dir in E3.DIRECOES:
		for clipe in E3.CLIPES:
			for i in 20:
				var f := float(i) / 20.0
				for correndo in [false, true]:
					if correndo and clipe not in ["jump_air", "jump_land", "jump_start"]:
						continue
					var p := E3.pose(m, dir, f, clipe, correndo)
					var alvos := E3._patas(pernas, clipe, f, m["motion"], correndo)
					for perna in pernas:
						if not perna.has("l3"):
							continue
						var nome := String(perna["nome"])
						var P := _j3(p, String(perna["upper"]))
						var K := _j3(p, "joelho_" + nome)
						var H := _j3(p, "jarrete_" + nome)
						var F := _j3(p, "pata_" + nome)
						var tag := "%s/%s/%.2f/%s" % [dir, clipe, f, nome]
						checar(H.is_finite() and F.is_finite(), "jarrete e pata finitos " + tag)
						if clipe in ["death", "get_up"]:
							# _deitar deforma TODAS as juntas por design anterior, inclusive os ossos.
							continue
						perto(P.distance_to(K), float(perna["l1"]), 0.002, "fêmur " + tag)
						perto(K.distance_to(H), float(perna["l2"]), 0.002, "tíbia " + tag)
						perto(H.distance_to(F), float(perna["l3"]), 0.002, "metatarso " + tag)
						var alvo: Vector3 = _alvo_efetivo(perna, P, alvos[nome])
						var H0 := E3._jarrete_alcancavel(P, alvo, float(perna["l1"]),
							float(perna["l2"]), float(perna["l3"]), perna["offset_jarr"])
						if P.distance_to(H0) <= float(perna["l1"]) + float(perna["l2"]) + 0.0001 and P.distance_to(H0) >= absf(float(perna["l1"]) - float(perna["l2"])) - 0.0001:
							checar(F.distance_to(alvo) < 0.002, "contato de pata alcançável " + tag)
							if clipe in ["idle", "walk", "run"] and alvo.y == 0.0:
								perto(F.y, 0.0, 0.002, "chão do mundo " + tag)


func test_jarrete_extremo_corrige_contato_sem_teleporte_ou_stretch() -> void:
	var m := _rig()
	var perna: Dictionary = E3._pernas(m)[2]
	var P := E3._vec(m["juntas"]["anca_e"])
	var l1 := float(perna["l1"])
	var l2 := float(perna["l2"])
	var l3 := float(perna["l3"])
	var F := E3._vec(m["juntas"]["pata_te"])
	var anterior := F
	for passo in 25:
		var alvo := F + Vector3(0, -float(passo) * 2.0, 0)
		var H := E3._jarrete_alcancavel(P, alvo, l1, l2, l3, perna["offset_jarr"])
		var sol := E3._ik(P, H, l1, l2, 1.0)
		var K: Vector3 = sol["joelho"]
		var jarrete: Vector3 = sol["pata"]
		var pata := jarrete + (alvo - H).normalized() * l3
		checar(K.is_finite() and jarrete.is_finite() and pata.is_finite(), "extremo finito %d" % passo)
		perto(P.distance_to(K), l1, 0.002, "fêmur extremo %d" % passo)
		perto(K.distance_to(jarrete), l2, 0.002, "tíbia extremo %d" % passo)
		perto(jarrete.distance_to(pata), l3, 0.002, "metatarso extremo %d" % passo)
		checar(pata.distance_to(anterior) < 3.0, "extremo sem teleporte %d" % passo)
		anterior = pata
	checar(anterior.distance_to(F + Vector3(0, -48, 0)) > 10.0,
		"alvo impossível corrige contato em vez de esticar ossos")


## Ramo angular: o offset rígido põe o jarrete em cima do quadril (fora do
## alcance), mas a pata continua alcançável. O solver precisa girar o jarrete
## pelo círculo do metatarso e preservar a pata — sem repetir a própria função.
func test_jarrete_ramo_angular_gira_circulo_e_preserva_pata() -> void:
	var m := _rig()
	var perna: Dictionary = E3._pernas(m)[2]
	var P := E3._vec(m["juntas"]["anca_e"])
	var l1 := float(perna["l1"])
	var l2 := float(perna["l2"])
	var l3 := float(perna["l3"])
	var offset: Vector3 = perna["offset_jarr"]
	var F: Vector3 = P - offset
	var H := E3._jarrete_alcancavel(P, F, l1, l2, l3, offset)
	checar(H.distance_to(P) > 0.1, "jarrete não fica em cima do quadril")
	perto(H.distance_to(F), l3, 0.001, "jarrete continua no círculo do metatarso")
	var d := P.distance_to(H)
	checar(d >= absf(l1 - l2) - 0.001 and d <= l1 + l2 + 0.001,
		"jarrete girado entra no alcance (%.3f)" % d)
	var sol := E3._ik(P, H, l1, l2, 1.0)
	var jarrete: Vector3 = sol["pata"]
	var pata := jarrete + (F - H).normalized() * l3
	checar(pata.distance_to(F) < 0.001, "pata preservada no ramo angular")


func test_ik_alvos_impossiveis_zero_e_deslocamento_lateral() -> void:
	var P := Vector3(0.4, 18.0, 7.0)
	var casos := [Vector3(1.0, 0.0, 9.5), Vector3(0.4, -100.0, 7.0),
		P, P + Vector3(0.0, 0.0, 0.01), P + Vector3(25.0, 0.0, 0.0)]
	for F in casos:
		var solucao := E3._ik(P, F, 10.5, 10.5, -1.0)
		var K: Vector3 = solucao["joelho"]
		var pata: Vector3 = solucao["pata"]
		checar(K.is_finite() and pata.is_finite(), "IK finita para alvo %s" % F)
		perto(P.distance_to(K), 10.5, 0.001, "l1 não alonga %s" % F)
		perto(K.distance_to(pata), 10.5, 0.001, "l2 não alonga %s" % F)
		if P.distance_to(F) > 0.001 and P.distance_to(F) <= 21.0:
			checar(pata.distance_to(F) < 0.0001, "alvo no alcance preservado %s" % F)
		elif P.distance_to(F) > 21.0:
			perto(P.distance_to(pata), 21.0, 0.001, "alvo distante limitado ao alcance %s" % F)
	# Quando l1 != l2, alvo na origem deve parar no raio mínimo, sem NaN.
	var curto := E3._ik(P, P, 11.0, 8.0, 1.0)
	perto(P.distance_to(curto["pata"]), 3.0, 0.001, "alvo zero respeita raio mínimo")
	perto(P.distance_to(curto["joelho"]), 11.0, 0.001, "raio mínimo sem osso elástico")
	perto((curto["joelho"] as Vector3).distance_to(curto["pata"]), 8.0, 0.001, "segundo osso rígido")


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
		igual(a.size(), 47, "23 ossos + 24 juntas no pintor: " + dir)
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


func test_canino_carrega_o_rig_3d() -> void:
	checar(not Rigs3D.carregar("canino3d").is_empty(), "loader 3D carrega o canino3d")
	igual(Rigs3D.carregar("inexistente").size(), 0, "rig 3D ausente devolve vazio")
	igual(Rigs3D.carregar("../canino3d").size(), 0, "traversal não carrega no 3D")
	# P24: a criatura 2D (`jogo/criatura.gd`) saiu do jogo; o rig 3D carregado
	# ainda entrega pose (o rig fica, congelado).
	var p := E3.pose(Rigs3D.carregar("canino3d"), "south", 0.0, "idle")
	checar(not p.is_empty(), "rig 3D entrega pose")


func test_pose_aceita_yaw_continuo() -> void:
	var m := _rig()
	for y in [22.5, 200.0, -30.0, 405.0]:
		var p := E3.pose(m, "east", 0.3, "walk", false, float(y))
		checar(not p.is_empty(), "pose com yaw contínuo %.1f" % y)
		perto(rad_to_deg(float(p["yaw"])), fposmod(float(y), 360.0), 0.0001,
			"yaw devolvido normalizado %.1f" % y)
		for nome in p["juntas"]:
			checar((p["juntas"][nome] as Vector2).is_finite(), "junta finita yaw %.1f/%s" % [y, nome])
	# O contínuo NÃO usa o yaw do setor: 22,5° difere do padrão 0° (east).
	var a := E3.pose(m, "east", 0.3, "walk", false, 22.5)
	var b := E3.pose(m, "east", 0.3, "walk")
	var mexeu := 0.0
	for nome in a["juntas"]:
		mexeu = maxf(mexeu, (a["juntas"][nome] as Vector2).distance_to(b["juntas"][nome]))
	checar(mexeu > 0.5, "22,5° move a projeção em relação a east (%.3f px)" % mexeu)


func test_continuidade_do_giro() -> void:
	var m := _rig()
	var base := E3.pose(m, "south-east", 0.42, "walk", false, 0.0)
	for y in [1.0, 2.0]:
		var p := E3.pose(m, "south-east", 0.42, "walk", false, float(y))
		var maxd := 0.0
		for nome in base["juntas"]:
			maxd = maxf(maxd, (p["juntas"][nome] as Vector2).distance_to(base["juntas"][nome]))
		checar(maxd < 1.0, "1° de giro desloca menos de 1 px (veio %.3f)" % maxd)
		base = p
	# Fronteiras reais de `Dir.setor` (22,5° e 67,5°): o setor muda, mas a
	# projeção contínua não pode dar salto.
	for par in [[22.0, 22.4, 22.6, 23.0], [67.0, 67.4, 67.6, 68.0]]:
		var anterior: Dictionary = {}
		for y in par:
			var dir := Dir.setor(Vector2.from_angle(deg_to_rad(float(y))))
			var p2 := E3.pose(m, dir, 0.42, "walk", false, float(y))
			if not anterior.is_empty():
				var maxd2 := 0.0
				for nome in p2["juntas"]:
					maxd2 = maxf(maxd2, (p2["juntas"][nome] as Vector2).distance_to(anterior[nome]))
				checar(maxd2 < 1.0, "fronteira de setor %.1f° sem salto (%.3f px)" % [y, maxd2])
			anterior = p2["juntas"]
	# 359° → 0° fecha o círculo.
	var fim := E3.pose(m, "south-east", 0.42, "walk", false, 359.0)
	var inicio := E3.pose(m, "south-east", 0.42, "walk", false, 0.0)
	var maxw := 0.0
	for nome in fim["juntas"]:
		maxw = maxf(maxw, (fim["juntas"][nome] as Vector2).distance_to(inicio["juntas"][nome]))
	checar(maxw < 1.0, "359→0 sem salto (%.3f px)" % maxw)


func test_espelho_yaw_180_continuo() -> void:
	var m := _rig()
	for y in [22.5, 200.0]:
		var a := E3.pose(m, "east", 0.25, "walk", false, float(y))
		var b := E3.pose(m, "east", 0.25, "walk", false, float(y) + 180.0)
		var mina := INF
		var maxa := -INF
		var minb := INF
		var maxb := -INF
		for nome in a["juntas"]:
			var qa: Vector2 = a["juntas"][nome]
			var qb: Vector2 = b["juntas"][nome]
			perto(qa.x + qb.x, 68.0, 0.0001, "yaw+180 inverte x em %s" % nome)
			mina = minf(mina, qa.x)
			maxa = maxf(maxa, qa.x)
			minb = minf(minb, qb.x)
			maxb = maxf(maxb, qb.x)
		perto(minb, 68.0 - maxa, 0.0001, "bbox x espelhada (min) %.1f" % y)
		perto(maxb, 68.0 - mina, 0.0001, "bbox x espelhada (max) %.1f" % y)
		# No idle as quatro patas estão em y=0: nelas a profundidade z também
		# inverte. (No walk uma pata pode estar no ar, com y>0.)
		var ia := E3.pose(m, "east", 0.0, "idle", false, float(y))
		var ib := E3.pose(m, "east", 0.0, "idle", false, float(y) + 180.0)
		for k in PATAS:
			perto(float(ia["profundidade"][k]) + float(ib["profundidade"][k]), 0.0, 0.000001,
				"yaw+180 inverte a profundidade da pata %s (%.1f)" % [k, y])
	# y=0: a profundidade horizontal também inverte (x e z do plano do chão).
	var va := E3.projetar(Vector3(3.0, 0.0, -5.0), deg_to_rad(22.5), E3.pitch())
	var vb := E3.projetar(Vector3(3.0, 0.0, -5.0), deg_to_rad(202.5), E3.pitch())
	perto(va.x + vb.x, 0.0, 0.000001, "projeção x inverte")
	perto(va.z + vb.z, 0.0, 0.000001, "profundidade z inverte no chão")


func test_setor_e_angulo_coincidem_nos_oito_yaws() -> void:
	var m := _rig()
	for dir in E3.DIRECOES:
		var padrao := E3.pose(m, dir, 0.33, "run")
		var explicito := E3.pose(m, dir, 0.33, "run", false, E3.yaw_graus(dir))
		perto(float(explicito["yaw"]), float(padrao["yaw"]), 0.000001, "yaw rad: " + dir)
		for nome in padrao["juntas"]:
			perto_v(explicito["juntas"][nome], padrao["juntas"][nome], 0.000001,
				"junta igual ao padrão: %s/%s" % [dir, nome])
		for nome in padrao["sockets"]:
			perto_v(explicito["sockets"][nome]["pos"], padrao["sockets"][nome]["pos"], 0.000001,
				"socket igual ao padrão: %s/%s" % [dir, nome])


func test_sockets_seguem_o_setor_com_yaw_continuo() -> void:
	var m := _rig()
	# A direção continua decidindo oculto_em, mesmo com uma câmera de 200°.
	var norte := E3.pose(m, "north", 0.0, "idle", false, 200.0)
	checar(not bool((norte["sockets"]["boca"] as Dictionary)["visivel"]), "boca some em north (yaw 200)")
	checar(bool((norte["sockets"]["base_cauda"] as Dictionary)["visivel"]), "cauda existe em north (yaw 200)")
	var sul := E3.pose(m, "south", 0.0, "idle", false, 200.0)
	checar(bool((sul["sockets"]["boca"] as Dictionary)["visivel"]), "boca existe em south (yaw 200)")
	checar(not bool((sul["sockets"]["base_cauda"] as Dictionary)["visivel"]), "cauda some em south (yaw 200)")
	# A posição do socket, porém, acompanha o yaw contínuo.
	var setor := E3.pose(m, "north", 0.0, "idle")
	var d := ((norte["sockets"]["coroa"] as Dictionary)["pos"] as Vector2).distance_to(
		(setor["sockets"]["coroa"] as Dictionary)["pos"] as Vector2)
	checar(d > 1.0, "socket se move com o yaw contínuo (%.2f px)" % d)


func _dif_ang(a: float, b: float) -> float:
	return absf(wrapf(a - b, -180.0, 180.0))


func test_idle_relaxado() -> void:
	var m := _rig()
	perto(float(m["clips"]["idle"]["duracao_s"]), 2.4, 0.001, "idle de 2,4 s")
	perto(float(m["motion"]["respira_px"]), 0.5, 0.001, "respiração 0,5 px")
	perto(float(m["motion"]["idle_peso_lateral_px"]), 0.8, 0.001, "peso lateral ±0,8")
	perto(float(m["motion"]["idle_cabeca_graus"]), 4.0, 0.001, "cabeça ±4°")
	var lxmin := 1e9
	var lxmax := -1e9
	var fxmin := 1e9
	var fxmax := -1e9
	var tmin := 1e9
	var tmax := -1e9
	for i in 41:
		var f := float(i) / 40.0
		var p := E3.pose(m, "east", f, "idle")
		checar(not p.is_empty(), "idle pose f=%.2f" % f)
		for k in PATAS:
			perto(_j3(p, k).y, 0.0, 0.000001, "idle pata plantada f=%.2f/%s" % [f, k])
		var lombo := _j3(p, "lombo")
		lxmin = minf(lxmin, lombo.x)
		lxmax = maxf(lxmax, lombo.x)
		var foc := _j3(p, "focinho")
		fxmin = minf(fxmin, foc.x)
		fxmax = maxf(fxmax, foc.x)
		var rel := _j3(p, "cauda_ponta").x - lombo.x
		tmin = minf(tmin, rel)
		tmax = maxf(tmax, rel)
	checar(lxmax - lxmin > 1.2, "peso lateral ±0,8 (range %.2f px)" % (lxmax - lxmin))
	checar(tmax - tmin > 2.6, "cauda ±1,5 relativa ao lombo (range %.2f px)" % (tmax - tmin))
	checar(fxmax - fxmin > 0.3, "cabeça varre ±4° (range x %.2f px)" % (fxmax - fxmin))
	var p0 := E3.pose(m, "east", 0.0, "idle")
	checar(_j3(p0, "orelha_e").y < float(m["juntas"]["orelha_e"][1]) - 0.3,
		"orelha relaxada/baixa")


func test_walk_dinamica() -> void:
	var m := _rig()
	perto(float(m["motion"]["passo_px"]), 13.8, 0.001, "passo 13,8 px")
	perto(float(m["motion"]["duty_walk"]), 0.55, 0.001, "duty walk 0,55")
	perto(float(m["motion"]["walk_balanco_lateral_px"]), 0.7, 0.001, "balanço lateral ±0,7")
	perto(float(m["motion"]["walk_transversa_px"]), 1.5, 0.001, "transversa ±1,5")
	var lxmin := 1e9
	var lxmax := -1e9
	var hmin := 1e9
	var hmax := -1e9
	var bmin := 1e9
	var bmax := -1e9
	for i in 41:
		var f := float(i) / 40.0
		var p := E3.pose(m, "east", f, "walk")
		var lombo := _j3(p, "lombo")
		lxmin = minf(lxmin, lombo.x)
		lxmax = maxf(lxmax, lombo.x)
		var h := _j3(p, "cabeca")
		hmin = minf(hmin, h.y)
		hmax = maxf(hmax, h.y)
		bmin = minf(bmin, lombo.y)
		bmax = maxf(bmax, lombo.y)
	checar(lxmax - lxmin > 1.2, "balanço lateral ±0,7 (range %.2f px)" % (lxmax - lxmin))
	var p25 := E3.pose(m, "east", 0.25, "walk")
	var p75 := E3.pose(m, "east", 0.75, "walk")
	var d25 := _j3(p25, "peito").z - _j3(p25, "quadril").z
	var d75 := _j3(p75, "peito").z - _j3(p75, "quadril").z
	checar(d25 - d75 > 5.0, "ombros/ancas em antifase (%.2f px)" % (d25 - d75))
	checar(hmax - hmin < (bmax - bmin) * 0.5,
		"cabeça estabilizada contra o bob (head %.2f / corpo %.2f)" % [hmax - hmin, bmax - bmin])


func test_run_dinamica() -> void:
	var m := _rig()
	perto(float(m["motion"]["duty_galope"]), 0.20, 0.001, "duty galope 0,20")
	perto(float(m["motion"]["galope_suspensao_px"]), 4.2, 0.001, "suspensão 4,2 px")
	perto(float(m["motion"]["galope_passo_px"]), 17.0, 0.001, "passo 17 px")
	perto(float(m["motion"]["galope_levanta_px"]), 5.5, 0.001, "levanta 5,5 px")
	perto(float(m["motion"]["run_baixa_px"]), 1.6, 0.001, "corpo desce 1,6 px")
	perto(float(m["motion"]["run_estica_px"]), 2.5, 0.001, "tronco alonga 2,5 px")
	perto(float(m["motion"]["run_pitch_gather_graus"]), 9.0, 0.001, "pitch gather +9°")
	perto(float(m["motion"]["run_pitch_suspensao_graus"]), -6.0, 0.001, "pitch suspensão -6°")
	var p0 := E3.pose(m, "east", 0.0, "run")
	var p25 := E3.pose(m, "east", 0.25, "run")
	checar(_pitch_corpo(p0) > _pitch_corpo(p25) + 8.0,
		"gather nariz baixo > suspensão (%+.2f° / %+.2f°)" % [_pitch_corpo(p0), _pitch_corpo(p25)])
	var fmin := 1e9
	var fmax := -1e9
	for i in 41:
		var f := float(i) / 40.0
		var p := E3.pose(m, "east", f, "run")
		var d := _j3(p, "peito").z - _j3(p, "quadril").z
		fmin = minf(fmin, d)
		fmax = maxf(fmax, d)
	checar(fmax - fmin > 2.5, "flexão do tronco (%.2f px)" % (fmax - fmin))
	var p35 := E3.pose(m, "east", 0.35, "run")
	for k in PATAS:
		checar(_j3(p35, k).y > 0.5, "suspensão tira a pata do chão: " + k)
	var idle5 := E3.pose(m, "east", 0.5, "idle")
	checar(_j3(p25, "orelha_e").z < _j3(idle5, "orelha_e").z - 1.0, "orelhas para trás")
	var len_run := _j3(p25, "cauda_base").distance_to(_j3(p25, "cauda_ponta"))
	var len_idle := _j3(idle5, "cauda_base").distance_to(_j3(idle5, "cauda_ponta"))
	checar(len_run > len_idle + 0.8, "cauda esticada (%.2f > %.2f)" % [len_run, len_idle])


## Passada aparente: entre um apoio e o seguinte a pata varre o passo inteiro
## em z. Medido no ciclo: 13,80 px no walk e 17,00 px no galope, em todas as
## patas (os alvos de _patas usam exatamente passo_px/galope_passo_px).
## A passada APARENTE (extremo traseiro → dianteiro da pata) sai da marcha em
## DADOS, e o LIMITE DE COMPRESSÃO é a única coisa que mexe nela: no balanço a
## pata é afastada do topo da cadeia, e o extremo traseiro pode recuar até o
## afastamento máximo daquele clipe. Medido no galope: fe 17,4643 (dados 17,0 +
## clamp até 0,46 px), te 17,0. A marcha em dados continua exatamente a mesma —
## é o que a primeira checagem prova, varrendo só `_patas`.
func test_passada_aparente_walk_e_run() -> void:
	var m := _rig()
	var pernas := E3._pernas(m)
	var minimos := {"walk": 12.0, "run": 15.0}
	for clipe in ["walk", "run"]:
		var chave := "passo_px" if clipe == "walk" else "galope_passo_px"
		var passo := float(m["motion"][chave])
		var menor := 1e9
		for k in PATAS:
			var sufixo := String(k).replace("pata_", "")
			var perna: Dictionary = {}
			for bruto in pernas:
				if String(bruto["nome"]) == sufixo:
					perna = bruto
			var tmin := 1e9
			var tmax := -1e9
			for i in 400:
				var tz := float(E3._patas(pernas, clipe, float(i) / 400.0, m["motion"])[sufixo].z)
				tmin = minf(tmin, tz)
				tmax = maxf(tmax, tz)
			perto(tmax - tmin, passo, 0.01, "passada dos DADOS de %s em %s" % [k, clipe])
			var zmin := 1e9
			var zmax := -1e9
			var desloc := 0.0
			for i in 200:
				var fase := float(i) / 200.0
				var p := E3.pose(m, "east", fase, clipe)
				var z := _j3(p, k).z
				zmin = minf(zmin, z)
				zmax = maxf(zmax, z)
				var az := float(E3._patas(pernas, clipe, fase, m["motion"])[sufixo].z)
				desloc = maxf(desloc, absf(z - az))
			checar(zmax - zmin >= passo - 0.01 and zmax - zmin <= passo + desloc + 0.01,
				"passada de %s em %s = %.4f (dados %.4f, clamp até %.4f)"
				% [k, clipe, zmax - zmin, passo, desloc])
			menor = minf(menor, zmax - zmin)
		checar(menor >= float(minimos[clipe]),
			"passada aparente %s = %.2f px (mínimo %.0f)" % [clipe, menor, minimos[clipe]])


## Corrida mais baixa e mais esticada: o corpo desce (peito e quadril abaixo
## do idle em alguma fase) e a separação z peito–quadril oscila mais que no
## walk. Medido: peito run 16,53 (idle 19,00); quadril run 17,01 (idle 19,50);
## amplitude da separação run 7,22 px (walk 6,00); média run 21,89 (walk 17,0).
func test_corrida_mais_baixa_e_esticada() -> void:
	var m := _rig()
	var medida := {}
	for clipe in ["idle", "walk", "run"]:
		var peito_min := 1e9
		var quadril_min := 1e9
		var sep_min := 1e9
		var sep_max := -1e9
		var sep_soma := 0.0
		for i in 200:
			var p := E3.pose(m, "east", float(i) / 200.0, clipe)
			peito_min = minf(peito_min, _j3(p, "peito").y)
			quadril_min = minf(quadril_min, _j3(p, "quadril").y)
			var sep := _j3(p, "peito").z - _j3(p, "quadril").z
			sep_min = minf(sep_min, sep)
			sep_max = maxf(sep_max, sep)
			sep_soma += sep
		medida[clipe] = {"peito": peito_min, "quadril": quadril_min,
			"amp": sep_max - sep_min, "media": sep_soma / 200.0}
	var run: Dictionary = medida["run"]
	var idle: Dictionary = medida["idle"]
	var walk: Dictionary = medida["walk"]
	checar(float(run["peito"]) < float(idle["peito"]) - 1.0,
		"peito da corrida desce (%.2f < %.2f)" % [run["peito"], idle["peito"]])
	checar(float(run["quadril"]) < float(idle["quadril"]) - 1.0,
		"quadril da corrida desce (%.2f < %.2f)" % [run["quadril"], idle["quadril"]])
	checar(float(run["amp"]) > float(walk["amp"]) + 0.5,
		"separação peito–quadril oscila mais no run (%.2f > %.2f)" % [run["amp"], walk["amp"]])
	checar(float(run["media"]) > float(walk["media"]) + 3.0,
		"tronco mais esticado no run (média %.2f > %.2f)" % [run["media"], walk["media"]])


func test_pulo_parado() -> void:
	var m := _rig()
	var idle5 := E3.pose(m, "east", 0.5, "idle")
	var js5 := E3.pose(m, "east", 0.5, "jump_start")
	checar(_j3(js5, "lombo").y < _j3(idle5, "lombo").y - 2.5, "agacha ~3 px")
	var head_rel_js := _j3(js5, "cabeca").y - _j3(js5, "lombo").y
	var head_rel_idle := _j3(idle5, "cabeca").y - _j3(idle5, "lombo").y
	checar(head_rel_js > head_rel_idle + 1.0, "cabeça sobe na antecipação")
	var ja2 := E3.pose(m, "east", 0.2, "jump_air")
	var ja65 := E3.pose(m, "east", 0.65, "jump_air")
	var ja9 := E3.pose(m, "east", 0.9, "jump_air")
	checar(_j3(ja2, "pata_fe").y > _j3(ja2, "pata_te").y + 2.0, "dianteiras recolhem primeiro")
	checar(_j3(ja65, "pata_te").y > _j3(ja65, "pata_fe").y + 0.8, "traseiras recolhem depois")
	checar(_j3(ja9, "pata_fe").y < _j3(ja65, "pata_fe").y - 2.0, "dianteiras estendem antes do pouso")
	var jl5 := E3.pose(m, "east", 0.5, "jump_land")
	checar(_j3(jl5, "lombo").y < _j3(idle5, "lombo").y - 2.5, "pouso absorve ~3 px")
	# Sem teleporte de pata nas emendas dos clipes.
	var js_fim := E3.pose(m, "east", 0.99, "jump_start")
	var ja_ini := E3.pose(m, "east", 0.0, "jump_air")
	var ja_fim := E3.pose(m, "east", 0.99, "jump_air")
	var jl_ini := E3.pose(m, "east", 0.0, "jump_land")
	for k in PATAS:
		checar(_j3(js_fim, k).distance_to(_j3(ja_ini, k)) < 0.5, "emenda jump_start→jump_air: " + k)
		checar(_j3(ja_fim, k).distance_to(_j3(jl_ini, k)) < 0.5, "emenda jump_air→jump_land: " + k)


func test_pulo_correndo() -> void:
	var m := _rig()
	var parado := E3.pose(m, "east", 0.5, "jump_air", false)
	var correndo := E3.pose(m, "east", 0.5, "jump_air", true)
	checar(_j3(correndo, "pata_fe").z > _j3(parado, "pata_fe").z + 2.5,
		"pulo correndo alcança +3 z (%.2f)" % (_j3(correndo, "pata_fe").z - _j3(parado, "pata_fe").z))
	checar(_j3(correndo, "lombo").y < _j3(parado, "lombo").y - 0.5,
		"pulo correndo mais baixo (%.2f < %.2f)" % [_j3(correndo, "lombo").y, _j3(parado, "lombo").y])
	var land_c := E3.pose(m, "east", 0.2, "jump_land", true)
	var land_p := E3.pose(m, "east", 0.2, "jump_land", false)
	checar(_j3(land_c, "pata_fe").z > _j3(land_p, "pata_fe").z + 2.0,
		"pouso correndo derrapa com a pata à frente")


func test_mordida_fases() -> void:
	var m := _rig()
	var b15 := E3.pose(m, "east", 0.15, "bite")
	var b4 := E3.pose(m, "east", 0.4, "bite")
	var b65 := E3.pose(m, "east", 0.65, "bite")
	var b1 := E3.pose(m, "east", 1.0, "bite")
	checar(_j3(b15, "cabeca").z < _j3(b4, "cabeca").z - 3.0,
		"antecipação−ataque no z da cabeça (%.2f < %.2f)" % [_j3(b15, "cabeca").z, _j3(b4, "cabeca").z])
	checar(_j3(b4, "focinho").z > _j3(b15, "focinho").z + 3.0,
		"focinho avança no ataque")
	checar(_j3(b4, "focinho").z - _j3(b4, "cabeca").z > 5.0, "focinho abre +2 z")
	checar(_j3(b65, "cabeca").z > _j3(b4, "cabeca").z + 1.0, "cabeça passa do alvo no follow-through")
	checar(_j3(b1, "cabeca").z < _j3(b65, "cabeca").z - 5.0, "follow-through assenta")


func test_esbarrao_fases() -> void:
	var m := _rig()
	var idle4 := E3.pose(m, "east", 0.4, "idle")
	var s4 := E3.pose(m, "east", 0.4, "slam")
	var s7 := E3.pose(m, "east", 0.7, "slam")
	var idle5 := E3.pose(m, "east", 0.5, "idle")
	var s5 := E3.pose(m, "east", 0.5, "slam")
	checar(_j3(s4, "lombo").z - _j3(idle4, "lombo").z > 9.0,
		"pico de dz ~0,4 (%.2f px)" % (_j3(s4, "lombo").z - _j3(idle4, "lombo").z))
	checar(_j3(s7, "lombo").z < _j3(s4, "lombo").z - 0.5, "recua depois do impacto")
	checar(_j3(s4, "lombo").y < _j3(idle4, "lombo").y - 0.5, "corpo baixo no disparo")
	checar(_j3(s5, "cabeca").y < _j3(idle5, "cabeca").y - 1.0, "cabeça baixa no impacto")


func test_fluidez_entre_clipes() -> void:
	var m := _rig()
	var walk_fim := E3.pose(m, "east", 0.99, "walk")
	var run_ini := E3.pose(m, "east", 0.0, "run")
	var run_fim := E3.pose(m, "east", 0.99, "run")
	var jump_ini := E3.pose(m, "east", 0.0, "jump_start")
	var d_wr := _max_dist(walk_fim, run_ini)
	var d_rj := _max_dist(run_fim, jump_ini)
	# A passada cresceu (13,8 px no walk, 17 px no galope): na fronteira CRUA a
	# pata pode estar em pontos opostos do passo — medido 13,89 px, perto do
	# teto (passada_walk + passada_galope) / 2 = 15,4 px. O salto visível não
	# acontece porque a criatura mistura os clipes; esse contrato é testado em
	# test_transicao_walk_run_primeiro_quadro (<3 px).
	checar(d_wr < 15.0, "walk→run sem salto grande (%.2f px)" % d_wr)
	checar(d_rj < 9.0, "run→jump_start sem salto grande (%.2f px)" % d_rj)
	var passo_i := _maior_passo(m, "idle")
	var passo_w := _maior_passo(m, "walk")
	var passo_r := _maior_passo(m, "run")
	checar(passo_i < 1.0, "idle a 60 fps sem pico (%.2f px/quadro)" % passo_i)
	checar(passo_w < 2.0, "walk a 60 fps sem pico (%.2f px/quadro)" % passo_w)
	# O galope tem passada 17 px e só 20% de apoio: o balanço varre mais rápido
	# e o pico do jarrete sobe de ~1,9 para 2,31 px/quadro.
	# Lote 3C: o metatarso mais longo (7,60) sobe o jarrete 1,3 px e a tíbia
	# mais curta (8,97) aproxima a cadeia coxa→joelho→jarrete do recolhimento
	# total (|l1−l2| = 2,03) no balanço do galope: o pico do joelho traseiro
	# (joelho_td, fase 0,733) medido é 3,48 px/quadro. Teto 2,5 → 3,5 com o
	# motivo declarado; a pata NÃO acelera (o pico é do joelho, não do pé).
	checar(passo_r < 3.5, "run a 60 fps sem pico (%.2f px/quadro)" % passo_r)


func _max_dist(a: Dictionary, b: Dictionary) -> float:
	var md := 0.0
	for nome in a["juntas"]:
		md = maxf(md, (a["juntas"][nome] as Vector2).distance_to(b["juntas"][nome]))
	return md


func _maior_passo(m: Dictionary, clipe: String) -> float:
	var md := 0.0
	for i in 60:
		var a := E3.pose(m, "east", float(i) / 60.0, clipe)
		var b := E3.pose(m, "east", float(i + 1) / 60.0, clipe)
		md = maxf(md, _max_dist(a, b))
	return md


func test_misturar_poses() -> void:
	var m := _rig()
	var a := E3.pose(m, "east", 0.99, "walk")
	var b := E3.pose(m, "east", 0.0, "run")
	var z := E3.misturar(a, b, 0.0)
	var o := E3.misturar(a, b, 1.0)
	var meio := E3.misturar(a, b, 0.5)
	for nome in a["juntas"]:
		perto_v(z["juntas"][nome], a["juntas"][nome], 0.000001, "misturar w=0 junta " + nome)
		perto_v(o["juntas"][nome], b["juntas"][nome], 0.000001, "misturar w=1 junta " + nome)
		perto_v(meio["juntas"][nome],
			(a["juntas"][nome] as Vector2).lerp(b["juntas"][nome], 0.5), 0.000001,
			"misturar 0,5 junta " + nome)
		perto(float(meio["profundidade"][nome]),
			lerpf(float(a["profundidade"][nome]), float(b["profundidade"][nome]), 0.5), 0.000001,
			"misturar 0,5 profundidade " + nome)
	for nome in a["sockets"]:
		perto_v(z["sockets"][nome]["pos"], a["sockets"][nome]["pos"], 0.000001,
			"misturar w=0 socket " + nome)
		perto_v(o["sockets"][nome]["pos"], b["sockets"][nome]["pos"], 0.000001,
			"misturar w=1 socket " + nome)
		perto(float(z["sockets"][nome]["profundidade"]), float(a["sockets"][nome]["profundidade"]),
			0.000001, "misturar w=0 socket prof " + nome)
		perto(float(o["sockets"][nome]["profundidade"]), float(b["sockets"][nome]["profundidade"]),
			0.000001, "misturar w=1 socket prof " + nome)
		perto_v(meio["sockets"][nome]["pos"],
			(a["sockets"][nome]["pos"] as Vector2).lerp(b["sockets"][nome]["pos"], 0.5), 0.000001,
			"misturar 0,5 socket " + nome)
		perto(float(meio["sockets"][nome]["profundidade"]),
			lerpf(float(a["sockets"][nome]["profundidade"]), float(b["sockets"][nome]["profundidade"]), 0.5),
			0.000001, "misturar 0,5 socket prof " + nome)
	# A origem e o destino não são mutados.
	perto_v(a["juntas"]["peito"], (E3.pose(m, "east", 0.99, "walk")["juntas"]["peito"] as Vector2), 0.000001,
		"misturar não muta a")
	perto_v(b["juntas"]["peito"], (E3.pose(m, "east", 0.0, "run")["juntas"]["peito"] as Vector2), 0.000001,
		"misturar não muta b")


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
