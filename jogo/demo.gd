extends Node
## DEMO roteirizada (`-- --demo`, usada pelo oráculo): sintetiza DEDOS — não
## comandos — e os entrega pelo MESMO caminho de um toque de verdade
## (main.dedo_* → sim/gestos → sim/comandos → sim/corpo).
##
## Roteiro da v0.8 (MULTITOUCH):
## 1. caminho com UM dedo: a criatura anda AO VIVO atrás do traço, a tela
##    escurece e o mundo desacelera enquanto o dedo desenha;
## 2. ataque = DOIS dedos: o dedo extra desliza para cima e a criatura NÃO anda;
## 3. especial = DOIS dedos abrindo para fora;
## 4. defesa = DOIS dedos: o extra desliza para baixo e fica (sustentada);
## 5. toque duplo = pulo; toque na árvore trava a mira; ataque vai no alvo;
## 6. ataque DURANTE o desenho: o segundo dedo sobe enquanto o primeiro desenha.
##
## O tempo é o `main.tempo_ms` (real); o tempo lento muda o MUNDO, não o roteiro.

var main: Node
var _passos: Array = []
var _curso: Array = []


func _init(m: Node) -> void:
	main = m
	_passos = [
		{"t": 0.4, "tipo": "caminho", "ate": [[10, 13], [14, 13]], "dur": 1.2},
		{"t": 2.2, "tipo": "ataque"},
		{"t": 3.4, "tipo": "especial"},
		{"t": 4.6, "tipo": "defesa"},
		{"t": 6.4, "tipo": "toque_duplo"},                       # pulo
		{"t": 7.4, "tipo": "toque", "celula": [15, 13]},         # trava mira na árvore
		{"t": 8.2, "tipo": "ataque"},                           # ataque na direção do alvo
		{"t": 9.4, "tipo": "caminho", "ate": [[12, 10], [14, 10]], "dur": 1.8},
		{"t": 10.0, "tipo": "ataque_extra"},                    # ataque DURANTE o desenho
		{"t": 11.8, "tipo": "toque", "celula": [16, 9]},         # trava no adversário
	]


func _process(_delta: float) -> void:
	var agora: float = main.tempo_ms / 1000.0
	while not _passos.is_empty() and agora >= float(_passos[0]["t"]):
		_disparar(_passos.pop_front(), agora)
	for d in _curso.duplicate():
		if agora < float(d["t0"]):
			continue
		var u := clampf((agora - float(d["t0"])) / maxf(float(d["t1"]) - float(d["t0"]), 0.001), 0.0, 1.0)
		for t in d["trilhas"]:
			var dedo: int = t["dedo"]
			if not d["desceu"].has(dedo):
				d["desceu"][dedo] = true
				main.dedo_desceu(dedo, t["pts"][0])
			main.dedo_moveu(dedo, _em(t["pts"], u))
		if u >= 1.0 and agora >= float(d["t1"]) + float(d.get("hold", 0.0)):
			for t in d["trilhas"]:
				main.dedo_subiu(t["dedo"], _em(t["pts"], 1.0))
			_curso.erase(d)


func _disparar(p: Dictionary, agora: float) -> void:
	print("demo: %.1f s · %s" % [agora, p["tipo"]])
	var tela: Vector2 = main.get_viewport_rect().size
	var centro := Vector2(tela.x * 0.5, tela.y * 0.72)
	match p["tipo"]:
		"caminho":
			var ancora := Vector2(tela.x * 0.18, tela.y * 0.80)
			var cria: Vector2 = main.tela_de(main.corpo.pos)
			# o GANHO de sensibilidade amplia o traço: para o roteiro cobrir as
			# mesmas células, o dedo anda a menos (divide pelo ganho)
			var ganho := maxf(float(main.cfg_gestos.get("desenho", {}).get("ganho", 1.0)), 0.01)
			var pts := PackedVector2Array([ancora])
			for c in p["ate"]:
				var alvo: Vector2 = main.tela_de(main.mundo.centro(Vector2i(c[0], c[1])))
				pts.append(ancora + (alvo - cria) / ganho)
			_curso.append({"t0": agora, "t1": agora + float(p.get("dur", 1.2)), "hold": 0.0,
				"trilhas": [{"dedo": 0, "pts": pts}], "desceu": {}})
		"ataque":
			# dois dedos: o primeiro fica parado, o EXTRA sobe
			_curso.append({"t0": agora, "t1": agora + 0.18, "hold": 0.0, "desceu": {}, "trilhas": [
				{"dedo": 0, "pts": PackedVector2Array([centro])},
				{"dedo": 1, "pts": PackedVector2Array([centro + Vector2(0, 120), centro + Vector2(0, 10)])},
			]})
		"ataque_extra":
			# só o dedo EXTRA: o primeiro já está desenhando o caminho
			_curso.append({"t0": agora, "t1": agora + 0.18, "hold": 0.0, "desceu": {}, "trilhas": [
				{"dedo": 1, "pts": PackedVector2Array([centro + Vector2(0, 120), centro + Vector2(0, 10)])},
			]})
		"especial":
			# dois dedos abrindo para fora (o extra afasta-se do primeiro)
			_curso.append({"t0": agora, "t1": agora + 0.30, "hold": 0.0, "desceu": {}, "trilhas": [
				{"dedo": 0, "pts": PackedVector2Array([centro])},
				{"dedo": 1, "pts": PackedVector2Array([centro + Vector2(0, 90), centro + Vector2(90, 160)])},
			]})
		"defesa":
			# dois dedos: o extra desliza para baixo e FICA (sustentada)
			_curso.append({"t0": agora, "t1": agora + 0.30, "hold": 1.2, "desceu": {}, "trilhas": [
				{"dedo": 0, "pts": PackedVector2Array([centro + Vector2(0, -60)])},
				{"dedo": 1, "pts": PackedVector2Array([centro + Vector2(0, -180), centro + Vector2(0, -80)])},
			]})
		"toque_duplo":
			var alvo := Vector2(tela.x * 0.5, tela.y * 0.86)
			_curso.append({"t0": agora, "t1": agora + 0.10, "hold": 0.0, "desceu": {},
				"trilhas": [{"dedo": 0, "pts": PackedVector2Array([alvo, alvo])}]})
			_curso.append({"t0": agora + 0.26, "t1": agora + 0.36, "hold": 0.0, "desceu": {},
				"trilhas": [{"dedo": 0, "pts": PackedVector2Array([alvo, alvo])}]})
		"toque":
			var c: Array = p["celula"]
			var ponto: Vector2 = main.tela_de(main.mundo.centro(Vector2i(c[0], c[1])))
			_curso.append({"t0": agora, "t1": agora + 0.10, "hold": 0.0, "desceu": {},
				"trilhas": [{"dedo": 0, "pts": PackedVector2Array([ponto, ponto])}]})


func _em(pts: PackedVector2Array, u: float) -> Vector2:
	if pts.size() == 1:
		return pts[0]
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i - 1].distance_to(pts[i])
	var alvo := total * clampf(u, 0.0, 1.0)
	for i in range(1, pts.size()):
		var seg := pts[i - 1].distance_to(pts[i])
		if alvo <= seg or i == pts.size() - 1:
			return pts[i - 1].lerp(pts[i], clampf(alvo / maxf(seg, 0.001), 0.0, 1.0))
		alvo -= seg
	return pts[pts.size() - 1]
