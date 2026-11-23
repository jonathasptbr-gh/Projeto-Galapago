extends "res://testes/caso.gd"
## Contrato do esqueleto: o rig do canino valida, a pose responde nas quatro
## direções, o pé fica no chão, o espelho não desloca e a âncora ausente NÃO
## herda posição. Rig adulterado falha fechado.

const E := preload("res://sim/esqueleto.gd")
const CAMINHO := "res://dados/rig/canino.json"


func _rig() -> Dictionary:
	var texto := FileAccess.get_file_as_string(CAMINHO)
	checar(not texto.is_empty(), "rig legível em " + CAMINHO)
	var m := E.de_json(texto)
	checar(not m.is_empty(), "rig válido (de_json)")
	return m


func test_rig_do_projeto_valida() -> void:
	var m := _rig()
	igual(E.validar(m), "", "canino sem erro")
	igual(E.direcoes(m).size(), 4, "quatro direções")
	perto(E.duracao(m, "walk"), 0.5, 0.001, "duração do passo")
	perto(E.duracao(m, "idle"), 1.0, 0.001, "duração do parado")


func test_pose_tem_juntas_nas_quatro_direcoes() -> void:
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


func test_espelho_nao_desloca() -> void:
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
