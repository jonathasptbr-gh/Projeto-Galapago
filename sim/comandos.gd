extends RefCounted
## Gesto → COMANDO (a ação pedida) — LÓGICA PURA, pela tabela "mapa" de
## dados/gestos.json. É a INTENÇÃO do jogador; quem decide se a criatura
## obedece é a camada seguinte (afinidade, pacote P4 — hoje obedece sempre).
##
## Deslize: o ângulo é RELATIVO ao olhar da criatura (0 = frente, positivo =
## direita dela). A tela tem y para baixo, então "direita da criatura" é o
## sentido horário na tela — é o que Vector2.angle() já mede.
##
## Comando: {acao, direcao (unitário), alvo, pontos, setor, gesto}.
## Posições (alvo, pontos) vêm em pixels de MUNDO: a jogo/ converte antes.


## Ângulo do vetor em relação ao olhar, em graus, em (-180, 180].
static func angulo_relativo(vetor: Vector2, olhar: Vector2) -> float:
	var a := rad_to_deg(wrapf(vetor.angle() - olhar.angle(), -PI, PI))
	return 180.0 if is_equal_approx(a, -180.0) else a


## Setor do deslize pela tabela; {} se nenhum casar.
static func setor(angulo: float, tabela: Array) -> Dictionary:
	for s in tabela:
		if angulo >= float(s["de"]) and angulo <= float(s["ate"]):
			return s
	return {}


## Traduz um evento (já com "alvo"/"pontos" em mundo) num comando; {} = nada.
static func traduzir(ev: Dictionary, olhar: Vector2, mapa: Dictionary) -> Dictionary:
	var g: String = ev.get("gesto", "")
	var cmd := {"gesto": g, "alvo": ev.get("alvo", Vector2.ZERO), "pontos": ev.get("pontos_mundo", PackedVector2Array()),
		"direcao": Vector2(ev.get("vetor", Vector2.ZERO)).normalized(), "setor": ""}
	match g:
		"toque", "toque_duplo", "trajetoria":
			cmd["acao"] = mapa.get(g, "")
		"segurar_inicio":
			cmd["acao"] = mapa.get("segurar_na_criatura" if ev.get("na_criatura", false) else "segurar", "")
		"segurar_fim":
			cmd["acao"] = "soltar"
		"deslize":
			var ang := angulo_relativo(ev["vetor"], olhar)
			var s := setor(ang, mapa.get("deslize", []))
			if s.is_empty():
				return {}
			cmd["acao"] = s["acao"]
			cmd["setor"] = s["nome"]
			cmd["angulo"] = ang
		_:
			return {}
	if cmd["acao"] == "":
		return {}
	return cmd
