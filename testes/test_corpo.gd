extends "res://testes/caso.gd"

const M := preload("res://sim/mundo.gd")
const Corpo := preload("res://sim/corpo.gd")

var terrenos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/terrenos.json"))
var acoes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/acoes.json"))


func _setup(celulas: Array, subsolo: Array = []) -> Array:
	var m := M.criar({"celula_px": 32, "celulas": celulas, "subsolo": subsolo}, terrenos)
	var c := Corpo.new(acoes)
	c.pos = Vector2(48, 16)
	return [m, c]


func _rodar(c: RefCounted, m: RefCounted, segundos: float, dt := 1.0 / 30.0) -> Array:
	var todos: Array = []
	var t := 0.0
	while t < segundos:
		c.passo(dt, m)
		todos.append_array(c.drenar_eventos())
		t += dt
	return todos


func test_ataque_passa_pelas_tres_fases_e_volta_a_parado() -> void:
	var s := _setup([",,,,,,"])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	igual(c.comandar({"acao": "ataque_x", "direcao": Vector2.RIGHT}, m), "aceito", "aceito")
	var ev: Array = c.drenar_eventos() + _rodar(c, m, 1.0)
	igual(ev, ["antecipacao:ataque_x", "inicio:ataque_x", "ativo:ataque_x", "recuperacao:ataque_x", "fim:ataque_x"], "fases em ordem")
	igual(c.estado, "parado", "parado")
	checar(c.pos.x > 48.0, "deu o passinho do golpe")


func test_golpe_so_vale_na_fase_ativa() -> void:
	var s := _setup([",,,,,,"])
	var c: RefCounted = s[1]
	c.comandar({"acao": "ataque_y", "direcao": Vector2.RIGHT}, s[0])
	igual(c.golpe_ativo(), {}, "antecipação: ainda não")
	_rodar(c, s[0], 0.25)
	checar(not c.golpe_ativo().is_empty(), "ativa: vale")


func test_ocupado_guarda_na_recuperacao_e_recusa_antes() -> void:
	var s := _setup([",,,,,,"])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "ataque_x", "direcao": Vector2.RIGHT}, m)
	checar(c.comandar({"acao": "ataque_y", "direcao": Vector2.RIGHT}, m).begins_with("recusado"), "na antecipação recusa")
	_rodar(c, m, 0.27)
	igual(c.fase, "recuperacao", "chegou na recuperação")
	igual(c.comandar({"acao": "ataque_y", "direcao": Vector2.RIGHT}, m), "guardado", "guarda")
	var ev: Array = _rodar(c, m, 0.3)
	checar("inicio:ataque_y" in ev, "o guardado saiu em seguida")


func test_recarga() -> void:
	var s := _setup([",,,,,,"])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "investida", "direcao": Vector2.RIGHT}, m)
	_rodar(c, m, 0.45)
	igual(c.estado, "parado", "terminou")
	igual(c.comandar({"acao": "investida", "direcao": Vector2.RIGHT}, m), "recusado: recarga", "em recarga")
	_rodar(c, m, 0.6)
	igual(c.comandar({"acao": "investida", "direcao": Vector2.RIGHT}, m), "aceito", "recarga acabou")


func test_investida_para_na_parede() -> void:
	var s := _setup([",,#,,,"])
	var c: RefCounted = s[1]
	c.comandar({"acao": "investida", "direcao": Vector2.RIGHT}, s[0])
	_rodar(c, s[0], 1.0)
	checar(c.pos.x < 64.0, "não atravessou a rocha (x=%s)" % c.pos.x)


func test_pulo_sobre_o_canal_com_altura() -> void:
	var s := _setup([",,~~,,"])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "pular", "alvo": Vector2(4 * 32 + 16, 16)}, m)
	var zmax := 0.0
	for i in 40:
		c.passo(1.0 / 30.0, m)
		zmax = maxf(zmax, c.z)
	igual(m.celula_de(c.pos), Vector2i(4, 0), "pousou do outro lado")
	checar(zmax > 20.0, "subiu no ar (z máx %s)" % zmax)
	perto(c.z, 0.0, 0.001, "voltou ao chão")


func test_defender_sustenta_enquanto_segura() -> void:
	var s := _setup([",,,,,,"])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "defender"}, m)
	_rodar(c, m, 2.0)
	checar(c.defendendo(), "segue defendendo enquanto segura")
	c.comandar({"acao": "soltar"}, m)
	_rodar(c, m, 0.5)
	checar(not c.defendendo(), "soltou")
	igual(c.estado, "parado", "parado")


func test_escavar_desce_e_sobe() -> void:
	var s := _setup([":,,,:"], ["====="])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.pos = Vector2(16, 16)
	igual(c.comandar({"acao": "escavar"}, m), "aceito", "escava")
	_rodar(c, m, 1.2)
	igual(c.camada, M.SUBSOLO, "no subsolo")
	checar(c.comandar({"acao": "pular"}, m).begins_with("recusado"), "não pula no subsolo")
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(4 * 32 + 16, 16)])}, m)
	_rodar(c, m, 2.0)
	igual(m.celula_de(c.pos), Vector2i(4, 0), "andou no túnel")
	c.comandar({"acao": "escavar"}, m)
	_rodar(c, m, 1.2)
	igual(c.camada, M.SUPERFICIE, "voltou à superfície")


func test_mover_respeita_o_mundo() -> void:
	var s := _setup([",,,~~,"])
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(5 * 32 + 16, 16)])}, s[0])
	_rodar(c, s[0], 3.0)
	checar(c.pos.x < 96.0, "parou antes da água (x=%s)" % c.pos.x)
