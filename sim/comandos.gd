extends RefCounted
## Gesto → COMANDO (a intenção do jogador) — LÓGICA PURA, pela tabela "mapa"
## de dados/gestos.json. Quem decide se a criatura obedece é a camada de
## afinidade (P4); hoje ela obedece.
##
## v0.18 — UM DEDO SÓ. O caminho é desenhado ao vivo pelo `jogo/main.gd` em
## `corpo.tracar`; aqui passam os gestos que viram comando: toque (**tiro**: o
## corpo começa a carga de 1 s e dispara sozinho), toque duplo (pulo),
## segurar (**correr** com caminho, habilidade sem caminho) e a trajetória
## (mover, já desenhada). O reconhecedor não tem mais pausa de saída: o toque
## simples fica pendente só pela janela do duplo e o segurar vale em
## `segurar_min_ms` em qualquer lugar.
##
## O ATAQUE NÃO PASSA POR AQUI: ele nasce da FORMA do caminho em
## `sim/formas.gd` → `sim/corpo.gd` (hoje só a travessia; o LAÇO está desligado
## desde a v0.11.5 — `formas.laco_ataque`).
##
## Comando: {acao, alvo, pontos, direcao, alcance, gesto}.

const AO_ALCANCE := 110.0


## Traduz um evento (já com "alvo"/"pontos" em mundo) num comando; {} = nada.
static func traduzir(ev: Dictionary, mapa: Dictionary) -> Dictionary:
	var g: String = ev.get("gesto", "")
	var cmd := {
		"gesto": g, "alvo": ev.get("alvo", Vector2.ZERO),
		"pontos": ev.get("pontos_mundo", PackedVector2Array()),
		"direcao": Vector2(ev.get("vetor", Vector2.ZERO)).normalized(),
		"alcance": AO_ALCANCE,
	}
	match g:
		"toque", "toque_duplo", "trajetoria":
			cmd["acao"] = mapa.get(g, "")
		"segurar_inicio":
			cmd["acao"] = mapa.get("segurar", "segurar")
		"segurar_fim":
			cmd["acao"] = "soltar_segurar"
		_:
			return {}
	if cmd["acao"] == "":
		return {}
	return cmd
