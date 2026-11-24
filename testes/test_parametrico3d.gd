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
		var porte: Array = m["porte_px"]
		var quadro: Array = m["quadro_px"]
		checar(int(quadro[0]) >= int(porte[0]) and int(quadro[1]) >= int(porte[1]),
			"quadro %s contém o porte: %s >= %s" % [nome, quadro, porte])
		checar(int(quadro[0]) > 68 or int(quadro[1]) > 68,
			"quadro %s não travado em 68: %s" % [nome, quadro])
		igual(m["bounds_clipes"].size(), E3.CLIPES.size(), "bbox por clipe")
		for clipe in E3.CLIPES:
			var box: Rect2 = m["bounds_clipes"][clipe]
			for dir in E3.DIRECOES:
				for i in 17:
					var pose := E3.pose(m, dir, float(i) / 16.0, clipe, true)
					for q in pose["juntas"].values():
						checar(box.has_point(q) and q.x >= 0 and q.x < quadro[0]
							and q.y >= 0 and q.y < quadro[1], "bbox %s/%s" % [nome, clipe])
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


func test_porte_imutavel_em_todos_os_clipes_direcoes_e_fases() -> void:
	for nome in ["canino3d", "equino3d"]:
		var declarado: Array = _raw(nome)["porte_px"]
		igual([float(declarado[0]), float(declarado[1])], [68.0, 68.0],
			"porte %s declarado no JSON" % nome)
		var m := Rigs.carregar(nome)
		igual(m["porte_px"], declarado, "porte %s preparado = declarado" % nome)
		for clipe in E3.CLIPES:
			for dir in E3.DIRECOES:
				for i in 9:
					for sprint in [false, true]:
						E3.pose(m, dir, float(i) / 8.0, clipe, sprint)
		igual(m["porte_px"], declarado, "nenhuma pose reescreve o porte (%s)" % nome)
		var pronto := E3.preparar(m)
		igual(pronto["porte_px"], declarado, "preparar de novo preserva o porte")
		checar(pronto.has("quadro_px") and not pronto.has("canvas_px"),
			"quadro_px é o único campo derivado")


func test_quadro_contem_o_porte_e_rig_antigo_reprova() -> void:
	for nome in ["canino3d", "equino3d"]:
		var m := Rigs.carregar(nome)
		var porte: Array = m["porte_px"]
		var quadro: Array = m["quadro_px"]
		checar(int(quadro[0]) >= int(porte[0]) and int(quadro[1]) >= int(porte[1]),
			"quadro %s contém o porte: %s >= %s" % [nome, quadro, porte])
		checar(int(quadro[0]) > int(porte[0]) or int(quadro[1]) > int(porte[1]),
			"quadro %s cresce além do porte: %s" % [nome, quadro])
	var antigo := _raw("canino3d")
	antigo["canvas_px"] = antigo["porte_px"]
	antigo.erase("porte_px")
	igual(E3.validar(antigo), "porte_px inválido", "campo antigo não passa calado")
	checar(E3.de_json(JSON.stringify(antigo)).is_empty(), "de_json fecha a porta")
	checar(E3.preparar(antigo).is_empty(), "preparar fecha a porta")


## A marcha é DADO: `motion.clipe_marcha` aponta o walk para `motion.marchas.passo`.
## Dobrar a passada SÓ no JSON (em memória) e reprepare tem de dobrar a varredura
## do pé no apoio — prova de que a pose obedece à tabela, não ao motor. Sem a
## tabela o validador reprova (o motor não tem fallback de marcha).
func test_marcha_em_dados_comanda_a_passada_do_walk() -> void:
	var cru := _raw("canino3d")
	var passo := float(cru["motion"]["marchas"]["passo"]["passo_px"])
	var base := Rigs.carregar("canino3d")
	perto(float(E3._marcha(base["motion"], "walk").get("passo_px", -1.0)), passo, 0.001,
		"walk resolvido pela marcha `passo` da tabela")
	var antes := _varredura_z(base, "pata_te")
	perto(antes, passo, 0.01, "varredura do pé no apoio = passada da tabela")
	var dobrado := cru.duplicate(true)
	dobrado["motion"]["marchas"]["passo"]["passo_px"] = passo * 2.0
	var pronto := E3.preparar(dobrado)
	checar(not pronto.is_empty(), "rig com a marcha dobrada prepara")
	var depois := _varredura_z(pronto, "pata_te")
	perto(depois, antes * 2.0, 0.02, "passada dobrada dobra a varredura do pé (%.3f)" % depois)
	var sem := cru.duplicate(true)
	sem["motion"].erase("marchas")
	checar(E3.validar(sem) != "", "rig sem `marchas` reprova (fail-closed, sem fallback)")


