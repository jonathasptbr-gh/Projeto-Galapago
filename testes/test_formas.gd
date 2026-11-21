extends "res://testes/caso.gd"

const F := preload("res://sim/formas.gd")

## Os limiares vêm dos DADOS (dados/acoes.json), como no jogo: o teste não
## repete os números — mudar o design muda o teste junto.
func _cfg() -> Dictionary:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/acoes.json"))
	return d.get("formas", {})


## Traço com pontos a cada 2 px (o dedo deixa pontos densos, não só os vértices).
func _denso(vertices: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(vertices.size()):
		var a := Vector2(float(vertices[i][0]), float(vertices[i][1]))
		if i == 0:
			out.append(a)
			continue
		var b := Vector2(float(vertices[i - 1][0]), float(vertices[i - 1][1]))
		var n := maxi(1, ceili(a.distance_to(b) / 2.0))
		for k in range(1, n + 1):
			out.append(b.lerp(a, float(k) / n))
	return out


func _por_tipo(marcas: Array, tipo: String) -> Array:
	return marcas.filter(func(m): return str(m["tipo"]) == tipo)


# ---------------------------------------------------------------- laço

## O traço fecha em cima de si mesmo: nó no cruzamento, centro e raio da área.
func test_laco_da_no_centro_e_no_raio() -> void:
	var p := _denso([[0, 0], [100, 0], [100, 100], [30, 100], [30, -30]])
	var lacos := _por_tipo(F.analisar(p, _cfg()), "laco")
	igual(lacos.size(), 1, "um laço")
	if lacos.is_empty():
		return
	var m: Dictionary = lacos[0]
	perto_v(Vector2(m["ponto"]), Vector2(30, 0), 4.0, "nó onde o traço fecha")
	perto_v(Vector2(m["centro"]), Vector2(65, 50), 8.0, "centro estimado do laço")
	checar(float(m["raio"]) > 30.0 and float(m["raio"]) < 70.0, "raio do laço (%s)" % m["raio"])
	checar(Vector2(m["dir"]).dot(Vector2(0, -1)) > 0.9, "direção do FECHAMENTO (%s)" % m["dir"])


func test_ida_e_volta_reta_nao_e_laco() -> void:
	var p := _denso([[0, 0], [100, 0], [0, 0]])
	igual(_por_tipo(F.analisar(p, _cfg()), "laco").size(), 0, "sem área, sem laço")


func test_curva_nao_e_laco() -> void:
	var p := PackedVector2Array()
	for i in 40:
		var a := PI * 0.5 * i / 39.0
		p.append(Vector2(cos(a), sin(a)) * 100.0)
	igual(_por_tipo(F.analisar(p, _cfg()), "laco").size(), 0, "curva só")


## v0.11.1: TAMANHO MÍNIMO do laço. Um laço do tamanho do animal (40×40) que
## nasce sem querer não acende a área; um desenhado de propósito (60×60) sim.
func test_laco_pequeno_nao_acende_a_area() -> void:
	var p := _denso([[0, 0], [40, 0], [40, 40], [0, 40], [0, 0]])
	igual(_por_tipo(F.analisar(p, _cfg()), "laco").size(), 0, "laço de 40×40 não é ataque (%s)" % [F.analisar(p, _cfg())])


func test_laco_de_tamanho_util_acende_a_area() -> void:
	var p := _denso([[0, 0], [60, 0], [60, 60], [0, 60], [0, 0]])
	igual(_por_tipo(F.analisar(p, _cfg()), "laco").size(), 1, "laço de 60×60 é ataque (%s)" % [F.analisar(p, _cfg())])


# ---------------------------------------------------------------- centro

func test_centroide_de_retangulo() -> void:
	var pol := PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100)])
	perto_v(F.centroide(pol), Vector2(50, 50), 0.01, "centro do retângulo")
	perto(F.area_assinada(pol), 10000.0, 0.01, "área")
