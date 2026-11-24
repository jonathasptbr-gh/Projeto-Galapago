extends RefCounted
## ESQUELETO 3D — juntas e ossos em 3D projetados ortograficamente em 2D
## (LÓGICA PURA). Fase A: matemática, sem camadas de pixel art.
##
## Convenção do mundo (a mesma do estudo e do rig 2D):
##   x = lateral (direita do cão positiva), y = altura, z = frente.
##   chão em y = 0; o pivô do canvas é o ponto do chão (34, 50).
## A câmera é ortográfica com yaw de 45° em 45° (8 setores de sim/direcao.gd)
## e pitch de 20° (LOW TOP-DOWN). O yaw NÃO gira o modelo: a câmera gira em
## volta dele. O desenho ordena do longe para o perto pela profundidade.
##
## O rig é DADO (`dados/rig/canino3d.json`); este arquivo valida fail-closed,
## avalia a pose por fase/clipe, projeta, resolve socket por NOME e devolve o
## MESMO formato de pose que `jogo/modulos.gd` e `jogo/pele_geometrica.gd`
## esperam: `juntas` (Vector2 no canvas) + `sockets` resolvidos. As peças 2D
## por osso (`pecas`) já são validadas, mas NÃO são desenhadas nesta fase.

const Topologia := preload("res://sim/topologia3d.gd")
const DIRECOES := ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
const YAW_GRAUS := {
	"south": 90.0, "south-east": 45.0, "east": 0.0, "north-east": 315.0,
	"north": 270.0, "north-west": 225.0, "west": 180.0, "south-west": 135.0,
}
const CLIPES := ["idle", "walk", "run", "jump_start", "jump_air", "jump_land", "charge", "shot",
	"bite", "slam", "dig", "hit", "stunned", "death", "get_up"]
const PITCH_GRAUS := 20.0
## Tolerância (px de mundo) da ORDEM ANATÔMICA das pernas na marcha. É régua do
## solver, não dado: a pata continua no alvo e os ossos não esticam.
const TOL_ANATOMIA := 0.01
## Folga do LADO (px): a regra de lado é de DIREÇÃO, não de distância — numa
## perna dobrada o jarrete raspa a reta e exigir 0,01 px ali fazia a solução
## pular de ramo (medido: 6,6 px de joelho num quadro a 60 fps).
const TOL_LADO := 0.5
## Salto máximo (px) do joelho para aceitar outra dobra. No recolhimento máximo
## da traseira a cadeia chega perto de |l1−l2| e outra dobra exige um pulo de
## 5–7 px num quadro (medido); aí fica a dobra autoral e o quadro é contado
## como sem solução — o conserto é de alvo (pose), não do solver.
const SALTO_DOBRA := 2.5
## Folga (px) do LIMITE DE COMPRESSÃO: o alvo do pé nunca chega mais perto do
## topo da cadeia que a distância em que a dobra do polo deixa de existir.
## 0,05 px é a mesma ordem do erro de projeção do alvo (a pata é escrita a
## partir do alvo já corrigido, então a folga não move o pé em apoio).
const FOLGA_COMPRESSAO := 0.05
const JUNTAS_ESPERADAS := 24
const OSSOS_ESPERADOS := 23
const SOCKETS_OBRIGATORIOS := ["boca", "coroa", "base_cauda", "dorso"]
const Z := ["front", "back"]
## Patas da marcha em dados (mesmos nomes de `_pernas`): traseira/dianteira
## esquerda e direita. A defasagem de cada uma vem do JSON, nunca do motor.
const MARCHA_PATAS := ["te", "fe", "td", "fd"]
## Chaves numéricas obrigatórias de cada bloco opcional de uma marcha. Um bloco
## que existe tem todas elas; um bloco ausente simplesmente não se aplica.
const MARCHA_BLOCOS := {
	"voo": ["expoente", "baixa_px", "pescoco_graus", "levanta_extra"],
	"corpo": ["suspensao_px", "suspensao_largura", "bob_px", "baixa_px", "estica_px",
		"flexao_px", "pitch_gather_graus", "pitch_suspensao_graus", "cabeca_contra_pitch"],
	"extras": ["cauda_chicote_px", "orelha_tras_px", "orelha_baixa_px", "cauda_voo_y",
		"cauda_voo_z", "cauda_ponta_voo_y", "cauda_ponta_voo_z"],
}


## Lê o JSON e valida. Devolve {} (falha fechada) para texto ou rig inválido.
static func de_json(texto: String) -> Dictionary:
	var v: Variant = JSON.parse_string(texto)
	if not v is Dictionary:
		return {}
	var m: Dictionary = v
	if validar(m) != "":
		return {}
	return m


## Primeiro erro encontrado; vazio = rig 3D válido.
static func validar(m: Dictionary) -> String:
	var schema := int(m.get("schema_version", 0))
	if schema not in [3, 4]:
		return "schema_version != 3/4"
	if Topologia.compilar(m).is_empty():
		return "topologia inválida (grafo, papéis ou membros)"
	if not m.get("id") is String or (m["id"] as String).is_empty():
		return "id ausente"
	if m.get("arquetipo") not in Topologia.ARQUETIPOS:
		return "arquétipo desconhecido"
	for chave in ["porte_px", "pivot_px"]:
		if not _par(m.get(chave)):
			return chave + " inválido"
		var par: Array = m[chave]
		if float(par[0]) <= 0.0 or float(par[1]) <= 0.0:
			return chave + " não positivo"
	var env: Variant = m.get("envelope_px")
	if not env is Dictionary:
		return "envelope_px ausente"
	for chave in ["altura", "comprimento", "largura"]:
		var valor: Variant = (env as Dictionary).get(chave)
		if not (valor is int or valor is float) or not is_finite(float(valor)) or float(valor) <= 0.0:
			return "envelope_px." + chave + " inválido"

	var juntas: Variant = m.get("juntas")
	if not juntas is Dictionary:
		return "juntas inválido"
	if schema == 3 and (juntas as Dictionary).size() != JUNTAS_ESPERADAS:
		return "juntas: esperado %d, veio %d" % [JUNTAS_ESPERADAS, (juntas as Dictionary).size()]
	for nome in juntas:
		if not _v3(juntas[nome]):
			return "junta %s inválida" % nome
	# A topologia compilada valida as cadeias; o schema 3 preserva o contrato legado.
	if schema == 3:
		for lado in ["e", "d"]:
			for nome in ["anca_" + lado, "joelho_t" + lado, "jarrete_t" + lado, "pata_t" + lado]:
				if not (juntas as Dictionary).has(nome):
					return "junta traseira obrigatória ausente: " + nome

	var ossos: Variant = m.get("ossos")
	if not ossos is Array:
		return "ossos inválido"
	if schema == 3 and (ossos as Array).size() != OSSOS_ESPERADOS:
		return "ossos: esperado %d, veio %d" % [OSSOS_ESPERADOS, (ossos as Array).size()]
	var usados: Dictionary = {}
	var arestas: Dictionary = {}
	for i in (ossos as Array).size():
		var b: Variant = (ossos as Array)[i]
		if not b is Dictionary:
			return "osso %d não é objeto" % i
		var osso: Dictionary = b
		var a: Variant = osso.get("a")
		var bb: Variant = osso.get("b")
		if not a is String or not (juntas as Dictionary).has(a):
			return "osso %d com junta A ausente" % i
		if not bb is String or not (juntas as Dictionary).has(bb):
			return "osso %d com junta B ausente" % i
		if a == bb:
			return "osso %d liga a junta a si mesma" % i
		var largura: Variant = osso.get("largura")
		if not (largura is int or largura is float) or not is_finite(float(largura)) or float(largura) <= 0.0:
			return "osso %d sem largura positiva" % i
		usados[a] = true
		usados[bb] = true
		arestas[String(a) + ">" + String(bb)] = true
	if schema == 3:
		for lado in ["e", "d"]:
			var sufixo: String = "t" + String(lado)
			for trecho in [["anca_" + lado, "joelho_" + sufixo],
				["joelho_" + sufixo, "jarrete_" + sufixo],
				["jarrete_" + sufixo, "pata_" + sufixo]]:
				if not arestas.has(String(trecho[0]) + ">" + String(trecho[1])):
					return "osso traseiro obrigatório ausente: %s>%s" % trecho
	for nome in juntas:
		if not usados.has(nome):
			return "junta %s não pertence a osso" % nome

	var corpo: Variant = m.get("corpo")
	if not corpo is Array or (corpo as Array).is_empty():
		return "corpo vazio"
	for nome in corpo:
		if not (juntas as Dictionary).has(nome):
			return "corpo com junta inexistente"

	var dirs: Variant = m.get("directions")
	if not dirs is Dictionary or (dirs as Dictionary).size() != 8:
		return "directions != 8"
	for dir in DIRECOES:
		if not (dirs as Dictionary).has(dir):
			return "direção ausente: " + dir
		var info: Variant = (dirs as Dictionary)[dir]
		if not info is Dictionary:
			return "direção %s não é objeto" % dir
		var d: Dictionary = info
		var y: Variant = d.get("yaw")
		if not (y is int or y is float) or not is_finite(float(y)):
			return "direção %s sem yaw" % dir
		if absf(float(y) - float(YAW_GRAUS[dir])) > 0.01:
			return "direção %s com yaw diferente do setor" % dir
		if not d.get("mirror") is bool or not d.get("costas") is bool:
			return "direção %s: mirror/costas" % dir
	for dir in dirs:
		if dir not in DIRECOES:
			return "direção desconhecida: " + str(dir)

	var sockets: Variant = m.get("sockets")
	if not sockets is Dictionary:
		return "sockets inválido"
	for obrig in SOCKETS_OBRIGATORIOS:
		if not (sockets as Dictionary).has(obrig):
			return "socket obrigatório ausente: " + obrig
	for nome in sockets:
		var s: Variant = (sockets as Dictionary)[nome]
		if not s is Dictionary:
			return "socket %s não é objeto" % nome
		var item: Dictionary = s
		if not item.get("joint") is String or not (juntas as Dictionary).has(item["joint"]):
			return "socket %s aponta junta inexistente" % nome
		if not _v3(item.get("offset")):
			return "socket %s com offset 3D inválido" % nome
		if not (item.get("z") in Z):
			return "socket %s com z inválido" % nome
		if item.has("uso") and item["uso"] != "vfx":
			return "socket %s com uso inválido" % nome
		if not item.get("oculto_em") is Array:
			return "socket %s sem oculto_em" % nome
		for oculta in item["oculto_em"]:
			if oculta not in DIRECOES:
				return "socket %s oculto em direção desconhecida" % nome

	var clips: Variant = m.get("clips")
	if not clips is Dictionary:
		return "clips inválido"
	for clipe in CLIPES:
		if not (clips as Dictionary).has(clipe):
			return "clipe %s ausente" % clipe
		var c: Variant = (clips as Dictionary)[clipe]
		if not c is Dictionary:
			return "clipe %s não é objeto" % clipe
		if not (c as Dictionary).get("loop") is bool:
			return "clipe %s sem loop" % clipe
		if float((c as Dictionary).get("duracao_s", 0.0)) <= 0.0:
			return "clipe %s sem duração positiva" % clipe

	var motion: Variant = m.get("motion")
	if not motion is Dictionary:
		return "motion inválido"
	for chave in motion:
		# As marchas são o único bloco não numérico do motion; têm validação
		# própria logo abaixo.
		if String(chave) in ["marchas", "clipe_marcha"]:
			continue
		var v2: Variant = (motion as Dictionary)[chave]
		if not (v2 is int or v2 is float) or not is_finite(float(v2)):
			return "motion.%s inválido" % chave
	var erro_marcha := _validar_marchas(motion)
	if erro_marcha != "":
		return erro_marcha

	# Fase B: o modelo de dados já aceita peças 2D por osso; nada as desenha.
	var pecas: Variant = m.get("pecas", [])
	if not pecas is Array:
		return "pecas inválido"
	for i in (pecas as Array).size():
		var p: Variant = (pecas as Array)[i]
		if not p is Dictionary:
			return "peça %d não é objeto" % i
		var peca: Dictionary = p
		var osso: Variant = peca.get("osso")
		if osso is String:
			if not usados.has(osso):
				return "peça %d aponta osso inexistente" % i
		elif osso is int or osso is float:
			if int(osso) < 0 or int(osso) >= (ossos as Array).size():
				return "peça %d com índice de osso fora" % i
		else:
			return "peça %d sem osso" % i
		var poly: Variant = peca.get("poly")
		if not poly is Array or (poly as Array).size() < 3:
			return "peça %d com poly inválido" % i
		for q in poly:
			if not _par(q):
				return "peça %d com ponto inválido" % i
		if float(peca.get("w", 0.0)) <= 0.0:
			return "peça %d sem largura" % i
		for cor in ["fill", "outline"]:
			var texto: Variant = peca.get(cor)
			if not texto is String or not (texto as String).is_valid_html_color():
				return "peça %d com %s inválido" % [i, cor]
	return ""


