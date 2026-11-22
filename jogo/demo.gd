extends Node
## DEMO roteirizada (`-- --demo`, usada pelo oráculo): sintetiza DEDOS — não
## comandos — e os entrega pelo MESMO caminho de um toque de verdade
## (main.dedo_* → sim/gestos → sim/comandos → sim/corpo).
##
## Roteiro (v0.17; a regra nova é do corpo, aqui só se encena o dedo):
## 0. o caminho de sempre (baseline de 60 quadros do CI — NÃO MUDAR);
## 1. PAUSA + SEGURAR: caminho curto e, ~0,1 s depois de soltar, o dedo desce e
##    segura: a pausa de saída ainda vale, o segurar (200 ms) CANCELA a
##    caminhada, carrega e solta atirando no destino final do caminho;
## 2. PAUSA + TOQUE: outro caminho e um toque curto — ele pula a pausa e sai
##    correndo (arrancada);
## 3. TIRO NO ALVO MARCADO: o caminho termina EM CIMA do adversário (marca o
##    alvo); o segurar na pausa carrega e solta no inimigo marcado;
## 4. TOQUE DUPLO = PULO;
## 5. PERSEGUIÇÃO/GOLPE FINAL: caminho terminando no inimigo e SEM segurar — a
##    criatura anda, persegue e bate;
## 6. SEGURAR SEM CAMINHO = HABILIDADE (cavar), numa célula escavável.
##
## O tempo é o `main.tempo_ms` (real); o tempo lento muda o MUNDO, não o roteiro.
## Os caminhos são em px de MUNDO, relativos à criatura no instante da descida.
## Entre soltar um dedo e descer o próximo há sempre ≥ 0,1 s (dois dedos não
## são um toque).

var main: Node
var _passos: Array = []
var _curso: Array = []
# CAVAR (cena 6): o caminho até a célula escavável só é riscado quando a
# perseguição/golpe anterior terminou (o inimigo anda, então a chegada varia);
# depois o dedo desce quando a criatura PARA em cima da célula.
# "" = nada · "livre" = esperando o corpo ficar livre · "chegada" = esperando
# a caminhada até a célula acabar.
var _cavar := ""
var _cavar_limite := 0.0


func _init(m: Node) -> void:
	main = m
	_passos = [
		# 0. baseline do CI (NÃO MUDAR): o caminho de sempre nos 2 primeiros segundos
		{"t": 0.5, "tipo": "caminho", "rel": [[0, 0], [70, 0], [70, -50], [20, -50], [20, 15]], "dur": 1.4},
		# 1. caminho curto e, 0,1 s depois de soltar, o dedo desce e SEGURA
		{"t": 2.2, "tipo": "caminho", "rel": [[0, 0], [90, 0], [90, -40]], "dur": 0.6},
		{"t": 2.9, "tipo": "segurar", "hold": 1.0},
		# 2. outro caminho curto e um TOQUE, 0,1 s depois de soltar
		{"t": 4.1, "tipo": "caminho", "rel": [[0, 0], [80, 0]], "dur": 0.6},
		{"t": 4.8, "tipo": "toque"},
		# 3. caminho até EM CIMA do adversário e SEGURAR na pausa (tiro no alvo)
		{"t": 5.6, "tipo": "perto", "dur": 1.2},
		{"t": 6.9, "tipo": "segurar", "hold": 1.1},
		# 4. dois toques = PULO
		{"t": 8.3, "tipo": "toque_duplo"},
		# 5. caminho terminando no inimigo e SEM segurar = perseguição/golpe
		{"t": 8.9, "tipo": "perto", "dur": 1.2},
		# 6. segurar sem caminho/alvo = habilidade (cavar) — armado aqui, mas
		#    só sai quando o corpo estiver livre e parado numa célula escavável
		{"t": 9.2, "tipo": "cavar"},
	]
	# MODO HOSTIL (`-- --demo --hostil`, para o oráculo ver os ataques): coloca a
	# criatura perto do adversário, liga a hostilidade e fecha a cena com um
	# golpe ROTEIRIZADO — é o que faz ele se ESCONDER.
	if "--hostil" in OS.get_cmdline_user_args():
		_passos = [
			{"t": 0.2, "tipo": "hostil_on"},
			# golpe ROTEIRIZADO no inimigo: o oráculo precisa do estado
			# ESCONDIDO nos quadros (um caminho desenhado erraria o alvo móvel)
			{"t": 4.2, "tipo": "esconder_demo"},
		]
		if not main.adversarios.is_empty():
			main.corpo.pos = main.adversarios[0].pos + Vector2(-96, 0)
			main.camera.position = main.corpo.pos
			main.camera.reset_smoothing()


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
	# cena 6 (cavar): espera a perseguição/golpe acabar, risca o caminho até a
	# célula escavável mais perto e desce o dedo quando a criatura PARA nela.
	if _cavar != "" and agora >= _cavar_limite:
		_cavar = ""
	elif _cavar == "livre" and _curso.is_empty() and _livre():
		var cel := _celula_escavavel()
		if cel.x < 0:
			_cavar = ""
		else:
			_cavar = "chegada"
			_cavar_limite = agora + 6.0
			_disparar({"tipo": "caminho", "cel": [cel.x, cel.y], "dur": 0.5}, agora)
	elif _cavar == "chegada" and _curso.is_empty() and _parada():
		_cavar = ""
		_disparar({"tipo": "segurar", "hold": 0.7}, agora)


