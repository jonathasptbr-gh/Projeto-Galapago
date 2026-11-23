extends RefCounted
## PELE GEOMÉTRICA — o rig desenhado com formas. Nenhum asset, nenhuma geração.
## Lê `sim/esqueleto.gd` (pose e âncoras por NOME) e só desenha; trocar por
## sprite é trocar esta pele, não a mecânica.

const E := preload("res://sim/esqueleto.gd")
const TINTA := Color("#2a1a10")
const ANCORA := {"boca": Color("#7fe0ff"), "coroa": Color("#ffd84d"), "base_cauda": Color("#ff9f6b"),
	"dorso": Color("#c58bff"), "asa_e": Color("#9fe26a"), "asa_d": Color("#9fe26a")}
const PALETAS := {
	"canino": {"corpo": "#d9752f", "claro": "#f2a45c", "escuro": "#9c4f1c"},
	"serpente": {"corpo": "#6fae5a", "claro": "#a8d98a", "escuro": "#3f7034"},
	"ave": {"corpo": "#c9b48a", "claro": "#e6d7b4", "escuro": "#8a7350"}
}


## `base` é o ponto do chão da criatura na tela; `tinta` escurece no subsolo.
static func desenhar(c: CanvasItem, rig: Dictionary, direcao: String, fase: float, clipe: String,
		base: Vector2, tinta: Color = Color.WHITE, debug: bool = false, escala: float = 1.0,
		pose_pronta: Dictionary = {}) -> void:
	var pose := pose_pronta
	if pose.is_empty():
		pose = E.pose(rig, direcao, fase, clipe)
	if pose.is_empty():
		return
	var j: Dictionary = pose["juntas"]
	var piv := Vector2(float(rig["pivot_px"][0]), float(rig["pivot_px"][1]))
	var arq := String(rig.get("arquetipo", "quadrupede"))
	var pal: Dictionary = PALETAS.get(String(rig.get("id", "")), PALETAS["canino"])
	var cores := {
		"corpo": Color(pal["corpo"]) * tinta,
		"claro": Color(pal["claro"]) * tinta,
		"escuro": Color(pal["escuro"]) * tinta,
		"tinta": TINTA * tinta,
	}
	match arq:
		"serpente":
			_serpente(c, rig, j, direcao, base, piv, escala, cores)
		"ave":
			_ave(c, rig, j, direcao, base, piv, escala, cores)
		_:
			_quadrupede(c, rig, j, direcao, base, piv, escala, cores)
	if debug:
		_ossos(c, rig, j, direcao, base, piv, escala)
		_ancoras(c, rig, pose, direcao, base, piv, escala)


static func _p(p: Vector2, base: Vector2, piv: Vector2, s: float) -> Vector2:
	return base + (p - piv) * s


static func _cor(cores: Dictionary, chave: String) -> Color:
	return cores.get(chave, cores["corpo"])


# --- quadrúpede ---

static func _quadrupede(c: CanvasItem, rig: Dictionary, j: Dictionary, direcao: String,
		base: Vector2, piv: Vector2, s: float, cores: Dictionary) -> void:
	var costas := bool(rig["directions"][direcao]["costas"])
	var perf: String = rig["directions"][direcao]["profile"]
	if perf == "frontal":
		_quad_frontal(c, j, base, piv, s, cores, costas)
	else:
		_quad_lateral(c, j, base, piv, s, cores, costas)


