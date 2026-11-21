extends "res://testes/caso.gd"

const M := preload("res://sim/mundo.gd")
const Corpo := preload("res://sim/corpo.gd")
const Adversario := preload("res://sim/adversario.gd")

var terrenos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/terrenos.json"))
var acoes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/acoes.json"))

# Mapa amplo (8×12 células = 384×256 px): cabe rota horizontal e vertical. A
# criatura começa em (48, 48) = célula (1,1). Depois que a rota termina ela
# entra em AUTONOMIA e anda sozinha — por isso as asserções de rota medem no
# MOMENTO em que a rota acaba (`_seguir_ate_fim`), não no fim do teste.
const MAPA := [
	",,,,,,,,,,,,", ",,,,,,,,,,,,", ",,,,,,,,,,,,", ",,,,,,,,,,,,",
	",,,,,,,,,,,,", ",,,,,,,,,,,,", ",,,,,,,,,,,,", ",,,,,,,,,,,,",
]
const AGUA := [",,,,,,,,,,,,", ",,~~,,,,,,,,", ",,,,,,,,,,,,"]
const TERRA := [",,,,,,,,,,,,", ":,,,:,,,,,,,", ",,,,,,,,,,,,"]
const TUNEL := ["", "=====,,,,,,,", ""]


func _setup(celulas: Array, subsolo: Array = [], semente := 5) -> Array:
	var m := M.criar({"celula_px": 32, "celulas": celulas, "subsolo": subsolo}, terrenos)
	var c := Corpo.new(acoes)
	c.rng.seed = semente
	c.pos = Vector2(48, 48)
	return [m, c]


## Avança até a ROTA ACABAR (ou o limite). Devolve os eventos.
func _seguir_ate_fim(c: RefCounted, m: RefCounted, alvos: Array = [], limite_s := 8.0) -> Array:
	var evs: Array = []
	var t := 0.0
	while c.em_rota() and t < limite_s:
		c.passo(1.0 / 30.0, m, alvos)
		evs.append_array(c.drenar_eventos())
		t += 1.0 / 30.0
	return evs


func _rodar(c: RefCounted, m: RefCounted, segundos: float, alvos: Array = [], dt := 1.0 / 30.0) -> Array:
	var todos: Array = []
	var t := 0.0
	while t < segundos:
		c.passo(dt, m, alvos)
		todos.append_array(c.drenar_eventos())
		t += dt
	return todos


func _alvo(id: String, pos: Vector2, tipo := "arvore") -> Dictionary:
	return {"id": id, "tipo": tipo, "pos": pos, "raio": 14.0, "travavel": true, "interativo": false, "dados": {}}


# ---------------------------------------------------------------- rota

func test_rota_percorre_ate_o_fim_e_entra_em_autonomia() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(240, 48)])}, m, []).begins_with("ok"), "aceitou a rota")
	checar(c.em_rota(), "está em rota")
	var evs := _seguir_ate_fim(c, m)
	checar(not c.em_rota(), "rota terminou")
	checar(c.pos.x > 225.0, "chegou ao fim da rota (x=%s)" % c.pos.x)
	checar("rota:fim" in evs, "avisou o fim")
	_rodar(c, m, 3.0)
	checar(c.autonomia in ["parado", "vagar"], "depois fica parada ou vagueia (%s)" % c.autonomia)


## A REGRA CENTRAL: ataque NÃO cancela a rota.
func test_ataque_nao_cancela_a_rota() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(400, 48)])}, m, [])
	_rodar(c, m, 0.3)
	var x0: float = c.pos.x
	checar(c.comandar({"acao": "ataque"}, m, []).begins_with("ok"), "atacou")
	checar(c.em_rota(), "a rota CONTINUA")
	_rodar(c, m, 0.5)
	checar(c.pos.x > x0 + 30.0, "seguiu andando durante o golpe (x %s → %s)" % [x0, c.pos.x])

func test_pulo_e_arco_sem_cancelar_a_rota() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(400, 48)])}, m, [])
	var zmax := 0.0
	_rodar(c, m, 0.1)
	checar(c.comandar({"acao": "pular"}, m, []).begins_with("ok"), "pulou")
	for i in 20:
		c.passo(1.0 / 30.0, m, [])
		zmax = maxf(zmax, c.z)
	checar(zmax > 12.0, "subiu no ar (z máx %s)" % zmax)
	perto(c.z, 0.0, 0.01, "voltou ao chão")
	checar(c.em_rota(), "rota continua depois do pulo")

