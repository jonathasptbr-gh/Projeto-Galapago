extends RefCounted
## Gesto → COMANDO (a intenção do jogador) — LÓGICA PURA, pela tabela "mapa"
## de dados/gestos.json. Quem decide se a criatura obedece é a camada de
## afinidade (P4); hoje ela obedece.
##
## v0.8 — MULTITOUCH: as ações vêm dos DEDOS EXTRAS (o primeiro dedo é o
## caminho, que não passa por aqui: `jogo/main.gd` o desenha ao vivo em
## `corpo.tracar`). A ação é lida no vetor do dedo extra, relativo à TELA:
## cima → ataque físico (tabela `deslize`); o `especial` (dois dedos abrindo)
## tem gesto próprio; o `segurar_inicio` com `defesa` → defender; sem `defesa`,
## segurar nela sem arrastar → escavar.
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
		"especial":
			cmd["acao"] = mapa.get("especial", "especial")
			var v: Vector2 = ev.get("vetor", Vector2.ZERO)
			if v.length() > 0.01:
				cmd["direcao"] = v.normalized()
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
