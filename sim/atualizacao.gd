extends RefCounted
## Decisão de atualização — LÓGICA PURA (o HTTP fica em jogo/atualizador.gd).
##
## O canal público (repositório Projeto-Galapago-canal, arquivo canal.json)
## só diz o número da versão; o APK continua no repositório privado e baixa
## pelo navegador logado no GitHub (decisão do operador, 2026-11-20).

const CAMPOS := ["versao_codigo", "versao_nome", "apk"]


## Lê o texto do canal. Devolve {} se faltar campo ou o JSON for inválido.
static func ler_canal(texto: String) -> Dictionary:
	var j := JSON.new()
	if j.parse(texto) != OK:  # parse() não imprime erro; parse_string() imprime
		return {}
	var d = j.data
	if typeof(d) != TYPE_DICTIONARY:
		return {}
	for c in CAMPOS:
		if not d.has(c):
			return {}
	if typeof(d["versao_codigo"]) != TYPE_FLOAT and typeof(d["versao_codigo"]) != TYPE_INT:
		return {}
	return d


## Atualiza só se o build local é de verdade (> 0; 0 = rodando fora de um APK
## do CI) e o canal anuncia código MAIOR.
static func deve_atualizar(build_local: int, canal: Dictionary) -> bool:
	if build_local <= 0 or canal.is_empty():
		return false
	return int(canal["versao_codigo"]) > build_local
