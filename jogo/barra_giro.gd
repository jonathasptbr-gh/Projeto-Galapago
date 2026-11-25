extends Control
## BARRA DE GIRO (P24): a faixa tátil do topo da tela que gira a câmera 3D.
## Aqui só se DESENHA — quem lê o dedo é `jogo/main.gd` (`_toque_barra`, no
## `_input`): dedo que DESCE dentro da faixa gira a câmera e não vira gesto,
## pinça nem caminho.
##
## Visual discreto: faixa translúcida, uma régua de bússola com marca a cada
## 15° (maior a cada 45°) e as letras N/L/S/O nos cardeais. A régua anda COM o
## dedo: a escala é a mesma do giro (`graus_por_px` de `dados/camera3d.json`),
## então a marca sob o dedo fica sob o dedo. A seta fixa no meio aponta o rumo
## que está no ALTO da tela (N no meio = norte para cima, yaw 0).
##
## `yaw_graus`, `graus_por_px` e `ativa` (dedo na barra: realça) vêm do main.

const PASSO_GRAUS := 15.0
const COR_FAIXA := Color(0.04, 0.09, 0.12, 0.26)
const COR_FAIXA_ATIVA := Color(0.04, 0.09, 0.12, 0.42)
const COR_MARCA := Color(1.0, 1.0, 1.0, 0.55)
const COR_NORTE := Color(1.0, 0.45, 0.35, 0.95)
## rumo (graus de yaw que o põem no meio) → letra
const CARDEAIS := {0: "N", 90: "O", 180: "S", 270: "L"}

var yaw_graus := 0.0
var graus_por_px := 0.35
var ativa := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func definir(yaw: float, dedo_na_barra: bool) -> void:
	if is_equal_approx(yaw, yaw_graus) and dedo_na_barra == ativa:
		return
	yaw_graus = yaw
	ativa = dedo_na_barra
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), COR_FAIXA_ATIVA if ativa else COR_FAIXA)
	draw_line(Vector2(0, h - 1.0), Vector2(w, h - 1.0), Color(1, 1, 1, 0.22), 2.0)
	var cx := w * 0.5
	var px_por_grau := 1.0 / maxf(graus_por_px, 0.001)
	var fonte := ThemeDB.fallback_font
	var n := int(360.0 / PASSO_GRAUS)
	for k in n:
		var rumo := float(k) * PASSO_GRAUS
		var x := cx + wrapf(yaw_graus - rumo, -180.0, 180.0) * px_por_grau
		if x < -20.0 or x > w + 20.0:
			continue
		var grande := k % 3 == 0
		var alto := h * (0.34 if grande else 0.18)
		draw_line(Vector2(x, h - 2.0), Vector2(x, h - 2.0 - alto), COR_MARCA, 2.0 if grande else 1.0, true)
		var chave := int(rumo)
		if CARDEAIS.has(chave):
			var cor := COR_NORTE if chave == 0 else Color(1, 1, 1, 0.8)
			draw_string_outline(fonte, Vector2(x - 20.0, h * 0.42), CARDEAIS[chave],
				HORIZONTAL_ALIGNMENT_CENTER, 40.0, 26, 6, Color(0, 0, 0, 0.6))
			draw_string(fonte, Vector2(x - 20.0, h * 0.42), CARDEAIS[chave],
				HORIZONTAL_ALIGNMENT_CENTER, 40.0, 26, cor)
	# a seta fixa no meio: o rumo que está no alto da tela
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 9.0, h - 2.0), Vector2(cx + 9.0, h - 2.0), Vector2(cx, h - 16.0),
	]), Color(1.0, 0.85, 0.3, 0.9))
	# setas laterais: "deslize"
	for lado in [-1.0, 1.0]:
		var bx: float = cx + lado * (w * 0.5 - 22.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(bx + lado * 8.0, h * 0.62), Vector2(bx - lado * 6.0, h * 0.62 - 9.0),
			Vector2(bx - lado * 6.0, h * 0.62 + 9.0),
		]), Color(1, 1, 1, 0.35))
