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


func _setup(celulas: Array, subsolo: Array = [], semente := 5, cfg: Dictionary = {}) -> Array:
	var m := M.criar({"celula_px": 32, "celulas": celulas, "subsolo": subsolo}, terrenos)
	var c := Corpo.new(acoes if cfg.is_empty() else cfg)
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


## O ÚLTIMO projétil de tiro vivo (o mais recente, se o teste atirou duas vezes).
func _efeito_tiro(c: RefCounted) -> Dictionary:
	var ef := {}
	for e in c.efeitos:
		if str(e["tipo"]) == "tiro":
			ef = e
	return ef


# ---------------------------------------------------------------- controle relativo

func test_controle_relativo_para_ao_soltar_e_descarta_rota() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(240, 48)])}, m, [])
	c.definir_controle_relativo(true)
	checar(not c.em_rota(), "rota anterior cancelada")
	c.mover_relativo(Vector2(1, 1))
	c.passo(0.1, m, [])
	checar(c.pos.x > 48 and c.pos.y > 48, "andou na diagonal")
	var pos: Vector2 = c.pos
	c.mover_relativo(Vector2.ZERO)
	_rodar(c, m, 2.0)
	perto_v(c.pos, pos, 0.001, "parou sem retomar rota nem autonomia")


func test_controle_relativo_respeita_agua_e_limita_velocidade() -> void:
	var s := _setup(AGUA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.definir_controle_relativo(true)
	c.mover_relativo(Vector2(100, 0))
	_rodar(c, m, 2.0)
	checar(c.pos.x < 64.0, "não entrou na água")
	c.pos = Vector2(48, 48)
	c.mover_relativo(Vector2(0, -100))
	c.passo(0.1, m, [])
	perto(c.pos.y, 48.0 - c.velocidade * 0.1, 0.01, "magnitude limitada")


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

## v0.11.2: a ROTA entra na água mas VOLTA à terra perto do animal — o destino
## não é a água. A criatura contorna o lago (mesmo desvio do tronco) e segue.
func test_rota_atravessa_agua_contornando_quando_ha_continuacao() -> void:
	var s := _setup(AGUA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(300, 48)])}, m, []).begins_with("ok"), "rota")
	var t := 0.0
	var invadiu := 0
	while c.em_rota() and t < 12.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		if m.bloqueio(m.celula_de(c.pos), M.SUPERFICIE) == "terreno":
			invadiu += 1
		t += 1.0 / 30.0
	checar(not c.em_rota(), "atravessou/contornou a água em %.1f s" % t)
	checar(not c.barrado(), "não ficou parada na fronteira")
	checar(invadiu == 0, "nunca tentou ENTRAR na água (%d quadros)" % invadiu)
	checar(c.pos.x > 250.0, "chegou ao fim depois da água (x=%.0f)" % c.pos.x)


## Se a rota TERMINA dentro da água, não há continuação em terra: para na
## fronteira. (O pulo é o que atravessa, como antes.)
func test_rota_que_termina_na_agua_para_na_fronteira() -> void:
	var s := _setup(AGUA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(96, 48)])}, m, [])
	_rodar(c, m, 3.0)
	checar(c.barrado(), "parou na fronteira")
	checar(c.pos.x < 96.0, "não entrou na água (x=%s)" % c.pos.x)


## v0.11.3: DESNÍVEL (encosta/planalto) também é barreira contornável. A rota
## passa por cima de um planalto alto; a criatura dá a volta pelas laterais e
## segue — sem esbarrar na encosta.
func test_rota_contorna_desnivel_quando_ha_continuacao() -> void:
	var s := _setup([",,,,,,,,,,,,", ",,^^,,,,,,,,", ",,,,,,,,,,,,"])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(300, 48)])}, m, []).begins_with("ok"), "rota")
	var t := 0.0
	var subiu := 0
	while c.em_rota() and t < 12.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		if m.altura(m.celula_de(c.pos)) > 1.5:
			subiu += 1
		t += 1.0 / 30.0
	checar(not c.em_rota(), "contornou a encosta em %.1f s" % t)
	checar(not c.barrado(), "não ficou presa na encosta")
	checar(subiu == 0, "não subiu no planalto (%d quadros)" % subiu)
	checar(c.pos.x > 250.0, "seguiu depois da encosta (x=%.0f)" % c.pos.x)


## ROCHA é o mesmo TERRENO: com uma continuação em terra perto, contorna.
func test_rota_contorna_rocha_quando_ha_continuacao() -> void:
	var s := _setup([",,,,,,,,,,,,", ",,##,,,,,,,,", ",,,,,,,,,,,,"])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(300, 48)])}, m, [])
	var t := 0.0
	while c.em_rota() and t < 12.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		t += 1.0 / 30.0
	checar(not c.em_rota(), "contornou a rocha em %.1f s" % t)
	checar(not c.barrado(), "não ficou parada na pedra")
	checar(c.pos.x > 250.0, "seguiu depois da rocha (x=%.0f)" % c.pos.x)


## A linha ENTRA na água, sai na terra e continua: o vai-e-volta dentro do
## lago não é o destino; a criatura contorna e segue pelo trecho de terra.
func test_linha_que_entra_na_agua_e_sai_na_terra_e_contornada() -> void:
	var celulas := [
		",,,,,,,,", ",,,~~,,,", ",,,~~,,,", ",,,,,,,,", ",,,,,,,,", ",,,,,,,,",
	]
	var s := _setup(celulas)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([
		Vector2(112, 48), Vector2(112, 140), Vector2(240, 140)])}, m, [])
	var t := 0.0
	while c.em_rota() and t < 12.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		t += 1.0 / 30.0
	checar(not c.em_rota(), "saiu do vai-e-volta na água em %.1f s" % t)
	checar(not c.barrado(), "não ficou presa no muro")
	checar(c.pos.x > 200.0, "seguiu pela terra depois da água (x=%.0f)" % c.pos.x)


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


## v0.11.3: a DIREÇÃO não pisca no desvio — o giro por quadro fica limitado
## por `giro_max_graus_s` (navegação estável, sem tremer/rodar no lugar).
func test_direcao_estavel_ao_contornar() -> void:
	var s := _setup_objeto([{"tipo": "arvore", "celula": [3, 1]}])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(240, 48)])}, m, [])
	var ang_antes: float = c.olhar.angle()
	var maior := 0.0
	var t := 0.0
	while c.em_rota() and t < 10.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		var d: float = absf(wrapf(c.olhar.angle() - ang_antes, -PI, PI))
		maior = maxf(maior, d)
		ang_antes = c.olhar.angle()
		t += 1.0 / 30.0
	var giro := float(acoes.get("rota", {}).get("giro_max_graus_s", 720.0))
	var limite := deg_to_rad(giro / 30.0 + 0.5)
	checar(maior <= limite, "giro por quadro estável (%.1f° ≤ %.1f°)" % [rad_to_deg(maior), rad_to_deg(limite)])
	checar(c.pos.x > 200.0, "contornou e seguiu (x=%.0f)" % c.pos.x)


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
	_rodar(c, m, 1.5)
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


