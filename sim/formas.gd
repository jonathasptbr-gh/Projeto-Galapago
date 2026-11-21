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
## - **BICO**: ida e volta BRUSCA (um espinho estreito): o traço SAI e VOLTA
##   para perto do ponto de onde saiu. A marca é a **base** (o ponto do caminho
##   antes do bico); o tiro sai dela na direção da ponta. Um bico desenhado já
##   no ponto de partida dispara sem a criatura andar.
##
## Toda marca: {tipo, ponto, chave, dir, ...}. `ponto` é onde o gatilho acende.
## O LAÇO é lido no traço reduzido (RDP de 3 px — a forma sobrevive). O BICO é
## lido no traço CRU, porque a marca leva `i`/`j` (os índices do trecho que o
## corpo vai CORTAR da rota): a PONTA é uma reversão e a BASE é a volta que
## reencontra a estrada. Nada é amostrado aqui.

const TOL_REDUCAO := 3.0   # px — redução para ler laços


## Todas as marcas de um traço (laços primeiro, depois bicos). `[]` = nada.
static func analisar(pontos: PackedVector2Array, cfg: Dictionary = {}) -> Array:
	var out: Array = []
	if pontos.size() < 3:
		return out
	var reduzido := _reduzir(pontos, TOL_REDUCAO)
	if reduzido.size() >= 4:
		out.append_array(lacos(reduzido, cfg))
	if pontos.size() >= 3:
		out.append_array(bicos(pontos, cfg))
	return out


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


# ---------------------------------------------------------------- bico

## BICOS: o "T" (ou o "V") desenhado por cima do caminho. O traço SAI da
## estrada, vai até uma PONTA e VOLTA para ela.
##
## - a **PONTA** é uma REVERSÃO (~180° numa janela de `bico_janela_px` de arco);
## - a **BASE** é onde a volta REENCONTRA a estrada: a primeira curva forte
##   (`bico_base_angulo`) depois da ponta — ou o fim do traço —, sempre perto do
##   traço anterior (`bico_base_px`, e `bico_fim_px` quando o traço acaba);
## - o bico **NÃO é andado**: `i` e `j` (índices no traço cru) dizem ao corpo
##   qual trecho cortar; a criatura para antes e dispara da BASE.
##
## Devolve {tipo, ponto: base, base, ponta, dir, i, j, chave, comprimento}.
static func bicos(p: PackedVector2Array, cfg: Dictionary = {}) -> Array:
	if p.size() < 3:
		return []
	var ponta_min := float(cfg.get("bico_ponta_min", 18.0))
	var tol := float(cfg.get("bico_tol_px", 26.0))
	var ang := deg_to_rad(float(cfg.get("bico_angulo_min", 120.0)))
	var janela := maxf(float(cfg.get("bico_janela_px", 10.0)), 2.0)
	var base_px := maxf(float(cfg.get("bico_base_px", 14.0)), 1.0)
	var fim_px := maxf(float(cfg.get("bico_fim_px", 40.0)), base_px)
	var base_ang := deg_to_rad(float(cfg.get("bico_base_angulo", 45.0)))
	var arco := arcos(p)
	# 1) as PONTAS (reversões)
	var pontas: Array[int] = []
	for k in range(1, p.size() - 1):
		var a := _indice_antes(arco, k, janela)
		var b := _indice_depois(arco, k, janela)
		if a < 0 or b < 0:
			continue
		var v1 := p[k] - p[a]
		var v2 := p[b] - p[k]
		if v1.length() < 4.0 or v2.length() < 4.0:
			continue
		if v1.normalized().dot(v2.normalized()) > cos(ang):
			continue
		if not pontas.is_empty() and arco[k] - arco[pontas[pontas.size() - 1]] <= janela * 1.2:
			continue  # ponta arredondada: uma reversão só
		pontas.append(k)
	# 2) para cada ponta, a BASE (o ponto antes do bico)
	var out: Array = []
	for t in pontas:
		var achado := _bico_da_ponta(p, arco, t, ponta_min, tol, janela, base_px, fim_px, base_ang)
		if achado.is_empty():
			continue
		var base: Vector2 = achado["base"]
		var dir: Vector2 = achado["dir"]
		if _ja_bico(out, base, dir, ponta_min):
			continue
		achado["tipo"] = "bico"
		achado["ponto"] = base
		achado["chave"] = "bico:%d,%d" % [roundi(base.x), roundi(base.y)]
		out.append(achado)
	return out


