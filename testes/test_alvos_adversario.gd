extends "res://testes/caso.gd"

const Alvos := preload("res://sim/alvos.gd")
const Adversario := preload("res://sim/adversario.gd")
const M := preload("res://sim/mundo.gd")

var terrenos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/terrenos.json"))


func _mundo() -> RefCounted:
	var linhas: Array = []
	for y in 6:
		linhas.append(",,,,,,,,,,")
	return M.criar({"celula_px": 32, "celulas": linhas}, terrenos)


func test_montar_alvos_dos_objetos() -> void:
	var m := _mundo()
	var objetos := [{"tipo": "arvore", "celula": [2, 2]}, {"tipo": "tronco", "celula": [8, 2]}]
	var out := Alvos.montar(objetos, [], m)
	igual(out.size(), 2, "dois alvos")
	igual(out[0]["id"], "arvore:2,2", "id = tipo:célula")
	checar(out[0]["travavel"], "árvore travável")
	checar(not out[1]["travavel"], "tronco não é alvo")
	checar(not out[0].has("interativo"), "o baú interativo saiu")
	perto_v(Alvos.pos_de(out, "arvore:2,2"), m.centro(Vector2i(2, 2)) + Vector2(0, 6), 0.001, "posição pelo id")


func test_sincronizar_move_o_alvo_do_adversario() -> void:
	var m := _mundo()
	var adv := Adversario.new(3)
	adv.pos = Vector2(100, 100)
	var out := Alvos.montar([], [adv], m)
	igual(int(Alvos.pos_de(out, "adversario:0").x), 100, "posição inicial")
	adv.pos = Vector2(150, 120)
	Alvos.sincronizar(out, [adv])
	igual(int(Alvos.pos_de(out, "adversario:0").x), 150, "acompanhou o alvo móvel")


func test_adversario_vagueia_deterministico_e_fica_no_mapa() -> void:
	var m := _mundo()
	var a := Adversario.new(11)
	var b := Adversario.new(11)
	a.pos = Vector2(150, 100)
	b.pos = Vector2(150, 100)
	for i in 300:
		a.passo(1.0 / 30.0, m)
		b.passo(1.0 / 30.0, m)
	perto_v(a.pos, b.pos, 0.001, "mesma semente, mesmo passeio")
	checar(a.pos.distance_to(Vector2(150, 100)) > 20.0, "andou de verdade (%s)" % a.pos)
	checar(m.andavel(m.celula_de(a.pos), M.SUPERFICIE), "ficou em chão andável")


func test_adversario_nao_entra_na_agua() -> void:
	var linhas: Array = [",,,,,,,,,,", ",,~~,,,,,,", ",,,,,,,,,,"]
	var m := M.criar({"celula_px": 32, "celulas": linhas}, terrenos)
	var adv := Adversario.new(4)
	adv.pos = Vector2(48, 48)  # célula (1,1), à esquerda da água em x=2..3
	for i in 600:
		adv.passo(1.0 / 30.0, m)
		checar(m.andavel(m.celula_de(adv.pos), M.SUPERFICIE), "nunca na água (pos %s)" % adv.pos)


## v0.9: o adversário leva empurrão e PISCA (sem vida ainda).
func test_empurrao_move_e_pisca() -> void:
	var m := _mundo()
	var adv := Adversario.new(3)
	adv.pos = Vector2(100, 48)
	var out := Alvos.montar([], [adv], m)
	checar(Alvos.reage(out[0]), "adversário reage a golpe")
	checar(Alvos.empurrar(out, "adversario:0", Vector2.RIGHT, 30.0), "empurrou")
	checar(adv.piscando(), "pisca no acerto")
	for i in 20:
		adv.passo(1.0 / 30.0, m)
	checar(adv.pos.x > 115.0, "saiu empurrado (%s)" % adv.pos)
	checar(not adv.empurrado(), "o empurrão acaba")
	checar(not adv.piscando(), "a piscada acaba")


func test_arvore_e_tronco_nao_reagem() -> void:
	var m := _mundo()
	var objetos := [{"tipo": "arvore", "celula": [2, 2]}, {"tipo": "tronco", "celula": [8, 2]}]
	var out := Alvos.montar(objetos, [], m)
	checar(not Alvos.reage(out[0]), "árvore não reage")
	checar(not Alvos.empurrar(out, "arvore:2,2", Vector2.RIGHT, 20.0), "árvore não é empurrada")