## As ações do jogo com o LAÇO forçado. v0.11.5 desligou a área por padrão;
## os testes da ONDA ligam de propósito para provar que o código está inteiro.
func _acoes_com_laco(ligado: bool) -> Dictionary:
	var d := acoes.duplicate(true)
	var f: Dictionary = d.get("formas", {})
	f["laco_ataque"] = ligado
	d["formas"] = f
	return d


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
	var s := _setup(MAPA, [], 5, _acoes_com_laco(true))
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


## v0.11: o BICO é ANDADO — o traço é obedecido como foi desenhado (o "beco"
## não é ignorado).
func test_bico_e_andado() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([
		Vector2(150, 48), Vector2(150, 120), Vector2(150, 48), Vector2(260, 48)])}, m, []).begins_with("ok"), "rota com T")
	var alto := false
	for q in c.rota:
		if q.y > 60.0:
			alto = true
	checar(alto, "o bico está na rota (%s)" % [c.rota])


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


## v0.10: se o alvo marcado ANDAR, o animal VAI ATRÁS dele (perseguição final)
## em vez de atacar de longe — e só bate ao CHEGAR perto.
func test_perseguicao_final_vai_atras_do_alvo() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var adv := _adv(Vector2(200, 200))
	var alvos := [_alvo_adv("adversario:0", adv)]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(200, 200)])}, m, alvos)
	c.finalizar_rota(alvos)
	igual(c.mira_final_id, "adversario:0", "marcou")
	# ele ANDOU para longe antes de a criatura chegar
	adv.pos = Vector2(300, 230)
	alvos[0]["pos"] = adv.pos
	var evs := _rodar_com(c, m, alvos, adv, 4.0)
	checar("golpe_final:adversario:0" in evs, "perseguiu e bateu (%s)" % [evs])
	# chegou na região do alvo (o empurrão do golpe afasta o inimigo depois)
	checar(c.pos.distance_to(Vector2(300, 230)) < 120.0, "foi atrás do alvo (%s)" % c.pos)


# ---------------------------------------------------------------- v0.9.1: ajustes

## v0.10: o laço acende pela DISTÂNCIA da criatura ao CENTRO da área (até
## `area_gatilho_px`, ~7× o corpo): não precisa chegar no anel.
func test_laco_acende_pela_distancia_ao_centro() -> void:
	var s := _setup(MAPA, [], 5, _acoes_com_laco(true))
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	# o centro do laço fica a ~58 px do ponto de partida (bem dentro dos 224 px)
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([
		Vector2(130, 48), Vector2(130, 120), Vector2(60, 120), Vector2(60, 30)])}, m, []).begins_with("ok"), "rota com laço")
	var evs := _rodar(c, m, 0.1)
	checar("laco:onda" in evs, "onda saiu pela distância ao centro (%s)" % [evs])


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


## v0.11.1: NÃO há mais freio antes do fim. A criatura chega no último ponto
## na velocidade NORMAL e a frenagem é a INÉRCIA depois dele (pedaço curto).
func test_inercia_depois_do_fim_do_caminho() -> void:
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
	checar(fim > 90.0, "chegou no fim na velocidade normal (%.0f px/s)" % fim)
	checar(not c.em_rota(), "a rota terminou")
	checar(c.em_inercia(), "entrou na inércia")
	var p0: Vector2 = c.pos
	var t2 := 0.0
	while c.em_inercia() and t2 < 1.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		t2 += 1.0 / 30.0
	checar(c.pos.x > p0.x + 6.0, "passou um pouco do fim (+%.0f px)" % (c.pos.x - p0.x))
	checar(c.pos.x < p0.x + 32.0, "não foi longe no freio (+%.0f px)" % (c.pos.x - p0.x))
	checar(not c.em_inercia(), "parou depois do freio")


# ---------------------------------------------------------------- v0.9.2: recarga e embalo

## Os ataques especiais têm 1 s de RECARGA: uma segunda marca não dispara
## durante o cooldown (fica pendente e acende quando a recarga termina).
func test_recarga_de_um_segundo_nos_especiais() -> void:
	var s := _setup(MAPA, [], 5, _acoes_com_laco(true))
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([
		Vector2(130, 48), Vector2(130, 120), Vector2(60, 120), Vector2(60, 30)])}, m, []).begins_with("ok"), "rota com laço")
	var evs := _rodar(c, m, 0.1)
	checar("laco:onda" in evs, "1ª onda saiu")
	checar(float(c._recargas.get("onda", 0.0)) > 0.7, "entrou em recarga (%.2f)" % float(c._recargas.get("onda", 0.0)))
	# uma marca de laço em cima dela NÃO acende durante o cooldown
	c.marcas.append({"tipo": "laco", "ponto": c.pos, "centro": c.pos, "raio": 30.0,
		"dir": Vector2.RIGHT, "chave": "teste:laco"})
	var evs2 := _rodar(c, m, 0.15)
	checar("laco:onda" not in evs2, "não disparou em recarga")
	checar(not c._tem_marca("teste:laco") == false, "a marca ficou pendente")
	# libera a recarga e a marca acende
	c._recargas["onda"] = 0.0
	var evs3 := _rodar(c, m, 0.05)
	checar("laco:onda" in evs3 or c._tem_marca("teste:laco") == false, "acendeu ao liberar (%s)" % [evs3])


## O EMPURRÃO embala: passa mais rápido que a caminhada normal pelo alvo.
func test_empurrao_embala_e_desacelera() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var adv := _adv(Vector2(150, 48))
	var alvos := [_alvo_adv("adversario:0", adv)]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(280, 48)])}, m, alvos)
	var bateu := false
	var vmax := 0.0
	var t := 0.0
	while t < 3.0 and not bateu:
		var antes: Vector2 = c.pos
		adv.passo(1.0 / 30.0, m)
		alvos[0]["pos"] = adv.pos
		c.passo(1.0 / 30.0, m, alvos)
		for e in c.drenar_eventos():
			if e.begins_with("batida:"):
				bateu = true
		if bateu:
			break
		t += 1.0 / 30.0
	checar(bateu, "deu a batida")
	checar(c._turbo_t > 0.0, "entrou no embalo")
	# mede a velocidade logo depois da batida
	var pos0: Vector2 = c.pos
	_rodar(c, m, 0.15, alvos)
	var v: float = c.pos.distance_to(pos0) / 0.15
	checar(v > 135.0, "passou mais rápido que a caminhada (%.0f px/s)" % v)
	# e depois volta ao normal
	_rodar(c, m, 1.2, alvos)
	checar(c._turbo_t <= 0.0, "o embalo acaba")


## A MARCAÇÃO acelera CURTO perto do alvo final (embalo menor que o empurrão).
func test_marcacao_embala_curto() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	# o alvo fica 30 px ao lado do fim (sem travessia, só a marcação)
	var adv := _adv(Vector2(230, 200))
	var alvos := [_alvo_adv("adversario:0", adv)]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(200, 200)])}, m, alvos)
	c.finalizar_rota(alvos)
	var vmax := 0.0
	var turbo := false
	var t := 0.0
	while t < 4.0:
		var antes: Vector2 = c.pos
		var restante: float = c.pos.distance_to(Vector2(230, 200))
		adv.passo(1.0 / 30.0, m)
		alvos[0]["pos"] = adv.pos
		c.passo(1.0 / 30.0, m, alvos)
		c.drenar_eventos()
		if restante < 80.0:
			vmax = maxf(vmax, c.pos.distance_to(antes) * 30.0)
		if c._turbo_t > 0.0:
			turbo = true
			checar(c._turbo_dur <= 0.3, "embalo CURTO (%.2f s)" % c._turbo_dur)
		t += 1.0 / 30.0
	checar(turbo, "embalou para a marcação")
	checar(vmax > 130.0, "acelerou perto do alvo (%.0f px/s)" % vmax)


