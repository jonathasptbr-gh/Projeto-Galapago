extends "res://testes/caso.gd"
## Setores de 45°: as oito direções do contrato sem a cena decidir nada.

const D := preload("res://sim/direcao.gd")


func test_cardinais() -> void:
	igual(D.setor(Vector2.RIGHT), "east", "leste")
	igual(D.setor(Vector2.DOWN), "south", "sul")
	igual(D.setor(Vector2.LEFT), "west", "oeste")
	igual(D.setor(Vector2.UP), "north", "norte")


func test_diagonais() -> void:
	igual(D.setor(Vector2(1, 1)), "south-east", "sudeste")
	igual(D.setor(Vector2(1, -1)), "north-east", "nordeste")
	igual(D.setor(Vector2(-1, 1)), "south-west", "sudoeste")
	igual(D.setor(Vector2(-1, -1)), "north-west", "noroeste")


func test_zero_cai_no_sul() -> void:
	igual(D.setor(Vector2.ZERO), "south", "sem olhar")
	igual(D.setor(Vector2(NAN, 0)), "south", "não finito")


func test_fronteira_de_225() -> void:
	# 22,5° ainda é leste; 22,6° já é sudeste (setor centrado na direção)
	var quase := Vector2.from_angle(deg_to_rad(22.4))
	var passou := Vector2.from_angle(deg_to_rad(22.6))
	igual(D.setor(quase), "east", "antes da fronteira")
	igual(D.setor(passou), "south-east", "depois da fronteira")


func test_volta_completa_percorre_os_oito() -> void:
	var vistos := {}
	for i in 72:
		vistos[D.setor(Vector2.from_angle(deg_to_rad(float(i) * 5.0)))] = true
	igual(vistos.size(), 8, "cinco em cinco graus cobre os oito setores")


func test_indice() -> void:
	igual(D.indice("east"), 0, "leste é 0")
	igual(D.indice("south"), 2, "sul é 2")
	igual(D.indice("north-east"), 7, "nordeste é 7")
	igual(D.indice("cima"), -1, "nome inválido")
