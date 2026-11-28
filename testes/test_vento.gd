extends "res://testes/caso.gd"
## Campo de vento da mata (sim/vento.gd): a regra pura — brisa, rajadas que
## varrem o mapa, vento forte, turbulência e as fontes de habilidade — e o
## contrato de `uniformizar()`, que a apresentação (shader, fatia seguinte) lê.
const Vento := preload("res://sim/vento.gd")


func _dados() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://dados/vento.json"))


## Pontos espalhados pelo mapa, para amostrar o campo.
func _pontos() -> Array:
	return [Vector2.ZERO, Vector2(1.5, -2.0), Vector2(-7.25, 3.5), Vector2(12.0, 9.75)]


func _rumo(ang: float) -> Vector2:
	return Vector2(cos(ang), sin(ang))


func test_dados_vento_json_tem_as_secoes_e_chaves() -> void:
	var d := _dados()
	checar(not d.is_empty(), "dados/vento.json parseia como dicionário")
	checar(d.has("_leia"), "_leia explica o arquivo")
	var esperado := {
		"brisa": ["forca", "direcao_rad", "vaivem_rad", "giro_s"],
		"rajada": ["forca", "periodo_s", "largura", "velocidade", "percurso"],
		"vento_forte": ["forca", "periodo_s", "duracao_s"],
		"turbulencia": ["forca", "escala", "velocidade"],
		"fonte": ["duracao_s", "raio", "teto"],
	}
	for secao in esperado:
		checar(d.has(secao), "seção %s presente" % secao)
		if not d.has(secao):
			continue
		checar(typeof(d[secao]) == TYPE_DICTIONARY, "seção %s é um objeto" % secao)
		for chave in esperado[secao]:
			checar(d[secao].has(chave), "%s.%s presente" % [secao, chave])
			var v = d[secao].get(chave)
			checar(typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT,
				"%s.%s é número" % [secao, chave])


func test_mesmo_cfg_e_mesmo_avancar_dao_o_mesmo_vetor() -> void:
	var a := Vento.new(_dados())
	var b := Vento.new(_dados())
	for i in range(20):
		a.avancar(0.13)
		b.avancar(0.13)
		for p in _pontos():
			var ca := a.campo(p)
			var cb := b.campo(p)
			igual(ca["vetor"], cb["vetor"], "determinismo do vetor no passo %d em %s" % [i, p])
			igual(ca["direcao"], cb["direcao"], "determinismo da direção no passo %d" % i)
			igual(ca["forca"], cb["forca"], "determinismo da força no passo %d" % i)
			igual(ca["rajada"], cb["rajada"], "determinismo da rajada no passo %d" % i)


func test_direcao_unitaria_e_forca_nao_negativa() -> void:
	for instante in [0.0, 0.7, 5.3, 20.0, 43.0]:
		var v := Vento.new(_dados())
		v.avancar(instante)
		for p in _pontos():
			perto(v.direcao(p).length(), 1.0, 0.001, "direção unitária em %s t=%.1f" % [p, instante])
			checar(v.forca(p) >= 0.0, "força não negativa em %s t=%.1f" % [p, instante])
			checar(is_finite(v.forca(p)), "força finita em %s t=%.1f" % [p, instante])


func test_avancar_acumula_tempo_e_ignora_dt_nao_positivo() -> void:
	var v := Vento.new(_dados())
	perto(v.tempo, 0.0, 0.0, "o tempo começa em 0")
	v.avancar(0.5)
	perto(v.tempo, 0.5, 0.000001, "avancar soma 0,5 s")
	v.avancar(0.0)
	perto(v.tempo, 0.5, 0.000001, "dt 0 é ignorado")
	v.avancar(-1.0)
	perto(v.tempo, 0.5, 0.000001, "dt negativo é ignorado")
	v.avancar(0.25)
	perto(v.tempo, 0.75, 0.000001, "0,25 s somam")
	var p := Vector2(1.0, 1.0)
	var antes := v.vetor(p)
	v.avancar(0.0)
	igual(v.vetor(p), antes, "dt 0 também não muda o campo")


func test_brisa_varia_no_tempo() -> void:
	var v := Vento.new(_dados())
	var p := Vector2(3.5, -2.25)
	var mn := INF
	var mx := -INF
	for i in range(300):
		v.avancar(0.1)
		var f := v.forca(p)
		mn = minf(mn, f)
		mx = maxf(mx, f)
	checar(mx - mn > 0.05, "a força varia em 30 s (de %.3f a %.3f)" % [mn, mx])