# ---------------------------------------------------------------- v0.10/v0.18/v0.19: tiro
# (o alvo marcado e a carga)

## TOQUE = TIRO CARREGADO (v0.19): o comando NÃO atira na hora. Ele começa a
## carga (o animal para e `carga()` cresce) e, ao completar `carga_tiro_s`
## (padrão do JSON = 0,5 s = 15 quadros), o projétil sai SOZINHO na direção do
## **FIM DO CAMINHO** — nunca na direção do toque — com o TAMANHO proporcional
## ao tempo: 0,5 s de 1,5 s = carga 1/3 → 10,5 / 336 / 32.
func test_toque_carrega_e_dispara_sozinho_no_fim_do_caminho() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	perto(c.carga_tiro_s, 0.5, 0.001, "o padrão da carga vem do JSON (0,5 s)")
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(240, 48)])}, m, [])
	var toque: Vector2 = c.pos + Vector2(0, 100)  # para baixo (o fim do caminho é +x)
	igual(c.comandar({"acao": "tiro", "alvo": toque}, m, []), "ok: carregando", "toque começa a carga")
	checar(c.carregando(), "está carregando")
	perto(c.carga(), 0.0, 0.01, "a carga começa em zero")
	checar("carga:on" in c.drenar_eventos(), "avisou a carga")
	var p0: Vector2 = c.pos
	var evs := _rodar(c, m, 0.3)
	perto_v(c.pos, p0, 0.001, "o animal PARA enquanto carrega")
	perto(c.carga(), 0.6, 0.02, "a carga cresce (0,3 s de 0,5 s = 60%)")
	checar("tiro:disparo" not in evs, "ainda não disparou")
	# completa 0,5 s: o disparo sai sozinho, com o tamanho do tempo escolhido
	evs.append_array(_rodar(c, m, 0.21))
	checar("tiro:disparo" in evs, "disparou sozinho ao completar 0,5 s (%s)" % [evs])
	checar(not c.carregando(), "a carga acabou")
	perto(c.carga(), 0.0, 0.001, "carga zerada depois do disparo")
	checar(float(c._recargas.get("tiro", 0.0)) > 0.7, "entrou em recarga")
	checar(c._pausa_t > 0.0, "parou para atirar")
	var ef := _efeito_tiro(c)
	checar(not ef.is_empty(), "há um projétil")
	if ef.is_empty():
		return
	var dir := Vector2(ef["dir"])
	var fim: Vector2 = c.rota[c.rota.size() - 1]
	checar(dir.dot((fim - c.pos).normalized()) > 0.99, "tiro na direção do FIM do caminho (%s)" % dir)
	checar(dir.dot((toque - c.pos).normalized()) < 0.5, "e não na direção do toque (%s)" % dir)
	perto(float(ef["raio"]), 10.5, 0.01, "0,5 s de 1,5 s: raio")
	perto(float(ef["alcance"]), 336.0, 0.02, "0,5 s de 1,5 s: alcance")
	perto(float(ef["empurrao"]), 32.0, 0.01, "0,5 s de 1,5 s: empurrão")
	igual(c.comandar({"acao": "tiro", "alvo": toque}, m, []), "recusado: recarga", "recarga segura o 2º toque")


# ---------------------------------------------------------------- v0.19: tempo de carga e tamanho

## O TEMPO escolhido define o tamanho: `carga_tiro_s` 1,5 s (o teto de
## `tiro_carga_max_s()`) leva 1,5 s de preparo e sai com o tiro MÁXIMO
## 13,5 / 448 / 48.
func test_carga_de_um_e_meio_segundo_e_o_tiro_maximo() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	perto(c.tiro_carga_max_s(), 1.5, 0.001, "o teto do slider vem do JSON (1,5 s)")
	c.carga_tiro_s = 1.5
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(240, 48)])}, m, [])
	igual(c.comandar({"acao": "tiro", "alvo": c.pos + Vector2(0, 100)}, m, []), "ok: carregando", "carrega")
	var evs := _rodar(c, m, 1.0)
	checar("tiro:disparo" not in evs, "1 s ainda não completa 1,5 s")
	checar(c.carregando(), "segue carregando")
	perto(c.carga(), 2.0 / 3.0, 0.07, "a barra marca ~2/3 (1 s de 1,5 s)")
	evs.append_array(_rodar(c, m, 0.55))
	checar("tiro:disparo" in evs, "disparou ao completar 1,5 s (%s)" % [evs])
	var ef := _efeito_tiro(c)
	checar(not ef.is_empty(), "há um projétil")
	if ef.is_empty():
		return
	perto(float(ef["raio"]), 13.5, 0.01, "tempo máximo: raio")
	perto(float(ef["alcance"]), 448.0, 0.02, "tempo máximo: alcance")
	perto(float(ef["empurrao"]), 48.0, 0.01, "tempo máximo: empurrão")


## No MEIO do caminho a escala é linear: 0,75 s de 1,5 s = carga 1/2 →
## 11,25 / 364 / 36, com 0,75 s de preparo.
func test_carga_de_tres_quartos_de_segundo_escala_no_meio() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.carga_tiro_s = 0.75
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(240, 48)])}, m, [])
	igual(c.comandar({"acao": "tiro", "alvo": c.pos + Vector2(0, 100)}, m, []), "ok: carregando", "carrega")
	var evs := _rodar(c, m, 0.4)
	checar("tiro:disparo" not in evs, "0,4 s ainda não completa 0,75 s")
	perto(c.carga(), 0.4 / 0.75, 0.07, "a barra marca ~o preparo (0,4 s de 0,75 s)")
	evs.append_array(_rodar(c, m, 0.4))
	checar("tiro:disparo" in evs, "disparou ao completar 0,75 s (%s)" % [evs])
	var ef := _efeito_tiro(c)
	checar(not ef.is_empty(), "há um projétil")
	if ef.is_empty():
		return
	perto(float(ef["raio"]), 11.25, 0.01, "metade da carga: raio")
	perto(float(ef["alcance"]), 364.0, 0.02, "metade da carga: alcance")
	perto(float(ef["empurrao"]), 36.0, 0.01, "metade da carga: empurrão")


