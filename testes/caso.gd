extends RefCounted
## Base dos testes: cada `test_*` acumula falhas aqui; o executor (run.gd) as
## lê. Sem exceções em GDScript, um erro de script NÃO vira falha sozinho —
## quem pega isso é o tools/testes.sh, que reprova "SCRIPT ERROR" na saída.

var falhas: Array[String] = []


func checar(cond: bool, msg: String) -> void:
	if not cond:
		falhas.append(msg)


func igual(veio: Variant, esperado: Variant, msg := "") -> void:
	if veio != esperado:
		falhas.append("%s — esperado %s, veio %s" % [msg, esperado, veio])


func perto(veio: float, esperado: float, tol := 0.001, msg := "") -> void:
	if absf(veio - esperado) > tol:
		falhas.append("%s — esperado %s ± %s, veio %s" % [msg, esperado, tol, veio])


func perto_v(veio: Vector2, esperado: Vector2, tol := 0.001, msg := "") -> void:
	if veio.distance_to(esperado) > tol:
		falhas.append("%s — esperado %s ± %s, veio %s" % [msg, esperado, tol, veio])
