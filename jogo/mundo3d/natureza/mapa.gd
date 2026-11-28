extends Node3D
## Mata úmida: o DESENHO do mapa de testes NATUREZA. Reconstrução idempotente,
## semente fixa. O que bloqueia (riacho, vaus, trilha, árvores, troncos caídos)
## vem de sim/natureza.gd — a mesma fonte da regra; aqui só se desenha e se
## enfeita (samambaias, sub-bosque, capim, pedras pequenas, folhas no chão).
## MultiMeshes por família/variante: não há um nó por planta.
##
## Espaço LOCAL (o de sim/natureza.gd): chão andável PLANO em y = 0; só o leito
## do riacho desce. No jogo o nó vai em `Natureza.origem_3d()` (chão em
## y = 0,4, célula da sim = 1 unidade); construído sozinho (testes) fica na origem.
##
## Contrato para o jogo:
## - `construir(semente)`; `ligar_chao(textura, ret)` — o MAPA DO CHÃO no solo
##   (trilha, mira, perigos pintados na terra, como na ilha);
## - `definir_foco(p)` — COPA VAZADA em volta de `p` (espaço da câmera): folhas e
##   madeira das árvores entre a câmera e `p` somem por dither; `desligar_foco()`;
## - `ambientar(env, sol, nevoa)` — luz e céu da mata (estático; a Fundação não
##   chama).

const Natureza := preload("res://sim/natureza.gd")
const Biblioteca := preload("res://jogo/mundo3d/natureza/malhas.gd")
const SEMENTE := Natureza.SEMENTE
const LIMITE_X := 23.0
const Z_INICIO := -39.0
const Z_FIM := 23.0
const PASSO := 0.5
const AGUA_Y := -0.12
## leito de cascalho do vau: um pouco acima da água (o vau aparece seco)
const VAU_Y := -0.05
## mata distante em volta do mapa (unidades): a vista alta não vê o vazio
const MARGEM_FUNDO := 40.0
## lado (unidades) do setor de cada MultiMesh (descarte por câmera)
const SETOR := 12.0

var estatisticas: Dictionary = {}
var lotes: Array[MultiMeshInstance3D] = []
## nome do lote → as transformações das instâncias (o servidor de render
## headless não guarda as da MultiMesh: os testes leem daqui)
var registro: Dictionary = {}
## materiais com COPA VAZADA (folhas e madeira das árvores)
var _mats_foco: Array[ShaderMaterial] = []
## materiais que o VENTO balança; ver docs/gdd/vento.md
var _mats_vento: Array[ShaderMaterial] = []
var _mat_solo: ShaderMaterial

## P25/2.1: escolha de sessão, nunca persistida. Só as copas trocam de emissor.
enum Sombras { COMPLETAS, SIMPLIFICADAS, DESLIGADAS }
const NOMES_SOMBRAS := ["COMPLETAS", "SIMPLIFICADAS", "DESLIGADAS"]
var modo_sombras := Sombras.COMPLETAS
var _copas: Array[MultiMeshInstance3D] = []
var proxies: Array[MultiMeshInstance3D] = []


func definir_sombras(modo: int) -> void:
	modo_sombras = clampi(modo, Sombras.COMPLETAS, Sombras.DESLIGADAS)
	var simplificadas := modo_sombras == Sombras.SIMPLIFICADAS
	for copa in _copas:
		copa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if simplificadas else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for proxy in proxies:
		proxy.visible = simplificadas


static func rio_x(z: float) -> float:
	return Natureza.rio_x(z)


static func largura_rio(z: float) -> float:
	return Natureza.largura_rio(z)


static func trilha_x(z: float) -> float:
	return Natureza.trilha_x(z)


## Altura local do chão: 0 em toda a terra andável; o leito desce até −0,48 só
## dentro da faixa de água da regra (largura + folga), e o vau sobe a VAU_Y.
static func altura(x: float, z: float) -> float:
	var d := absf(x - rio_x(z)) - largura_rio(z)
	var margem := smoothstep(-0.5, Natureza.FOLGA_AGUA, d)
	var leito := lerpf(-0.48, 0.0, margem)
	var v := Natureza.vau(z)
	if v > 0.0 and leito < VAU_Y:
		leito = lerpf(leito, VAU_Y, v)
	return leito