## `carga_tiro_s` = 0 é o tiro INSTANTÂNEO: o comando dispara na hora
## (`"ok: tiro"`), NÃO fica carregando e o projétil BASE já existe com
## 9 / 280 / 24. A recarga e a pausa do tiro valem como sempre.
func test_carga_zero_dispara_na_hora_com_o_tiro_base() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.carga_tiro_s = 0.0
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(240, 48)])}, m, [])
	c.drenar_eventos()
	var toque: Vector2 = c.pos + Vector2(0, 100)  # para baixo (o fim do caminho é +x)
	igual(c.comandar({"acao": "tiro", "alvo": toque}, m, []), "ok: tiro", "instantâneo dispara no comando")
	checar(not c.carregando(), "não fica carregando")
	perto(c.carga(), 0.0, 0.001, "sem barra de carga")
	var evs: Array = c.drenar_eventos()
	checar("tiro:disparo" in evs, "avisou o disparo (%s)" % [evs])
	checar("carga:on" not in evs, "não avisou carga (%s)" % [evs])
	var ef := _efeito_tiro(c)
	checar(not ef.is_empty(), "o projétil sai no mesmo comando")
	if ef.is_empty():
		return
	var dir := Vector2(ef["dir"])
	var fim: Vector2 = c.rota[c.rota.size() - 1]
	checar(dir.dot((fim - c.pos).normalized()) > 0.99, "na direção do FIM do caminho (%s)" % dir)
	checar(dir.dot((toque - c.pos).normalized()) < 0.5, "e nunca na direção do toque (%s)" % dir)
	perto(float(ef["raio"]), 9.0, 0.01, "tiro base: raio")
	perto(float(ef["alcance"]), 280.0, 0.02, "tiro base: alcance")
	perto(float(ef["empurrao"]), 24.0, 0.01, "tiro base: empurrão")
	perto(float(c._recargas.get("tiro", 0.0)), 1.0, 0.001, "entrou em recarga")
	checar(c._pausa_t > 0.0, "pausa do tiro")
	igual(c.comandar({"acao": "tiro", "alvo": toque}, m, []), "recusado: recarga", "recarga segura um toque novo")


## O tempo vem do JSON e admite configuração própria: `carga_tiro_s` lê
## `combate.tiro_carga_s` e `tiro_carga_max_s()` lê `combate.tiro_carga_max_s`
## (nunca ≤ 0, porque é divisor do tamanho).
func test_carga_do_tiro_vem_do_json() -> void:
	var cfg: Dictionary = acoes.duplicate(true)
	cfg["combate"]["tiro_carga_s"] = 0.25
	cfg["combate"]["tiro_carga_max_s"] = 2.0
	var c := Corpo.new(cfg)
	perto(c.carga_tiro_s, 0.25, 0.001, "o tempo lê combate.tiro_carga_s")
	perto(c.tiro_carga_max_s(), 2.0, 0.001, "o teto lê combate.tiro_carga_max_s")
	cfg["combate"]["tiro_carga_max_s"] = 0.0
	c = Corpo.new(cfg)
	checar(c.tiro_carga_max_s() > 0.0, "teto nunca é ≤ 0")


## O slider (escrita em `carga_tiro_s`) vale para o PRÓXIMO tiro e mudá-lo
## DURANTE a carga não a quebra: o preparo em curso guarda o teto do começo,
## mas o TAMANHO do disparo é o valor ATUAL (aqui 1,5 s → máximo).
func test_slider_muda_o_proximo_tiro_sem_quebrar_a_carga_em_curso() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(240, 48)])}, m, [])
	igual(c.comandar({"acao": "tiro", "alvo": c.pos + Vector2(0, 100)}, m, []), "ok: carregando", "carrega com 0,5 s")
	_rodar(c, m, 0.2)
	checar(c.carregando(), "carregando")
	c.carga_tiro_s = 1.5  # o jogador arrastou o slider no meio do preparo
	checar(c.carregando(), "a carga em curso não quebra")
	perto(c.carga(), 0.4, 0.07, "a barra segue o teto travado no começo (~0,2 s de 0,5 s)")
	var evs := _rodar(c, m, 0.35)
	checar("tiro:disparo" in evs, "disparou no teto do começo, 0,5 s (%s)" % [evs])
	var ef := _efeito_tiro(c)
	checar(not ef.is_empty(), "há um projétil")
	if not ef.is_empty():
		perto(float(ef["raio"]), 13.5, 0.01, "o tamanho usa o valor ATUAL (1,5 s = máximo)")
	# o PRÓXIMO tiro já sai com o tempo novo (0,75 s = 11,25 / 364 / 36)
	_rodar(c, m, 0.3)  # a pausa do tiro passa
	c._recargas["tiro"] = 0.0
	c.carga_tiro_s = 0.75
	igual(c.comandar({"acao": "tiro", "alvo": c.pos + Vector2(0, 100)}, m, []), "ok: carregando", "carrega com 0,75 s")
	var evs2 := _rodar(c, m, 0.8)
	checar("tiro:disparo" in evs2, "disparou ao completar 0,75 s (%s)" % [evs2])
	var ef2 := _efeito_tiro(c)
	checar(not ef2.is_empty(), "há um segundo projétil")
	if not ef2.is_empty():
		perto(float(ef2["raio"]), 11.25, 0.01, "o próximo tiro usa o tempo novo: raio")
		perto(float(ef2["alcance"]), 364.0, 0.02, "o próximo tiro usa o tempo novo: alcance")
		perto(float(ef2["empurrao"]), 36.0, 0.01, "o próximo tiro usa o tempo novo: empurrão")


## v0.18: sem alvo marcado e SEM caminho não há para onde atirar — o toque
## deixou de ser a direção. A carga nem começa.
func test_tiro_sem_destino_e_recusado() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	igual(c.comandar({"acao": "tiro", "alvo": c.pos + Vector2(0, 100)}, m, []),
		"recusado: sem destino", "sem caminho e sem marca não atira")
	checar(not c.carregando(), "nenhuma carga")
	perto(c.carga(), 0.0, 0.001, "carga zerada")
	checar(c.efeitos.is_empty(), "nenhum projétil criado")
	perto(float(c._recargas.get("tiro", 0.0)), 0.0, 0.001, "não entrou em recarga")


## COM ALVO MARCADO a automira da v0.10 continua: o toque em OUTRO lugar não
## muda a direção. O disparo sai no **ALVO VIVO** ao completar a carga (0,5 s),
## e a marca NÃO sai no disparo.
func test_toque_com_alvo_marcado_mira_no_alvo_vivo() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var adv := _adv(Vector2(200, 200))
	var alvos := [_alvo_adv("adversario:0", adv)]
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(200, 200)])}, m, alvos).begins_with("ok"), "rota até o alvo")
	c.finalizar_rota(alvos)
	igual(c.mira_final_id, "adversario:0", "marcou")
	var toque: Vector2 = c.pos + Vector2(-150, 0)  # toque do lado OPOSTO ao alvo
	igual(c.comandar({"acao": "tiro", "alvo": toque}, m, alvos), "ok: carregando", "o toque carrega")
	checar(c.carregando(), "carregando")
	_rodar(c, m, 0.3, alvos)
	# o alvo ANDA durante a carga: a direção segue a posição ATUAL dele
	adv.pos = Vector2(120, 230)
	alvos[0]["pos"] = adv.pos
	var evs := _rodar(c, m, 0.21, alvos)
	checar("tiro:disparo" in evs, "disparou ao completar 0,5 s (%s)" % [evs])
	igual(c.mira_final_id, "adversario:0", "a marca FICA após o disparo")
	var ef := _efeito_tiro(c)
	checar(not ef.is_empty(), "há um projétil")
	if not ef.is_empty():
		var dir := Vector2(ef["dir"])
		checar(dir.dot((Vector2(adv.pos) - c.pos).normalized()) > 0.99, "tiro no alvo VIVO (não no toque) (%s)" % dir)
	igual(c.comandar({"acao": "tiro"}, m, alvos), "recusado: recarga", "recarga segura o 2º toque")
	var evs2 := _rodar_com(c, m, alvos, adv, 1.2)
	checar("acerto:adversario:0" in evs2, "acertou o alvo (%s)" % [evs2])


