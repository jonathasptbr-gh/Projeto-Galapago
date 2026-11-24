extends Node2D
## Cena principal (v0.9): a FUNDAÇÃO em RETRATO, com caminho desenhado AO VIVO
## e o ataque nascendo da FORMA do desenho.
##
## Camadas de desenho (z_index), de trás para frente:
##   −20 parallax fundo · 0 chão · 1 trilha/rota · 2 objetos (y-sort: troncos,
##   baú, adversário, criatura) · 15 subsolo · 24 efeitos (onda/tiro) ·
##   25 marca de mira/alvo final · 30 copas · 40 parallax frente · HUD.
##
## Fluxo: dedo → sim/gestos (um dedo: caminho ao vivo; toque = TIRO CARREGADO,
## toque duplo = pulo, segurar = CORRER com caminho / habilidade sem ele) →
## sim/comandos → sim/corpo (traço ao vivo + formas do caminho + carga do tiro
## + overlays + autonomia). O tempo é SIMULADO (tempo_ms): demo e oráculo são
## determinísticos. Nenhuma regra de jogo mora aqui: o main lê o dedo, desenha
## e chama o comando.
##
## v0.9 — a ORIGEM do caminho é congelada no `dedo_desceu` (posição da criatura
## naquele instante). A FORMA do traço vira ataque dentro do `sim/corpo.gd`
## (travessia → batida; fim em cima do adversário → golpe final marcado nele;
## o laço NÃO vira mais onda em área desde a v0.11.5 — ver `formas.laco_ataque`
## em `dados/acoes.json`). Enquanto desenha, o mundo roda em tempo lento e a
## tela escurece; ao soltar, o tempo ACELERA numa rampa.
##
## v0.18 — a **PAUSA DE SAÍDA** não existe mais (nem `corpo.em_atraso()`): o
## toque (`"tiro"`) começa a CARGA de 1 s — o animal para e o disparo sai
## sozinho, com carga cheia, mirado no alvo marcado vivo ou no fim do caminho;
## o segurar com caminho é o CORRER contínuo e, sem caminho, a habilidade. A
## RAMPA de aceleração (`rota.rampa_s`) é do CORPO no começo de cada caminhada
## NOVA; o main só desacelera e retoma o MUNDO enquanto o dedo desenha. A HUD
## desenha a barra de carga e a criatura, o anel; o jogo só lê o corpo e desenha.

const Mundo := preload("res://sim/mundo.gd")
const Corpo := preload("res://sim/corpo.gd")
const Gestos := preload("res://sim/gestos.gd")
const CameraToque := preload("res://sim/camera_toque.gd")
const Comandos := preload("res://sim/comandos.gd")
const Alvos := preload("res://sim/alvos.gd")
const Adversario := preload("res://sim/adversario.gd")
const Mock := preload("res://jogo/mock.gd")
const Chao := preload("res://jogo/camadas/chao.gd")
const Subsolo := preload("res://jogo/camadas/subsolo.gd")
const ObjetoMock := preload("res://jogo/camadas/objeto_mock.gd")
const Copa := preload("res://jogo/camadas/copa.gd")
const Parallax := preload("res://jogo/camadas/parallax.gd")
const Criatura := preload("res://jogo/criatura.gd")
const AdversarioMock := preload("res://jogo/adversario_mock.gd")
const Perigos := preload("res://jogo/perigos.gd")
const Mira := preload("res://jogo/mira.gd")
const Trilha := preload("res://jogo/trilha.gd")
const Efeitos := preload("res://jogo/efeitos.gd")
const Hud := preload("res://jogo/hud.gd")
const Demo := preload("res://jogo/demo.gd")

const MAPA := "res://dados/mapas/fundacao.json"
# JOYSTICK da vista íntima: o deslocamento do dedo até este RAIO vira magnitude
# 1,0 do controle relativo (100% do curso). Com o teto de 88 px/s do modo
# PERTO, metade do raio = 44 px/s; além do raio satura em 88.
const RAIO_JOYSTICK_PX := 90.0

