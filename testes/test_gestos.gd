extends "res://testes/caso.gd"

const G := preload("res://sim/gestos.gd")
const C := preload("res://sim/comandos.gd")

var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/gestos.json"))
const CRIA := Vector2(360, 640)


func _r() -> RefCounted:
	return G.new(cfg["limiares"])


func _gesto(r: RefCounted, de: Vector2, ate: Vector2, t0: float, dur: float, passos := 5) -> Array:
	r.iniciar(de, t0, CRIA)
	for i in range(1, passos):
		r.mover(de.lerp(ate, float(i) / passos), t0 + dur * i / passos)
	return r.soltar(ate, t0 + dur)


func _nomes(evs: Array) -> Array:
	return evs.map(func(e): return e["gesto"])


func test_toque_e_toque_duplo() -> void:
	var r := _r()
	igual(_nomes(_gesto(r, Vector2(600, 300), Vector2(602, 301), 0, 90)), ["toque"], "1º toque")
	igual(_nomes(_gesto(r, Vector2(605, 302), Vector2(605, 302), 250, 80)), ["toque", "toque_duplo"], "2º perto e logo")


## v0.7: NÃO existe mais segurar antes. Passou da tolerância, é CAMINHO.
func test_arrasto_ja_e_caminho_sem_espera() -> void:
	var r := _r()
	var p := Vector2(200, 1000)
	r.iniciar(p, 0, CRIA)
	igual(r.mover(p + Vector2(8, 0), 20), [], "abaixo da tolerância ainda é toque")
	checar(not r.desenhando(), "não desenhou")
	var evs_meio: Array = r.mover(p + Vector2(40, 0), 60)
	igual(evs_meio, [], "40 px em 60 ms ainda é desenho lento")
	checar(r.desenhando(), "já é caminho — sem espera")
	checar(r.planejando(), "e o mundo desacelera")
	igual(r.inicio(), p, "o começo do traço é o ponto da descida")
	var evs: Array = r.soltar(p + Vector2(140, 0), 500)
	igual(_nomes(evs), ["trajetoria"], "soltar fecha o caminho")
	igual(evs[0]["inicio"], p, "e leva o começo junto")
	checar(not evs[0]["defesa"], "não é defesa")


## O RISCO rápido dispara a ação NO MEIO do arrasto; o caminho segue.
func test_risco_dispara_acao_no_meio_do_desenho() -> void:
	var r := _r()
	r.iniciar(Vector2(200, 700), 0, CRIA)
	var evs: Array = []
	var p := Vector2(200, 700)
	for i in range(1, 6):
		p += Vector2(0, -40)
		evs.append_array(r.mover(p, 30 * i))
	igual(_nomes(evs), ["deslize"], "uma ação, no meio do traço")
	checar(r.desenhando(), "o caminho continua sendo desenhado")
	var cmd := C.traduzir(evs[0], cfg["mapa"])
	igual(cmd["acao"], "ataque", "risco para cima = ataque")
	igual(cmd["setor"], "cima", "setor de cima")
	igual(_nomes(r.soltar(p + Vector2(20, -40), 220)), ["trajetoria"], "o soltar ainda fecha a rota")


## Um gesto dispara NO MÁXIMO uma ação (senão um desenho rápido vira metralhadora).
func test_um_risco_por_gesto() -> void:
	var r := _r()
	r.iniciar(Vector2(200, 700), 0, CRIA)
	var evs: Array = []
	var p := Vector2(200, 700)
	for i in range(1, 6):
		p += Vector2(40, 0)
		evs.append_array(r.mover(p, 30 * i))
	igual(_nomes(evs), ["deslize"], "só o primeiro risco dispara")


## Desenho lento não vira ação: é só caminho.
func test_desenho_lento_nao_dispara_acao() -> void:
	var r := _r()
	var p := Vector2(100, 900)
	r.iniciar(p, 0, CRIA)
	var evs: Array = []
	for i in range(1, 13):
		p += Vector2(20, 10)
		evs.append_array(r.mover(p, 120 * i))
	igual(evs, [], "nenhuma ação num traço lento")
	checar(r.desenhando(), "e continua sendo caminho")
	igual(_nomes(r.soltar(p, 1600)), ["trajetoria"], "fecha a rota")