static func _quad_lateral(c: CanvasItem, j: Dictionary, base: Vector2, piv: Vector2, s: float,
		cores: Dictionary, costas: bool) -> void:
	var tinta := _cor(cores, "tinta")
	var corpo := _cor(cores, "corpo")
	var claro := _cor(cores, "claro")
	var escuro := _cor(cores, "escuro")
	for suf in ["t2", "f2"]:
		if j.has("pata_" + suf) and j.has("joelho_" + suf):
			var raiz := "quadril" if suf.begins_with("t") else "peito"
			_membro(c, _p(j[raiz], base, piv, s), _p(j["joelho_" + suf], base, piv, s),
				_p(j["pata_" + suf], base, piv, s), 3.6 * s, escuro, tinta)
	if not costas and j.has("cauda_base"):
		_cauda(c, j, base, piv, s, corpo, tinta)
	var meio: Vector2 = (j["lombo"] + j["peito"]) * 0.5
	_elipse(c, _p(meio, base, piv, s), 9.2 * s, 7.6 * s, corpo, tinta)
	_elipse(c, _p(meio + Vector2(1.2, 2.4), base, piv, s), 6.2 * s, 4.2 * s, claro, Color(0, 0, 0, 0))
	for suf in ["t", "f"]:
		if j.has("pata_" + suf) and j.has("joelho_" + suf):
			var raiz2 := "quadril" if suf == "t" else "peito"
			_membro(c, _p(j[raiz2], base, piv, s), _p(j["joelho_" + suf], base, piv, s),
				_p(j["pata_" + suf], base, piv, s), 4.0 * s, corpo, tinta)
	_membro(c, _p(j["peito"], base, piv, s), _p(j["pescoco"], base, piv, s),
		_p(j["cabeca"], base, piv, s), 5.8 * s, corpo, tinta)
	var cab := _p(j["cabeca"], base, piv, s)
	var foc := _p(j["focinho"], base, piv, s)
	var d := (foc - cab).normalized()
	var n := d.orthogonal()
	_elipse(c, cab, 6.2 * s, 5.9 * s, corpo, tinta)
	if not costas:
		_membro(c, cab + d * 1.0 * s, cab + d * 3.0 * s, foc, 4.3 * s, claro, tinta)
	if costas:
		_cauda(c, j, base, piv, s, corpo, tinta)
	var ponta := _p(j["orelha"], base, piv, s) if j.has("orelha") else cab + n * 7.0 * s
	c.draw_colored_polygon(PackedVector2Array([cab + n * 3.6 * s + d * 3.0 * s,
		cab + n * 3.4 * s - d * 2.6 * s, ponta]), tinta)
	c.draw_colored_polygon(PackedVector2Array([cab + n * 2.8 * s + d * 2.2 * s,
		cab + n * 2.6 * s - d * 1.8 * s, ponta]), corpo)
	if not costas:
		c.draw_circle(foc - d * 0.8 * s, 1.5 * s, tinta, true, -1.0, true)
		c.draw_circle(cab + n * 1.2 * s + d * 2.4 * s, 1.2 * s, tinta, true, -1.0, true)


static func _cauda(c: CanvasItem, j: Dictionary, base: Vector2, piv: Vector2, s: float,
		corpo: Color, tinta: Color) -> void:
	if not (j.has("cauda_base") and j.has("cauda_ponta")):
		return
	var q := _p(j["quadril"], base, piv, s)
	var cb := _p(j["cauda_base"], base, piv, s)
	var cp := _p(j["cauda_ponta"], base, piv, s)
	c.draw_line(q, cb, tinta, 5.4 * s, true)
	c.draw_line(cb, cp, tinta, 4.2 * s, true)
	c.draw_circle(cp, 2.1 * s, tinta, true, -1.0, true)
	c.draw_line(q, cb, corpo, 4.0 * s, true)
	c.draw_line(cb, cp, corpo, 2.8 * s, true)
	c.draw_circle(cp, 1.4 * s, corpo, true, -1.0, true)


