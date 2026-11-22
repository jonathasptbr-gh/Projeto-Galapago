extends "res://testes/caso.gd"
## ADVERSÁRIO HOSTIL (v0.14): caçada, preparação, as áreas demarcadas (círculo
## do bote, faixa do esbarrão, linha do cuspe), o especial de esconder e o
## golpe que empurra/atordoa a criatura.
##
## Os testes de ATAQUE usam um ALVO FALSO (posição fixa e `levar_golpe` que só
## anota o que recebeu): assim a asserção é sobre o que o inimigo decidiu, sem
## a autonomia da criatura no meio. O golpe REAL é testado em `sim/corpo.gd`.

const M := preload("res://sim/mundo.gd")
const Corpo := preload("res://sim/corpo.gd")
const Adversario := preload("res://sim/adversario.gd")
const Alvos := preload("res://sim/alvos.gd")

var terrenos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/terrenos.json"))
var acoes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/acoes.json"))
var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/adversario.json"))

const DT := 1.0 / 30.0


## Alvo de mentira: fica onde mandarem e anota os golpes que levar.
class AlvoFalso:
	var pos := Vector2.ZERO
	var golpes: Array = []

	func levar_golpe(dir: Vector2, forca: float, atordoamento: float) -> bool:
		golpes.append({"dir": dir, "forca": forca, "atordoamento": atordoamento})
		return true


func _mundo(linhas: Array = []) -> RefCounted:
	if linhas.is_empty():
		for y in 12:
			linhas.append(",".repeat(24))
	return M.criar({"celula_px": 32, "celulas": linhas}, terrenos)


func _adv(p: Vector2, semente := 7, hostil := true) -> RefCounted:
	var a := Adversario.new(semente, Rect2(), cfg)
	a.pos = p
	if hostil:
		a.definir_hostil(true)
	return a


func _alvo(p: Vector2) -> AlvoFalso:
	var c := AlvoFalso.new()
	c.pos = p
	return c


## Avança até aparecer um evento que comece com `prefixo` (devolve todos).
func _ate_evento(a: RefCounted, m: RefCounted, alvo: Variant, prefixo: String,
		limite := 3.0) -> Array:
	var evs: Array = []
	var t := 0.0
	while t < limite:
		a.passo(DT, m, alvo)
		for e in a.drenar_eventos():
			evs.append(e)
			if str(e).begins_with(prefixo):
				return evs
		t += DT
	return evs


func _rodar(a: RefCounted, m: RefCounted, alvo: Variant, segundos: float) -> Array:
	var evs: Array = []
	var t := 0.0
	while t < segundos:
		a.passo(DT, m, alvo)
		evs.append_array(a.drenar_eventos())
		t += DT
	return evs


# ---------------------------------------------------------------- caçada

func test_hostil_persegue_e_e_mais_rapido_que_o_passeio() -> void:
	var m := _mundo()
	var perseguidor := _adv(Vector2(64, 100), 7, true)
	var passivo := _adv(Vector2(64, 100), 7, false)
	var alvo := _alvo(Vector2(720, 100))  # longe: só persegue, não ataca ainda
	for i in 45:                          # 1,5 s
		perseguidor.passo(DT, m, alvo)
		passivo.passo(DT, m)
	checar(perseguidor.pos.x > 140.0, "hostil ANDOU para o alvo (x=%.1f)" % perseguidor.pos.x)
	var d0 := Vector2(64, 100).distance_to(alvo.pos)
	checar(perseguidor.pos.distance_to(alvo.pos) < d0 - 60.0, "hostil encurtou a distância")
	checar(passivo.pos.distance_to(Vector2(64, 100)) < 40.0, "passivo continua vagueando devagar")


func test_hostil_mesma_semente_mesma_cacada() -> void:
	var m := _mundo()
	var a := _adv(Vector2(80, 96), 21, true)
	var b := _adv(Vector2(80, 96), 21, true)
	var alvo_a := _alvo(Vector2(300, 120))
	var alvo_b := _alvo(Vector2(300, 120))
	for i in 90:
		a.passo(DT, m, alvo_a)
		b.passo(DT, m, alvo_b)
	perto_v(a.pos, b.pos, 0.001, "mesma semente, mesma caçada")
	perto_v(a.olhar, b.olhar, 0.001, "mesmo olhar")


