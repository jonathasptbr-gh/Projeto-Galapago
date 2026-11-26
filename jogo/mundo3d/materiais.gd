extends RefCounted
## Fábrica dos materiais do mundo 3D (sem estado além de um cache por cor).
## Contrato:
## - `toon(cor, contorno := 0.0, forma := FORMA_NORMAL) -> ShaderMaterial`:
##   toon.gdshader na cor; com `contorno > 0` ganha a casca como `next_pass`
##   (espessura em unidades 3D, `forma` como em casca.gdshader).
## - `casca(espessura, forma) -> ShaderMaterial`: só o contorno (a casca do
##   terreno usa `FORMA_TERRENO`: paredes já infladas na malha, `espessura` =
##   largura da aba do topo).
## - `terreno(cor) -> ShaderMaterial`: toon do TERRENO, instância NOVA (fora
##   do cache) para receber o mapa do chão (`usar_chao`, `chao`, `chao_ret`;
##   ver `jogo/mundo3d/chao.gd`); quem liga é `ilha.ligar_chao`.
## Materiais iguais saem do cache (mesma instância): NÃO altere parâmetros de
## um material devolvido — peça outro com os valores que quer.

const TOON := preload("res://jogo/mundo3d/toon.gdshader")
const CASCA := preload("res://jogo/mundo3d/casca.gdshader")

const FORMA_NORMAL := 0
const FORMA_CAIXA := 1
const FORMA_CILINDRO := 2
## casca do terreno (ilha.gd): malha pronta + aba do topo empurrada no shader
const FORMA_TERRENO := 3
## espessura padrão do contorno dos objetos (unidades; ~1,3 px interno na vista alta)
const CONTORNO := 0.05

static var _cache := {}


static func toon(cor: Color, contorno := 0.0, forma := FORMA_NORMAL) -> ShaderMaterial:
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


static func terreno(cor: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("cor", cor)
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
