extends RefCounted
## CAMPO DE VENTO — LÓGICA PURA (sem nó, sem desenho, sem relógio real).
## Fonte única do vento da mata: brisa, rajadas que varrem o mapa, vento forte e
## turbulência. É também o campo que as habilidades elementares de ar (P27) vão
## empurrar e que a água vai ler; por isso não depende do desenho.
## Determinístico: o estado é (tempo, posição); nada de sorteio global.
##
## Espaço: o plano local do mapa (x, z), nas unidades 3D de sim/natureza.gd
## (1 unidade = 1 célula da sim). A direção é unitária e aponta para onde o
## vento SOPRA; a força é adimensional (0–2).
##
## O campo num ponto é a soma `dir_base(p) * força_base(p) + Σ frentes + Σ
## fontes`, com `força_base = brisa + vento_forte + turbulência` (nunca
## negativa). As FRENTES são bandas de rajada que viajam com o vento ambiente;
## as FONTES são empurrões de habilidade, com raio e tempo de vida.
##
## Todo número de design mora em dados/vento.json; o PADRAO abaixo é a reserva
## (os MESMOS valores) para quem não passa cfg, e `_init` aceita cfg PARCIAL
## (mescla seção a seção sobre o padrão). Nada de `_process`, `Time` nem
## `randf()` global: só `avancar(dt)` move o relógio.
##
## A apresentação (shader, fatia seguinte) lê `uniformizar()` para os campos de
## largo alcance e `vetor(p)`/`campo(p)` para o vento em cada ponto do mapa.

## Reserva do JSON (mesmos valores), usada com cfg ausente, parcial ou inválido.
const PADRAO := {
	"brisa": {"forca": 0.32, "direcao_rad": 0.6, "vaivem_rad": 0.55, "giro_s": 61.0},
	"rajada": {"forca": 0.62, "periodo_s": 6.4, "largura": 7.5, "velocidade": 4.2, "percurso": 90.0},
	"vento_forte": {"forca": 0.55, "periodo_s": 43.0, "duracao_s": 7.0},
	"turbulencia": {"forca": 0.18, "escala": 2.6, "velocidade": 1.9},
	"fonte": {"duracao_s": 1.6, "raio": 4.0, "teto": 8},
}

## Bandas de rajada vivas ao mesmo tempo; a mais antiga sai.
const MAX_FRENTES := 6
## Desvio local da direção da brisa (rad) e como ele se espalha pelo mapa.
const DESVIO_FORCA := 0.22
const DESVIO_ESCALA := Vector2(0.17, 0.11)
## Segunda frequência da turbulência (a primeira é cfg.turbulencia.velocidade).
const TURBULENCIA_FREQ_2 := 3.1
## Pisos de segurança: cfg absurdo (0, negativo, NaN) não vira divisão por zero.
const LARGURA_MIN := 0.001
const PERIODO_MIN := 0.05
const RAIO_MIN := 0.001
## Vetor abaixo disto é "sem vento": a direção cai na brisa.
const MIN_VETOR := 0.0001
## Teto de nascimentos de rajada num único `avancar` (dt absurdo não trava).
const NASCIMENTOS_MAX := 64

## Relógio da simulação (s); começa em 0.0 e só `avancar` o move.
var tempo := 0.0

var _cfg: Dictionary = {}
var _frentes: Array = []
var _fontes: Array = []
var _frente_n: int = 0
var _prox_frente_s: float = 0.0
var _prox_id: int = 0


func _init(cfg := {}) -> void:
	_cfg = _mesclar(PADRAO, cfg)
	# A primeira rajada nasce em tempo == 0, no meio do percurso.
	_criar_frente_auto()
	_prox_frente_s = maxf(PERIODO_MIN, _num(_secao("rajada"), "periodo_s", 6.4))


