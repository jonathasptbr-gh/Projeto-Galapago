extends Node2D
## Desenha o mapa: lê o design (dados/mapas/*.json), escolhe a peça de cada
## célula pela `sim/mapa.gd` e monta um TileMapLayer com os tilesets do
## PixelLab (arte/cenarios/tilesets/<nome>.png + <nome>.json, os metadados).
## Um tileset por par de terrenos vizinhos; a ordem em "tilesets" é a dos pares.

const M := preload("res://sim/mapa.gd")
const DIR_TILESETS := "res://arte/cenarios/tilesets/"

var celula_px := 32
var tamanho := Vector2i.ZERO  # em células
var dados: Dictionary = {}
var _camada: TileMapLayer


## Monta o mapa. Devolve os erros (vazio = tudo certo).
func carregar(caminho: String) -> PackedStringArray:
	dados = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	celula_px = int(dados["celula_px"])
	var g := M.niveis(PackedStringArray(dados["pontos"]))
	var erros := M.validar(g)
	if not erros.is_empty():
		return erros
	tamanho = Vector2i(g[0].size() - 1, g.size() - 1)

	var ts := TileSet.new()
	ts.tile_size = Vector2i(celula_px, celula_px)
	var atlas_por_par: Array = []
	for i in dados["tilesets"].size():
		var nome: String = dados["tilesets"][i]
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR_TILESETS + nome + ".json"))
		var fonte := TileSetAtlasSource.new()
		fonte.texture = load(DIR_TILESETS + nome + ".png")
		fonte.texture_region_size = Vector2i(celula_px, celula_px)
		var atlas := {}
		var idx := M.indice_cantos(meta["tileset_data"]["tiles"])
		for chave in idx:
			var coords: Vector2i = (idx[chave] as Rect2i).position / celula_px
			if not fonte.has_tile(coords):
				fonte.create_tile(coords)
			atlas[chave] = coords
		ts.add_source(fonte, i)
		atlas_por_par.append(atlas)

	_camada = TileMapLayer.new()
	_camada.tile_set = ts
	add_child(_camada)
	var faltando := 0
	for y in tamanho.y:
		for x in tamanho.x:
			var p := M.peca(g, x, y)
			var atlas: Dictionary = atlas_por_par[p["par"]]
			if atlas.has(p["chave"]):
				_camada.set_cell(Vector2i(x, y), p["par"], atlas[p["chave"]])
			else:
				faltando += 1
	if faltando > 0:
		erros.append("%d células sem peça correspondente no tileset" % faltando)
	return erros


## Ponto no chão no meio da célula (x, y), em pixels de mundo.
func centro_celula(c: Vector2) -> Vector2:
	return (c + Vector2(0.5, 0.5)) * celula_px


func limites() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(tamanho * celula_px))
