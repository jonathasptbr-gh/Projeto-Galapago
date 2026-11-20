extends "res://testes/caso.gd"

const G := preload("res://sim/gestos.gd")
const C := preload("res://sim/comandos.gd")

var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/gestos.json"))
const CRIA := Vector2(640, 360)


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
	igual(_nomes(_gesto(r, Vector2(900, 300), Vector2(902, 301), 0, 90)), ["toque"], "1º toque")
	igual(_nomes(_gesto(r, Vector2(905, 302), Vector2(905, 302), 250, 80)), ["toque", "toque_duplo"], "2º perto e logo")


func test_segurar_e_defender() -> void:
	var r := _r()
	r.iniciar(Vector2(300, 300), 0, CRIA)
	igual(r.tick(200), [], "ainda não")
	igual(_nomes(r.tick(400)), ["segurar_inicio"], "segurou")
	igual(_nomes(r.soltar(Vector2(302, 300), 900)), ["segurar_fim"], "soltou")


## A REGRA NOVA: arrasto começando perto da criatura é ROTA, mesmo RÁPIDO.
func test_arrasto_perto_e_sempre_rota_mesmo_rapido() -> void:
	var rapido := _gesto(_r(), CRIA + Vector2(10, 0), CRIA + Vector2(200, 60), 0, 120)
	igual(_nomes(rapido), ["trajetoria"], "rápido, perto: rota")
	var lento := _gesto(_r(), CRIA + Vector2(20, 0), CRIA + Vector2(300, 80), 0, 900, 12)
	igual(_nomes(lento), ["trajetoria"], "lento, perto: rota")


func test_arrasto_longe_e_gesto() -> void:
	igual(_nomes(_gesto(_r(), Vector2(200, 600), Vector2(320, 560), 0, 150)), ["deslize"], "rápido, longe: gesto")
	igual(_nomes(_gesto(_r(), Vector2(100, 650), Vector2(400, 650), 0, 900, 12)), ["nada"], "lento, longe: nada")


func test_deslize_vira_acao_pelo_setor() -> void:
	var m: Dictionary = cfg["mapa"]
	var olhar := Vector2.RIGHT
	igual(C.traduzir({"gesto": "deslize", "vetor": Vector2(1, 0) * 100.0}, olhar, m)["acao"], "ataque", "frente")
	igual(C.traduzir({"gesto": "deslize", "vetor": Vector2(1, -0.3) * 100.0}, olhar, m)["acao"], "ataque", "frente acima")
	var esq := C.traduzir({"gesto": "deslize", "vetor": Vector2(0, -1) * 100.0}, olhar, m)
	igual(esq["acao"], "esquiva", "esquerda")
	igual(esq["lado"], -1.0, "lado esquerdo")
	var dir := C.traduzir({"gesto": "deslize", "vetor": Vector2(0, 1) * 100.0}, olhar, m)
	igual(dir["acao"], "esquiva", "direita")
	igual(dir["lado"], 1.0, "lado direito")
	# relativo ao olhar: olhando para o SUL, um deslize para leste é a ESQUERDA dela
	igual(C.traduzir({"gesto": "deslize", "vetor": Vector2(1, 0) * 100.0}, Vector2.DOWN, m)["lado"], -1.0, "relativo ao olhar")


func test_traduz_os_outros_gestos() -> void:
	var m: Dictionary = cfg["mapa"]
	igual(C.traduzir({"gesto": "toque"}, Vector2.RIGHT, m)["acao"], "travar", "toque = travar mira")
	igual(C.traduzir({"gesto": "toque_duplo"}, Vector2.RIGHT, m)["acao"], "pular", "toque duplo")
	igual(C.traduzir({"gesto": "segurar_inicio", "na_criatura": false}, Vector2.RIGHT, m)["acao"], "defender", "segurar")
	igual(C.traduzir({"gesto": "segurar_inicio", "na_criatura": true}, Vector2.RIGHT, m)["acao"], "escavar", "segurar nela")
	igual(C.traduzir({"gesto": "trajetoria"}, Vector2.RIGHT, m)["acao"], "mover", "trajetória")
	igual(C.traduzir({"gesto": "nada"}, Vector2.RIGHT, m), {}, "nada")
