extends Node2D
## A LINHA DO CAMINHO (v0.9.2): desenhada como o traço REAL do dedo — os pontos
## densos do desenho, não a rota simplificada (que traçava retas entre os
## pontos de referência e ficava quebrada).
##
## Estilo: **PONTILHADA**, **escura e transparente**, NO CHÃO (S5b: desenhada
## no mapa do chão, `jogo/mundo3d/chao.gd`, que o terreno 3D pinta no topo das
## células — a criatura, as copas e as paredes passam por cima). Os pontinhos
## são espaçados por ARCO, então acompanham a curva de verdade, sem emendar retas.
##
## O que ela mostra é `corpo.traco` (o desenho cru, em pontos de MUNDO) — quem
## chama decide quando há linha (desenhando ou em rota).
##
## v0.11.3: `corpo.traco_t` é o arco JÁ ANDADO. A linha só desenha do corte
## para a frente, com um rabinho de `APAGAR_PX` em fade atrás — o caminho vai
## sumindo conforme o animal passa.

var pontos := PackedVector2Array()
var corte := 0.0            # arco JÁ ANDADO: a linha some atrás (v0.11.3)
## Desenha em px de MUNDO da sim; o pai (`chao.raiz`) leva a texels do mapa do
## chão, e o terreno põe cada texel no topo da sua célula (altura e câmera não
## entram aqui).

const PASSO_PX := 7.0       # distância entre os pontinhos, no arco
const RAIO := 2.1           # raio do pontinho
const COR := Color(0.04, 0.09, 0.12, 0.55)  # escura e transparente
const APAGAR_PX := 22.0     # rabinho de fade atrás do que já foi andado


func mostrar(p: PackedVector2Array, ja_andado := 0.0) -> void:
	pontos = p
	corte = maxf(ja_andado, 0.0)
	queue_redraw()


func _draw() -> void:
	if pontos.size() < 2:
		return
	var sobra := 0.0
	var arco := 0.0
	for i in range(1, pontos.size()):
		var a := pontos[i - 1]
		var b := pontos[i]
		var seg := a.distance_to(b)
		if seg < 0.0001:
			continue
		var t := sobra
		while t <= seg:
			var s := arco + t
			var a_alfa := clampf((s - (corte - APAGAR_PX)) / APAGAR_PX, 0.0, 1.0)
			if a_alfa > 0.0:
				draw_circle(a.lerp(b, t / seg), RAIO, Color(COR, COR.a * a_alfa), true, -1.0, true)
			t += PASSO_PX
		sobra = t - seg
		arco += seg
	# a ponta do caminho: um pontinho um pouco maior (o destino), se ainda falta
	if arco >= corte:
		draw_circle(pontos[pontos.size() - 1], RAIO + 1.0, Color(COR, 0.85), true, -1.0, true)
