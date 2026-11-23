extends SceneTree
## Oráculo auxiliar da Fase A: 8 direções × 7 clipes × 3 fases no esqueleto 3D
## projetado. Uso:
##   LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=softpipe xvfb-run -a \
##     godot --path . --rendering-driver opengl3 --resolution 1600x800 \
##     -s res://tools/folha_canino3d.gd -- /root/tmp/canino-folha3d.png
## Variante de comparação (2D ao lado do 3D, fase 0,50):
##   ... -- /root/tmp/canino-folha3d-comparacao.png --comparar

const Rigs := preload("res://jogo/rigs.gd")
const Rigs3D := preload("res://jogo/rigs3d.gd")

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
	var comparar := false
	var largura := 1560
	var altura := 760

	func _draw() -> void:
		draw_rect(Rect2(0, 0, largura, altura), Color("#17202b"))
		if comparar:
			_desenhar_comparacao()
		else:
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


func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var comparar := "--comparar" in OS.get_cmdline_user_args()
	var quadro := Quadro.new()
	quadro.rig2 = Rigs.carregar("canino")
	quadro.rig3 = Rigs3D.carregar("canino3d")
	quadro.comparar = comparar
	quadro.largura = 1600 if comparar else 1560
	quadro.altura = 760
	root.size = Vector2i(quadro.largura, quadro.altura)
	root.add_child.call_deferred(quadro)
	_gravar.call_deferred()


func _gravar() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var comparar := "--comparar" in OS.get_cmdline_user_args()
	var destino := "/root/tmp/canino-folha3d-comparacao.png" if comparar else "/root/tmp/canino-folha3d.png"
	for arg in OS.get_cmdline_user_args():
		if not String(arg).begins_with("--"):
			destino = arg
			break
	var erro := root.get_texture().get_image().save_png(destino)
	print("folha canino 3D: ", destino, " (erro=", erro, ")")
	quit(0 if erro == OK else 1)