static func _quad_frontal(c: CanvasItem, j: Dictionary, base: Vector2, piv: Vector2, s: float,
		cores: Dictionary, costas: bool) -> void:
	var tinta := _cor(cores, "tinta")
	var corpo := _cor(cores, "corpo")
	var claro := _cor(cores, "claro")
	var escuro := _cor(cores, "escuro")
	var centro := _p((j["lombo"] + j["peito"]) * 0.5, base, piv, s)
	for k in ["pata_e", "pata_d"]:
		if j.has(k):
			var pe := _p(j[k], base, piv, s)
			c.draw_line(_p(j["quadril"], base, piv, s), pe, tinta, 5.4 * s, true)
			c.draw_line(_p(j["quadril"], base, piv, s), pe, corpo, 3.8 * s, true)
	_elipse(c, centro, 9.0 * s, 7.6 * s, corpo, tinta)
	_elipse(c, centro + Vector2(0, 2.4) * s, 5.4 * s, 4.4 * s, claro, Color(0, 0, 0, 0))
	for k in ["pata_e", "pata_d"]:
		if j.has(k):
			_elipse(c, _p(j[k], base, piv, s), 3.3 * s, 2.0 * s, escuro, tinta)
	var cab := _p(j["cabeca"], base, piv, s)
	_elipse(c, cab, 7.0 * s, 6.6 * s, corpo, tinta)
	for k in ["orelha_e", "orelha_d"]:
		if j.has(k):
			var ponta := _p(j[k], base, piv, s)
			var lado := -1.0 if k == "orelha_e" else 1.0
			var b := cab + Vector2(lado * 4.2, -3.8) * s
			c.draw_colored_polygon(PackedVector2Array([b + Vector2(-2.6, 1.2) * s,
				b + Vector2(2.6, 1.2) * s, ponta]), tinta)
			c.draw_colored_polygon(PackedVector2Array([b + Vector2(-1.9, 0.7) * s,
				b + Vector2(1.9, 0.7) * s, ponta + Vector2(0, 1.2) * s]), corpo)
	if not costas:
		var foc := _p(j["focinho"], base, piv, s)
		_elipse(c, foc, 3.4 * s, 2.4 * s, claro, tinta)
		_elipse(c, foc + Vector2(0, -1.4) * s, 1.5 * s, 1.1 * s, tinta, Color(0, 0, 0, 0))
		c.draw_circle(cab + Vector2(-2.7, 0.4) * s, 1.25 * s, tinta, true, -1.0, true)
		c.draw_circle(cab + Vector2(2.7, 0.4) * s, 1.25 * s, tinta, true, -1.0, true)
	elif j.has("cauda_base") and j.has("cauda_ponta"):
		var cb := _p(j["cauda_base"], base, piv, s)
		var cp := _p(j["cauda_ponta"], base, piv, s)
		c.draw_line(cb, cp, tinta, 4.6 * s, true)
		c.draw_line(cb, cp, corpo, 3.2 * s, true)
		c.draw_circle(cp, 1.6 * s, corpo, true, -1.0, true)


# --- serpente ---

static func _serpente(c: CanvasItem, rig: Dictionary, j: Dictionary, direcao: String,
		base: Vector2, piv: Vector2, s: float, cores: Dictionary) -> void:
	var tinta := _cor(cores, "tinta")
	var corpo := _cor(cores, "corpo")
	var claro := _cor(cores, "claro")
	var cadeia: Array[Vector2] = []
	for i in 8:
		var nome := "s%d" % i
		if j.has(nome):
			cadeia.append(_p(j[nome], base, piv, s))
	for extra in ["pescoco", "cabeca"]:
		if j.has(extra):
			cadeia.append(_p(j[extra], base, piv, s))
	if cadeia.size() < 2:
		return
	# contorno UMA vez (a silhueta), depois o preenchimento por cima: sem anéis
	c.draw_polyline(PackedVector2Array(cadeia), tinta, 8.0 * s, true)
	for p in cadeia:
		c.draw_circle(p, 4.0 * s, tinta, true, -1.0, true)
	for i in cadeia.size() - 1:
		var w := 6.0 if i < 4 else (4.5 if i < 7 else 3.5)
		c.draw_line(cadeia[i], cadeia[i + 1], corpo, w * s, true)
	for i in cadeia.size():
		var w2 := 6.0 if i < 5 else (4.5 if i < 8 else 3.5)
		c.draw_circle(cadeia[i], w2 * 0.5 * s, corpo, true, -1.0, true)
	if j.has("s4"):
		_elipse(c, _p(j["s4"], base, piv, s) + Vector2(0, 1.6) * s, 9.0 * s, 2.4 * s, claro, Color(0, 0, 0, 0))
	if j.has("cabeca"):
		var cab := _p(j["cabeca"], base, piv, s)
		_elipse(c, cab, 6.2 * s, 5.2 * s, corpo, tinta)
		var costas := bool(rig["directions"][direcao]["costas"])
		if not costas and j.has("boca"):
			var boca := _p(j["boca"], base, piv, s)
			c.draw_line(cab + Vector2(2.0, 0) * s, boca, tinta, 1.6 * s, true)
			c.draw_circle(cab + Vector2(2.6, -1.6) * s, 1.3 * s, tinta, true, -1.0, true)
			c.draw_circle(cab + Vector2(3.2, 0.8) * s, 0.8 * s, tinta, true, -1.0, true)