static func ponto(x: float, z: float) -> Vector3:
	return Vector3(x, altura(x, z), z)


## Luz e céu da mata: verdes vivos, sem lavagem cinza. `nevoa` serve a uma vista
## em perspectiva (o piloto, removido em 2026-11-26); na vista alta do jogo fica desligada.
static func ambientar(env: Environment, sol: DirectionalLight3D, nevoa := false) -> void:
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#9fd3e6")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b8dcc8")
	env.ambient_light_energy = 0.55
	env.ambient_light_sky_contribution = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.04
	env.fog_enabled = nevoa
	env.fog_light_color = Color("#a9d4d8")
	env.fog_light_energy = 0.9
	env.fog_density = 0.0028
	sol.rotation_degrees = Vector3(-50.0, -32.0, 0.0)
	sol.light_color = Color("#fff0cf")
	sol.light_energy = 1.25


func construir(semente := SEMENTE) -> void:
	for filho in get_children():
		filho.free()
	lotes.clear()
	_copas.clear()
	proxies.clear()
	registro.clear()
	_mats_foco.clear()
	_mats_vento.clear()
	estatisticas = {"semente": semente, "instancias": 0, "lotes": 0, "arvores": 0,
		"triangulos_instanciados": 0, "vertices_armazenados": 0}
	var r := RandomNumberGenerator.new()
	r.seed = semente
	_mat_solo = Biblioteca.material()
	_terreno()
	_fundo()
	_agua()
	var casca := Biblioteca.material()
	var madeira := Biblioteca.material()
	var folha_arvore := Biblioteca.material(true)
	var folha := Biblioteca.material(true)
	var folha_capim := Biblioteca.material(true)
	_mats_foco.append(madeira)
	_mats_foco.append(folha_arvore)
	# VENTO: a copa é alta e anda mais; samambaia/arbusto, menos; capim, pouco e
	# curto (a base fica parada por `vento_altura`).
	for par in [[folha_arvore, 9.0, 0.30], [folha, 0.7, 0.13], [folha_capim, 0.30, 0.09]]:
		par[0].set_shader_parameter("vento_altura", par[1])
		par[0].set_shader_parameter("vento_amplitude", par[2])
		_mats_vento.append(par[0])
	# Estrato arbóreo: as MESMAS árvores que bloqueiam na sim.
	var posicoes: Array[Transform3D] = []
	for a in Natureza.arvores(semente):
		posicoes.append(_transforme(ponto(a["x"], a["z"]) - Vector3.UP * 0.08, a["yaw"],
			Vector3.ONE * float(a["escala"])))
	estatisticas["arvores"] = posicoes.size()
	# moldura: uma variante SIMPLES (~1/4 das folhas), só decorativa
	var moldura: Array[Transform3D] = []
	for t in arvores_moldura(semente):
		moldura.append(_transforme(Vector3(t.x, -0.1, t.z), t.y, Vector3.ONE * 1.05))
	estatisticas["arvores_moldura"] = moldura.size()
	var simples: Dictionary = Biblioteca.arvore(semente + 909, true)
	_lote("Moldura_troncos", simples["madeira"], moldura, madeira, r)
	_lote("Moldura_folhas", simples["folhas"], moldura, folha_arvore, r, true, simples["sombra"])
	for variante in range(4):
		var arv: Dictionary = Biblioteca.arvore(semente + variante * 101)
		var ts: Array[Transform3D] = []
		for i in range(variante, posicoes.size(), 4):
			ts.append(posicoes[i])
		_lote("Troncos_%d" % variante, arv["madeira"], ts, madeira, r)
		_lote("Folhas_%d" % variante, arv["folhas"], ts, folha_arvore, r, true, arv["sombra"])
	# Samambaias preferem margem; arbustos e capim enchem a mata.
	for variante in range(3):
		var samambaias: Array[Transform3D] = []
		var arbustos: Array[Transform3D] = []
		var capins: Array[Transform3D] = []
		for i in range(49):
			var z := r.randf_range(-31.0, 17.0)
			var lado := -1.0 if i % 2 == 0 else 1.0
			var x := rio_x(z) + lado * r.randf_range(1.9, 8.0)
			if not _vegetavel(x, z):
				continue
			samambaias.append(_transforme(ponto(x, z), r.randf_range(0.0, TAU),
				Vector3.ONE * r.randf_range(0.55, 1.13)))
		for i in range(95):
			var x := r.randf_range(-21.0, 21.0)
			var z := r.randf_range(-37.0, 20.0)
			if not _vegetavel(x, z):
				continue
			arbustos.append(_transforme(ponto(x, z), r.randf_range(0.0, TAU),
				Vector3.ONE * r.randf_range(0.55, 1.30)))
		for i in range(270):
			var x := r.randf_range(-22.0, 22.0)
			var z := r.randf_range(-38.0, 22.0)
			if not _vegetavel(x, z):
				continue
			capins.append(_transforme(ponto(x, z), r.randf_range(0.0, TAU),
				Vector3.ONE * r.randf_range(0.7, 1.4)))
		_lote("Samambaias_%d" % variante, Biblioteca.samambaia(semente + variante), samambaias, folha, r)
		_lote("Sub_bosque_%d" % variante, Biblioteca.sub_bosque(semente + variante), arbustos, folha, r)
		_lote("Gramineas_%d" % variante, Biblioteca.capim(semente + variante), capins, folha_capim, r, false)
	# Pedras: seixos nos meandros (fora dos vaus) e pedras chatas de passagem
	# nos vaus. Pequenas: decoração, não bloqueiam (a regra é da sim).
	for variante in range(3):
		var pedras: Array[Transform3D] = []
		for i in range(45):
			var z := r.randf_range(-35.0, 20.0)
			var lado := -1.0 if i % 2 == 0 else 1.0
			var x := rio_x(z) + lado * r.randf_range(0.85, 2.0)
			var escala := r.randf_range(0.18, 0.58)
			if Natureza.vau(z) > 0.0:
				continue
			pedras.append(_transforme(ponto(x, z) - Vector3.UP * 0.03, r.randf_range(0.0, TAU),
				Vector3(escala * 1.2, escala, escala)))
		for zv in Natureza.VAUS:
			for k in range(5):
				if k % 3 != variante:
					continue
				var u := -1.0 + k * 0.5
				var z := zv + r.randf_range(-0.45, 0.45)
				var x := rio_x(z) + u * largura_rio(z)
				var e := r.randf_range(0.22, 0.32)
				pedras.append(_transforme(Vector3(x, VAU_Y - 0.06, z), r.randf_range(0.0, TAU),
					Vector3(e * 1.4, e * 0.45, e * 1.2)))
		_lote("Rochas_%d" % variante, Biblioteca.rocha(semente + variante), pedras, casca, r)
	# Troncos caídos: os MESMOS da sim (bloqueiam as células que ocupam).
	var troncos: Array[Transform3D] = []
	for t in Natureza.TRONCOS:
		troncos.append(_transforme(ponto(t[0], t[1]), t[2], Vector3.ONE * float(t[3])))
	_lote("Troncos_caidos", Biblioteca.tronco(semente), troncos, casca, r)
	_serrapilheira(r)
	estatisticas["lotes"] = lotes.size()
	estatisticas["familias"] = registro.size()
	definir_sombras(modo_sombras)