func test_nova_rota_substitui_a_anterior() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(400, 48)])}, m, [])
	_rodar(c, m, 0.2)
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(48, 240)])}, m, [])
	_rodar(c, m, 1.0)
	checar(c.pos.y > 100.0, "seguiu a rota NOVA (y=%s)" % c.pos.y)
	checar(c.pos.x < 120.0, "e abandonou a antiga (x=%s)" % c.pos.x)


# ---------------------------------------------------------------- alvo

func test_travar_solta_e_mira_no_movel() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var alvos := [_alvo("arvore:3,1", Vector2(112, 48)), _alvo("adversario:0", Vector2(200, 48), "adversario")]
	checar(c.comandar({"acao": "travar", "alvo": Vector2(112, 40)}, m, alvos).begins_with("ok"), "travou na árvore")
	igual(c.alvo_id, "arvore:3,1", "id certo")
	igual(c.comandar({"acao": "travar", "alvo": Vector2(112, 40)}, m, alvos), "ok: mira solta", "mesmo alvo solta")
	igual(c.alvo_id, "", "soltou")
	c.comandar({"acao": "travar", "alvo": Vector2(200, 48)}, m, alvos)
	igual(c.alvo_id, "adversario:0", "travou no adversário")
	alvos[1]["pos"] = Vector2(48, 140)  # o adversário ANDOU
	c.comandar({"acao": "ataque"}, m, alvos)
	checar(c.ataque_dir.y > 0.9, "golpe para onde o alvo está AGORA (%s)" % c.ataque_dir)


func test_ataque_sem_alvo_usa_a_direcao_da_rota() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(400, 120)])}, m, [])
	_rodar(c, m, 0.2)
	c.comandar({"acao": "ataque"}, m, [])
	checar(c.ataque_dir.x > 0.5, "golpe na direção em que segue (%s)" % c.ataque_dir)


func test_interagir_com_bau_nao_trava() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var bau := {"id": "bau:2,1", "tipo": "bau", "pos": Vector2(80, 48), "raio": 14.0, "travavel": false, "interativo": true, "dados": {}}
	checar(c.comandar({"acao": "travar", "alvo": Vector2(80, 48)}, m, [bau]).begins_with("ok"), "interagiu")
	igual(c.alvo_id, "", "não travou mira")
	checar("interagir:bau:2,1" in c.drenar_eventos(), "evento de interação")


# ---------------------------------------------------------------- autonomia

func test_autonomia_vai_ate_o_alvo_marcado() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var alvos := [_alvo("adversario:0", Vector2(280, 48), "adversario")]
	c.comandar({"acao": "travar", "alvo": Vector2(280, 48)}, m, alvos)
	var antes: float = c.pos.distance_to(Vector2(280, 48))
	_rodar(c, m, 5.0, alvos)
	var depois: float = c.pos.distance_to(alvos[0]["pos"])
	checar(depois < antes - 60.0, "chegou mais perto do alvo (%s → %s)" % [antes, depois])


func test_autonomia_e_deterministica_com_a_mesma_semente() -> void:
	var a := _setup(MAPA, [], 99)
	var b := _setup(MAPA, [], 99)
	for i in 150:
		a[1].passo(1.0 / 30.0, a[0], [])
		b[1].passo(1.0 / 30.0, b[0], [])
	perto_v(a[1].pos, b[1].pos, 0.001, "mesma semente, mesmo passeio")


func test_autonomia_nao_sai_do_mundo() -> void:
	var s := _setup(MAPA, [], 3)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	_rodar(c, m, 20.0)
	checar(m.dentro(m.celula_de(c.pos)), "ficou dentro do mapa (%s)" % c.pos)


# ---------------------------------------------------------------- mundo

func test_mover_respeita_o_mundo() -> void:
	var s := _setup(AGUA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(300, 48)])}, m, [])
	_rodar(c, m, 3.0)
	checar(c.pos.x < 96.0, "parou antes da água (x=%s)" % c.pos.x)