## Avança o relógio e o estado (frentes andam, fontes envelhecem). dt <= 0 é
## ignorado — chamada repetida com 0 s não muda nada.
func avancar(dt: float) -> void:
	if dt <= 0.0:
		return
	tempo += dt
	_mover_frentes(dt)
	var periodo := maxf(PERIODO_MIN, _num(_secao("rajada"), "periodo_s", 6.4))
	_prox_frente_s -= dt
	var nascimentos := 0
	while _prox_frente_s <= 0.0 and nascimentos < NASCIMENTOS_MAX:
		_criar_frente_auto()
		_prox_frente_s += periodo
		nascimentos += 1
	if _prox_frente_s <= 0.0:
		_prox_frente_s = periodo
	_avancar_fontes(dt)


## Direção unitária do vento em `p` (o vetor total, ou a brisa se não há vento).
func direcao(p: Vector2) -> Vector2:
	return _unitario(vetor(p), p)


## Força do vento em `p` (>= 0).
func forca(p: Vector2) -> float:
	return vetor(p).length()


## Vetor do vento em `p`: direção × força.
func vetor(p: Vector2) -> Vector2:
	return _base_vetor(p) + _frentes_vetor(p) + _fontes_vetor(p)


## O campo num ponto, para quem desenha: direção, força, vetor e o quanto de
## rajada há ali (0..1).
func campo(p: Vector2) -> Dictionary:
	var v := vetor(p)
	return {
		"direcao": _unitario(v, p),
		"forca": v.length(),
		"vetor": v,
		"rajada": rajada(p),
	}


## Soma das bandas de rajada em `p` (0..1) — adimensional, sem a brisa.
func rajada(p: Vector2) -> float:
	var s := 0.0
	for item in _frentes:
		var f: Dictionary = item
		s += float(f["forca"]) * _banda(f, p)
	return minf(1.0, s)


## Rajada manual (demo/habilidade): uma banda que nasce em `pos` e segue o
## vento ambiente.
func criar_frente(pos: Vector2, forca := 1.0) -> void:
	_nova_frente(pos, _direcao_ambiente(), _num_valor(forca, 1.0))


## Empurrão de habilidade (ar/P27): soma ao campo por `duracao_s` s, até um
## raio `raio` (0 = o padrão de dados/vento.json). Devolve um id crescente.
func adicionar_fonte(pos: Vector2, dir: Vector2, forca: float, raio: float, duracao_s: float) -> int:
	var sec := _secao("fonte")
	var r := _num_valor(raio, 0.0)
	if r <= 0.0:
		r = _num(sec, "raio", 4.0)
	var dur := _num_valor(duracao_s, 0.0)
	if dur <= 0.0:
		dur = _num(sec, "duracao_s", 1.6)
	_prox_id += 1
	_fontes.append({
		"id": _prox_id,
		"pos": pos,
		"dir": _unitario(dir, pos) if dir.length() > MIN_VETOR else Vector2.ZERO,
		"forca": maxf(0.0, _num_valor(forca, 0.0)),
		"raio": maxf(RAIO_MIN, r),
		"duracao_s": maxf(RAIO_MIN, dur),
		"idade": 0.0,
	})
	var teto := maxi(0, int(_num(sec, "teto", 8.0)))
	while _fontes.size() > teto and not _fontes.is_empty():
		_fontes.pop_front()
	return _prox_id


## Apaga todas as fontes (o campo volta ao de antes das habilidades).
func limpar_fontes() -> void:
	_fontes.clear()


## Quantas bandas de rajada estão vivas (observação: diagnóstico e testes).
func frentes_vivas() -> int:
	return _frentes.size()


## Campos de largo alcance (a fatia do shader usa estes nomes, exatamente).
## `frente`/`frente_forca` são da frente mais PERCEBIDA na origem do mapa — não
## a mais forte: o desenho mostra UMA banda, então ela tem de ser a que cruza a
## área visível. Sem frente, ZERO.
func uniformizar() -> Dictionary:
	var melhor: Dictionary = {}
	var melhor_peso := -1.0
	var largura := maxf(LARGURA_MIN, _num(_secao("rajada"), "largura", 7.5))
	for item in _frentes:
		var f: Dictionary = item
		var q: float = (f["pos"] as Vector2).length() / largura
		var peso := float(f["forca"]) * exp(-q * q)
		if peso > melhor_peso:
			melhor = f
			melhor_peso = peso
	var frente := Vector2.ZERO
	var frente_forca := 0.0
	if not melhor.is_empty():
		frente = melhor["pos"]
		frente_forca = float(melhor["forca"])
	return {
		"direcao": _direcao_base(Vector2.ZERO),
		"forca": maxf(0.0, _forca_larga()),
		"frente": frente,
		"frente_forca": frente_forca,
		"frente_largura": maxf(LARGURA_MIN, _num(_secao("rajada"), "largura", 7.5)),
		"turbulencia": _num(_secao("turbulencia"), "forca", 0.0),
		"tempo": tempo,
	}


