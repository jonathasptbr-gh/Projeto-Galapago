extends "res://testes/caso.gd"
## Água de grade (sim/agua.gd): conserva, desce a rampa, empoça, não sobe,
## vai para o riacho e evapora.
const Agua := preload("res://sim/agua.gd")


## Rampa de norte (alta) para sul (baixa) com uma bacia no meio.
func _rampa(w := 9, h := 12) -> RefCounted:
	var g := Agua.new(w, h)
	for y in range(h):
		for x in range(w):
			var alt := 1.0 - y * 0.08
			if Vector2(x - 4, y - 5).length() < 1.6:
				alt -= 0.3
			g.definir_chao(Vector2i(x, y), alt)
	return g


func test_conserva_sem_fonte_rio_nem_evaporacao() -> void:
	var g := _rampa()
	g.evaporacao = 0.0
	g.agua[g.indice(Vector2i(4, 1))] = 0.8
	var antes: float = g.total()
	for i in range(100):
		g.passo(0.1)
	perto(g.total(), antes, 0.0005, "a água não aparece nem some sozinha")


func test_desce_a_rampa_e_empoca_na_bacia() -> void:
	var g := _rampa()
	g.evaporacao = 0.0
	g.agua[g.indice(Vector2i(4, 1))] = 0.6
	for i in range(80):
		g.passo(0.1)
	checar(g.agua[g.indice(Vector2i(4, 5))] > g.agua[g.indice(Vector2i(4, 1))], "a bacia junta mais água que o alto")
	checar(g.agua[g.indice(Vector2i(4, 1))] < 0.05, "o alto da rampa escorreu")
	checar(g.fluxo[g.indice(Vector2i(4, 3))].y >= 0.0, "o fluxo na rampa aponta para baixo (sul)")


func test_nao_sobe_parede() -> void:
	var g := Agua.new(5, 1)
	for x in range(5):
		g.definir_chao(Vector2i(x, 0), 0.0 if x < 2 else 2.0)
	g.evaporacao = 0.0
	g.agua[0] = 0.5
	for i in range(60):
		g.passo(0.1)
	perto(g.agua[2] + g.agua[3] + g.agua[4], 0.0, 0.0001, "a água não sobe um degrau mais alto que ela")
	perto(g.agua[0], g.agua[1], 0.01, "nivela no plano")


func test_riacho_leva_embora_e_tudo_evapora() -> void:
	var g := _rampa()
	for x in range(9):
		# leito do riacho abaixo da margem: a superfície dele não inunda a rampa
		g.definir_chao(Vector2i(x, 11), 1.0 - 11 * 0.08 - 0.3)
		g.rio(Vector2i(x, 11), 0.15)
	g.fonte(Vector2i(4, 1), 0.6)
	for i in range(30):
		g.passo(0.1)
	checar(g.agua[g.indice(Vector2i(4, 5))] > 0.05, "a fonte encheu a bacia")
	g.fonte(Vector2i(4, 1), 0.0)
	for i in range(400):
		g.passo(0.1)
	perto(g.agua[g.indice(Vector2i(4, 11))], 0.15, 0.0001, "o riacho mantém o nível")
	var fora_do_rio := 0.0
	for y in range(11):
		for x in range(9):
			fora_do_rio += g.agua[g.indice(Vector2i(x, y))]
	perto(fora_do_rio, 0.0, 0.0001, "sem fonte, a água some (escorre ao riacho ou evapora)")
	checar(g.umidade[g.indice(Vector2i(4, 5))] < 1.0, "o chão vai secando")


func test_reproduzivel() -> void:
	var a := _rampa()
	var b := _rampa()
	for g in [a, b]:
		g.fonte(Vector2i(4, 1), 0.5)
		for i in range(25):
			g.passo(0.1)
	igual(a.agua, b.agua, "mesmos passos, mesma água")
