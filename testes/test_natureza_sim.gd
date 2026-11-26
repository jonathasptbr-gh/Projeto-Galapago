extends "res://testes/caso.gd"
## Mapa de testes NATUREZA na sim: grade válida, regra coerente com o layout e
## a mata inteira alcançável a pé (as duas margens, pelos vaus).
const Natureza := preload("res://sim/natureza.gd")
const Mundo := preload("res://sim/mundo.gd")


func _terrenos() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://dados/terrenos.json"))


func _mundo() -> RefCounted:
	return Mundo.criar(Natureza.mundo_dict(), _terrenos())


func test_grade_valida_e_reproduzivel() -> void:
	var m := _mundo()
	igual(m.validar(), PackedStringArray(), "grade e legenda válidas")
	igual(m.largura, Natureza.LARGURA, "largura")
	igual(m.altura_grade, Natureza.ALTURA, "altura")
	igual(Natureza.mundo_dict(), Natureza.mundo_dict(), "mesma semente = mesmo mapa")
	checar(Natureza.arvores(1) != Natureza.arvores(2), "outra semente muda as árvores")
	var n := Natureza.mundo_dict()
	checar(n["objetos"].size() > 70, "mata densa: muitas árvores bloqueando")


func test_inicio_e_adversario_andaveis() -> void:
	var d := Natureza.mundo_dict()
	var m := _mundo()
	var ini := Vector2i(d["inicio"][0], d["inicio"][1])
	checar(m.andavel(ini, Mundo.SUPERFICIE), "começo andável")
	igual(String(m.celulas[ini.y][ini.x]), "p", "começo na trilha")
	var a: Array = d["adversarios"][0]["celula"]
	checar(m.andavel(Vector2i(a[0], a[1]), Mundo.SUPERFICIE), "adversário em célula andável")


func test_agua_troncos_e_arvores_bloqueiam() -> void:
	var d := Natureza.mundo_dict()
	var m := _mundo()
	var agua := 0
	for z in range(m.altura_grade):
		var linha: String = m.celulas[z]
		for x in range(m.largura):
			if linha[x] == "~":
				agua += 1
				checar(not m.andavel(Vector2i(x, z), Mundo.SUPERFICIE), "água não é andável")
	checar(agua > 100, "o riacho existe na regra")
	var troncos := 0
	for o in d["objetos"]:
		var c := Vector2i(o["celula"][0], o["celula"][1])
		checar(not m.andavel(c, Mundo.SUPERFICIE), "%s bloqueia a célula" % o["tipo"])
		if o["tipo"] == "tronco":
			troncos += 1
	checar(troncos >= 6, "troncos caídos ocupam várias células")


func test_layout_e_regra_concordam() -> void:
	var m := _mundo()
	# cada árvore desenhada tem o tronco numa célula bloqueada
	for a in Natureza.arvores():
		var c := Natureza.celula_local(a["x"], a["z"])
		checar(not m.andavel(c, Mundo.SUPERFICIE), "árvore do render bloqueia na sim")
	# o meio do riacho é água fora dos vaus e cascalho andável nos vaus
	for z in range(-35, 20):
		var c := Natureza.celula_local(Natureza.rio_x(z + 0.5), z + 0.5)
		if Natureza.vau(z + 0.5) >= 0.5:
			checar(m.andavel(c, Mundo.SUPERFICIE), "vau andável em z=%d" % z)
		else:
			checar(not m.andavel(c, Mundo.SUPERFICIE), "meio do riacho é água em z=%d" % z)


func test_as_duas_margens_alcancaveis_a_pe() -> void:
	var d := Natureza.mundo_dict()
	var m := _mundo()
	var ini := Vector2i(d["inicio"][0], d["inicio"][1])
	var visto := {ini: true}
	var fila: Array[Vector2i] = [ini]
	var lados: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not fila.is_empty():
		var c: Vector2i = fila.pop_back()
		for l in lados:
			var v := c + l
			if not visto.has(v) and m.pode_andar(c, v, Mundo.SUPERFICIE):
				visto[v] = true
				fila.append(v)
	var andaveis := 0
	var leste := 0
	var oeste := 0
	for z in range(m.altura_grade):
		for x in range(m.largura):
			var c := Vector2i(x, z)
			if not m.andavel(c, Mundo.SUPERFICIE):
				continue
			andaveis += 1
			var p := Natureza.centro_local(c)
			if visto.has(c):
				if p.x > Natureza.rio_x(p.y) + 2.0:
					leste += 1
				elif p.x < Natureza.rio_x(p.y) - 2.0:
					oeste += 1
	checar(leste > 300, "margem leste alcançável a pé (%d células)" % leste)
	checar(oeste > 300, "margem oeste alcançável a pé (%d células)" % oeste)
	checar(visto.size() >= andaveis * 0.97,
		"quase toda a mata alcançável: %d de %d" % [visto.size(), andaveis])
