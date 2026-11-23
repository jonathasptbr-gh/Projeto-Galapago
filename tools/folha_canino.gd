extends SceneTree
## Oráculo auxiliar: 8 direções × 7 clipes × 3 fases no desenho REAL da pele.
## Uso: LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=softpipe xvfb-run -a \
##   godot --path . --rendering-driver opengl3 --resolution 1470x720 \
##   -s res://tools/folha_canino.gd -- /root/tmp/canino-folha.png
## Variante do sprint (impulso de corrida): troque o destino por
##   `-- --sprint /root/tmp/canino-folha-sprint.png`.

const Rigs := preload("res://jogo/rigs.gd")

class Quadro extends Node2D:
	const P := preload("res://jogo/pele_geometrica.gd")
	const Esq := preload("res://sim/esqueleto.gd")
	var rig: Dictionary = {}
	var dirs := Esq.DIRECOES
	var clips := ["walk", "run", "jump_start", "jump_air", "jump_land", "bite", "slam"]
	var fases := [0.17, 0.42, 0.73]
	var sprint := false

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1470, 720), Color("#17202b"))
		for col in clips.size():
			var ms := roundi(float(rig["clips"][clips[col]]["duracao_s"]) * 1000.0)
			draw_string(ThemeDB.fallback_font, Vector2(80 + col * 204, 20), "%s (%dms)" % [clips[col], ms],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
		for row in dirs.size():
			var dir: String = dirs[row]
			draw_string(ThemeDB.fallback_font, Vector2(4, 67 + row * 86), dir,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ffe4a0"))
			for col in clips.size():
				var clip: String = clips[col]
				for i in fases.size():
					var pose := Esq.pose(rig, dir, fases[i], clip, sprint)
					var chao := Vector2(83 + col * 204 + i * 68, 66 + row * 86)
					P.desenhar(self, rig, dir, fases[i], clip, chao, Color.WHITE, false, 1.0, pose)


func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1470, 720)
	var quadro := Quadro.new()
	quadro.rig = Rigs.carregar("canino")
	quadro.sprint = "--sprint" in OS.get_cmdline_user_args()
	root.add_child.call_deferred(quadro)
	_gravar.call_deferred()


func _gravar() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	# O primeiro argumento que NÃO é opção é o destino; `--sprint` é só flag.
	var destino := "/root/tmp/canino-folha.png"
	for arg in OS.get_cmdline_user_args():
		if not String(arg).begins_with("--"):
			destino = arg
			break
	var erro := root.get_texture().get_image().save_png(destino)
	print("folha canino: ", destino, " (erro=", erro, ")")
	quit(0 if erro == OK else 1)
