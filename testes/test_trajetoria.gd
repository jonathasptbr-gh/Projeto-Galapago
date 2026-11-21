extends "res://testes/caso.gd"

const T := preload("res://sim/trajetoria.gd")


func test_amostrar_descarta_pontos_proximos_e_guarda_o_final() -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(5, 0), Vector2(6, 0)])
	var a := T.amostrar(p, 3.0)
	igual(a, PackedVector2Array([Vector2(0, 0), Vector2(5, 0), Vector2(6, 0)]), "amostragem")


func test_amostrar_vazio() -> void:
	igual(T.amostrar(PackedVector2Array(), 3.0).size(), 0, "vazio")


func test_comprimento_de_l() -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(3, 0), Vector2(3, 4)])
	perto(T.comprimento(p), 7.0, 0.0001, "L 3+4")


func test_ponto_em_anda_sobre_os_segmentos() -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(3, 0), Vector2(3, 4)])
	perto_v(T.ponto_em(p, 0.0), Vector2(0, 0), 0.0001, "início")
	perto_v(T.ponto_em(p, 1.5), Vector2(1.5, 0), 0.0001, "meio do 1º")
	perto_v(T.ponto_em(p, 5.0), Vector2(3, 2), 0.0001, "meio do 2º")
	perto_v(T.ponto_em(p, 99.0), Vector2(3, 4), 0.0001, "além do fim = fim")
	perto_v(T.ponto_em(p, -1.0), Vector2(0, 0), 0.0001, "antes do início = início")


## v0.6: a rota é reduzida a POUCOS pontos de referência. Reta = duas pontas;
## canto e curva continuam com os pontos que fazem a forma.
func test_simplificar_reta_fica_com_as_pontas() -> void:
	var p := PackedVector2Array()
	for i in 20:
		p.append(Vector2(i * 10, 0))
	igual(T.simplificar(p, 10.0), PackedVector2Array([Vector2(0, 0), Vector2(190, 0)]), "reta")


func test_simplificar_preserva_o_canto() -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100)])
	var s := T.simplificar(p, 10.0)
	igual(s.size(), 3, "canto com três pontos")
	perto_v(s[1], Vector2(100, 0), 0.001, "canto fica")


## O DESCONTO INICIAL tira o pequeno vai-e-volta do começo do traço.
func test_desconto_inicial_tira_o_vai_e_volta() -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(-12, 0), Vector2(0, 0), Vector2(30, 0), Vector2(80, 0)])
	var d := T.descontar_inicio(p, 44.0, 140.0)
	checar(d.size() < p.size(), "cortou o começo")
	checar(d[0] == Vector2(0, 0), "mantém o início")
	perto_v(d[d.size() - 1], Vector2(80, 0), 0.001, "mantém o destino")
	checar(d.size() >= 2 and d[1].distance_to(Vector2.ZERO) > 44.0, "alinha fora do raio")


func test_desconto_inicial_nao_mexe_em_reta() -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(20, 0), Vector2(30, 0), Vector2(40, 0)])
	igual(T.descontar_inicio(p, 44.0, 140.0), p, "reta intacta")


func test_desconto_inicial_nao_corta_loop_que_termina_no_raio() -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(-20, 0), Vector2(0, 0)])
	igual(T.descontar_inicio(p, 44.0, 140.0), p, "sem destino fora do raio, não corta")


## v0.9: a PONTA de um bico passa da ponta do segmento; ela FICA na rota (senão
## a criatura nunca chegaria a fazer a ida e volta).
func test_simplificar_preserva_a_ponta_do_bico() -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(90, 0), Vector2(30, 0)])
	var s := T.simplificar(p, 10.0)
	igual(s.size(), 3, "a ponta do bico fica (%s)" % [s])
	if s.size() == 3:
		perto_v(s[1], Vector2(90, 0), 0.001, "ponta")


## v0.11.1: AMONTOADOS. Um laço minúsculo no meio da reta (aqui 20×22 px)
## some da rota: o traço liga a entrada do laço direto ao ponto de retorno.
func test_limpar_amontoados_corta_um_laco_minusculo() -> void:
	var p := PackedVector2Array([
		Vector2(0, 0), Vector2(60, 0), Vector2(80, 0), Vector2(80, 30),
		Vector2(60, 30), Vector2(60, 0), Vector2(120, 0)])
	var limpo := T.limpar_amontoados(p, 24.0, 100.0)
	igual(limpo, PackedVector2Array([Vector2(0, 0), Vector2(60, 0), Vector2(120, 0)]),
		"laço minúsculo cortado (%s)" % [limpo])


## Um BICO grande (volta a 60 px da base) NÃO é amontoado: o traço é andado.
func test_limpar_amontoados_preserva_bico_grande() -> void:
	var p := PackedVector2Array([
		Vector2(0, 0), Vector2(40, 0), Vector2(40, 60), Vector2(40, 0), Vector2(100, 0)])
	var limpo := T.limpar_amontoados(p, 24.0, 100.0)
	igual(limpo, p, "bico grande intacto (%s)" % [limpo])


## Reta e curva de verdade não são amontoado (o arco é ~igual à distância).
func test_limpar_amontoados_nao_mexe_em_curva() -> void:
	var p := PackedVector2Array()
	for i in 30:
		var a := PI * 0.5 * i / 29.0
		p.append(Vector2(cos(a), sin(a)) * 80.0)
	var limpo := T.limpar_amontoados(p, 24.0, 100.0)
	igual(limpo, p, "curva intacta")


## O atalho só é cortado se for ANDÁVEL: com o callback recusando, o amontoado
## fica (não se pula para o outro lado de uma parede).
func test_limpar_amontoados_respeita_o_caminho_livre() -> void:
	var p := PackedVector2Array([
		Vector2(0, 0), Vector2(60, 0), Vector2(80, 0), Vector2(80, 30),
		Vector2(60, 30), Vector2(60, 0), Vector2(120, 0)])
	var recusa := func(_a: Vector2, _b: Vector2) -> bool: return false
	igual(T.limpar_amontoados(p, 24.0, 100.0, recusa), p, "atalho bloqueado mantém o traço")
