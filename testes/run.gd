extends SceneTree
## Executor mínimo: roda toda função `test_*` de res://testes/test_*.gd.
## Uso: tools/testes.sh  (ou godot --headless --path . -s res://testes/run.gd)
## Filtro (verificação seletiva): GALAPAGO_TESTES=test_gestos.gd,test_corpo.gd
## Sai com código 1 se algum teste falhar ou se um nome do filtro não existir.


func _initialize() -> void:
	call_deferred("_executar")


func _executar() -> void:
	var arquivos: Array[String] = []
	for f in DirAccess.get_files_at("res://testes"):
		if f.begins_with("test_") and f.ends_with(".gd"):
			arquivos.append(f)
	arquivos.sort()
	# Filtro opcional do tools/verificar.sh: nomes separados por vírgula.
	var filtro := OS.get_environment("GALAPAGO_TESTES").strip_edges()
	if filtro != "":
		var quer := PackedStringArray()
		for nome in filtro.split(","):
			nome = nome.strip_edges()
			if nome != "":
				if not nome.ends_with(".gd"):
					nome += ".gd"
				quer.append(nome)
		print("filtro: %d arquivo(s)" % quer.size())
		for nome in quer:
			if not FileAccess.file_exists("res://testes/" + nome):
				printerr("  FALHA  filtro: teste %s não existe" % nome)
				quit(1)
		var filtrados: Array[String] = []
		for nome in quer:
			filtrados.append(nome)
		arquivos = filtrados
	var total := 0
	var falhas := 0
	for f in arquivos:
		var script: GDScript = load("res://testes/" + f)
		var nomes: Array[String] = []
		for m in script.get_script_method_list():
			var nome: String = m["name"]
			if nome.begins_with("test_") and nome not in nomes:
				nomes.append(nome)
		for nome in nomes:
			var caso = script.new()
			total += 1
			caso.call(nome)
			if caso.falhas.is_empty():
				print("  ok     %s :: %s" % [f, nome])
			else:
				falhas += 1
				for msg in caso.falhas:
					printerr("  FALHA  %s :: %s — %s" % [f, nome, msg])
	print("%d testes, %d falhas" % [total, falhas])
	quit(1 if falhas > 0 or total == 0 else 0)
