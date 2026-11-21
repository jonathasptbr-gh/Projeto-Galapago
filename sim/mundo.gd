extends RefCounted
## O MUNDO LÓGICO em células — LÓGICA PURA (sem nó, sem desenho).
##
## Camadas lógicas:
## - SUPERFÍCIE: cada célula tem um terreno (dados/terrenos.json) com altura,
##   andável e escavável; objetos com tronco bloqueiam a célula deles.
## - SUBSOLO: grade própria de túneis ('='); células escavadas viram túnel.
## Regras (docs/gdd/mapa.md):
## - ANDAR vence diferença de altura de no máximo 0,5 (rampa = 1,5 liga 1 e 2);
## - PULAR pousa em célula andável até 1 nível ACIMA (descer, qualquer altura)
##   e passa por cima de água e obstáculos no caminho;
## - ESCAVAR em célula escavável desce ao subsolo; escavar no subsolo sob uma
##   célula escavável (ou já escavada) sobe.
## Posições em pixels de mundo; células em Vector2i.

const SUPERFICIE := "superficie"
const SUBSOLO := "subsolo"
const PASSO_AMOSTRA := 4.0  # px entre amostras ao conferir um trajeto

var celula_px := 32
var largura := 0
var altura_grade := 0
var legenda: Dictionary = {}
var celulas: PackedStringArray = []
var tuneis: PackedStringArray = []
var objetos: Array = []
var _bloqueadas := {}  # Vector2i -> true (troncos)
var escavadas := {}  # Vector2i -> true


## Monta a partir dos dicionários já lidos (mapa e legenda de terrenos).
static func criar(mapa: Dictionary, terrenos: Dictionary) -> RefCounted:
	var m = new()
	m.celula_px = int(mapa.get("celula_px", 32))
	m.legenda = terrenos
	m.celulas = PackedStringArray(mapa["celulas"])
	m.tuneis = PackedStringArray(mapa.get("subsolo", []))
	m.altura_grade = m.celulas.size()
	m.largura = m.celulas[0].length() if m.altura_grade > 0 else 0
	m.objetos = mapa.get("objetos", [])
	for o in m.objetos:
		if o.get("tipo", "") == "arvore" or o.get("bloqueia", false):
			m._bloqueadas[Vector2i(o["celula"][0], o["celula"][1])] = true
	return m


## Erros de desenho do mapa (vazio = válido).
func validar() -> PackedStringArray:
	var erros := PackedStringArray()
	for y in altura_grade:
		if celulas[y].length() != largura:
			erros.append("linha %d da superfície tem %d células; a primeira tem %d" % [y, celulas[y].length(), largura])
		for x in celulas[y].length():
			if not legenda.has(celulas[y][x]):
				erros.append("célula (%d,%d): terreno '%s' fora da legenda" % [x, y, celulas[y][x]])
	if not tuneis.is_empty() and tuneis.size() != altura_grade:
		erros.append("subsolo tem %d linhas; a superfície tem %d" % [tuneis.size(), altura_grade])
	return erros


func dentro(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < largura and c.y < altura_grade


func celula_de(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / celula_px), floori(pos.y / celula_px))


