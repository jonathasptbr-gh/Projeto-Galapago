extends "res://testes/caso.gd"

const M := preload("res://sim/mundo.gd")
const V := preload("res://sim/visibilidade.gd")
const N := preload("res://sim/natureza.gd")

var terrenos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/terrenos.json"))


func _mundo(celulas: Array, subsolo: Array = [], objetos: Array = []) -> RefCounted:
	return M.criar({"celula_px": 32, "celulas": celulas, "subsolo": subsolo, "objetos": objetos}, terrenos)


func _c(x: int, y: int) -> Vector2:
	return Vector2(x * 32 + 16, y * 32 + 16)


func test_mapa_natureza_e_valido() -> void:
	var d: Dictionary = N.mundo_dict()
	var m := M.criar(d, terrenos)
	igual(m.validar().size(), 0, "natureza: %s" % [m.validar()])
	checar(m.andavel(Vector2i(d["inicio"][0], d["inicio"][1]), M.SUPERFICIE), "início andável")


func test_andar_bloqueia_agua_rocha_e_tronco() -> void:
	var m := _mundo([",~,#,,"], [], [{"tipo": "arvore", "celula": [5, 0]}])
	checar(not m.pode_andar(Vector2i(0, 0), Vector2i(1, 0), M.SUPERFICIE), "água")
	checar(not m.pode_andar(Vector2i(2, 0), Vector2i(3, 0), M.SUPERFICIE), "rocha")
	checar(not m.pode_andar(Vector2i(4, 0), Vector2i(5, 0), M.SUPERFICIE), "tronco")


func test_altura_rampa() -> void:
	var m := _mundo([",^,/^"])
	checar(not m.pode_andar(Vector2i(0, 0), Vector2i(1, 0), M.SUPERFICIE), "chão→planalto direto não")
	checar(m.pode_andar(Vector2i(2, 0), Vector2i(3, 0), M.SUPERFICIE), "chão→rampa")
	checar(m.pode_andar(Vector2i(3, 0), Vector2i(4, 0), M.SUPERFICIE), "rampa→planalto")


func test_limitar_caminho_para_na_agua() -> void:
	var m := _mundo([",,,~~,,"])
	var c: PackedVector2Array = m.limitar_caminho(PackedVector2Array([_c(0, 0), _c(6, 0)]), M.SUPERFICIE)
	checar(c[c.size() - 1].x < 3 * 32, "parou antes da água (x=%s)" % c[c.size() - 1].x)
	checar(c[c.size() - 1].x > 2 * 32, "andou até a beira")


func test_pulo_atravessa_canal_e_sobe_um_nivel() -> void:
	var m := _mundo([",,~~,,", ",,~~^^"])
	var p: Vector2 = m.pouso(_c(1, 0), _c(4, 0), 84.0, M.SUPERFICIE)
	igual(m.celula_de(p), Vector2i(4, 0), "pousa do outro lado do canal")
	p = m.pouso(_c(1, 0), _c(5, 0), 84.0, M.SUPERFICIE)
	checar(m.celula_de(p).x <= 4, "alcance limita")
	checar(m.pouso_valido(_c(1, 1), _c(4, 1), M.SUPERFICIE), "sobe 1 nível pulando")
	p = m.pouso(_c(1, 0), _c(2, 0) + Vector2(10, 0), 84.0, M.SUPERFICIE)
	checar(m.andavel(m.celula_de(p), M.SUPERFICIE), "alvo na água: pousa antes, em terra")


func test_escavar_desce_anda_no_tunel_e_sobe() -> void:
	var m := _mundo([":,,,:"], ["=====", ])
	checar(m.pode_escavar(Vector2i(0, 0), M.SUPERFICIE), "terra fofa escava")
	checar(not m.pode_escavar(Vector2i(1, 0), M.SUPERFICIE), "grama não")
	igual(m.escavar(Vector2i(0, 0), M.SUPERFICIE), M.SUBSOLO, "desceu")
	checar(m.pode_andar(Vector2i(0, 0), Vector2i(1, 0), M.SUBSOLO), "anda no túnel")
	checar(m.pode_escavar(Vector2i(4, 0), M.SUBSOLO), "sobe sob terra fofa")
	checar(not m.pode_escavar(Vector2i(2, 0), M.SUBSOLO), "não sobe sob grama")


func test_alfa_da_copa() -> void:
	perto(V.alfa_cobertura(0.0, 40.0), 0.28, 0.001, "embaixo: quase transparente")
	perto(V.alfa_cobertura(200.0, 40.0), 1.0, 0.001, "longe: opaca")
	var meio: float = V.alfa_cobertura(52.0, 40.0)
	checar(meio > 0.28 and meio < 1.0, "transição suave (%s)" % meio)


## v0.6: o corpo distingue OBJETO (dá para desviar) de TERRENO (barreira; só
## o pulo passa) para decidir entre contornar e parar.
func test_bloqueio_distingue_objeto_de_terreno() -> void:
	var m := _mundo([",~,#,"], [], [{"tipo": "arvore", "celula": [4, 0]}])
	igual(m.bloqueio(Vector2i(0, 0), M.SUPERFICIE), "", "livre")
	igual(m.bloqueio(Vector2i(1, 0), M.SUPERFICIE), "terreno", "água")
	igual(m.bloqueio(Vector2i(3, 0), M.SUPERFICIE), "terreno", "rocha")
	igual(m.bloqueio(Vector2i(4, 0), M.SUPERFICIE), "objeto", "tronco")
	igual(m.bloqueio(Vector2i(0, 0), M.SUBSOLO), "terreno", "sem túnel no subsolo")


func test_caminho_livre() -> void:
	var m := _mundo([",,,~~,,"])
	checar(m.caminho_livre(_c(0, 0), _c(2, 0), M.SUPERFICIE), "até a beira da água")
	checar(not m.caminho_livre(_c(0, 0), _c(4, 0), M.SUPERFICIE), "atravessar a água não")
