extends RefCounted
## Gesto → COMANDO (a intenção do jogador) — LÓGICA PURA, pela tabela "mapa"
## de dados/gestos.json. Quem decide se a criatura obedece é a camada de
## afinidade (P4); hoje ela obedece.
##
## v0.6 — SETORES DE TELA: o ângulo é o do vetor do dedo na TELA (0° = direita,
## -90° = cima, +90° = baixo). Não depende do olhar da criatura. A tabela
## `deslize` de dados/gestos.json decide a ação: cima → ataque físico; lados →
## especiais; baixo → esquiva. O caminho (trajetoria) vem da âncora; segurar em
## cima dela (sem `defesa`) → escavar; segurar depois de um deslize para baixo
## (`defesa: true`) → defender.
##
## Comando: {acao, lado, alcance, alvo, pontos, setor, angulo, direcao, gesto}.

const AO_ALCANCE := 110.0


## Setor do deslize pela tabela; {} se nenhum casar. A tabela é de ângulos de
## tela e pode ter mais de uma faixa para o mesmo setor (esquerda em ±180°).
static func setor(angulo: float, tabela: Array) -> Dictionary:
	for s in tabela:
		# tolerância: o ângulo de uma diagonal pode chegar como -135,00001
		if angulo >= float(s["de"]) - 0.01 and angulo <= float(s["ate"]) + 0.01:
			return s
	return {}


## Traduz um evento (já com "alvo"/"pontos" em mundo) num comando; {} = nada.
static func traduzir(ev: Dictionary, mapa: Dictionary) -> Dictionary:
	var g: String = ev.get("gesto", "")
	var cmd := {"gesto": g, "alvo": ev.get("alvo", Vector2.ZERO), "pontos": ev.get("pontos_mundo", PackedVector2Array()),
		"direcao": Vector2(ev.get("vetor", Vector2.ZERO)).normalized(), "setor": "", "angulo": 0.0,
		"lado": 0.0, "alcance": AO_ALCANCE}
	match g:
		"toque", "toque_duplo", "trajetoria":
			cmd["acao"] = mapa.get(g, "")
		"segurar_inicio":
			if ev.get("defesa", false):
				cmd["acao"] = mapa.get("segurar", "")
			else:
				cmd["acao"] = mapa.get("segurar_na_criatura" if ev.get("na_criatura", false) else "segurar", "")
		"segurar_fim":
			cmd["acao"] = "soltar"
		"deslize":
			var vetor: Vector2 = ev.get("vetor", Vector2.ZERO)
			if vetor.length() < 0.01:
				return {}
			var ang := rad_to_deg(vetor.angle())
			var s := setor(ang, mapa.get("deslize", []))
			if s.is_empty():
				return {}
			cmd["acao"] = s["acao"]
			cmd["setor"] = s["nome"]
			cmd["angulo"] = ang
			cmd["direcao"] = vetor.normalized()
			if s.has("lado"):
				cmd["lado"] = float(s["lado"])
		_:
			return {}
	if cmd["acao"] == "":
		return {}
	return cmd
