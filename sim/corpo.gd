extends RefCounted
## O CORPO da criatura: máquina de ações — LÓGICA PURA, avançada por passo(dt).
##
## Estados: parado · andando (segue um caminho) · acao (uma ação de
## dados/acoes.json). Toda ação tem três fases — antecipação, ATIVA,
## recuperação — e só a ativa tem efeito (golpe, voo, deslocamento, escavação).
## Regras:
## - uma ação por vez; um comando que chega na RECUPERAÇÃO fica guardado
##   (`pendente`) e sai assim que ela termina; antes disso é recusado;
## - cada ação tem recarga (não repete antes);
## - ação sustentada (defender) fica na fase ativa enquanto o dedo segura;
## - deslocamentos e pulo consultam o mundo (sim/mundo.gd): não atravessam
##   parede, pulo só pousa onde pode;
## - escavar troca a camada (superfície ↔ subsolo) no fim da fase ativa.
## A apresentação lê pos, z, olhar, camada, acao, fase e drena `eventos`.

const Mundo := preload("res://sim/mundo.gd")
const Trajetoria := preload("res://sim/trajetoria.gd")

var defs: Dictionary = {}
var pos := Vector2.ZERO
var z := 0.0  # altura no ar (pulo), em px de mundo
var olhar := Vector2.RIGHT
var camada := Mundo.SUPERFICIE
var estado := "parado"
var acao := ""
var fase := ""
var t_fase := 0.0
var caminho := PackedVector2Array()
var recargas := {}
var pendente := {}
var eventos: Array[String] = []
var dir := Vector2.RIGHT  # direção da ação em curso
var _andado := 0.0
var _origem := Vector2.ZERO
var _destino := Vector2.ZERO
var _segurando := false
var _celula := Vector2i.ZERO


func _init(definicoes: Dictionary = {}) -> void:
	defs = definicoes


## Recebe um comando (sim/comandos.gd). Devolve "aceito", "guardado" ou
## "recusado: <motivo>".
func comandar(cmd: Dictionary, mundo: RefCounted) -> String:
	var a: String = cmd.get("acao", "")
	if a == "soltar":
		_segurando = false
		return "aceito"
	if not defs.has(a):
		return "recusado: ação desconhecida (%s)" % a
	if estado == "acao":
		if fase == "recuperacao" and a != "olhar":
			pendente = cmd
			return "guardado"
		return "recusado: ocupado (%s)" % acao
	if float(recargas.get(a, 0.0)) > 0.0:
		return "recusado: recarga"
	var d: Dictionary = defs[a]
	match d.get("tipo", "acao"):
		"movimento":
			var pts := PackedVector2Array([pos])
			pts.append_array(cmd.get("pontos", PackedVector2Array()))
			caminho = mundo.limitar_caminho(Trajetoria.amostrar(pts, 3.0), camada)
			if caminho.size() < 2:
				return "recusado: caminho bloqueado"
			estado = "andando"
			_andado = 0.0
			eventos.append("inicio:mover")
			return "aceito"
		"instantanea":
			var v: Vector2 = cmd.get("alvo", pos) - pos
			if v.length() > 1.0:
				olhar = v.normalized()
			return "aceito"
	return _iniciar_acao(a, d, cmd, mundo)