static func direcoes(m: Dictionary) -> PackedStringArray:
	var lista := PackedStringArray()
	if not m.get("directions") is Dictionary:
		return lista
	for dir in m["directions"]:
		lista.append(str(dir))
	return lista


static func envelope(m: Dictionary) -> Dictionary:
	var env: Variant = m.get("envelope_px", {})
	return env if env is Dictionary else {}


## Um único pivô para TODOS os clipes: bbox amostrada em 16 yaws e 32
## fases por clipe, com margem de 6px, mais o alcance analítico das patas.
## `porte_px` é o porte do animal, declarado e imutável; o quadro derivado é
## metadado, nunca recorte físico nem escala.
static func calcular_quadro(m: Dictionary) -> Dictionary:
	var minimo := Vector2(INF, INF)
	var maximo := Vector2(-INF, -INF)
	var clipes: Dictionary = {}
	var margem := 6.0
	for osso in m.get("ossos", []):
		margem = maxf(margem, float(osso.get("largura", 1.0)) * 0.5 + 4.0)
	var antigo := Vector2(float(m["pivot_px"][0]), float(m["pivot_px"][1]))
	for clipe in CLIPES:
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for yaw_i in 16:
			var angulo := float(yaw_i) * 22.5
			for f_i in 33:
				for sprint in ([false, true] if clipe.begins_with("jump_") else [false]):
					var p := pose(m, "south", float(f_i) / 32.0, clipe, sprint, angulo)
					for pt in p.get("juntas", {}).values():
						lo = lo.min((pt as Vector2) - antigo)
						hi = hi.max((pt as Vector2) - antigo)
					for sock in p.get("sockets", {}).values():
						lo = lo.min((sock["pos"] as Vector2) - antigo)
						hi = hi.max((sock["pos"] as Vector2) - antigo)
		clipes[clipe] = Rect2(lo - Vector2.ONE * margem, hi - lo + Vector2.ONE * margem * 2.0)
		minimo = minimo.min(lo)
		maximo = maximo.max(hi)
	# Polos de alcance em mundo: o apoio pode estar em qualquer ponto da esfera
	# atingível; a projeção ortográfica nunca ultrapassa esse raio por eixo.
	for perna in _pernas(m):
		var upper := _vec(m["juntas"][perna["upper"]])
		var raio := float(perna["l1"]) + float(perna["l2"]) + float(perna.get("l3", 0.0))
		for i in 16:
			var ang := deg_to_rad(float(i) * 22.5)
			var centro := projetar(upper, ang, pitch())
			minimo = minimo.min(Vector2(centro.x, centro.y) - Vector2.ONE * raio)
			maximo = maximo.max(Vector2(centro.x, centro.y) + Vector2.ONE * raio)
	var pivot := Vector2(ceilf(maxf(antigo.x, -minimo.x + margem)),
		ceilf(maxf(antigo.y, -minimo.y + margem)))
	var quadro := Vector2(ceilf(maxf(float(m["porte_px"][0]), pivot.x + maximo.x + margem)),
		ceilf(maxf(float(m["porte_px"][1]), pivot.y + maximo.y + margem)))
	for clipe in clipes:
		var r: Rect2 = clipes[clipe]
		clipes[clipe] = Rect2(r.position + pivot, r.size)
	return {"quadro_px": [int(quadro.x), int(quadro.y)],
		"pivot_px": [int(pivot.x), int(pivot.y)], "bounds_clipes": clipes}


static func preparar(m: Dictionary) -> Dictionary:
	if validar(m) != "":
		return {}
	var out := m.duplicate(true)
	out["topologia_compilada"] = Topologia.compilar(out)
	if out["topologia_compilada"]["locomocao_suportada"]:
		out.merge(calcular_quadro(out), true)
	return out


static func yaw(direcao: String) -> float:
	if not YAW_GRAUS.has(direcao):
		return NAN
	return deg_to_rad(float(YAW_GRAUS[direcao]))


## Yaw do rig em GRAUS, na convenção do jogo: 0 = east, 90 = south,
## 180 = west, 270 = north (e as diagonais a 45°). É o valor que a câmera
## contínua usa; `yaw()` devolve o mesmo em radianos.
static func yaw_graus(direcao: String) -> float:
	if not YAW_GRAUS.has(direcao):
		return NAN
	return float(YAW_GRAUS[direcao])


## Ângulo efetivo da câmera: `yaw_graus` contínuo quando finito; NaN (padrão)
## volta ao yaw do setor do rig. Sempre normalizado em [0, 360).
static func yaw_efetivo(direcao: String, yaw_graus: float) -> float:
	if is_finite(yaw_graus):
		return fposmod(yaw_graus, 360.0)
	return yaw_graus(direcao)


static func pitch() -> float:
	return deg_to_rad(PITCH_GRAUS)


