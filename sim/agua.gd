extends RefCounted
## ÁGUA DE GRADE (ensaio do P27) — LÓGICA PURA (sem nó, sem desenho).
##
## Cada célula guarda a ALTURA do chão (`chao`, unidades) e a PROFUNDIDADE de
## água (`agua`, unidades). A cada `passo(dt)` a água escorre para as vizinhas
## (4-vizinhança) cuja SUPERFÍCIE (chão + água) é mais baixa, evapora devagar e
## deixa o chão úmido (`umidade` 0..1, que seca mais devagar ainda). Não é
## simulação de fluido: é "física mínima" barata e determinística (sem
## sorteio), alguns milhares de células poucas vezes por segundo.
##
## - `fonte(c, vazao)`: célula que recebe água (unidades/s) — o jato.
## - `rio(c, nivel)`: célula de riacho com profundidade FIXA: recebe o que
##   chega e devolve o que falta (o riacho leva embora a água que entra).
## - `fluxo[i]`: para onde a água da célula está indo (Vector2 x/z, suavizado);
##   o desenho usa para correr os filetes.
## - Conservação: sem fontes, rios e evaporação a soma de `agua` não muda.

## MODELO DE CANOS VIRTUAIS (o usual em jogos para água rasa): cada célula
## guarda o fluxo de saída para cada vizinha; o fluxo ganha embalo com a
## diferença de superfície (GRAVIDADE) e perde com o ATRITO, e nunca tira mais
## água do que a célula tem — por isso conserva e não fica negativo.
const GRAVIDADE := 9.0
## fração do fluxo que sobrevive a cada segundo (o resto é atrito)
const ATRITO := 0.25
## maior subpasso (s): acima disso o passo é dividido
const SUBPASSO_MAX := 0.025
## evaporação (unidades/s) e profundidade abaixo da qual a célula seca
const EVAPORA := 0.012
const SECO := 0.002
## fluxo (unidades³/s) a partir do qual a água conta como correnteza (evapora
## só 15% do normal)
const CORRENTE := 0.25
## quanto de água deixa o chão totalmente úmido, e quanto a umidade seca por s
const ENCHARCA := 0.04
const SECA_UMIDADE := 0.08
## suavização do vetor de fluxo (por segundo)
const SUAVE_FLUXO := 6.0

var largura := 0
var altura := 0
var chao := PackedFloat32Array()
var agua := PackedFloat32Array()
var umidade := PackedFloat32Array()
var fluxo := PackedVector2Array()
## fluxo de saída por vizinha: índice × 4 (+x, −x, +z, −z), em unidades³/s
var canos := PackedFloat32Array()
var fontes := {}   # índice -> vazão (unidades/s)
var rios := {}     # índice -> profundidade fixa
var evaporacao := EVAPORA


func _init(w: int, h: int) -> void:
	largura = w
	altura = h
	chao.resize(w * h)
	agua.resize(w * h)
	umidade.resize(w * h)
	fluxo.resize(w * h)
	canos.resize(w * h * 4)


func indice(c: Vector2i) -> int:
	return c.y * largura + c.x


func dentro(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < largura and c.y < altura


func definir_chao(c: Vector2i, h: float) -> void:
	chao[indice(c)] = h


func fonte(c: Vector2i, vazao: float) -> void:
	if vazao <= 0.0:
		fontes.erase(indice(c))
	else:
		fontes[indice(c)] = vazao


func rio(c: Vector2i, nivel: float) -> void:
	rios[indice(c)] = nivel
	agua[indice(c)] = nivel


func total() -> float:
	var s := 0.0
	for a in agua:
		s += a
	return s


## Um passo de `dt` segundos (dividido em subpassos de até SUBPASSO_MAX).
func passo(dt: float) -> void:
	var n := maxi(1, ceili(dt / SUBPASSO_MAX))
	for _i in range(n):
		_subpasso(dt / n)


func _subpasso(dt: float) -> void:
	var vizinhos: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var guarda := pow(ATRITO, dt)
	# 1) fluxos de saída: embalo + gravidade, limitados à água da célula
	for y in range(altura):
		for x in range(largura):
			var i := y * largura + x
			var s := chao[i] + agua[i]
			var soma := 0.0
			for k in range(4):
				var v := Vector2i(x, y) + vizinhos[k]
				var f := 0.0
				if dentro(v):
					var j := v.y * largura + v.x
					f = maxf(0.0, canos[i * 4 + k] * guarda + dt * GRAVIDADE * (s - chao[j] - agua[j]))
				canos[i * 4 + k] = f
				soma += f
			if soma > 0.0:
				var escala := minf(1.0, agua[i] / (soma * dt))
				if escala < 1.0:
					for k in range(4):
						canos[i * 4 + k] *= escala
	# 2) volumes: entra o que as vizinhas mandam, sai o que esta manda
	var nova := agua.duplicate()
	for y in range(altura):
		for x in range(largura):
			var i := y * largura + x
			var sai := 0.0
			var vetor := Vector2.ZERO
			for k in range(4):
				var f := canos[i * 4 + k]
				sai += f
				vetor += Vector2(vizinhos[k]) * f
				var v := Vector2i(x, y) + vizinhos[k]
				if f > 0.0 and dentro(v):
					nova[v.y * largura + v.x] += f * dt
			nova[i] -= sai * dt
			fluxo[i] = fluxo[i].lerp(vetor, clampf(SUAVE_FLUXO * dt, 0.0, 1.0))
	for i in range(agua.size()):
		agua[i] = maxf(0.0, nova[i])
	for i in fontes:
		agua[i] += float(fontes[i]) * dt
	for i in range(agua.size()):
		if rios.has(i):
			agua[i] = float(rios[i])
			continue
		if agua[i] > 0.0 and evaporacao > 0.0:
			# a água PARADA é a que seca à vista; correnteza quase não perde
			var parada := 1.0 - clampf(fluxo[i].length() / CORRENTE, 0.0, 0.85)
			agua[i] = maxf(0.0, agua[i] - evaporacao * parada * dt)
			# a película fina some de vez (é evaporação: sem ela, conserva)
			if agua[i] < SECO and not fontes.has(i):
				agua[i] = 0.0
				for k in range(4):
					canos[i * 4 + k] = 0.0
		var molhado := clampf(agua[i] / ENCHARCA, 0.0, 1.0)
		umidade[i] = maxf(molhado, umidade[i] - SECA_UMIDADE * dt)
