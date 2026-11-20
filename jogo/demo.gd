extends Node
## DEMO roteirizada (`-- --demo`, usada pelo oráculo): sintetiza DEDOS — não
## comandos — e os entrega pelo MESMO caminho de um toque de verdade
## (main.dedo_desceu/moveu/subiu → sim/gestos → sim/comandos → sim/corpo).
## Se a tabela de gestos mudar, a demo continua testando o sistema real.
##
## Cada passo: {t (s), tipo, ...}. Posições-alvo em CÉLULAS do mapa; direções
## de deslize em graus RELATIVOS ao olhar da criatura no momento.

const Mock := preload("res://jogo/mock.gd")

var main: Node
var _passos: Array = []
var _curso: Array = []  # dedos em curso: {t0, t1, de, ate, pts}


func _init(m: Node) -> void:
	main = m
	_passos = [
		{"t": 0.5, "tipo": "trajetoria", "ate": [[12, 10], [19, 11]], "dur": 0.7},
		{"t": 5.0, "tipo": "deslize", "rel": -45.0},
		{"t": 5.9, "tipo": "deslize", "rel": 45.0},
		{"t": 6.9, "tipo": "deslize", "rel": 0.0},
		{"t": 8.0, "tipo": "toque_duplo", "alvo": [23, 11]},
		{"t": 9.4, "tipo": "segurar", "longe": true, "dur": 1.1},
		{"t": 11.0, "tipo": "deslize", "rel": 180.0},
		{"t": 11.9, "tipo": "trajetoria", "ate": [[25, 12], [28, 14]], "dur": 0.6},
		{"t": 14.6, "tipo": "segurar", "longe": false, "dur": 0.6},
		{"t": 16.0, "tipo": "trajetoria", "ate": [[28, 17], [7, 17]], "dur": 0.8},
		{"t": 24.8, "tipo": "segurar", "longe": false, "dur": 0.6},
		{"t": 26.2, "tipo": "trajetoria", "ate": [[10, 16], [13, 15]], "dur": 0.6},
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


func _disparar(p: Dictionary, agora: float) -> void:
	var cria: Vector2 = main.tela_de(main.criatura.ponto_visual() + Vector2(0, -20))
	var olhar: Vector2 = main.corpo.olhar
	match p["tipo"]:
		"trajetoria":
			var pts := PackedVector2Array([cria])
			for c in p["ate"]:
				pts.append(main.tela_de(main.mundo.centro(Vector2i(c[0], c[1]))))
			_curso.append({"t0": agora, "t1": agora + float(p["dur"]), "pts": pts})
		"deslize":
			var v := olhar.rotated(deg_to_rad(float(p["rel"]))) * 140.0
			var de := cria + Vector2(-60, 140)  # longe da criatura: deslize vale de qualquer lugar
			_curso.append({"t0": agora, "t1": agora + 0.15, "pts": PackedVector2Array([de, de + v])})
		"toque_duplo":
			var alvo: Vector2 = main.tela_de(main.mundo.centro(Vector2i(p["alvo"][0], p["alvo"][1])))
			_curso.append({"t0": agora, "t1": agora + 0.08, "pts": PackedVector2Array([alvo, alvo])})
			_curso.append({"t0": agora + 0.16, "t1": agora + 0.24, "pts": PackedVector2Array([alvo, alvo])})
		"segurar":
			var ponto: Vector2 = cria + (Vector2(0, 160) if p["longe"] else Vector2(4, 6))
			_curso.append({"t0": agora, "t1": agora + float(p["dur"]), "pts": PackedVector2Array([ponto, ponto])})


## Ponto do dedo na fração u do traço (polilinha em tela).
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
