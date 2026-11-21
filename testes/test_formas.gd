extends "res://testes/caso.gd"

const F := preload("res://sim/formas.gd")

const CFG := {
	"gatilho_raio_px": 24, "laco_arco_min": 90, "laco_area_min": 700,
	"laco_raio_min": 24, "laco_raio_max": 120, "laco_dedupe_px": 26,
	"bico_angulo_min": 120, "bico_ponta_min": 18, "bico_tol_px": 26,
	"bico_volta_px": 40, "bico_janela_px": 10,
}


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
	var lacos := _por_tipo(F.analisar(p, CFG), "laco")
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
	igual(_por_tipo(F.analisar(p, CFG), "laco").size(), 0, "sem área, sem laço")


func test_curva_nao_e_laco() -> void:
	var p := PackedVector2Array()
	for i in 40:
		var a := PI * 0.5 * i / 39.0
		p.append(Vector2(cos(a), sin(a)) * 100.0)
	igual(_por_tipo(F.analisar(p, CFG), "laco").size(), 0, "curva só")


# ---------------------------------------------------------------- bico

## Ida e volta brusca: a marca é a BASE, apontando para a ponta.
func test_bico_da_a_base_e_a_direcao() -> void:
	var p := _denso([[0, 0], [90, 0], [20, 0]])
	var bicos := _por_tipo(F.analisar(p, CFG), "bico")
	igual(bicos.size(), 1, "um bico")
	if bicos.is_empty():
		return
	# a volta termina em 20; a base é o ponto do traço mais perto dela
	checar(Vector2(bicos[0]["ponto"]).distance_to(Vector2(20, 0)) <= 10.0, "base do bico (%s)" % bicos[0]["ponto"])
	checar(Vector2(bicos[0]["dir"]).dot(Vector2(1, 0)) > 0.9, "direção do bico (%s)" % bicos[0]["dir"])
	checar(float(bicos[0]["comprimento"]) > 55.0, "comprimento (%s)" % bicos[0]["comprimento"])


## O bico no MEIO do caminho: a base é onde o espinho sai, não o começo.
func test_bico_no_meio_usa_a_base_do_espinho() -> void:
	var p := _denso([[0, 0], [150, 0], [250, 0], [150, 0], [300, 0]])
	var bicos := _por_tipo(F.analisar(p, CFG), "bico")
	igual(bicos.size(), 1, "um bico (%s)" % [bicos])
	if bicos.is_empty():
		return
	perto_v(Vector2(bicos[0]["ponto"]), Vector2(150, 0), 10.0, "base em 150")


func test_bico_com_ponta_no_fim_do_traco() -> void:
	var p := _denso([[0, 0], [90, 0], [30, 0]])
	igual(_por_tipo(F.analisar(p, CFG), "bico").size(), 1, "bico que termina na volta")


## Esquina comum (90°) não é bico: o traço não volta para perto de onde saiu.
func test_esquina_nao_e_bico() -> void:
	var p := _denso([[0, 0], [100, 0], [100, 100]])
	igual(_por_tipo(F.analisar(p, CFG), "bico").size(), 0, "esquina")


## O pequeno vai-e-volta de alinhamento do começo também não é bico: a volta
## não chega a ir longe.
func test_tremor_do_comeco_nao_e_bico() -> void:
	var p := _denso([[0, 0], [-12, 0], [0, 0], [30, 0], [80, 0]])
	igual(_por_tipo(F.analisar(p, CFG), "bico").size(), 0, "tremor")


# ---------------------------------------------------------------- centro

func test_centroide_de_retangulo() -> void:
	var pol := PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100)])
	perto_v(F.centroide(pol), Vector2(50, 50), 0.01, "centro do retângulo")
	perto(F.area_assinada(pol), 10000.0, 0.01, "área")


## v0.9.1: o "T" — o bico SAI da estrada na perpendicular e volta para ela.
func test_bico_em_t_perpendicular() -> void:
	var p := _denso([[0, 0], [150, 0], [150, 70], [150, 0], [260, 0]])
	var bicos := _por_tipo(F.analisar(p, CFG), "bico")
	igual(bicos.size(), 1, "um bico em T (%s)" % [bicos])
	if bicos.is_empty():
		return
	checar(Vector2(bicos[0]["ponto"]).distance_to(Vector2(150, 0)) <= 10.0, "base no T (%s)" % bicos[0]["ponto"])
	checar(Vector2(bicos[0]["dir"]).dot(Vector2(0, 1)) > 0.9, "direção da ponta (%s)" % bicos[0]["dir"])
	checar(int(bicos[0]["j"]) > int(bicos[0]["i"]), "i/j para cortar o beco")
