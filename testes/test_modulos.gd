extends "res://testes/caso.gd"
## Módulos/efeitos presos a socket: nome resolve posição, socket ausente não
## desenha, e nada pode conceder habilidade.

const Mods := preload("res://sim/modulos.gd")
const E := preload("res://sim/esqueleto.gd")
const A := preload("res://sim/animacao.gd")
const CAMINHO := "res://dados/modulos.json"
const RIG := "res://dados/rig/"


func _cat() -> Dictionary:
	var texto := FileAccess.get_file_as_string(CAMINHO)
	checar(not texto.is_empty(), "catálogo legível")
	var m := Mods.de_json(texto)
	checar(not m.is_empty(), "catálogo válido")
	return m


func _rig(nome: String) -> Dictionary:
	return E.de_json(FileAccess.get_file_as_string(RIG + nome + ".json"))


func test_catalogo_valido() -> void:
	var m := _cat()
	igual(Mods.validar(m), "", "sem erro")
	igual((m["modulos"] as Dictionary).size(), 3, "três módulos")
	igual((m["efeitos"] as Dictionary).size(), 3, "três efeitos")


func test_modulo_usa_o_socket_do_rig() -> void:
	var m := _cat()
	var rig := _rig("canino")
	var pose := E.pose(rig, "east", 0.0, "idle")
	var r := Mods.resolver(m, "tufo", rig, pose, "east")
	checar(not r.is_empty(), "tufo resolvido")
	var coroa := E.socket(rig, pose, "east", "coroa")
	perto_v(r["pos"], coroa["pos"], 0.001, "tufo na coroa")
	igual(String(r["z"]), "front", "tufo na frente")
	igual((Mods.aplicaveis(m, rig, pose, "east") as PackedStringArray).size(), 2, "canino aceita tufo e espinho")


func test_socket_ausente_nao_desenha() -> void:
	var m := _cat()
	var rig := _rig("canino")
	var sul := E.pose(rig, "south", 0.0, "idle")
	igual(Mods.resolver(m, "espinho_cauda", rig, sul, "south").size(), 0, "cauda oculta ao sul")
	igual(Mods.resolver(m, "asa_membrana", rig, sul, "south").size(), 0, "canino não tem dorso")
	var serp := _rig("serpente")
	var pose_serp := E.pose(serp, "east", 0.0, "idle")
	checar(not Mods.resolver(m, "asa_membrana", serp, pose_serp, "east").is_empty(), "serpente tem dorso")


func test_modulo_nao_concede_habilidade() -> void:
	var m := _cat()
	var torto := m.duplicate(true)
	torto["modulos"]["tufo"]["concede_habilidade"] = true
	checar(Mods.validar(torto) != "", "módulo que concede é recusado")
	var efeito_torto := m.duplicate(true)
	efeito_torto["efeitos"]["dano"]["concede_habilidade"] = true
	checar(Mods.validar(efeito_torto) != "", "efeito que concede é recusado")


func test_janela_de_evento_por_tempo() -> void:
	var anim := A.de_json(FileAccess.get_file_as_string("res://dados/animacoes.json"))
	checar(not anim.is_empty(), "catálogo de animação válido")
	igual(A.janela_ativa(anim, "bite", 0.0).size(), 0, "antes da janela")
	igual(A.janela_ativa(anim, "bite", 200.0).size(), 1, "dentro da janela")
	igual(A.janela_ativa(anim, "bite", 400.0).size(), 0, "depois da janela")
	var e := A.janela_ativa(anim, "bite", 200.0)
	if not e.is_empty():
		igual(String(e[0]["socket"]), "boca", "evento ancorado na boca")


func test_efeito_tem_forma_e_cor() -> void:
	var m := _cat()
	var e := Mods.efeito(m, "dano")
	checar(not e.is_empty(), "efeito dano existe")
	igual(String(e.get("forma", "")), "faisca", "faísca")
	checar(e.get("concede_habilidade") == false, "efeito não concede")