func _varredura_z(m: Dictionary, pata: String) -> float:
	var zmin := INF
	var zmax := -INF
	for i in 41:
		var p := E3.pose(m, "east", float(i) / 40.0, "walk")
		var z := float((p["juntas_3d"][pata] as Vector3).z)
		zmin = minf(zmin, z)
		zmax = maxf(zmax, z)
	return zmax - zmin


## Métrica e invariante: o ciclo agora é DERIVADO (`passo_px / duty`), então
## `duty × ciclo` é a própria passada e o descompasso é zero por construção.
## A métrica continua impressa para auditoria e o teste exige zero — se alguém
## voltar a declarar ciclo à mão, quebra aqui.
func test_metricas_das_marchas_declaradas() -> void:
	for nome in ["canino3d", "equino3d"]:
		var m := Rigs.carregar(nome)
		for clipe in ["walk", "run"]:
			var marcha := E3._marcha(m["motion"], clipe)
			var passada := float(marcha.get("passo_px", 0.0))
			var avanco := float(marcha.get("duty", 0.0)) * E3._ciclo(marcha)
			perto(avanco, passada, 0.000001,
				"descompasso zero em %s/%s (passada = duty × ciclo derivado)" % [nome, clipe])
			print("métrica marcha %s/%s: passada=%.6f duty*ciclo=%.6f descompasso=%.6f px"
				% [nome, clipe, passada, avanco, passada - avanco])


## Prova de construção, SEM âncora: com o ciclo derivado a pata plantada fica
## parada no mundo só pela pose — nenhum `alvos` entra no `E3.pose` aqui. O
## corpo anda 1,83 px por quadro e a pose recua a pata na mesma medida durante
## o apoio; a variação da posição de mundo tem de ser zero (tolerância 0,01
## px). Sem essa identidade, quem segura o pé é a âncora.
func test_derrapagem_zero_sem_ancora_na_passada() -> void:
	var m := Rigs.carregar("canino3d")
	var piv := Vector2(float(m["pivot_px"][0]), float(m["pivot_px"][1]))
	for clipe in ["walk", "run"]:
		var pior := 0.0
		var amostras := 0
		var primeira := {}
		var estado: Dictionary = {}
		var anterior := Vector2.ZERO
		for i in 80:
			var pos := Vector2(float(i) * 1.83, 0.0)
			estado = Loc.avancar(m, estado, pos, "east", 0.0, clipe, pos - anterior)
			anterior = pos
			# Pose PURA: sem `alvos`, o apoio não vem de âncora nenhuma.
			var p := E3.pose(m, "east", estado["fase"], clipe)
			for perna in E3._pernas(m):
				var nome := String(perna["nome"])
				if not (estado["alvos"] as Dictionary).has(nome):
					primeira.erase(nome)
					continue
				var foot := String(perna["foot"])
				var mundo: Vector2 = pos + (p["juntas"][foot] as Vector2) - piv
				if not primeira.has(nome):
					primeira[nome] = mundo
					continue
				pior = maxf(pior, mundo.distance_to(primeira[nome]))
				amostras += 1
		checar(amostras > 12, "apoios sem âncora suficientes em %s: %d" % [clipe, amostras])
		checar(pior < 0.01, "derrapagem sem âncora em %s: %.6f px (<0,01)" % [clipe, pior])
		print("métrica derrapagem sem âncora %s: %.6f px em %d apoios" % [clipe, pior, amostras])