var mundo: RefCounted
var corpo: RefCounted
var reconhecedor: RefCounted
var cfg_gestos: Dictionary
var tempo_ms := 0.0
var alvos: Array = []
var adversarios: Array = []
var cfg_adversario: Dictionary = {}
var hostilidade := false
var chao: Node2D
var subsolo: Node2D
var criatura: Node2D
var mira: Node2D
var trilha: Node2D
var perigos: Node2D
var efeitos: Node2D
var camera: Camera2D
var hud: CanvasLayer
var copas: Array = []
var veu: ColorRect
var _dedos := {}  # índice do dedo -> pressionado (multitouch)
var camera_toque := CameraToque.new()
var mundo_visual: Node2D
var objetos_visuais: Node2D
var _joystick_origem := Vector2.ZERO
var _joystick_dedo := -1
# a ORIGEM do gesto (congelada na descida do dedo): a linha não anda com ela
var _gesto_tela := Vector2.ZERO
var _gesto_origem := Vector2.ZERO
var _gesto_inv := Transform2D.IDENTITY
var _traco_iniciado := false
# o traço nasceu de um SEGURAR que virou desenho (dedo não levantou)?
# Só esse caso recomeça a origem e encerra o sprint ao soltar.
var _desenho_de_segurar := false
# tempo lento do desenho e a rampa de volta ao tempo normal (do MUNDO; a
# rampa de aceleração do começo da caminhada é do corpo)
var _escala := 1.0
var _retomada := 0.0
var _veu_alfa := 0.0


func _ready() -> void:
	var mapa := _json(MAPA)
	cfg_gestos = _json("res://dados/gestos.json")
	cfg_adversario = _json("res://dados/adversario.json")
	mundo = Mundo.criar(mapa, _json("res://dados/terrenos.json"))
	for e in mundo.validar():
		push_error("mapa: " + e)
	corpo = Corpo.new(_json("res://dados/acoes.json"))
	corpo.rng.seed = 20261120
	corpo.pos = mundo.centro(Vector2i(mapa["inicio"][0], mapa["inicio"][1]))
	reconhecedor = Gestos.new(cfg_gestos.get("limiares", {}))
	RenderingServer.set_default_clear_color(Color("#0b2438"))

	add_child(Parallax.new())
	var no := Node2D.new()
	mundo_visual = no
	add_child(no)
	chao = Chao.new()
	chao.mundo = mundo
	no.add_child(chao)
	trilha = Trilha.new()
	trilha.z_index = 1
	no.add_child(trilha)

	var objetos := Node2D.new()
	objetos_visuais = objetos
	objetos.y_sort_enabled = true
	objetos.z_index = 2
	no.add_child(objetos)
	for o in mapa.get("objetos", []):
		var c := Vector2i(o["celula"][0], o["celula"][1])
		var ob := ObjetoMock.new()
		ob.tipo = o["tipo"]
		ob.id_objeto = "%s:%d,%d" % [o["tipo"], c.x, c.y]
		ob.position = mundo.centro(c) + Vector2(0, 8)
		ob.set_meta("altura_terreno", mundo.altura(c))
		ob.desnivel = Mock.desnivel(mundo.altura(c))
		objetos.add_child(ob)
		if o.has("copa"):
			var cp := Copa.new()
			cp.raio = float(o["copa"])
			cp.base = ob.position + Vector2(0, ob.desnivel)
			cp.set_meta("tronco", ob)
			cp.z_index = 30
			no.add_child(cp)
			copas.append(cp)

	for a in mapa.get("adversarios", []):
		var adv := Adversario.new(int(a.get("semente", 1)), Rect2(), cfg_adversario)
		adv.pos = mundo.centro(Vector2i(a["celula"][0], a["celula"][1]))
		adversarios.append(adv)
		var no_adv := AdversarioMock.new()
		no_adv.adv = adv
		no_adv.mundo = mundo
		objetos.add_child(no_adv)
	alvos = Alvos.montar(mapa.get("objetos", []), adversarios, mundo)
	perigos = Perigos.new()
	perigos.adversarios = adversarios
	perigos.mundo = mundo
	perigos.z_index = 1
	no.add_child(perigos)

	criatura = Criatura.new()
	criatura.corpo = corpo
	criatura.mundo = mundo
	objetos.add_child(criatura)

	subsolo = Subsolo.new()
	subsolo.mundo = mundo
	subsolo.z_index = 15
	subsolo.visible = false
	no.add_child(subsolo)

	efeitos = Efeitos.new()
	efeitos.corpo = corpo
	efeitos.mundo = mundo
	efeitos.z_index = 24
	no.add_child(efeitos)

	mira = Mira.new()
	mira.corpo = corpo
	mira.mundo = mundo
	mira.alvos = alvos
	mira.z_index = 25
	no.add_child(mira)

	camera = Camera2D.new()
	camera.zoom = Vector2(Mock.ZOOM, Mock.ZOOM)
	camera.limit_left = -Mock.CELULA
	camera.limit_top = -Mock.CELULA
	camera.limit_right = (mundo.largura + 1) * Mock.CELULA
	camera.limit_bottom = (mundo.altura_grade + 1) * Mock.CELULA
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.position = corpo.pos
	add_child(camera)
	camera.make_current()

	hud = Hud.new()
	hud.hostilidade_alternada.connect(definir_hostilidade)
	add_child(hud)
	# VÉU do desenho: escurece a tela para ilustrar a desaceleração (fica
	# ATRÁS dos rótulos da HUD, que são filhos da mesma CanvasLayer).
	veu = ColorRect.new()
	veu.color = Color(0, 0, 0, 0)
	veu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(veu)
	hud.move_child(veu, 0)
	if "--demo" in OS.get_cmdline_user_args():
		add_child(Demo.new(self))


