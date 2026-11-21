extends RefCounted
## LEITURA DO DESENHO — as FORMAS do caminho que viram ataque (v0.9).
##
## LÓGICA PURA: recebe o traço desenhado (pontos em px de mundo) e devolve
## MARCAS; nada aqui conhece nó, tela, `Input` ou tempo real. Quem compara a
## marca com a posição da criatura é o `sim/corpo.gd`.
##
## - **LAÇO**: o traço volta e CRUZA o próprio caminho. O cruzamento é o **nó**;
##   a área fechada dá o **centro** e o **raio** do ataque em área. A marca
##   acende quando a criatura passa pelo nó, no trecho que FECHA o laço — por
##   isso a marca guarda a `dir` do fechamento (a ida e a volta passam pelo
##   mesmo ponto, mas em direções diferentes).
## v0.11: o BICO não é mais lido aqui — o traço é obedecido como foi desenhado
## (o animal anda o espinho; o "beco" não é ignorado).
##
## Toda marca: {tipo, ponto, centro, raio, dir, chave}. `ponto` é o nó.
## O LAÇO é lido no traço reduzido (RDP de 3 px — a forma sobrevive).

const TOL_REDUCAO := 3.0   # px — redução para ler laços


## Todas as marcas de um traço (hoje: só o LAÇO). `[]` = nada.
static func analisar(pontos: PackedVector2Array, cfg: Dictionary = {}) -> Array:
	if pontos.size() < 3:
		return []
	var reduzido := _reduzir(pontos, TOL_REDUCAO)
	if reduzido.size() < 4:
		return []
	return lacos(reduzido, cfg)


# ---------------------------------------------------------------- laço

## Laços fechados do traço. Um por trecho: para cada saída `i`, o PRIMEIRO
## cruzamento `j` que fecha; laços repetidos (o mesmo nó visto de dentro) são
## descartados pela chave.
static func lacos(p: PackedVector2Array, cfg: Dictionary = {}) -> Array:
	var n := p.size()
	if n < 4:
		return []
	var arco := arcos(p)
	var arco_min := float(cfg.get("laco_arco_min", 90.0))
	var area_min := float(cfg.get("laco_area_min", 700.0))
	var raio_min := float(cfg.get("laco_raio_min", 24.0))
	var raio_max := float(cfg.get("laco_raio_max", 120.0))
	var dedupe := float(cfg.get("laco_dedupe_px", 26.0))
	var out: Array = []
	for i in range(0, n - 2):
		for j in range(i + 2, n - 1):
			if arco[j] - arco[i] < arco_min:
				continue
			var x := cruzamento(p[i], p[i + 1], p[j], p[j + 1])
			if x.is_empty():
				continue
			var no: Vector2 = x["p"]
			var poligono := PackedVector2Array([no])
			for k in range(i + 1, j + 1):
				poligono.append(p[k])
			var area := absf(area_assinada(poligono))
			if area < area_min:
				continue
			var centro := centroide(poligono)
			var chave := "laco:%d,%d" % [roundi(no.x), roundi(no.y)]
			var repetido := false
			for m in out:
				if Vector2(m["ponto"]).distance_to(no) <= dedupe \
						and Vector2(m["centro"]).distance_to(centro) <= dedupe * 2.0:
					repetido = true
					break
			if repetido:
				break
			out.append({
				"tipo": "laco", "ponto": no, "centro": centro,
				"raio": clampf(sqrt(area / PI), raio_min, raio_max),
				"area": area, "dir": (p[j + 1] - p[j]).normalized(), "chave": chave,
			})
			break  # o laço MAIS CURTO que fecha neste trecho
	return out


## Cruzamento entre os segmentos AB e CD: {p, t, u} ou {} se não se cruzam.
## `t` é o quanto do segmento AB (0..1) e `u` o do CD.
static func cruzamento(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> Dictionary:
	var ab := b - a
	var cd := d - c
	var den := ab.cross(cd)
	if absf(den) < 0.000001:
		return {}  # paralelos (ou colineares): não conta como laço
	var ca := c - a
	var t := ca.cross(cd) / den
	var u := ca.cross(ab) / den
	if t < 0.0 or t > 1.0 or u < 0.0 or u > 1.0:
		return {}
	return {"p": a + ab * t, "t": t, "u": u}


## Área com sinal (shoelace). O polígono NÃO repete o primeiro ponto.
static func area_assinada(pol: PackedVector2Array) -> float:
	var soma := 0.0
	var n := pol.size()
	for i in n:
		soma += pol[i].cross(pol[(i + 1) % n])
	return soma * 0.5


## Centro de massa da ÁREA fechada (é o "centro estimado do laço"). Um polígono
## degenerado cai na média dos pontos.
static func centroide(pol: PackedVector2Array) -> Vector2:
	var soma := 0.0
	var acc := Vector2.ZERO
	var n := pol.size()
	for i in n:
		var a := pol[i]
		var b := pol[(i + 1) % n]
		var cr := a.cross(b)
		soma += cr
		acc += (a + b) * cr
	if absf(soma) < 0.0001:
		return media(pol)
	return acc / (3.0 * soma)


static func media(p: PackedVector2Array) -> Vector2:
	if p.is_empty():
		return Vector2.ZERO
	var acc := Vector2.ZERO
	for q in p:
		acc += q
	return acc / float(p.size())


# ---------------------------------------------------------------- medidas

## Comprimento de arco acumulado em cada ponto (arcos[0] = 0).
static func arcos(p: PackedVector2Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if p.is_empty():
		return out
	out.append(0.0)
	for i in range(1, p.size()):
		out.append(out[i - 1] + p[i - 1].distance_to(p[i]))
	return out


# ---------------------------------------------------------------- redução

## RDP com distância ao SEGMENTO (não à reta infinita): um ponto que passa da
## ponta do segmento conta como fora — é o que preserva a forma de um laço.
static func _reduzir(pontos: PackedVector2Array, tol: float) -> PackedVector2Array:
	if pontos.size() < 3 or tol <= 0.0:
		return pontos
	return _rdp(pontos, 0, pontos.size() - 1, tol)


static func _rdp(p: PackedVector2Array, ini: int, fim: int, tol: float) -> PackedVector2Array:
	var a := p[ini]
	var b := p[fim]
	var maior := 0.0
	var corte := -1
	for i in range(ini + 1, fim):
		var d := _dist_segmento(p[i], a, b)
		if d > maior:
			maior = d
			corte = i
	if corte == -1 or maior <= tol:
		return PackedVector2Array([a, b])
	var esq := _rdp(p, ini, corte, tol)
	var dir := _rdp(p, corte, fim, tol)
	var out := esq
	for i in range(1, dir.size()):
		out.append(dir[i])
	return out


static func _dist_segmento(q: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.000001:
		return q.distance_to(a)
	var t := clampf((q - a).dot(ab) / l2, 0.0, 1.0)
	return q.distance_to(a + ab * t)
