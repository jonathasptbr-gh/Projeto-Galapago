extends RefCounted
## DIREÇÃO DE OLHAR → uma das 8 direções do contrato (setor de 45°).
## Lógica pura e testável: a cena não decide setor e a arte futura não muda a
## regra. Setores começam a 0° = leste e giram no sentido da tela (+y = sul),
## com o setor centrado na direção (fronteira a 22,5°).

const SETORES := [
	"east", "south-east", "south", "south-west",
	"west", "north-west", "north", "north-east"
]


## Olhar zero/inválido cai em "south" (a pose frontal, a mais neutra).
static func setor(olhar: Vector2) -> String:
	if not is_finite(olhar.x) or not is_finite(olhar.y) or olhar.length() < 0.001:
		return "south"
	var graus := fposmod(rad_to_deg(olhar.angle()), 360.0)
	var i := int(floorf((graus + 22.5) / 45.0)) % 8
	return SETORES[i]


## De qual direção o setor está mais perto (0 = leste, 1 = sudeste...).
static func indice(direcao: String) -> int:
	return SETORES.find(direcao)