## Curva rápida é desenho, não risco: o traço não é reto.
func test_risco_curvo_nao_dispara() -> void:
	var r := _r()
	var p0 := Vector2(300, 800)
	r.iniciar(p0, 0, CRIA)
	var evs: Array = []
	evs.append_array(r.mover(p0 + Vector2(40, 0), 15))    # 40 px: abaixo do mínimo
	evs.append_array(r.mover(p0 + Vector2(40, 40), 30))   # 90°: sai da corda
	evs.append_array(r.mover(p0 + Vector2(0, 40), 45))
	igual(evs, [], "sem ação num traço curvo")


## Deslizar para BAIXO e continuar PARADO = defesa sustentada.
func test_baixo_parado_defende() -> void:
	var r := _r()
	r.iniciar(Vector2(200, 700), 0, CRIA)
	r.mover(Vector2(200, 750), 100)
	r.mover(Vector2(200, 800), 300)
	igual(_nomes(r.tick(520)), ["segurar_inicio"], "defende")
	checar(r.defendendo(), "está defendendo")
	igual(_nomes(r.soltar(Vector2(200, 800), 900)), ["segurar_fim"], "soltou")


## Segurar em cima dela sem arrastar continua sendo escavar.
func test_segurar_nela_sem_arrastar_escava() -> void:
	var r := _r()
	r.iniciar(CRIA, 0, CRIA)
	igual(r.tick(200), [], "antes do tempo")
	r.tick(400)
	var evs: Array = r.soltar(CRIA, 500)
	igual(_nomes(evs), ["segurar_inicio"], "escavar")
	checar(evs[0]["na_criatura"], "em cima dela")
	checar(not evs[0]["defesa"], "não é defesa")


## Um arrasto curtinho (dentro da tolerância) ainda é toque, não caminho.
func test_arrasto_curto_continua_toque() -> void:
	var r := _r()
	igual(_nomes(_gesto(r, Vector2(400, 500), Vector2(408, 505), 0, 80)), ["toque"], "toque com tremida")


## Setores de TELA: cima = ataque, lados = especiais, baixo = esquiva.
func test_setores_de_tela() -> void:
	var m: Dictionary = cfg["mapa"]
	var cima := C.traduzir({"gesto": "deslize", "vetor": Vector2(0, -100)}, m)
	igual(cima["acao"], "ataque", "cima")
	igual(cima["setor"], "cima", "setor cima")
	var esq := C.traduzir({"gesto": "deslize", "vetor": Vector2(-100, 0)}, m)
	igual(esq["acao"], "especial", "esquerda")
	igual(esq["lado"], -1.0, "lado esquerdo")
	var dir := C.traduzir({"gesto": "deslize", "vetor": Vector2(100, 0)}, m)
	igual(dir["acao"], "especial", "direita")
	igual(dir["lado"], 1.0, "lado direito")
	var baixo := C.traduzir({"gesto": "deslize", "vetor": Vector2(0, 100)}, m)
	igual(baixo["acao"], "esquiva", "baixo")
	perto_v(baixo["direcao"], Vector2.DOWN, 0.01, "direção para baixo")
	# diagonal de cima-esquerda ainda é ataque (o setor mais próximo da tabela)
	igual(C.traduzir({"gesto": "deslize", "vetor": Vector2(-100, -100)}, m)["acao"], "ataque", "diagonal cima")


func test_traduz_os_outros_gestos() -> void:
	var m: Dictionary = cfg["mapa"]
	igual(C.traduzir({"gesto": "toque"}, m)["acao"], "travar", "toque = travar mira")
	igual(C.traduzir({"gesto": "toque_duplo"}, m)["acao"], "pular", "toque duplo")
	igual(C.traduzir({"gesto": "segurar_inicio", "na_criatura": false}, m)["acao"], "defender", "segurar")
	igual(C.traduzir({"gesto": "segurar_inicio", "na_criatura": true}, m)["acao"], "escavar", "segurar nela")
	igual(C.traduzir({"gesto": "segurar_inicio", "defesa": true, "na_criatura": true}, m)["acao"], "defender", "defesa vence o 'nela'")
	igual(C.traduzir({"gesto": "segurar_fim"}, m)["acao"], "soltar", "soltar")
	igual(C.traduzir({"gesto": "trajetoria"}, m)["acao"], "mover", "trajetória")
	igual(C.traduzir({"gesto": "nada"}, m), {}, "nada")
