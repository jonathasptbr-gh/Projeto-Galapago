extends RefCounted
## MOCKUPS e a escala visual do mundo — um lugar só para os números de tela.
##
## Enquanto não há arte, tudo é xadrez colorido (texturas geradas em código,
## filtro nearest → o pixel de arte aparece como bloco). Trocar pela arte é
## trocar as texturas daqui, não a lógica.

const CELULA := 32  # px de arte por célula
# DISTÂNCIA DA CÂMERA (v0.11.4, pedido do operador: "ver mais do mapa e do campo
# total"). Era 2,0 (escala C, zoom inteiro). Em 1,6 a tela mostra 450×800 px de
# arte — os 24 andares do mapa inteiros na vertical (1280/1,6 = 800 < 832 dos
# limites, então não aparece chão fora do mapa) e ~35% da largura. Custo: o
# pixel de arte deixa de ser múltiplo inteiro de tela (1–2 px), o que só vai
# importar quando a arte real entrar (P6). Ajustar aqui muda câmera e demo.
const ZOOM := 1.6
const SPRITE := 64  # canvas de criatura, em px de arte
const ALTURA_PX := 12.0  # quanto um nível de altura "sobe" na tela, em px de arte

static var _cache := {}


## Deslocamento vertical de desenho para uma altura de terreno (chão = 1 → 0).
static func desnivel(altura: float) -> float:
	return -maxf(altura - 1.0, 0.0) * ALTURA_PX


## Textura de xadrez lado×lado, casas de `casa` px, nas duas cores.
static func xadrez(lado: int, casa: int, a: Color, b: Color) -> ImageTexture:
	var chave := "%d/%d/%s/%s" % [lado, casa, a.to_html(), b.to_html()]
	if _cache.has(chave):
		return _cache[chave]
	var img := Image.create_empty(lado, lado, false, Image.FORMAT_RGBA8)
	for y in lado:
		for x in lado:
			img.set_pixel(x, y, a if ((x / casa) + (y / casa)) % 2 == 0 else b)
	var t := ImageTexture.create_from_image(img)
	_cache[chave] = t
	return t


## Sprite de criatura de mockup: xadrez 64×64 com borda, ocupando o canvas.
static func criatura(a: Color, b: Color, borda: Color) -> ImageTexture:
	var chave := "criatura/%s/%s/%s" % [a.to_html(), b.to_html(), borda.to_html()]
	if _cache.has(chave):
		return _cache[chave]
	var img := Image.create_empty(SPRITE, SPRITE, false, Image.FORMAT_RGBA8)
	var margem := 12  # corpo de 40×40 dentro do canvas de 64 (espaço para pose)
	for y in SPRITE:
		for x in SPRITE:
			var dentro := x >= margem and y >= margem and x < SPRITE - margem and y < SPRITE - margem
			if not dentro:
				continue
			var na_borda := x < margem + 2 or y < margem + 2 or x >= SPRITE - margem - 2 or y >= SPRITE - margem - 2
			img.set_pixel(x, y, borda if na_borda else (a if ((x / 8) + (y / 8)) % 2 == 0 else b))
	var t := ImageTexture.create_from_image(img)
	_cache[chave] = t
	return t


static func cor(html: String) -> Color:
	return Color(html)
