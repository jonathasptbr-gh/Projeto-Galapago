extends "res://testes/caso.gd"

const A := preload("res://sim/atualizacao.gd")
const URL := "https://github.com/jonathasptbr-gh/Projeto-Galapago/releases/download/dev/projeto-galapago-dev.apk"


func _manifesto(codigo := 9, url := URL, bytes := 26000000) -> String:
	return JSON.stringify({"versao_codigo": codigo, "versao_nome": "0.3.1-b%d" % codigo, "apk": url, "bytes": bytes})


func test_ler_manifesto_valido() -> void:
	var m := A.ler_manifesto(_manifesto())
	igual(int(m["versao_codigo"]), 9, "código")
	igual(int(m["bytes"]), 26000000, "bytes")


func test_ler_manifesto_invalido() -> void:
	igual(A.ler_manifesto("não é json"), {}, "lixo")
	igual(A.ler_manifesto('{"versao_codigo": 9}'), {}, "faltam campos")
	igual(A.ler_manifesto(JSON.stringify({"versao_codigo": "9", "versao_nome": "a", "apk": URL, "bytes": 1})), {}, "código como texto")
	igual(A.ler_manifesto(_manifesto(9, URL, 0)), {}, "tamanho zero")
	igual(A.ler_manifesto(_manifesto(9, URL, 400 * 1024 * 1024)), {}, "acima do teto")


func test_host_travado() -> void:
	checar(A.host_ok(URL), "github.com https")
	checar(not A.host_ok(URL.replace("https://", "http://")), "http recusado")
	checar(not A.host_ok("https://github.com.mal.com/x.apk"), "domínio parecido recusado")
	checar(not A.host_ok("https://exemplo.com/github.com/x.apk"), "outro host recusado")
	igual(A.ler_manifesto(_manifesto(9, "https://exemplo.com/a.apk")), {}, "manifesto com host alheio")


func test_deve_atualizar() -> void:
	var m := A.ler_manifesto(_manifesto())
	checar(A.deve_atualizar(8, m), "8 < 9 atualiza")
	checar(not A.deve_atualizar(9, m), "mesma versão não")
	checar(not A.deve_atualizar(10, m), "local mais novo não")
	checar(not A.deve_atualizar(0, m), "build local (0) nunca")
	checar(not A.deve_atualizar(8, {}), "manifesto vazio nunca")


func test_download_completo() -> void:
	var m := A.ler_manifesto(_manifesto())
	checar(A.download_completo(26000000, m), "tamanho exato")
	checar(not A.download_completo(25999999, m), "truncado")
	checar(not A.download_completo(26000000, {}), "sem manifesto")


func test_tamanho_legivel() -> void:
	igual(A.tamanho_legivel(26528563), "25,3 MB", "MB com vírgula")