# --- o campo, por partes ----------------------------------------------------

## Vetor da brisa/vento forte/turbulência em `p` (a base da soma).
func _base_vetor(p: Vector2) -> Vector2:
	var f := maxf(0.0, _forca_larga() + _turbulencia(p))
	return _direcao_base(p) * f


## Brisa + vento forte (as duas parcelas de largo alcance, sem rajada nem
## turbulência).
func _forca_larga() -> float:
	var b := _secao("brisa")
	var base := _num(b, "forca", 0.32) * (0.86 + 0.14 * sin(tempo * 0.37))
	var vf := _secao("vento_forte")
	var periodo := maxf(PERIODO_MIN, _num(vf, "periodo_s", 43.0))
	var dur := maxf(0.0, _num(vf, "duracao_s", 7.0))
	var t_local := fposmod(tempo, periodo)
	if dur > 0.0 and t_local < dur:
		base += _num(vf, "forca", 0.55) * sin(PI * t_local / dur)
	return base


## Turbulência (escalar somado à força base): duas ondas desencontradas no
## espaço e no tempo.
func _turbulencia(p: Vector2) -> float:
	var t := _secao("turbulencia")
	var vel := _num(t, "velocidade", 1.9)
	var esc := _num(t, "escala", 2.6)
	return _num(t, "forca", 0.18) * (
		0.6 * sin(tempo * vel + p.x * esc * 0.55)
		+ 0.4 * sin(tempo * TURBULENCIA_FREQ_2 - p.y * esc * 0.7)
	)


## Ângulo da brisa (rad), sem o desvio local: é o que as frentes seguem.
func _angulo_brisa() -> float:
	var b := _secao("brisa")
	var giro := maxf(PERIODO_MIN, _num(b, "giro_s", 61.0))
	return _num(b, "direcao_rad", 0.6) + _num(b, "vaivem_rad", 0.55) * sin(TAU * tempo / giro)


## Direção ambiente (unitária, sem desvio local): o rumo do vento "de largo".
func _direcao_ambiente() -> Vector2:
	var a := _angulo_brisa()
	return Vector2(cos(a), sin(a))


## Direção base num ponto: brisa + desvio local pequeno (a mata não é lisa).
func _direcao_base(p: Vector2) -> Vector2:
	var a := _angulo_brisa() + DESVIO_FORCA * sin(
		tempo * 0.9 + p.x * DESVIO_ESCALA.x + p.y * DESVIO_ESCALA.y
	)
	return Vector2(cos(a), sin(a))


## Soma das frentes vivas em `p` (bandas perpendiculares ao rumo do vento).
func _frentes_vetor(p: Vector2) -> Vector2:
	var v := Vector2.ZERO
	for item in _frentes:
		var f: Dictionary = item
		v += f["dir"] * (float(f["forca"]) * _banda(f, p))
	return v


## Peso da banda da frente `f` em `p`: 1 na linha central, cai com gaussiana.
func _banda(f: Dictionary, p: Vector2) -> float:
	var largura := maxf(LARGURA_MIN, _num(_secao("rajada"), "largura", 7.5))
	var d: float = (p - f["pos"]).dot(f["dir"])
	var q := d / largura
	return exp(-q * q)


