extends "res://testes/caso.gd"
## Carregador de rigs do jogo: os três das âncoras entram, id inválido não.

const Rigs := preload("res://jogo/rigs.gd")


func test_carrega_as_tres_ancoras() -> void:
	for id in ["canino", "serpente", "ave"]:
		var m := Rigs.carregar(id)
		checar(not m.is_empty(), "rig carregado: " + id)
		igual(String(m.get("id", "")), id, "id do rig: " + id)


func test_id_invalido_nao_entra() -> void:
	igual(Rigs.carregar("inexistente").size(), 0, "rig ausente devolve vazio")
	igual(Rigs.carregar("../canino").size(), 0, "traversal não carrega")