func test_hostil_nao_entra_na_agua() -> void:
	var linhas: Array = []
	for y in 10:
		var l := ",,,,,,,,,,,"  # 11 células; água nas colunas 5 e 6
		l = l.substr(0, 5) + "~~" + l.substr(7)
		linhas.append(l)
	var m := _mundo(linhas)
	var a := _adv(Vector2(80, 96), 3, true)
	var alvo := _alvo(Vector2(300, 96))
	for i in 240:  # 8 s tentando atravessar
		a.passo(DT, m, alvo)
		checar(m.andavel(m.celula_de(a.pos), M.SUPERFICIE), "nunca na água (%s)" % a.pos)


# ---------------------------------------------------------------- bote

func test_bote_demarca_circulo_e_acerta_quem_fica() -> void:
	var m := _mundo()
	var a := _adv(Vector2(100, 100), 5, true)
	var alvo := _alvo(Vector2(140, 100))  # 40 px: só o bote serve
	var evs := _ate_evento(a, m, alvo, "perigo:bote", 1.5)
	checar("perigo:bote" in evs, "avisou o preparo do bote")
	checar(not a.perigos.is_empty(), "a área demarcada está viva")
	if not a.perigos.is_empty():
		igual(str(a.perigos[0]["forma"]), "circulo", "bote demarca um círculo")
		checar(float(a.perigos[0]["raio"]) > 0.0, "círculo tem raio")
	# continua: no fim do preparo o golpe cai
	evs = _ate_evento(a, m, alvo, "acerta:bote", 2.0)
	checar("acerta:bote" in evs, "o bote acertou quem ficou")
	igual(alvo.golpes.size(), 1, "um golpe só")
	if alvo.golpes.size() == 1:
		perto(float(alvo.golpes[0]["forca"]), 70.0, 0.01, "empurrão do bote")
		perto(float(alvo.golpes[0]["atordoamento"]), 0.45, 0.01, "atordoamento do bote")


func test_bote_erra_quem_sai_do_circulo() -> void:
	var m := _mundo()
	var a := _adv(Vector2(100, 100), 5, true)
	var alvo := _alvo(Vector2(140, 100))
	_ate_evento(a, m, alvo, "perigo:bote", 1.5)
	alvo.pos += Vector2(0, -90)  # saiu da área antes do golpe
	var evs := _rodar(a, m, alvo, 2.0)
	checar(not ("acerta:bote" in evs), "quem saiu do círculo não levou o bote")


# ---------------------------------------------------------------- esbarrão

func test_esbarrao_demarca_faixa_e_acerta_quem_fica_na_linha() -> void:
	var m := _mundo()
	var a := _adv(Vector2(100, 100), 9, true)
	var alvo := _alvo(Vector2(240, 100))  # 140 px: esbarrão (cuspe só a partir de 150)
	var evs := _ate_evento(a, m, alvo, "perigo:esbarrao", 1.5)
	checar("perigo:esbarrao" in evs, "avisou o preparo do esbarrão")
	if not a.perigos.is_empty():
		igual(str(a.perigos[0]["forma"]), "faixa", "esbarrão demarca uma faixa")
		checar(float(a.perigos[0]["largura"]) > 0.0, "faixa tem largura")
	evs = _ate_evento(a, m, alvo, "acerta:esbarrao", 2.0)
	checar("acerta:esbarrao" in evs, "acertou quem ficou no corredor")
	igual(alvo.golpes.size(), 1, "um golpe só")
	if alvo.golpes.size() == 1:
		checar(float(alvo.golpes[0]["forca"]) > 70.0, "esbarrão empurra mais que o bote")
		checar(float(alvo.golpes[0]["atordoamento"]) > 0.45, "e atordoa mais")


func test_esbarrao_erra_quem_sai_da_faixa() -> void:
	var m := _mundo()
	var a := _adv(Vector2(100, 100), 9, true)
	var alvo := _alvo(Vector2(240, 100))
	_ate_evento(a, m, alvo, "perigo:esbarrao", 1.5)
	alvo.pos += Vector2(0, -70)  # fora da largura da faixa
	var evs := _rodar(a, m, alvo, 2.0)
	checar(not ("acerta:esbarrao" in evs), "quem saiu do corredor não levou o esbarrão")


# ---------------------------------------------------------------- cuspe