func _process(delta: float) -> void:
	tempo_ms += delta * 1000.0
	# O relógio do gesto é REAL: o `tick` solta o TOQUE pendente quando a janela
	# do duplo fecha e ativa o segurar no limiar (a regra é de sim/gestos.gd).
	_entregar(reconhecedor.tick(tempo_ms))
	# TRAÇO AO VIVO: enquanto o dedo desenha, a rota é refeita e a criatura já
	# anda por ela. O relógio do GESTO é real; quem desacelera é o MUNDO.
	if reconhecedor.desenhando():
		var pts_gesto := _pontos_gesto()
		# um recomeço de segurar começa com UM ponto — não traça ainda.
		if pts_gesto.size() >= 2:
			var res := str(corpo.tracar(pts_gesto, mundo, not _traco_iniciado, alvos))
			# No recomeço do segurar, um "recusado" (traço curto) NÃO marca o
			# início: senão a rota seria adotada como continuação (inicio=false)
			# e herdaria o progresso da rota antiga.
			if not _desenho_de_segurar or res.begins_with("ok"):
				_traco_iniciado = true
	# PLANEJAMENTO: desenhando, o mundo desacelera; ao soltar, uma RAMPA de
	# aceleração devolve o tempo normal (dá tempo de reagir).
	var plano: Dictionary = cfg_gestos.get("planejamento", {})
	var lento := float(plano.get("escala_tempo", 0.35))
	var retomada_s := maxf(float(plano.get("retomada_ms", 450)) / 1000.0, 0.001)
	var planejando: bool = reconhecedor.planejando()
	if planejando:
		_retomada = retomada_s
		_escala = lento
	elif _retomada > 0.0:
		_retomada = maxf(0.0, _retomada - delta)
		var v := 1.0 - _retomada / retomada_s
		_escala = lerpf(lento, 1.0, v * v)  # começa devagar e solta no fim
	else:
		_escala = 1.0
	var dt := delta * _escala
	# o inimigo só caça quem está na SUPERFÍCIE; no subsolo ele não tem alvo
	var alvo_corpo: Variant = corpo if corpo.camada == Mundo.SUPERFICIE else null
	for adv in adversarios:
		adv.passo(dt, mundo, alvo_corpo)
		for e in adv.drenar_eventos():
			_evento(e)
	Alvos.sincronizar(alvos, adversarios)
	corpo.passo(dt, mundo, alvos)
	for e in corpo.drenar_eventos():
		_evento(e)
	for cp in copas:
		cp.atualizar(corpo.pos, delta, corpo.camada == Mundo.SUBSOLO)
	# A LINHA mostra o TRAÇO CRU (os pontos densos do desenho): contínua e fiel
	# ao movimento do dedo, não a rota simplificada (v0.9.2).
	if corpo.em_rota() or reconhecedor.desenhando():
		trilha.mostrar(corpo.traco, corpo.traco_t)
	else:
		trilha.mostrar(PackedVector2Array())
	var visual: Vector2 = criatura.ponto_visual()
	if camera_toque.inclinacao() == 1.0:
		camera.position = visual  # preserva exatamente a aritmética do baseline
	else:
		camera.position = Vector2(visual.x, corpo.pos.y * camera_toque.inclinacao() + visual.y - corpo.pos.y)
	hud.estado(corpo, alvos, planejando, _escala, adversarios, hostilidade)
	_escurecer(planejando, plano, retomada_s, delta)


