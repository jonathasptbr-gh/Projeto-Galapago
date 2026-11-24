extends RefCounted
## ANIMAÇÃO — máquina de estados e catálogo de clipes (LÓGICA PURA).
##
## Recebe o RETRATO do corpo (o que ele está fazendo) e devolve QUAL clipe
## desenhar, com que prioridade e em que fase. Não decide regra de jogo: dano,
## alcance e tempo continuam em `sim/corpo.gd`; aqui só se escolhe o desenho.
##
## Camadas (menor prioridade vence): morte 0 · atordoado 1 · dano 2 · ação 3 ·
## salto 4 · base 5 · overlay 6 · expressão 7. Um clipe de uma vez: overlay
## simultâneo é assunto da arte (peças separadas), não do contrato atual.

const CAMADAS := ["base", "salto", "acao", "reacao", "overlay", "expressao"]
const OBRIGATORIOS := [
	"idle", "walk", "run", "jump_start", "jump_air", "jump_land",
	"charge", "shot", "bite", "slam", "dig", "hit", "stunned", "death", "get_up", "sleep"
]


static func de_json(texto: String) -> Dictionary:
	var v: Variant = JSON.parse_string(texto)
	if not v is Dictionary:
		return {}
	var m: Dictionary = v
	if validar(m) != "":
		return {}
	return m


## Primeiro erro; vazio = catálogo válido.
static func validar(m: Dictionary) -> String:
	if int(m.get("schema_version", 0)) != 1:
		return "schema_version != 1"
	var cat: Variant = m.get("catalogo")
	if not cat is Dictionary or (cat as Dictionary).is_empty():
		return "catálogo vazio"
	for id in cat:
		var c: Variant = cat[id]
		if not c is Dictionary:
			return "clipe %s não é objeto" % id
		var item: Dictionary = c
		if not (item.get("camada") in CAMADAS):
			return "clipe %s: camada inválida" % id
		if not item.get("loop") is bool:
			return "clipe %s: loop inválido" % id
		var dur := float(item.get("duracao_ms", 0.0))
		if not is_finite(dur) or dur <= 0.0:
			return "clipe %s: duração inválida" % id
		if not (item.get("prioridade") is int or item.get("prioridade") is float):
			return "clipe %s: prioridade inválida" % id
		for campo in ["requer", "interrompe", "nao_interrompe"]:
			if not item.get(campo) is Array:
				return "clipe %s: %s inválido" % [id, campo]
		var janelas: Variant = item.get("janelas")
		if not janelas is Array:
			return "clipe %s: janelas inválidas" % id
		for j in janelas:
			if not j is Dictionary or not j.get("evento") is String:
				return "clipe %s: janela sem evento" % id
			var ms := float(j.get("ms", -1.0))
			if ms < 0.0 or ms >= dur:
				return "clipe %s: janela fora da duração" % id
			if not j.get("socket") is String:
				return "clipe %s: janela sem socket" % id
	for obrig in OBRIGATORIOS:
		if not (cat as Dictionary).has(obrig):
			return "clipe obrigatório ausente: " + obrig
	if not m.get("prioridades") is Dictionary:
		return "prioridades ausentes"
	return ""


## Catálogo privado da pele: só o canino lê seus tempos mais ágeis.
## O catálogo comum permanece byte a byte igual para os demais rigs.
static func para_rig(m: Dictionary, rig: Dictionary) -> Dictionary:
	var copia := m.duplicate(true)
	if String(rig.get("familia", "")) != "canino":
		return copia
	var cat: Dictionary = copia.get("catalogo", {})
	var clips: Dictionary = rig.get("clips", {})
	for id in clips:
		if cat.has(id):
			cat[id]["duracao_ms"] = roundi(float(clips[id]["duracao_s"]) * 1000.0)
	return copia


static func clipe(m: Dictionary, id: String) -> Dictionary:
	var cat: Dictionary = m.get("catalogo", {})
	return cat.get(id, {})


static func prioridade(m: Dictionary, id: String) -> int:
	var c := clipe(m, id)
	if c.is_empty():
		return 99
	return int(c.get("prioridade", 99))


## Retrato do corpo: o que a máquina precisa saber. `andando` é medido pela
## apresentação (deslocamento por quadro); o resto vem do próprio corpo.
static func retrato(corpo: RefCounted, andando: bool, saltou := false, pousou := false) -> Dictionary:
	return {
		"morto": false,
		"atordoado": corpo.atordoado(),
		"dano": false,
		"golpe": String(corpo.ataque),
		"carregando": corpo.carregando(),
		"escavando": bool(corpo.escavando),
		"no_ar": corpo.no_ar(),
		"saltou": saltou,
		"pousou": pousou,
		"correndo": corpo.correndo(),
		# MODO DA CÂMERA (v0.34): de LONGE não existe caminhada — andando, ela
		# já está em CORRIDA (o clipe base é o run). De PERTO o walk continua.
		"caminhada": corpo.caminhada_existe(),
		# Só para a pose de decolagem: cauda física acelera enquanto há rota.
		"impulso_corrida": andando and corpo.em_rota() and corpo._fator_sprint() > 1.001,
		"andando": andando,
		"dormindo": false,
	}