func ligar_chao(textura: Texture2D, ret: Vector4) -> void:
	_mat_solo.set_shader_parameter("usar_chao", textura != null)
	_mat_solo.set_shader_parameter("chao", textura)
	_mat_solo.set_shader_parameter("chao_ret", ret)


## COPA VAZADA em volta de `p` (espaço da câmera). `raio` vem em unidades de
## mundo: o `main` o encolhe junto com a aproximação, de modo que a abertura
## cresça em PX de tela com o zoom (2,6 na vista de longe ⇒ ~133 px; 1,45 na
## máxima aproximação ⇒ ~232 px) sem apagar a mata inteira no perto.
func definir_foco(p: Vector3, raio := 2.6) -> void:
	for m in _mats_foco:
		m.set_shader_parameter("usar_foco", true)
		m.set_shader_parameter("foco", p)
		m.set_shader_parameter("raio_foco", maxf(raio, 0.01))


func desligar_foco() -> void:
	for m in _mats_foco:
		m.set_shader_parameter("usar_foco", false)


## VENTO: o pacote de `sim/vento.gd`.uniformizar(), nos materiais de folha.
## `frente` vem em coordenadas LOCAIS do mapa; o shader trabalha em mundo, então
## o deslocamento do nó entra aqui (ver docs/gdd/vento.md).
func aplicar_vento(u: Dictionary) -> void:
	var org: Vector3 = global_position if is_inside_tree() else position
	var direcao: Vector2 = u.get("direcao", Vector2.RIGHT)
	var frente: Vector2 = u.get("frente", Vector2.ZERO)
	var frente_mundo := frente + Vector2(org.x, org.z)
	for m in _mats_vento:
		m.set_shader_parameter("vento_direcao", direcao)
		m.set_shader_parameter("vento_forca", float(u.get("forca", 0.0)))
		m.set_shader_parameter("vento_frente", frente_mundo)
		m.set_shader_parameter("vento_frente_forca", float(u.get("frente_forca", 0.0)))
		m.set_shader_parameter("vento_frente_largura", float(u.get("frente_largura", 7.5)))
		m.set_shader_parameter("vento_turbulencia", float(u.get("turbulencia", 0.0)))
		m.set_shader_parameter("vento_tempo", float(u.get("tempo", 0.0)))


