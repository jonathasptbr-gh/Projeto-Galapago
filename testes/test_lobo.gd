extends "res://testes/caso.gd"
## Lobo importado: mantém o arquivo/paleta, lê estados reais da sim e não
## altera a cena nem a aparência dos adversários provisórios.

const Lobo := preload("res://jogo/mundo3d/lobo.gd")
const Ator := preload("res://jogo/mundo3d/ator.gd")
const Main := preload("res://jogo/main.gd")
const Espaco := preload("res://jogo/mundo3d/espaco.gd")


func test_importacao_preserva_quatro_materiais_e_encaixe() -> void:
	var lobo := Lobo.new()
	Engine.get_main_loop().root.add_child(lobo)
	var modelo: Node3D = lobo.get_node("Lobo")
	var malha: MeshInstance3D = modelo.get_node("RootNode/AnimalArmature/Skeleton3D/Wolf")
	igual(malha.mesh.get_surface_count(), 4, "quatro materiais originais")
	perto(modelo.scale.x, 0.25, 0.00001, "escala só na instância")
	for i in 4:
		var original := malha.mesh.surface_get_material(i) as StandardMaterial3D
		var aplicado := malha.get_surface_override_material(i) as ShaderMaterial
		checar(aplicado != null, "material estilizado da superfície %d" % i)
		if aplicado != null:
			var base: Color = aplicado.get_shader_parameter("cor")
			checar(base.is_equal_approx(original.albedo_color), "cor %d preservada" % i)
	lobo.atualizar(Vector2(64, 96), 1.0, Vector2.RIGHT, 0.3)
	perto(lobo.position.distance_to(Espaco.ponto(Vector2(64, 96), 1.0) + Vector3(0, 0.3, 0)), 0.0, 0.0001, "pés + salto")
	perto((lobo.basis * Vector3.FORWARD).distance_to(Vector3.RIGHT), 0.0, 0.0001, "frente local aponta à direita")
	lobo.free()


func test_clipes_exatos_sem_prefixo_e_sem_corrida_falsa() -> void:
	var lobo := Lobo.new()
	Engine.get_main_loop().root.add_child(lobo)
	var anim: AnimationPlayer = lobo.get_node("Lobo/AnimationPlayer")
	igual(anim.assigned_animation, "Idle", "parado desde o início")
	lobo.animar(0.0, 0.1, false, false, false)
	igual(anim.assigned_animation, "Idle", "olhar não induz movimento")
	lobo.animar(4.0, 0.1, false, false, true)
	igual(anim.assigned_animation, "Walk", "perto anda")
	lobo.animar(4.0, 0.1, false, false, false)
	igual(anim.assigned_animation, "Gallop", "longe usa galope, não Run")
	lobo.animar(4.0, 0.1, true, false, false)
	igual(anim.assigned_animation, "Gallop_Jump", "pulo real vence deslocamento")
	lobo.animar(0.0, 0.1, false, true, false)
	igual(anim.assigned_animation, "Attack", "ataque real vence inércia")
	lobo.animar(0.0, 0.1, false, false, false)
	igual(anim.assigned_animation, "Idle", "fim do ataque volta ao repouso")
	lobo.free()


func test_mesma_distancia_tem_mesma_fase_em_duas_velocidades() -> void:
	var fases: Array[float] = []
	for segundos in [0.5, 0.25]:
		var lobo := Lobo.new()
		Engine.get_main_loop().root.add_child(lobo)
		var anim: AnimationPlayer = lobo.get_node("Lobo/AnimationPlayer")
		# Meio metro em ambas: uma vez em 0,5 s, outra em 0,25 s.
		lobo.animar(16.0, segundos, false, false, true)
		anim.advance(segundos)
		fases.append(anim.current_animation_position / anim.get_animation("Walk").length)
		lobo.free()
	perto(fases[0], fases[1], 0.01, "fase depende da distância, não do FPS/tempo")
	perto(fases[0], 0.5 / Lobo.PASSADA_WALK, 0.01, "meio metro usa a passada calibrada")


func test_imobilidade_termina_passada_sem_patinar() -> void:
	var lobo := Lobo.new()
	Engine.get_main_loop().root.add_child(lobo)
	var anim: AnimationPlayer = lobo.get_node("Lobo/AnimationPlayer")
	lobo.animar(8.0, 0.1, false, false, false)
	checar(anim.speed_scale > 0.0, "galope acelera quando percorre chão")
	lobo.animar(0.0, 0.1, false, false, false)
	igual(anim.assigned_animation, "Idle", "imóvel não continua as passadas")
	perto(anim.speed_scale, 1.0, 0.00001, "idle respira na cadência original")
	lobo.animar(8.0, 0.1, true, false, false)
	igual(anim.assigned_animation, "Gallop_Jump", "pulo tem clipe independente")
	perto(anim.speed_scale, 1.0, 0.00001, "pulo não herda velocidade da passada")
	lobo.animar(8.0, 0.1, true, true, false)
	igual(anim.assigned_animation, "Attack", "ataque prevalece sobre pulo")
	perto(anim.speed_scale, 1.0, 0.00001, "ataque não herda velocidade da passada")
	lobo.free()


func test_so_criatura_recebe_lobo_no_jogo() -> void:
	var m := Main.new()
	Engine.get_main_loop().root.add_child(m)
	checar(m.ator_criatura is Lobo, "criatura-base substituída")
	for adv in m.atores_adv:
		checar(adv is Ator, "adversário conserva corpo e comportamento")
	m.free()