func test_escavar_desce_anda_no_tunel_e_sobe() -> void:
	var s := _setup(TERRA, TUNEL)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.pos = Vector2(16, 48)  # célula (0,1) = terra fofa
	checar(c.comandar({"acao": "habilidade"}, m, []).begins_with("ok"), "escava")
	_rodar(c, m, 1.2)
	igual(c.camada, M.SUBSOLO, "no subsolo")
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(144, 48)])}, m, []).begins_with("ok"), "rota no túnel")
	_seguir_ate_fim(c, m)
	igual(m.celula_de(c.pos), Vector2i(4, 1), "andou no túnel até a saída (pos %s)" % c.pos)
	checar(c.comandar({"acao": "habilidade"}, m, []).begins_with("ok"), "escava para subir")
	_rodar(c, m, 1.2)
	igual(c.camada, M.SUPERFICIE, "voltou à superfície")


# ---------------------------------------------------------------- v0.6: rota por waypoints

func _setup_objeto(objetos: Array, semente := 5) -> Array:
	var m := M.criar({"celula_px": 32, "celulas": MAPA, "subsolo": [], "objetos": objetos}, terrenos)
	var c := Corpo.new(acoes)
	c.rng.seed = semente
	c.pos = Vector2(48, 48)
	return [m, c]


## A criatura contorna um TRONCO (desvio local) e continua a rota.
func test_rota_desvia_de_objeto_e_continua() -> void:
	var s := _setup_objeto([{"tipo": "arvore", "celula": [3, 1]}])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(240, 48)])}, m, []).begins_with("ok"), "rota")
	var evs := _seguir_ate_fim(c, m, [], 10.0)
	checar("rota:fim" in evs, "terminou a rota")
	checar(c.pos.x > 200.0, "passou do tronco (x=%s)" % c.pos.x)


## Água é BARREIRA: para, mas a rota fica guardada. Um pulo durante a rota
## passa por cima e retoma o percurso.
func test_barreira_para_a_rota_e_pulo_retoma() -> void:
	var s := _setup([",,~,,,"])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.pos = Vector2(16, 16)
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(176, 16)])}, m, [])
	_rodar(c, m, 2.0)
	checar(c.em_rota(), "rota continua guardada")
	checar(c.barrado(), "parada na barreira")
	checar(c.pos.x < 96.0, "antes da água (x=%s)" % c.pos.x)
	checar(c.comandar({"acao": "pular"}, m, []).begins_with("ok"), "pulou")
	_rodar(c, m, 1.2)
	checar(c.pos.x > 96.0, "passou da água (x=%s)" % c.pos.x)


## O desconto inicial: a ida e volta do começo do traço não é obedecida.
func test_desconto_inicial_nao_volta_no_comeco() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(28, 48), Vector2(48, 48), Vector2(160, 48)])}, m, [])
	igual(c.rota.size(), 2, "cortou o vai-e-volta (%s)" % [c.rota])
	checar(c.rota.size() == 2 and c.rota[1].x > 48.0, "segue para a frente")


func test_rota_passa_pelos_pontos_na_ordem() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(200, 48), Vector2(200, 200), Vector2(48, 200)])}, m, [])
	var vistos: Array = []
	var t := 0.0
	while c.em_rota() and t < 10.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		t += 1.0 / 30.0
		for par in [["a", Vector2(200, 48)], ["b", Vector2(200, 200)], ["c", Vector2(48, 200)]]:
			if not par[0] in vistos and c.pos.distance_to(par[1]) < 24.0:
				vistos.append(par[0])
	igual(vistos, ["a", "b", "c"], "ordem dos pontos (%s)" % [vistos])


## Pulo curto não atravessa canal largo: cai na água, a rota para, e é preciso
## OUTRO pulo. É a regra "sem pular, para na barreira; pulando, segue".
func test_pulo_curto_cai_na_agua_e_precisa_de_outro() -> void:
	var s := _setup([",,~~,,"])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.pos = Vector2(16, 16)
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(176, 16)])}, m, [])
	_rodar(c, m, 2.0)
	checar(c.comandar({"acao": "pular"}, m, []).begins_with("ok"), "1º pulo")
	_rodar(c, m, 0.6)
	checar(c.pos.x > 64.0 and c.pos.x < 128.0, "caiu na água (x=%s)" % c.pos.x)
	checar(c.barrado(), "parada na água")
	_rodar(c, m, 0.4)
	checar(c.comandar({"acao": "pular"}, m, []).begins_with("ok"), "2º pulo")
	_rodar(c, m, 0.8)
	checar(c.pos.x > 128.0, "saiu da água (x=%s)" % c.pos.x)


