@tool
extends EditorScript

func _run():
	var root = CharacterBody3D.new()
	root.name = "Kratos"
	
	var collision = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape = CapsuleShape3D.new()
	shape.height = 2.0
	shape.radius = 0.5
	collision.shape = shape
	collision.position.y = 1.0 # Lift collision shape up
	root.add_child(collision)
	collision.owner = root
	
	var kratos_scene = load("res://modelos/kratos/Kratos.glb")
	if not kratos_scene:
		print("Error: No se pudo cargar Kratos.glb")
		return
	
	var kratos_instance = kratos_scene.instantiate()
	kratos_instance.name = "kratos"
	root.add_child(kratos_instance)
	kratos_instance.owner = root
	
	var skeleton = _find_skeleton(kratos_instance)
	if skeleton:
		var anclaje_izq = BoneAttachment3D.new()
		anclaje_izq.name = "AnclajeEspadaIZQ"
		if skeleton.find_bone("mixamorig:LeftHand") != -1:
			anclaje_izq.bone_name = "mixamorig:LeftHand"
		skeleton.add_child(anclaje_izq)
		anclaje_izq.owner = root
		
		var espada_scene = load("res://modelos/espadas_del_caos/blades_of_chaos.glb")
		if espada_scene:
			var espada_izq = espada_scene.instantiate()
			espada_izq.name = "espada_izq"
			anclaje_izq.add_child(espada_izq)
			espada_izq.owner = root
			
			var anclaje_der = BoneAttachment3D.new()
			anclaje_der.name = "AnclajeEspadaDER"
			if skeleton.find_bone("mixamorig:RightHand") != -1:
				anclaje_der.bone_name = "mixamorig:RightHand"
			skeleton.add_child(anclaje_der)
			anclaje_der.owner = root
			
			var espada_der = espada_scene.instantiate()
			espada_der.name = "espada_der"
			anclaje_der.add_child(espada_der)
			espada_der.owner = root
	else:
		print("Advertencia: No se encontró el Skeleton3D en el modelo Kratos.glb")
	
	var packed_scene = PackedScene.new()
	var err = packed_scene.pack(root)
	if err == OK:
		# Ensure directory exists
		var dir = DirAccess.open("res://")
		if not dir.dir_exists("res://escenas"):
			dir.make_dir("res://escenas")
		
		var save_err = ResourceSaver.save(packed_scene, "res://escenas/kratos.tscn")
		if save_err == OK:
			print("Éxito: Escena guardada en res://escenas/kratos.tscn")
		else:
			print("Error al guardar la escena: ", save_err)
	else:
		print("Error al empaquetar la escena: ", err)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var skel = _find_skeleton(child)
		if skel:
			return skel
	return null
