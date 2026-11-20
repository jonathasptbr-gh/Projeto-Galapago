extends "res://testes/caso.gd"

const T := preload("res://sim/trajetoria.gd")


func test_amostrar_descarta_pontos_proximos_e_guarda_o_final() -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(5, 0), Vector2(6, 0)])
	var a := T.amostrar(p, 3.0)
	igual(a, PackedVector2Array([Vector2(0, 0), Vector2(5, 0), Vector2(6, 0)]), "amostragem")


func test_amostrar_vazio() -> void:
	igual(T.amostrar(PackedVector2Array(), 3.0).size(), 0, "vazio")


func test_comprimento_de_l() -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(3, 0), Vector2(3, 4)])
	perto(T.comprimento(p), 7.0, 0.0001, "L 3+4")


func test_ponto_em_anda_sobre_os_segmentos() -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(3, 0), Vector2(3, 4)])
	perto_v(T.ponto_em(p, 0.0), Vector2(0, 0), 0.0001, "início")
	perto_v(T.ponto_em(p, 1.5), Vector2(1.5, 0), 0.0001, "meio do 1º")
	perto_v(T.ponto_em(p, 5.0), Vector2(3, 2), 0.0001, "meio do 2º")
	perto_v(T.ponto_em(p, 99.0), Vector2(3, 4), 0.0001, "além do fim = fim")
	perto_v(T.ponto_em(p, -1.0), Vector2(0, 0), 0.0001, "antes do início = início")
