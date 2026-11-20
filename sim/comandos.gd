extends RefCounted
## Gesto → COMANDO (a intenção do jogador) — LÓGICA PURA, pela tabela "mapa"
## de dados/gestos.json. Quem decide se a criatura obedece é a camada de
## afinidade (P4); hoje ela obedece.
##
## Regras (v0.5):
## - arrasto começando PERTO da criatura = ROTA (vem como "trajetoria");
## - gesto de ação só FORA da área dela; o SETOR é relativo ao OLHAR:
##   frente → ataque (a direção do golpe é do alvo/rota, não do dedo),
##   esquerda/direita → esquiva para aquele lado;
## - toque = travar a mira (ou interagir); toque duplo = pular;
##   segurar = defender (para a rota); segurar nela = escavar.
##
## Comando: {acao, lado, alcance, alvo, pontos, setor, direcao, gesto}.

const AO_ALCANCE := 110.0


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
		"direcao": Vector2(ev.get("vetor", Vector2.ZERO)).normalized(), "setor": "", "lado": 0.0, "alcance": AO_ALCANCE}
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
			if s.has("lado"):
				cmd["lado"] = float(s["lado"])
		_:
			return {}
	if cmd["acao"] == "":
		return {}
	return cmd
