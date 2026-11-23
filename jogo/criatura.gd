extends Node2D
## A criatura na TELA (mockup 64×64 em xadrez). Só LÊ o corpo (sim/corpo.gd):
## posição, altura do terreno, z do pulo, olhar, camada, golpe e habilidade.
## Desenha:
## - sombra que encolhe no pulo; corpo que sobe no arco;
## - nariz (olhar);
## - golpe: cone na direção do golpe (o ataque final vai no inimigo marcado);
## - habilidade: terra voando quando cava; anel quando é outra habilidade;
## - carga do tiro: arco amarelo que fecha em volta dela (`corpo.carga()`);
## - subsolo: apagada, por cima da camada escura.
## v0.9: não há mais rastro de esquiva nem anel de defesa — a esquiva é o
## próprio caminhar e não existe gesto de defesa.

const Mock := preload("res://jogo/mock.gd")
const V := preload("res://sim/visibilidade.gd")
const Esq := preload("res://sim/esqueleto.gd")
const Dir := preload("res://sim/direcao.gd")
const Rigs := preload("res://jogo/rigs.gd")
const PeleGeo := preload("res://jogo/pele_geometrica.gd")
const Anim := preload("res://sim/animacao.gd")
const AnimData := preload("res://jogo/animacoes.gd")
const ModDraw := preload("res://jogo/modulos.gd")

var corpo: RefCounted
var mundo: RefCounted
var inclinacao := 1.0
var _desnivel := 0.0
var _tempo := 0.0
var _sprite: Texture2D
# Pele geométrica (F2): vazio = mock de xadrez. O rig vem de dados/rig/*.json.
var _rig: Dictionary = {}
var _rig_id := ""
var _rig_debug := false
var _tempo_pele := 0.0
var _ultima_pos := Vector2.ZERO
var _andando := false
# F3: máquina de estados da animação (catálogo em dados/animacoes.json).
var _anim_cat: Dictionary = {}
var _anim_mem: Dictionary = {}
var _clipe_forcado := ""
var _fase_forcada := -1.0
# F4: módulos/efeitos presos a socket (dados/modulos.json; cosméticos).
var _mod_cat: Dictionary = {}
var _mod_ids := PackedStringArray()
var _no_ar_antes := false
var _saltou := false
var _pousou := false


func _ready() -> void:
	_sprite = Mock.criatura(Color("#d9752f"), Color("#f2a45c"), Color("#4a2010"))
	_anim_cat = AnimData.carregar()
	_mod_cat = ModDraw.catalogo()
	if corpo != null:
		_ultima_pos = corpo.pos
	# F5 (teste de movimento): a criatura do jogo normal é a pele geométrica.
	# `--mock` mantém o xadrez antigo; as flags de demo (--geo-*) trocam depois.
	if not ("--mock" in OS.get_cmdline_user_args()):
		ativar_pele_geometrica("canino")


## Liga a pele geométrica (F2). Rig inválido/ausente mantém o mock (falha fechada).
func ativar_pele_geometrica(id: String = "canino", debug := false) -> bool:
	var m := Rigs.carregar(id)
	if m.is_empty():
		push_error("pele geométrica recusada: rig " + id)
		return false
	_rig = m
	_rig_id = id
	_rig_debug = debug
	_anim_cat = Anim.para_rig(AnimData.carregar(), m)
	_anim_mem = {}
	_tempo_pele = 0.0
	queue_redraw()
	return true


func pele_geometrica_ativa() -> bool:
	return not _rig.is_empty()


## Só na demo: congela um clipe do catálogo para inspecionar o desenho.
func forcar_clipe(id: String, fase := 0.5) -> void:
	_clipe_forcado = id
	_fase_forcada = fase


## Módulos/efeitos cosméticos presos a socket; nada concede habilidade.
func ativar_modulos(ids: PackedStringArray) -> void:
	_mod_ids = ids
	queue_redraw()


