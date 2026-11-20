extends RefCounted
## Decisão de atualização — LÓGICA PURA (HTTP, arquivo e tela ficam em
## jogo/atualizador.gd). O mesmo método do Áudio Visual IASD (ShellUpdater.kt):
## o manifesto `versao.json` vai como asset da Release `dev` do repositório
## público; o app o lê, baixa o APK que ele aponta e entrega ao instalador.
##
## Segurança, como lá: o Android só instala por cima um APK assinado com a
## MESMA chave — um arquivo adulterado simplesmente não instala. O que fica
## aqui é o que impede um campo alterado de apontar para outro servidor
## (host travado + https) e um download cortado de chegar ao instalador
## (tamanho conferido).

const CAMPOS := ["versao_codigo", "versao_nome", "apk", "bytes"]
const HOSTS_OK := ["github.com"]
const TETO_BYTES := 300 * 1024 * 1024


## Lê o manifesto. Devolve {} se o JSON for inválido, faltar campo ou o
## endereço do APK não for https em github.com.
static func ler_manifesto(texto: String) -> Dictionary:
	var j := JSON.new()
	if j.parse(texto) != OK:  # parse() não imprime erro; parse_string() imprime
		return {}
	var d = j.data
	if typeof(d) != TYPE_DICTIONARY:
		return {}
	for c in CAMPOS:
		if not d.has(c):
			return {}
	for c in ["versao_codigo", "bytes"]:
		if typeof(d[c]) != TYPE_FLOAT and typeof(d[c]) != TYPE_INT:
			return {}
	if not host_ok(str(d["apk"])) or int(d["bytes"]) <= 0 or int(d["bytes"]) > TETO_BYTES:
		return {}
	return d


## https e host da lista (o redirecionamento do download para o armazenamento
## do GitHub é seguido pelo HTTPRequest; o que se trava é o endereço anunciado).
static func host_ok(url: String) -> bool:
	if not url.begins_with("https://"):
		return false
	var resto := url.substr(8)
	var host := resto.split("/", true, 1)[0].to_lower()
	return host in HOSTS_OK


## Atualiza só se o build local é de verdade (> 0; 0 = rodando fora de um APK
## do CI) e o manifesto anuncia código MAIOR.
static func deve_atualizar(build_local: int, manifesto: Dictionary) -> bool:
	if build_local <= 0 or manifesto.is_empty():
		return false
	return int(manifesto["versao_codigo"]) > build_local


## O download está inteiro? (o laço de leitura acabar não prova que acabou o
## arquivo — a lição da K5 do IASD: corpo truncado chegava ao instalador.)
static func download_completo(lidos: int, manifesto: Dictionary) -> bool:
	return not manifesto.is_empty() and lidos == int(manifesto["bytes"])


## Texto curto do tamanho, para o aviso ("25,3 MB").
static func tamanho_legivel(bytes: int) -> String:
	return ("%.1f MB" % (bytes / 1048576.0)).replace(".", ",")


## Código do build a partir do nome ("0.5.0-b13" → 13); -1 se não houver.
## Usado pela fonte alternativa (API da Release, que não traz o código).
static func codigo_do_nome(nome: String) -> int:
	var partes := nome.split("-b")
	if partes.size() < 2:
		return -1
	var n := partes[partes.size() - 1].strip_edges()
	return int(n) if n.is_valid_int() else -1


## Manifesto a partir do JSON da API da Release (fonte alternativa): o asset
## .apk e o versao.json estão em `assets`.
static func manifesto_da_api(dados: Dictionary) -> Dictionary:
	if not dados.has("assets"):
		return {}
	var apk := ""
	var bytes := 0
	for a in dados["assets"]:
		if str(a.get("name", "")).ends_with(".apk"):
			apk = str(a.get("browser_download_url", ""))
			bytes = int(a.get("size", 0))
	var nome := str(dados.get("tag_name", "")) + ""
	var codigo := codigo_do_nome(str(dados.get("name", "")))
	if codigo < 0:
		codigo = codigo_do_nome(str(dados.get("tag_name", "")))
	if apk == "" or codigo < 0:
		return {}
	return {"versao_codigo": codigo, "versao_nome": str(dados.get("name", nome)),
		"apk": apk, "bytes": bytes, "sha256": "", "commit": "", "publicado_em": str(dados.get("published_at", ""))}
