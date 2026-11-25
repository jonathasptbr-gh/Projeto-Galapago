extends RefCounted
## Câmera 3D ORTOGRÁFICA ORBITAL — só a matemática (sem nó, sem `Input`).
## Config: `dados/camera3d.json` (o `jogo/` lê o JSON e passa o Dictionary).
##
## Espaços:
## - sim: plano 2D em px de mundo (`Vector2 q`, 32 px por célula);
## - mundo 3D: 1 unidade = 1 célula, Y para cima:
##   `P3 = Vector3(q.x / 32, h, q.y / 32)` (`para_3d`/`para_plano`);
## - tela: px, origem no canto superior esquerdo, x direita, y BAIXO.
##
## Câmera: ortográfica `keep_height` (Camera3D.size = `altura_mundo`, em
## unidades). `base() = Basis.from_euler(Vector3(pitch, yaw, 0))` (ordem YXZ
## padrão; pitch negativo olha para baixo). Posição = `foco + base().z *
## distancia`. Colunas da base: x = direita da tela, y = cima da tela,
## z = para trás (a câmera olha para -z).
##
## Giro (`girar_px`): arrastar para a DIREITA aumenta o yaw. Visto de cima
## (norte = -z para cima no mapa), a câmera orbita no sentido ANTI-HORÁRIO e o
## mundo, na tela, gira no sentido HORÁRIO — a parte de cima da cena (a do
## fundo, onde fica a barra) acompanha o dedo para a direita.

const PX_POR_UNIDADE := 32.0

var cfg: Dictionary = {}
## foco suave (o que a câmera olha), em unidades de mundo 3D
var foco := Vector3.ZERO
## radianos, giro livre, sempre normalizado em [-PI, PI)
var yaw := 0.0
var vista := "alta"
## valores ATUAIS (interpolados durante a transição de vista)
var pitch := 0.0
var altura_mundo := 25.0

var _de_pitch := 0.0
var _de_altura := 25.0
var _t_transicao := -1.0  # < 0 = sem transição em curso


func _init(config: Dictionary = {}) -> void:
	cfg = {
		"vistas": {
			"alta": {"pitch_graus": -60.0, "altura_mundo": 25.0},
			"intima": {"pitch_graus": -35.0, "altura_mundo": 12.0},
		},
		"vista_inicial": "alta",
		"distancia": 60.0,
		"suavizacao": 6.0,
		"giro": {"graus_por_px": 0.35},
		"transicao_vista_s": 0.35,
		"pixel_pass": {"altura_interna": 640},
	}
	_mesclar(cfg, config)
	var inicial := String(cfg["vista_inicial"])
	if not Dictionary(cfg["vistas"]).has(inicial):
		inicial = "alta"
	vista = inicial
	pitch = _pitch_alvo(vista)
	altura_mundo = _altura_alvo(vista)
	_de_pitch = pitch
	_de_altura = altura_mundo


static func _mesclar(destino: Dictionary, fonte: Dictionary) -> void:
	for k in fonte:
		if String(k).begins_with("_"):
			continue
		if destino.has(k) and destino[k] is Dictionary and fonte[k] is Dictionary:
			_mesclar(destino[k], fonte[k])
		else:
			destino[k] = fonte[k]


# --- espaços -----------------------------------------------------------------

## px de mundo da sim (+ altura do chão em unidades) → ponto 3D
static func para_3d(q: Vector2, h := 0.0) -> Vector3:
	return Vector3(q.x / PX_POR_UNIDADE, h, q.y / PX_POR_UNIDADE)


## ponto 3D → px de mundo da sim (descarta a altura)
static func para_plano(p: Vector3) -> Vector2:
	return Vector2(p.x * PX_POR_UNIDADE, p.z * PX_POR_UNIDADE)


# --- foco ----------------------------------------------------------------------

## Aproxima o foco do alvo: `foco = alvo + (foco - alvo) * exp(-suavizacao*dt)`.
## Exponencial exata ⇒ independe do fps (2 passos de dt/2 = 1 de dt).
func seguir(alvo: Vector3, dt: float) -> void:
	var k := exp(-float(cfg["suavizacao"]) * maxf(dt, 0.0))
	foco = alvo + (foco - alvo) * k


## Põe o foco no alvo sem suavizar (início, teleporte).
func posicionar(alvo: Vector3) -> void:
	foco = alvo


# --- giro ----------------------------------------------------------------------

## dx em px de tela da barra do topo; direita ⇒ yaw aumenta (ver cabeçalho).
func girar_px(dx: float) -> void:
	girar(deg_to_rad(dx * float(cfg["giro"]["graus_por_px"])))


## Gira em radianos (positivo = mesmo sentido de arrastar para a direita).
func girar(radianos: float) -> void:
	yaw = wrapf(yaw + radianos, -PI, PI)


# --- vistas --------------------------------------------------------------------

## Começa a transição (smoothstep em `transicao_vista_s`) para a vista `nome`.
## Nome desconhecido ⇒ false e nada muda. Pedir a vista atual não reinicia.
func definir_vista(nome: String) -> bool:
	if not Dictionary(cfg["vistas"]).has(nome):
		return false
	if nome == vista:
		return true
	vista = nome
	_de_pitch = pitch
	_de_altura = altura_mundo
	_t_transicao = 0.0
	if float(cfg["transicao_vista_s"]) <= 0.0:
		_concluir_transicao()
	return true


