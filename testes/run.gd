extends SceneTree
## Executor mínimo: roda toda função `test_*` de res://testes/test_*.gd.
## Uso: tools/testes.sh  (ou godot --headless --path . -s res://testes/run.gd)
## Sai com código 1 se algum teste falhar.


func _initialize() -> void:
	call_deferred("_executar")


func _executar() -> void:
	var arquivos: Array[String] = []
	for f in DirAccess.get_files_at("res://testes"):
		if f.begins_with("test_") and f.ends_with(".gd"):
			arquivos.append(f)
	arquivos.sort()
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
