extends Node
## DEMO roteirizada (`-- --demo`, usada pelo oráculo), no mapa NATUREZA (o
## único desde 2026-11-27): sintetiza DEDOS — não
## comandos — e os entrega pelo MESMO caminho de um toque de verdade
## (main.dedo_* → sim/gestos → sim/comandos → sim/corpo).
##
## Roteiro (v0.18; a regra nova é do corpo, aqui só se encena o dedo):
## 0. CAMINHO nos 2 primeiros segundos (baseline de 60 quadros do CI): é a cena
##    que mostra a RAMPA de aceleração do começo da caminhada (do corpo,
##    `rota.rampa_s`: ~15% → 100% em 0,30 s);
## 1. TOQUE = TIRO CARREGADO: um caminho curto e, 0,1 s depois de soltar, um
##    toque de 0,08 s — o animal PARA, a barra/anel de CARGA aparecem e o tiro
##    sai sozinho ~1 s depois (mais a janela pendente do toque, 280 ms);
## 2. SEGURAR = CORRER: um caminho em curso e, 0,1 s depois de soltar, o dedo
##    desce e SEGURA 0,8 s — sprint contínuo, energia caindo, HUD "CORRENDO";
##    ao soltar, a CAUDA (`sprint.cauda_s`) mantém o embalo;
## 3. TIRO NO ALVO MARCADO: o caminho termina EM CIMA do adversário (marca o
##    alvo vivo) e um TOQUE carrega e atira nele;
## 4. TOQUE DUPLO = PULO;
## 5. PERSEGUIÇÃO/GOLPE FINAL: caminho terminando no inimigo e SEM toque — a
##    criatura anda, persegue e bate;
## 6. SEGURAR SEM CAMINHO = HABILIDADE (cavar), numa célula escavável.
## P24 — GIRO DA CÂMERA (entre a cena 0 e a 1, em 2,0–2,5 s, para caber nos 90
## quadros do oráculo): um dedo DESCE na BARRA DE GIRO do topo e arrasta
## ~343 px para a direita (~120° de yaw), entregue como InputEventScreenTouch/
## Drag ao `main._input` — o MESMO caminho de um dedo de verdade. O caminho da
## cena 1 já é desenhado com a câmera girada.
##
## O tempo é o `main.tempo_ms` (real); o tempo lento muda o MUNDO, não o roteiro.
## Os caminhos são em px de MUNDO, relativos à criatura no instante da descida
## (convertidos para a tela pela base da afim da câmera 3D: giram com ela).
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
# GIRO (P24): o dedo da barra em curso ({} = nenhum). Índice próprio, longe
# dos dedos do roteiro (0, 1).
const DEDO_BARRA := 7
var _giro: Dictionary = {}