## A base do bico a partir da PONTA `t`: a primeira volta que reencontra a
## estrada (curva ≥ `base_ang`) ou o fim do traço, perto do traço anterior.
static func _bico_da_ponta(p: PackedVector2Array, arco: PackedFloat32Array, t: int,
		ponta_min: float, tol: float, janela: float, base_px: float, fim_px: float,
		base_ang: float) -> Dictionary:
	var n := p.size()
	for b in range(t + 1, n):
		if arco[b] - arco[t] < ponta_min:
			continue
		var altura := p[t].distance_to(p[b])
		if altura < ponta_min:
			continue
		var fim := b == n - 1
		var limite := fim_px if fim else base_px
		var perto := _indice_perto(p, p[b], t, limite)
		if perto < 0:
			continue
		if not fim and _curva_forte(p, arco, b, janela) < base_ang:
			continue
		if _largo(p, perto, b, p[perto], p[t]) > minf(tol, altura * 0.5):
			continue
		var dir := (p[t] - p[perto]).normalized()
		return {"base": p[perto], "ponta": p[t], "dir": dir, "i": perto, "j": b,
			"comprimento": altura}
	return {}


## Índice ~`janela` px de arco ANTES de `k` (-1 se não há).
static func _indice_antes(arco: PackedFloat32Array, k: int, janela: float) -> int:
	var a := k - 1
	while a > 0 and arco[k] - arco[a] < janela:
		a -= 1
	return a if a >= 0 and arco[k] - arco[a] > 0.0 else -1


## Índice ~`janela` px de arco DEPOIS de `k` (-1 se não há).
static func _indice_depois(arco: PackedFloat32Array, k: int, janela: float) -> int:
	var b := k + 1
	while b < arco.size() - 1 and arco[b] - arco[k] < janela:
		b += 1
	return b if b < arco.size() and arco[b] - arco[k] > 0.0 else -1


## Curva (em radianos) no ponto `k`: ângulo entre a direção dos ~`janela` px
## ANTES e a dos ~`janela` px DEPOIS.
static func _curva_forte(p: PackedVector2Array, arco: PackedFloat32Array, k: int, janela: float) -> float:
	var a := _indice_antes(arco, k, janela)
	var b := _indice_depois(arco, k, janela)
	if a < 0 or b < 0:
		return 0.0
	var v1 := p[k] - p[a]
	var v2 := p[b] - p[k]
	if v1.length() < 1.0 or v2.length() < 1.0:
		return 0.0
	return absf(v1.angle_to(v2))


## O ponto do traço ANTES da ponta mais perto de `q` (até `raio` px): a base
## de saída. -1 se não há.
static func _indice_perto(p: PackedVector2Array, q: Vector2, limite: int, raio: float) -> int:
	var melhor := -1
	var melhor_d := raio
	for k in range(0, limite):
		var d := p[k].distance_to(q)
		if d <= melhor_d:
			melhor_d = d
			melhor = k
	return melhor


## O quanto o trecho [i..j] se afasta da reta base→ponta: é o que separa um
## bico (espinho estreito) de um laço ou de uma curva larga.
static func _largo(p: PackedVector2Array, i: int, j: int, base: Vector2, ponta: Vector2) -> float:
	var d := ponta - base
	if d.length() < 0.001:
		return INF
	var dir := d.normalized()
	var m := 0.0
	for k in range(i, j + 1):
		m = maxf(m, absf((p[k] - base).cross(dir)))
	return m


static func _ja_bico(out: Array, base: Vector2, dir: Vector2, raio: float) -> bool:
	for m in out:
		if Vector2(m["base"]).distance_to(base) <= raio \
				and Vector2(m["dir"]).dot(dir) > 0.7:
			return true
	return false


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