func test_cuspe_demarca_linha_e_acerta_quem_fica() -> void:
	var m := _mundo()
	var a := _adv(Vector2(100, 100), 4, true)
	var alvo := _alvo(Vector2(400, 100))  # 300 px: só o cuspe
	var evs := _ate_evento(a, m, alvo, "perigo:cuspe", 1.5)
	checar("perigo:cuspe" in evs, "avisou o preparo do cuspe")
	if not a.perigos.is_empty():
		igual(str(a.perigos[0]["forma"]), "linha", "cuspe demarca uma linha")
	evs = _ate_evento(a, m, alvo, "acerta:cuspe", 3.0)
	checar("acerta:cuspe" in evs, "o projétil acertou quem ficou na linha")
	igual(alvo.golpes.size(), 1, "um golpe só")
	if alvo.golpes.size() == 1:
		perto(float(alvo.golpes[0]["forca"]), 40.0, 0.01, "empurrão do cuspe")


func test_cuspe_erra_quem_sai_da_linha() -> void:
	var m := _mundo()
	var a := _adv(Vector2(100, 100), 4, true)
	var alvo := _alvo(Vector2(400, 100))
	_ate_evento(a, m, alvo, "perigo:cuspe", 1.5)
	alvo.pos += Vector2(0, -60)  # saiu da linha
	var evs := _rodar(a, m, alvo, 3.0)
	checar(not ("acerta:cuspe" in evs), "quem saiu da linha não levou o cuspe")


# ---------------------------------------------------------------- esconder

func test_golpe_faz_esconder_e_ficar_intocavel() -> void:
	var m := _mundo()
	var a := _adv(Vector2(100, 100), 6, true)
	var alvo := _alvo(Vector2(140, 100))
	a.empurrar(Vector2.RIGHT, 30.0)
	_rodar(a, m, alvo, 1.2)  # empurrão acaba, ele afunda
	checar(a.oculto(), "ficou escondido depois do golpe")
	checar(not a.alvo_visivel(), "escondido não é alvo")
	var lista := Alvos.montar([], [a], m)
	Alvos.sincronizar(lista, [a])
	checar(not Alvos.reage(lista[0]), "a lista diz que ele não reage")
	checar(not Alvos.empurrar(lista, "adversario:0", Vector2.RIGHT, 50.0), "não dá para bater no escondido")
	# reaparece sozinho, perto, depois do tempo
	_rodar(a, m, alvo, 2.6)
	checar(not a.oculto(), "reapareceu")
	checar(a.alvo_visivel(), "voltou a ser alvo")
	checar(a.pos.distance_to(Vector2(100, 100)) > 20.0, "reapareceu em outro lugar")


func test_desligar_hostilidade_tira_o_esconderijo() -> void:
	var m := _mundo()
	var a := _adv(Vector2(100, 100), 6, true)
	var alvo := _alvo(Vector2(140, 100))
	a.empurrar(Vector2.RIGHT, 30.0)
	_rodar(a, m, alvo, 1.2)
	checar(a.oculto(), "estava escondido")
	a.definir_hostil(false)
	checar(not a.oculto(), "desligar a hostilidade revela")
	igual(a.estado_atual(), "vagar", "volta ao passeio")
	checar(a.perigos.is_empty(), "sem área demarcada pendente")


# ---------------------------------------------------------------- golpe real

func test_corpo_leva_golpe_empurra_atordoa_e_nao_obedece() -> void:
	var m := _mundo()
	var c := Corpo.new(acoes)
	c.rng.seed = 3
	c.pos = Vector2(100, 120)
	checar(c.levar_golpe(Vector2.RIGHT, 60.0, 0.5), "levou o golpe")
	checar(c.atordoado(), "ficou atordoada")
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(200, 120)])}, m).begins_with("recusado"),
		"atordoada recusa comando")
	checar(not c.levar_golpe(Vector2.LEFT, 60.0, 0.5), "a janela de invencibilidade segura o segundo golpe")
	for i in 24:  # 0,8 s: o empurrão desliza e o atordoamento passa
		c.passo(DT, m)
	checar(c.pos.x > 130.0, "o empurrão levou a criatura (x=%.1f)" % c.pos.x)
	checar(not c.atordoado(), "o atordoamento acaba")
	c.camada = M.SUBSOLO
	checar(not c.levar_golpe(Vector2.RIGHT, 60.0, 0.5), "no subsolo o golpe não pega")
