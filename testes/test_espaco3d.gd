extends "res://testes/caso.gd"
## O espaço 3D do jogo (jogo/mundo3d/espaco.gd): px de mundo da sim + níveis
## → unidades 3D, a mesma escala da sim/natureza.gd.

const Espaco := preload("res://jogo/mundo3d/espaco.gd")
const Natureza := preload("res://sim/natureza.gd")


func test_ponto_converte_px_e_niveis() -> void:
	var p: Vector3 = Espaco.ponto(Vector2(48, 80), 2.0)
	checar(p.is_equal_approx(Vector3(1.5, 2.0 * Espaco.ALTURA_NIVEL, 2.5)), "ponto: %s" % p)


func test_mesma_escala_da_natureza() -> void:
	perto(Espaco.ALTURA_NIVEL, Natureza.ALTURA_NIVEL, 0.000001, "nível 3D igual ao da mata")
	perto(Espaco.altura_3d(1.5), 1.5 * Espaco.ALTURA_NIVEL, 0.000001, "altura_3d linear")