## Pose 3D completa. Devolve {} para direção/clipe desconhecido — nunca
## inventa pose. `juntas` é o contrato 2D (Vector2 no canvas); `juntas_3d`,
## `profundidade` e `sockets` são o que o desenho 3D e os módulos consomem.
##
## `direcao` continua mandando no SETOR (sockets/oculto_em e módulos). O
## `yaw_graus` é só a CÂMERA de apresentação: NaN (padrão) usa o yaw do setor;
## um valor contínuo gira a projeção sem tocar em nenhuma regra. Convenção:
## 0° = east, 90° = south, 180° = west, 270° = north.
static func pose(m: Dictionary, direcao: String, fase: float, clipe: String = "walk",
		salto_correndo: bool = false, yaw_graus: float = NAN, alvos: Dictionary = {}) -> Dictionary:
	if m.is_empty() or not m.get("directions") is Dictionary:
		return {}
	# Os outros arquétipos já têm contrato topológico, mas ainda não gait/pose.
	if String(m.get("arquetipo", "")) != "quadrupede":
		return {}
	if not (m["directions"] as Dictionary).has(direcao):
		return {}
	if clipe not in CLIPES:
		return {}
	var j := _juntas_rest(m)
	if j.is_empty():
		return {}
	var f := clampf(fase, 0.0, 1.0)
	var loop := true
	var clips: Variant = m.get("clips", {})
	if clips is Dictionary and (clips as Dictionary).has(clipe):
		loop = bool((clips as Dictionary)[clipe].get("loop", true))
	if loop:
		f = wrapf(fase, 0.0, 1.0)
	var mo: Dictionary = m.get("motion", {})
	var pernas := _pernas(m)
	var patas := _patas(pernas, clipe, f, mo, salto_correndo)
	# Âncoras de chão só fazem sentido num clipe com marcha declarada.
	if not _marcha(mo, clipe).is_empty():
		for nome in alvos:
			if patas.has(nome) and alvos[nome] is Vector3:
				patas[nome] = alvos[nome]
	_mover_corpo(m, j, clipe, f, mo, salto_correndo)
	# A ordem anatômica só é imposta nos clipes de MARCHA (os que a tabela
	# `marchas` do rig aponta). Pulo, morte e levantar têm outra postura e
	# ficam de fora — lá a regra não vale.
	var vale_ordem := not _marcha(mo, clipe).is_empty()
	for perna in pernas:
		var nome := String(perna["nome"])
		var upper := String(perna["upper"])
		var P: Vector3 = j[upper]
		var F: Vector3 = patas[nome]
		var l1 := float(perna["l1"])
		var l2 := float(perna["l2"])
		var pole: Vector3 = perna["pole"]
		var moderno := alvos.has(nome) or int(m.get("schema_version", 3)) == 4
		var sentido := _sentido_polo(perna, moderno)
		# LIMITE DE COMPRESSÃO, antes da IK e no ALVO do pé: se |topo→pata| cai
		# abaixo de `dmin` a dobra do polo deixa de existir e o alvo é afastado
		# ao longo da reta topo→pata até `dmin`. Só no BALANÇO (`F.y > 0`): com
		# a pata no chão a distância é grande e o apoio não muda um pixel.
		F = _alvo_compressao(P, F, F.y > 0.0, _dmin_perna(perna))
		if perna.has("l3"):
			var l3 := float(perna["l3"])
			var H := _jarrete_alcancavel(P, F, l1, l2, l3, perna["offset_jarr"])
			# Solução de repouso: o jarrete de contato é o que fecha o
			# metatarso no alvo, e é ele que escreve a pata — a dobra
			# escolhida nunca move o alvo.
			var solucao := _dobra(P, H, l1, l2, pole, moderno, sentido)
			var jarrete: Vector3 = solucao["pata"]
			var joelho: Vector3 = solucao["joelho"]
			if vale_ordem:
				# O jarrete anda no círculo do metatarso (regra do jarrete); o
				# joelho continua sendo SEMPRE o da dobra do polo.
				var escolha := _perna_traseira(P, F, l1, l2, l3, perna["offset_jarr"],
					pole, moderno, sentido, {"joelho": joelho, "jarrete": jarrete})
				joelho = escolha["joelho"]
				jarrete = escolha["jarrete"]
			j[String(perna["joint1"])] = joelho
			j[String(perna["joint2"])] = jarrete
			# A pata é o alvo: o círculo rígido do metatarso em torno dela
			# garante F exato; alvo fora do alcance corrige só o contato. A
			# expressão usa o jarrete de CONTATO (não o da dobra), então a
			# posição da pata não muda com a regra anatômica.
			j[String(perna["foot"])] = solucao["pata"] + (F - H).normalized() * l3
		else:
			# POLO FIXO: uma perna, uma dobra — a do polo (cotovelo atrás). Sem
			# troca de ramo e sem escolha por violação: se o alvo ainda puser a
			# dobra acima do ombro, o problema é do ALVO (o clamp acima é o
			# teto), não do solver.
			var solucao := _dobra(P, F, l1, l2, pole, moderno, sentido)
			j[String(perna["joint1"])] = solucao["joelho"]
			j[String(perna["foot"])] = solucao["pata"]
	_extras(j, clipe, f, mo, salto_correndo)
	if clipe == "death":
		_deitar(j, f)
	elif clipe == "get_up":
		_deitar(j, 1.0 - f)
	return _projetar_pose(m, j, direcao, clipe, f, yaw_graus)


## Projeção ortográfica. Devolve Vector3(sx, sy_para_baixo, profundidade_longe).
## yaw gira em torno de Y; pitch é a elevação da câmera (0 = de lado,
## 90 = de cima). A profundidade é usada só para a ordenação do pintor.
static func projetar(p: Vector3, yaw_rad: float, pitch_rad: float) -> Vector3:
	var cy := cos(yaw_rad)
	var sy := sin(yaw_rad)
	var cp := cos(pitch_rad)
	var sp := sin(pitch_rad)
	var sx := -p.x * sy + p.z * cy
	var syd := p.x * cy * sp - p.y * cp + p.z * sy * sp
	var prof := -(p.x * cy * cp + p.y * sp + p.z * sy * cp)
	return Vector3(sx, syd, prof)


## Ponto do mundo → px do canvas (pivô do chão em `pivot_px`).
static func para_canvas(projetado: Vector3, m: Dictionary) -> Vector2:
	var piv: Array = m["pivot_px"]
	return Vector2(float(piv[0]) + projetado.x, float(piv[1]) + projetado.y)


## Ordem do pintor: longe → perto. Determinística (empate por id estável),
## usada pelo desenho e testável sem nó.
static func ordem_pintor(rig: Dictionary, p: Dictionary) -> Array:
	var itens: Array = []
	var juntas: Dictionary = p.get("juntas", {})
	var prof: Dictionary = p.get("profundidade", {})
	if juntas.is_empty() or prof.is_empty():
		return itens
	var ossos: Array = rig.get("ossos", [])
	for i in ossos.size():
		var b: Dictionary = ossos[i]
		var a := String(b["a"])
		var bb := String(b["b"])
		if not prof.has(a) or not prof.has(bb):
			continue
		itens.append({"tipo": "osso", "id": "osso:%03d:%s>%s" % [i, a, bb],
			"a": a, "b": bb, "largura": float(b.get("largura", 2.0)),
			"profundidade": (float(prof[a]) + float(prof[bb])) * 0.5})
	for nome in rig.get("juntas", {}):
		if not juntas.has(nome) or not prof.has(nome):
			continue
		itens.append({"tipo": "junta", "id": "junta:" + String(nome),
			"nome": String(nome), "profundidade": float(prof[nome])})
	itens.sort_custom(func(x, y):
		var dx := float(x["profundidade"])
		var dy := float(y["profundidade"])
		if absf(dx - dy) < 0.000001:
			return String(x["id"]) < String(y["id"])
		return dx > dy)
	return itens


## Adaptador: devolve um rig/pose no formato EXATO que `jogo/modulos.gd` e
## `sim/modulos.gd` já consomem (socket por nome via sim/esqueleto.gd), sem
## mudar uma linha deles. Os sockets viram juntas sintéticas na pose 2D e já
## chegam projetados com o yaw contínuo da pose; `direcao` decide só o
## `oculto_em` (as vistas de costas continuam escondendo boca/cauda).
static func adaptar_modulos(rig: Dictionary, p: Dictionary, direcao: String) -> Dictionary:
	var juntas_mod: Dictionary = (p.get("juntas", {}) as Dictionary).duplicate()
	var sockets: Dictionary = p.get("sockets", {})
	var nomes: Dictionary = {}
	for nome in sockets:
		var chave := "sock__" + String(nome)
		nomes[nome] = chave
		juntas_mod[chave] = sockets[nome]["pos"]
	var dirs: Dictionary = {}
	for dir in DIRECOES:
		dirs[dir] = {"profile": "mod", "mirror": false, "costas": false}
	var socks_mod: Dictionary = {}
	for nome in sockets:
		var s: Dictionary = sockets[nome]
		var item := {"joint": String(nomes[nome]), "offset": [0, 0], "z": s["z"],
			"oculto_em": [] if bool(s["visivel"]) else DIRECOES.duplicate()}
		if s.has("uso"):
			item["uso"] = s["uso"]
		socks_mod[nome] = item
	var rig_mod := {
		"pivot_px": rig.get("pivot_px", [34, 50]),
		"directions": dirs,
		"sockets": socks_mod,
		"profiles": {"mod": {"joints": juntas_mod, "bones": []}},
	}
	var pose_mod := {
		"juntas": juntas_mod,
		"sockets": sockets,
		"direcao": direcao,
		"clipe": p.get("clipe", ""),
		"fase": p.get("fase", 0.0),
	}
	return {"rig": rig_mod, "pose": pose_mod}


## Mistura de APRESENTAÇÃO entre duas poses (a antiga e a nova). Interpola
## `juntas`, `sockets[*].pos`, `sockets[*].profundidade` e `profundidade`;
## `juntas_3d`, quando existe nos dois, também acompanha. O blend linear
## de apresentação NÃO conserva comprimentos ósseos (comportamento anterior).
## O mesmo vale para _deitar em death/get_up; a IK da marcha continua rígida.
## w=0 devolve `a` e
## w=1 devolve `b`; a visibilidade/z dos sockets vem de `b` (a pose nova).
## É pura e NÃO altera `pose`/`validar`: a troca de clipe decide o w.
static func misturar(a: Dictionary, b: Dictionary, w: float) -> Dictionary:
	if a.is_empty():
		return b
	if b.is_empty():
		return a
	var t := clampf(w, 0.0, 1.0)
	if t <= 0.0:
		return a
	if t >= 1.0:
		return b
	var out: Dictionary = b.duplicate(true)
	out["juntas"] = _misturar_vec2(a.get("juntas", {}), b.get("juntas", {}), t)
	out["profundidade"] = _misturar_float(a.get("profundidade", {}), b.get("profundidade", {}), t)
	if a.has("juntas_3d") and b.has("juntas_3d"):
		out["juntas_3d"] = _misturar_vec3(a["juntas_3d"], b["juntas_3d"], t)
	var sa: Variant = a.get("sockets", {})
	var sb: Variant = b.get("sockets", {})
	if sa is Dictionary and sb is Dictionary:
		var socks: Dictionary = {}
		for nome in sb:
			var item: Dictionary = ((sb as Dictionary)[nome] as Dictionary).duplicate(true)
			if (sa as Dictionary).has(nome):
				var antigo: Dictionary = (sa as Dictionary)[nome]
				if antigo.has("pos") and item.has("pos"):
					item["pos"] = (antigo["pos"] as Vector2).lerp(item["pos"], t)
				if antigo.has("profundidade") and item.has("profundidade"):
					item["profundidade"] = lerpf(float(antigo["profundidade"]), float(item["profundidade"]), t)
			socks[nome] = item
		for nome in sa:
			if not socks.has(nome):
				socks[nome] = (sa as Dictionary)[nome]
		out["sockets"] = socks
	return out


