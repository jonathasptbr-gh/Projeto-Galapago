extends "res://testes/caso.gd"
const E3 := preload("res://sim/esqueleto3d.gd")
const Topo := preload("res://sim/topologia3d.gd")
const Loc := preload("res://sim/locomocao3d.gd")
const Rigs := preload("res://jogo/rigs3d.gd")


func _raw(nome: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://dados/rig/" + nome + ".json"))


func test_compilador_legacy_e_segunda_especie() -> void:
	var cao := _raw("canino3d")
	var equino := _raw("equino3d")
	igual(E3.validar(cao), "", "cão schema 3 preservado")
	igual(E3.validar(equino), "", "novo quadrúpede schema 4 validado")
	var tc := Topo.compilar(cao)
	var te := Topo.compilar(equino)
	igual(tc["articulacoes"], 24, "24 juntas caninas mantidas")
	checar(tc["acima_recomendacao"], "legado excede teto recomendado, sem apagar juntas")
	igual(te["articulacoes"], 20, "preset novo cabe em vinte")
	checar(not te["acima_recomendacao"], "novo modelo cumpre recomendação")
	igual(te["membros"].size(), 4, "membros compilados por papel")
	var pronto := Rigs.carregar("equino3d")
	checar(not pronto.is_empty(), "loader compila equino sem editar solver")
	for dir in E3.DIRECOES:
		for clipe in E3.CLIPES:
			var p := E3.pose(pronto, dir, 0.42, clipe)
			igual(p.get("juntas", {}).size(), 20, "20 juntas em %s/%s" % [dir, clipe])
			for ponto in p.get("juntas", {}).values():
				checar((ponto as Vector2).is_finite(), "ponto equino finito")


func test_topologia_reprova_ciclo_disconnect_polo_e_cardinalidade() -> void:
	var original := _raw("equino3d")
	var m := original.duplicate(true)
	m["ossos"][0]["b"] = "quadril"
	checar(Topo.compilar(m).is_empty(), "ciclo/autoligação reprovado")
	m = original.duplicate(true)
	m["papeis"]["cabeca"] = "spine"
	checar(Topo.compilar(m).is_empty(), "head obrigatório")
	m = original.duplicate(true)
	m["membros"][0]["pole"] = [0, 0, 0]
	checar(Topo.compilar(m).is_empty(), "polo nulo reprovado")
	m = original.duplicate(true)
	m["ossos"][1]["b"] = "fantasma"
	checar(Topo.compilar(m).is_empty(), "junta inexistente reprovada")
	m = original.duplicate(true)
	m["ossos"][1]["b"] = m["ossos"][0]["b"]
	checar(Topo.compilar(m).is_empty(), "pai múltiplo reprovado")


func test_interfaces_bipede_ave_serpente_sem_promessa_de_gait() -> void:
	var modelos := [
		{"arquetipo": "bipede", "roles": ["pelvis", "head", "limb_front", "limb_front", "limb_back", "limb_back"]},
		{"arquetipo": "ave", "roles": ["pelvis", "head", "wing", "wing", "limb_back", "limb_back"]},
		{"arquetipo": "serpente", "roles": ["pelvis", "spine", "spine", "head"]},
	]
	for item in modelos:
		var m := {"schema_version": 4, "arquetipo": item["arquetipo"], "juntas": {}, "ossos": [], "papeis": {}}
		for i in item["roles"].size():
			var nome := "j%d" % i
			m["juntas"][nome] = [0, 2, i * 3]
			m["papeis"][nome] = item["roles"][i]
			if i > 0:
				m["ossos"].append({"a": "j0", "b": nome, "largura": 1})
		var t := Topo.compilar(m)
		checar(not t.is_empty(), "interface %s compilada" % item["arquetipo"])
		checar(not bool(t.get("locomocao_suportada", true)), "gait %s não prometida" % item["arquetipo"])


func test_ik_espacial_polo_e_jarrete_sem_inverter() -> void:
	for pole in [Vector3(1, 0, 1), Vector3(-1, 0, 1)]:
		var p := Vector3(0, 18, 0)
		var alvo := Vector3(5, 0, 7)
		var sol := E3.ik_pole(p, alvo, 11, 11, pole)
		perto(p.distance_to(sol["joelho"]), 11, 0.001, "fêmur rígido")
		perto((sol["joelho"] as Vector3).distance_to(sol["pata"]), 11, 0.001, "tíbia rígida")
		checar((sol["joelho"] as Vector3).is_finite(), "polo com x produz junta finita")
		checar((sol["joelho"] as Vector3).x * pole.x > -1.0, "polo 3D orienta flexão")
	var extremo := E3.ik_pole(Vector3.ZERO, Vector3(0, -40, 0), 10, 10,
		Vector3(0, 0, 1))
	checar(not extremo["alcancavel"] and (extremo["pata"] as Vector3).length() <= 19.61,
		"extensão suavizada 98% em alvo impossível")


func test_bounds_globais_mantem_pivo_e_cobre_clipes() -> void:
	for nome in ["canino3d", "equino3d"]:
		var m := Rigs.carregar(nome)
		var piv: Array = m["pivot_px"]
		var canvas: Array = m["canvas_px"]
		checar(int(canvas[0]) > 68 or int(canvas[1]) > 68,
			"canvas %s não travado em 68: %s" % [nome, canvas])
		igual(m["bounds_clipes"].size(), E3.CLIPES.size(), "bbox por clipe")
		for clipe in E3.CLIPES:
			var box: Rect2 = m["bounds_clipes"][clipe]
			for dir in E3.DIRECOES:
				for i in 17:
					var pose := E3.pose(m, dir, float(i) / 16.0, clipe, true)
					for q in pose["juntas"].values():
						checar(box.has_point(q) and q.x >= 0 and q.x < canvas[0]
							and q.y >= 0 and q.y < canvas[1], "bbox %s/%s" % [nome, clipe])
		igual(m["pivot_px"], piv, "pivô global imutável entre clipes")


func test_voo_corrido_comprimento_altura_sem_escala() -> void:
	var m := Rigs.carregar("canino3d")
	var f := 0.375
	var p := E3.pose(m, "east", f, "run")
	var a: Dictionary = p["juntas_3d"]
	var frente: Vector3 = a["pata_fe"]
	var tras: Vector3 = a["pata_te"]
	var alto := 0.0
	var baixo := INF
	for q in a.values():
		alto = maxf(alto, (q as Vector3).y)
		baixo = minf(baixo, (q as Vector3).y)
	var largura := absf(frente.z - tras.z)
	var altura := alto - baixo
	print("métrica voo canino: comprimento=", largura, " altura=", altura,
		" ratio=", largura / altura)
	checar(largura / altura >= 1.8 and largura / altura <= 2.3,
		"voo esticado ~2:1, sem escalar px (%.2f)" % (largura / altura))
	checar(frente.z > a["ombro_e"].z and tras.z < a["anca_e"].z,
		"patas voam na direção anatômica")


func test_apoios_reais_fase_por_distancia_e_idle() -> void:
	var m := Rigs.carregar("canino3d")
	var estado: Dictionary = {}
	var anterior := Vector2.ZERO
	var amostras := 0
	var pior := 0.0
	for i in 80:
		var pos := Vector2(float(i) * 1.83, 0.0)
		estado = Loc.avancar(m, estado, pos, "east", 0.0, "walk", pos - anterior)
		anterior = pos
		var p := E3.pose(m, "east", estado["fase"], "walk", false, 0.0, estado["alvos"])
		var piv := Vector2(float(m["pivot_px"][0]), float(m["pivot_px"][1]))
		for perna in E3._pernas(m):
			var nome := String(perna["nome"])
			if not estado["alvos"].has(nome):
				continue
			var alvo: Vector3 = estado["alvos"][nome]
			var upper: Vector3 = p["juntas_3d"][perna["upper"]]
			var raio := float(perna["l1"]) + float(perna["l2"]) + float(perna.get("l3", 0.0))
			if upper.distance_to(alvo) > raio - 0.4:
				continue
			var foot := String(perna["foot"])
			var mundo_pata: Vector2 = pos + (p["juntas"][foot] as Vector2) - piv
			var erro := mundo_pata.distance_to(estado["apoios"][nome])
			pior = maxf(pior, erro)
			amostras += 1
	checar(amostras > 12, "apoios viáveis suficientes: %d" % amostras)
	checar(pior < 1.0, "deslizamento em apoio alcançável %.3f px (<1)" % pior)
	var fase := float(estado["fase"])
	estado = Loc.avancar(m, estado, anterior, "east", 0.0, "walk", Vector2.ZERO)
	perto(float(estado["fase"]), fase, 0.00001, "parado não avança fase")
	estado = Loc.avancar(m, estado, anterior, "east", 0.0, "idle", Vector2.ZERO)
	igual((estado["apoios"] as Dictionary).size(), 0, "idle libera âncoras")
	estado = Loc.avancar(m, estado, anterior, "north", 270.0, "walk", Vector2.ZERO)
	igual((estado["apoios"] as Dictionary).size(), 4, "giro reancora sem transportar patas anteriores")
	print("métrica marcha: ", amostras, " apoios alcançáveis, erro máximo ", pior, " px")