# --- ave ---

static func _ave(c: CanvasItem, rig: Dictionary, j: Dictionary, direcao: String,
		base: Vector2, piv: Vector2, s: float, cores: Dictionary) -> void:
	var tinta := _cor(cores, "tinta")
	var corpo := _cor(cores, "corpo")
	var claro := _cor(cores, "claro")
	var escuro := _cor(cores, "escuro")
	var costas := bool(rig["directions"][direcao]["costas"])
	# perna de trás
	if j.has("pata_d") and j.has("coxa_d"):
		_membro(c, _p(j["coxa_d"], base, piv, s), _p(j["coxa_d"], base, piv, s),
			_p(j["pata_d"], base, piv, s), 2.8 * s, escuro, tinta)
	# asa de trás (frontal)
	if j.has("asa_d") and j.has("asa_ponta_d"):
		_asa(c, _p(j["asa_d"], base, piv, s), _p(j["asa_ponta_d"], base, piv, s), s, escuro, tinta)
	if j.has("cauda") and j.has("cauda_ponta"):
		_membro(c, _p(j["corpo"], base, piv, s), _p(j["cauda"], base, piv, s),
			_p(j["cauda_ponta"], base, piv, s), 3.2 * s, corpo, tinta)
	var meio: Vector2 = (j["corpo"] + j["peito"]) * 0.5
	_elipse(c, _p(meio, base, piv, s), 9.4 * s, 8.2 * s, corpo, tinta)
	_elipse(c, _p(meio + Vector2(0, 2.4), base, piv, s), 5.6 * s, 4.4 * s, claro, Color(0, 0, 0, 0))
	# perna da frente
	if j.has("pata_e") and j.has("coxa_e"):
		_membro(c, _p(j["coxa_e"], base, piv, s), _p(j["coxa_e"], base, piv, s),
			_p(j["pata_e"], base, piv, s), 3.0 * s, corpo, tinta)
	# asa dobrada: lateral no corpo, frontal nas laterais
	if j.has("asa") and j.has("asa_ponta"):
		_asa(c, _p(j["asa"], base, piv, s), _p(j["asa_ponta"], base, piv, s), s, escuro, tinta)
	if j.has("asa_e") and j.has("asa_ponta_e"):
		_asa(c, _p(j["asa_e"], base, piv, s), _p(j["asa_ponta_e"], base, piv, s), s, claro, tinta)
	# pescoço, cabeça e bico
	if j.has("pescoco") and j.has("cabeca"):
		_membro(c, _p(j["peito"], base, piv, s), _p(j["pescoco"], base, piv, s),
			_p(j["cabeca"], base, piv, s), 4.6 * s, corpo, tinta)
		var cab := _p(j["cabeca"], base, piv, s)
		_elipse(c, cab, 5.6 * s, 5.0 * s, corpo, tinta)
		if not costas and j.has("bico"):
			var bic := _p(j["bico"], base, piv, s)
			var d := (bic - cab).normalized()
			var n := d.orthogonal()
			c.draw_colored_polygon(PackedVector2Array([cab + n * 2.6 * s, cab - n * 2.6 * s,
				bic + d * 3.4 * s]), Color("#e0a33c") * tinta)
			c.draw_circle(cab + n * 1.8 * s + d * 1.0 * s, 1.2 * s, tinta, true, -1.0, true)