# ---------------------------------------------------------------- v0.7: traço ao vivo

## O traço desenhado AO VIVO: a rota nasce na origem, a criatura já anda por
## ela e, quando o dedo acrescenta pontos, o progresso NUNCA volta ao começo.
func test_traco_ao_vivo_cresce_sem_voltar() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var origem := Vector2(48, 48)
	checar(c.tracar(PackedVector2Array([origem, Vector2(140, 48)]), m, true).begins_with("ok"), "a rota nasce")
	checar(c.em_rota(), "está seguindo")
	_rodar(c, m, 0.3)
	var andado: float = c.rota_t
	checar(andado > 1.0, "já andou enquanto desenhava (%s)" % andado)
	perto_v(c.rota[0], origem, 0.001, "a origem não se move")
	checar(c.tracar(PackedVector2Array([origem, Vector2(140, 48), Vector2(280, 48)]), m, false).begins_with("ok"), "o traço cresce")
	perto(c.rota_t, andado, 0.001, "atualizar o traço não zera o progresso")
	checar(c.rota[c.rota.size() - 1].x > 200.0, "o fim da rota é o dedo (%s)" % [c.rota])
	_rodar(c, m, 1.2)
	checar(c.pos.x > 200.0, "seguiu até o fim (x=%s)" % c.pos.x)


## A linha não anda junto com o animal: se ele se mexeu antes do traço começar,
## o primeiro trecho o traz de volta ao começo (a origem congelada).
func test_traco_comeca_onde_ela_estava_na_descida() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var origem := Vector2(48, 48)
	c.pos = Vector2(96, 48)  # ela andou 48 px antes de o traço começar
	checar(c.tracar(PackedVector2Array([origem, Vector2(176, 48)]), m, true).begins_with("ok"), "a rota nasce")
	perto_v(c.rota[0], c.pos, 1.0, "o 1º ponto é ONDE ELA ESTÁ")
	checar(c.rota[1].distance_to(origem) < 1.0, "o 2º é o começo do traço (%s)" % [c.rota])
	_rodar(c, m, 0.2)
	checar(c.pos.x < 96.0, "voltou para o começo (x=%s)" % c.pos.x)


# ---------------------------------------------------------------- v0.9: formas do desenho

## Adversário parado (só reage ao golpe) e o alvo que a lista de alvos usa.
func _adv(lugar: Vector2) -> RefCounted:
	var a := Adversario.new(3)
	a.pos = lugar
	a.velocidade = 0.0
	return a


func _alvo_adv(id: String, adv: RefCounted) -> Dictionary:
	return {"id": id, "tipo": "adversario", "pos": adv.pos, "raio": adv.raio,
		"travavel": true, "interativo": false, "dados": adv}


## Avança corpo e adversário juntos, mantendo a lista de alvos sincronizada.
func _rodar_com(c: RefCounted, m: RefCounted, alvos: Array, adv: RefCounted, segundos: float) -> Array:
	var evs: Array = []
	var t := 0.0
	var dt := 1.0 / 30.0
	while t < segundos:
		adv.passo(dt, m)
		if not alvos.is_empty():
			alvos[0]["pos"] = adv.pos
		c.passo(dt, m, alvos)
		evs.append_array(c.drenar_eventos())
		t += dt
	return evs


## LAÇO: o traço fecha em cima de si mesmo. A onda nasce no CENTRO do laço
## quando a criatura passa pelo nó, e varre (empurra) quem está lá.
func test_laco_vira_onda_em_area_no_centro() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var adv := _adv(Vector2(175, 119))  # centro do laço
	var alvos := [_alvo_adv("adversario:0", adv)]
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([
		Vector2(240, 48), Vector2(240, 190), Vector2(110, 190), Vector2(110, 30)])}, m, alvos).begins_with("ok"), "rota com laço")
	checar(not c.marcas.is_empty(), "o laço foi lido")
	var tipo := ""
	var centro := Vector2.ZERO
	for mm in c.marcas:
		if str(mm["tipo"]) == "laco":
			tipo = "laco"
			centro = Vector2(mm["centro"])
	igual(tipo, "laco", "tem marca de laço")
	perto_v(centro, Vector2(175, 119), 12.0, "centro estimado do laço")
	var evs := _rodar_com(c, m, alvos, adv, 8.0)
	checar("laco:onda" in evs, "a onda disparou ao passar pelo nó")
	checar("acerto:adversario:0" in evs, "varreu o inimigo no centro (%s)" % [evs])
	checar(adv.pos.distance_to(Vector2(175, 119)) > 5.0, "o empurrão moveu o inimigo (%s)" % adv.pos)