func test_vento_forte_entra_e_sai_do_envelope() -> void:
	var cfg := _dados()
	var dur := float(cfg["vento_forte"]["duracao_s"])
	for instante in [3.5, 20.0]:
		var com := Vento.new(cfg)
		var sem := Vento.new({"vento_forte": {"forca": 0.0}})
		com.avancar(instante)
		sem.avancar(instante)
		var esperado := 0.0
		if instante < dur:
			esperado = float(cfg["vento_forte"]["forca"]) * sin(PI * instante / dur)
		perto(float(com.uniformizar()["forca"]) - float(sem.uniformizar()["forca"]), esperado, 0.000001,
			"envelope do vento forte em t=%.1f" % instante)


func test_rajada_automatica_nasce_em_tempo_zero() -> void:
	var cfg := _dados()
	var v := Vento.new(cfg)
	var u := v.uniformizar()
	var k0 := float(cfg["rajada"]["forca"]) * (0.7 + 0.3 * sin(0.0))
	perto(float(u["frente_forca"]), k0, 0.000001, "força da primeira rajada (k = 0)")
	var rumo := _rumo(float(cfg["brisa"]["direcao_rad"]))
	var inicio := minf(float(cfg["rajada"]["percurso"]) * 0.5, 22.0)
	perto_v(u["frente"], -rumo * inicio, 0.001,
		"a primeira rajada nasce atrás do mapa, já perto da mata")
	igual(v.frentes_vivas(), 1, "uma rajada viva no início")
	v.avancar(float(cfg["rajada"]["periodo_s"]))
	igual(v.frentes_vivas(), 2, "no período nasce outra rajada")


func test_rajada_varre_o_mapa() -> void:
	var v := Vento.new(_dados())
	var centro := Vector2(0.0, 0.0)
	v.criar_frente(centro, 0.9)
	var perto_centro := v.forca(centro)
	var longe := v.forca(centro + Vector2(90.0, 0.0))
	checar(perto_centro > longe + 0.2,
		"no centro da frente (%.2f) há mais vento que longe (%.2f)" % [perto_centro, longe])
	var u := v.uniformizar()
	checar(float(u["frente_forca"]) > 0.0, "a frente aparece em uniformizar()")
	igual(u["frente"], centro, "uniformizar() dá o centro da frente mais forte")
	checar(v.rajada(centro) > v.rajada(centro + Vector2(90.0, 0.0)), "rajada() é uma banda")


func test_frente_anda_na_direcao_do_vento() -> void:
	var cfg := _dados()
	var v := Vento.new(cfg)
	var pos := Vector2(1.0, 2.0)
	v.criar_frente(pos, 0.9)
	var antes: Vector2 = v.uniformizar()["frente"]
	perto_v(antes, pos, 0.001, "a frente nasce onde foi criada")
	v.avancar(1.0)
	var depois: Vector2 = v.uniformizar()["frente"]
	var rumo := _rumo(float(cfg["brisa"]["direcao_rad"]))  # em t = 0 o vaivém é 0
	var delta := depois - antes
	perto(delta.dot(rumo), float(cfg["rajada"]["velocidade"]), 0.01,
		"andou velocidade × 1 s no rumo do vento")
	perto(delta.dot(Vector2(-rumo.y, rumo.x)), 0.0, 0.001, "sem desvio lateral")


func test_fonte_de_habilidade_soma_e_decai() -> void:
	var p := Vector2(2.0, -1.0)
	var v := Vento.new(_dados())
	var gemeo := Vento.new(_dados())
	var antes := v.vetor(p)
	var id := v.adicionar_fonte(p, Vector2(0.0, 1.0), 3.0, 4.0, 1.6)
	checar(id > 0, "adicionar_fonte devolve um id inteiro")
	checar(v.forca(p) > antes.length() + 1.0, "a fonte soma vento no ponto")
	igual(gemeo.vetor(p), antes, "o gêmeo sem fonte está no campo de antes")
	v.limpar_fontes()
	igual(v.vetor(p), antes, "limpar_fontes() devolve o campo de antes")
	# decai com a idade e desaparece no tempo de vida
	var id2 := v.adicionar_fonte(p, Vector2(0.0, 1.0), 3.0, 4.0, 1.6)
	checar(id2 > id, "o id cresce a cada fonte")
	gemeo.avancar(0.8)
	v.avancar(0.8)
	checar(v.forca(p) > gemeo.forca(p) + 0.5, "aos 0,8 s a fonte ainda empurra")
	gemeo.avancar(1.0)
	v.avancar(1.0)
	perto(v.forca(p), gemeo.forca(p), 0.000001, "aos 1,8 s a fonte morreu")


