extends Node
## DEMO roteirizada (`-- --demo`, usada pelo oráculo): sintetiza DEDOS — não
## comandos — e os entrega pelo MESMO caminho de um toque de verdade
## (main.dedo_* → sim/gestos → sim/comandos → sim/corpo).
##
## Roteiro da v0.9 — o ataque nasce da FORMA do desenho:
## 1. caminho com LAÇO: a criatura anda atrás do traço e, ao entrar no ANEL
##    (a circunferência) do laço, a ONDA em área cresce do centro dele;
## 2. caminho com BICO em "T" (sai da estrada e volta): o beco NÃO é andado —
##    a criatura para na base e dispara o TIRO na direção da ponta;
## 3. caminho até a AREIA e SEGURAR parado: habilidade (cavar) — e de novo para
##    subir;
## 4. toque duplo = pulo;
## 5. caminho por CIMA do adversário: travessia → BATIDA/empurrão;
## 6. caminho que TERMINA EM CIMA dele: alvo final e GOLPE físico na chegada.
##
## O tempo é o `main.tempo_ms` (real); o tempo lento muda o MUNDO, não o roteiro.
## Os caminhos são em px de MUNDO, relativos à criatura no instante da descida.

var main: Node
var _passos: Array = []
var _curso: Array = []


func _init(m: Node) -> void:
	main = m
	_passos = [
		{"t": 0.5, "tipo": "caminho", "rel": [[0, 0], [70, 0], [70, -50], [20, -50], [20, 15]], "dur": 1.4},
		{"t": 4.4, "tipo": "caminho", "rel": [[0, 0], [70, 0], [70, -60], [70, 0], [150, 0]], "dur": 1.0},
		{"t": 5.8, "tipo": "caminho", "cel": [2, 12], "dur": 0.8},
		{"t": 8.2, "tipo": "segurar"},
		{"t": 10.0, "tipo": "segurar"},
		{"t": 11.6, "tipo": "toque_duplo"},
		{"t": 12.6, "tipo": "perto", "passa": true, "dur": 2.0},
		{"t": 15.6, "tipo": "perto", "fim": true, "dur": 0.7},
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
	match p["tipo"]:
		"caminho":
			_curso.append({"t0": agora, "t1": agora + float(p.get("dur", 1.2)), "hold": 0.0,
				"trilhas": [{"dedo": 0, "pts": _pontos(p)}], "desceu": {}})
		"segurar":
			# parado SEM arrastar: o gesto vira a habilidade em si mesmo
			var alvo := Vector2(tela.x * 0.5, tela.y * 0.9)
			_curso.append({"t0": agora, "t1": agora + 0.05, "hold": 0.5, "desceu": {},
				"trilhas": [{"dedo": 0, "pts": PackedVector2Array([alvo])}]})
		"toque_duplo":
			var alvo := Vector2(tela.x * 0.5, tela.y * 0.86)
			_curso.append({"t0": agora, "t1": agora + 0.08, "hold": 0.0, "desceu": {},
				"trilhas": [{"dedo": 0, "pts": PackedVector2Array([alvo, alvo])}]})
			_curso.append({"t0": agora + 0.25, "t1": agora + 0.33, "hold": 0.0, "desceu": {},
				"trilhas": [{"dedo": 0, "pts": PackedVector2Array([alvo, alvo])}]})
		"perto":
			# em cima do ADVERSÁRIO: passa por cima (batida) ou termina nele (golpe final)
			var adv := Vector2(main.adversarios[0].pos)
			var cria := Vector2(main.corpo.pos)
			var dir := (adv - cria)
			if dir.length() < 1.0:
				dir = Vector2.RIGHT
			dir = dir.normalized()
			var rel: Array = [[0, 0]]
			if p.get("passa", false):
				rel.append([(adv - cria - dir * 12.0).x, (adv - cria - dir * 12.0).y])
				rel.append([(adv - cria + dir * 34.0).x, (adv - cria + dir * 34.0).y])
			else:
				rel.append([(adv - cria).x, (adv - cria).y])
			_curso.append({"t0": agora, "t1": agora + float(p.get("dur", 1.0)), "hold": 0.0,
				"trilhas": [{"dedo": 0, "pts": _pontos({"rel": rel})}], "desceu": {}})


## Pontos de TELA do desenho: o traço é em MUNDO, a partir da criatura AGORA.
## Se `cel` existe, o último ponto é o centro daquela célula.
func _pontos(p: Dictionary) -> PackedVector2Array:
	var cria_w: Vector2 = main.corpo.pos
	var cria_t: Vector2 = main.tela_de(cria_w)
	var zoom: float = main.camera.zoom.x
	var ganho := maxf(float(main.cfg_gestos.get("desenho", {}).get("ganho", 1.0)), 0.01)
	var rel: Array = []
	if p.has("cel"):
		var c: Array = p["cel"]
		var alvo: Vector2 = main.mundo.centro(Vector2i(c[0], c[1]))
		rel.append([0.0, 0.0])
		rel.append([alvo.x - cria_w.x, alvo.y - cria_w.y])
	else:
		rel = p.get("rel", [])
	var pts := PackedVector2Array()
	for r in rel:
		pts.append(cria_t + Vector2(r[0], r[1]) * zoom / ganho)
	return pts


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