static func _misturar_vec2(a: Variant, b: Variant, t: float) -> Dictionary:
	var out: Dictionary = {}
	var da: Dictionary = a if a is Dictionary else {}
	var db: Dictionary = b if b is Dictionary else {}
	for nome in db:
		if da.has(nome):
			out[nome] = (da[nome] as Vector2).lerp(db[nome], t)
		else:
			out[nome] = db[nome]
	for nome in da:
		if not out.has(nome):
			out[nome] = da[nome]
	return out


static func _misturar_vec3(a: Variant, b: Variant, t: float) -> Dictionary:
	var out: Dictionary = {}
	var da: Dictionary = a if a is Dictionary else {}
	var db: Dictionary = b if b is Dictionary else {}
	for nome in db:
		if da.has(nome):
			out[nome] = (da[nome] as Vector3).lerp(db[nome], t)
		else:
			out[nome] = db[nome]
	for nome in da:
		if not out.has(nome):
			out[nome] = da[nome]
	return out


static func _misturar_float(a: Variant, b: Variant, t: float) -> Dictionary:
	var out: Dictionary = {}
	var da: Dictionary = a if a is Dictionary else {}
	var db: Dictionary = b if b is Dictionary else {}
	for nome in db:
		if da.has(nome):
			out[nome] = lerpf(float(da[nome]), float(db[nome]), t)
		else:
			out[nome] = db[nome]
	for nome in da:
		if not out.has(nome):
			out[nome] = da[nome]
	return out


# --- pose: montagem ---

static func _juntas_rest(m: Dictionary) -> Dictionary:
	var j: Dictionary = {}
	var bruto: Variant = m.get("juntas", {})
	if not bruto is Dictionary:
		return j
	for nome in bruto:
		j[nome] = _vec(bruto[nome])
	return j


## As quatro pernas derivam os comprimentos do repouso: dianteiras conservam
## upper→joelho→pata; traseiras usam anca→joelho→jarrete→pata.
static func _pernas(m: Dictionary) -> Array:
	var out: Array = []
	var j: Dictionary = m.get("juntas", {})
	var topo: Dictionary = m.get("topologia_compilada", {})
	if topo.is_empty():
		topo = Topologia.compilar(m)
	for membro in topo.get("membros", []):
		var cadeia: Array = membro["cadeia"]
		var upper := String(cadeia[0])
		var joelho := String(cadeia[1])
		var pata := String(cadeia[-1])
		var nome := ("f" if membro["papel"] == "limb_front" else "t") + String(membro["lado"])
		var pu := _vec(j[upper])
		var pk := _vec(j[joelho])
		var pp := _vec(j[pata])
		var perna := {"nome": nome, "upper": upper, "joint1": joelho, "foot": pata,
			"pole": _vec(membro["pole"]), "x": pp.x, "rest_z": pp.z,
			"l1": pu.distance_to(pk), "l2": pk.distance_to(pp)}
		if cadeia.size() == 4:
			var ph := _vec(j[cadeia[2]])
			perna["joint2"] = String(cadeia[2])
			perna["l2"] = pk.distance_to(ph)
			perna["l3"] = ph.distance_to(pp)
			perna["offset_jarr"] = ph - pp
		out.append(perna)
	return out


