extends Node
## DEMO roteirizada (`-- --demo`, usada pelo oráculo): sintetiza DEDOS — não
## comandos — e os entrega pelo MESMO caminho de um toque de verdade
## (main.dedo_* → sim/gestos → sim/comandos → sim/corpo).
##
## O roteiro mostra as regras da v0.5:
## 1. rota riscada a partir dela;
## 2. ataque, esquiva e pulo DURANTE a caminhada — sem cancelar a rota;
## 3. toque na árvore trava a mira; novo ataque sai na direção do alvo;
## 4. toque no adversário trava num alvo MÓVEL;
## 5. segurar = defesa (para a rota); soltar retoma;
## 6. ao terminar a rota, autonomia (vai/ronda o alvo marcado).

const Mock := preload("res://jogo/mock.gd")

var main: Node
var _passos: Array = []
var _curso: Array = []


func _init(m: Node) -> void:
	main = m
	_passos = [
		{"t": 0.5, "tipo": "rota", "ate": [[9, 11], [18, 12]], "dur": 0.9},
		{"t": 2.4, "tipo": "longe", "rel": 0.0},          # ataque (andando)
		{"t": 3.6, "tipo": "longe", "rel": -90.0},        # esquiva à esquerda
		{"t": 4.6, "tipo": "longe", "rel": 90.0},         # esquiva à direita
		{"t": 5.6, "tipo": "toque_duplo"},                # pulo (arco andando)
		{"t": 7.0, "tipo": "toque", "celula": [12, 13]},  # trava mira na árvore
		{"t": 8.0, "tipo": "longe", "rel": 0.0},          # ataque na direção do alvo
		{"t": 9.4, "tipo": "toque", "celula": [16, 9]},   # trava no adversário (móvel)
		{"t": 10.6, "tipo": "defender", "dur": 1.6},      # defesa: para a rota
		{"t": 12.8, "tipo": "longe", "rel": 0.0},         # ataque na direção do alvo
		{"t": 14.0, "tipo": "rota", "ate": [[19, 13]], "dur": 0.5},  # rota curta: acaba
		{"t": 17.0, "tipo": "toque", "celula": [13, 14]}, # interage com o baú
	]


func _process(_delta: float) -> void:
	var agora: float = main.tempo_ms / 1000.0
	while not _passos.is_empty() and agora >= float(_passos[0]["t"]):
		_disparar(_passos.pop_front(), agora)
	for d in _curso.duplicate():
		if agora < float(d["t0"]):
			continue
		if not d.get("desceu", false):
			d["desceu"] = true
			main.dedo_desceu(_em(d, 0.0))
			continue
		var u := clampf((agora - float(d["t0"])) / maxf(float(d["t1"]) - float(d["t0"]), 0.001), 0.0, 1.0)
		if u >= 1.0:
			main.dedo_subiu(_em(d, 1.0))
			_curso.erase(d)
		else:
			main.dedo_moveu(_em(d, u))


func _cria() -> Vector2:
	return main.tela_de(main.criatura.ponto_visual() + Vector2(0, -20))


func _disparar(p: Dictionary, agora: float) -> void:
	var cria := _cria()
	var olhar: Vector2 = main.corpo.olhar
	match p["tipo"]:
		"rota":
			var pts := PackedVector2Array([cria])
			for c in p["ate"]:
				pts.append(main.tela_de(main.mundo.centro(Vector2i(c[0], c[1]))))
			_curso.append({"t0": agora, "t1": agora + float(p["dur"]), "pts": pts})
		"longe":
			# dedo LONGE dela: é gesto de ação, na direção relativa ao olhar
			var v := olhar.rotated(deg_to_rad(float(p["rel"]))) * 150.0
			var de := cria + Vector2(0, 230)
			if de.distance_to(cria) < 130.0:
				de = cria + Vector2(0, -230)
			_curso.append({"t0": agora, "t1": agora + 0.16, "pts": PackedVector2Array([de, de + v])})
		"toque_duplo":
			var alvo := cria + Vector2(0, 240)
			if alvo.y > 660.0:
				alvo = cria + Vector2(0, -240)
			_curso.append({"t0": agora, "t1": agora + 0.14, "pts": PackedVector2Array([alvo, alvo])})
			_curso.append({"t0": agora + 0.26, "t1": agora + 0.40, "pts": PackedVector2Array([alvo, alvo])})
		"toque":
			var c: Array = p["celula"]
			var ponto: Vector2 = main.tela_de(main.mundo.centro(Vector2i(c[0], c[1])))
			_curso.append({"t0": agora, "t1": agora + 0.10, "pts": PackedVector2Array([ponto, ponto])})
		"defender":
			var ponto := cria + Vector2(0, 200)
			if ponto.y > 690.0:
				ponto = cria + Vector2(0, -200)
			_curso.append({"t0": agora, "t1": agora + float(p["dur"]), "pts": PackedVector2Array([ponto, ponto])})


func _em(d: Dictionary, u: float) -> Vector2:
	var pts: PackedVector2Array = d["pts"]
	if pts.size() == 1:
		return pts[0]
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i - 1].distance_to(pts[i])
	var alvo := total * u
	for i in range(1, pts.size()):
		var seg := pts[i - 1].distance_to(pts[i])
		if alvo <= seg or i == pts.size() - 1:
			return pts[i - 1].lerp(pts[i], clampf(alvo / maxf(seg, 0.001), 0.0, 1.0))
		alvo -= seg
	return pts[pts.size() - 1]
