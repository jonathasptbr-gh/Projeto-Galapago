extends "res://testes/caso.gd"

const M := preload("res://sim/mundo.gd")
const V := preload("res://sim/visibilidade.gd")

var terrenos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/terrenos.json"))


func _mundo(celulas: Array, subsolo: Array = [], objetos: Array = []) -> RefCounted:
	return M.criar({"celula_px": 32, "celulas": celulas, "subsolo": subsolo, "objetos": objetos}, terrenos)


func _c(x: int, y: int) -> Vector2:
	return Vector2(x * 32 + 16, y * 32 + 16)


func test_mapa_da_fundacao_e_valido() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/mapas/fundacao.json"))
	var m := M.criar(d, terrenos)
	igual(m.validar().size(), 0, "fundacao.json: %s" % [m.validar()])
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


## v0.12: a EXTENSÃO DE PARKOUR a leste (x=40..63). A trilha entra pela ilha
## leste, o pátio sobe por rampa ou por pulo, a passarela e a plataforma dão
## desníveis de 1 nível e a volta desce em degraus — tudo em cima de água.
func test_extensao_parkour_e_valida_e_ligada() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/mapas/fundacao.json"))
	var m := M.criar(d, terrenos)
	igual(m.validar().size(), 0, "fundacao.json (com a extensão): %s" % [m.validar()])
	igual(m.largura, 64, "extensão: 24 colunas a leste")
	checar(m.pode_andar(Vector2i(37, 11), Vector2i(38, 11), M.SUPERFICIE), "a trilha liga a ilha leste")
	checar(m.pode_andar(Vector2i(39, 11), Vector2i(40, 11), M.SUPERFICIE), "a trilha entra no pátio")
	checar(m.andavel(Vector2i(42, 11), M.SUPERFICIE), "pátio de trilha é andável")


func test_extensao_parkour_rampas_ligam_os_niveis() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/mapas/fundacao.json"))
	var m := M.criar(d, terrenos)
	igual(m.altura(Vector2i(41, 11)), 1.0, "trilha no chão")
	igual(m.altura(Vector2i(46, 11)), 2.0, "passarela um nível acima")
	igual(m.altura(Vector2i(54, 11)), 3.0, "plataforma dois níveis acima")
	igual(m.altura(Vector2i(56, 12)), 2.5, "rampa alta fica entre 2 e 3")
	checar(m.pode_andar(Vector2i(43, 13), Vector2i(44, 13), M.SUPERFICIE), "pátio entra na rampa")
	checar(m.pode_andar(Vector2i(44, 13), Vector2i(45, 13), M.SUPERFICIE), "rampa leva à passarela")
	checar(m.pode_andar(Vector2i(55, 12), Vector2i(56, 12), M.SUPERFICIE), "plataforma entra na rampa alta")
	checar(m.pode_andar(Vector2i(56, 12), Vector2i(57, 12), M.SUPERFICIE), "rampa alta desce à passarela")


func test_extensao_parkour_vaos_e_pulos() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/mapas/fundacao.json"))
	var m := M.criar(d, terrenos)
	checar(not m.andavel(Vector2i(44, 11), M.SUPERFICIE), "vão de 1 célula antes da passarela")
	checar(not m.pode_andar(Vector2i(43, 11), Vector2i(45, 11), M.SUPERFICIE), "o vão não se anda")
	checar(m.pouso_valido(_c(43, 11), _c(45, 11), M.SUPERFICIE), "pulo sobe um nível")
	checar(not m.pouso_valido(_c(43, 11), _c(54, 11), M.SUPERFICIE), "pulo não sobe dois níveis")
	checar(not m.andavel(Vector2i(51, 11), M.SUPERFICIE), "vão de 2 células antes da plataforma (1)")
	checar(not m.andavel(Vector2i(52, 11), M.SUPERFICIE), "vão de 2 células antes da plataforma (2)")
	# a volta: degraus 1→2→3→2→1, com um vão de 2 células no meio
	igual(m.altura(Vector2i(47, 16)), 2.0, "volta sobe à passarela")
	igual(m.altura(Vector2i(50, 16)), 3.0, "volta sobe à plataforma")
	igual(m.altura(Vector2i(53, 16)), 2.0, "volta desce à passarela")
	igual(m.altura(Vector2i(55, 16)), 1.0, "volta desce à trilha")
	checar(not m.andavel(Vector2i(57, 16), M.SUPERFICIE), "volta tem vão de 2 células (1)")
	checar(not m.andavel(Vector2i(58, 16), M.SUPERFICIE), "volta tem vão de 2 células (2)")
