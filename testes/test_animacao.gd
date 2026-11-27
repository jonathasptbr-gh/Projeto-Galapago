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
	var cauda := false
	var rota := true
	var caminhada := true

	func em_rota() -> bool:
		return rota

	func _fator_sprint() -> float:
		return 1.6 if sprint or cauda else 1.0

	func atordoado() -> bool:
		return tonto > 0.0

	func carregando() -> bool:
		return carga

	func no_ar() -> bool:
		return ar

	func correndo() -> bool:
		return sprint

	func caminhada_existe() -> bool:
		return caminhada


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


func test_salto_em_corrida_preserva_impulso_sem_mudar_catalogo() -> void:
	var m := _cat()
	var mem := A.resolver({"andando": true, "correndo": true}, m, {}, 0.0)
	igual(mem["id"], "run", "sprint ativo")
	mem = A.resolver({"saltou": true, "no_ar": true}, m, mem, 80.0)
	igual(mem["id"], "jump_start", "impulso inicial")
	checar(bool(mem.get("salto_correndo", false)), "salto herda corrida anterior")
	mem = A.resolver({"no_ar": true}, m, mem, 240.0)
	igual(mem["id"], "jump_air", "sprint no ar")
	checar(bool(mem.get("salto_correndo", false)), "ar mantém impulso sem correndo()")
	mem = A.resolver({"pousou": true}, m, mem, 320.0)
	igual(mem["id"], "jump_land", "pouso")
	checar(bool(mem.get("salto_correndo", false)), "pouso mantém impulso")
	mem = A.resolver({}, m, mem, 510.0)
	igual(mem["id"], "idle", "retorna ao repouso")
	checar(not bool(mem.get("salto_correndo", false)), "sinal só existe durante salto")
	var parado := A.resolver({"saltou": true}, m, {}, 0.0)
	checar(not bool(parado.get("salto_correndo", false)), "salto parado permanece distinto")


func test_salto_parado_nao_vira_sprint_no_ar() -> void:
	var m := _cat()
	var mem := A.resolver({"saltou": true, "no_ar": true}, m, {}, 0.0)
	checar(not bool(mem.get("salto_correndo", false)), "decolou parado")
	mem = A.resolver({"no_ar": true, "correndo": true, "impulso_corrida": true}, m, mem, 150.0)
	igual(mem["id"], "jump_air", "entrou no ar")
	checar(not bool(mem.get("salto_correndo", false)), "sprint surgido no ar não altera pose")
	mem = A.resolver({"pousou": true, "correndo": true}, m, mem, 200.0)
	checar(not bool(mem.get("salto_correndo", false)), "pouso também não captura sprint tardio")


func test_cauda_fisica_herda_impulso_ao_decolar() -> void:
	var m := _cat()
	var f := Fake.new()
	f.sprint = true
	var mem := A.resolver(A.retrato(f, true), m, {}, 0.0)
	igual(mem["id"], "run", "começou em sprint")
	f.sprint = false
	f.cauda = true
	mem = A.resolver(A.retrato(f, true), m, mem, 20.0)
	igual(mem["id"], "walk", "soltar mudou só apresentação da marcha")
	f.ar = true
	var lancamento := A.retrato(f, true, true)
	checar(bool(lancamento["impulso_corrida"]), "cauda física com deslocamento tem impulso")
	mem = A.resolver(lancamento, m, mem, 40.0)
	igual(mem["id"], "jump_start", "saltou na cauda")
	checar(bool(mem.get("salto_correndo", false)), "pulo herdou impulso mesmo após clipe walk")
	f.cauda = false
	mem = A.resolver(A.retrato(f, true), m, mem, 220.0)
	checar(bool(mem.get("salto_correndo", false)), "sinal permanece no ar após cauda zerar")
	f.ar = false
	checar(not bool(A.retrato(f, false, true)["impulso_corrida"]), "sem deslocamento não inventa impulso")
	f.cauda = true
	f.rota = false
	checar(not bool(A.retrato(f, true, true)["impulso_corrida"]), "inércia fora da rota não recebe fator aéreo")


## v0.34 — o MODO DA CÂMERA manda no clipe base: de LONGE não existe
## caminhada (andando, ela já está em CORRIDA — nunca `walk`); de PERTO o
## `walk` continua. O sprint, de longe, só acelera: o clipe segue `run`.
func test_longe_anda_em_corrida_e_perto_mantem_a_caminhada() -> void:
	var m := _cat()
	var f := Fake.new()
	f.caminhada = false
	igual(A.desejado(A.retrato(f, true), m), "run", "de longe, andar pede corrida")
	igual(String(A.resolver(A.retrato(f, true), m, {}, 0.0)["id"]), "run", "e o clipe resolvido é o run")
	f.caminhada = true
	igual(A.desejado(A.retrato(f, true), m), "walk", "de perto, andar pede caminhada")
	f.sprint = true
	igual(A.desejado(A.retrato(f, true), m), "run", "de perto, o sprint pede corrida")
	f.sprint = false
	igual(A.desejado({"andando": true, "caminhada": false}, m), "run", "longe sem sprint continua corrida")
	igual(A.desejado({"andando": true, "caminhada": false, "correndo": true}, m), "run", "longe acelerada é corrida")
	igual(A.desejado({"andando": true}, m), "walk", "sem o campo, o padrão é a caminhada")


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
