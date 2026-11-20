extends RefCounted
## Mapa por terrenos em CANTOS (Wang) — LÓGICA PURA.
##
## O desenho é uma grade de PONTOS (vértices): cada caractere é o terreno
## naquele canto. A célula (x, y) tem os cantos (x,y) (x+1,y) (x,y+1) (x+1,y+1).
## Os terrenos são NÍVEIS em ordem (mar 0, areia 1, grama 2, planalto 3) e há
## um tileset por par vizinho (0↔1, 1↔2, 2↔3). Por isso os quatro cantos de
## uma célula só podem diferir em UM nível — `validar` reprova o resto.

const NIVEIS := {"~": 0, ".": 1, ",": 2, "^": 3}


## Converte as linhas do desenho em níveis. Caractere desconhecido → -1.
static func niveis(linhas: PackedStringArray) -> Array:
	var g: Array = []
	for l in linhas:
		var linha: Array[int] = []
		for c in l:
			linha.append(NIVEIS.get(c, -1))
		g.append(linha)
	return g


## Erros de desenho, um por problema. Vazio = desenho válido.
static func validar(g: Array) -> PackedStringArray:
	var erros := PackedStringArray()
	if g.size() < 2:
		erros.append("precisa de pelo menos 2 linhas de pontos")
		return erros
	var largura: int = g[0].size()
	for y in g.size():
		if g[y].size() != largura:
			erros.append("linha %d tem %d pontos; a primeira tem %d" % [y, g[y].size(), largura])
		for x in g[y].size():
			if g[y][x] < 0:
				erros.append("ponto (%d,%d): caractere desconhecido" % [x, y])
	if not erros.is_empty():
		return erros
	for y in g.size() - 1:
		for x in largura - 1:
			var c := cantos(g, x, y)
			if c.max() - c.min() > 1:
				erros.append("célula (%d,%d): cantos %s pulam mais de um nível" % [x, y, c])
	return erros


## Cantos da célula na ordem NW, NE, SW, SE.
static func cantos(g: Array, x: int, y: int) -> Array:
	return [g[y][x], g[y][x + 1], g[y + 1][x], g[y + 1][x + 1]]


## Para uma célula: qual par de terrenos (tileset) e a chave de cantos
## "NW,NE,SW,SE" com "upper"/"lower" — o formato dos metadados do PixelLab.
## Célula de um nível só: o nível 0 usa o par 0 todo "lower"; os outros usam
## o par abaixo deles todo "upper".
static func peca(g: Array, x: int, y: int) -> Dictionary:
	var c := cantos(g, x, y)
	var lo: int = c.min()
	var hi: int = c.max()
	var par: int
	var chave: PackedStringArray = []
	if lo == hi:
		par = 0 if lo == 0 else lo - 1
		var v := "lower" if lo == 0 else "upper"
		chave = [v, v, v, v]
	else:
		par = lo
		for n in c:
			chave.append("upper" if n == hi else "lower")
	return {"par": par, "chave": ",".join(chave)}


## Índice "NW,NE,SW,SE" → retângulo na folha, a partir de
## metadata.tileset_data.tiles do PixelLab.
static func indice_cantos(tiles: Array) -> Dictionary:
	var idx := {}
	for t in tiles:
		var k: Dictionary = t["corners"]
		var b: Dictionary = t["bounding_box"]
		idx["%s,%s,%s,%s" % [k["NW"], k["NE"], k["SW"], k["SE"]]] = Rect2i(
			int(b["x"]), int(b["y"]), int(b["width"]), int(b["height"]))
	return idx
