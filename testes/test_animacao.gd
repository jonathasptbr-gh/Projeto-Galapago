extends "res://testes/caso.gd"
## Máquina de estados da animação: catálogo válido, prioridades, clipe de uma
## vez que segura a cena, ameaça que interrompe e fase (loop × fim).

const A := preload("res://sim/animacao.gd")
const CAMINHO := "res://dados/animacoes.json"

class Fake extends RefCounted:
	var ataque := ""
	var escavando := false
	var tonto := 0.0
	var carga := false
	var ar := false
	var sprint := false

	func atordoado() -> bool:
		return tonto > 0.0

	func carregando() -> bool:
		return carga

	func no_ar() -> bool:
		return ar

	func correndo() -> bool:
		return sprint


func _cat() -> Dictionary:
	var texto := FileAccess.get_file_as_string(CAMINHO)
	checar(not texto.is_empty(), "catálogo legível")
	var m := A.de_json(texto)
	checar(not m.is_empty(), "catálogo válido")
	return m


func _mem(id: String, desde: float) -> Dictionary:
	return {"id": id, "desde_ms": desde}


func test_catalogo_valido_e_completo() -> void:
	var m := _cat()
	igual(A.validar(m), "", "sem erro")
	igual((m["catalogo"] as Dictionary).size(), 43, "43 ações do catálogo")
	for id in A.OBRIGATORIOS:
		checar(A.clipe(m, id).size() > 0, "clipe obrigatório: " + id)


func test_prioridades() -> void:
	var m := _cat()
	var ordem := ["death", "stunned", "hit", "bite", "jump_air", "walk", "eat", "happy"]
	var anterior := -1
	for id in ordem:
		var p := A.prioridade(m, id)
		checar(p > anterior, "prioridade cresce em " + id)
		anterior = p


func test_desejado_por_estado() -> void:
	var m := _cat()
	igual(A.desejado({"andando": true}, m), "walk", "andando")
	igual(A.desejado({}, m), "idle", "parado")
	igual(A.desejado({"atordoado": true}, m), "stunned", "atordoado")
	igual(A.desejado({"golpe": "ataque"}, m), "bite", "mordida")
	igual(A.desejado({"golpe": "batida"}, m), "slam", "esbarrão")
	igual(A.desejado({"carregando": true}, m), "charge", "carga")
	igual(A.desejado({"escavando": true}, m), "dig", "cavar")
	igual(A.desejado({"no_ar": true}, m), "jump_air", "pulo")
	igual(A.desejado({"morto": true}, m), "death", "morte vence tudo")


func test_clipe_de_uma_vez_segura_a_cena() -> void:
	var m := _cat()
	var mem := A.resolver({"golpe": "ataque"}, m, _mem("", 0.0), 0.0)
	igual(mem["id"], "bite", "começou a mordida")
	mem = A.resolver({}, m, mem, 200.0)
	igual(mem["id"], "bite", "ainda morde em 200 ms")
	igual(float(mem["desde_ms"]), 0.0, "início preservado")
	mem = A.resolver({}, m, mem, 500.0)
	igual(mem["id"], "idle", "acabou e volta ao parado")


func test_ameaca_interrompe_mas_mordida_nao_interrompe_atordoado() -> void:
	var m := _cat()
	var mem := A.resolver({"golpe": "ataque"}, m, _mem("", 0.0), 0.0)
	mem = A.resolver({"atordoado": true}, m, mem, 100.0)
	igual(mem["id"], "stunned", "atordoado corta a mordida")
	mem = A.resolver({"golpe": "ataque"}, m, mem, 150.0)
	igual(mem["id"], "stunned", "mordida não corta atordoado")
	mem = A.resolver({"morto": true}, m, mem, 200.0)
	igual(mem["id"], "death", "morte corta tudo")


func test_base_troca_entre_andar_e_parar() -> void:
	var m := _cat()
	var mem := A.resolver({"andando": true}, m, _mem("", 0.0), 0.0)
	igual(mem["id"], "walk", "andando")
	mem = A.resolver({}, m, mem, 100.0)
	igual(mem["id"], "idle", "parou")
	mem = A.resolver({"andando": true}, m, mem, 200.0)
	igual(mem["id"], "walk", "voltou a andar")


func test_fase_loop_e_fim() -> void:
	var m := _cat()
	var andar := _mem("walk", 0.0)
	perto(A.fase(andar, m, 250.0), 0.5, 0.001, "metade do passo")
	perto(A.fase(andar, m, 500.0), 0.0, 0.001, "loop fecha")
	var morder := _mem("bite", 0.0)
	perto(A.fase(morder, m, 210.0), 0.5, 0.001, "metade da mordida")
	perto(A.fase(morder, m, 999.0), 1.0, 0.001, "fim não passa de 1")


func test_retrato_do_corpo() -> void:
	var f := Fake.new()
	f.tonto = 0.5
	f.carga = true
	f.ar = true
	var r := A.retrato(f, true)
	checar(bool(r["atordoado"]), "atordoado no retrato")
	checar(bool(r["carregando"]), "carga no retrato")
	checar(bool(r["no_ar"]), "ar no retrato")
	checar(bool(r["andando"]), "andando no retrato")
	f.sprint = true
	checar(bool(A.retrato(f, true)["correndo"]), "correndo no retrato")
	igual(String(r["golpe"]), "", "sem golpe")
	f.ataque = "batida"
	igual(String(A.retrato(f, false)["golpe"]), "batida", "golpe no retrato")


func test_corrida_e_transicoes_de_pulo() -> void:
	var m := _cat()
	var mem := A.resolver({"andando": true}, m, _mem("", 0.0), 0.0)
	igual(mem["id"], "walk", "andar")
	mem = A.resolver({"andando": true, "correndo": true}, m, mem, 100.0)
	igual(mem["id"], "run", "correr troca a base")
	mem = A.resolver({"saltou": true}, m, mem, 200.0)
	igual(mem["id"], "jump_start", "saída do chão")
	mem = A.resolver({"no_ar": true}, m, mem, 250.0)
	igual(mem["id"], "jump_start", "início segura a cena")
	mem = A.resolver({"no_ar": true}, m, mem, 400.0)
	igual(mem["id"], "jump_air", "depois vem o ar")
	mem = A.resolver({"pousou": true}, m, mem, 500.0)
	igual(mem["id"], "jump_land", "pouso corta o ar")
	mem = A.resolver({}, m, mem, 700.0)
	igual(mem["id"], "idle", "pouso termina em parado")