## Curva de easing suave (0→1) usada nas chaves e no recolhimento das patas.
static func _smoothstep(a: float, b: float, x: float) -> float:
	var t := clampf((x - a) / maxf(b - a, 0.000001), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Envelope de VOO da marcha (0..1): máximo no meio de cada suspensão, que
## começa em 0,25 e em 0,75 e dura `duty` — daí as cristas em 0,25+duty/2 e
## 0,75+duty/2 (0,375 e 0,875 com duty 0,25, o galope do canino), mínimo um
## quarto de ciclo depois e ~0,31 na emenda do ciclo — o cão chega quase "em
## pé" em jump_start. `voo.expoente` (1,7) estreita a crista: sem ele a cabeça
## (alavanca longa) teria de voltar rápido demais e o passo por quadro do
## clipe estouraria. O duty e o expoente vêm da marcha em dados; outra marcha
## herda o voo sem editar o motor.
static func _voo_galope(f: float, marcha: Dictionary) -> float:
	var duty := float(marcha.get("duty", 0.0))
	var crista := 0.25 + duty * 0.5
	return pow(0.5 + 0.5 * cos(TAU * 2.0 * (f - crista)),
		float((marcha.get("voo", {}) as Dictionary).get("expoente", 0.0)))


## Pulso 0→1→0 entre a..b (sobe) e c..d (desce); serve para recolher/estender
## as patas do pulo em tempos diferentes.
static func _pulso(f: float, a: float, b: float, c: float, d: float) -> float:
	return _smoothstep(a, b, f) * (1.0 - _smoothstep(c, d, f))


## Amostra periódica com interpolação smoothstep (4 valores = um por quarto
## do passo). Serve para o peso lateral seguir o lado do apoio.
static func _amostra_periodica(vals: Array, f: float) -> float:
	var n := vals.size()
	if n == 0:
		return 0.0
	var x := fposmod(f, 1.0) * float(n)
	var i := int(floorf(x))
	var u := x - float(i)
	return lerpf(float(vals[i % n]), float(vals[(i + 1) % n]), _smoothstep(0.0, 1.0, u))


## Interpolação por chaves [[t, valor], ...] com smoothstep entre elas. É a
## base das ações de uma vez (mordida, esbarrão, pulo).
static func _chave(chaves: Array, f: float) -> float:
	if chaves.is_empty():
		return 0.0
	if f <= float(chaves[0][0]):
		return float(chaves[0][1])
	for i in range(1, chaves.size()):
		var t0 := float(chaves[i - 1][0])
		var v0 := float(chaves[i - 1][1])
		var t1 := float(chaves[i][0])
		var v1 := float(chaves[i][1])
		if f <= t1:
			return lerpf(v0, v1, _smoothstep(t0, t1, f))
	return float(chaves[chaves.size() - 1][1])


static func _girar_x_nomes(j: Dictionary, nomes: Array, piv: Vector3, ang: float) -> void:
	var c := cos(ang)
	var s := sin(ang)
	for nome in nomes:
		if not j.has(nome):
			continue
		var p: Vector3 = j[nome]
		var dy := p.y - piv.y
		var dz := p.z - piv.z
		j[nome] = Vector3(p.x, piv.y + dy * c - dz * s, piv.z + dy * s + dz * c)


static func _girar_y_nomes(j: Dictionary, nomes: Array, piv: Vector3, ang: float) -> void:
	var c := cos(ang)
	var s := sin(ang)
	for nome in nomes:
		if not j.has(nome):
			continue
		var p: Vector3 = j[nome]
		var dx := p.x - piv.x
		var dz := p.z - piv.z
		j[nome] = Vector3(piv.x + dx * c - dz * s, p.y, piv.z + dx * s + dz * c)


## Marcha que dirige o clipe: `clipe_marcha` escolhe a tabela em `marchas`.
## Devolve {} quando o mapa não aponta o clipe (o clipe sem marcha não anda).
## `validar` exige walk e run mapeados e reprova o rig sem a tabela — o motor
## não tem fallback de gait.
static func _marcha(mo: Dictionary, clipe: String) -> Dictionary:
	var mapa: Variant = mo.get("clipe_marcha", {})
	if not mapa is Dictionary or not (mapa as Dictionary).has(clipe):
		return {}
	var tabela: Variant = mo.get("marchas", {})
	if not tabela is Dictionary:
		return {}
	var nome: Variant = (mapa as Dictionary)[clipe]
	if not nome is String:
		return {}
	var marcha: Variant = (tabela as Dictionary).get(nome)
	return marcha if marcha is Dictionary else {}


## Ciclo derivado da própria marcha: `passo_px / duty`. Uma fonte só — no
## apoio o corpo anda `duty × ciclo` e essa conta tem de ser a própria
## passada, então ciclo não é valor declarado (a chave `ciclo_px` deixou de
## existir nos rigs). Se um rig antigo ainda a trouxer, `validar` só a confere
## contra este derivado; o motor não a lê.
static func _ciclo(marcha: Dictionary) -> float:
	return float(marcha.get("passo_px", 0.0)) / maxf(float(marcha.get("duty", 0.0)), 0.000001)


## Alvo do pé [z, y] no instante `f` de uma marcha em dados. Apoio: a pata
## recua a passada inteira em z. Balanço: volta com a curva de `avanco` do
## LADO (dianteira/traseira) — `ease_out` chega cedo, `ease_in` fica para trás
## e varre no fim — e sobe em arco; se a marcha tem bloco `voo`, as quatro
## patas recolhem mais no voo (`levanta_extra`). Nada aqui conhece nome de
## clipe. Array (e não Vector2) para o cálculo seguir em double, como antes de
## a marcha sair do motor.
static func _pe_da_marcha(marcha: Dictionary, pata: String, frente: bool, f: float) -> Array:
	var defas: Dictionary = marcha.get("defasagem", {})
	var duty := float(marcha.get("duty", 0.0))
	var passo := float(marcha.get("passo_px", 0.0))
	var c := fposmod(f - float(defas.get(pata, 0.0)), 1.0)
	if c < duty:
		return [passo * 0.5 - passo * (c / duty), 0.0]
	var t := (c - duty) / (1.0 - duty)
	var lado := "dianteira" if frente else "traseira"
	var curva: Dictionary = (marcha.get("avanco", {}) as Dictionary).get(lado, {})
	var expoente := float(curva.get("expoente", 0.0))
	var avanca := (pow(t, expoente) if String(curva.get("curva", "")) == "ease_in"
		else 1.0 - pow(1.0 - t, expoente))
	var z := -passo * 0.5 + passo * avanca
	var y := float(marcha.get("levanta_px", 0.0))
	var voo: Variant = marcha.get("voo")
	if voo is Dictionary:
		y = y * (1.0 + float((voo as Dictionary).get("levanta_extra", 0.0))
			* _voo_galope(f, marcha))
	y = y * pow(maxf(0.0, sin(PI * t)), float(marcha.get("easing_levanta", 0.0)))
	return [z, y]


## Alvos de pata. Apoio = y 0 (chão do MUNDO); balanço = arco em y. A marcha
## de 4 tempos usa LH→LF→RH→RF; o galope usa o par traseiro e depois o
## dianteiro, com suspensão. A saída do balanço é rápida e o pouso macio
## (`pow(sin, easing)` no y, curva de `avanco` no z). Qualquer clipe que tenha
## marcha em `clipe_marcha` é resolvido pela tabela `marchas` do rig —
## defasagem, passada, altura, easings, lados e voo vêm do JSON. Nos demais
## clipes as patas ficam plantadas, salvo o pulo (recolhe/estende) e o pouso
## correndo (derrapagem).
static func _patas(pernas: Array, clipe: String, f: float, mo: Dictionary,
		salto_correndo: bool = false) -> Dictionary:
	var out: Dictionary = {}
	var marcha := _marcha(mo, clipe)
	for perna in pernas:
		var nome := String(perna["nome"])
		var x := float(perna["x"])
		var z := float(perna["rest_z"])
		var y := 0.0
		var frente := String(perna["upper"]).begins_with("ombro")
		if not marcha.is_empty():
			var pe := _pe_da_marcha(marcha, nome, frente, f)
			z += float(pe[0])
			y = float(pe[1])
		elif clipe == "jump_air":
			# Dianteiras recolhem primeiro; traseiras depois. Antes do pouso as
			# dianteiras voltam a estender.
			var pulso := _pulso(f, 0.0, 0.25, 0.55, 0.85) if frente else _pulso(f, 0.15, 0.4, 0.7, 1.0)
			y = float(mo.get("pulo_levanta_px", 5.0)) * pulso
			z += (1.5 if frente else -1.0) * pulso
			if salto_correndo:
				# Salto horizontal: dianteiras alcançam mais à frente.
				var alcance := _smoothstep(0.0, 0.2, f)
				z += (float(mo.get("pulo_alcance_dianteiro_px", 3.0)) if frente
					else float(mo.get("pulo_alcance_traseiro_px", 2.0))) * alcance
		elif clipe == "jump_land":
			if salto_correndo:
				# Derrapagem curta: as patas ficam à frente no primeiro contato
				# e voltam ao chão normal até o fim do clipe.
				var derr := 1.0 - _smoothstep(0.0, 0.6, f)
				z += (float(mo.get("pulo_alcance_dianteiro_px", 3.0)) if frente
					else float(mo.get("pulo_alcance_traseiro_px", 2.0))) * derr
		elif clipe == "slam":
			z -= 1.0 * sin(PI * f)
		out[nome] = Vector3(x, y, z)
	return out


## Movimento do tronco por clipe. Só as juntas do corpo; as patas são alvos
## no chão e a IK resolve a perna depois. `twist` (transversa) e `flex` (flexão
## do tronco) movem a frente e o traseiro em sentidos opostos; a cabeça é
## contra-rotacionada para não bater no bob/pitch. O tronco do galope (agachar,
## alongar, pitch, suspensão, bob e o afundamento no voo) é o bloco `corpo` da
## marcha em dados — nenhum clipe é consultado pelo nome aqui.
static func _mover_corpo(m: Dictionary, j: Dictionary, clipe: String, f: float, mo: Dictionary,
		salto_correndo: bool = false) -> void:
	var dy := 0.0
	var dz := 0.0
	var dx := 0.0
	var pitch_corpo := 0.0
	var twist := 0.0
	var flex := 0.0
	var marcha := _marcha(mo, clipe)
	var corpo: Dictionary = marcha.get("corpo", {}) if marcha.get("corpo") is Dictionary else {}
	var voo_bloco: Dictionary = marcha.get("voo", {}) if marcha.get("voo") is Dictionary else {}
	# 0..1 no envelope de suspensão da marcha (fase e meia-fase).
	var voo := _voo_galope(f, marcha) if not voo_bloco.is_empty() else 0.0
	if not corpo.is_empty():
		var susp := 0.0
		var fases: Array = corpo.get("suspensao_fases", [])
		var largura := float(corpo.get("suspensao_largura", 0.0))
		for inicio in fases:
			var ts := (f - float(inicio)) / largura
			if ts >= 0.0 and ts <= 1.0:
				susp = maxf(susp, float(corpo.get("suspensao_px", 0.0)) * sin(PI * ts))
		# A corrida anda agachada e alongada o tempo todo: a descida e a
		# extensão do tronco são constantes, SOMADAS à oscilação da marcha
		# (não é física nova — só a pose do clipe). As patas seguem no chão
		# (alvo y=0) e a IK resolve o resto.
		# No voo o tronco ainda AFUNDA: o galope esticado é baixo e longo
		# (patas à frente e atrás), não um pulo em pé.
		dy = susp + float(corpo.get("bob_px", 0.0)) * sin(TAU * f * 2.0) \
			- float(corpo.get("baixa_px", 0.0)) \
			- float(voo_bloco.get("baixa_px", 0.0)) * voo
		var g := float(corpo.get("pitch_gather_graus", 0.0))
		var s := float(corpo.get("pitch_suspensao_graus", 0.0))
		pitch_corpo = deg_to_rad((g + s) * 0.5 + (g - s) * 0.5 * cos(TAU * f * 2.0))
		flex = (-0.5 * float(corpo.get("flexao_px", 0.0)) * cos(TAU * f * 2.0)
			+ float(corpo.get("estica_px", 0.0)))
	match clipe:
		"idle":
			dy = float(mo.get("respira_px", 0.5)) * sin(TAU * f)
			dx = float(mo.get("idle_peso_lateral_px", 0.8)) * sin(TAU * f)
		"walk":
			dy = float(mo.get("corpo_px", 1.1)) * sin(TAU * f * 2.0 + 0.8)
			# Peso para o lado do apoio: soma dos pés plantados por quarto de
			# passo (+8, -6,5, -8, +6,5), suavizada.
			var apoio := _amostra_periodica([8.0, -6.5, -8.0, 6.5], f) / 8.0
			dx = float(mo.get("walk_balanco_lateral_px", 0.7)) * apoio
			twist = float(mo.get("walk_transversa_px", 1.5)) * sin(TAU * f)
		"jump_start":
			dy = -float(mo.get("pulo_agacha_px", 3.0)) * sin(PI * f)
			dy += 1.2 * _smoothstep(0.6, 1.0, f)
			if salto_correndo:
				dy -= 0.8
				pitch_corpo += deg_to_rad(6.0) * _smoothstep(0.1, 0.8, f)
		"jump_air":
			dy = 1.0 + 0.5 * sin(PI * f)
			if salto_correndo:
				dy = 0.2 + 0.2 * sin(PI * f)
				pitch_corpo = deg_to_rad(8.0)
		"jump_land":
			dy = -3.0 * sin(PI * f)
			if salto_correndo:
				dy -= 0.5
				pitch_corpo = deg_to_rad(5.0) * sin(PI * f)
		"charge":
			dy = -2.5
		"shot":
			dz = -2.5 * sin(PI * f)
		"hit":
			dz = -3.0 * sin(PI * f)
		"dig":
			dy = -5.0
		"stunned":
			dx = 2.6 * sin(TAU * f * 3.0)
		"bite":
			var ant := _chave([[0.0, 0.0], [0.2, 1.0], [0.45, 0.0], [1.0, 0.0]], f)
			dy = -1.0 * ant
			dz = -0.8 * ant
		"slam":
			# 0–15% agacha/junta; 15–40% dispara para frente; 40–60% impacto
			# baixo; 60–100% recuo/assenta. O +z projeta para CIMA em north.
			dz = _chave([[0.0, 0.0], [0.15, -1.0], [0.4, 11.0], [0.6, 11.0], [1.0, 0.0]], f)
			dy = _chave([[0.0, 0.0], [0.15, -1.5], [0.4, -1.0], [0.6, -1.0], [1.0, 0.0]], f)
	var frente := ["peito", "pescoco", "cabeca", "focinho", "orelha_e", "orelha_d",
		"ombro_e", "ombro_d"]
	var tras := ["quadril", "anca_e", "anca_d", "cauda_base", "cauda_ponta"]
	var centro := Vector3(0.0, 18.0, -2.0)
	for nome in m.get("corpo", []):
		if not j.has(nome):
			continue
		var q: Vector3 = j[nome]
		q += Vector3(dx, dy, dz)
		if nome in frente:
			q.z += twist + flex
		elif nome in tras:
			q.z -= twist + flex
		if absf(pitch_corpo) > 0.00001:
			var ry := q.y - centro.y
			var rz := q.z - centro.z
			q.y = centro.y + ry * cos(pitch_corpo) - rz * sin(pitch_corpo)
			q.z = centro.z + ry * sin(pitch_corpo) + rz * cos(pitch_corpo)
		j[nome] = q
	# Estabilização da cabeça: no passo ela absorve a maior parte do bob; na
	# marcha com bloco `corpo` contra-rotaciona o pitch do tronco em torno do
	# pescoço (`cabeca_contra_pitch` vem do JSON).
	if clipe == "walk":
		var counter := -dy * float(mo.get("walk_cabeca_estabiliza", 0.75))
		for nome in ["cabeca", "focinho", "orelha_e", "orelha_d"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) + Vector3(0, counter, 0)
	elif not corpo.is_empty() and absf(pitch_corpo) > 0.00001:
		_girar_x_nomes(j, ["cabeca", "focinho", "orelha_e", "orelha_d"],
			j["pescoco"], -pitch_corpo * float(corpo.get("cabeca_contra_pitch", 0.0)))
	# Voo da marcha: o pescoço se estende à frente e para baixo até a cabeça
	# ficar na linha do dorso, e as orelhas vão junto. Sem isso o alto da
	# silhueta continua sendo a orelha e o cão corre em pé, não esticado.
	if not voo_bloco.is_empty() and voo > 0.0 and j.has("peito") and j.has("pescoco"):
		var angulo := deg_to_rad(float(voo_bloco.get("pescoco_graus", 0.0))) * voo
		if absf(angulo) > 0.00001:
			_girar_x_nomes(j, ["pescoco", "cabeca", "focinho", "orelha_e", "orelha_d"],
				j["peito"], angulo)


## Cabeça, cauda e orelhas: gesto de leitura do clipe (não mexe em regra).
## A cauda e as orelhas usam atraso de fase (follow-through); o idle mantém a
## cauda baixa e as orelhas relaxadas, sem picos. O bloco `extras` da marcha
## (chicote da cauda e orelha varrida no voo) vale para qualquer clipe que a
## declare — nunca pelo nome do clipe.
static func _extras(j: Dictionary, clipe: String, f: float, mo: Dictionary,
		salto_correndo: bool = false) -> void:
	var cauda := float(mo.get("cauda_px", 1.8))
	var atraso := float(mo.get("walk_atraso_fase", 0.1))
	var marcha := _marcha(mo, clipe)
	var extras: Dictionary = marcha.get("extras", {}) if marcha.get("extras") is Dictionary else {}
	if not extras.is_empty():
		var chicote := float(extras.get("cauda_chicote_px", 0.0))
		# A cauda vai baixa e comprida, na linha do dorso: no galope esticado o
		# que alonga a cauda é o z (para trás), não o y. Subir a base criava o
		# ponto mais alto da silhueta, justamente o que o voo precisa achatar.
		var voo := _voo_galope(f, marcha)
		if j.has("cauda_base"):
			j["cauda_base"] = (j["cauda_base"] as Vector3) + Vector3(0,
				float(extras.get("cauda_voo_y", 0.0)) * voo,
				float(extras.get("cauda_voo_z", 0.0)) * voo)
		if j.has("cauda_ponta"):
			j["cauda_ponta"] = (j["cauda_ponta"] as Vector3) + Vector3(
				chicote * sin(TAU * (f - atraso)),
				float(extras.get("cauda_ponta_voo_y", 0.0)) * voo,
				float(extras.get("cauda_ponta_voo_z", 0.0)) * voo)
		# O pescoço esticado leva a cabeça para +z; as orelhas varridas para
		# trás (coladas no pescoço) recuperam a leitura de galope.
		var tras := float(extras.get("orelha_tras_px", 0.0))
		for nome in ["orelha_e", "orelha_d"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) + Vector3(0,
					-float(extras.get("orelha_baixa_px", 0.0)), -tras)
	elif clipe == "idle":
		var idle_c := float(mo.get("idle_cauda_px", 1.5))
		if j.has("cauda_base"):
			j["cauda_base"] = (j["cauda_base"] as Vector3) + Vector3(
				idle_c * 0.25 * sin(TAU * f), 0.0,
				idle_c * 0.15 * sin(TAU * (f - atraso)))
		if j.has("cauda_ponta"):
			j["cauda_ponta"] = (j["cauda_ponta"] as Vector3) + Vector3(
				idle_c * 1.00 * sin(TAU * f),
				idle_c * 0.25 * sin(TAU * (f - atraso)),
				idle_c * 0.20 * sin(TAU * (f - atraso)))
		var bob := float(mo.get("idle_cabeca_bob_px", 0.6))
		for nome in ["cabeca", "focinho"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) + Vector3(0, bob * sin(TAU * f + 0.4), 0)
		var orelha := float(mo.get("idle_orelha_px", 0.4))
		for nome in ["orelha_e", "orelha_d"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) + Vector3(0,
					-0.6 + orelha * sin(TAU * (f - atraso)), 0)
		_girar_y_nomes(j, ["cabeca", "focinho", "orelha_e", "orelha_d"], j["pescoco"],
			deg_to_rad(float(mo.get("idle_cabeca_graus", 4.0))) * sin(TAU * f))
	elif clipe == "walk":
		var a := cauda * sin(TAU * (f - atraso))
		if j.has("cauda_base"):
			j["cauda_base"] = (j["cauda_base"] as Vector3) + Vector3(a * 0.25, 0, 0)
		if j.has("cauda_ponta"):
			j["cauda_ponta"] = (j["cauda_ponta"] as Vector3) + Vector3(a * 0.75, 0, 0)
		for nome in ["orelha_e", "orelha_d"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) + Vector3(0, 0.35 * sin(TAU * (f - atraso)), 0)
	elif clipe == "jump_start":
		var arco := sin(PI * f)
		for nome in ["cabeca", "focinho"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) + Vector3(0, 2.0 * arco, 0)
	elif clipe == "jump_air":
		if j.has("cauda_ponta"):
			var extra := 1.0 if salto_correndo else 0.0
			j["cauda_ponta"] = (j["cauda_ponta"] as Vector3) + Vector3(0, 2.0 + extra, -1.0)
		for nome in ["orelha_e", "orelha_d"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) + Vector3(0, 1.0, -0.8)
	elif clipe == "jump_land":
		var arco := sin(PI * f)
		for nome in ["cabeca", "focinho"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) + Vector3(0, -1.0 * arco, 0)
	elif clipe == "bite":
		# 0–20% antecipa (-2 z), 20–45% ataca (+6 z e focinho +2),
		# 45–100% passa do alvo (+8) e assenta.
		var zc := _chave([[0.0, 0.0], [0.2, -2.0], [0.45, 6.0], [0.65, 8.0], [1.0, 0.0]], f)
		for nome in ["pescoco", "cabeca", "focinho", "orelha_e", "orelha_d"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) + Vector3(0, 0, zc)
		if j.has("focinho"):
			var abre := _chave([[0.0, 0.0], [0.2, -0.5], [0.42, 2.0], [0.65, 1.0], [1.0, 0.0]], f)
			j["focinho"] = (j["focinho"] as Vector3) + Vector3(0, 0, abre)
		if j.has("cauda_ponta"):
			var contra := _chave([[0.0, 0.0], [0.2, 1.2], [0.45, -1.0], [1.0, 0.0]], f)
			j["cauda_ponta"] = (j["cauda_ponta"] as Vector3) + Vector3(contra, 0, 0)
	elif clipe == "slam":
		# Impacto baixo e cabeça para baixo; o corpo já avançou no _mover_corpo.
		var baixa := _chave([[0.0, 0.0], [0.15, 0.0], [0.4, 1.2], [0.6, 1.5], [1.0, 0.0]], f)
		for nome in ["cabeca", "focinho", "orelha_e", "orelha_d"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) - Vector3(0, baixa, 0)
		if j.has("cauda_ponta"):
			var chicote := _chave([[0.0, 0.0], [0.15, 1.5], [0.5, -2.0], [1.0, 0.0]], f)
			j["cauda_ponta"] = (j["cauda_ponta"] as Vector3) + Vector3(chicote, 0, 0)
	elif clipe == "shot":
		var a := 2.5 * sin(PI * f)
		for nome in ["cabeca", "focinho"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) - Vector3(0, 0, a)
	elif clipe == "charge":
		var a := 3.0 * sin(PI * f)
		for nome in ["cabeca", "focinho"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) - Vector3(0, 0, a)
	elif clipe == "hit":
		var a := 1.5 * sin(PI * f)
		for nome in ["cabeca", "focinho"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) - Vector3(0, a, 0)
	elif clipe == "stunned":
		for nome in ["cabeca", "focinho"]:
			if j.has(nome):
				j[nome] = (j[nome] as Vector3) - Vector3(0, 3.0, 0)


## Tomba/levanta: baixa o corpo e estende o focinho no chão, sem sair do
## canvas. A morte vai de f=0 (em pé) a f=1 (deitado); get_up faz o inverso.
static func _deitar(j: Dictionary, f: float) -> void:
	var q := clampf(f, 0.0, 1.0)
	for nome in j:
		var p: Vector3 = j[nome]
		var y := p.y * (1.0 - 0.82 * q)
		var z := p.z + (p.y - y) * 0.35
		j[nome] = Vector3(p.x, y, z)


## --- ordem anatômica das pernas (regra do SOLVER; o dado não é tocado) ---
## Duas regras, e só duas:
##
## 1) POLO FIXO, SEM TROCA DE RAMO. A dobra é sempre a do polo do rig — o
##    cotovelo dianteiro para TRÁS, o joelho traseiro para a FRENTE e o jarrete
##    atrás do joelho (é a dobra do REPOUSO, medida em `dados/rig`). O solver
##    não escolhe ramo por violação: a versão que comparava violações trocava
##    a dianteira para a dobra espelhada e o cotovelo aparecia dobrado para a
##    frente. Uma perna, uma dobra.
##
## 2) LIMITE DE COMPRESSÃO, antes da IK, no ALVO do pé (`_alvo_compressao`).
##    Quando |topo→pata| cai abaixo de `dmin` a dobra do polo não existe mais
##    (as duas soluções violam a altura da junta) e o alvo é AFASTADO ao longo
##    da reta topo→pata até `dmin` — é o teto físico de dobra da perna, e ele
##    não estica osso: a pata é escrita a partir do alvo corrigido.
##    `dmin` (`_dmin_perna`): 2 ossos = sqrt(l2² − l1²) + folga; traseira de 3
##    = o mesmo sobre a cadeia toda, sqrt((l2 + l3)² − l1²) + folga.
##    SÓ NO BALANÇO: com a pata no chão a distância é grande e o clamp nunca
##    dispara em apoio (medido: 0 quadros), então o apoio não muda um pixel.
##
## Régua em px de mundo (a mesma de `violacao_perna`):
##   dianteira: y(cotovelo) ≤ y(ombro) + tol E cotovelo atrás da reta ombro→pata;
##   traseira: y(joelho) ≤ y(anca) + tol, joelho à frente da reta anca→pata,
##             y(jarrete) ≤ y(joelho) + tol E jarrete atrás da mesma reta.
## "Atrás" é o lado em que o cotovelo/jarrete de REPOUSO fica — o mesmo sinal
## do critério da auditoria ("z menor que o da reta ombro→pata naquele y"),
## medido em perpendicular para não explodir com a perna deitada.

## Distância com sinal de Q à reta P→F no plano (y,z); > 0 = atrás da reta,
## < 0 = à frente. Perpendicular (e não a diferença de z em y fixo) para não
## explodir quando a perna deita.
static func _lado_da_reta(P: Vector3, F: Vector3, Q: Vector3) -> float:
	var dy := F.y - P.y
	var dz := F.z - P.z
	var n := sqrt(dy * dy + dz * dz)
	if n < 0.000001:
		return 0.0
	return (-dz * (Q.y - P.y) + dy * (Q.z - P.z)) / n


## Violação (px) da ordem anatômica: 0 = configuração válida. Soma as folgas que
## faltam, então também serve de desempate quando nada é válido.
## `H` só é lido na traseira (jarrete); na dianteira passa-se o próprio joelho.
static func violacao_perna(P: Vector3, F: Vector3, K: Vector3, H: Vector3,
		tres_ossos: bool) -> float:
	var v := maxf(0.0, K.y - P.y - TOL_ANATOMIA)
	if tres_ossos:
		v += maxf(0.0, _lado_da_reta(P, F, K) - TOL_LADO)
		v += maxf(0.0, H.y - K.y - TOL_ANATOMIA)
		v += maxf(0.0, -_lado_da_reta(P, F, H) - TOL_LADO)
	else:
		v += maxf(0.0, -_lado_da_reta(P, F, K) - TOL_LADO)
	return v


## As duas dobras possíveis da IK de dois ossos para o par (P, alvo), na
## convenção da perna. `sentido` +1 = dobra do polo (a autoral: cotovelo atrás,
## joelho à frente); -1 = a espelhada. `|P-K| = l1` e `|K-alvo| = l2` nas duas,
## e a pata devolvida é a mesma.
static func _dobra(P: Vector3, alvo: Vector3, l1: float, l2: float, pole: Vector3,
		moderno: bool, sentido: float) -> Dictionary:
	if moderno:
		return ik_pole(P, alvo, l1, l2, pole if sentido > 0.0 else -pole, 0.9999)
	return _ik(P, alvo, l1, l2, sentido)


## Sentido da dobra do POLO na convenção de cada solver. `ik_pole` recebe o
## próprio polo (+1); o legado `_ik` não conhece polo e o seu perpendicular
## cresce para +z, então o polo que aponta para trás pede -1. Uma perna, uma
## dobra: nada de trocar de ramo por violação.
static func _sentido_polo(perna: Dictionary, moderno: bool) -> float:
	if moderno:
		return 1.0
	return -1.0 if (perna["pole"] as Vector3).z < 0.0 else 1.0


## Distância mínima (px) entre o topo da cadeia e o alvo do pé antes da IK: é
## onde a dobra do polo deixa de existir. Na cadeia de 2 ossos é o d em que o
## cotovelo fica no nível do ombro, sqrt(l2² − l1²); na traseira de 3, o mesmo
## sobre a cadeia toda — o primeiro osso (anca→joelho) contra a cadeia distal
## inteira (joelho→jarrete→pata), sqrt((l2 + l3)² − l1²). Rig em que o osso
## proximal é o mais longo (l1 ≥ l2) não tem esse limite: devolve só a folga.
static func _dmin_perna(perna: Dictionary) -> float:
	var l1 := float(perna["l1"])
	var distal := float(perna["l2"]) + float(perna.get("l3", 0.0))
	return sqrt(maxf(0.0, distal * distal - l1 * l1)) + FOLGA_COMPRESSAO


## LIMITE DE COMPRESSÃO: devolve o alvo do pé afastado do topo da cadeia até
## `dmin` ao longo da reta topo→pata, quando o alvo está mais perto que isso.
## `no_ar` é obrigatório: o apoio (pata no chão) não pode mudar de posição, e
## com a pata plantada a distância é grande — o clamp é regra de BALANÇO.
static func _alvo_compressao(P: Vector3, F: Vector3, no_ar: bool, dmin: float) -> Vector3:
	if not no_ar or dmin <= 0.0:
		return F
	var d := P.distance_to(F)
	if d < 0.000001 or d >= dmin:
		return F
	return P + (F - P) / d * dmin


## Traseira: o jarrete anda no círculo rígido do metatarso em volta da pata.
## Parte do offset de repouso (`base`, a solução de antes da regra) e, se a
## ordem não vale, gira o metatarso para BAIXO/ATRÁS — o sentido em que o
## jarrete desce — até a cadeia fechar; fica o MENOR giro válido. A faixa é a
## anatômica: jarrete acima do chão e atrás da pata. O joelho é SEMPRE o da
## dobra do polo (`_sentido_polo`): o giro escolhe onde fica o jarrete no
## círculo do metatarso, nunca o ramo da IK. Devolve joelho/jarrete; nada aqui
## move a pata (o metatarso tem raio l3 em torno dela por construção).
static func _perna_traseira(P: Vector3, F: Vector3, l1: float, l2: float, l3: float,
		offset: Vector3, pole: Vector3, moderno: bool, sentido: float,
		base: Dictionary) -> Dictionary:
	var k0: Vector3 = base["joelho"]
	var h0: Vector3 = base["jarrete"]
	var v0 := violacao_perna(P, F, k0, h0, true)
	if v0 <= TOL_ANATOMIA:
		return {"joelho": k0, "jarrete": h0, "violacao": v0, "giro": 0.0}
	var ang0 := atan2(offset.z, offset.y)
	var minimo := absf(l1 - l2)
	var maximo := l1 + l2
	var melhor := {"joelho": k0, "jarrete": h0, "violacao": v0, "giro": 0.0}
	for passo in 300:
		var giro := -deg_to_rad(float(passo + 1) * 0.5)
		var ang := ang0 + giro
		var H := F + Vector3(0.0, l3 * cos(ang), l3 * sin(ang))
		if H.y <= 0.0 or H.z >= F.z:
			continue
		var d := P.distance_to(H)
		if d < minimo + 0.0001 or d > maximo - 0.0001:
			continue
		var K: Vector3 = _dobra(P, H, l1, l2, pole, moderno, sentido)["joelho"]
		if K.distance_to(k0) > SALTO_DOBRA:
			continue
		var v := violacao_perna(P, F, K, H, true)
		if v < float(melhor["violacao"]) - 0.000001:
			melhor = {"joelho": K, "jarrete": H, "violacao": v, "giro": giro}
		if v <= TOL_ANATOMIA:
			return {"joelho": K, "jarrete": H, "violacao": v, "giro": giro}
	return melhor


## Escolhe o jarrete no círculo rígido de raio l3 em torno do alvo da pata.
## Preserva o offset de repouso se alcançável; caso contrário escolhe o ponto
## angularmente mais próximo que alcança a cadeia anca→joelho→jarrete. O círculo
## pode não tocar a faixa de alcance (alvo extremo): devolve seu ponto mais
## próximo e a correção de contato em pose() fica explícita, sem NaN/stretch.
static func _jarrete_alcancavel(P: Vector3, F: Vector3, l1: float, l2: float,
		l3: float, offset: Vector3) -> Vector3:
	var alvo := F + offset
	var minimo := absf(l1 - l2)
	var maximo := l1 + l2
	var d := P.distance_to(alvo)
	if d >= minimo and d <= maximo:
		return alvo
	var yz := Vector2(P.y - F.y, P.z - F.z)
	var raio := yz.length()
	if raio < 0.000001 or l3 < 0.000001:
		return alvo
	var base := (P - F).length_squared() + l3 * l3
	var divisor := 2.0 * l3 * raio
	var c_min := (base - maximo * maximo) / divisor
	var c_max := (base - minimo * minimo) / divisor
	var phi := yz.angle()
	var inicio := Vector2(offset.y, offset.z).angle()
	if c_min > 1.0:
		return F + Vector3(0.0, l3 * cos(phi), l3 * sin(phi))
	if c_max < -1.0:
		return F - Vector3(0.0, l3 * cos(phi), l3 * sin(phi))
	var c := clampf(cos(inicio - phi), maxf(-1.0, c_min), minf(1.0, c_max))
	var ang := acos(clampf(c, -1.0, 1.0))
	var a := phi + ang
	var b := phi - ang
	var theta := a if absf(wrapf(a - inicio, -PI, PI)) <= absf(wrapf(b - inicio, -PI, PI)) else b
	return F + Vector3(0.0, l3 * cos(theta), l3 * sin(theta))


## IK espacial estável: polo autoral define o semiplano, sem inversão de joelho
## quando a direção muda; a extensão reserva 2% para evitar singularidade.
## Ao mirar fora de alcance a pata aproxima o alvo sem esticar os segmentos.
static func ik_pole(p: Vector3, alvo: Vector3, l1: float, l2: float,
		pole: Vector3, limite := 0.98) -> Dictionary:
	if l1 <= 0.0 or l2 <= 0.0 or pole.length_squared() < 0.000001:
		return {}
	var delta := alvo - p
	var distancia := delta.length()
	var dir := delta / distancia if distancia > 0.000001 else Vector3.DOWN
	var minimo := absf(l1 - l2) + 0.00001
	var d := clampf(distancia, minimo, (l1 + l2) * clampf(limite, 0.5, 0.9999))
	var radial := pole - dir * pole.dot(dir)
	if radial.length_squared() < 0.000001:
		var fallback := Vector3.RIGHT if absf(dir.x) < 0.8 else Vector3.FORWARD
		radial = fallback - dir * fallback.dot(dir)
	radial = radial.normalized()
	var a := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(0.0, l1 * l1 - a * a))
	return {"joelho": p + dir * a + radial * h, "pata": p + dir * d,
		"alcancavel": distancia >= minimo and distancia <= d + 0.0001}


