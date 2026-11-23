extends "res://testes/caso.gd"
## Contrato do esqueleto: o rig do canino valida, a pose responde nas quatro
## direções, o pé fica no chão, o espelho não desloca e a âncora ausente NÃO
## herda posição. Rig adulterado falha fechado.

const E := preload("res://sim/esqueleto.gd")
const CAMINHO := "res://dados/rig/canino.json"


func _rig() -> Dictionary:
	return _rig_nome("canino")


func _rig_nome(nome: String) -> Dictionary:
	var caminho := "res://dados/rig/" + nome + ".json"
	var texto := FileAccess.get_file_as_string(caminho)
	checar(not texto.is_empty(), "rig legível em " + caminho)
	var m := E.de_json(texto)
	checar(not m.is_empty(), "rig válido (de_json): " + nome)
	return m


func test_rig_do_projeto_valida() -> void:
	var m := _rig()
	igual(E.validar(m), "", "canino sem erro")
	igual(E.direcoes(m).size(), 8, "oito direções")
	perto(E.duracao(m, "walk"), 0.5, 0.001, "duração do passo")
	perto(E.duracao(m, "idle"), 1.0, 0.001, "duração do parado")


func test_pose_tem_juntas_nas_oito_direcoes() -> void:
	var m := _rig()
	for dir in E.DIRECOES:
		var p := E.pose(m, dir, 0.0, "idle")
		checar(not p.is_empty(), "pose existe: " + dir)
		var j: Dictionary = p.get("juntas", {})
		checar(j.size() >= 12, "juntas suficientes: " + dir)
		checar(j.has("pata_e") or j.has("pata_f"), "tem pé: " + dir)


func test_pes_no_chao() -> void:
	var m := _rig()
	var p := E.pose(m, "south", 0.0, "idle")
	var j: Dictionary = p["juntas"]
	perto((j["pata_e"] as Vector2).y, 50.0, 0.001, "pé esquerdo no chão")
	perto((j["pata_d"] as Vector2).y, 50.0, 0.001, "pé direito no chão")
	var l := E.pose(m, "east", 0.0, "idle")
	var jl: Dictionary = l["juntas"]
	perto((jl["pata_f"] as Vector2).y, 50.0, 0.001, "pata dianteira no chão")
	perto((jl["pata_t"] as Vector2).y, 50.0, 0.001, "pata traseira no chão")
	for diag in ["south-east", "north-east"]:
		var p2 := E.pose(m, diag, 0.0, "idle")
		var j2: Dictionary = p2["juntas"]
		perto((j2["pata_f"] as Vector2).y, 50.0, 0.001, "pata dianteira no chão: " + diag)
		perto((j2["pata_t"] as Vector2).y, 50.0, 0.001, "pata traseira no chão: " + diag)


func test_espelho_nao_desloca() -> void:
	var m := _rig()
	for par in [["east", "west"], ["south-east", "south-west"], ["north-east", "north-west"]]:
		var da: String = par[0]
		var db: String = par[1]
		var a := E.pose(m, da, 0.0, "walk")
		var b := E.pose(m, db, 0.0, "walk")
		var ja: Dictionary = a["juntas"]
		var jb: Dictionary = b["juntas"]
		checar(not ja.is_empty() and not jb.is_empty(), "pose do par " + da)
		for nome in ja:
			if jb.has(nome):
				perto((ja[nome] as Vector2).x + (jb[nome] as Vector2).x, 68.0, 0.001,
					"espelho %s/%s em %s" % [da, db, nome])
				perto((ja[nome] as Vector2).y, (jb[nome] as Vector2).y, 0.001,
					"altura %s/%s em %s" % [da, db, nome])


func test_espelho_cardinal_antigo() -> void:
	var m := _rig()
	var l := E.pose(m, "east", 0.0, "idle")
	var o := E.pose(m, "west", 0.0, "idle")
	var fl: Vector2 = l["juntas"]["focinho"]
	var fo: Vector2 = o["juntas"]["focinho"]
	perto(fl.x + fo.x, 68.0, 0.001, "espelho em torno do pivô 34")
	perto(fl.y, fo.y, 0.001, "espelho preserva altura")
	var bl: Vector2 = l["juntas"]["cauda_ponta"]
	var bo: Vector2 = o["juntas"]["cauda_ponta"]
	perto(bl.x + bo.x, 68.0, 0.001, "cauda também espelha")