## A MARCA nasce DURANTE o caminho, quando a ponta do traço alcança o alvo.
func test_marca_nasce_durante_o_caminho() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var adv := _adv(Vector2(200, 200))
	var alvos := [_alvo_adv("adversario:0", adv)]
	checar(c.tracar(PackedVector2Array([c.pos, c.pos + Vector2(80, 0), Vector2(200, 200)]), m, true, alvos).begins_with("ok"), "traço")
	igual(c.mira_final_id, "adversario:0", "marcou durante o caminho")


# ---------------------------------------------------------------- v0.11: sprint do segurar

## SEGURAR durante um CAMINHO = SPRINT: acelera, gasta a barra de energia e
## desliga ao soltar (a energia recupera depois). É contínuo enquanto o dedo
## fica — não há mais arrancada curta de duração própria.
func test_sprint_durante_o_caminho_gasta_energia() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(330, 48)])}, m, [])
	_rodar(c, m, 0.3)
	igual(c.comandar({"acao": "segurar"}, m, []), "ok: sprint", "segurar com caminho corre")
	checar(c._sprint, "sprint ligado")
	var e0: float = c.energia
	var antes: Vector2 = c.pos
	_rodar(c, m, 0.2)
	var v: float = c.pos.distance_to(antes) / 0.2
	checar(v > 150.0, "acelerou (%.0f px/s)" % v)
	checar(c.energia < e0 - 0.05, "gastou energia (%.2f → %.2f)" % [e0, c.energia])
	c.comandar({"acao": "soltar_segurar"}, m, [])
	var e1: float = c.energia
	_rodar(c, m, 0.3)
	checar(c.energia > e1, "recuperou a energia (%.2f → %.2f)" % [e1, c.energia])


## v0.11.4: soltar o segurar NÃO corta a velocidade na hora — a CAUDA mantém o
## embalo por um tempo e só depois volta à caminhada normal (e a energia para
## de ser gasta no soltar).
func test_cauda_do_sprint_mantem_o_embalo_depois_de_soltar() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(340, 48)])}, m, [])
	_rodar(c, m, 0.2)
	c.comandar({"acao": "segurar"}, m, [])
	_rodar(c, m, 0.2)
	c.comandar({"acao": "soltar_segurar"}, m, [])
	var p0: Vector2 = c.pos
	var e0: float = c.energia
	_rodar(c, m, 0.1)
	var v: float = c.pos.distance_to(p0) / 0.1
	checar(v > 140.0, "ainda acelerado logo após soltar (%.0f px/s)" % v)
	_rodar(c, m, 0.8)
	var p1: Vector2 = c.pos
	_rodar(c, m, 0.1)
	var v2: float = c.pos.distance_to(p1) / 0.1
	checar(v2 < 125.0, "voltou à velocidade normal depois da cauda (%.0f px/s)" % v2)
	checar(c.energia > e0, "a energia não é mais gasta ao soltar (%.2f → %.2f)" % [e0, c.energia])


# ---------------------------------------------------------------- v0.18: rampa de aceleração

## Toda caminhada NOVA começa lenta (`rota.rampa_s`, 0,30 s) e chega à
## velocidade normal: o primeiro 0,1 s anda MENOS que um 0,1 s já em cruzeiro.
func test_rampa_de_aceleracao_no_comeco_da_rota() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(376, 48)])}, m, [])
	var p0: Vector2 = c.pos
	_rodar(c, m, 0.1)
	var primeiro: float = c.pos.distance_to(p0)
	# passa a rampa (0,3 s) e mede o MESMO 0,1 s em velocidade de cruzeiro
	_rodar(c, m, 0.4)
	var p1: Vector2 = c.pos
	_rodar(c, m, 0.1)
	var cruzeiro: float = c.pos.distance_to(p1)
	checar(primeiro < cruzeiro * 0.6, "o começo é mais lento (%.1f vs %.1f px)" % [primeiro, cruzeiro])
	checar(cruzeiro > 9.0, "depois da rampa anda na velocidade normal (%.1f px)" % cruzeiro)
	perto(c._rampa_t, c._rampa_s(), 0.001, "a rampa já completou")


## A rampa REARMA só numa rota NOVA: crescer o traço ao vivo
## (`tracar(inicio=false)`) não reinicia o relógio; um caminho novo reinicia.
func test_rampa_rearma_so_com_rota_nova() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var origem: Vector2 = c.pos
	checar(c.tracar(PackedVector2Array([origem, Vector2(240, 48)]), m, true).begins_with("ok"), "traço")
	_rodar(c, m, 0.2)
	var t_antes: float = c._rampa_t
	checar(t_antes > 0.0, "a rampa começou")
	checar(c.tracar(PackedVector2Array([origem, Vector2(240, 48), Vector2(320, 48)]), m, false).begins_with("ok"), "o traço cresce")
	checar(c._rampa_t >= t_antes, "crescer o traço NÃO reinicia a rampa (%.3f → %.3f)" % [t_antes, c._rampa_t])
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(48, 240)])}, m, [])
	perto(c._rampa_t, 0.0, 0.001, "um caminho NOVO rearma a rampa")


# ---------------------------------------------------------------- v0.18: carga cancelada

## Um caminho NOVO cancela a carga do tiro (o tiro preparado valia para o
## caminho que o jogador acabou de fechar).
func test_caminho_novo_cancela_a_carga() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(300, 48)])}, m, [])
	igual(c.comandar({"acao": "tiro", "alvo": c.pos + Vector2(0, 100)}, m, []), "ok: carregando", "carrega")
	checar(c.carregando(), "carregando")
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(48, 240)])}, m, [])
	checar(not c.carregando(), "a carga foi cancelada pelo caminho novo")
	perto(c.carga(), 0.0, 0.001, "carga zerada")
	var evs := _rodar(c, m, 1.1)
	checar("tiro:disparo" not in evs, "não disparou (%s)" % [evs])
	checar(c.em_rota(), "segue o caminho novo")


## Um SEGURAR cancela a carga (o jogador mudou de ideia) e CORRE, como na
## v0.16: o sprint é contínuo e gasta energia.
func test_segurar_cancela_a_carga_e_corre() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(330, 48)])}, m, [])
	_rodar(c, m, 0.4)  # a rampa já passou
	igual(c.comandar({"acao": "tiro", "alvo": c.pos + Vector2(0, 100)}, m, []), "ok: carregando", "carrega")
	_rodar(c, m, 0.2)
	checar(c.carregando(), "carregando")
	igual(c.comandar({"acao": "segurar"}, m, []), "ok: sprint", "segurar cancela a carga e corre")
	checar(not c.carregando(), "a carga foi cancelada")
	checar(c._sprint, "sprint ligado")
	var e0: float = c.energia
	var antes: Vector2 = c.pos
	_rodar(c, m, 0.2)
	var v: float = c.pos.distance_to(antes) / 0.2
	checar(v > 150.0, "acelerou (%.0f px/s)" % v)
	checar(c.energia < e0 - 0.05, "gastou energia (%.2f → %.2f)" % [e0, c.energia])
	igual(c.comandar({"acao": "soltar_segurar"}, m, []), "ok", "soltar não atira")
	checar(not c.carregando(), "continua sem carga")


