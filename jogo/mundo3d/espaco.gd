extends RefCounted
## ESPAÇO 3D do jogo: a conversão da sim (px de mundo + altura em NÍVEIS de
## `dados/terrenos.json`) para unidades 3D. Herdado da antiga ilha da Fundação
## (removida em 2026-11-27): o mapa NATUREZA, os atores, a câmera e as
## sobreposições usam a mesma escala.
##
## - 1 unidade = 1 célula = 32 px da sim (`sim/camera3d.gd`, `para_3d`); Y para
##   cima.
## - `ALTURA_NIVEL` unidades por nível (0 mar, 1 chão, 2 planalto; o mesmo de
##   `sim/natureza.gd`).

const Cam := preload("res://sim/camera3d.gd")

const ALTURA_NIVEL := 0.4


## níveis de terreno → unidades 3D
static func altura_3d(niveis: float) -> float:
	return niveis * ALTURA_NIVEL


## px de mundo da sim + altura em níveis → ponto 3D
static func ponto(q_px: Vector2, niveis := 0.0) -> Vector3:
	return Cam.para_3d(q_px, altura_3d(niveis))