## VÉU: escurece enquanto desenha e clareia junto com a rampa de aceleração.
## Suavizado para não piscar num gesto que mal começou.
func _escurecer(planejando: bool, plano: Dictionary, retomada_s: float, delta: float) -> void:
	var forca := float(plano.get("escurecer", 0.22))
	# 1 enquanto planeja; ao soltar, 1 → 0 junto com a rampa
	var alvo := 1.0 if planejando else _retomada / retomada_s
	_veu_alfa = lerpf(_veu_alfa, clampf(alvo, 0.0, 1.0), clampf(delta * 9.0, 0.0, 1.0))
	veu.color = Color(0, 0, 0, forca * _veu_alfa)


func _evento(e: String) -> void:
	if e.begins_with("camada:"):
		subsolo.visible = corpo.camada == Mundo.SUBSOLO
		chao.queue_redraw()
		subsolo.queue_redraw()
	elif e.begins_with("interagir:"):
		var id := e.substr(10)
		for n in get_node(".").find_children("*", "", true, false):
			if n is ObjetoMock and n.id_objeto == id:
				n.aberto = true
	elif e == "rota:fim":
		trilha.mostrar(PackedVector2Array())
	elif e == "carga:on":
		print("evento: ", e)
		hud.nota("CARREGANDO")
	elif e == "sprint:on":
		print("evento: ", e)
		hud.nota("CORRENDO")
	elif e == "sprint:off":
		# soltou o segurar: a CAUDA mantém o embalo por `sprint.cauda_s`
		print("evento: ", e)
		hud.nota("CAUDA — o embalo continua")
	elif e.begins_with("laco:"):
		print("evento: ", e)
		hud.nota("LAÇO: onda em área")
	elif e.begins_with("tiro:"):
		print("evento: ", e)
		hud.nota("TIRO")
	elif e.begins_with("batida:"):
		print("evento: ", e)
		hud.nota("BATIDA em %s" % e.substr(7))
	elif e.begins_with("acerto:"):
		print("evento: ", e)
		hud.nota("ACERTO em %s" % e.substr(7))
	elif e.begins_with("golpe_final:"):
		print("evento: ", e)
		hud.nota("GOLPE FINAL em %s" % e.substr(12))
	elif e == "mira_final:perde":
		print("evento: ", e)
		hud.nota("alvo marcado se perdeu")
	elif e == "mira_final:":
		# v0.11.4: o caminho passou por cima e SEGUIU — não volta para bater
		print("evento: ", e)
		hud.nota("marca solta: o caminho seguiu longe")
	elif e.begins_with("mira_final:"):
		print("evento: ", e)
		hud.nota("ALVO MARCADO em %s" % e.substr(11))
	elif e.begins_with("perigo:"):
		print("evento: ", e)
		hud.nota("INIMIGO PREPARA %s" % _nome_ataque(e.substr(7)))
	elif e.begins_with("acerta:"):
		print("evento: ", e)
		hud.nota("GOLPE DO INIMIGO: %s" % _nome_ataque(e.substr(7)))
	elif e == "levou:golpe":
		print("evento: ", e)
	elif e == "esconde:prepara":
		print("evento: ", e)
		hud.nota("o inimigo vai se esconder")
	elif e == "esconde:on":
		print("evento: ", e)
		hud.nota("o inimigo se ESCONDEU — intocável")
	elif e == "esconde:off":
		print("evento: ", e)
		hud.nota("o inimigo reapareceu")
	elif e == "esconde:sai":
		pass


func _nome_ataque(nome: String) -> String:
	match nome:
		"bote":
			return "BOTE"
		"esbarrao":
			return "ESBARRÃO"
		"cuspe":
			return "CUSPE"
		"esconder":
			return "ESCONDER"
	return nome.to_upper()


## Liga/desliga a hostilidade em TODOS os adversários (o botão da HUD chama).
func definir_hostilidade(v: bool) -> void:
	hostilidade = v
	for adv in adversarios:
		adv.definir_hostil(v)
	if hud:
		hud.nota("HOSTILIDADE %s" % ("LIGADA — ele vai caçar" if v else "desligada"))


# ---------- o dedo (toque real e demo passam por aqui) ----------

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and corpo != null:
		_cancelar_contatos()