## alta ⇄ intima; devolve o nome da vista nova.
func alternar_vista() -> String:
	definir_vista("intima" if vista == "alta" else "alta")
	return vista


func em_transicao() -> bool:
	return _t_transicao >= 0.0


## Avança a transição de vista (chamar todo quadro).
func avancar(dt: float) -> void:
	if _t_transicao < 0.0:
		return
	var dur := float(cfg["transicao_vista_s"])
	_t_transicao += maxf(dt, 0.0)
	if dur <= 0.0 or _t_transicao >= dur:
		_concluir_transicao()
		return
	var k := smoothstep(0.0, 1.0, _t_transicao / dur)
	pitch = lerpf(_de_pitch, _pitch_alvo(vista), k)
	altura_mundo = lerpf(_de_altura, _altura_alvo(vista), k)


func _concluir_transicao() -> void:
	pitch = _pitch_alvo(vista)
	altura_mundo = _altura_alvo(vista)
	_t_transicao = -1.0


func _pitch_alvo(nome: String) -> float:
	return deg_to_rad(float(cfg["vistas"][nome]["pitch_graus"]))


func _altura_alvo(nome: String) -> float:
	return float(cfg["vistas"][nome]["altura_mundo"])


# --- câmera --------------------------------------------------------------------

func base() -> Basis:
	return Basis.from_euler(Vector3(pitch, yaw, 0.0))


func distancia() -> float:
	return float(cfg["distancia"])


## Transform da Camera3D com o foco SUAVE (sem snap).
func transform_camera() -> Transform3D:
	var b := base()
	return Transform3D(b, foco + b.z * distancia())


## Snap do Pixel Pass. texel = altura_mundo / altura_interna (unidades).
## O foco é arredondado no grid de texel do espaço da câmera (eixos
## direita = base.x e cima = base.y). Devolve:
## - `transform`: Transform3D da câmera com o foco arredondado (renderizar a
##   imagem interna com ele);
## - `resto_px`: Vector2 em px INTERNOS, sentido de tela (x direita, y baixo) =
##   quanto a câmera suave está deslocada da arredondada. Na imagem do snap,
##   todo ponto aparece `resto_px` À FRENTE de onde a câmera suave o poria;
##   portanto desenhe a imagem ampliada deslocada de `-resto_px * fator`
##   (fator = px de tela por px interno). |resto| ≤ 0,5 em cada eixo;
## - `celula_trama`: Vector2i = (rx, -ry), índices do foco arredondado em
##   texels (direita, BAIXO). O px interno `p` usa a trama Bayer
##   `p + celula_trama` (a menos de uma constante): ancorada no mundo enquanto
##   yaw e pitch não mudam;
## - `texel`: float, tamanho do texel em unidades.
func snap(altura_interna_px: int = -1) -> Dictionary:
	if altura_interna_px <= 0:
		altura_interna_px = int(cfg["pixel_pass"]["altura_interna"])
	var texel := altura_mundo / float(altura_interna_px)
	var b := base()
	var fx := foco.dot(b.x) / texel
	var fy := foco.dot(b.y) / texel
	var rx := roundf(fx)
	var ry := roundf(fy)
	var foco_snap := foco + b.x * ((rx - fx) * texel) + b.y * ((ry - fy) * texel)
	return {
		"transform": Transform3D(b, foco_snap + b.z * distancia()),
		"resto_px": Vector2(fx - rx, -(fy - ry)),
		"celula_trama": Vector2i(int(rx), -int(ry)),
		"texel": texel,
	}


# --- chão ⇄ tela -----------------------------------------------------------------

func px_por_unidade(tela: Vector2) -> float:
	return tela.y / altura_mundo


## Afim exata (ortográfica) que leva `q` (px de mundo da sim, no plano de altura
## `h` em unidades) a px de tela, para a câmera SUAVE. O foco cai no centro.
func chao_para_tela(tela: Vector2, h := 0.0) -> Transform2D:
	var b := base()
	var s := px_por_unidade(tela)
	var k := s / PX_POR_UNIDADE
	var c := foco - Vector3(0.0, h, 0.0)
	return Transform2D(
		Vector2(b.x.x, -b.y.x) * k,
		Vector2(b.x.z, -b.y.z) * k,
		tela * 0.5 + Vector2(-c.dot(b.x), c.dot(b.y)) * s)


## Inversa: px de tela → px de mundo da sim no plano de altura `h`.
func tela_para_chao(tela: Vector2, h := 0.0) -> Transform2D:
	return chao_para_tela(tela, h).affine_inverse()


## Projeção de um ponto 3D qualquer em px de tela (câmera suave).
func ponto_para_tela(p: Vector3, tela: Vector2) -> Vector2:
	var b := base()
	var d := p - foco
	return tela * 0.5 + Vector2(d.dot(b.x), -d.dot(b.y)) * px_por_unidade(tela)
