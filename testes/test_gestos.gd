extends "res://testes/caso.gd"

const G := preload("res://sim/gestos.gd")
const C := preload("res://sim/comandos.gd")

var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/gestos.json"))
const CRIA := Vector2(360, 640)


func _r() -> RefCounted:
	return G.new(cfg["limiares"])


func _nomes(evs: Array) -> Array:
	return evs.map(func(e): return e["gesto"])


func _toque(r: RefCounted, p: Vector2, t0: float, dur: float) -> Array:
	r.iniciar(0, p, t0, CRIA)
	return r.soltar(0, p, t0 + dur)


# ---------------------------------------------------------------- um dedo = caminho

## v0.8: o primeiro dedo arrasta e JÁ desenha, sem espera.
func test_um_dedo_arrasta_e_ja_e_caminho() -> void:
	var r := _r()
	var p := Vector2(200, 1000)
	r.iniciar(0, p, 0, CRIA)
	igual(r.mover(0, p + Vector2(8, 0), 20), [], "abaixo da tolerância ainda é toque")
	checar(not r.desenhando(), "não desenhou")
	r.mover(0, p + Vector2(40, 0), 60)
	checar(r.desenhando(), "40 px já é caminho — sem espera")
	igual(r.inicio(), p, "o começo do traço é o ponto da descida")
	var evs: Array = r.soltar(0, p + Vector2(140, 0), 500)
	igual(_nomes(evs), ["trajetoria"], "soltar fecha o caminho")
	igual(evs[0]["inicio"], p, "e leva o começo junto")


## Um dedo só NUNCA dispara ação: movimento e ação não se confundem.
func test_um_dedo_nunca_dispara_acao() -> void:
	var r := _r()
	r.iniciar(0, Vector2(100, 900), 0, CRIA)
	var evs: Array = []
	for i in range(1, 6):
		evs.append_array(r.mover(0, Vector2(100, 900 - 30 * i), 30 * i))
	igual(evs, [], "sem ação com um dedo")


func test_toque_e_toque_duplo() -> void:
	var r := _r()
	igual(_nomes(_toque(r, Vector2(600, 300), 0, 90)), ["toque"], "1º toque")
	igual(_nomes(_toque(r, Vector2(605, 302), 250, 80)), ["toque", "toque_duplo"], "2º perto e logo")


## Segurar em cima dela sem arrastar continua sendo escavar.
func test_segurar_nela_sem_arrastar_escava() -> void:
	var r := _r()
	r.iniciar(0, CRIA, 0, CRIA)
	igual(r.tick(200), [], "antes do tempo")
	r.tick(400)
	var evs: Array = r.soltar(0, CRIA, 500)
	igual(_nomes(evs), ["segurar_inicio"], "escavar")
	checar(evs[0]["na_criatura"], "em cima dela")
	checar(not evs[0]["defesa"], "não é defesa")


# ---------------------------------------------------------------- dois dedos = ação

## Dois dedos: o EXTRA sobe → ataque; o dedo parado não desenha caminho.
func test_dois_dedos_para_cima_atacam_sem_andar() -> void:
	var r := _r()
	r.iniciar(0, Vector2(300, 800), 0, CRIA)
	r.iniciar(1, Vector2(300, 900), 20, CRIA)
	checar(not r.desenhando(), "dois dedos não desenham")
	var evs: Array = []
	for i in range(1, 4):
		evs.append_array(r.mover(1, Vector2(300, 900 - 40 * i), 20 + 30 * i))
	igual(_nomes(evs), ["deslize"], "ataque")
	var cmd := C.traduzir(evs[0], cfg["mapa"])
	igual(cmd["acao"], "ataque", "setor de cima")
	checar(not r.desenhando(), "nenhum caminho")
	igual(_nomes(r.soltar(1, Vector2(300, 780), 200)), [], "soltar o extra não faz nada")
	igual(_nomes(r.soltar(0, Vector2(300, 800), 220)), [], "e o dedo parado não vira toque")


## Dois dedos: o EXTRA desce e fica → defesa sustentada até soltar.
func test_dois_dedos_para_baixo_defendem() -> void:
	var r := _r()
	r.iniciar(0, Vector2(300, 600), 0, CRIA)
	r.iniciar(1, Vector2(300, 500), 20, CRIA)
	var evs: Array = []
	evs.append_array(r.mover(1, Vector2(300, 540), 60))
	checar(evs.is_empty(), "40 px ainda não é defesa")
	evs.append_array(r.mover(1, Vector2(300, 600), 100))
	igual(_nomes(evs), ["segurar_inicio"], "defesa")
	checar(evs[0]["defesa"], "é defesa")
	checar(r.defendendo(), "sustentada")
	igual(_nomes(r.soltar(1, Vector2(300, 600), 900)), ["segurar_fim"], "soltou")


