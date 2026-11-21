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
## O LAÇO é lido no traço reduzido (RDP de 3 px — a forma sobrevive); o BICO é
## lido no traço amostrado por distância (6 px), porque uma ida e volta na MESMA
## reta teria desvio zero e o RDP comeria a ponta. O espinho é achado pela
## VOLTA: dois pontos perto no espaço e longe no percurso.

const TOL_REDUCAO := 3.0   # px — redução para ler laços
const PASSO_BICO := 6.0    # px — amostragem para ler bicos


## Todas as marcas de um traço (laços primeiro, depois bicos). `[]` = nada.
static func analisar(pontos: PackedVector2Array, cfg: Dictionary = {}) -> Array:
	var out: Array = []
	if pontos.size() < 3:
		return out
	var reduzido := _reduzir(pontos, TOL_REDUCAO)
	if reduzido.size() >= 4:
		out.append_array(lacos(reduzido, cfg))
	var amostra := _amostrar(pontos, PASSO_BICO)
	if amostra.size() >= 3:
		out.append_array(bicos(amostra, cfg))
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

## Bicos: o traço vai até uma PONTA e VOLTA. O sinal é a REVERSÃO (a direção
## vira de ponta-cabeça em ~180°) e a VOLTA a uma base: a ponta é a primeira
## reversão e a base é a segunda (onde o traço reencontra o caminho) — ou o
## começo do traço, quando ele acaba na volta. A base é o ponto do caminho
## ANTES do bico: é nele que o tiro sai, na direção da ponta.
static func bicos(p: PackedVector2Array, cfg: Dictionary = {}) -> Array:
	if p.size() < 3:
		return []
	var ponta_min := float(cfg.get("bico_ponta_min", 18.0))
	var tol := float(cfg.get("bico_tol_px", 26.0))
	var ang := deg_to_rad(float(cfg.get("bico_angulo_min", 120.0)))
	var janela := maxf(float(cfg.get("bico_janela_px", 10.0)), 2.0)
	var volta := maxf(float(cfg.get("bico_volta_px", 40.0)), 1.0)
	var arco := arcos(p)
	# 1) as REVERSÕES (a ponta e a base do bico são as duas)
	var revs: Array[int] = []
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
		if not revs.is_empty() and arco[k] - arco[revs[revs.size() - 1]] <= janela * 1.2:
			continue  # ponta arredondada: uma reversão só
		revs.append(k)
	# 2) ponta + base de cada bico
	var out: Array = []
	for r in revs.size():
		var tip_i: int = revs[r]
		var base := Vector2.ZERO
		var fim := 0
		if r + 1 < revs.size():
			fim = revs[r + 1]
			base = p[fim]                       # onde a volta REENCONTRA o caminho
		else:
			# o traço acaba na volta: vale se ela termina perto do COMEÇO
			if p[p.size() - 1].distance_to(p[0]) > volta:
				continue
			fim = p.size() - 1
			base = p[0]                         # o ponto antes do bico (a partida)
		var tip := p[tip_i]
		var altura := tip.distance_to(base)
		if altura < ponta_min:
			continue
		if arco[fim] - arco[tip_i] < ponta_min:
			continue  # a volta é curta demais: não houve ida e volta
		var antes := _indice_antes(arco, tip_i, janela)
		if antes < 0:
			continue
		var dir := (tip - p[antes]).normalized()
		var largo := 0.0
		for k in range(tip_i, fim + 1):
			largo = maxf(largo, absf((p[k] - base).cross(dir)))
		if largo > minf(tol, altura * 0.35):
			continue  # a volta não veio POR DENTRO do espinho (é laço, não bico)
		var chave := "bico:%d,%d" % [roundi(base.x), roundi(base.y)]
		if _ja_bico(out, base, dir, ponta_min):
			continue
		out.append({
			"tipo": "bico", "ponto": base, "base": base, "ponta": tip, "dir": dir,
			"comprimento": altura, "chave": chave,
		})
	return out


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

## Amostra por DISTÂNCIA de arco: um ponto a cada `passo` px (o último sempre
## fica). Serve ao bico, que precisa manter a ponta mesmo numa reta.
static func _amostrar(pontos: PackedVector2Array, passo: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in pontos:
		if out.is_empty() or out[out.size() - 1].distance_to(q) >= passo:
			out.append(q)
	if not pontos.is_empty() and (out.is_empty() or out[out.size() - 1] != pontos[pontos.size() - 1]):
		out.append(pontos[pontos.size() - 1])
	return out


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
