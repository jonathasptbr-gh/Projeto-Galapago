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
## Fase A (3D): o cão usa `dados/rig/canino3d.json` e `sim/esqueleto3d.gd`;
## serpente/ave continuam no rig 2D e `--canino-2d` força o 2D no cão.

const Mock := preload("res://jogo/mock.gd")
const V := preload("res://sim/visibilidade.gd")
const Esq := preload("res://sim/esqueleto.gd")
const Dir := preload("res://sim/direcao.gd")
const Rigs := preload("res://jogo/rigs.gd")
const PeleGeo := preload("res://jogo/pele_geometrica.gd")
const Anim := preload("res://sim/animacao.gd")
const AnimData := preload("res://jogo/animacoes.gd")
const ModDraw := preload("res://jogo/modulos.gd")
const Esq3 := preload("res://sim/esqueleto3d.gd")
# Teto do amortecimento angular da CÂMERA de apresentação (rad/s). Só se
# aplica a curvas suaves; ataque/salto de olhar vai direto ao alvo.
const VEL_YAW_RAD_S := 18.0
const Rigs3D := preload("res://jogo/rigs3d.gd")
const PeleGeo3D := preload("res://jogo/pele_geometrica3d.gd")

var corpo: RefCounted
var mundo: RefCounted
var inclinacao := 1.0
var _desnivel := 0.0
var _tempo := 0.0
var _sprite: Texture2D
# Pele geométrica (F2): vazio = mock de xadrez. O rig vem de dados/rig/*.json.
var _rig: Dictionary = {}
var _rig_id := ""
# Fase A do plano 3D: esqueleto de juntas/ossos 3D projetado em 2D. Vazio =
# pele 2D/mock; o cão usa o 3D por padrão e `--canino-2d` volta ao rig 2D.
var _rig3d: Dictionary = {}
var _rig3d_id := ""
var _rig_debug := false
var _tempo_pele := 0.0
# Yaw de APRESENTAÇÃO (graus) com suavização angular só visual; NaN = ainda
# não inicializado. Não é `corpo.olhar` e não decide setor/regra nenhuma.
var _yaw_vis := NAN
# TRANSIÇÃO ENTRE CLIPES (só apresentação, v0.31.0): a pose do quadro da troca
# é misturada com a nova por `TRANSICAO_S`; nada disso toca na simulação.
const TRANSICAO_S := 0.08
var _pose_de: Dictionary = {}
var _pose_ultima: Dictionary = {}
var _clipe_pose := ""
var _inicio_transicao := -1.0
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
	# `--mock` mantém o xadrez antigo; `--canino-2d` força o rig 2D (debug e
	# fallback) e as flags de demo (--geo-*) trocam depois. O cão nasce no
	# esqueleto 3D; serpente e ave continuam no rig 2D.
	var args := OS.get_cmdline_user_args()
	if not ("--mock" in args):
		if "--canino-2d" in args:
			ativar_pele_geometrica("canino")
		elif not ativar_esqueleto3d("canino3d"):
			ativar_pele_geometrica("canino")


## Liga a pele geométrica (F2). Rig inválido/ausente mantém o mock (falha fechada).
func ativar_pele_geometrica(id: String = "canino", debug := false) -> bool:
	var m := Rigs.carregar(id)
	if m.is_empty():
		push_error("pele geométrica recusada: rig " + id)
		return false
	_rig = m
	_rig_id = id
	_rig3d = {}
	_rig3d_id = ""
	_rig_debug = debug
	_anim_cat = Anim.para_rig(AnimData.carregar(), m)
	_anim_mem = {}
	_tempo_pele = 0.0
	_yaw_vis = NAN
	_pose_de = {}
	_pose_ultima = {}
	_clipe_pose = ""
	_inicio_transicao = -1.0
	queue_redraw()
	return true


## Liga o esqueleto 3D (Fase A). Rig inválido/ausente devolve false e NÃO
## troca a pele atual (o `_ready` cai para o rig 2D; falha fechada).
func ativar_esqueleto3d(id: String = "canino3d", debug := false) -> bool:
	var m := Rigs3D.carregar(id)
	if m.is_empty():
		push_error("esqueleto 3D recusado: rig " + id)
		return false
	_rig3d = m
	_rig3d_id = id
	_rig = {}
	_rig_id = ""
	_rig_debug = debug
	_anim_cat = Anim.para_rig(AnimData.carregar(), m)
	_anim_mem = {}
	_tempo_pele = 0.0
	_yaw_vis = NAN
	_pose_de = {}
	_pose_ultima = {}
	_clipe_pose = ""
	_inicio_transicao = -1.0
	queue_redraw()
	return true


