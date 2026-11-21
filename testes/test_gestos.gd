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

## O primeiro dedo arrasta e JÁ desenha, sem espera.
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


func test_toque_e_toque_duplo() -> void:
	var r := _r()
	igual(_nomes(_toque(r, Vector2(600, 300), 0, 90)), ["toque"], "1º toque")
	igual(_nomes(_toque(r, Vector2(605, 302), 250, 80)), ["toque", "toque_duplo"], "2º perto e logo")


func test_toque_longo_vira_nada() -> void:
	var r := _r()
	igual(_nomes(_toque(r, Vector2(600, 300), 0, 500)), ["nada"], "passou do tempo de toque")


## O planejamento (tempo lento) só entra com o desenho CONFIRMADO.
func test_planejando_so_depois_do_desenho_confirmado() -> void:
	var r := _r()
	var p := Vector2(200, 1000)
	r.iniciar(0, p, 0, CRIA)
	r.mover(0, p + Vector2(40, 0), 60)
	checar(r.desenhando(), "desenha")
	checar(not r.planejando(), "ainda não desacelerou")
	r.mover(0, p + Vector2(80, 0), 300)
	checar(r.planejando(), "passou de desenho_min_ms: desacelera")


# ---------------------------------------------------------------- segurar = habilidade

## SEGURAR parado (em QUALQUER lugar da tela) ativa a habilidade em si mesmo.
func test_segurar_parado_e_habilidade() -> void:
	var r := _r()
	var p := Vector2(120, 200)  # longe da criatura: não importa
	r.iniciar(0, p, 0, CRIA)
	igual(r.tick(200), [], "antes do tempo")
	r.tick(400)
	var evs: Array = r.soltar(0, p, 500)
	igual(_nomes(evs), ["segurar_inicio"], "habilidade")
	var cmd := C.traduzir(evs[0], cfg["mapa"])
	igual(cmd["acao"], "habilidade", "segurar parado = habilidade")
	checar(not r.planejando(), "segurar não desacelera o mundo")


func test_segurar_precisa_de_um_dedo() -> void:
	var r := _r()
	var p := Vector2(120, 200)
	r.iniciar(0, p, 0, CRIA)
	r.iniciar(1, p + Vector2(80, 0), 20, CRIA)
	r.tick(500)
	igual(_nomes(r.soltar(0, p, 560)), [], "com dois dedos não vira habilidade")


# ---------------------------------------------------------------- dois dedos não são ação

## v0.9: o segundo dedo não é ação — o caminho do primeiro continua.
func test_segundo_dedo_nao_atrapalha_o_desenho() -> void:
	var r := _r()
	var p := Vector2(200, 1000)
	r.iniciar(0, p, 0, CRIA)
	r.mover(0, p + Vector2(40, 0), 100)
	checar(r.desenhando(), "desenha")
	r.iniciar(1, Vector2(500, 500), 120, CRIA)
	checar(r.desenhando(), "o segundo dedo não cancela o traço")
	igual(r.mover(1, Vector2(500, 420), 160), [], "o segundo dedo não dispara ação")
	r.mover(0, p + Vector2(160, 0), 300)
	checar(r.desenhando(), "o primeiro dedo continua desenhando")
	igual(_nomes(r.soltar(1, Vector2(500, 420), 320)), [], "soltar o segundo não faz nada")
	igual(_nomes(r.soltar(0, p + Vector2(200, 0), 500)), ["trajetoria"], "o caminho fecha")


## Dois dedos NUNCA viram toque (é o que evita pular/travar sem querer).
func test_dois_dedos_nunca_viram_toque() -> void:
	var r := _r()
	var p := Vector2(600, 300)
	r.iniciar(0, p, 0, CRIA)
	r.iniciar(1, p + Vector2(80, 0), 20, CRIA)
	r.soltar(1, p + Vector2(80, 0), 60)
	igual(_nomes(r.soltar(0, p, 90)), [], "sem toque")


# ---------------------------------------------------------------- tabela

func test_traduz_os_gestos() -> void:
	var m: Dictionary = cfg["mapa"]
	igual(C.traduzir({"gesto": "toque"}, m)["acao"], "travar", "toque = travar mira")
	igual(C.traduzir({"gesto": "toque_duplo"}, m)["acao"], "pular", "toque duplo = pular")
	igual(C.traduzir({"gesto": "segurar_inicio"}, m)["acao"], "habilidade", "segurar = habilidade")
	igual(C.traduzir({"gesto": "trajetoria"}, m)["acao"], "mover", "trajetória = mover")
	igual(C.traduzir({"gesto": "nada"}, m), {}, "nada")
	igual(C.traduzir({"gesto": "deslize", "vetor": Vector2(0, -100)}, m), {}, "não há mais gesto de dois dedos")
