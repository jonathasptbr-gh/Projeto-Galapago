extends RefCounted
## Trajetória riscada pelo jogador — LÓGICA PURA.
##
## Camada `sim/`: nada de nó, cena, Input ou tempo real. Recebe dados, devolve
## dados; é por isso que se testa headless (testes/test_trajetoria.gd).
## Quem desenha e quem lê o toque é a camada `jogo/`.


## Descarta pontos mais próximos que `dist_min` do último mantido; o ponto
## final do traço é sempre preservado (é o destino que o jogador escolheu).
static func amostrar(pontos: PackedVector2Array, dist_min: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pontos:
		if out.is_empty() or out[out.size() - 1].distance_to(p) >= dist_min:
			out.append(p)
	if not pontos.is_empty() and out[out.size() - 1] != pontos[pontos.size() - 1]:
		out.append(pontos[pontos.size() - 1])
	return out


static func comprimento(pontos: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, pontos.size()):
		total += pontos[i - 1].distance_to(pontos[i])
	return total


## Ponto a `d` unidades do início, andando sobre a linha. `d` é limitado ao
## intervalo [0, comprimento]: fora dele, devolve a ponta correspondente.
static func ponto_em(pontos: PackedVector2Array, d: float) -> Vector2:
	if pontos.is_empty():
		return Vector2.ZERO
	if d <= 0.0 or pontos.size() == 1:
		return pontos[0]
	var resto := d
	for i in range(1, pontos.size()):
		var seg := pontos[i - 1].distance_to(pontos[i])
		if resto <= seg and seg > 0.0:
			return pontos[i - 1].lerp(pontos[i], resto / seg)
		resto -= seg
	return pontos[pontos.size() - 1]
