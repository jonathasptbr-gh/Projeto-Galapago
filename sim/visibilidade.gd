extends RefCounted
## SUBCAMADAS DE VISIBILIDADE — LÓGICA PURA.
##
## Copa de árvore (e tudo que fica POR CIMA do mundo: telhado, ponte, arco):
## longe, opaca — esconde o que está embaixo; com a criatura passando por
## baixo ou ao lado, quase transparente — deixa ver. Entre os dois, uma
## transição suave (smoothstep), para não piscar na borda.


## Opacidade da cobertura. `dist` = distância da criatura ao centro da
## cobertura (no chão). Dentro de `raio` → `alfa_min`; além de `raio + faixa`
## → 1.0; no meio, transição suave.
static func alfa_cobertura(dist: float, raio: float, faixa := 24.0, alfa_min := 0.28) -> float:
	var u := clampf((dist - raio) / maxf(faixa, 0.001), 0.0, 1.0)
	u = u * u * (3.0 - 2.0 * u)
	return lerpf(alfa_min, 1.0, u)


## Aproxima o valor atual do alvo sem saltos (para animar quadro a quadro).
static func aproximar(atual: float, alvo: float, dt: float, velocidade := 6.0) -> float:
	return lerpf(atual, alvo, 1.0 - exp(-velocidade * dt))