func test_ancora_existe_e_some() -> void:
	var m := _rig()
	var sul := E.pose(m, "south", 0.0, "idle")
	var norte := E.pose(m, "north", 0.0, "idle")
	checar(not E.socket(m, sul, "south", "boca").is_empty(), "boca ao sul")
	checar(E.socket(m, norte, "north", "boca").is_empty(), "boca some ao norte")
	checar(E.socket(m, sul, "south", "base_cauda").is_empty(), "cauda some ao sul")
	checar(not E.socket(m, norte, "north", "base_cauda").is_empty(), "cauda ao norte")
	checar(not E.socket(m, sul, "south", "coroa").is_empty(), "coroa ao sul")
	checar(not E.socket(m, norte, "north", "coroa").is_empty(), "coroa ao norte")
	var se := E.pose(m, "south-east", 0.0, "idle")
	var ne := E.pose(m, "north-east", 0.0, "idle")
	checar(not E.socket(m, se, "south-east", "boca").is_empty(), "boca na diagonal da frente")
	checar(E.socket(m, ne, "north-east", "boca").is_empty(), "boca some na diagonal de costas")
	checar(E.socket(m, se, "south-east", "base_cauda").is_empty(), "cauda some na diagonal da frente")
	checar(not E.socket(m, ne, "north-east", "base_cauda").is_empty(), "cauda na diagonal de costas")
	checar(E.socket(m, sul, "south", "asa").is_empty(), "socket inexistente devolve vazio")


func test_ancora_decorre_da_junta() -> void:
	var m := _rig()
	var p := E.pose(m, "east", 0.0, "idle")
	var j: Dictionary = p["juntas"]
	var boca := E.socket(m, p, "east", "boca")
	perto_v(boca["pos"], j["focinho"], 0.001, "boca no focinho")
	var coroa := E.socket(m, p, "east", "coroa")
	perto_v(coroa["pos"], (j["cabeca"] as Vector2) + Vector2(0, -7), 0.001, "coroa no topo da cabeça")
	var oeste := E.pose(m, "west", 0.0, "idle")
	var boca_o := E.socket(m, oeste, "west", "boca")
	perto_v(boca_o["pos"], oeste["juntas"]["focinho"], 0.001, "espelho também desloca a âncora")


func test_passo_anda_e_fecha_o_loop() -> void:
	var m := _rig()
	var a := E.pose(m, "east", 0.25, "walk")
	var b := E.pose(m, "east", 0.75, "walk")
	var pa: Vector2 = a["juntas"]["pata_f"]
	var pb: Vector2 = b["juntas"]["pata_f"]
	checar(absf(pa.x - pb.x) > 4.0, "a pata anda entre as fases")
	var f0 := E.pose(m, "east", 0.0, "walk")
	var f1 := E.pose(m, "east", 1.0, "walk")
	perto_v(f0["juntas"]["pata_f"], f1["juntas"]["pata_f"], 0.001, "fase 0 = fase 1 (loop)")


func test_pose_nao_inventa() -> void:
	var m := _rig()
	igual(E.pose(m, "cima", 0.0, "walk").size(), 0, "direção desconhecida")
	igual(E.pose(m, "south", 0.0, "voo").size(), 0, "clipe desconhecido")


