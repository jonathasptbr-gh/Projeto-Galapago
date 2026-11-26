extends "res://testes/caso.gd"
## Construção headless: nenhuma imagem, janela ou GPU é necessária.
const Malhas := preload("res://jogo/mundo3d/natureza/malhas.gd")
const Mapa := preload("res://jogo/mundo3d/natureza/mapa.gd")
const Piloto := preload("res://jogo/mundo3d/natureza/piloto.gd")
const CENA := preload("res://jogo/mundo3d/natureza/piloto.tscn")


func _validar(m: ArrayMesh, nome: String) -> void:
	igual(m.get_surface_count(), 1, nome + ": uma superfície")
	var a := m.surface_get_arrays(0)
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var cs: PackedColorArray = a[Mesh.ARRAY_COLOR]
	checar(vs.size() > 0 and vs.size() % 3 == 0, nome + ": triângulos completos")
	igual(ns.size(), vs.size(), nome + ": normais completas")
	igual(cs.size(), vs.size(), nome + ": cores completas")
	var invalidos := 0
	var degenerados := 0
	var invertidos := 0
	for i in range(vs.size()):
		if not vs[i].is_finite() or not ns[i].is_finite() or absf(ns[i].length() - 1.0) > 0.001:
			invalidos += 1
		if not is_finite(cs[i].r) or not is_finite(cs[i].g) or not is_finite(cs[i].b):
			invalidos += 1
	for i in range(0, vs.size(), 3):
		var cruz := (vs[i + 1] - vs[i]).cross(vs[i + 2] - vs[i])
		if cruz.length_squared() < 1e-18:
			degenerados += 1
		if cruz.dot(ns[i] + ns[i + 1] + ns[i + 2]) >= 0.0:
			invertidos += 1
	igual(invalidos, 0, nome + ": valores finitos e normais unitárias")
	igual(degenerados, 0, nome + ": sem triângulos degenerados")
	igual(invertidos, 0, nome + ": winding horário coerente com normais")
	var indices: Variant = a[Mesh.ARRAY_INDEX]
	if indices != null:
		for indice in indices:
			checar(indice >= 0 and indice < vs.size(), nome + ": índice dentro da malha")
	var caixa := m.get_aabb()
	checar(caixa.size.x > 0.0 and caixa.size.y > 0.0 and caixa.size.z > 0.0, nome + ": AABB positivo")


func test_familias_geometria_valida_e_folhas_recortadas() -> void:
	for seed_local in [11, 112, 213, 314]:
		var arvore := Malhas.arvore(seed_local)
		_validar(arvore["madeira"], "ramos")
		_validar(arvore["folhas"], "folhas")
		_validar(Malhas.samambaia(seed_local), "samambaia")
		_validar(Malhas.sub_bosque(seed_local), "sub-bosque")
		_validar(Malhas.capim(seed_local), "capim")
		_validar(Malhas.rocha(seed_local), "rocha")
		_validar(Malhas.tronco(seed_local), "tronco caído")
		var madeira: ArrayMesh = arvore["madeira"]
		var folhas: ArrayMesh = arvore["folhas"]
		checar(madeira.get_aabb().size.y > 8.0, "árvore com proporção esguia real")
		checar(folhas.surface_get_array_len(0) > 3000, "folhas individuais, não esfera de copa")
	var mat := Malhas.material(true)
	igual(mat.transparency, BaseMaterial3D.TRANSPARENCY_DISABLED, "folhas opacas sem alpha overdraw")


func test_seed_geometria_reproduzivel_e_diversa() -> void:
	var a: ArrayMesh = Malhas.arvore(81)["folhas"]
	var b: ArrayMesh = Malhas.arvore(81)["folhas"]
	var c: ArrayMesh = Malhas.arvore(82)["folhas"]
	igual(a.surface_get_arrays(0), b.surface_get_arrays(0), "mesma seed = geometria e cores idênticas")
	checar(a.surface_get_arrays(0) != c.surface_get_arrays(0), "outra seed muda silhueta")