## Onde nascem plantas: terra firme fora da trilha e longe da travessia dos vaus.
static func _vegetavel(x: float, z: float) -> bool:
	var d := absf(x - rio_x(z))
	if d < largura_rio(z) + 0.7 or absf(x - trilha_x(z)) < 0.8:
		return false
	return not (Natureza.vau(z) > 0.0 and d < largura_rio(z) + 1.6)


static func _transforme(p: Vector3, yaw: float, escala: Vector3) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(escala), p)


func _lote(nome: String, m: ArrayMesh, ts: Array[Transform3D], mat: Material,
		r: RandomNumberGenerator, sombra := true, proxy: ArrayMesh = null) -> void:
	if ts.is_empty():
		return
	m.surface_set_material(0, mat)
	# tom por instância na ordem original (a semente não depende dos setores)
	var tons: Array[float] = []
	for i in range(ts.size()):
		tons.append(r.randf_range(0.88, 1.12))
	# SETORES de SETOR×SETOR unidades: uma MultiMesh por setor, para o
	# descarte por câmera (e pela fatia da sombra) pular o que está fora
	var por_setor := {}
	for i in range(ts.size()):
		var k := Vector2i(floori(ts[i].origin.x / SETOR), floori(ts[i].origin.z / SETOR))
		if not por_setor.has(k):
			por_setor[k] = []
		por_setor[k].append(i)
	var chaves: Array = por_setor.keys()
	chaves.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for k in chaves:
		var idx: Array = por_setor[k]
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_colors = true
		multi.mesh = m
		multi.instance_count = idx.size()
		for j in range(idx.size()):
			multi.set_instance_transform(j, ts[idx[j]])
			multi.set_instance_color(j, Color(tons[idx[j]], tons[idx[j]], tons[idx[j]], 1.0))
		var no := MultiMeshInstance3D.new()
		no.name = "%s_%d_%d" % [nome, k.x, k.y]
		no.multimesh = multi
		if not sombra:
			no.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(no)
		lotes.append(no)
		if proxy != null:
			_copas.append(no)
			# Mesmos transforms/setor/ordem, sem RNG extra ou leitura de buffers
			# (o servidor headless não guarda buffers de MultiMesh).
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = proxy
			mm.instance_count = idx.size()
			for j in range(idx.size()):
				mm.set_instance_transform(j, ts[idx[j]])
			var emissor := MultiMeshInstance3D.new()
			emissor.name = "Copa_sombra"
			emissor.multimesh = mm
			emissor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			emissor.visible = false
			# Filho do lote: mover/remover o lote leva sua sombra junto (P26).
			no.add_child(emissor)
			proxies.append(emissor)
	registro[nome] = ts.duplicate()
	var nv := m.surface_get_array_len(0)
	estatisticas["instancias"] += ts.size()
	estatisticas["vertices_armazenados"] += nv
	estatisticas["triangulos_instanciados"] += nv / 3 * ts.size()