## SEGURAR sem caminho nem alvo = HABILIDADE (cavar), ativada na hora.
func test_segurar_sem_caminho_cava() -> void:
	var s := _setup(TERRA, TUNEL)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.pos = Vector2(16, 48)  # célula (0,1) = terra fofa
	checar(c.comandar({"acao": "segurar"}, m, []).begins_with("ok"), "segurar sem caminho cava")
	checar(c.escavando, "cavando já")
	_rodar(c, m, 1.2)
	igual(c.camada, M.SUBSOLO, "desceu")


## v0.11.3: a LINHA apaga o trecho já andado (`corpo.traco_t` avança, nunca
## volta e fica dentro do traço). O desenho usa esse corte em `jogo/trilha.gd`.
func test_traco_vai_apagando_o_trecho_andado() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(240, 48)])}, m, [])
	var ultimo := 0.0
	var subiu := false
	var t := 0.0
	while c.em_rota() and t < 3.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		if c.traco_t > 0.1:
			subiu = true
		checar(c.traco_t >= ultimo - 0.01, "o corte nunca volta (%.2f < %.2f)" % [c.traco_t, ultimo])
		ultimo = c.traco_t
		t += 1.0 / 30.0
	checar(subiu, "o corte avançou enquanto andava")
	var total := preload("res://sim/trajetoria.gd").comprimento(c.traco)
	checar(c.traco_t <= total + 0.01, "corte dentro do traço (%.1f/%.1f)" % [c.traco_t, total])


# ---------------------------------------------------------------- v0.11.1: estrada que não corta

## O LAÇO é ANDADO: a criatura passa pelo lado direito e pelo fundo do laço
## (em vez de "pular" no cruzamento para a continuação) e termina no fim.
func test_laco_e_andado_sem_cortar_a_volta() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([
		Vector2(240, 48), Vector2(240, 190), Vector2(110, 190), Vector2(110, 30)])}, m, [])
	var direita := false
	var fundo := false
	var barrado := 0
	var t := 0.0
	while c.em_rota() and t < 10.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		if c.barrado():
			barrado += 1
		if c.pos.x > 210.0 and c.pos.y > 150.0:
			direita = true
		if c.pos.y > 170.0 and c.pos.x < 150.0:
			fundo = true
		t += 1.0 / 30.0
	checar(direita, "passou pelo lado direito do laço (%s)" % c.pos)
	checar(fundo, "passou pelo fundo do laço (%s)" % c.pos)
	checar(not c.em_rota(), "a rota terminou (não cortou para a volta)")
	checar(barrado == 0, "não parou na barreira (%d quadros)" % barrado)
	while c.em_inercia():
		c.passo(1.0 / 30.0, m, [])
	var d: float = c.pos.distance_to(Vector2(110, 30))
	checar(d < 40.0, "terminou perto do fim do laço (d=%.0f)" % d)


## O BICO (ida e volta sobre a mesma linha) é andado ATÉ A PONTA e continua:
## a criatura não fica oscilando/travada na ponta do retorno.
func test_bico_e_andado_ate_a_ponta_e_continua() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([
		Vector2(150, 48), Vector2(150, 160), Vector2(150, 48), Vector2(280, 48)])}, m, [])
	var fundo := false
	var barrado := 0
	var t := 0.0
	while c.em_rota() and t < 10.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		if c.barrado():
			barrado += 1
		if c.pos.y > 150.0:
			fundo = true
		t += 1.0 / 30.0
	checar(fundo, "chegou na ponta do bico (%s)" % c.pos)
	checar(not c.em_rota(), "saiu do bico (não travou na ponta) em %.1f s" % t)
	checar(barrado == 0, "não parou na barreira (%d quadros)" % barrado)
	while c.em_inercia():
		c.passo(1.0 / 30.0, m, [])
	checar(c.pos.x > 260.0, "continuou o caminho depois do bico (x=%.0f)" % c.pos.x)


## BEIRA DE ÁGUA: a rota corre a 1 px da água; o desvio orgânico lateral NÃO
## pode empurrar o alvo para dentro do mar nem travar a caminhada.
const COSTA := [
	"~~~~~~~~~~~~", "~~~~~~~~~~~~",
	",,,,,,,,,,,,", ",,,,,,,,,,,,", ",,,,,,,,,,,,", ",,,,,,,,,,,,", ",,,,,,,,,,,,", ",,,,,,,,,,,,",
]

func test_beira_de_agua_nao_trava_quando_a_rota_contorna() -> void:
	var s := _setup(COSTA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.pos = Vector2(48, 65)  # 1 px abaixo da linha da água
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(340, 65)])}, m, []).begins_with("ok"), "rota pela beira")
	var barrado := 0
	var t := 0.0
	while c.em_rota() and t < 6.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		if c.barrado():
			barrado += 1
		t += 1.0 / 30.0
	checar(barrado == 0, "não travou na beira (%d quadros)" % barrado)
	checar(not c.em_rota(), "percorreu a beira toda")
	while c.em_inercia():
		c.passo(1.0 / 30.0, m, [])
	checar(c.pos.x > 320.0, "chegou ao fim da beirada (x=%.0f)" % c.pos.x)


## AMONTOADO no meio do traço: um laço de 20×22 px não é andado; a rota corta
## direto e o animal segue.
func test_amontoado_curto_e_cortado_da_rota() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([
		Vector2(120, 48), Vector2(140, 48), Vector2(140, 70), Vector2(120, 70),
		Vector2(120, 48), Vector2(240, 48)])}, m, [])
	checar(c.rota.size() <= 4, "a rota ficou curta (%s)" % [c.rota])
	for p in c.rota:
		checar(p.y < 60.0, "não sobrou o laço na rota (%s)" % [c.rota])
	checar(c.total_rota < 220.0, "comprimento sem o amontoado (%.0f)" % c.total_rota)
	var t := 0.0
	while c.em_rota() and t < 5.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		t += 1.0 / 30.0
	while c.em_inercia():
		c.passo(1.0 / 30.0, m, [])
	checar(c.pos.x > 235.0, "seguiu ao fim (x=%.0f)" % c.pos.x)


## LAÇO PEQUENO não acende a área: o traço do amontoado passa pelo leitor de
## formas, mas fica abaixo do tamanho mínimo (não vira marca).
func test_laco_pequeno_nao_acende_a_area() -> void:
	var s := _setup(MAPA, [], 5, _acoes_com_laco(true))
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([
		Vector2(120, 48), Vector2(140, 48), Vector2(140, 70), Vector2(120, 70),
		Vector2(120, 48), Vector2(240, 48)])}, m, [])
	var lacos := 0
	for marca in c.marcas:
		if str(marca["tipo"]) == "laco":
			lacos += 1
	igual(lacos, 0, "laço pequeno não marcou a área")
	var evs := _rodar(c, m, 1.0)
	checar("laco:onda" not in evs, "não disparou a onda (%s)" % [evs])