func test_mapa_denso_batching_orcamento_e_reconstrucao() -> void:
	var mapa := Mapa.new()
	mapa.construir(500)
	var stats: Dictionary = mapa.estatisticas.duplicate()
	var ts: PackedVector3Array = mapa.lotes[0].multimesh.transform_array
	var registros := {}
	checar(stats["arvores"] >= 65, "mata densa, não meia dúzia de copas")
	checar(stats["instancias"] > 1000, "estratos com muitas plantas")
	checar(stats["triangulos_instanciados"] < 650000, "limite de 650k triângulos instanciados")
	checar(stats["vertices_armazenados"] < 150000, "malhas reutilizadas, não duplicadas por planta")
	checar(mapa.get_child_count() < 35, "batching: menos de 35 nós no mapa")
	for lote in mapa.lotes:
		registros[lote.name] = [lote.multimesh.transform_array, lote.multimesh.color_array]
		_validar(lote.multimesh.mesh, str(lote.name))
		for i in range(lote.multimesh.instance_count):
			var t := lote.multimesh.get_instance_transform(i)
			checar(t.origin.is_finite() and t.basis.determinant() > 0.0, "transformação válida")
	for no in mapa.get_children():
		if no is MeshInstance3D:
			_validar(no.mesh, str(no.name))
			if no.name in [&"Riacho", &"Filetes_correnteza"]:
				var ns_agua: PackedVector3Array = no.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
				for normal_agua in ns_agua:
					checar(normal_agua.dot(Vector3.UP) > 0.999, "água e filetes com exterior físico para cima")
	mapa.construir(500)
	igual(mapa.estatisticas, stats, "reconstruir não acumula instâncias/triângulos")
	for lote in mapa.lotes:
		igual([lote.multimesh.transform_array, lote.multimesh.color_array], registros[lote.name],
			"mesma seed = distribuição e cores idênticas em TODOS os lotes")
	mapa.construir(501)
	checar(mapa.lotes[0].multimesh.transform_array != ts, "seed muda distribuição")
	print("  natureza medido (seed 500): ", JSON.stringify(stats))
	mapa.free()


func test_riacho_trilha_e_margens_coerentes() -> void:
	for z in range(-35, 20):
		var x := Mapa.rio_x(float(z))
		checar(Mapa.altura(x, z) < Mapa.AGUA_Y, "leito abaixo da água")
		checar(Mapa.altura(x + Mapa.largura_rio(z) + 1.0, z) > Mapa.AGUA_Y, "margem acima da água")
		checar(Mapa.altura(Mapa.trilha_x(z), z) > Mapa.AGUA_Y, "trilha seca")
	checar(absf(Mapa.rio_x(-12.0) - Mapa.rio_x(5.0)) > 1.0, "rio sinuoso")


func test_cena_isolada_camera_estatica_e_contorno_local() -> void:
	var cena := CENA.instantiate()
	# _ready monta apenas recursos 3D; headless não desenha nada.
	var raiz: Window = Engine.get_main_loop().root
	raiz.add_child(cena)
	igual(cena.vista.contorno.layers, 0, "contorno desativado só na instância piloto")
	cena.vista._reconfigurar()
	igual(cena.vista.contorno.layers, 0, "resize não reativa contorno")
	igual(cena.vista.camera.projection, Camera3D.PROJECTION_PERSPECTIVE, "perspectiva de proximidade padrão")
	var geral := Piloto.configuracao(PackedStringArray(["--vista-geral", "--demo"]))
	checar(geral["ortografica"], "vista geral ortográfica compatível com jogo")
	var detalhe := Piloto.configuracao(PackedStringArray(["--detalhe"]))
	checar(not detalhe["ortografica"], "detalhe próximo em perspectiva")
	checar(Piloto.configuracao(PackedStringArray(["--verso"]))["posicao"] != detalhe["posicao"], "outro ângulo real")
	checar(not cena.is_processing(), "demo não gira câmera automaticamente")
	cena.free()