func _process(delta: float) -> void:
	if corpo == null:
		return
	_tempo += delta
	_tempo_pele += delta
	var desloc: float = (corpo.pos - _ultima_pos).length()
	_ultima_pos = corpo.pos
	_andando = desloc > 0.35
	var ar: bool = corpo.no_ar()
	_saltou = ar and not _no_ar_antes
	_pousou = (not ar) and _no_ar_antes
	_no_ar_antes = ar
	if not _anim_cat.is_empty():
		_anim_mem = Anim.resolver(Anim.retrato(corpo, _andando, _saltou, _pousou),
			_anim_cat, _anim_mem, _tempo_pele * 1000.0)
	position = corpo.pos
	var celula: Vector2i = mundo.celula_de(corpo.pos)
	var alt: float = mundo.altura(celula) if corpo.camada == "superficie" else 1.0
	_desnivel = V.aproximar(_desnivel, Mock.desnivel(alt, inclinacao) * inclinacao, delta, 14.0)
	var subsolo: bool = corpo.camada == "subsolo"
	z_as_relative = not subsolo
	z_index = 20 if subsolo else 0
	queue_redraw()


## Onde aparece na tela (mundo): chão + desnível − altura do pulo.
func ponto_visual() -> Vector2:
	return corpo.pos + Vector2(0, _desnivel - corpo.z)


func _draw() -> void:
	if corpo == null:
		return
	var chao := Vector2(0, _desnivel)
	var meu := chao - Vector2(0, corpo.z)
	var subsolo: bool = corpo.camada == "subsolo"
	var s := clampf(1.0 - corpo.z / 70.0, 0.4, 1.0)
	draw_set_transform(chao, 0.0, Vector2(s, s * 0.35))
	draw_circle(Vector2.ZERO, 20.0, Color(0, 0, 0, 0.3), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	var cor := Color(0.45, 0.45, 0.55, 0.85) if subsolo else Color.WHITE
	# ATORDOADA (v0.14): o bicho treme e fica avermelhado — o golpe tira o comando
	var tonta: bool = corpo.atordoado()
	if tonta:
		cor = Color(1.0, 0.58, 0.52)
		meu += Vector2(sin(_tempo * 57.0) * 2.2, 0.0)
	var c := meu + Vector2(0, -20)
	if not _rig.is_empty():
		# F2/F3: a direção sai do olhar em OITO setores; o clipe e a fase vêm da
		# máquina de estados (ou do clipe forçado, só na demo); o rig manda no
		# desenho e o golpe sai da âncora `boca`.
		var dir := Dir.setor(corpo.olhar)
		var clipe := String(_anim_mem.get("id", "idle"))
		if _clipe_forcado != "":
			clipe = _clipe_forcado
		if not (_rig.get("clips", {}) as Dictionary).has(clipe):
			clipe = "walk" if _andando else "idle"
		var fase := _fase_forcada
		if fase < 0.0:
			fase = Anim.fase(_anim_mem, _anim_cat, _tempo_pele * 1000.0)
		var salto_correndo := bool(_anim_mem.get("salto_correndo", false)) and _clipe_forcado == ""
		var pose := Esq.pose(_rig, dir, fase, clipe, salto_correndo)
		ModDraw.desenhar(self, _rig, pose, dir, meu, _mod_cat, _mod_ids, "back")
		PeleGeo.desenhar(self, _rig, dir, fase, clipe, meu, cor, _rig_debug, 1.0, pose)
		ModDraw.desenhar(self, _rig, pose, dir, meu, _mod_cat, _mod_ids, "front")
		_desenhar_eventos(meu, pose, dir, fase, clipe)
		c = _ancora_boca(meu, dir, pose)
		if _rig_debug:
			var rotulo := clipe + (" (forçado)" if _clipe_forcado != "" else " · " + String(_anim_mem.get("id", "")))
			draw_string(ThemeDB.fallback_font, meu + Vector2(-30, -58), rotulo,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.9))
	else:
		draw_texture_rect(_sprite, Rect2(meu + Vector2(-32, -52), Vector2(64, 64)), false, cor)
		var o: Vector2 = corpo.olhar if corpo.olhar.length() > 0.01 else Vector2.RIGHT
		draw_colored_polygon(PackedVector2Array([c + o * 30.0, c + o * 18.0 + o.orthogonal() * 7.0, c + o * 18.0 - o.orthogonal() * 7.0]), Color(1, 1, 1, 0.9))
	_desenhar_acoes(c)
	if tonta:
		_desenhar_estrelas(Vector2(0, -66))


