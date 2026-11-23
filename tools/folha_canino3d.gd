extends SceneTree
## Oráculo auxiliar da Fase A: 8 direções × 7 clipes × 3 fases no esqueleto 3D
## projetado. Uso:
##   LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=softpipe xvfb-run -a \
##     godot --path . --rendering-driver opengl3 --resolution 1600x800 \
##     -s res://tools/folha_canino3d.gd -- /root/tmp/canino-folha3d.png
## Variante de comparação (2D ao lado do 3D, fase 0,50):
##   ... -- /root/tmp/canino-folha3d-comparacao.png --comparar
## Giro contínuo (24 yaws × 3 fases de walk; grava a folha e uma tira de
## 24 quadros para compor o GIF):
##   ... --resolution 1760x360 -- /root/tmp/canino-folha3d-giro.png --giro

const Rigs := preload("res://jogo/rigs.gd")
const Rigs3D := preload("res://jogo/rigs3d.gd")
const YAWS_GIRO := 24
const PASSO_GIRO := 15.0
const CELULA := 68
const MARGEM_X := 80


class Quadro extends Node2D:
	const P2 := preload("res://jogo/pele_geometrica.gd")
	const P3 := preload("res://jogo/pele_geometrica3d.gd")
	const E2 := preload("res://sim/esqueleto.gd")
	const E3 := preload("res://sim/esqueleto3d.gd")

	var rig2: Dictionary = {}
	var rig3: Dictionary = {}
	var dirs := E3.DIRECOES
	var clips := ["walk", "run", "jump_start", "jump_air", "jump_land", "bite", "slam"]
	var fases := [0.17, 0.42, 0.73]
	var modo := "normal"
	var largura := 1560
	var altura := 760

	func _draw() -> void:
		draw_rect(Rect2(0, 0, largura, altura), Color("#17202b"))
		match modo:
			"comparar":
				_desenhar_comparacao()
			"giro":
				_desenhar_giro()
			"giro_frames":
				_desenhar_giro_frames()
			_:
				_desenhar_3d()

	func _desenhar_3d() -> void:
		for col in clips.size():
			var ms := roundi(float(rig3["clips"][clips[col]]["duracao_s"]) * 1000.0)
			draw_string(ThemeDB.fallback_font, Vector2(82 + col * 204, 20), "%s (%dms)" % [clips[col], ms],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
		for row in dirs.size():
			var dir: String = dirs[row]
			draw_string(ThemeDB.fallback_font, Vector2(4, 67 + row * 86), dir,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ffe4a0"))
			for col in clips.size():
				var clip: String = clips[col]
				for i in fases.size():
					var pose := E3.pose(rig3, dir, fases[i], clip)
					var chao := Vector2(83 + col * 204 + i * 68, 66 + row * 86)
					P3.desenhar(self, rig3, pose, chao, Color.WHITE, false, 1.0)

	func _desenhar_comparacao() -> void:
		for col in clips.size():
			draw_string(ThemeDB.fallback_font, Vector2(92 + col * 212, 20), clips[col],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
		for row in dirs.size():
			var dir: String = dirs[row]
			draw_string(ThemeDB.fallback_font, Vector2(4, 67 + row * 86), dir,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ffe4a0"))
			for col in clips.size():
				var clip: String = clips[col]
				var x0 := 88 + col * 212
				var y0 := 66 + row * 86
				var pose2 := E2.pose(rig2, dir, 0.5, clip)
				P2.desenhar(self, rig2, dir, 0.5, clip, Vector2(x0, y0), Color.WHITE, false, 1.0, pose2)
				draw_string(ThemeDB.fallback_font, Vector2(x0 - 14, y0 + 11), "2D",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#9fb4c9"))
				var pose3 := E3.pose(rig3, dir, 0.5, clip)
				P3.desenhar(self, rig3, pose3, Vector2(x0 + 84, y0), Color.WHITE, false, 1.0)
				draw_string(ThemeDB.fallback_font, Vector2(x0 + 70, y0 + 11), "3D",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#9fb4c9"))

	func _desenhar_giro() -> void:
		for col in YAWS_GIRO:
			draw_string(ThemeDB.fallback_font, Vector2(MARGEM_X + col * CELULA + 2, 18),
				str(int(col * PASSO_GIRO)), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#9fb4c9"))
		for row in fases.size():
			draw_string(ThemeDB.fallback_font, Vector2(4, 88 + row * 86),
				"walk %.2f" % float(fases[row]), HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
				Color("#ffe4a0"))
			for col in YAWS_GIRO:
				var yaw := float(col) * PASSO_GIRO
				var pose := E3.pose(rig3, "east", fases[row], "walk", false, yaw)
				var chao := Vector2(MARGEM_X + col * CELULA + 34, 100 + row * 86)
				P3.desenhar(self, rig3, pose, chao, Color.WHITE, false, 1.0)

	func _desenhar_giro_frames() -> void:
		for col in YAWS_GIRO:
			var yaw := float(col) * PASSO_GIRO
			var pose := E3.pose(rig3, "east", 0.42, "walk", false, yaw)
			var chao := Vector2(MARGEM_X + col * CELULA + 34, 90)
			P3.desenhar(self, rig3, pose, chao, Color.WHITE, false, 1.0)


var _quadro: Quadro


func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var args := OS.get_cmdline_user_args()
	var comparar := "--comparar" in args
	var giro := "--giro" in args
	_quadro = Quadro.new()
	_quadro.rig2 = Rigs.carregar("canino")
	_quadro.rig3 = Rigs3D.carregar("canino3d")
	if giro:
		_quadro.modo = "giro"
		_quadro.largura = MARGEM_X + YAWS_GIRO * CELULA
		_quadro.altura = 360
	elif comparar:
		_quadro.modo = "comparar"
		_quadro.largura = 1600
		_quadro.altura = 760
	else:
		_quadro.modo = "normal"
		_quadro.largura = 1560
		_quadro.altura = 760
	root.size = Vector2i(_quadro.largura, _quadro.altura)
	root.add_child.call_deferred(_quadro)
	_gravar.call_deferred()


func _gravar() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	var giro := "--giro" in args
	var comparar := "--comparar" in args
	var destino := "/root/tmp/canino-folha3d.png"
	if giro:
		destino = "/root/tmp/canino-folha3d-giro.png"
	elif comparar:
		destino = "/root/tmp/canino-folha3d-comparacao.png"
	for arg in args:
		if not String(arg).begins_with("--"):
			destino = arg
			break
	var erro := root.get_texture().get_image().save_png(destino)
	print("folha canino 3D: ", destino, " (erro=", erro, ")")
	if giro and erro == OK:
		# Tira de 24 quadros (fase 0,42) para o GIF 360°; cada célula fica em
		# (MARGEM_X + i*68, 40) com 68×68, pronta para fatiar.
		_quadro.modo = "giro_frames"
		_quadro.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var tira := destino.get_basename() + "-frames.png"
		var erro2 := root.get_texture().get_image().save_png(tira)
		print("tira 360 do canino 3D: ", tira, " (erro=", erro2, ")")
		quit(0 if erro2 == OK else 1)
		return
	quit(0 if erro == OK else 1)