## Terceira marcha declarada SÓ EM DADOS: trote diagonal (te+fd juntos, fe+td
## meio ciclo depois, duty 0,4). O motor não conhece o nome — `clipe_marcha.walk`
## aponta para ela e pose/ancoragem saem da tabela, sem edição de motor. As
## quatro patas passam pelo apoio (dois pares diagonais) e o pé plantado não
## desliza (erro < 1 px), o mesmo contrato do walk.
func test_terceira_marcha_so_em_dados_anda_com_quatro_apoios() -> void:
	var cru := _raw("canino3d")
	var m := cru.duplicate(true)
	m["motion"]["marchas"]["trote"] = {
		"duty": 0.4,
		"passo_px": 12.0,
		"levanta_px": 3.0,
		"easing_levanta": 0.72,
		"avanco": {
			"dianteira": {"curva": "ease_out", "expoente": 2.0},
			"traseira": {"curva": "ease_out", "expoente": 2.0},
		},
		"defasagem": {"te": 0.0, "fe": 0.5, "td": 0.5, "fd": 0.0},
	}
	m["motion"]["clipe_marcha"]["walk"] = "trote"
	var pronto := E3.preparar(m)
	checar(not pronto.is_empty(), "rig com a terceira marcha prepara")
	igual(String(pronto["motion"]["clipe_marcha"]["walk"]), "trote",
		"walk aponta a marcha nova em dados")
	perto(float(E3._marcha(pronto["motion"], "walk").get("duty", -1.0)), 0.4, 0.0001,
		"o motor lê duty 0,4 da tabela, sem conhecer o nome")
	var estado: Dictionary = {}
	var anterior := Vector2.ZERO
	var em_apoio: Dictionary = {}
	var apoio_por_pata: Dictionary = {}
	var pior := 0.0
	var amostras := 0
	var max_simult := 0
	var min_simult := 999
	for i in 80:
		var pos := Vector2(float(i) * 1.83, 0.0)
		estado = Loc.avancar(pronto, estado, pos, "east", 0.0, "walk", pos - anterior)
		anterior = pos
		max_simult = maxi(max_simult, (estado["alvos"] as Dictionary).size())
		min_simult = mini(min_simult, (estado["alvos"] as Dictionary).size())
		var p := E3.pose(pronto, "east", estado["fase"], "walk", false, 0.0, estado["alvos"])
		var piv := Vector2(float(pronto["pivot_px"][0]), float(pronto["pivot_px"][1]))
		for perna in E3._pernas(pronto):
			var nome := String(perna["nome"])
			if not estado["alvos"].has(nome):
				continue
			em_apoio[nome] = true
			apoio_por_pata[nome] = int(apoio_por_pata.get(nome, 0)) + 1
			var alvo: Vector3 = estado["alvos"][nome]
			var upper: Vector3 = p["juntas_3d"][perna["upper"]]
			var raio := float(perna["l1"]) + float(perna["l2"]) + float(perna.get("l3", 0.0))
			if upper.distance_to(alvo) > raio - 0.4:
				continue
			var foot := String(perna["foot"])
			var mundo_pata: Vector2 = pos + (p["juntas"][foot] as Vector2) - piv
			pior = maxf(pior, mundo_pata.distance_to(estado["apoios"][nome]))
			amostras += 1
	igual(em_apoio.size(), 4, "as quatro patas passam pelo apoio no trote")
	checar(amostras > 12, "apoios viáveis no trote: %d" % amostras)
	checar(pior < 1.0, "trote sem derrapar em apoio alcançável %.3f px (<1)" % pior)
	# Assinatura do dado, não do nome: dois pares diagonais apoiando juntos e
	# suspensão entre eles (duty 0,4). O walk (duty 0,55, defasagem em quartos)
	# chega a três patas no chão e nunca fica sem apoio.
	checar(max_simult <= 2, "trote apoia no máximo um par diagonal (%d)" % max_simult)
	igual(min_simult, 0, "trote tem suspensão entre os pares (duty 0,4 da tabela)")
	for nome in ["te", "fd"]:
		perto(float(apoio_por_pata.get(nome, 0)) / 80.0, 0.4, 0.08,
			"fração em apoio de %s = duty 0,4 da tabela" % nome)
	var trote: Dictionary = pronto["motion"]["marchas"]["trote"]
	var passada := float(trote["passo_px"])
	var avanco := float(trote["duty"]) * E3._ciclo(trote)
	print("métrica marcha trote: passada=%.6f duty*ciclo=%.6f descompasso=%.6f px"
		% [passada, avanco, passada - avanco])