## Soma das fontes vivas em `p`: caem com a idade e com a distância (smoothstep).
func _fontes_vetor(p: Vector2) -> Vector2:
	var v := Vector2.ZERO
	for item in _fontes:
		var f: Dictionary = item
		var peso := 1.0 - float(f["idade"]) / float(f["duracao_s"])
		if peso <= 0.0:
			continue
		var raio := float(f["raio"])
		var perto := 1.0 - smoothstep(0.0, raio, p.distance_to(f["pos"]))
		v += f["dir"] * (float(f["forca"]) * peso * perto)
	return v


## Normaliza `v`; se não há vento (vetor minúsculo), devolve a direção da brisa.
func _unitario(v: Vector2, p: Vector2) -> Vector2:
	if v.length() < MIN_VETOR:
		return _direcao_base(p)
	return v.normalized()


# --- frentes e fontes, estado -----------------------------------------------

## Nasce uma frente da série automática (k = 0, 1, 2...): no máximo 22
## unidades atrás do mapa (a banda já aparece na mata em ~1 s, não só depois de
## cruzar meio percurso), com a força do k.
func _criar_frente_auto() -> void:
	var r := _secao("rajada")
	var dir := _direcao_ambiente()
	var forca := _num(r, "forca", 0.62) * (0.7 + 0.3 * sin(float(_frente_n) * 2.39))
	var inicio := minf(_num(r, "percurso", 90.0) * 0.5, 22.0)
	_nova_frente(-dir * inicio, dir, forca)
	_frente_n += 1


func _nova_frente(pos: Vector2, dir: Vector2, forca: float) -> void:
	_frentes.append({
		"pos": pos,
		"dir": dir if dir.length() > MIN_VETOR else _direcao_ambiente(),
		"forca": maxf(0.0, forca),
		"percorrido": 0.0,
	})
	while _frentes.size() > MAX_FRENTES:
		_frentes.pop_front()


func _mover_frentes(dt: float) -> void:
	var r := _secao("rajada")
	var vel := maxf(0.0, _num(r, "velocidade", 4.2))
	var percurso := maxf(0.0, _num(r, "percurso", 90.0))
	for i in range(_frentes.size() - 1, -1, -1):
		var f: Dictionary = _frentes[i]
		f["pos"] = f["pos"] + f["dir"] * (vel * dt)
		f["percorrido"] = float(f["percorrido"]) + vel * dt
		if float(f["percorrido"]) >= percurso:
			_frentes.remove_at(i)


func _avancar_fontes(dt: float) -> void:
	for i in range(_fontes.size() - 1, -1, -1):
		var f: Dictionary = _fontes[i]
		f["idade"] = float(f["idade"]) + dt
		if float(f["idade"]) >= float(f["duracao_s"]):
			_fontes.remove_at(i)


# --- configuração -----------------------------------------------------------

## Mescla `sobre` no `base`, seção a seção (cfg parcial é aceito). Valor de
## tipo errado que não seja dicionário sobrescreve; `_secao` cai na reserva.
static func _mesclar(base: Dictionary, sobre) -> Dictionary:
	var out: Dictionary = base.duplicate(true)
	if typeof(sobre) != TYPE_DICTIONARY:
		return out
	for chave in sobre:
		var v = sobre[chave]
		if out.has(chave) and typeof(out[chave]) == TYPE_DICTIONARY and typeof(v) == TYPE_DICTIONARY:
			out[chave] = _mesclar(out[chave], v)
		else:
			out[chave] = v
	return out


## Seção da configuração (sempre completa: veio do PADRAO mesclado).
func _secao(nome: String) -> Dictionary:
	var s = _cfg.get(nome, null)
	if typeof(s) != TYPE_DICTIONARY:
		s = PADRAO.get(nome, {})
	return s


## Número da configuração com reserva: valor de tipo errado, NaN ou infinito
## não contamina o campo (cfg absurdo continua finito).
static func _num(d: Dictionary, chave: String, reserva: float) -> float:
	return _num_valor(d.get(chave, reserva), reserva)


## Número avulso (argumento de API) com a mesma reserva.
static func _num_valor(v, reserva: float) -> float:
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return reserva
	var f := float(v)
	if not is_finite(f):
		return reserva
	return f
