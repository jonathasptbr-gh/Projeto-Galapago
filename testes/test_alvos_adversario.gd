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


func test_montar_e_mais_proximo() -> void:
	var m := _mundo()
	var objetos := [{"tipo": "arvore", "celula": [2, 2]}, {"tipo": "bau", "celula": [8, 2]}]
	var out := Alvos.montar(objetos, [], m)
	igual(out.size(), 2, "dois alvos")
	checar(out[0]["travavel"], "árvore travável")
	checar(not out[1]["travavel"], "baú não é alvo")
	checar(out[1]["interativo"], "baú interativo")
	var achado := Alvos.mais_proximo(out, Vector2(80, 70), 60.0)
	igual(achado.get("id", ""), "arvore:2,2", "o mais perto")
	igual(Alvos.mais_proximo(out, Vector2(500, 400), 20.0), {}, "fora de alcance: nada")


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
