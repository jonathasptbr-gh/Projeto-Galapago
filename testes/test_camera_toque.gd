extends "res://testes/caso.gd"
const CameraToque := preload("res://sim/camera_toque.gd")

func test_pinca_bloqueia_ate_todos_sairem() -> void:
	var c := CameraToque.new()
	igual(c.descer(1, Vector2(0, 0)), "principal", "primeiro dedo")
	igual(c.descer(2, Vector2(100, 0)), "pinca", "segundo dedo")
	igual(c.mover(2, Vector2(200, 0)), "pinca", "pinça amplia")
	perto(c.zoom, 3.2, 0.001, "zoom limitado")
	igual(c.subir(2), "ignorar", "soltar não dispara")
	igual(c.mover(1, Vector2(30, 0)), "ignorar", "dedo restante não vira gesto")
	igual(c.descer(3, Vector2(50, 0)), "ignorar", "terceiro contato não recomeça")
	igual(c.subir(1), "ignorar", "sem disparo")
	igual(c.subir(3), "ignorar", "sem disparo")
	igual(c.descer(4, Vector2.ZERO), "principal", "novo ciclo")

func test_terceiro_dedo_nao_substitui_par_original() -> void:
	var c := CameraToque.new()
	c.descer(1, Vector2.ZERO)
	c.descer(2, Vector2(100, 0))
	c.descer(3, Vector2(900, 0))
	c.subir(2)
	var anterior: float = c.zoom
	igual(c.mover(3, Vector2(1000, 0)), "ignorar", "par interrompido não é substituído")
	perto(c.zoom, anterior, 0.001, "sem salto de zoom")


## v0.34 — o MODO do corpo segue a PINÇA: quem decide é a função pura
## `intima()`; aproximar liga o teto de 88 px/s e mantém a caminhada, afastar
## devolve os 110. Nada de Camera2D aqui (o modo entra por parâmetro).
func test_pinca_muda_o_modo_de_camera_do_corpo() -> void:
	var c := CameraToque.new()
	var Corpo := preload("res://sim/corpo.gd")
	var acoes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dados/acoes.json"))
	var corpo := Corpo.new(acoes)
	corpo.definir_camera_perto(c.intima())
	checar(not corpo.caminhada_existe(), "começa de longe")
	perto(corpo.velocidade_efetiva(), 110.0, 0.001, "110 de longe")
	c.descer(1, Vector2(0, 0))
	c.descer(2, Vector2(100, 0))
	c.mover(2, Vector2(150, 0))
	checar(c.intima(), "a pinça aproximou")
	corpo.definir_camera_perto(c.intima())
	checar(corpo.caminhada_existe(), "o modo perto chegou ao corpo")
	perto(corpo.velocidade_efetiva(), 88.0, 0.001, "teto de 88 de perto")
	c.mover(2, Vector2(50, 0))
	checar(not c.intima(), "a pinça afastou")
	corpo.definir_camera_perto(c.intima())
	checar(not corpo.caminhada_existe(), "voltou a longe")
	perto(corpo.velocidade_efetiva(), 110.0, 0.001, "volta aos 110")


func test_retorno_superior_por_pinca() -> void:
	var c := CameraToque.new()
	c.descer(1, Vector2.ZERO)
	c.descer(2, Vector2(100, 0))
	c.mover(2, Vector2(150, 0))
	checar(c.intima(), "aproximou")
	perto(c.inclinacao(), 0.80, 0.001, "ângulo intermediário")
	c.mover(2, Vector2(200, 0))
	perto(c.inclinacao(), 0.60, 0.001, "ângulo íntimo máximo")
	c.mover(2, Vector2(50, 0))
	checar(not c.intima(), "voltou ao superior")
	perto(c.inclinacao(), 1.0, 0.001, "projeção original")
