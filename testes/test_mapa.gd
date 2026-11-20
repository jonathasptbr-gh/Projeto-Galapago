extends "res://testes/caso.gd"

const M := preload("res://sim/mapa.gd")


func test_niveis_e_desconhecido() -> void:
	var g := M.niveis(PackedStringArray(["~.", ",^", "x~"]))
	igual(g[0], [0, 1], "linha 0")
	igual(g[1], [2, 3], "linha 1")
	igual(g[2][0], -1, "desconhecido")


func test_validar_aceita_degrau_de_um() -> void:
	var g := M.niveis(PackedStringArray(["~~.", "~..", "..,"]))
	igual(M.validar(g).size(), 0, "degraus de um nível")


func test_validar_reprova_salto_de_dois() -> void:
	var g := M.niveis(PackedStringArray(["~,", "~~"]))
	var e := M.validar(g)
	igual(e.size(), 1, "mar encostando em grama")
	checar(e[0].begins_with("célula (0,0)"), "mensagem aponta a célula")


func test_validar_largura_diferente() -> void:
	igual(M.validar(M.niveis(PackedStringArray(["~~~", "~~"]))).size(), 1, "largura")


func test_peca_um_nivel() -> void:
	var g := M.niveis(PackedStringArray(["~~", "~~"]))
	igual(M.peca(g, 0, 0), {"par": 0, "chave": "lower,lower,lower,lower"}, "mar puro")
	g = M.niveis(PackedStringArray([",,", ",,"]))
	igual(M.peca(g, 0, 0), {"par": 1, "chave": "upper,upper,upper,upper"}, "grama pura = topo do par areia↔grama")


func test_peca_transicao() -> void:
	# NW e NE areia, SW e SE mar → par 0, de cima "upper"
	var g := M.niveis(PackedStringArray(["..", "~~"]))
	igual(M.peca(g, 0, 0), {"par": 0, "chave": "upper,upper,lower,lower"}, "praia ao norte")
	g = M.niveis(PackedStringArray([",^", ",,"]))
	igual(M.peca(g, 0, 0), {"par": 2, "chave": "lower,upper,lower,lower"}, "planalto a nordeste")


func test_indice_cantos() -> void:
	var tiles := [{"corners": {"NW": "upper", "NE": "lower", "SW": "lower", "SE": "lower"},
		"bounding_box": {"x": 32, "y": 64, "width": 32, "height": 32}}]
	var idx := M.indice_cantos(tiles)
	igual(idx.get("upper,lower,lower,lower"), Rect2i(32, 64, 32, 32), "retângulo")


func test_desenho_da_ilha_e_valido() -> void:
	var dados: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/mapas/ilha_teste.json"))
	var e := M.validar(M.niveis(PackedStringArray(dados["pontos"])))
	igual(e.size(), 0, "ilha_teste: %s" % [e])