## INÉRCIA maior no SPRINT manual: o pedaço de frenagem fora da rota cresce um
## pouco quando a criatura chega acelerada pelo segurar.
func _frenagem(sprint: bool) -> float:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(340, 48)])}, m, [])
	if sprint:
		c.comandar({"acao": "segurar"}, m, [])
	var t := 0.0
	while c.em_rota() and t < 8.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		t += 1.0 / 30.0
	var p0: Vector2 = c.pos
	var t2 := 0.0
	while c.em_inercia() and t2 < 2.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		t2 += 1.0 / 30.0
	return c.pos.distance_to(p0)


func test_inercia_do_sprint_e_um_pouco_maior() -> void:
	var normal := _frenagem(false)
	var sprint := _frenagem(true)
	checar(normal > 8.0 and normal < 24.0, "frenagem normal curta (%.1f px)" % normal)
	checar(sprint > normal + 3.0, "frenagem do sprint um pouco maior (%.1f vs %.1f px)" % [sprint, normal])
	checar(sprint < normal + 20.0, "não exagera no sprint (%.1f px)" % sprint)


# ---------------------------------------------------------------- v0.11.4: ajustes do operador

## v0.11.4: passar POR CIMA e SEGUIR para longe não deixa a marca — o animal
## não volta do fim do caminho para dar o golpe de perseguição num alvo que só
## empurrou de passagem. (A batida da travessia continua acontecendo.)
func test_passar_por_cima_e_seguir_longe_nao_volta_para_bater() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var adv := _adv(Vector2(150, 48))
	var alvos := [_alvo_adv("adversario:0", adv)]
	# TRAÇO AO VIVO: a ponta chega no inimigo...
	checar(c.tracar(PackedVector2Array([c.pos, Vector2(150, 48)]), m, true, alvos).begins_with("ok"), "traço até o inimigo")
	igual(c.mira_final_id, "adversario:0", "marcou ao chegar nele")
	# ...e continua, sem soltar o dedo, até LONGE dele
	checar(c.tracar(PackedVector2Array([c.pos, Vector2(150, 48), Vector2(330, 48)]), m, false, alvos).begins_with("ok"), "segue o traço")
	igual(c.mira_final_id, "", "a marca saiu quando a ponta se afastou")
	var evs := _rodar_com(c, m, alvos, adv, 5.0)
	checar("batida:adversario:0" in evs, "deu a batida ao passar (%s)" % [evs])
	checar("golpe_final:adversario:0" not in evs, "NÃO voltou para o golpe final (%s)" % [evs])
	checar(c.pos.x > 300.0, "foi até o fim do caminho, sem voltar (x=%.0f)" % c.pos.x)


## v0.11.4: o pulo PEDIDO durante o ar é percebido na hora e sai no quadro em
## que o primeiro termina — dois (ou mais) pulos emendam sem o atraso de
## esperar o toque cair no chão.
func test_pulo_pedido_no_ar_sai_ao_terminar_o_primeiro() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	checar(c.comandar({"acao": "pular"}, m, []).begins_with("ok"), "1º pulo")
	_rodar(c, m, 0.1)
	igual(c.comandar({"acao": "pular"}, m, []), "ok: pulo na fila", "o 2º pulo fica na fila")
	# sem NENHUM comando novo, o 2º sobe quando o 1º pousa (~0,32 s depois)
	var evs := _rodar(c, m, 0.5)
	var ons := 0
	for e in evs:
		if e == "pulo:on":
			ons += 1
	igual(ons, 1, "o 2º pulo saiu sozinho (%s)" % [evs])
	checar(c.z > 6.0, "está no ar no 2º pulo (z=%.1f)" % c.z)
	perto(float(c._pulo_fila_t), 0.0, 0.001, "a fila foi consumida")


## Distância andada DURANTE um pulo, numa rota reta; com `sprint`, segura e
## SOLTA antes de pular (a cauda é o que tem de manter o embalo).
func _pulo_andado(sprint: bool) -> float:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(340, 48)])}, m, [])
	_rodar(c, m, 0.15)
	if sprint:
		c.comandar({"acao": "segurar"}, m, [])
		_rodar(c, m, 0.2)
		c.comandar({"acao": "soltar_segurar"}, m, [])
	c.comandar({"acao": "pular"}, m, [])
	var p0: Vector2 = c.pos
	var t := 0.0
	while c.no_ar() and t < 1.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		t += 1.0 / 30.0
	return c.pos.distance_to(p0)


## v0.11.4 (o pedido do operador): depois de soltar o acelerador ainda dá para
## PULAR acelerado — o pulo vai mais longe do que o pulo normal.
func test_pulo_com_cauda_do_sprint_vai_mais_longe() -> void:
	var normal := _pulo_andado(false)
	var com_cauda := _pulo_andado(true)
	checar(normal > 20.0, "o pulo normal anda (%.1f px)" % normal)
	checar(com_cauda > normal * 1.2, "o pulo com cauda vai mais longe (%.1f vs %.1f px)" % [com_cauda, normal])


# ---------------------------------------------------------------- v0.11.5: laço desligado

## v0.11.5: o ATAQUE EM ÁREA do laço está DESLIGADO (decisão do operador).
## Desenhar um círculo continua sendo CAMINHO — a rota é andada normalmente —
## mas não nasce marca de área nem sai a ONDA.
func test_laco_desenhado_nao_vira_mais_ataque_em_area() -> void:
	var s := _setup(MAPA)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	var adv := _adv(Vector2(175, 119))
	var alvos := [_alvo_adv("adversario:0", adv)]
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([
		Vector2(240, 48), Vector2(240, 190), Vector2(110, 190), Vector2(110, 30)])}, m, alvos).begins_with("ok"), "rota com laço")
	var lacos := 0
	for mm in c.marcas:
		if str(mm["tipo"]) == "laco":
			lacos += 1
	igual(lacos, 0, "nenhuma marca de área (%s)" % [c.marcas])
	checar(c.total_rota > 200.0, "a rota do laço continua valendo (%.0f px)" % c.total_rota)
	var evs := _rodar_com(c, m, alvos, adv, 8.0)
	checar("laco:onda" not in evs, "nenhuma onda saiu (%s)" % [evs])
	checar(not c.em_rota(), "andou o caminho até o fim (%.0f px)" % c.pos.x)


# ---------------------------------------------------------------- v0.13: pulo automático e pulo no sprint

## Escada de UM nível (^ = altura 2) no meio do caminho; a rota termina em cima.
const DEGRAU := [
	",,,,,,,,,,,,",
	",,,,^^^^^^^^",
	",,,,,,,,,,,,",
]
## Escada de DOIS níveis (q = altura 3): o pulo automático NÃO deve disparar.
const DEGRAU_DOIS := [
	",,,,,,,,,,,,",
	",,,,qqqqqqqq",
	",,,,,,,,,,,,",
]


func test_pulo_auto_vem_desligado_por_padrao() -> void:
	var s := _setup(DEGRAU)
	var c: RefCounted = s[1]
	checar(not c.pulo_auto, "padrão desligado (decisão: o jogador liga no botão)")
	var cfg: Dictionary = acoes.duplicate(true)
	cfg["pular"]["auto_padrao"] = true
	var c2 := Corpo.new(cfg)
	checar(c2.pulo_auto, "o dado `pular.auto_padrao` liga")