func _unica(nome: String, o: RefCounted, mat: Material) -> void:
	var m: ArrayMesh = o.malha()
	m.surface_set_material(0, mat)
	var no := MeshInstance3D.new()
	no.name = nome
	no.mesh = m
	add_child(no)
	var nv := m.surface_get_array_len(0)
	estatisticas["vertices_armazenados"] += nv
	estatisticas["triangulos_instanciados"] += nv / 3


## Terra quente com manchas de musgo, trilha batida clara, margem úmida e o
## cascalho do vau.
static func _cor_chao(x: float, z: float) -> Color:
	var ruido := clampf(0.5 + sin(x * 0.65 + sin(z * 0.31)) * 0.26 + cos(z * 0.59 - x * 0.23) * 0.20, 0.0, 1.0)
	var terra := Color("#7d5a34").lerp(Color("#3f8a34"), ruido)
	var caminho := 1.0 - smoothstep(0.35, 1.0, absf(x - trilha_x(z)))
	terra = terra.lerp(Color("#b48a58"), caminho * 0.9)
	var d := absf(x - rio_x(z)) - largura_rio(z)
	var margem := 1.0 - smoothstep(0.0, 1.1, absf(d))
	terra = terra.lerp(Color("#5c4a30"), margem * 0.6)
	var v := Natureza.vau(z) * (1.0 - smoothstep(0.0, 0.9, d))
	return terra.lerp(Color("#c6b28a"), v)


static func _normal_chao(x: float, z: float) -> Vector3:
	return Vector3(altura(x - 0.06, z) - altura(x + 0.06, z), 0.12,
		altura(x, z - 0.06) - altura(x, z + 0.06)).normalized()


func _terreno() -> void:
	var o := Biblioteca.Oficina.new()
	var nx := int(ceil(LIMITE_X * 2.0 / PASSO))
	var nz := int(ceil((Z_FIM - Z_INICIO) / PASSO))
	for iz in range(nz):
		for ix in range(nx):
			var x := -LIMITE_X + ix * PASSO
			var z := Z_INICIO + iz * PASSO
			var a := ponto(x, z)
			var b := ponto(x + PASSO, z)
			var c := ponto(x, z + PASSO)
			var d := ponto(x + PASSO, z + PASSO)
			# Cor/normal por vértice compartilhado: não cria xadrez de facetas.
			for p in [a, b, c, b, d, c]:
				o.vertices.append(p)
				o.normais.append(_normal_chao(p.x, p.z))
				o.cores.append(_cor_chao(p.x, p.z))
	_unica("Solo_continuo", o, _mat_solo)


## Mata distante: moldura em volta do mapa, logo abaixo do chão, com o mesmo
## manchado de terra e musgo (sem trilha nem riacho) em quadras de
## PASSO_FUNDO — a borda do mapa é água para a regra; a vista não enxerga o
## vazio nem um bloco chapado.
const PASSO_FUNDO := 2.0


func _fundo() -> void:
	var o := Biblioteca.Oficina.new()
	var y := -0.02
	var x0 := -LIMITE_X - MARGEM_FUNDO
	var z0 := Z_INICIO - MARGEM_FUNDO
	var nx := int(ceil((2.0 * (LIMITE_X + MARGEM_FUNDO)) / PASSO_FUNDO))
	var nz := int(ceil((Z_FIM - Z_INICIO + 2.0 * MARGEM_FUNDO) / PASSO_FUNDO))
	for iz in range(nz):
		for ix in range(nx):
			var x := x0 + ix * PASSO_FUNDO
			var z := z0 + iz * PASSO_FUNDO
			# só a moldura: a quadra inteira dentro do mapa fica de fora
			if x >= -LIMITE_X and x + PASSO_FUNDO <= LIMITE_X and z >= Z_INICIO and z + PASSO_FUNDO <= Z_FIM:
				continue
			var a := Vector3(x, y, z)
			var b := Vector3(x + PASSO_FUNDO, y, z)
			var c := Vector3(x, y, z + PASSO_FUNDO)
			var d := Vector3(x + PASSO_FUNDO, y, z + PASSO_FUNDO)
			for p in [a, b, c, b, d, c]:
				o.vertices.append(p)
				o.normais.append(Vector3.UP)
				o.cores.append(_cor_fundo(p.x, p.z))
	_unica("Mata_distante", o, Biblioteca.material())