func _init(m: Node) -> void:
	main = m
	if "--camera-intermediaria" in OS.get_cmdline_user_args() or "--camera-intima" in OS.get_cmdline_user_args():
		main.dedo_desceu(0, Vector2(200, 500))
		main.dedo_desceu(1, Vector2(300, 500))
		var distancia := 200.0 if "--camera-intima" in OS.get_cmdline_user_args() else 150.0
		main.dedo_moveu(1, Vector2(200 + distancia, 500))
		main.dedo_subiu(1, Vector2(200 + distancia, 500))
		main.dedo_subiu(0, Vector2(200, 500))
		return
	_passos = [
		# 0. baseline do CI: o caminho de sempre nos 2 primeiros segundos, com a
		#    RAMPA de aceleração do começo da caminhada à vista
		{"t": 0.5, "tipo": "caminho", "rel": [[0, 0], [70, 0], [70, -50], [20, -50], [20, 15]], "dur": 1.4},
		# P24: GIRO pela barra do topo (~120°), com o mesmo toque de um dedo
		{"t": 2.0, "tipo": "girar", "dx": 120.0, "dur": 0.5},
		# 1. caminho curto e, 0,1 s depois de soltar, um TOQUE: começa a CARGA
		{"t": 2.6, "tipo": "caminho", "rel": [[0, 0], [90, 0], [90, -40]], "dur": 0.5},
		{"t": 3.2, "tipo": "toque"},
		# 2. caminho em curso e, 0,1 s depois de soltar, SEGURAR = CORRER
		{"t": 5.0, "tipo": "caminho", "rel": [[0, 0], [0, 120], [110, 120]], "dur": 0.5},
		{"t": 5.6, "tipo": "segurar", "hold": 0.8},
		# 3. caminho até EM CIMA do adversário (marca o alvo vivo) e um TOQUE
		{"t": 7.0, "tipo": "perto", "dur": 1.0},
		{"t": 8.1, "tipo": "toque"},
		# 4. dois toques = PULO
		{"t": 9.8, "tipo": "toque_duplo"},
		# 5. caminho terminando no inimigo e SEM toque = perseguição/golpe
		{"t": 10.9, "tipo": "perto", "dur": 1.1},
		# 6. segurar sem caminho = habilidade (cavar) — armado aqui, mas só sai
		#    quando o corpo estiver livre e parado numa célula escavável
		{"t": 11.0, "tipo": "cavar"},
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
			main.posicionar_camera()


func _process(_delta: float) -> void:
	var agora: float = main.tempo_ms / 1000.0
	while not _passos.is_empty() and agora >= float(_passos[0]["t"]):
		_disparar(_passos.pop_front(), agora)
	_girar(agora)
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
			# parado SEM arrastar: com caminho em curso = CORRER (sprint
			# contínuo); sem caminho = a habilidade em si mesmo. O segurar vale
			# no limiar (`segurar_min_ms`, 380 ms), não no soltar.
			var alvo := Vector2(tela.x * 0.5, tela.y * 0.9)
			_curso.append({"t0": agora, "t1": agora + 0.05, "hold": float(p.get("hold", 0.5)),
				"desceu": {}, "trilhas": [{"dedo": 0, "pts": PackedVector2Array([alvo])}]})
		"toque":
			# toque CURTO: fica pendente pela janela do duplo (280 ms) e então o
			# corpo começa a CARGA do tiro (1 s); o disparo sai sozinho.
			var p1 := Vector2(tela.x * 0.5, tela.y * 0.86)
			_curso.append({"t0": agora, "t1": agora + 0.08, "hold": 0.0, "desceu": {},
				"trilhas": [{"dedo": 0, "pts": PackedVector2Array([p1, p1])}]})
		"girar":
			# dedo na BARRA: desce no terço esquerdo e arrasta o equivalente a
			# `dx` graus de yaw (graus_por_px da câmera) em `dur` s
			var gpp: float = float(main.cam3d.cfg["giro"]["graus_por_px"])
			var y: float = main.ALTURA_BARRA * 0.5
			var x0: float = tela.x * 0.5 - float(p["dx"]) / gpp * 0.5
			_giro = {"t0": agora, "t1": agora + float(p.get("dur", 0.5)), "x0": x0,
				"x1": x0 + float(p["dx"]) / gpp, "y": y, "x": x0}
			main._input(_toque_barra(true, Vector2(x0, y)))
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
			# do alvo e golpe final). O caminho vai em "L".
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


## GIRO em curso: arrasta o dedo da barra e o solta no fim (eventos de toque,
## não chamada direta à câmera).
func _girar(agora: float) -> void:
	if _giro.is_empty():
		return
	var u := clampf((agora - float(_giro["t0"])) / maxf(float(_giro["t1"]) - float(_giro["t0"]), 0.001), 0.0, 1.0)
	var x := lerpf(float(_giro["x0"]), float(_giro["x1"]), u)
	var y := float(_giro["y"])
	if not is_equal_approx(x, float(_giro["x"])):
		var arrasto := InputEventScreenDrag.new()
		arrasto.index = DEDO_BARRA
		arrasto.position = Vector2(x, y)
		arrasto.relative = Vector2(x - float(_giro["x"]), 0.0)
		main._input(arrasto)
		_giro["x"] = x
	if u >= 1.0:
		main._input(_toque_barra(false, Vector2(x, y)))
		print("demo: %.1f s · giro solto (yaw %.0f°)" % [agora, rad_to_deg(main.cam3d.yaw)])
		_giro = {}


func _toque_barra(pressionado: bool, pos: Vector2) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.index = DEDO_BARRA
	ev.position = pos
	ev.pressed = pressionado
	return ev


## O corpo terminou o caminho E a perseguição/golpe (a marca saiu e não há
## ataque em curso)? É a hora de riscar o caminho da cena do cavar.
func _livre() -> bool:
	return not main.corpo.em_rota() and not main.corpo.em_inercia() \
		and main.corpo.mira_final_id == "" and main.corpo.ataque == ""


## Está parada na superfície, sem rota/inércia e SEM CARREGAR o tiro: o dedo do
## cavar desce (começar a cavar no meio de uma carga seria outra ação).
func _parada() -> bool:
	return main.corpo.camada == "superficie" and not main.corpo.em_rota() \
		and not main.corpo.em_inercia() and not main.corpo.carregando() \
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
	# a BASE da afim chão→tela (escala + giro + encurtamento do pitch)
	var base: Transform2D = main.chao_tela()
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
		pts.append(cria_t + base.basis_xform(Vector2(r[0], r[1])) / ganho)
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
