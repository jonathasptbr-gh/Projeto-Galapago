extends SubViewport
## O MAPA DO CHÃO (S5b): um SubViewport 2D transparente que cobre a ilha inteira
## vista de cima. As marcas de chão (trilha, mira, áreas de perigo, onda) são
## filhas de `raiz` e desenham em px de MUNDO da sim, como sempre; o
## `toon.gdshader` do TERRENO lê esta textura pelo XZ do mundo e pinta o topo
## das células com ela ANTES da luz — árvores, pedras, paredes e atores ficam
## por cima, e a sombra do sol cai sobre o caminho, em qualquer yaw e altura.
##
## Contrato:
## - `configurar(largura, altura)` (em células): tamanho da textura e a afim
##   fixa de `raiz`. Mapeamento: texel = (q − `origem_px`) × `escala`, com
##   `origem_px` = −`MARGEM_CELULAS` células (q = px de mundo da sim).
## - `escala`: texels por px da sim = min(`ESCALA_MAX`, `LADO_MAX` / maior
##   lado em px da sim), arredondada para baixo a um número INTEIRO de texels
##   por célula (fundacao.json, 64×24 + margem: 31/32 → 2046×806 texels).
## - `transform_chao() -> Transform2D`: a afim px da sim → texel (= `raiz`).
## - `ret_shader() -> Vector4`: o `chao_ret` do toon: (origem X, origem Z em
##   unidades 3D, texels por unidade / tamanho), uv = (xz − ret.xy) × ret.zw.
## - `uv_de_3d(p)`: a mesma conta do shader, em GDScript (testes).
## Textura: RGBA8 PREMULTIPLICADA (o mix do canvas sobre fundo transparente
## deixa rgb·a; medido no Compatibility, 2026-11-25); o shader divide por alfa.

const Cam := preload("res://sim/camera3d.gd")

## lado máximo da textura (px); acima disso a escala cai
const LADO_MAX := 2048
## texels por px da sim, no máximo
const ESCALA_MAX := 2.0
## margem em volta do mapa (células), para o caminho que sai da borda
const MARGEM_CELULAS := 1

var raiz: Node2D
var escala := 1.0
var origem_px := Vector2.ZERO


func _init() -> void:
	name = "MapaDoChao"
	transparent_bg = true
	disable_3d = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# o filtro da amostragem é do shader (linear, sem mipmap); aqui só o
	# desenho 2D dentro da textura
	canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	raiz = Node2D.new()
	raiz.name = "Raiz"
	add_child(raiz)


func configurar(largura_celulas: int, altura_celulas: int) -> void:
	var celulas := Vector2i(largura_celulas, altura_celulas) + Vector2i.ONE * (2 * MARGEM_CELULAS)
	var lado_px := float(maxi(celulas.x, celulas.y)) * Cam.PX_POR_UNIDADE
	var por_celula := floorf(minf(ESCALA_MAX, float(LADO_MAX) / lado_px) * Cam.PX_POR_UNIDADE)
	por_celula = maxf(por_celula, 1.0)
	escala = por_celula / Cam.PX_POR_UNIDADE
	origem_px = -Vector2.ONE * (MARGEM_CELULAS * Cam.PX_POR_UNIDADE)
	size = Vector2i(celulas.x * int(por_celula), celulas.y * int(por_celula))
	raiz.transform = transform_chao()


func transform_chao() -> Transform2D:
	return Transform2D(0.0, Vector2(escala, escala), 0.0, -origem_px * escala)


func ret_shader() -> Vector4:
	var por_unidade := escala * Cam.PX_POR_UNIDADE
	var o := origem_px / Cam.PX_POR_UNIDADE
	return Vector4(o.x, o.y, por_unidade / float(size.x), por_unidade / float(size.y))


func uv_de_3d(p: Vector3) -> Vector2:
	var r := ret_shader()
	return Vector2((p.x - r.x) * r.z, (p.z - r.y) * r.w)
