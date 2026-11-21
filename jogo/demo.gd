extends Node
## DEMO roteirizada (`-- --demo`, usada pelo oráculo): sintetiza DEDOS — não
## comandos — e os entrega pelo MESMO caminho de um toque de verdade
## (main.dedo_* → sim/gestos → sim/comandos → sim/corpo).
##
## Roteiro (v0.10; v0.11.4/v0.11.5 ajustaram as regras):
## 1. caminho com LAÇO perto: o laço é ANDADO como caminho (v0.11.5 desligou a
##    ONDA em área — o roteiro ficou igual para os quadros compararem);
## 2. caminho até a AREIA e SEGURAR parado: habilidade (cavar) — e de novo para
##    subir;
## 3. TOQUE DUPLO = PULO;
## 4. caminho por CIMA do adversário e terminando nele: travessia (BATIDA/
##    embalo) e a MARCA do alvo no fim do caminho;
## 5. TOQUE simples = TIRO mirado no alvo marcado (com 1 s de recarga);
## 6. o caminho acaba e a criatura PERSEGUE o alvo marcado e bate (golpe).
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
		{"t": 3.2, "tipo": "caminho", "cel": [2, 12], "dur": 0.8},
		{"t": 6.0, "tipo": "segurar"},
		{"t": 7.8, "tipo": "segurar"},
		{"t": 9.4, "tipo": "toque_duplo"},
		{"t": 10.4, "tipo": "perto", "passa": true, "dur": 2.6},
		{"t": 14.0, "tipo": "toque"},
		{"t": 15.4, "tipo": "toque"},
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
		"toque":
			# toque SIMPLES = pulo (o simples fica pendente até a janela do duplo)
			var p1 := Vector2(tela.x * 0.5, tela.y * 0.86)
			_curso.append({"t0": agora, "t1": agora + 0.08, "hold": 0.0, "desceu": {},
				"trilhas": [{"dedo": 0, "pts": PackedVector2Array([p1, p1])}]})
		"toque_duplo":
			# dois toques = TIRO no alvo marcado
			var alvo := Vector2(tela.x * 0.5, tela.y * 0.86)
			_curso.append({"t0": agora, "t1": agora + 0.08, "hold": 0.0, "desceu": {},
				"trilhas": [{"dedo": 0, "pts": PackedVector2Array([alvo, alvo])}]})
			_curso.append({"t0": agora + 0.18, "t1": agora + 0.26, "hold": 0.0, "desceu": {},
				"trilhas": [{"dedo": 0, "pts": PackedVector2Array([alvo, alvo])}]})
		"perto":
			# em cima do ADVERSÁRIO: passa por cima (batida) ou termina nele (golpe final)
			var adv := Vector2(main.adversarios[0].pos)
			var cria := Vector2(main.corpo.pos)
			var dir := (adv - cria)
			if dir.length() < 1.0:
				dir = Vector2.RIGHT
			dir = dir.normalized()
			# caminho em "L" (na horizontal e depois na vertical): desvia do
			# planalto no meio da arena, que a criatura não sobe andando.
			var d := adv - cria
			var rel: Array = [[0, 0]]
			if p.get("passa", false):
				rel.append([d.x, 0.0])
				rel.append([d.x, d.y - 10.0])
				rel.append([d.x + 40.0, d.y - 10.0])
			else:
				rel.append([d.x, 0.0])
				rel.append([d.x, d.y])
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