## BICO: ida e volta brusca. O tiro sai da BASE (o ponto antes do bico), na
## direção da ponta — e acerta o alvo que estiver nessa linha.
func test_bico_dispara_tiro_na_direcao_do_bico() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var adv := _adv(Vector2(200, 48))
	var alvos := [_alvo_adv("adversario:0", adv)]
	# bico a partir da POSIÇÃO INICIAL: 48 → 150 → 70
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([
		Vector2(150, 48), Vector2(70, 48)])}, m, alvos).begins_with("ok"), "rota com bico")
	var evs := _rodar_com(c, m, alvos, adv, 1.5)
	checar("bico:tiro" in evs, "o bico disparou (%s)" % [evs])
	checar("acerto:adversario:0" in evs, "o tiro acertou quem estaba na linha (%s)" % [evs])
	checar(adv.pos.distance_to(Vector2(200, 48)) > 5.0, "e empurrou (%s)" % adv.pos)


## O gatilho do bico é a BASE: com a main line antes, o tiro só sai quando a
## criatura chega no ponto ANTERIOR ao bico.
func test_bico_no_meio_dispara_na_base() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	# caminho reto até 150; o bico vai a 250 e VOLTA a 150; segue a 300
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([
		Vector2(150, 48), Vector2(250, 48), Vector2(150, 48), Vector2(300, 48)])}, m, []).begins_with("ok"), "rota")
	checar("bico:tiro" not in c.drenar_eventos(), "não disparou parada")
	var disparou := false
	var x_no_disparo := 0.0
	var t := 0.0
	while t < 1.6 and not disparou:
		c.passo(1.0 / 30.0, m, [])
		for e in c.drenar_eventos():
			if e == "bico:tiro":
				disparou = true
				x_no_disparo = c.pos.x
		t += 1.0 / 30.0
	checar(disparou, "disparou durante a caminhada")
	checar(x_no_disparo > 120.0 and x_no_disparo < 176.0, "disparou na base (x=%s)" % x_no_disparo)



## TRAVESSIA: a linha passa POR CIMA do adversário. Ao passar, a criatura dá a
## batida e o empurra.
func test_travessia_empurra_o_adversario() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var adv := _adv(Vector2(150, 48))
	var alvos := [_alvo_adv("adversario:0", adv)]
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(250, 48)])}, m, alvos).begins_with("ok"), "rota por cima")
	var evs := _rodar_com(c, m, alvos, adv, 2.5)
	checar("batida:adversario:0" in evs, "deu a batida ao passar (%s)" % [evs])
	checar(adv.pos.x > 155.0, "empurrou o inimigo (%s)" % adv.pos)


## FIM EM CIMA: o adversário fica marcado como alvo final do golpe físico — a
## marca vai NELE (e é ele que é golpeado na chegada).
func test_fim_em_cima_marca_o_alvo_e_golpeia() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var adv := _adv(Vector2(200, 200))
	var alvos := [_alvo_adv("adversario:0", adv)]
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(200, 200)])}, m, alvos).begins_with("ok"), "rota até o inimigo")
	checar(c.finalizar_rota(alvos).begins_with("ok"), "marcou o alvo final")
	igual(c.mira_final_id, "adversario:0", "marca no inimigo")
	var evs := _rodar_com(c, m, alvos, adv, 4.0)
	checar("golpe_final:adversario:0" in evs, "deu o golpe final (%s)" % [evs])
	checar(adv.pos.distance_to(Vector2(200, 200)) > 5.0, "o golpe empurrou (%s)" % adv.pos)


