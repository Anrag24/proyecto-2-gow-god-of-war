extends Node3D

@export var sensitividad_raton: float = 0.003
@export var objetivo_path: NodePath

@onready var spring_arm: SpringArm3D = $SpringArm3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * sensitividad_raton
		spring_arm.rotation.x -= event.relative.y * sensitividad_raton
		# Limitar la rotación vertical para que no dé la vuelta completa
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-80), deg_to_rad(30))
	
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(_delta: float) -> void:
	if not objetivo_path.is_empty():
		var objetivo = get_node_or_null(objetivo_path)
		if objetivo:
			# Seguir la posición del objetivo suavemente o directamente
			global_position = objetivo.global_position + Vector3(0, 1.5, 0) # Añadimos offset de altura
