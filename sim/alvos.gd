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
			"raio": a.raio, "travavel": true, "interativo": false, "dados": a,
		})
	return out


## Atualiza as posições dos alvos que se movem (adversários) na lista pronta.
static func sincronizar(out: Array, adversarios: Array) -> void:
	var n := 0
	for a in out:
		if a["tipo"] == "adversario":
			if n < adversarios.size():
				a["pos"] = adversarios[n].pos
				n += 1


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
