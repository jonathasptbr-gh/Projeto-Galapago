extends RefCounted
## Trajetória riscada pelo jogador — LÓGICA PURA.
##
## Camada `sim/`: nada de nó, cena, Input ou tempo real. Recebe dados, devolve
## dados; é por isso que se testa headless (testes/test_trajetoria.gd).
## Quem desenha e quem lê o toque é a camada `jogo/`.
##
## v0.6: o traço não é mais seguido ponto a ponto. Ele é (1) descartado no
## começo quando tem aquele vai-e-volta de alinhamento (`descontar_inicio`) e
## (2) reduzido a POUCOS pontos de referência (`simplificar`, Douglas-Peucker):
## o corpo procura cada ponto na ordem e pode se desviar um pouco para
## contornar objetos. Ver docs/gdd/gestos-e-acoes.md.

## Distância mínima entre pontos amostrados; o ponto final é sempre preservado.
static func amostrar(pontos: PackedVector2Array, dist_min: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pontos:
		if out.is_empty() or out[out.size() - 1].distance_to(p) >= dist_min:
			out.append(p)
	if not pontos.is_empty() and out[out.size() - 1] != pontos[pontos.size() - 1]:
		out.append(pontos[pontos.size() - 1])
	return out


## Douglas-Peucker: mantém os pontos que fazem a forma se afastar do SEGMENTO
## entre as pontas em mais de `tolerancia` px. Numa reta sobram só as pontas;
## uma curva ou um canto continuam com alguns pontos. O primeiro e o último
## sempre ficam.
##
## v0.9: a distância é ao SEGMENTO, não à reta infinita. Um ponto que passa da
## PONTA do segmento conta como fora — é o que preserva a ponta de um BICO
## (ida e volta brusca) na rota: sem isso, a ida e a volta se anulavam na reta
## e a criatura nunca chegava a fazer o bico.
static func simplificar(pontos: PackedVector2Array, tolerancia: float) -> PackedVector2Array:
	if pontos.size() < 3 or tolerancia <= 0.0:
		return pontos
	return _rdp(pontos, 0, pontos.size() - 1, tolerancia)


static func _rdp(pontos: PackedVector2Array, ini: int, fim: int, tolerancia: float) -> PackedVector2Array:
	var a := pontos[ini]
	var b := pontos[fim]
	var maior := 0.0
	var corte := -1
	for i in range(ini + 1, fim):
		var d := _distancia_reta(pontos[i], a, b)
		if d > maior:
			maior = d
			corte = i
	if corte == -1 or maior <= tolerancia:
		return PackedVector2Array([a, b])
	var esq := _rdp(pontos, ini, corte, tolerancia)
	var dir := _rdp(pontos, corte, fim, tolerancia)
	var out := esq
	for i in range(1, dir.size()):
		out.append(dir[i])
	return out


static func _distancia_reta(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.000001:
		return p.distance_to(a)
	# distância ao SEGMENTO: fora das pontas, vale a distância à ponta mais perto
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


## O "desconto inicial": tira o pequeno vai-e-volta que o dedo faz no ponto de
## partida ao começar a desenhar. Só corta quando houve uma VOLTA de verdade
## (a distância ao início diminuiu pelo menos 6 px) e quando o corte cabe em
## `janela` px de traço. O destino e o começo são sempre preservados; a reta
## entre o início e o ponto de alinhamento é conferida pelo chamador (não pode
## atravessar parede). Depois do início, idas e vindas são permitidas.
static func descontar_inicio(pontos: PackedVector2Array, raio: float, janela: float) -> PackedVector2Array:
	if pontos.size() < 3:
		return pontos
	var p0 := pontos[0]
	var arco := 0.0
	var anterior := 0.0
	var ultimo_perto := -1
	var houve_volta := false
	for i in pontos.size():
		var d := p0.distance_to(pontos[i])
		if i > 0:
			arco += pontos[i - 1].distance_to(pontos[i])
			if arco <= janela and d < anterior - 6.0:
				houve_volta = true
		if arco <= janela and d <= raio:
			ultimo_perto = i
		anterior = d
	if not houve_volta or ultimo_perto < 1 or ultimo_perto >= pontos.size() - 1:
		return pontos
	var out := PackedVector2Array([p0])
	for i in range(ultimo_perto + 1, pontos.size()):
		out.append(pontos[i])
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