## Dois dedos abrindo para fora → especial (e vai na direção de fora).
func test_dois_dedos_abrindo_especial() -> void:
	var r := _r()
	r.iniciar(0, Vector2(300, 600), 0, CRIA)
	r.iniciar(1, Vector2(300, 700), 20, CRIA)
	var evs: Array = r.mover(1, Vector2(380, 760), 100)
	igual(_nomes(evs), ["especial"], "especial")
	var cmd := C.traduzir(evs[0], cfg["mapa"])
	igual(cmd["acao"], "especial", "ação")
	checar(cmd["direcao"].x > 0.5, "para fora (%s)" % cmd["direcao"])


# ---------------------------------------------------------------- desenhar e agir

## O caso central: desenhar o caminho e ATACAR com o segundo dedo, sem parar o
## traço e sem a criatura mudar de rumo.
func test_ataque_durante_o_desenho() -> void:
	var r := _r()
	r.iniciar(0, Vector2(200, 1000), 0, CRIA)
	r.mover(0, Vector2(240, 1000), 100)   # o traço NASCE aqui (t=100)
	r.mover(0, Vector2(280, 1000), 300)   # já desenha há 200 ms
	checar(r.desenhando(), "está desenhando")
	r.iniciar(1, Vector2(400, 900), 320, CRIA)
	checar(r.desenhando(), "o segundo dedo NÃO interrompe o desenho")
	var evs: Array = []
	evs.append_array(r.mover(1, Vector2(400, 840), 360))
	evs.append_array(r.mover(1, Vector2(400, 780), 400))
	igual(_nomes(evs), ["deslize"], "ataque no meio do desenho")
	checar(r.desenhando(), "e o caminho continua")
	igual(_nomes(r.soltar(1, Vector2(400, 780), 420)), [], "o extra sai calado")
	igual(_nomes(r.soltar(0, Vector2(340, 1000), 500)), ["trajetoria"], "o caminho fecha no soltar")


## Dois dedos ANTES de o caminho desenhar: o traço cai e o gesto é só ação.
func test_segundo_dedo_cedo_cancela_o_caminho() -> void:
	var r := _r()
	r.iniciar(0, Vector2(200, 1000), 0, CRIA)
	r.mover(0, Vector2(240, 1000), 40)
	checar(r.desenhando(), "começou a desenhar")
	var evs: Array = r.iniciar(1, Vector2(400, 900), 60, CRIA)
	igual(_nomes(evs), ["caminho_cancelar"], "o traço é cancelado")
	checar(not r.desenhando(), "não desenha mais")
	r.mover(0, Vector2(300, 1000), 100)
	checar(not r.desenhando(), "o dedo do caminho não desenha num gesto de dois")


## Um gesto de ação dispara UMA vez (para não virar metralhadora).
func test_acao_uma_vez_por_gesto() -> void:
	var r := _r()
	r.iniciar(0, Vector2(300, 800), 0, CRIA)
	r.iniciar(1, Vector2(300, 900), 20, CRIA)
	var evs: Array = []
	for i in range(1, 5):
		evs.append_array(r.mover(1, Vector2(300, 900 - 30 * i), 20 + 30 * i))
	igual(_nomes(evs), ["deslize"], "só o primeiro disparo")


func test_uma_acao_por_gesto_de_dois_dedos() -> void:
	var r := _r()
	r.iniciar(0, Vector2(300, 800), 0, CRIA)
	r.iniciar(1, Vector2(300, 900), 20, CRIA)
	var evs: Array = []
	evs.append_array(r.mover(1, Vector2(300, 840), 60))
	igual(_nomes(evs), ["deslize"], "primeiro")
	igual(_nomes(r.mover(1, Vector2(300, 780), 90)), [], "o segundo movimento não repete")


# ---------------------------------------------------------------- tabela

func test_setores_de_tela() -> void:
	var m: Dictionary = cfg["mapa"]
	igual(C.traduzir({"gesto": "deslize", "vetor": Vector2(0, -100)}, m)["acao"], "ataque", "cima")
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
	igual(C.traduzir({"gesto": "especial", "vetor": Vector2(80, 60)}, m)["acao"], "especial", "especial")
	igual(C.traduzir({"gesto": "nada"}, m), {}, "nada")
