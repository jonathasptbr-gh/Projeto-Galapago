extends "res://testes/caso.gd"

const M := preload("res://sim/mundo.gd")
const Corpo := preload("res://sim/corpo.gd")

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


func test_esquiva_desloca_para_o_lado_e_volta_sem_perder_a_rota() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(400, 48)])}, m, [])
	_rodar(c, m, 0.2)
	c.olhar = Vector2.RIGHT
	checar(c.comandar({"acao": "esquiva", "lado": -1.0}, m, []).begins_with("ok"), "esquivou")
	_rodar(c, m, 0.09)
	checar(c.desvio.length() > 8.0, "saiu para o lado (%s)" % c.desvio.length())
	checar(c.em_rota(), "rota continua")
	_rodar(c, m, 0.4)
	perto(c.desvio.length(), 0.0, 0.5, "voltou para a rota")
	checar(c.em_rota(), "e segue na rota")


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


func test_defesa_para_a_rota_e_soltar_retoma() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(400, 48)])}, m, [])
	_rodar(c, m, 0.3)
	c.comandar({"acao": "defender"}, m, [])
	var t0: float = c.rota_t
	_rodar(c, m, 0.5)
	perto(c.rota_t, t0, 0.01, "parou durante a defesa")
	c.comandar({"acao": "soltar"}, m, [])
	_rodar(c, m, 0.4)
	checar(c.rota_t > t0 + 30.0, "retomou ao soltar (%s → %s)" % [t0, c.rota_t])


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
	checar(c.comandar({"acao": "escavar"}, m, []).begins_with("ok"), "escava")
	_rodar(c, m, 1.2)
	igual(c.camada, M.SUBSOLO, "no subsolo")
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(144, 48)])}, m, []).begins_with("ok"), "rota no túnel")
	_seguir_ate_fim(c, m)
	igual(m.celula_de(c.pos), Vector2i(4, 1), "andou no túnel até a saída (pos %s)" % c.pos)
	checar(c.comandar({"acao": "escavar"}, m, []).begins_with("ok"), "escava para subir")
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


# ---------------------------------------------------------------- v0.6: especiais e esquiva de tela

func test_especial_sai_para_o_lado_do_gesto() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	checar(c.comandar({"acao": "especial", "direcao": Vector2.RIGHT}, m, []).begins_with("ok"), "especial")
	igual(c.ataque, "especial", "golpe especial em curso")
	checar(c.ataque_dir.x > 0.9, "para a direita (%s)" % c.ataque_dir)
	_rodar(c, m, 0.7)
	igual(c.ataque, "", "especial terminou")


func test_esquiva_vai_para_a_direcao_do_gesto() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(400, 48)])}, m, [])
	_rodar(c, m, 0.2)
	checar(c.comandar({"acao": "esquiva", "direcao": Vector2.DOWN}, m, []).begins_with("ok"), "esquivou")
	_rodar(c, m, 0.09)
	checar(c.desvio.y > 8.0, "para baixo (%s)" % c.desvio)
	checar(absf(c.desvio.x) < 1.0, "sem lado")
	checar(c.em_rota(), "rota continua")
	_rodar(c, m, 0.4)
	perto(c.desvio.length(), 0.0, 0.5, "voltou")


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