func _cancelar_contatos() -> void:
	_dedos.clear()
	camera_toque.dedos.clear()
	camera_toque.par.clear()
	camera_toque.bloqueado = false
	reconhecedor = Gestos.new(cfg_gestos.get("limiares", {}))
	_joystick_dedo = -1
	corpo.comandar({"acao": "soltar_segurar"}, mundo, alvos)
	if _traco_iniciado:
		corpo.definir_controle_relativo(true)
		corpo.definir_controle_relativo(camera_toque.intima())
	_traco_iniciado = false
	_desenho_de_segurar = false
	_levar_modo_camera()
	corpo.mover_relativo(Vector2.ZERO)


# Solturas de contatos iniciados no mundo devem chegar mesmo sobre um botão.
func _input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if _dedos.has(ev.index):
			if ev.canceled:
				_cancelar_contatos()
			elif not ev.pressed:
				dedo_subiu(ev.index, ev.position)
		elif ev.pressed and not _dedos.is_empty():
			dedo_desceu(ev.index, ev.position)
			get_viewport().set_input_as_handled()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed and not _dedos.has(ev.index):
			dedo_desceu(ev.index, ev.position)
		elif not ev.pressed and _dedos.has(ev.index):
			dedo_subiu(ev.index, ev.position)
	elif ev is InputEventScreenDrag and _dedos.has(ev.index):
		dedo_moveu(ev.index, ev.position)


func dedo_desceu(dedo: int, p: Vector2) -> void:
	var acao := camera_toque.descer(dedo, p)
	_dedos[dedo] = true
	# O zoom pode ter mudado desde o último toque: o modo é sincronizado AQUI
	# também, senão o dedo entraria com o modo velho (joystick × caminho).
	_levar_modo_camera()
	if acao == "pinca":
		# Cancela também toques pendentes; nenhum dedo remanescente reinicia gesto.
		corpo.comandar({"acao": "soltar_segurar"}, mundo, alvos)
		if _traco_iniciado:
			corpo.definir_controle_relativo(true)
			corpo.definir_controle_relativo(camera_toque.intima())
		reconhecedor = Gestos.new(cfg_gestos.get("limiares", {}))
		_traco_iniciado = false
		_desenho_de_segurar = false
		_joystick_dedo = -1
		corpo.mover_relativo(Vector2.ZERO)
		return
	if acao != "principal":
		return
	if camera_toque.intima():
		_joystick_dedo = dedo
		_joystick_origem = p
		corpo.mover_relativo(Vector2.ZERO)
		return
	_gesto_tela = p
	_gesto_origem = corpo.pos
	_gesto_inv = get_viewport().get_canvas_transform().affine_inverse()
	_traco_iniciado = false
	_desenho_de_segurar = false
	_entregar(reconhecedor.iniciar(dedo, p, tempo_ms, tela_de(criatura.ponto_visual() + Vector2(0, -20))))


func dedo_moveu(dedo: int, p: Vector2) -> void:
	var acao := camera_toque.mover(dedo, p)
	if acao == "pinca":
		_aplicar_camera()
	elif acao == "principal":
		if camera_toque.intima() and dedo == _joystick_dedo:
			var deslocamento := (p - _joystick_origem) / RAIO_JOYSTICK_PX
			corpo.mover_relativo(deslocamento.limit_length(1.0))
		else:
			# o dedo SEGURANDO que se move sem levantar começa um desenho
			# NOVO na posição ATUAL (a origem congelada na descida já não vale
			# para esses pontos). O segurar continua — o sprint não cai.
			var limiares: Dictionary = cfg_gestos.get("limiares", {})
			if not camera_toque.intima() and reconhecedor.ativo() \
					and not reconhecedor.desenhando() and reconhecedor.segurando() \
					and p.distance_to(reconhecedor.inicio()) > float(limiares.get("desenho_min_px", 16.0)):
				_recomecar_segurar(p)
			_entregar(reconhecedor.mover(dedo, p, tempo_ms))


## Recomeça o traço do SEGURAR no ponto atual. A criatura é a ORIGEM
## (em mundo) e o mapa tela→mundo também é congelado aqui; o primeiro ponto
## nasce exatamente sobre ela.
func _recomecar_segurar(p: Vector2) -> void:
	reconhecedor.recomecar(p, tempo_ms)
	_gesto_origem = corpo.pos
	_gesto_tela = p
	_gesto_inv = get_viewport().get_canvas_transform().affine_inverse()
	_traco_iniciado = false
	_desenho_de_segurar = true


func dedo_subiu(dedo: int, p: Vector2) -> void:
	var acao := camera_toque.subir(dedo)
	_dedos.erase(dedo)
	if acao != "principal":
		return
	if camera_toque.intima():
		_joystick_dedo = -1
		corpo.mover_relativo(Vector2.ZERO)
	else:
		_entregar(reconhecedor.soltar(dedo, p, tempo_ms))


