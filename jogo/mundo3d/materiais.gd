extends RefCounted
## Fábrica dos materiais do mundo 3D (sem estado além de um cache por cor).
## Contrato:
## - `contorno_tela() -> bool`: o contorno é o pós de TELA pela profundidade
##   (contorno_tela.gdshader, quad da vista.gd) — então a casca NÃO existe
##   (nem next_pass, nem casca/aba do terreno). Lê `modo_contorno`.
## - `modo_contorno`: MODO_TELA (padrão: Mobile e Compatibility leem a
##   profundidade nesse uso — medido no oráculo) ou MODO_CASCA (a casca
##   invertida antiga, reserva). Decida ANTES de construir os atores: os
##   materiais e as malhas de casca saem conforme o modo da hora.
## - `toon(cor, contorno := 0.0, forma := FORMA_NORMAL) -> ShaderMaterial`:
##   toon.gdshader na cor; com `contorno > 0` e modo casca ganha a casca como
##   `next_pass` (espessura em unidades 3D, `forma` como em casca.gdshader);
##   no modo tela `contorno` é ignorado.
## - `casca(espessura, forma) -> ShaderMaterial`: só o contorno (a casca do
##   terreno usa `FORMA_TERRENO`: paredes já infladas na malha, `espessura` =
##   largura da aba do topo).
## Materiais iguais saem do cache (mesma instância): NÃO altere parâmetros de
## um material devolvido — peça outro com os valores que quer.

const TOON := preload("res://jogo/mundo3d/toon.gdshader")
const CASCA := preload("res://jogo/mundo3d/casca.gdshader")

const FORMA_NORMAL := 0
const FORMA_CAIXA := 1
const FORMA_CILINDRO := 2
## casca do terreno (era da ilha da Fundação, removida em 2026-11-27): malha pronta + aba do topo
const FORMA_TERRENO := 3
## espessura padrão do contorno dos objetos (unidades; ~1,3 px interno na vista alta)
const CONTORNO := 0.05

const MODO_TELA := 0
const MODO_CASCA := 1

static var modo_contorno := MODO_TELA
static var _cache := {}


static func contorno_tela() -> bool:
	return modo_contorno == MODO_TELA


static func toon(cor: Color, contorno := 0.0, forma := FORMA_NORMAL) -> ShaderMaterial:
	if contorno_tela():
		contorno = 0.0
	var chave := "t|%s|%.4f|%d" % [cor.to_html(), contorno, forma]
	if _cache.has(chave):
		return _cache[chave]
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("cor", cor)
	if contorno > 0.0:
		m.next_pass = casca(contorno, forma)
	_cache[chave] = m
	return m


static func casca(espessura: float, forma := FORMA_NORMAL) -> ShaderMaterial:
	var chave := "c|%.4f|%d" % [espessura, forma]
	if _cache.has(chave):
		return _cache[chave]
	var m := ShaderMaterial.new()
	m.shader = CASCA
	m.set_shader_parameter("espessura", espessura)
	m.set_shader_parameter("forma", forma)
	_cache[chave] = m
	return m