## Adaptador matemático legado; testes antigos medem exatamente sua curva.
static func _ik(P: Vector3, F: Vector3, l1: float, l2: float, bend: float) -> Dictionary:
	var delta := F - P
	var distancia := delta.length()
	var dir := delta / distancia if distancia > 0.000001 else Vector3.DOWN
	var d := clampf(distancia, maxf(absf(l1 - l2), 0.000001), l1 + l2)
	var pata := P + dir * d
	var a := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(0.0, l1 * l1 - a * a))
	var perp := Vector3(0.0, dir.z, -dir.y)
	perp = perp.normalized() if perp.length_squared() > 0.000001 else Vector3.FORWARD
	return {"joelho": P + dir * a + perp * (bend * h), "pata": pata}


# --- projeção, sockets e pose 2D ---

static func _projetar_pose(m: Dictionary, j: Dictionary, direcao: String, clipe: String, f: float,
		yaw_graus: float = NAN) -> Dictionary:
	var yaw_rad := deg_to_rad(yaw_efetivo(direcao, yaw_graus))
	var pitch_rad := pitch()
	var pr: Dictionary = {}
	var prof: Dictionary = {}
	for nome in j:
		var p := projetar(j[nome], yaw_rad, pitch_rad)
		pr[nome] = para_canvas(p, m)
		prof[nome] = p.z
	var sockets := _sockets(m, j, pr, prof, direcao, yaw_rad)
	return {"juntas": pr, "juntas_3d": j, "profundidade": prof, "sockets": sockets,
		"direcao": direcao, "clipe": clipe, "fase": f, "yaw": yaw_rad}