func _disparar(p: Dictionary, agora: float) -> void:
	print("demo: %.1f s · %s" % [agora, p["tipo"]])
	var tela: Vector2 = main.get_viewport_rect().size
	match p["tipo"]:
		"caminho":
			_curso.append({"t0": agora, "t1": agora + float(p.get("dur", 1.2)), "hold": 0.0,
				"trilhas": [{"dedo": 0, "pts": _pontos(p)}], "desceu": {}})
		"segurar":
			# parado SEM arrastar: no caminho/alvo = tiro carregado; sem eles, a
			# habilidade em si mesmo. Na pausa, o limiar é curto (200 ms).
			var alvo := Vector2(tela.x * 0.5, tela.y * 0.9)
			_curso.append({"t0": agora, "t1": agora + 0.05, "hold": float(p.get("hold", 0.5)),
				"desceu": {}, "trilhas": [{"dedo": 0, "pts": PackedVector2Array([alvo])}]})
		"toque":
			# toque CURTO: na pausa ele sai na hora e CORRE; fora dela fica
			# pendente até a janela do duplo fechar (e então corre)
			var p1 := Vector2(tela.x * 0.5, tela.y * 0.86)
			_curso.append({"t0": agora, "t1": agora + 0.08, "hold": 0.0, "desceu": {},
				"trilhas": [{"dedo": 0, "pts": PackedVector2Array([p1, p1])}]})
		"hostil_on":
			main.definir_hostilidade(true)
		"esconder_demo":
			if not main.adversarios.is_empty():
				main.adversarios[0].empurrar(Vector2.RIGHT, 30.0)
		"toque_duplo":
			# dois toques rápidos = PULO (a janela do duplo é de 280 ms)
			var alvo := Vector2(tela.x * 0.5, tela.y * 0.86)
			_curso.append({"t0": agora, "t1": agora + 0.08, "hold": 0.0, "desceu": {},
				"trilhas": [{"dedo": 0, "pts": PackedVector2Array([alvo, alvo])}]})
			_curso.append({"t0": agora + 0.2, "t1": agora + 0.28, "hold": 0.0, "desceu": {},
				"trilhas": [{"dedo": 0, "pts": PackedVector2Array([alvo, alvo])}]})
		"perto":
			# em cima do ADVERSÁRIO: passa por cima (batida) ou termina nele (marca
			# do alvo e golpe final). O "L" desvia do planalto no meio da arena.
			var adv := Vector2(main.adversarios[0].pos)
			var cria := Vector2(main.corpo.pos)
			var dir := (adv - cria)
			if dir.length() < 1.0:
				dir = Vector2.RIGHT
			dir = dir.normalized()
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
		"cavar":
			# cena 6: só ARMA; o caminho e o dedo saem no `_process`, quando a
			# perseguição/golpe anterior tiver acabado.
			_cavar = "livre"
			_cavar_limite = agora + 8.0


## O corpo terminou o caminho E a perseguição/golpe (a marca saiu e não há
## ataque em curso)? É a hora de riscar o caminho da cena do cavar.
func _livre() -> bool:
	return not main.corpo.em_rota() and not main.corpo.em_inercia() \
		and main.corpo.mira_final_id == "" and main.corpo.ataque == ""


## Está parada na superfície, sem rota/pausa/inércia: o dedo do cavar desce.
func _parada() -> bool:
	return main.corpo.camada == "superficie" and not main.corpo.em_rota() \
		and not main.corpo.em_inercia() and not main.corpo.em_atraso() \
		and not main.corpo.no_ar()


## A célula ESCAVÁVEL mais perto da criatura (cena do cavar). Varre 5 células
## em volta; (-1, -1) = não há nenhuma por perto.
func _celula_escavavel() -> Vector2i:
	var base: Vector2i = main.mundo.celula_de(main.corpo.pos)
	var melhor := Vector2i(-1, -1)
	var melhor_d := 1.0e9
	for dx in range(-5, 6):
		for dy in range(-5, 6):
			var q := base + Vector2i(dx, dy)
			if not main.mundo.pode_escavar(q, "superficie"):
				continue
			var d: float = main.corpo.pos.distance_to(main.mundo.centro(q))
			if d < melhor_d:
				melhor = q
				melhor_d = d
	return melhor


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