func test_rig_adulterado_falha_fechado() -> void:
	var m := _rig()
	var copia := m.duplicate(true)
	copia["canvas_px"] = [68]
	checar(E.validar(copia) != "", "canvas sem dois números")

	copia = m.duplicate(true)
	copia["profiles"]["lateral"]["bones"][0]["a"] = "fantasma"
	checar(E.validar(copia) != "", "osso com junta fantasma")

	copia = m.duplicate(true)
	copia["sockets"]["boca"]["joint"] = "inexistente"
	checar(E.validar(copia) != "", "socket apontando junta inexistente")

	copia = m.duplicate(true)
	copia["sockets"]["boca"]["z"] = "meio"
	checar(E.validar(copia) != "", "z fora de front/back")

	copia = m.duplicate(true)
	copia["clips"]["walk"]["duracao_s"] = 0
	checar(E.validar(copia) != "", "clipe sem duração")

	copia = m.duplicate(true)
	copia["directions"]["south"]["profile"] = "inexistente"
	checar(E.validar(copia) != "", "direção sem perfil")

	copia = m.duplicate(true)
	copia["directions"]["cima"] = {"profile": "lateral", "mirror": false, "costas": false}
	checar(E.validar(copia) != "", "direção desconhecida no rig")

	copia = m.duplicate(true)
	copia["envelope_px"]["altura"] = 0
	checar(E.validar(copia) != "", "envelope sem altura")


func test_json_invalido_nao_vira_rig() -> void:
	igual(E.de_json("{").size(), 0, "json quebrado")
	igual(E.de_json("[]").size(), 0, "json que não é objeto")
	igual(E.de_json("{}").size(), 0, "objeto vazio")


func test_envelope_do_canino() -> void:
	var m := _rig()
	var env := E.envelope(m)
	perto(float(env.get("altura", 0.0)), 32.0, 0.001, "altura")
	perto(float(env.get("comprimento", 0.0)), 39.0, 0.001, "comprimento")
	perto(float(env.get("largura", 0.0)), 20.0, 0.001, "largura")


func test_os_tres_rigs_das_ancoras_validam() -> void:
	for nome in ["canino", "serpente", "ave"]:
		var m := _rig_nome(nome)
		igual(E.validar(m), "", "rig sem erro: " + nome)
		igual(E.direcoes(m).size(), 8, "oito direções: " + nome)
		for dir in E.DIRECOES:
			var p := E.pose(m, dir, 0.0, "walk")
			checar(not p.is_empty(), "pose %s em %s" % [nome, dir])


func test_serpente_rasteja_sem_pernas() -> void:
	var m := _rig_nome("serpente")
	var a := E.pose(m, "east", 0.0, "walk")
	var b := E.pose(m, "east", 0.5, "walk")
	var ja: Dictionary = a["juntas"]
	var jb: Dictionary = b["juntas"]
	checar(absf((ja["s4"] as Vector2).y - (jb["s4"] as Vector2).y) > 0.5, "onda move o meio do corpo")
	checar(absf((ja["cabeca"] as Vector2).x - (jb["cabeca"] as Vector2).x) > 0.2, "cabeça acompanha a onda")
	checar(not ja.has("pata_e") and not ja.has("pata_f"), "serpente não inventa perna")
	# a diagonal também ondula
	var se := E.pose(m, "south-east", 0.0, "walk")
	var sd := E.pose(m, "south-east", 0.5, "walk")
	checar(not se.is_empty() and (se["juntas"] as Dictionary).size() == (sd["juntas"] as Dictionary).size(), "diagonal da serpente")


func test_ave_bipede_alterna_os_pes() -> void:
	var m := _rig_nome("ave")
	var a := E.pose(m, "south", 0.25, "walk")
	var b := E.pose(m, "south", 0.75, "walk")
	var ja: Dictionary = a["juntas"]
	var jb: Dictionary = b["juntas"]
	checar(absf((ja["pata_e"] as Vector2).y - (jb["pata_e"] as Vector2).y) > 0.5, "pé esquerdo alterna")
	checar(absf((ja["pata_d"] as Vector2).y - (jb["pata_d"] as Vector2).y) > 0.5, "pé direito alterna em oposição")
	perto((ja["pata_d"] as Vector2).y, 50.0, 0.001, "o pé oposto fica no chão")
	perto((jb["pata_e"] as Vector2).y, 50.0, 0.001, "e troca no meio do passo")
	var norte := E.pose(m, "north", 0.0, "idle")
	checar(E.socket(m, norte, "north", "boca").is_empty(), "bico some ao norte")
	var leste := E.pose(m, "east", 0.0, "idle")
	checar(not E.socket(m, leste, "east", "boca").is_empty(), "bico existe a leste")