## Qual clipe o estado pede (sem olhar o clipe atual).
static func desejado(entrada: Dictionary, m: Dictionary) -> String:
	if bool(entrada.get("morto", false)):
		return "death"
	if bool(entrada.get("atordoado", false)):
		return "stunned"
	if bool(entrada.get("dano", false)):
		return "hit"
	match String(entrada.get("golpe", "")):
		"ataque":
			return "bite"
		"batida":
			return "slam"
	if bool(entrada.get("carregando", false)):
		return "charge"
	if bool(entrada.get("saltou", false)):
		return "jump_start"
	if bool(entrada.get("pousou", false)):
		return "jump_land"
	if bool(entrada.get("no_ar", false)):
		return "jump_air"
	if bool(entrada.get("escavando", false)):
		return "dig"
	if bool(entrada.get("dormindo", false)):
		return "sleep"
	if bool(entrada.get("andando", false)):
		# De LONGE (sem caminhada) andar JÁ É correr; o sprint só acelera.
		if bool(entrada.get("correndo", false)) or not bool(entrada.get("caminhada", true)):
			return "run"
		return "walk"
	return "idle"


## Resolve o clipe agora. `memoria` = {"id", "desde_ms"}; devolve a memória nova.
## Clipe de uma vez (loop=false) segura a cena até o fim, salvo ameaça de
## prioridade MENOR (mais urgente). Loop troca quando o pedido tem prioridade
## igual ou menor.
static func resolver(entrada: Dictionary, m: Dictionary, memoria: Dictionary, agora_ms: float) -> Dictionary:
	var proxima := _resolver_base(entrada, m, memoria, agora_ms)
	var id := String(proxima.get("id", ""))
	if id.begins_with("jump_"):
		# Metadado exclusivamente visual: conserva o impulso da corrida entre
		# início, ar e pouso mesmo quando correndo() deixa de valer no ar.
		var anterior := String(memoria.get("id", ""))
		if anterior.begins_with("jump_"):
			proxima["salto_correndo"] = bool(memoria.get("salto_correndo", false))
		else:
			proxima["salto_correndo"] = bool(entrada.get("impulso_corrida", false)) or bool(entrada.get("correndo", false)) or anterior == "run"
	return proxima


static func _resolver_base(entrada: Dictionary, m: Dictionary, memoria: Dictionary, agora_ms: float) -> Dictionary:
	var cat: Dictionary = m.get("catalogo", {})
	if cat.is_empty():
		return {"id": "idle", "desde_ms": agora_ms}
	var alvo := desejado(entrada, m)
	if not cat.has(alvo):
		alvo = "idle"
	var id := String(memoria.get("id", ""))
	var desde := float(memoria.get("desde_ms", agora_ms))
	if id == "" or not cat.has(id):
		return {"id": alvo, "desde_ms": agora_ms}
	if id == alvo:
		return {"id": id, "desde_ms": desde}
	var atual: Dictionary = cat[id]
	var segurando: bool = bool(atual["loop"]) or (agora_ms - desde) < float(atual["duracao_ms"])
	if segurando:
		var p_alvo := prioridade(m, alvo)
		var p_atual := prioridade(m, id)
		# Mais urgente (número menor) sempre corta; igual só segura fora da base.
		if p_alvo > p_atual:
			return {"id": id, "desde_ms": desde}
		if p_alvo == p_atual and String(atual["camada"]) != "base":
			# Um clipe de UMA VEZ pedido corta loop de mesma prioridade
			# (pouso corta o ar; mordida corta a carga).
			if not bool(clipe(m, alvo).get("loop", true)):
				return {"id": alvo, "desde_ms": agora_ms}
			return {"id": id, "desde_ms": desde}
	return {"id": alvo, "desde_ms": agora_ms}


## Janelas de evento ativas em `ms` do clipe (largura padrão de 150 ms).
## O evento é só de DESENHO: dano/alcance continuam em sim/corpo.gd.
static func janela_ativa(m: Dictionary, id: String, ms: float, largura_ms := 150.0) -> Array:
	var c := clipe(m, id)
	if c.is_empty():
		return []
	var out: Array = []
	for j in c.get("janelas", []):
		var inicio := float(j.get("ms", 0.0))
		if ms >= inicio and ms <= inicio + largura_ms:
			out.append(j)
	return out


## Fase 0..1 (loop fecha em 0; clipe de uma vez para em 1).
static func fase(memoria: Dictionary, m: Dictionary, agora_ms: float) -> float:
	var id := String(memoria.get("id", ""))
	var c := clipe(m, id)
	if c.is_empty():
		return 0.0
	var dur := maxf(float(c["duracao_ms"]), 0.001)
	var t := maxf(agora_ms - float(memoria.get("desde_ms", agora_ms)), 0.0)
	if bool(c["loop"]):
		return fmod(t / dur, 1.0)
	return clampf(t / dur, 0.0, 1.0)