func test_pulo_auto_sobe_o_degrau_de_um_nivel_e_segue() -> void:
	var s := _setup(DEGRAU)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.pulo_auto = true
	checar(c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(336, 48)])}, m, []).begins_with("ok"), "aceitou a rota")
	var evs := _rodar(c, m, 6.0)
	checar("pulo:auto" in evs, "pulou sozinho (%s)" % [evs])
	checar(c.pos.x > 280.0, "subiu o degrau e seguiu no planalto (x=%.0f)" % c.pos.x)


func test_pulo_auto_desligado_para_no_degrau() -> void:
	var s := _setup(DEGRAU)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(336, 48)])}, m, [])
	var evs := _rodar(c, m, 2.0)
	checar("pulo:auto" not in evs, "não pulou com o sistema desligado (%s)" % [evs])
	checar(c.barrado(), "parou na barreira")
	checar(c.pos.x < 140.0, "ficou antes do degrau (x=%.0f)" % c.pos.x)


func test_pulo_auto_nao_pula_dois_niveis() -> void:
	var s := _setup(DEGRAU_DOIS)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.pulo_auto = true
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(336, 48)])}, m, [])
	var evs := _rodar(c, m, 2.0)
	checar("pulo:auto" not in evs, "degrau de 2 níveis não dispara (%s)" % [evs])
	checar(c.barrado(), "continua parado na beirada")


func test_pulo_auto_nao_pula_quando_o_caminho_acaba_antes_do_degrau() -> void:
	var s := _setup(DEGRAU)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.pulo_auto = true
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(120, 48)])}, m, [])
	var evs := _rodar(c, m, 1.5)
	checar("pulo:auto" not in evs, "sem caminho do outro lado, não pula (%s)" % [evs])
	checar(c.pos.x < 128.0, "parou na ponta do caminho (x=%.0f)" % c.pos.x)


## Distância andada DURANTE um pulo, com `pular.sprint_fator` configurável.
## O embalo vem do segurar e SOLTA antes do pulo: é a CAUDA que vale no ar.
func _pulo_andado_com(sprint: bool, cfg: Dictionary) -> float:
	var s := _setup(MAPA, [], 5, cfg)
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(340, 48)])}, m, [])
	_rodar(c, m, 0.15)
	if sprint:
		c.comandar({"acao": "segurar"}, m, [])
		_rodar(c, m, 0.2)
		c.comandar({"acao": "soltar_segurar"}, m, [])
	c.comandar({"acao": "pular"}, m, [])
	var p0: Vector2 = c.pos
	var t := 0.0
	while c.no_ar() and t < 1.0:
		c.passo(1.0 / 30.0, m, [])
		c.drenar_eventos()
		t += 1.0 / 30.0
	return c.pos.distance_to(p0)


## v0.13: no AR com o sprint (ou a cauda) ativo, o avanço horizontal ganha
## `pular.sprint_fator` — o pulo acelerado vai mais longe que antes.
func test_pulo_no_sprint_alonga_o_avanco_do_ar() -> void:
	var sem: Dictionary = acoes.duplicate(true)
	sem["pular"]["sprint_fator"] = 1.0
	var com: Dictionary = acoes.duplicate(true)
	com["pular"]["sprint_fator"] = 1.5
	var d_sem := _pulo_andado_com(true, sem)
	var d_com := _pulo_andado_com(true, com)
	checar(d_sem > 30.0, "o pulo acelerado anda (%.1f px)" % d_sem)
	checar(d_com > d_sem * 1.3, "o fator alonga o pulo (%.1f vs %.1f px)" % [d_com, d_sem])


## O fator é SÓ do ar: o pulo normal (sem sprint) não muda.
func test_pulo_normal_nao_muda_com_o_fator_do_sprint() -> void:
	var sem: Dictionary = acoes.duplicate(true)
	sem["pular"]["sprint_fator"] = 1.0
	var com: Dictionary = acoes.duplicate(true)
	com["pular"]["sprint_fator"] = 1.5
	var d_sem := _pulo_andado_com(false, sem)
	var d_com := _pulo_andado_com(false, com)
	checar(absf(d_com - d_sem) < 4.0, "sem sprint o fator não vale (%.1f vs %.1f px)" % [d_com, d_sem])


## Vão de ÁGUA curto ANTES do degrau: o pulo automático cruza o vão e sobe
## (é o caso do pátio de parkour para a passarela).
func test_pulo_auto_cruza_vao_curto_e_sobe_o_degrau() -> void:
	var s := _setup([
		",,,,,,,,,,,,",
		",,,,~^^^^^^^",
		",,,,,,,,,,,,",
	])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.pulo_auto = true
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(336, 48)])}, m, [])
	var evs := _rodar(c, m, 6.0)
	checar("pulo:auto" in evs, "pulou o vão e subiu (%s)" % [evs])
	checar(c.pos.x > 200.0, "chegou ao planalto (x=%.0f)" % c.pos.x)


## Água no MESMO nível não é "obstáculo de um nível de altura": o sistema não
## pula, mesmo com o caminho continuando do outro lado.
func test_pulo_auto_nao_pula_vao_de_agua_no_mesmo_nivel() -> void:
	# coluna de água de ponta a ponta (não dá para CONTORNAR; só pular)
	var s := _setup([
		",,,,~,,,,,,,",
		",,,,~,,,,,,,",
		",,,,~,,,,,,,",
	])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.pulo_auto = true
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(336, 48)])}, m, [])
	var evs := _rodar(c, m, 2.0)
	checar("pulo:auto" not in evs, "sem degrau de altura, não pula (%s)" % [evs])
	# o contorno de TERRENO tenta a volta e falha (a coluna vai de ponta a
	# ponta), então o flag `barrado` oscila; o que importa é não atravessar.
	checar(c.pos.x < 132.0, "ficou na beira da água (x=%.0f)" % c.pos.x)


## Vão de 2 células antes do degrau, sem sprint: o pulo NÃO alcança o pouso,
## então o sistema não dispara (não pula para cair na água).
func test_pulo_auto_nao_pula_vao_de_2_celulas_sem_sprint() -> void:
	var s := _setup([
		",,,,,,,,,,,,",
		",,,,~~^^^^^^",
		",,,,,,,,,,,,",
	])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.pulo_auto = true
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(336, 48)])}, m, [])
	var evs := _rodar(c, m, 2.0)
	checar("pulo:auto" not in evs, "pouso fora do alcance não dispara (%s)" % [evs])
	checar(c.barrado(), "para na beira do vão")
	checar(c.pos.x < 140.0, "ficou antes do vão (x=%.0f)" % c.pos.x)


## Com o SPRINT (segurar), o pulo alonga e o mesmo vão de 2 células passa a ser
## alcançável: o automático cruza e sobe.
func test_pulo_auto_com_sprint_cruza_vao_de_2_celulas() -> void:
	var s := _setup([
		",,,,,,,,,,,,",
		",,,,~~^^^^^^",
		",,,,,,,,,,,,",
	])
	var m: RefCounted = s[0]
	var c: RefCounted = s[1]
	c.pulo_auto = true
	c.comandar({"acao": "mover", "pontos": PackedVector2Array([Vector2(336, 48)])}, m, [])
	c.comandar({"acao": "segurar"}, m, [])
	var evs := _rodar(c, m, 6.0)
	checar("pulo:auto" in evs, "o pulo do sprint alcança (%s)" % [evs])
	checar(c.pos.x > 200.0, "chegou ao planalto (x=%.0f)" % c.pos.x)
