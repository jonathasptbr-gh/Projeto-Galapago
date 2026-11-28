extends RefCounted
## Arbitragem do contato: uma pinça bloqueia todos os dedos até esvaziar.
const ZOOM_MIN := 1.6
const ZOOM_MAX := 3.2
var dedos := {}
var bloqueado := false
var distancia_inicial := 0.0
var zoom_inicial := ZOOM_MIN
var zoom := ZOOM_MIN
var par := []

func descer(id: int, p: Vector2) -> String:
	if dedos.has(id):
		return "ignorar"
	dedos[id] = p
	if dedos.size() == 1 and not bloqueado:
		return "principal"
	if dedos.size() == 2 and not bloqueado:
		bloqueado = true
		par = dedos.keys()
		var pontos := dedos.values()
		distancia_inicial = maxf(Vector2(pontos[0]).distance_to(pontos[1]), 1.0)
		zoom_inicial = zoom
		return "pinca"
	return "ignorar"

func mover(id: int, p: Vector2) -> String:
	if not dedos.has(id):
		return "ignorar"
	dedos[id] = p
	if bloqueado:
		if par.size() == 2 and dedos.has(par[0]) and dedos.has(par[1]):
			zoom = clampf(zoom_inicial * Vector2(dedos[par[0]]).distance_to(dedos[par[1]]) / distancia_inicial, ZOOM_MIN, ZOOM_MAX)
			return "pinca"
		return "ignorar"
	return "principal"

func subir(id: int) -> String:
	if not dedos.has(id):
		return "ignorar"
	dedos.erase(id)
	if par.has(id):
		par.clear()
	if bloqueado:
		if dedos.is_empty():
			bloqueado = false
		return "ignorar"
	return "principal"

## Fração do curso da pinça, sem degraus: a câmera ortográfica usa este valor
## diretamente, inclusive ao soltar em um ponto intermediário.
func fracao() -> float:
	return clampf((zoom - ZOOM_MIN) / (ZOOM_MAX - ZOOM_MIN), 0.0, 1.0)

func intima() -> bool:
	return fracao() > 0.00625

func inclinacao() -> float:
	return lerpf(1.0, 0.60, fracao())
