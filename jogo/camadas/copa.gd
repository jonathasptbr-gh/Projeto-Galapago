extends Node2D
## COPA de árvore — subcamada de VISIBILIDADE (mockup em xadrez verde).
## Fica numa camada acima de tudo: longe da criatura, opaca, esconde o que há
## embaixo (o baú do bosque); com a criatura por baixo ou ao lado, quase
## transparente. A conta é da sim/visibilidade.gd (testada).

const V := preload("res://sim/visibilidade.gd")
const Mock := preload("res://jogo/mock.gd")

var raio := 46.0
var base := Vector2.ZERO  # onde o tronco toca o chão (mundo)
var alfa := 1.0


## Centro visual da copa: acima do tronco.
func centro() -> Vector2:
	return base + Vector2(0, -34)


func atualizar(pos_criatura: Vector2, dt: float, escondida := false) -> void:
	# distância medida no CHÃO, do pé da criatura ao centro projetado da copa
	var alvo := 0.15 if escondida else V.alfa_cobertura(pos_criatura.distance_to(base + Vector2(0, -16)), raio * 0.8)
	alfa = V.aproximar(alfa, alvo, dt)
	modulate.a = alfa


func _draw() -> void:
	var c := centro()
	var casa := 8.0
	var a := Color("#2f6b2a")
	var b := Color("#3e8a37")
	var r := raio
	var y := -r
	while y < r:
		var x := -r
		while x < r:
			var meio := Vector2(x + casa / 2.0, y + casa / 2.0)
			if meio.length() <= r:
				var par := int(floor((x + r) / casa) + floor((y + r) / casa)) % 2 == 0
				draw_rect(Rect2(c + Vector2(x, y), Vector2(casa, casa)), a if par else b)
			x += casa
		y += casa
	draw_arc(c, r, 0.0, TAU, 48, Color(0.1, 0.25, 0.1, 0.9), 2.0, true)
