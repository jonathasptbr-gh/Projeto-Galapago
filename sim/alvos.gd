extends RefCounted
## ALVOS traváveis (árvore, adversário, baú) — LÓGICA PURA.
##
## Um alvo é um dicionário: {id, tipo, pos, raio, travavel, interativo}.
## `pos` é atualizada a cada quadro pelo dono (adversário anda); o corpo guarda
## só o `id` e resolve a posição por aqui, então mirar num alvo móvel funciona.

const AO_ALCANCE_PADRAO := 110.0


## Monta a lista a partir dos objetos do mapa e dos adversários vivos.
static func montar(objetos: Array, adversarios: Array, mundo: RefCounted) -> Array:
	var out: Array = []
	for o in objetos:
		var c := Vector2i(o["celula"][0], o["celula"][1])
		out.append({
			"id": "%s:%d,%d" % [o["tipo"], c.x, c.y],
			"tipo": o["tipo"], "pos": mundo.centro(c) + Vector2(0, 6),
			"raio": 14.0, "travavel": o["tipo"] == "arvore" or o["tipo"] == "adversario",
			"interativo": o["tipo"] == "bau", "dados": o,
		})
	for i in adversarios.size():
		var a: RefCounted = adversarios[i]
		out.append({
			"id": "adversario:%d" % i, "tipo": "adversario", "pos": a.pos,
			"raio": a.raio, "travavel": _visivel(a), "interativo": false, "dados": a,
		})
	return out


## Atualiza as posições dos alvos que se movem (adversários) na lista pronta.
## v0.14: o alvo ESCONDIDO deixa de ser travável (não dá para marcar nem bater).
static func sincronizar(out: Array, adversarios: Array) -> void:
	var n := 0
	for a in out:
		if a["tipo"] == "adversario":
			if n < adversarios.size():
				a["pos"] = adversarios[n].pos
				a["travavel"] = _visivel(adversarios[n])
				n += 1


static func _visivel(dados: Variant) -> bool:
	if not (dados is Object):
		return false
	if dados.has_method("alvo_visivel"):
		return bool(dados.alvo_visivel())
	return true


## O alvo travável mais perto de `ponto` (o toque) dentro de `alcance`; {} se
## nenhum. Empate: o primeiro na ordem (determinístico).
static func mais_proximo(out: Array, ponto: Vector2, alcance := AO_ALCANCE_PADRAO) -> Dictionary:
	var melhor := {}
	var melhor_d := alcance
	for a in out:
		var d: float = ponto.distance_to(a["pos"]) - float(a["raio"])
		if d <= melhor_d:
			melhor_d = d
			melhor = a
	return melhor


static func por_id(out: Array, id: String) -> Dictionary:
	for a in out:
		if a["id"] == id:
			return a
	return {}


## Posição atual de um alvo (Vector2.ZERO se o alvo sumiu).
static func pos_de(out: Array, id: String) -> Vector2:
	var a := por_id(out, id)
	return a["pos"] if not a.is_empty() else Vector2.ZERO


## O alvo leva um golpe: empurra se ele souber reagir (`empurrar` nos dados —
## adversário sabe, árvore/baú não). `true` = empurrou.
static func empurrar(out: Array, id: String, dir: Vector2, forca: float) -> bool:
	var a := por_id(out, id)
	if a.is_empty():
		return false
	if not reage(a):
		return false
	var dados: Variant = a.get("dados", null)
	if not (dados is Object) or not dados.has_method("empurrar"):
		return false
	dados.empurrar(dir, forca)
	return true


## É um alvo que reage a golpe (adversário)? O que decide a ONDA e o TIRO.
static func reage(a: Dictionary) -> bool:
	var dados: Variant = a.get("dados", null)
	if not (dados is Object) or not dados.has_method("empurrar"):
		return false
	# v0.14: ESCONDIDO não é alvo (o especial do adversário)
	if dados.has_method("alvo_visivel"):
		return bool(dados.alvo_visivel())
	return true