func centro(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * celula_px


## Propriedades do terreno da superfície; fora do mapa = água.
func terreno(c: Vector2i) -> Dictionary:
	if not dentro(c):
		return legenda.get("~", {"altura": 0, "andavel": false})
	return legenda.get(celulas[c.y][c.x], {})


func altura(c: Vector2i) -> float:
	return float(terreno(c).get("altura", 0))


func andavel(c: Vector2i, camada: String) -> bool:
	if not dentro(c):
		return false
	if camada == SUBSOLO:
		return escavadas.has(c) or (c.y < tuneis.size() and c.x < tuneis[c.y].length() and tuneis[c.y][c.x] == "=")
	return bool(terreno(c).get("andavel", false)) and not _bloqueadas.has(c)


## Andar de uma célula para a vizinha.
func pode_andar(a: Vector2i, b: Vector2i, camada: String) -> bool:
	if a == b:
		return true  # dentro da mesma célula sempre se move
	if not andavel(b, camada):
		return false
	return camada == SUBSOLO or absf(altura(a) - altura(b)) <= 0.5


## O que impede a célula: "objeto" (tronco — dá para desviar um pouco),
## "terreno" (água, rocha, fora do mapa) ou "" (livre). A diferença de ALTURA
## não aparece aqui: a célula é andável, mas `pode_andar` a recusa; o corpo
## trata isso como terreno (para e espera o pulo).
func bloqueio(c: Vector2i, camada: String) -> String:
	if not dentro(c):
		return "terreno"
	if camada == SUBSOLO:
		return "" if andavel(c, camada) else "terreno"
	if _bloqueadas.has(c):
		return "objeto"
	return "" if andavel(c, camada) else "terreno"


## O segmento a→b é andável de ponta a ponta? (usado para validar o corte do
## desconto inicial: a criatura não pode encurtar o caminho atravessando parede)
func caminho_livre(a: Vector2, b: Vector2, camada: String) -> bool:
	return limitar_segmento(a, b, camada).distance_to(b) < 0.5


## Corta um trajeto desenhado no primeiro passo impossível. Devolve o trecho
## andável (pelo menos o ponto de partida).
func limitar_caminho(pontos: PackedVector2Array, camada: String) -> PackedVector2Array:
	var saida := PackedVector2Array()
	if pontos.is_empty():
		return saida
	saida.append(pontos[0])
	var atual := pontos[0]
	for i in range(1, pontos.size()):
		var fim := limitar_segmento(atual, pontos[i], camada)
		if fim != atual:
			saida.append(fim)
		if fim.distance_to(pontos[i]) > 0.01:
			break
		atual = fim
	return saida


## Do ponto a em direção a b, até onde dá para ANDAR.
func limitar_segmento(a: Vector2, b: Vector2, camada: String) -> Vector2:
	var dist := a.distance_to(b)
	if dist < 0.001:
		return a
	var passos := ceili(dist / PASSO_AMOSTRA)
	var ultimo := a
	var c_ultimo := celula_de(a)
	for i in range(1, passos + 1):
		var p := a.lerp(b, float(i) / passos)
		var c := celula_de(p)
		if c != c_ultimo:
			if not pode_andar(c_ultimo, c, camada):
				return ultimo
			# diagonal: as duas vizinhas ortogonais também precisam deixar passar
			if c.x != c_ultimo.x and c.y != c_ultimo.y:
				var h := Vector2i(c.x, c_ultimo.y)
				var v := Vector2i(c_ultimo.x, c.y)
				if not (pode_andar(c_ultimo, h, camada) or pode_andar(c_ultimo, v, camada)):
					return ultimo
			c_ultimo = c
		ultimo = p
	return ultimo


## O pulo pode pousar ali? (passa por cima do que houver no caminho)
func pouso_valido(origem: Vector2, destino: Vector2, camada: String) -> bool:
	var c := celula_de(destino)
	if not andavel(c, camada):
		return false
	if camada == SUBSOLO:
		return true
	return altura(c) - altura(celula_de(origem)) <= 1.0


## Ponto de pouso: o mais longe possível em direção ao alvo (até `alcance`)
## onde o pouso é válido; se nenhum serve, pula no lugar.
func pouso(origem: Vector2, alvo: Vector2, alcance: float, camada: String) -> Vector2:
	var v := alvo - origem
	if v.length() > alcance:
		v = v.normalized() * alcance
	var passos := ceili(v.length() / PASSO_AMOSTRA)
	for i in range(passos, 0, -1):
		var p := origem + v * (float(i) / passos)
		if pouso_valido(origem, p, camada):
			return p
	return origem


## Dá para escavar aqui? Na superfície: célula escavável. No subsolo: subir só
## onde a superfície acima é escavável (ou já foi aberta).
func pode_escavar(c: Vector2i, camada: String) -> bool:
	if not dentro(c):
		return false
	var escavavel := bool(terreno(c).get("escavavel", false))
	if camada == SUPERFICIE:
		return escavavel and not _bloqueadas.has(c)
	return escavavel or escavadas.has(c)


## Abre o buraco (passa a ser túnel e entrada/saída). Devolve a outra camada.
func escavar(c: Vector2i, camada: String) -> String:
	escavadas[c] = true
	return SUBSOLO if camada == SUPERFICIE else SUPERFICIE