## Se o inimigo ANDAR DEMAIS até a criatura chegar, a automira final se perde
## (o golpe sai no vazio).
func test_alvo_final_se_perde_se_o_inimigo_andar() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var adv := _adv(Vector2(200, 200))
	var alvos := [_alvo_adv("adversario:0", adv)]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(200, 200)])}, m, alvos)
	c.finalizar_rota(alvos)
	igual(c.mira_final_id, "adversario:0", "marcou")
	# ele foge para longe da marca
	adv.pos = Vector2(48, 200)
	alvos[0]["pos"] = adv.pos
	var evs := _rodar_com(c, m, alvos, adv, 4.0)
	checar("mira_final:perde" in evs, "a mira se perdeu (%s)" % [evs])
	checar("golpe_final:adversario:0" not in evs, "não golpeou o alvo perdido")
	checar(c.mira_final_id == "", "e a marca foi limpa")


# ---------------------------------------------------------------- v0.9.1: ajustes

## O laço acende em QUALQUER parte da circunferência: se a criatura já está
## andando no anel quando ele fecha, a onda sai na hora.
func test_laco_acende_com_a_criatura_no_anel() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	# o anel do laço passa a 12 px do ponto de partida (nó em 60,48)
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([
		Vector2(130, 48), Vector2(130, 120), Vector2(60, 120), Vector2(60, 30)])}, m, []).begins_with("ok"), "rota com laço")
	var evs := _rodar(c, m, 0.1)
	checar("laco:onda" in evs, "onda saiu com a criatura no anel (%s)" % [evs])


## Bico em "T" no MEIO do caminho: o beco NÃO é andado, a criatura para e
## dispara da base na direção da ponta.
func test_bico_em_t_no_meio_nao_e_andado() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([
		Vector2(150, 48), Vector2(150, 120), Vector2(150, 48), Vector2(260, 48)])}, m, []).begins_with("ok"), "rota com T")
	var alto := false
	for p in c.rota:
		if p.y > 60.0:
			alto = true
	checar(not alto, "o beco saiu da rota (%s)" % [c.rota])
	var disparou := false
	var dir_ok := false
	for i in 90:
		c.passo(1.0 / 30.0, m, [])
		for e in c.drenar_eventos():
			if e == "bico:tiro":
				disparou = true
				for ef in c.efeitos:
					if str(ef["tipo"]) == "tiro":
						dir_ok = Vector2(ef["dir"]).dot(Vector2(0, 1)) > 0.9
		if disparou:
			break
	checar(disparou, "o T disparou")
	checar(dir_ok, "tiro na direção da ponta")
	# a criatura PARA no disparo (pausa do bico)
	var pos_disparo: Vector2 = c.pos
	_rodar(c, m, 0.15)
	checar(c.pos.distance_to(pos_disparo) < 1.0, "parou antes de entrar no beco (%s → %s)" % [pos_disparo, c.pos])


## A ESTRADA: a criatura anda por dentro de uma faixa (não colada na linha) e o
## caminho não é retilíneo — mas não sai da largura.
func test_estrada_organica_nao_e_reta() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(330, 48)])}, m, [])
	var max_desvio := 0.0
	var minimo := 0.0
	for i in 70:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		var d: float = c.pos.y - 48.0
		max_desvio = maxf(max_desvio, d)
		minimo = minf(minimo, d)
	checar(max_desvio > 1.5, "saiu para um lado da linha (%.1f px)" % max_desvio)
	checar(absf(minimo) > 1.5, "saiu para o outro lado (%.1f px)" % minimo)
	checar(max_desvio <= 17.0 and minimo >= -17.0, "ficou na estrada (%.1f a %.1f px)" % [minimo, max_desvio])


## ZONA DE FREIO: o fim do caminho é mais lento que o meio.
func test_freio_no_fim_do_caminho() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(240, 48)])}, m, [])
	var meio := 0.0
	var fim := 0.0
	var t := 0.0
	while c.em_rota() and t < 5.0:
		var antes: Vector2 = c.pos
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		var v: float = c.pos.distance_to(antes) * 30.0
		var restante: float = c.total_rota - c.rota_t
		if restante > 70.0 and restante < 150.0:
			meio = maxf(meio, v)
		if restante < 6.0:
			fim = maxf(fim, v)
		t += 1.0 / 30.0
	checar(meio > 70.0, "andou no meio (%.0f px/s)" % meio)
	checar(fim < 35.0, "freou no fim (%.0f px/s)" % fim)