## Estrelinhas girando sobre a cabeça: o corpo não obedece enquanto isso.
## Faísca/onda nas janelas de evento do clipe (por TEMPO, não por quadro).
## É só desenho: dano e alcance continuam em sim/corpo.gd.
func _desenhar_eventos(base: Vector2, pose: Dictionary, direcao: String, fase: float, clipe: String) -> void:
	if _anim_cat.is_empty() or _mod_cat.is_empty():
		return
	var c := Anim.clipe(_anim_cat, clipe)
	if c.is_empty():
		return
	var dur := maxf(float(c["duracao_ms"]), 0.001)
	var ms := fase * dur
	for j in Anim.janela_ativa(_anim_cat, clipe, ms):
		var alfa := 1.0 - clampf((ms - float(j["ms"])) / 150.0, 0.0, 1.0)
		ModDraw.desenhar_efeito(self, _rig, pose, direcao, base, String(j["socket"]), String(j["evento"]), _mod_cat, alfa)


## O golpe sai da ÂNCORA "boca" quando ela existe; senão do centro do corpo.
func _ancora_boca(base: Vector2, direcao: String, pose: Dictionary) -> Vector2:
	var a := Esq.socket(_rig, pose, direcao, "boca")
	if a.is_empty():
		return base + Vector2(0, -20)
	var piv := Vector2(float(_rig["pivot_px"][0]), float(_rig["pivot_px"][1]))
	return base + ((a["pos"] as Vector2) - piv)


func _desenhar_estrelas(base: Vector2) -> void:
	for i in 3:
		var a := _tempo * 7.0 + i * TAU / 3.0
		var p := base + Vector2(cos(a) * 15.0, sin(a) * 4.0 - 4.0)
		draw_circle(p, 2.4, Color(1.0, 0.9, 0.4, 0.95), true, -1.0, true)


func _desenhar_acoes(c: Vector2) -> void:
	var g: Dictionary = corpo.golpe_ativo()
	if not g.is_empty():
		var d: Vector2 = g["dir"]
		var meio := d.angle()
		var arco := deg_to_rad(float(g["arco"])) / 2.0
		var alcance := float(g["alcance"])
		var pts := PackedVector2Array([c])
		for i in 17:
			pts.append(c + Vector2.from_angle(meio - arco + 2.0 * arco * i / 16.0) * alcance)
		var especial: bool = corpo.ataque == "especial"
		var cor_cone := Color(0.4, 0.6, 1.0, 0.45) if especial else Color(1.0, 0.5, 0.12, 0.45)
		var cor_linha := Color(0.6, 0.9, 1.0, 0.95) if especial else Color(1.0, 0.85, 0.4, 0.95)
		draw_colored_polygon(pts, cor_cone)
		draw_polyline(pts.slice(1), cor_linha, 2.0, true)
	if corpo.carregando():
		# CARGA do tiro (v0.18): o aro vai de 20 a 30 px e o arco fecha com a
		# carga — o corpo só diz quanto (0..1), o desenho é daqui.
		var cg := clampf(corpo.carga(), 0.0, 1.0)
		var raio := lerpf(20.0, 30.0, cg)
		draw_arc(c, 30.0, 0.0, TAU, 40, Color(1.0, 0.85, 0.25, 0.22), 2.0, true)
		draw_arc(c, raio, -PI / 2.0, -PI / 2.0 + TAU * cg, 40,
			Color(1.0, 0.9, 0.3, 0.95), 3.0, true)
	if corpo.habilidade_ativa() and not corpo.escavando:
		# habilidade de si mesmo que não é a cavar: anel pulsando em volta
		var raio := 30.0 + 4.0 * sin(_tempo * 10.0)
		draw_arc(c, raio, 0.0, TAU, 40, Color(0.55, 1.0, 0.6, 0.9), 3.0, true)
		draw_circle(c, raio, Color(0.55, 1.0, 0.6, 0.12), true, -1.0, true)
	if corpo.escavando:
		for i in 6:
			var a := _tempo * 9.0 + i * TAU / 6.0
			draw_circle(c + Vector2(cos(a) * 26.0, 18.0 + sin(a) * 8.0 - absf(sin(_tempo * 12.0 + i)) * 14.0), 3.0, Color("#7a5230"), true, -1.0, true)
