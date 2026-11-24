extends RefCounted
## Estado puro da marcha: a fase acompanha distância de corpo, os apoios são
## pontos de chão do mundo. Sem movimento, não existe avanço de passada.
## Ciclo, duty e defasagem de cada pata vêm da tabela `marchas` do rig (via
## `clipe_marcha`); um clipe sem marcha declarada não avança fase.
const E3 := preload("res://sim/esqueleto3d.gd")
const INCLINACAO := sin(deg_to_rad(20.0))


static func avancar(rig: Dictionary, anterior: Dictionary, pos: Vector2,
		dir: String, yaw_graus: float, clipe: String, delta: Vector2) -> Dictionary:
	var estado: Dictionary = anterior.duplicate(true)
	var mo: Dictionary = rig.get("motion", {})
	var marcha := E3._marcha(mo, clipe)
	var tipo := clipe if not marcha.is_empty() else ""
	var yaw := deg_to_rad(E3.yaw_efetivo(dir, yaw_graus))
	var mudou: bool = String(estado.get("tipo", "")) != tipo
	var giro: float = absf(wrapf(yaw - float(estado.get("yaw", yaw)), -PI, PI))
	# Reset de fase e de ancoragem: o quadro que reseta não transporta âncora
	# nenhuma. Isso vale para a troca de clipe, para o giro de mais de 35° e
	# para o salto de mais de 40 px de uma vez.
	var reancorar: bool = mudou or giro > deg_to_rad(35.0) or delta.length() > 40.0
	if reancorar:
		estado = {"fase": 0.0, "apoios": {}, "apoiando": {}, "tipo": tipo}
	else:
		estado["apoios"] = (estado.get("apoios", {}) as Dictionary).duplicate()
		estado["apoiando"] = (estado.get("apoiando", {}) as Dictionary).duplicate()
	estado["yaw"] = yaw
	if tipo == "":
		estado["apoios"] = {}
		estado["apoiando"] = {}
		estado["alvos"] = {}
		return estado
	var ciclo := float(marcha.get("ciclo_px", 0.0))
	var antigo := float(estado.get("fase", 0.0))
	var fase := fposmod(antigo + delta.length() / maxf(ciclo, 1.0), 1.0)
	estado["fase"] = fase
	var apoios: Dictionary = estado["apoios"]
	var apoiando: Dictionary = estado["apoiando"]
	var alvos: Dictionary = {}
	var base := E3.pose(rig, dir, fase, tipo, false, yaw_graus)
	if base.is_empty():
		return estado
	var piv := Vector2(float(rig["pivot_px"][0]), float(rig["pivot_px"][1]))
	var duty := float(marcha.get("duty", 0.0))
	var defas: Dictionary = marcha.get("defasagem", {})
	for perna in E3._pernas(rig):
		var nome := String(perna["nome"])
		var pata := String(perna["foot"])
		var off := float(defas.get(nome, 0.0))
		var contato := fposmod(fase - off, 1.0) < duty
		if not contato:
			if reancorar:
				# No quadro do reset as QUATRO patas são replantadas onde estão,
				# inclusive as que já estão no ar (sem `apoiando`, então a
				# primeira volta ao contato ancora de novo). A âncora do giro é
				# uma foto da pose atual: nenhuma pata atravessa o corpo presa
				# a um ponto de chão do yaw antigo.
				apoios[nome] = pos + (base["juntas"][pata] as Vector2) - piv
			else:
				apoios.erase(nome)
			apoiando[nome] = false
			continue
		if not bool(apoiando.get(nome, false)) or not apoios.has(nome):
			apoios[nome] = pos + (base["juntas"][pata] as Vector2) - piv
		apoiando[nome] = true
		var relativo: Vector2 = (apoios[nome] as Vector2) - pos
		# Inversa exata da projeção ortográfica no plano do chão (y=0).
		# A velocidade da tela não é dividida por sin20: 1 px percorrido
		# exige 1 px de deslocamento do alvo em tela, sem reescala da arte.
		var x := -relativo.x * sin(yaw) + relativo.y * cos(yaw) / INCLINACAO
		var z := relativo.x * cos(yaw) + relativo.y * sin(yaw) / INCLINACAO
		alvos[nome] = Vector3(x, 0.0, z)
	estado["alvos"] = alvos
	return estado