static func _sockets(m: Dictionary, j: Dictionary, pr: Dictionary, prof: Dictionary,
		direcao: String, yaw_rad: float = NAN) -> Dictionary:
	var out: Dictionary = {}
	var socks: Variant = m.get("sockets", {})
	if not socks is Dictionary:
		return out
	if not is_finite(yaw_rad):
		yaw_rad = yaw(direcao)
	var pitch_rad := pitch()
	for nome in socks:
		var s: Dictionary = socks[nome]
		var visivel: bool = not (direcao in s["oculto_em"])
		var pos := Vector2.ZERO
		var dep := 0.0
		if j.has(s["joint"]):
			var p3: Vector3 = (j[s["joint"]] as Vector3) + _vec(s["offset"])
			var p := projetar(p3, yaw_rad, pitch_rad)
			pos = para_canvas(p, m)
			dep = p.z
		else:
			visivel = false
		var item := {"pos": pos, "z": s["z"], "visivel": visivel, "profundidade": dep}
		if s.has("uso"):
			item["uso"] = s["uso"]
		out[nome] = item
	return out


# --- validação auxiliar ---

static func _vec(v: Variant) -> Vector3:
	if _v3(v):
		var a: Array = v
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO


static func _v3(v: Variant) -> bool:
	if not v is Array or (v as Array).size() != 3:
		return false
	for i in 3:
		var n: Variant = (v as Array)[i]
		if not (n is int or n is float) or not is_finite(float(n)):
			return false
	return true