func esqueleto3d_ativo() -> bool:
	return not _rig3d.is_empty()


func pele_geometrica_ativa() -> bool:
	return not _rig.is_empty() or not _rig3d.is_empty()


## Ângulo CONTÍNUO do olhar para a câmera 3D, em graus: 0 = east, 90 = south,
## 180 = west, 270 = north. É só apresentação: a simulação continua usando
## `Dir.setor`. Olhar zero/inválido cai no setor (south), como `Dir.setor`.
func yaw_apresentacao() -> float:
	if corpo == null:
		return Esq3.yaw_graus("south")
	var olhar: Vector2 = corpo.olhar
	if not is_finite(olhar.x) or not is_finite(olhar.y) or olhar.length() < 0.001:
		return Esq3.yaw_graus(Dir.setor(Vector2.ZERO))
	return fposmod(rad_to_deg(olhar.angle()), 360.0)


## Yaw que o DESENHO usa agora (já amortecido). Fora do `_process`, cai no
## alvo; é o mesmo valor que `_draw` passa ao skin.
func yaw_desenho() -> float:
	if is_finite(_yaw_vis):
		return _yaw_vis
	return yaw_apresentacao()


## Atualiza o yaw de desenho. Ataque ativo (`corpo.ataque != ""`) ou salto
## bruto do olhar > 90° vai DIRETO ao alvo no mesmo quadro; só curvas suaves
## passam pelo passo máximo, que usa o `delta` real (18 rad/s), nunca um passo
## fixo. Não altera `corpo.olhar`.
func _atualizar_yaw_apresentacao(delta: float) -> void:
	var alvo := yaw_apresentacao()
	if not is_finite(_yaw_vis):
		_yaw_vis = alvo
		return
	var salto := absf(wrapf(alvo - _yaw_vis, -180.0, 180.0))
	if (corpo != null and String(corpo.ataque) != "") or salto > 90.0:
		_yaw_vis = alvo
		return
	_yaw_vis = _suavizar_yaw(_yaw_vis, alvo, maxf(delta, 0.0) * rad_to_deg(VEL_YAW_RAD_S))


## Registra o clipe DESENHADO. Troca de clipe guarda a última pose desenhada
## como origem; clipe repetido NÃO reinicia a transição.
func _registrar_clipe(clipe: String, agora: float) -> void:
	if _clipe_pose != "" and _clipe_pose != clipe and not _pose_ultima.is_empty():
		_pose_de = _pose_ultima
		_inicio_transicao = agora
	_clipe_pose = clipe


## Peso da mistura: 0→1 linear em `TRANSICAO_S`. No primeiro quadro a pose
## anda só ~delta/0,08 do caminho (≈0,21 a 60 fps => <2 px). Só apresentação.
func _peso_transicao(t: float) -> float:
	return clampf(t / TRANSICAO_S, 0.0, 1.0)


