extends "res://testes/caso.gd"

const A := preload("res://sim/atualizacao.gd")
const OK := '{"versao_codigo": 9, "versao_nome": "0.3.0-b9", "apk": "https://x/y.apk"}'


func test_ler_canal_valido() -> void:
	var c := A.ler_canal(OK)
	igual(int(c["versao_codigo"]), 9, "código")
	igual(c["versao_nome"], "0.3.0-b9", "nome")


func test_ler_canal_invalido() -> void:
	igual(A.ler_canal("não é json"), {}, "lixo")
	igual(A.ler_canal('{"versao_codigo": 9}'), {}, "faltam campos")
	igual(A.ler_canal('{"versao_codigo": "9", "versao_nome": "a", "apk": "b"}'), {}, "código como texto")


func test_deve_atualizar() -> void:
	var c := A.ler_canal(OK)
	checar(A.deve_atualizar(8, c), "8 < 9 atualiza")
	checar(not A.deve_atualizar(9, c), "mesma versão não")
	checar(not A.deve_atualizar(10, c), "local mais novo não")
	checar(not A.deve_atualizar(0, c), "build local (0) nunca")
	checar(not A.deve_atualizar(8, {}), "canal vazio nunca")
