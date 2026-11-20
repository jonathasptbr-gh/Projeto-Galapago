extends Node2D
## Objeto de cenário (árvore, rocha, estação): sprite em pixel art com os PÉS
## na origem do nó (para o y-sort ordenar pela base) e uma sombra LISA,
## desenhada na resolução da tela. Sem textura, desenha um marcador provisório.

var textura: Texture2D
var raio_sombra := 14.0


func _ready() -> void:
	if textura:
		var s := Sprite2D.new()
		s.texture = textura
		s.offset = Vector2(0, -base_opaca(textura) + textura.get_height() / 2.0)
		add_child(s)


func _draw() -> void:
	if raio_sombra > 0.0:  # 0 = a arte já traz a própria sombra
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.38))
		draw_circle(Vector2.ZERO, raio_sombra, Color(0, 0, 0, 0.28), true, -1.0, true)
		draw_set_transform(Vector2.ZERO)
	if not textura:
		draw_rect(Rect2(-8, -22, 16, 22), Color(0.45, 0.42, 0.38))


## Linha (y) do pixel opaco mais baixo — onde o objeto toca o chão.
static func base_opaca(t: Texture2D) -> int:
	var img := t.get_image()
	if img == null:
		return t.get_height()
	if img.is_compressed():
		img.decompress()
	for y in range(img.get_height() - 1, -1, -1):
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				return y + 1
	return img.get_height()