func _pose_com_transicao(pose_atual: Dictionary, agora: float) -> Dictionary:
	if _inicio_transicao < 0.0 or _pose_de.is_empty():
		return pose_atual
	var decorrido := agora - _inicio_transicao
	var t := decorrido / TRANSICAO_S
	if t >= 1.0:
		_inicio_transicao = -1.0
		_pose_de = {}
		return pose_atual
	return Esq3.misturar(_pose_de, pose_atual, _peso_transicao(decorrido))


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
	# CÂMERA 3D: segue o olhar já suavizado pelo corpo. Ataque/salto de olhar
	# vai direto; só curvas suaves são amortecidas (18 rad/s × delta).
	_atualizar_yaw_apresentacao(delta)
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
	var tem_rig: bool = not _rig.is_empty() or not _rig3d.is_empty()
	if tem_rig:
		# F2/F3/Fase A: a direção sai do olhar em OITO setores; o clipe e a fase
		# vêm da máquina de estados (ou do clipe forçado, só na demo); o rig
		# manda no desenho e o golpe sai da âncora `boca`.
		var dir := Dir.setor(corpo.olhar)
		var clipe := String(_anim_mem.get("id", "idle"))
		if _clipe_forcado != "":
			clipe = _clipe_forcado
		var clips_rig: Dictionary = (_rig3d if not _rig3d.is_empty() else _rig).get("clips", {})
		if not clips_rig.has(clipe):
			clipe = "walk" if _andando else "idle"
		var fase := _fase_forcada
		if fase < 0.0:
			fase = Anim.fase(_anim_mem, _anim_cat, _tempo_pele * 1000.0)
		var salto_correndo := bool(_anim_mem.get("salto_correndo", false)) and _clipe_forcado == ""
		if not _rig3d.is_empty():
			# O esqueleto 3D projeta; o adaptador entrega rig/pose no MESMO
			# formato que módulos e VFX já consomem (socket por nome). A
			# direção decide sockets; o yaw contínuo decide só a câmera.
			var pose3 := Esq3.pose(_rig3d, dir, fase, clipe, salto_correndo, yaw_desenho())
			if pose3.is_empty():
				push_error("pose 3D vazia: " + dir + "/" + clipe)
			else:
				# Transição de clipe: a origem é a ÚLTIMA pose desenhada; o
				# peso vai de 0 a 1 em `TRANSICAO_S` (linear), então o primeiro
				# quadro anda ~1,5 px. Clipe forçado (demo) não mistura.
				if _clipe_forcado == "":
					_registrar_clipe(clipe, _tempo_pele)
					pose3 = _pose_com_transicao(pose3, _tempo_pele)
				else:
					_clipe_pose = clipe
					_inicio_transicao = -1.0
					_pose_de = {}
				_pose_ultima = pose3
				var adapt := Esq3.adaptar_modulos(_rig3d, pose3, dir)
				var rig_mod: Dictionary = adapt["rig"]
				var pose_mod: Dictionary = adapt["pose"]
				ModDraw.desenhar(self, rig_mod, pose_mod, dir, meu, _mod_cat, _mod_ids, "back")
				PeleGeo3D.desenhar(self, _rig3d, pose3, meu, cor, _rig_debug, 1.0)
				ModDraw.desenhar(self, rig_mod, pose_mod, dir, meu, _mod_cat, _mod_ids, "front")
				_desenhar_eventos(meu, rig_mod, pose_mod, dir, fase, clipe)
				c = _ancora_boca(meu, rig_mod, pose_mod, dir)
		else:
			var pose := Esq.pose(_rig, dir, fase, clipe, salto_correndo)
			ModDraw.desenhar(self, _rig, pose, dir, meu, _mod_cat, _mod_ids, "back")
			PeleGeo.desenhar(self, _rig, dir, fase, clipe, meu, cor, _rig_debug, 1.0, pose)
			ModDraw.desenhar(self, _rig, pose, dir, meu, _mod_cat, _mod_ids, "front")
			_desenhar_eventos(meu, _rig, pose, dir, fase, clipe)
			c = _ancora_boca(meu, _rig, pose, dir)
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
func _desenhar_eventos(base: Vector2, rig: Dictionary, pose: Dictionary, direcao: String, fase: float, clipe: String) -> void:
	if _anim_cat.is_empty() or _mod_cat.is_empty():
		return
	var c := Anim.clipe(_anim_cat, clipe)
	if c.is_empty():
		return
	var dur := maxf(float(c["duracao_ms"]), 0.001)
	var ms := fase * dur
	for j in Anim.janela_ativa(_anim_cat, clipe, ms):
		var alfa := 1.0 - clampf((ms - float(j["ms"])) / 150.0, 0.0, 1.0)
		ModDraw.desenhar_efeito(self, rig, pose, direcao, base, String(j["socket"]), String(j["evento"]), _mod_cat, alfa)


## O golpe sai da ÂNCORA "boca" quando ela existe; senão do centro do corpo.
func _ancora_boca(base: Vector2, rig: Dictionary, pose: Dictionary, direcao: String) -> Vector2:
	var a := Esq.socket(rig, pose, direcao, "boca")
	if a.is_empty():
		return base + Vector2(0, -20)
	var piv := Vector2(float(rig["pivot_px"][0]), float(rig["pivot_px"][1]))
	return base + ((a["pos"] as Vector2) - piv)


## Lerp angular em graus com wrap; `passo_max` é o quanto pode girar no quadro.
func _suavizar_yaw(atual: float, alvo: float, passo_max: float) -> float:
	var d := wrapf(alvo - atual, -180.0, 180.0)
	if absf(d) <= passo_max:
		return fposmod(alvo, 360.0)
	return fposmod(atual + signf(d) * passo_max, 360.0)


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