static func _cor_fundo(x: float, z: float) -> Color:
	var ruido := clampf(0.5 + sin(x * 0.65 + sin(z * 0.31)) * 0.26 + cos(z * 0.59 - x * 0.23) * 0.20, 0.0, 1.0)
	return Color("#6e5232").lerp(Color("#357a30"), ruido)


## Árvores de moldura, só decorativas (fora da grade: a regra não as vê),
## numa faixa estreita além da borda, para a mata não acabar em linha reta.
static func arvores_moldura(semente: int) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = semente + 7
	var out: Array = []
	var passo := 7.5
	var x := -LIMITE_X - 3.0
	while x <= LIMITE_X + 3.0:
		for z in [Z_INICIO - 2.5, Z_FIM + 2.5]:
			out.append(Vector3(x + r.randf_range(-1.5, 1.5), r.randf_range(0.0, TAU), z + r.randf_range(-1.2, 1.2)))
		x += passo
	var z2 := Z_INICIO + 2.0
	while z2 <= Z_FIM - 2.0:
		for xb in [-LIMITE_X - 2.5, LIMITE_X + 2.5]:
			out.append(Vector3(xb + r.randf_range(-1.2, 1.2), r.randf_range(0.0, TAU), z2 + r.randf_range(-1.5, 1.5)))
		z2 += passo
	return out


func _agua() -> void:
	var o := Biblioteca.Oficina.new()
	for i in range(124):
		var z := Z_INICIO + i * 0.5
		var z2 := z + 0.5
		for j in range(6):
			var u := -1.0 + j / 3.0
			var v := u + 1.0 / 3.0
			var a := Vector3(rio_x(z) + largura_rio(z) * u, AGUA_Y, z)
			var b := Vector3(rio_x(z) + largura_rio(z) * v, AGUA_Y, z)
			var c := Vector3(rio_x(z2) + largura_rio(z2) * u, AGUA_Y, z2)
			var d := Vector3(rio_x(z2) + largura_rio(z2) * v, AGUA_Y, z2)
			var cor := Color("#1f9a9a").lerp(Color("#5cc2b4"), absf(u) * 0.55 + sin(z * 0.75) * 0.08)
			o.tri(a, c, b, cor, Vector3.UP)
			o.tri(b, c, d, cor, Vector3.UP)
	var m := Biblioteca.material()
	m.set_shader_parameter("rugosidade", 0.25)
	m.set_shader_parameter("especular", 0.6)
	_unica("Riacho", o, m)
	# Pequenos filetes opacos: movimento sugerido, sem passe transparente ou SSR.
	var reflexos := Biblioteca.Oficina.new()
	for i in range(160):
		var z := Z_INICIO + i * 0.38
		var x := rio_x(z) + sin(i * 4.3) * largura_rio(z) * 0.78
		var p := Vector3(x, AGUA_Y + 0.008, z)
		var cor := Color("#c9f0e4").darkened((sin(i * 1.7) + 1.0) * 0.08)
		reflexos.tri(p, p + Vector3(0.10, 0.0, 0.19), p + Vector3(0.018, 0.0, 0.62), cor, Vector3.UP)
	_unica("Filetes_correnteza", reflexos, Biblioteca.material())


func _serrapilheira(r: RandomNumberGenerator) -> void:
	var o := Biblioteca.Oficina.new()
	for i in range(1500):
		var x := r.randf_range(-16.0, 16.0)
		var z := r.randf_range(-30.0, 18.0)
		if absf(x - rio_x(z)) < largura_rio(z) + 0.3:
			continue
		var p := ponto(x, z) + Vector3.UP * 0.02
		var a := r.randf_range(0.0, TAU)
		var dest := p + Vector3(cos(a) * 0.13, 0.015, sin(a) * 0.13)
		o.folha(p, dest, 0.036, Color("#a0773f").lerp(Color("#5f8a32"), r.randf()), 0.012)
	_unica("Folhas_no_solo", o, Biblioteca.material())
