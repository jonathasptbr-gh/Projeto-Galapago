extends Node
## DEMO roteirizada (`-- --demo`, usada pelo oráculo): sintetiza DEDOS — não
## comandos — e os entrega pelo MESMO caminho de um toque de verdade
## (main.dedo_* → sim/gestos → sim/comandos → sim/corpo).
##
## O roteiro da v0.6 mostra as regras novas:
## 1. SEGURAR parado numa âncora longe da criatura e ARRASTAR: o desenho
##    aparece transladado sobre a criatura (o dedo não tapa a visão) e o mundo
##    entra em tempo lento enquanto a âncora existe;
## 2. o caminho passa POR CIMA da árvore: a criatura desvia um pouco do objeto;
## 3. ataque (cima), especiais (lados) e esquiva (baixo) relativos à TELA;
## 4. toque duplo = pulo; toque na árvore trava a mira; ataque vai no alvo;
## 5. baixo + segurar = defesa (para a rota); soltar retoma;
## 6. segundo caminho curto depois da defesa.
##
## O tempo é o `main.tempo_ms` (real); o tempo lento muda o MUNDO, não o roteiro.

var main: Node
var _passos: Array = []
var _curso: Array = []


func _init(m: Node) -> void:
	main = m
	_passos = [
		{"t": 0.4, "tipo": "caminho", "ate": [[10, 13], [14, 13]], "hold": 0.55, "dur": 1.2},
		{"t": 2.6, "tipo": "deslize", "dir": [0, -1]},          # ataque físico
		{"t": 3.6, "tipo": "deslize", "dir": [-1, 0]},          # especial esquerda
		{"t": 4.9, "tipo": "deslize", "dir": [1, 0]},           # especial direita (fora da recarga)
		{"t": 6.0, "tipo": "deslize", "dir": [0, 1]},           # esquiva para trás
		{"t": 7.0, "tipo": "toque_duplo"},                      # pulo
		{"t": 8.2, "tipo": "toque", "celula": [15, 13]},        # trava mira na árvore
		{"t": 9.2, "tipo": "deslize", "dir": [0, -1]},          # ataque na direção do alvo
		{"t": 10.6, "tipo": "defender"},                        # baixo + segurar
		{"t": 12.4, "tipo": "deslize", "dir": [0, -1]},         # ataque
		{"t": 13.6, "tipo": "caminho", "ate": [[16, 12], [17, 12]], "hold": 0.55, "dur": 0.8},
		{"t": 15.8, "tipo": "toque", "celula": [16, 9]},        # trava no adversário
	]


func _process(_delta: float) -> void:
	var agora: float = main.tempo_ms / 1000.0
	while not _passos.is_empty() and agora >= float(_passos[0]["t"]):
		_disparar(_passos.pop_front(), agora)
	for d in _curso.duplicate():
		if agora < float(d["t0"]):
			continue
		if d.get("tipo", "") == "caminho":
			var u := agora - float(d["t0"])
			var hold := float(d["hold"])
			if u < hold:
				if not d.get("desceu", false):
					d["desceu"] = true
					main.dedo_desceu(d["ancora"])
				continue
			if u < hold + float(d["dur"]):
				if not d.get("desceu", false):
					d["desceu"] = true
					main.dedo_desceu(d["ancora"])
				main.dedo_moveu(_em(d, (u - hold) / float(d["dur"])))
				continue
			main.dedo_subiu(_em(d, 1.0))
			_curso.erase(d)
			continue
		var u := clampf((agora - float(d["t0"])) / maxf(float(d["t1"]) - float(d["t0"]), 0.001), 0.0, 1.0)
		if not d.get("desceu", false):
			d["desceu"] = true
			main.dedo_desceu(_em(d, 0.0))
		if u >= 1.0:
			var hold := float(d.get("hold", 0.0))
			if agora < float(d["t1"]) + hold:
				main.dedo_moveu(_em(d, 1.0))
			else:
				main.dedo_subiu(_em(d, 1.0))
				_curso.erase(d)
		else:
			main.dedo_moveu(_em(d, u))


func _disparar(p: Dictionary, agora: float) -> void:
	print("demo: %.1f s · %s" % [agora, p["tipo"]])
	var tela: Vector2 = main.get_viewport_rect().size
	match p["tipo"]:
		"caminho":
			var ancora := Vector2(tela.x * float(p.get("ax", 0.18)), tela.y * float(p.get("ay", 0.80)))
			var cria: Vector2 = main.tela_de(main.corpo.pos)
			var pts := PackedVector2Array([ancora])
			for c in p["ate"]:
				var alvo: Vector2 = main.tela_de(main.mundo.centro(Vector2i(c[0], c[1])))
				pts.append(ancora + (alvo - cria))
			_curso.append({"tipo": "caminho", "t0": agora, "hold": float(p.get("hold", 0.55)),
				"dur": float(p.get("dur", 1.2)), "pts": pts, "ancora": ancora, "desceu": false})
		"deslize":
			var de := Vector2(tela.x * 0.5, tela.y * 0.70)
			var v := Vector2(float(p["dir"][0]), float(p["dir"][1])) * 150.0
			_curso.append({"t0": agora, "t1": agora + 0.16, "pts": PackedVector2Array([de, de + v])})
		"toque_duplo":
			var alvo := Vector2(tela.x * 0.5, tela.y * 0.86)
			_curso.append({"t0": agora, "t1": agora + 0.14, "pts": PackedVector2Array([alvo, alvo])})
			_curso.append({"t0": agora + 0.26, "t1": agora + 0.40, "pts": PackedVector2Array([alvo, alvo])})
		"toque":
			var c: Array = p["celula"]
			var ponto: Vector2 = main.tela_de(main.mundo.centro(Vector2i(c[0], c[1])))
			_curso.append({"t0": agora, "t1": agora + 0.10, "pts": PackedVector2Array([ponto, ponto])})
		"defender":
			var de := Vector2(tela.x * 0.5, tela.y * 0.55)
			var ate := de + Vector2(0, tela.y * 0.12)
			_curso.append({"t0": agora, "t1": agora + 0.12, "pts": PackedVector2Array([de, ate]), "hold": 1.4})


func _em(d: Dictionary, u: float) -> Vector2:
	var pts: PackedVector2Array = d["pts"]
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
