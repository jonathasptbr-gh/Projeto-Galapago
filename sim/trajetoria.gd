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
##
## v0.11.1: `limpar_amontoados` corta os trechos que voltam para dentro de uma
## ZONA DO TAMANHO DO ANIMAL (um laço/cruzamento minúsculo, uma ida e volta
## nervosa): a rota conecta o começo do amontoado direto ao ponto onde ele
## retorna — o animal não fica "remexendo" ali. Laços e bicos GRANDES não são
## tocados (o traço desenhado é obedecido).

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


## AMONTOADOS (v0.11.1): corta o trecho que sai e VOLTA para dentro de `raio`
## px em menos de `janela` px de arco. É o laço minúsculo, o cruzamento sem
## intenção e o vai-e-volta nervoso que não devem ser andados (nem acender a
## habilidade de área). A rota passa a ligar `p[i]` direto ao ponto `p[j]` onde
## o traço retorna à zona; o desenho grande (laço, bico, curva) fica intacto.
##
## O teste do "amontoado" é o RETORNO, não a proximidade: exige que o arco
## gasto seja bem maior que a distância líquida (`arco >= d*1.8 + 12`) — numa
## reta ou numa curva de verdade o arco e a distância são quase iguais, e nada
## é cortado.
##
## `livre` (opcional) é `func(a, b) -> bool`: só corta se o atalho for andável
## (o corpo passa `mundo.caminho_livre`, para não pular um tronco/água).
static func limpar_amontoados(pontos: PackedVector2Array, raio: float, janela: float,
		livre := Callable()) -> PackedVector2Array:
	if pontos.size() < 3 or raio <= 0.0 or janela <= 0.0:
		return pontos
	var arco := arcos_pontos(pontos)
	var out := PackedVector2Array([pontos[0]])
	var i := 0
	var n := pontos.size()
	while i < n - 1:
		var melhor_j := -1
		var j := i + 2
		while j < n and arco[j] - arco[i] <= janela:
			var d := pontos[i].distance_to(pontos[j])
			var gasto := arco[j] - arco[i]
			if d <= raio and gasto >= d * 1.8 + 12.0:
				if not livre.is_valid() or bool(livre.call(pontos[i], pontos[j])):
					melhor_j = j
			j += 1
		if melhor_j > i + 1:
			# o vai-e-volta COMEÇA em `p[i]`: liga o ponto ANTERIOR direto ao
			# ponto onde o traço retorna — sem isso sobrava o "espinho" de
			# entrada do amontoado na rota.
			var corta_ancora := out.size() >= 2 and out[out.size() - 1] == pontos[i]
			if corta_ancora and livre.is_valid():
				corta_ancora = bool(livre.call(out[out.size() - 2], pontos[melhor_j]))
			if corta_ancora:
				out.remove_at(out.size() - 1)
			if out[out.size() - 1] != pontos[melhor_j]:
				out.append(pontos[melhor_j])
			i = melhor_j
		else:
			i += 1
			if out[out.size() - 1] != pontos[i]:
				out.append(pontos[i])
	return out


## Comprimento de arco acumulado em cada ponto (arcos_pontos[0] = 0). Igual ao
## `sim/formas.arcos`, repetido aqui para a trajetória não depender das formas.
static func arcos_pontos(pontos: PackedVector2Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if pontos.is_empty():
		return out
	out.append(0.0)
	for i in range(1, pontos.size()):
		out.append(out[i - 1] + pontos[i - 1].distance_to(pontos[i]))
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
