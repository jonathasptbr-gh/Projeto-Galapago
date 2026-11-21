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


## A ÂNCORA: segurar parado cria o "animal virtual"; arrastar vira caminho.
func test_segurar_cria_ancora_e_arrasto_vira_caminho() -> void:
	var r := _r()
	var p := Vector2(200, 1000)
	r.iniciar(p, 0, CRIA)
	igual(r.tick(200), [], "ainda não")
	igual(r.tick(400), [], "âncora não gera comando")
	checar(r.ancorado(), "ancorou")
	r.mover(p + Vector2(80, -40), 470)
	r.mover(p + Vector2(160, -80), 560)
	var evs: Array = r.soltar(p + Vector2(200, -100), 700)
	igual(_nomes(evs), ["trajetoria"], "arrasto depois do segurar = caminho")
	igual(evs[0]["ancora"], p, "âncora é o ponto segurado")
	checar(not evs[0]["defesa"], "não é defesa")


## Segurar em cima dela sem arrastar continua sendo escavar.
func test_segurar_nela_sem_arrastar_escava() -> void:
	var r := _r()
	r.iniciar(CRIA, 0, CRIA)
	r.tick(400)
	var evs: Array = r.soltar(CRIA, 500)
	igual(_nomes(evs), ["segurar_inicio"], "escavar")
	checar(evs[0]["na_criatura"], "em cima dela")
	checar(not evs[0]["defesa"], "não é defesa")


## Arrastar para BAIXO e continuar segurando = defesa sustentada.
func test_baixo_segurando_defende() -> void:
	var r := _r()
	r.iniciar(Vector2(200, 700), 0, CRIA)
	r.mover(Vector2(200, 760), 80)
	r.mover(Vector2(200, 800), 150)
	igual(_nomes(r.tick(400)), ["segurar_inicio"], "defende")
	checar(r.defendendo(), "está defendendo")
	igual(_nomes(r.soltar(Vector2(200, 800), 900)), ["segurar_fim"], "soltou")


func test_baixo_rapido_esquiva_para_tras() -> void:
	var evs := _gesto(_r(), Vector2(200, 700), Vector2(200, 820), 0, 140)
	igual(_nomes(evs), ["deslize"], "esquiva")
	var cmd := C.traduzir(evs[0], cfg["mapa"])
	igual(cmd["acao"], "esquiva", "ação")
	perto_v(cmd["direcao"], Vector2.DOWN, 0.01, "direção do gesto")


## Sem o segurar antes, um arrasto rápido NÃO é caminho: é gesto de ação.
func test_arrasto_rapido_sem_segurar_nao_e_caminho() -> void:
	var evs := _gesto(_r(), CRIA + Vector2(10, 0), CRIA + Vector2(210, 20), 0, 120)
	igual(_nomes(evs), ["deslize"], "sem âncora = gesto")


func test_arrasto_lento_longe_e_nada() -> void:
	igual(_nomes(_gesto(_r(), Vector2(100, 900), Vector2(400, 900), 0, 900, 12)), ["nada"], "lento, sem âncora: nada")


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
