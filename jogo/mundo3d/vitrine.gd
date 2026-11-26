extends Node2D
## Vitrine do mundo 3D para o oráculo (não é o jogo): a ilha de
## `dados/mapas/fundacao.json`, a vista e um ator andando em círculo; a câmera
## segue o ator e gira 180° de yaw em `DURACAO_GIRO` s, depois para de girar.
## Argumentos de usuário (depois de `--`): padrão 3D liso; `--pixel` liga o
## Pixel Pass (`--liso`, antigo, é aceito sem efeito); `--vista-intima`
## começa na vista íntima. `--demo` (do oráculo) é ignorado.
## `--sob-arvore`: vista íntima, câmera PARADA (yaw `YAW_SOB`, foco fixo) e o
## ator atravessando rente ao tronco da árvore (14,15), sob a copa, com a
## quina do planalto (14,9) em silhueta ao fundo: filma o contorno na base do
## tronco, na base do ator, na quina e a copa por cima do ator (S6). 20
## quadros a 10 fps = uma travessia.
## Filmar: `QUADROS_CENA=res://jogo/mundo3d/vitrine.tscn tools/quadros.sh N dir`
## (com `QUADROS_FPS=10`, 30 quadros = os 3 s do giro).

const Mundo := preload("res://sim/mundo.gd")
const Cam := preload("res://sim/camera3d.gd")
const Ilha := preload("res://jogo/mundo3d/ilha.gd")
const Vista := preload("res://jogo/mundo3d/vista.gd")
const Ator := preload("res://jogo/mundo3d/ator.gd")

const MAPA := "res://dados/mapas/fundacao.json"
## centro e raio do passeio (células) e uma volta a cada VOLTA_S segundos
const CENTRO_CEL := Vector2(9.5, 8.5)
const RAIO_CEL := 3.5
const VOLTA_S := 6.0
const DURACAO_GIRO := 3.0
## --sob-arvore: árvore e quina (células), yaw da câmera (rad: negativo põe a
## câmera a oeste e a parede leste do planalto de quina), meia travessia
## (unidades) e duração de uma travessia (s)
const ARVORE_SOB := Vector2(14.5, 15.5)
const QUINA_SOB := Vector2(14.0, 9.0)
const YAW_SOB := -0.35
const MEIA_TRAVESSIA := 1.8
const TRAVESSIA_S := 2.0

var mundo: RefCounted
var cam: RefCounted
var vista: CanvasLayer
var ilha: Node3D
var ator: Node3D
var _t := 0.0
var _h := 1.0  # altura do ator em níveis, suavizada (degraus viram rampa)
var _sob := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_sob = "--sob-arvore" in args
	mundo = Mundo.criar(_json(MAPA), _json("res://dados/terrenos.json"))
	for e in mundo.validar():
		push_error("mapa: " + e)
	var cfg := _json("res://dados/camera3d.json")
	if "--vista-intima" in args or _sob:
		cfg["vista_inicial"] = "intima"
	cam = Cam.new(cfg)
	if _sob:
		cam.girar(YAW_SOB)

	vista = Vista.new()
	vista.altura_interna = int(cam.cfg["pixel_pass"]["altura_interna"])
	vista.pixel_pass = "--pixel" in args
	add_child(vista)

	ilha = Ilha.new()
	ilha.name = "Ilha"
	vista.mundo_3d.add_child(ilha)
	ilha.construir(mundo)

	ator = Ator.new()
	ator.name = "Ator"
	vista.mundo_3d.add_child(ator)

	var p := _posicao(0.0)
	_h = mundo.altura(mundo.celula_de(p))
	_mover(0.0)
	if _sob:
		# foco fixo entre a árvore e a quina (no nível do chão, 1)
		cam.posicionar(Ilha.ponto((ARVORE_SOB * 0.6 + QUINA_SOB * 0.4) * Cam.PX_POR_UNIDADE, 1.0))
	else:
		cam.posicionar(Ilha.ponto(p, _h))
	vista.aplicar_camera(cam)


func _posicao(t: float) -> Vector2:
	if _sob:
		# rente ao tronco, do lado da câmera (a copa esconde a cabeça do ator),
		# na perpendicular ao olhar
		var de_cam := Vector2(sin(YAW_SOB), cos(YAW_SOB))  # chão: foco → câmera
		var direita := Vector2(cos(YAW_SOB), -sin(YAW_SOB))
		var s := -cos(PI * t / TRAVESSIA_S) * MEIA_TRAVESSIA
		return (ARVORE_SOB + de_cam * 0.45 + direita * s) * Cam.PX_POR_UNIDADE
	var a := TAU * t / VOLTA_S
	return (CENTRO_CEL + Vector2(cos(a), sin(a)) * RAIO_CEL) * Cam.PX_POR_UNIDADE


func _mover(dt: float) -> void:
	var p := _posicao(_t)
	var alvo: float = mundo.altura(mundo.celula_de(p))
	_h = alvo + (_h - alvo) * exp(-12.0 * dt)
	var dir := _posicao(_t + 0.05) - p
	ator.atualizar(p, _h, dir, absf(sin(_t * 9.0)) * 0.06)


func _process(dt: float) -> void:
	_t += dt
	_mover(dt)
	if _sob:
		cam.avancar(dt)
		vista.aplicar_camera(cam)
		return
	if _t <= DURACAO_GIRO:
		cam.girar(PI * dt / DURACAO_GIRO)
	cam.seguir(ator.position, dt)
	cam.avancar(dt)
	vista.aplicar_camera(cam)


func _json(caminho: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(caminho))