## P0 da auditoria: a IK escolhia a dobra errada e a perna ficava
## anatomicamente impossível (cotovelo acima do ombro, joelho acima da anca,
## jarrete acima do joelho). As regras são do SOLVER, nunca do dado: a pata
## continua no alvo da marcha — passado pelo limite de compressão — e os
## comprimentos l1/l2/l3 não esticam. Varre 8 direções × 24 fases × walk/run
## nos dois rigs.
##
## REGRA 1 — POLO FIXO, SEM TROCA DE RAMO. A dobra é sempre a do polo do rig
## (cotovelo atrás, joelho à frente, jarrete atrás do joelho). A v0.34.2
## escolhia o ramo e o cotovelo aparecia dobrado para a frente; agora o sentido
## da dobra tem 0 casos fora do polo em TODAS as fases (`lado` ≥ 0 na dianteira
## e z(jarrete) < z(joelho) na traseira).
##
## REGRA 2 — LIMITE DE COMPRESSÃO, no alvo do pé antes da IK: no BALANÇO, se
## |topo→pata| < dmin o alvo é afastado ao longo da reta topo→pata até dmin
## (2 ossos: sqrt(l2²−l1²)+0,05; traseira de 3: sqrt((l2+l3)²−l1²)+0,05). Em
## APOIO o clamp não dispara (0 quadros medidos) e a pata em contato é bit a
## bit a mesma de antes (sha256 das 1280 patas em contato, antes = depois).
##
## MEDIDO (por direção, 24 fases, por perna). ANTES, cão no galope: cotovelo
## acima do ombro 10/24, joelho acima da anca 3/24, jarrete acima do joelho
## 3/24; pior violação 8,02 px. DEPOIS: cotovelo 6/24, joelho 3/24, jarrete
## 2/24; pior 5,35 px. Walk e equino (walk e run) ficam 100% limpos.
##
## O que SOBRA é geometria de ALVO, não escolha do solver:
##   dianteira — com o polo atrás, o cotovelo de uma cadeia de 2 ossos só desce
##   ao nível do ombro com |ombro→pata| ≥ 13,99–17,02 px (medido nesses
##   quadros; a pata teria de recuar 0,3–6,7 px além do arco da passada). A
##   dobra espelhada põe o cotovelo ABAIXO do ombro, mas à FRENTE (lado −6,1 a
##   −8,25): trocar de ramo é exatamente o que a Regra 1 proíbe.
##   traseira (jarrete) — no recolhimento máximo o jarrete sobe acima do
##   joelho; a busca do jarrete ACHA a solução ordenada (violação 0 no giro de
##   12,5–36°), mas ela exige um salto de joelho acima de `E3.SALTO_DOBRA`, e
##   sem esse teto a fluidez estoura (4,69 px/quadro contra o teto de 3,5).
##   traseira (joelho) — o jarrete cai à frente da anca; nenhuma distância
##   abaixo da do APOIO ordena a cadeia, e clampar o apoio é proibido.
func test_ordem_anatomica_das_pernas_na_marcha() -> void:
	var conta := {}
	var pior := 0.0
	var dobra_ruim := 0
	var clamp_em_apoio := 0
	for nome in ["canino3d", "equino3d"]:
		var m := Rigs.carregar(nome)
		var pernas := E3._pernas(m)
		var moderno := int(m.get("schema_version", 3)) == 4
		for clipe in ["walk", "run"]:
			for dir in E3.DIRECOES:
				for i in 24:
					var fase := float(i) / 24.0
					var p := E3.pose(m, dir, fase, clipe)
					var j3: Dictionary = p["juntas_3d"]
					var patas: Dictionary = E3._patas(pernas, clipe, fase, m["motion"])
					for bruto in pernas:
						var perna: Dictionary = bruto
						var tres: bool = perna.has("l3")
						var pata := String(perna["nome"])
						var P: Vector3 = j3[String(perna["upper"])]
						var K: Vector3 = j3[String(perna["joint1"])]
						var F: Vector3 = j3[String(perna["foot"])]
						var H: Vector3 = j3[String(perna["joint2"])] if tres else K
						var tag := "%s/%s/%s/%.3f/%s" % [nome, clipe, dir, fase, pata]
						# 0) O alvo do solver é o da marcha COM o limite de
						# compressão; em apoio, o alvo cru (o clamp não dispara).
						var alvo: Vector3 = E3._alvo_compressao(P, patas[pata],
							(Vector3(patas[pata]) as Vector3).y > 0.0, E3._dmin_perna(perna))
						if (Vector3(patas[pata]) as Vector3).y <= 0.0 and alvo != patas[pata]:
							clamp_em_apoio += 1
						# 1) A pata está no alvo (com o clamp) e o osso não estica.
						perto(F.distance_to(alvo), 0.0, 0.0002, "pata no alvo (com o clamp) " + tag)
						perto(P.distance_to(K), float(perna["l1"]), 0.0002, "l1 rígido " + tag)
						if tres:
							perto(K.distance_to(H), float(perna["l2"]), 0.0002, "l2 rígido " + tag)
							perto(H.distance_to(F), float(perna["l3"]), 0.0002, "l3 rígido " + tag)
						else:
							perto(K.distance_to(F), float(perna["l2"]), 0.0002, "l2 rígido " + tag)
						# 2) A DOBRA É A DO POLO em todas as fases (Regra 1).
						if tres:
							if not (H.z < K.z):
								dobra_ruim += 1
						elif E3._lado_da_reta(P, F, K) < 0.0:
							dobra_ruim += 1
						# 3) Ordem anatômica.
						var v := E3.violacao_perna(P, F, K, H, tres)
						pior = maxf(pior, v)
						if v <= E3.TOL_ANATOMIA:
							continue
						var chave := "%s/%s/%s" % [nome, clipe, "traseira" if tres else "dianteira"]
						conta[chave] = int(conta.get(chave, 0)) + 1
						if not tres:
							# Só é aceitável se a outra dobra estiver À FRENTE do
							# polo: aí não há ramo válido, e trocar é proibido.
							var outra := E3._dobra(P, alvo, float(perna["l1"]), float(perna["l2"]),
								perna["pole"], moderno, -E3._sentido_polo(perna, moderno))
							var joelho_outra: Vector3 = outra["joelho"]
							checar(E3._lado_da_reta(P, alvo, joelho_outra) < 0.0,
								"havia dobra do polo e o solver não a usou " + tag)
						else:
							# Traseira: só o galope do cão tem alvo extremo.
							checar(nome == "canino3d" and clipe == "run",
								"traseira fora da ordem em %s" % tag)
	print("métrica ordem anatômica: %s (pior violação %.3f px, dobra fora do polo %d, clamp em apoio %d)"
		% [JSON.stringify(conta), pior, dobra_ruim, clamp_em_apoio])
	# Regra 1 em todas as fases: a dobra é sempre a do polo.
	igual(dobra_ruim, 0, "dobra sempre no polo (cotovelo atrás, jarrete atrás do joelho)")
	# Regra 2 nunca toca no apoio.
	igual(clamp_em_apoio, 0, "clamp de compressão nunca dispara em apoio")
	# Marcha lenta: ordem 100% nos dois rigs e nas duas cadeias.
	for rig in ["canino3d", "equino3d"]:
		for lado in ["dianteira", "traseira"]:
			igual(int(conta.get("%s/walk/%s" % [rig, lado], 0)), 0,
				"%s %s limpa no walk" % [rig, lado])
	# Galope do equino: 100% também.
	for lado in ["dianteira", "traseira"]:
		igual(int(conta.get("equino3d/run/%s" % lado, 0)), 0,
			"equino %s limpa no run" % lado)
	# Cão no galope: só o que o alvo torna impossível. Teto = o medido agora
	# (96 dianteiras, 48 joelhos e 32 jarretes por 8 direções); subir é regressão.
	checar(int(conta.get("canino3d/run/dianteira", 0)) <= 96,
		"dianteira do cão no galope: só alvo extremo (%d casos)"
		% int(conta.get("canino3d/run/dianteira", 0)))
	checar(int(conta.get("canino3d/run/traseira", 0)) <= 80,
		"traseira do cão no galope: só recolhimento máximo (%d casos)"
		% int(conta.get("canino3d/run/traseira", 0)))