## Leva o MODO da câmera (PERTO/LONGE) para o corpo. É ele que decide o TETO
## de velocidade e se existe CAMINHADA (de longe, andar já é correr). A pinça
## pode mudar o zoom em QUALQUER movimento, então isto roda a cada movimento de
## pinça e em cada toque que ENTRA — nunca só na descida do primeiro dedo.
func _levar_modo_camera() -> void:
	var intima: bool = camera_toque.intima()
	corpo.definir_camera_perto(intima)
	if corpo.controle_relativo != intima:
		corpo.definir_controle_relativo(intima)


func _aplicar_camera() -> void:
	_levar_modo_camera()
	var intima: bool = camera_toque.intima()
	var inclinacao: float = camera_toque.inclinacao()
	mundo_visual.scale = Vector2(1.0, inclinacao)
	chao.inclinacao = inclinacao
	chao.queue_redraw()
	criatura.inclinacao = inclinacao
	efeitos.inclinacao = inclinacao
	mira.inclinacao = inclinacao
	perigos.inclinacao = inclinacao
	# Os pés seguem o chão projetado; os desenhos dos objetos não são achatados.
	for objeto in objetos_visuais.get_children():
		objeto.scale = Vector2(1.0, 1.0 / inclinacao)
		if objeto is AdversarioMock:
			objeto.inclinacao = inclinacao
		if objeto.has_meta("altura_terreno"):
			objeto.desnivel = Mock.desnivel(float(objeto.get_meta("altura_terreno")), inclinacao) * inclinacao
			objeto.queue_redraw()
	for cp in copas:
		var tronco: Node2D = cp.get_meta("tronco")
		cp.base = tronco.position + Vector2(0, tronco.desnivel / inclinacao)
		cp.queue_redraw()
	camera.zoom = Vector2.ONE * camera_toque.zoom
	camera.limit_top = roundi(-Mock.CELULA * inclinacao)
	camera.limit_bottom = roundi((mundo.altura_grade + 1) * Mock.CELULA * inclinacao)
	hud.definir_vista_intima(intima)


func _entregar(evs: Array) -> void:
	for ev in evs:
		if ev["gesto"] == "trajetoria":
			# O caminho já foi desenhado AO VIVO: aqui só se fecha a rota com o
			# último trecho (nada de recomeçar do zero) e se marca o alvo final.
			var res := str(corpo.tracar(_pontos_gesto(), mundo, not _traco_iniciado, alvos))
			_traco_iniciado = false
			var marca := str(corpo.finalizar_rota(alvos))
			if marca != "":
				res += " · " + marca
			# quando o desenho NASCEU de um SEGURAR (o dedo não levantou
			# entre o sprint e o traço), fechar a trajetória encerra o segurar —
			# senão o sprint ficaria preso. O desenho normal não passa por aqui.
			if _desenho_de_segurar:
				corpo.comandar({"acao": "soltar_segurar"}, mundo, alvos)
				_desenho_de_segurar = false
			hud.gesto(ev, Comandos.traduzir(ev, cfg_gestos.get("mapa", {})), res)
			continue
		var pm := PackedVector2Array()
		for q in PackedVector2Array(ev["pontos"]):
			pm.append(mundo_de(q))
		ev["pontos_mundo"] = pm
		ev["alvo"] = pm[pm.size() - 1] if not pm.is_empty() else corpo.pos
		var cmd := Comandos.traduzir(ev, cfg_gestos.get("mapa", {}))
		var res := "não reconhecido" if cmd.is_empty() else str(corpo.comandar(cmd, mundo, alvos))
		hud.gesto(ev, cmd, res)


## O desenho do dedo em MUNDO, a partir da origem congelada e com o GANHO de
## sensibilidade: um dedo menor cobre mais tela (o mesmo traço em px de tela é
## multiplicado por `desenho.ganho`).
func _pontos_gesto() -> PackedVector2Array:
	var ganho := float(cfg_gestos.get("desenho", {}).get("ganho", 1.0))
	var pts := PackedVector2Array()
	for q in reconhecedor.pontos():
		pts.append(_gesto_origem + _gesto_inv.basis_xform((q - _gesto_tela) * ganho))
	return pts


func mundo_de(tela: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * tela


func tela_de(mundo_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * mundo_pos


func _json(caminho: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(caminho))