func test_uniformizar_chaves_tipos_e_direcao() -> void:
	var v := Vento.new(_dados())
	v.criar_frente(Vector2(3.0, 4.0), 0.8)
	v.adicionar_fonte(Vector2(1.0, 1.0), Vector2(1.0, 0.0), 1.0, 3.0, 1.0)
	v.avancar(0.5)
	var u := v.uniformizar()
	var esperadas := ["direcao", "forca", "frente", "frente_forca", "frente_largura", "tempo", "turbulencia"]
	igual(u.size(), esperadas.size(), "uniformizar() devolve só as chaves do contrato")
	for chave in esperadas:
		checar(u.has(chave), "uniformizar() tem %s" % chave)
	checar(typeof(u["direcao"]) == TYPE_VECTOR2, "direcao é Vector2")
	checar(typeof(u["frente"]) == TYPE_VECTOR2, "frente é Vector2")
	checar(typeof(u["forca"]) == TYPE_FLOAT, "forca é float")
	checar(typeof(u["frente_forca"]) == TYPE_FLOAT, "frente_forca é float")
	checar(typeof(u["frente_largura"]) == TYPE_FLOAT, "frente_largura é float")
	checar(typeof(u["turbulencia"]) == TYPE_FLOAT, "turbulencia é float")
	checar(typeof(u["tempo"]) == TYPE_FLOAT, "tempo é float")
	perto(u["direcao"].length(), 1.0, 0.001, "a direção do campo é unitária")
	checar(float(u["frente_largura"]) > 0.0, "a largura da frente é positiva")
	perto(float(u["tempo"]), 0.5, 0.000001, "o tempo do campo é o da simulação")
	checar(is_finite(float(u["forca"])) and is_finite(float(u["turbulencia"])), "números finitos")


func test_cfg_parcial_e_absurdo_nao_quebram() -> void:
	var padrao := Vento.new()
	var vazio := Vento.new({})
	var p := Vector2(2.0, -3.0)
	igual(vazio.vetor(p), padrao.vetor(p), "cfg {} usa o PADRAO")
	var parcial := Vento.new({"brisa": {"forca": 0.5}})
	checar(not is_equal_approx(float(parcial.uniformizar()["forca"]), float(padrao.uniformizar()["forca"])),
		"cfg parcial aplica a seção dada e mantém o resto")
	checar(is_equal_approx(float(parcial.uniformizar()["frente_largura"]), float(padrao.uniformizar()["frente_largura"])),
		"cfg parcial mantém os valores que não vieram")
	var casos := [
		["zero", {"rajada": {"largura": 0.0, "periodo_s": 0.0, "velocidade": -5.0, "percurso": 0.0}}],
		["nan", {"brisa": {"forca": NAN, "giro_s": 0.0}}],
		["negativo", {"turbulencia": {"forca": -50.0, "escala": 0.0, "velocidade": 0.0}}],
		["teto zero", {"fonte": {"teto": 0, "raio": 0.0, "duracao_s": 0.0}}],
		["infinito", {"vento_forte": {"forca": INF, "periodo_s": 0.0, "duracao_s": 0.0}}],
		["tipo errado", {"brisa": "quebrado", "rajada": 3, "fonte": []}],
	]
	for caso in casos:
		var v := Vento.new(caso[1])
		v.criar_frente(Vector2(1.0, 1.0), 2.0)
		v.adicionar_fonte(Vector2(1.0, 1.0), Vector2(1.0, 0.0), 5.0, 0.0, 0.0)
		for t in [0.0, 1.3, 60.0]:
			v.avancar(t)
			for q in _pontos():
				var vq := v.vetor(q)
				checar(is_finite(v.forca(q)), "força finita (%s)" % caso[0])
				checar(is_finite(vq.x) and is_finite(vq.y), "vetor finito (%s)" % caso[0])
				checar(v.forca(q) >= 0.0, "força não negativa (%s)" % caso[0])
			var u := v.uniformizar()
			checar(is_finite(float(u["forca"])), "uniformizar forca finita (%s)" % caso[0])
			checar(is_finite(float(u["frente_forca"])), "uniformizar frente_forca finita (%s)" % caso[0])
			checar(is_finite(float(u["frente_largura"])), "uniformizar frente_largura finita (%s)" % caso[0])
			checar(float(u["frente_largura"]) > 0.0, "largura positiva (%s)" % caso[0])