static func _asa(c: CanvasItem, a: Vector2, ponta: Vector2, s: float, cor: Color, tinta: Color) -> void:
	_elipse(c, a, 4.6 * s, 5.6 * s, cor, tinta)
	c.draw_line(a + Vector2(0, 1.5) * s, ponta, cor.darkened(0.25), 1.2 * s, true)


# --- peças ---

static func _osso(c: CanvasItem, a: Vector2, b: Vector2, w: float, cor: Color, tinta: Color) -> void:
	c.draw_line(a, b, tinta, w + 2.0, true)
	c.draw_circle(a, (w + 2.0) * 0.5, tinta, true, -1.0, true)
	c.draw_circle(b, (w + 2.0) * 0.5, tinta, true, -1.0, true)
	c.draw_line(a, b, cor, w, true)
	c.draw_circle(a, w * 0.5, cor, true, -1.0, true)
	c.draw_circle(b, w * 0.5, cor, true, -1.0, true)


static func _membro(c: CanvasItem, a: Vector2, b: Vector2, d: Vector2, w: float,
		cor: Color, tinta: Color) -> void:
	c.draw_line(a, b, tinta, w + 2.0, true)
	c.draw_line(b, d, tinta, w + 2.0, true)
	c.draw_circle(b, (w + 2.0) * 0.5, tinta, true, -1.0, true)
	c.draw_circle(d, (w + 2.0) * 0.5, tinta, true, -1.0, true)
	c.draw_line(a, b, cor, w, true)
	c.draw_line(b, d, cor, w, true)
	c.draw_circle(a, w * 0.5, cor, true, -1.0, true)
	c.draw_circle(b, w * 0.5, cor, true, -1.0, true)
	c.draw_circle(d, w * 0.5, cor, true, -1.0, true)


static func _elipse(c: CanvasItem, centro: Vector2, rx: float, ry: float, cor: Color, contorno: Color) -> void:
	if contorno.a > 0.0:
		_elipse_preenchida(c, centro, rx + 1.2, ry + 1.2, contorno)
	_elipse_preenchida(c, centro, rx, ry, cor)


static func _elipse_preenchida(c: CanvasItem, centro: Vector2, rx: float, ry: float, cor: Color) -> void:
	var pts := PackedVector2Array()
	for i in 26:
		var a := TAU * float(i) / 26.0
		pts.append(centro + Vector2(cos(a) * rx, sin(a) * ry))
	c.draw_colored_polygon(pts, cor)


# --- debug do contrato ---

static func _ossos(c: CanvasItem, rig: Dictionary, j: Dictionary, direcao: String,
		base: Vector2, piv: Vector2, s: float) -> void:
	var perf: Dictionary = rig["profiles"][rig["directions"][direcao]["profile"]]
	for b in perf["bones"]:
		if j.has(b["a"]) and j.has(b["b"]):
			c.draw_line(_p(j[b["a"]], base, piv, s), _p(j[b["b"]], base, piv, s),
				Color(0.5, 0.83, 1.0, 0.85), 1.0, true)
	for nome in j:
		c.draw_circle(_p(j[nome], base, piv, s), 1.6, Color(0.9, 0.95, 1.0, 0.9), true, -1.0, true)


static func _ancoras(c: CanvasItem, rig: Dictionary, pose: Dictionary, direcao: String,
		base: Vector2, piv: Vector2, s: float) -> void:
	var t := E.sockets(rig, pose, direcao)
	for nome in t:
		if not t[nome]["visivel"]:
			continue
		var cor: Color = ANCORA.get(nome, Color("#ffd84d"))
		if t[nome]["z"] == "back":
			cor = Color(cor.darkened(0.25), 0.75)
		c.draw_circle(_p(t[nome]["pos"], base, piv, s), 2.2, TINTA, true, -1.0, true)
		c.draw_circle(_p(t[nome]["pos"], base, piv, s), 1.6, cor, true, -1.0, true)