static func _par(v: Variant) -> bool:
	if not v is Array or (v as Array).size() != 2:
		return false
	for i in 2:
		var n: Variant = (v as Array)[i]
		if not (n is int or n is float) or not is_finite(float(n)):
			return false
	return true


static func _num(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v))


## Marcha é dado OBRIGATÓRIO: `motion.marchas` (tabela por nome) e
## `motion.clipe_marcha` (clipe→marcha, com `walk` e `run` mapeados). Os blocos
## opcionais (`voo`, `corpo`, `extras`) também são dado: se um deles existe,
## todas as suas chaves são exigidas — o motor não completa valor por conta
## própria. Sem fallback de gait: rig sem a seção reprova aqui, fail-closed.
static func _validar_marchas(motion: Dictionary) -> String:
	var marchas: Variant = motion.get("marchas")
	if not marchas is Dictionary or (marchas as Dictionary).is_empty():
		return "motion.marchas ausente"
	for nome in marchas:
		var bruto: Variant = (marchas as Dictionary)[nome]
		if not bruto is Dictionary:
			return "marcha %s não é objeto" % nome
		var marcha: Dictionary = bruto
		var duty: Variant = marcha.get("duty")
		if not _num(duty) or float(duty) <= 0.0 or float(duty) >= 1.0:
			return "marcha %s com duty fora de (0,1)" % nome
		if not _num(marcha.get("passo_px")) or float(marcha.get("passo_px")) <= 0.0:
			return "marcha %s com passo_px inválido" % nome
		# Chave legada, não fonte: se o dado ainda declarar `ciclo_px`, ele
		# tem de ser exatamente `passo_px / duty` — divergir reprova.
		if marcha.has("ciclo_px"):
			if not _num(marcha.get("ciclo_px")):
				return "marcha %s com ciclo_px inválido" % nome
			if absf(float(marcha.get("ciclo_px")) - _ciclo(marcha)) > 0.000001:
				return "marcha %s com ciclo_px divergente de passo_px / duty" % nome
		if not _num(marcha.get("levanta_px")) or float(marcha.get("levanta_px")) < 0.0:
			return "marcha %s com levanta_px inválido" % nome
		if not _num(marcha.get("easing_levanta")) \
				or float(marcha.get("easing_levanta")) <= 0.0:
			return "marcha %s com easing_levanta inválido" % nome
		var avanco: Variant = marcha.get("avanco")
		if not avanco is Dictionary:
			return "marcha %s sem avanco" % nome
		for lado in ["dianteira", "traseira"]:
			var spec: Variant = (avanco as Dictionary).get(lado)
			if not spec is Dictionary:
				return "marcha %s sem avanco.%s" % [nome, lado]
			if String((spec as Dictionary).get("curva", "")) not in ["ease_in", "ease_out"]:
				return "marcha %s com avanco.%s.curva inválida" % [nome, lado]
			if not _num((spec as Dictionary).get("expoente")):
				return "marcha %s com avanco.%s.expoente inválido" % [nome, lado]
		for lado in avanco:
			if String(lado) not in ["dianteira", "traseira"]:
				return "marcha %s com lado desconhecido: %s" % [nome, str(lado)]
		var defas: Variant = marcha.get("defasagem")
		if not defas is Dictionary:
			return "marcha %s sem defasagem" % nome
		for pata in MARCHA_PATAS:
			if not _num((defas as Dictionary).get(pata)):
				return "marcha %s sem defasagem.%s" % [nome, pata]
		for pata in defas:
			if String(pata) not in MARCHA_PATAS:
				return "marcha %s com pata desconhecida: %s" % [nome, str(pata)]
		for bloco in MARCHA_BLOCOS:
			if not marcha.has(bloco):
				continue
			var b: Variant = marcha[bloco]
			if not b is Dictionary:
				return "marcha %s com %s não é objeto" % [nome, bloco]
			for chave in MARCHA_BLOCOS[bloco]:
				if not _num((b as Dictionary).get(chave)):
					return "marcha %s com %s.%s inválido" % [nome, bloco, chave]
		if marcha.has("corpo"):
			var fases: Variant = (marcha["corpo"] as Dictionary).get("suspensao_fases")
			if not fases is Array or (fases as Array).is_empty():
				return "marcha %s sem corpo.suspensao_fases" % nome
			for v in fases:
				if not _num(v):
					return "marcha %s com corpo.suspensao_fases inválido" % nome
		if marcha.has("extras") and not marcha.has("voo"):
			return "marcha %s com extras sem voo" % nome
	var mapa: Variant = motion.get("clipe_marcha")
	if not mapa is Dictionary:
		return "motion.clipe_marcha ausente"
	for clipe in ["walk", "run"]:
		if not (mapa as Dictionary).has(clipe):
			return "clipe_marcha sem " + clipe
	for clipe in mapa:
		if String(clipe) not in CLIPES:
			return "clipe_marcha com clipe desconhecido: " + str(clipe)
		var alvo: Variant = (mapa as Dictionary)[clipe]
		if not alvo is String or not (marchas as Dictionary).has(alvo):
			return "clipe_marcha.%s aponta marcha inexistente" % clipe
	return ""
