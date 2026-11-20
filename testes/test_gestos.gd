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
	igual(_nomes(_gesto(r, Vector2(905, 302), Vector2(905, 302), 250, 80)), ["toque", "toque_duplo"], "2º toque perto e logo")
	igual(_nomes(_gesto(r, Vector2(905, 302), Vector2(905, 302), 420, 80)), ["toque"], "3º não vira outro duplo")


func test_toque_duplo_longe_ou_tarde_nao() -> void:
	var r := _r()
	_gesto(r, Vector2(100, 100), Vector2(100, 100), 0, 80)
	igual(_nomes(_gesto(r, Vector2(400, 100), Vector2(400, 100), 200, 80)), ["toque"], "longe")
	igual(_nomes(_gesto(r, Vector2(400, 100), Vector2(400, 100), 1200, 80)), ["toque"], "tarde")


func test_segurar_inicio_e_fim() -> void:
	var r := _r()
	r.iniciar(Vector2(300, 300), 0, CRIA)
	igual(r.tick(200), [], "ainda não")
	var ev: Array = r.tick(400)
	igual(_nomes(ev), ["segurar_inicio"], "segurou")
	checar(not ev[0]["na_criatura"], "longe da criatura")
	igual(r.tick(600), [], "não repete")
	igual(_nomes(r.soltar(Vector2(302, 300), 900)), ["segurar_fim"], "soltou")


func test_segurar_na_criatura() -> void:
	var r := _r()
	r.iniciar(CRIA + Vector2(10, 5), 0, CRIA)
	var ev: Array = r.tick(500)
	checar(ev[0]["na_criatura"], "começou na criatura")


func test_deslize_rapido_de_qualquer_lugar() -> void:
	var ev := _gesto(_r(), Vector2(200, 600), Vector2(320, 560), 0, 150)
	igual(_nomes(ev), ["deslize"], "rápido e longo")


func test_trajetoria_comeca_na_criatura_e_e_lenta() -> void:
	var ev := _gesto(_r(), CRIA + Vector2(20, 0), CRIA + Vector2(300, 80), 0, 900, 12)
	igual(_nomes(ev), ["trajetoria"], "lenta, da criatura")
	ev = _gesto(_r(), Vector2(100, 650), Vector2(400, 650), 0, 900, 12)
	igual(_nomes(ev), ["nada"], "lenta, longe da criatura = não reconhecido")


func test_angulo_relativo() -> void:
	perto(C.angulo_relativo(Vector2.RIGHT, Vector2.RIGHT), 0.0, 0.01, "frente")
	perto(C.angulo_relativo(Vector2.DOWN, Vector2.RIGHT), 90.0, 0.01, "olhando leste, sul é a DIREITA dela")
	perto(C.angulo_relativo(Vector2.UP, Vector2.RIGHT), -90.0, 0.01, "norte é a esquerda")
	perto(absf(C.angulo_relativo(Vector2.LEFT, Vector2.RIGHT)), 180.0, 0.01, "trás")
	perto(C.angulo_relativo(Vector2.RIGHT, Vector2.UP), 90.0, 0.01, "olhando norte, leste é a direita")


func test_deslize_vira_acao_pelo_setor() -> void:
	var m: Dictionary = cfg["mapa"]
	var olhar := Vector2.RIGHT
	var casos := {Vector2(1, -1): "ataque_x", Vector2(1, 1): "ataque_y", Vector2(1, 0): "investida",
		Vector2(-1, 0): "esquiva", Vector2(-1, 0.3): "esquiva"}
	for v in casos:
		var cmd := C.traduzir({"gesto": "deslize", "vetor": v * 100.0}, olhar, m)
		igual(cmd.get("acao", ""), casos[v], "deslize %s olhando leste" % v)
	# relativo ao olhar: olhando para o SUL, frente-esquerda é sudeste
	igual(C.traduzir({"gesto": "deslize", "vetor": Vector2(1, 1) * 100.0}, Vector2.DOWN, m)["acao"], "ataque_x", "olhando sul")


func test_traduz_os_outros_gestos() -> void:
	var m: Dictionary = cfg["mapa"]
	igual(C.traduzir({"gesto": "toque_duplo"}, Vector2.RIGHT, m)["acao"], "pular", "toque duplo")
	igual(C.traduzir({"gesto": "segurar_inicio", "na_criatura": false}, Vector2.RIGHT, m)["acao"], "defender", "segurar")
	igual(C.traduzir({"gesto": "segurar_inicio", "na_criatura": true}, Vector2.RIGHT, m)["acao"], "escavar", "segurar na criatura")
	igual(C.traduzir({"gesto": "segurar_fim"}, Vector2.RIGHT, m)["acao"], "soltar", "soltar")
	igual(C.traduzir({"gesto": "trajetoria"}, Vector2.RIGHT, m)["acao"], "mover", "trajetória")
	igual(C.traduzir({"gesto": "nada"}, Vector2.RIGHT, m), {}, "nada")