func _iniciar_acao(a: String, d: Dictionary, cmd: Dictionary, mundo: RefCounted) -> String:
	var direcao: Vector2 = cmd.get("direcao", Vector2.ZERO)
	if direcao.length() < 0.01:
		direcao = olhar
	var destino := pos
	match a:
		"pular":
			if camada == Mundo.SUBSOLO:
				return "recusado: no subsolo não dá para pular"
			var alvo: Vector2 = cmd.get("alvo", pos)
			if alvo.distance_to(pos) > 8.0:
				direcao = (alvo - pos).normalized()
				destino = mundo.pouso(pos, alvo, float(d.get("distancia", 80.0)), camada)
		"escavar":
			_celula = mundo.celula_de(pos)
			if not mundo.pode_escavar(_celula, camada):
				return "recusado: aqui não dá para escavar"
		_:
			var desl := float(d.get("deslocamento", 0.0))
			if desl != 0.0:
				destino = mundo.limitar_segmento(pos, pos + direcao * desl, camada)
	if bool(d.get("vira", false)):
		olhar = direcao
	dir = direcao
	estado = "acao"
	acao = a
	caminho = PackedVector2Array()
	_origem = pos
	_destino = destino
	_segurando = bool(d.get("sustentada", false))
	_entrar("antecipacao")
	eventos.append("inicio:" + a)
	return "aceito"


func passo(dt: float, mundo: RefCounted) -> void:
	for k in recargas.keys():
		recargas[k] = maxf(0.0, float(recargas[k]) - dt)
	match estado:
		"andando":
			var total := Trajetoria.comprimento(caminho)
			var antes := pos
			_andado = minf(_andado + float(defs["mover"].get("velocidade", 100.0)) * dt, total)
			pos = Trajetoria.ponto_em(caminho, _andado)
			if pos.distance_to(antes) > 0.01:
				olhar = (pos - antes).normalized()
			if _andado >= total:
				estado = "parado"
				eventos.append("fim:mover")
		"acao":
			_passo_acao(dt, mundo)


func _passo_acao(dt: float, mundo: RefCounted) -> void:
	var d: Dictionary = defs[acao]
	var f: Array = d.get("fases", [0.0, 0.0, 0.0])
	t_fase += dt
	for _i in 4:  # várias fases curtas podem caber num passo grande
		if fase == "antecipacao" and t_fase >= float(f[0]):
			t_fase -= float(f[0])
			_entrar("ativo", false)
		elif fase == "ativo":
			if bool(d.get("sustentada", false)):
				if _segurando:
					return
				_entrar("recuperacao")
			else:
				var dur := maxf(float(f[1]), 0.0001)
				var u := clampf(t_fase / dur, 0.0, 1.0)
				pos = _origem.lerp(_destino, u)
				z = sin(PI * u) * float(d.get("altura", 0.0)) if acao == "pular" else 0.0
				if t_fase < dur:
					return
				t_fase -= dur
				_concluir_ativo(mundo)
				_entrar("recuperacao", false)
		elif fase == "recuperacao" and t_fase >= float(f[2]):
			_terminar(mundo)
			return
		else:
			return


func _concluir_ativo(mundo: RefCounted) -> void:
	z = 0.0
	pos = _destino
	if acao == "escavar":
		camada = mundo.escavar(_celula, camada)
		pos = mundo.centro(_celula)
		eventos.append("camada:" + camada)


func _terminar(mundo: RefCounted) -> void:
	recargas[acao] = float(defs[acao].get("recarga", 0.0))
	eventos.append("fim:" + acao)
	estado = "parado"
	acao = ""
	fase = ""
	if not pendente.is_empty():
		var p := pendente
		pendente = {}
		comandar(p, mundo)


func _entrar(nova: String, zerar := true) -> void:
	fase = nova
	if zerar:
		t_fase = 0.0
	eventos.append(nova + ":" + acao)


## Para a apresentação e o combate futuro: o golpe está valendo agora?
func golpe_ativo() -> Dictionary:
	if estado != "acao" or fase != "ativo" or not defs[acao].has("alcance"):
		return {}
	var d: Dictionary = defs[acao]
	return {"alcance": float(d["alcance"]), "arco": float(d.get("arco", 90.0)), "dir": dir}


func invulneravel() -> bool:
	return estado == "acao" and fase == "ativo" and bool(defs[acao].get("invulneravel", false))


func defendendo() -> bool:
	return estado == "acao" and acao == "defender" and fase != "recuperacao"


func drenar_eventos() -> Array[String]:
	var e := eventos
	eventos = []
	return e
