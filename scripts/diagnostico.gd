@tool
extends EditorScript

# Ejecutar con Ctrl+Shift+X para diagnosticar el AnimationPlayer
func _run():
	var kratos_scene = load("res://modelos/kratos/Kratos.glb")
	if not kratos_scene:
		print("ERROR: No se pudo cargar Kratos.glb")
		return
	
	var instance = kratos_scene.instantiate()
	
	print("=== DIAGNOSTICO DEL MODELO KRATOS ===")
	print("")
	
	# Buscar AnimationPlayer
	var anim_player = _find_node_of_type(instance, "AnimationPlayer")
	if anim_player:
		print("AnimationPlayer encontrado en ruta: ", instance.get_path_to(anim_player))
		print("Modo de proceso: ", anim_player.callback_mode_process)
		print("")
		print("--- Lista de animaciones ---")
		for anim_name in anim_player.get_animation_list():
			var anim = anim_player.get_animation(anim_name)
			if anim:
				var loop_str = "LOOP_NONE"
				if anim.loop_mode == Animation.LOOP_LINEAR:
					loop_str = "LOOP_LINEAR"
				elif anim.loop_mode == Animation.LOOP_PINGPONG:
					loop_str = "LOOP_PINGPONG"
				print("  [%s] %s  (duracion: %.2fs)" % [loop_str, anim_name, anim.length])
			else:
				print("  [NULL] ", anim_name)
		print("--- Total: %d animaciones ---" % anim_player.get_animation_list().size())
	else:
		print("ERROR: No se encontro AnimationPlayer")
	
	print("")
	
	# Mostrar arbol completo de nodos
	print("--- Arbol de nodos del modelo ---")
	_print_tree(instance, 0)
	print("--- Fin ---")
	
	instance.queue_free()

func _find_node_of_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var found = _find_node_of_type(child, type_name)
		if found:
			return found
	return null

func _print_tree(node: Node, depth: int):
	var indent = ""
	for i in depth:
		indent += "  "
	print("%s%s [%s]" % [indent, node.name, node.get_class()])
	for child in node.get_children():
		_print_tree(child, depth + 1)
