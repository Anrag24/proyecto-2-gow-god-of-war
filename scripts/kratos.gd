extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 6.0
const AIR_SPEED = 4.0
const ATTACK_SPEED = 1.6

# Distancia total que avanza el personaje en un heavy attack
const HEAVY_LUNGE_DISTANCE = 1.8
const LAUNCH_LUNGE_DISTANCE = 1.2

# Duracion aproximada del lunge (segundos); pasado este tiempo la velocidad llega a 0
const LUNGE_DURATION = 0.35

enum State {
	IDLE, MOVE, FALL, JUMP_LANDING, ATTACK, BLOCK, KNOCKBACK, GET_UP, DEATH, DANCE
}

const LOOPING_ANIMS: Array[String] = [
	"idle", "armed_walk", "falling_idle", "block_idle", "run"
]

var current_state: State = State.IDLE
var current_attack: String = ""
var buffered_input: String = ""

# Direccion fija capturada al inicio del heavy attack
var lunge_direction: Vector3 = Vector3.ZERO
# Velocidad inicial del lunge calculada a partir de distancia y duracion
var lunge_speed: float = 0.0
# Indica si hay un lunge activo
var lunge_active: bool = false

@onready var anim_player: AnimationPlayer = $kratos/AnimationPlayer
@onready var skeleton: Skeleton3D = $kratos/Armature/Skeleton3D

func _ready() -> void:
	anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	anim_player.animation_finished.connect(_on_animation_finished)
	_configure_animation_loops()

func _configure_animation_loops() -> void:
	for anim_name in anim_player.get_animation_list():
		var anim = anim_player.get_animation(anim_name)
		if anim:
			if anim_name in LOOPING_ANIMS:
				anim.loop_mode = Animation.LOOP_LINEAR
			else:
				anim.loop_mode = Animation.LOOP_NONE

func _physics_process(delta: float) -> void:
	if current_state == State.DEATH or current_state == State.DANCE:
		move_and_slide()
		return

	if Input.is_action_pressed("block") and current_state != State.GET_UP and current_state != State.KNOCKBACK:
		if current_state != State.BLOCK:
			change_state(State.BLOCK)
	elif current_state == State.BLOCK and not Input.is_action_pressed("block"):
		change_state(State.IDLE)

	if not is_on_floor():
		velocity += get_gravity() * delta
		if current_state in [State.IDLE, State.MOVE]:
			change_state(State.FALL)

	match current_state:
		State.IDLE, State.MOVE:
			handle_movement()
			handle_combat_inputs()
		State.FALL:
			handle_air_movement()
			if is_on_floor():
				change_state(State.JUMP_LANDING)
			else:
				handle_combat_inputs()
		State.JUMP_LANDING:
			apply_friction()
		State.ATTACK:
			_process_lunge(delta)
			if Input.is_action_just_pressed("attack_light"):
				buffered_input = "light"
			elif Input.is_action_just_pressed("attack_heavy"):
				buffered_input = "heavy"
		State.BLOCK:
			apply_friction()
		State.GET_UP:
			apply_friction()
		State.KNOCKBACK:
			apply_friction()

	move_and_slide()

# Aplica el lunge lineal cada frame y lo frena progresivamente
func _process_lunge(delta: float) -> void:
	if not lunge_active:
		apply_friction()
		return

	if lunge_speed > 0.0:
		# Velocidad solo en la direccion fija capturada al inicio
		velocity.x = lunge_direction.x * lunge_speed
		velocity.z = lunge_direction.z * lunge_speed

		# Desaceleracion lineal: reduce la velocidad hasta 0 en LUNGE_DURATION segundos
		var decel = (HEAVY_LUNGE_DISTANCE / LUNGE_DURATION) / LUNGE_DURATION
		lunge_speed = max(0.0, lunge_speed - decel * delta)

		if lunge_speed == 0.0:
			lunge_active = false
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		lunge_active = false
		velocity.x = 0.0
		velocity.z = 0.0

func _start_lunge(distance: float) -> void:
	# Captura la direccion forward una sola vez; no se vuelve a leer hasta el proximo ataque
	lunge_direction = global_transform.basis.z
	lunge_direction.y = 0.0
	lunge_direction = lunge_direction.normalized()

	# v0 para recorrer 'distance' en 'LUNGE_DURATION' con desaceleracion lineal hasta 0
	# Integrando: distance = v0 * t - 0.5 * decel * t^2, con v_final = 0 => v0 = 2*distance/t
	lunge_speed = (2.0 * distance) / LUNGE_DURATION
	lunge_active = true

func handle_movement() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		change_state(State.FALL)
		return

	var direction := get_camera_relative_input()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		rotation.y = atan2(direction.x, direction.z)
		if current_state != State.MOVE:
			change_state(State.MOVE)
	else:
		apply_friction()
		if current_state != State.IDLE:
			change_state(State.IDLE)

func handle_air_movement() -> void:
	var direction := get_camera_relative_input()
	if direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, direction.x * AIR_SPEED, 0.1)
		velocity.z = lerp(velocity.z, direction.z * AIR_SPEED, 0.1)
		rotation.y = atan2(direction.x, direction.z)

func apply_friction() -> void:
	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)

func get_camera_relative_input() -> Vector3:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var cam = get_viewport().get_camera_3d()
	if cam:
		var direction = cam.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)
		direction.y = 0
		return direction.normalized()
	return (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

func handle_combat_inputs() -> void:
	if Input.is_action_just_pressed("attack_light"):
		start_attack("light")
	elif Input.is_action_just_pressed("attack_heavy"):
		start_attack("heavy")

func start_attack(type: String) -> void:
	var next_anim = ""
	if not is_on_floor():
		if type == "light" and current_attack != "attack_air_light":
			next_anim = "attack_air_light"
		elif type == "heavy" and current_attack != "attack_air_heavy":
			next_anim = "attack_air_heavy"
	else:
		if type == "light":
			match current_attack:
				"": next_anim = "light_attackright_1"
				"light_attackright_1": next_anim = "light_attackleft_2"
				"light_attackleft_2": next_anim = "light_attack_finisher"
		elif type == "heavy":
			match current_attack:
				"": next_anim = "attack_heavy_1"
				"attack_heavy_1": next_anim = "attack_heavy_2"
				"attack_heavy_2": next_anim = "attack_heavy_3"
				"light_attackleft_2":
					next_anim = "attack_launch"
					velocity.y = JUMP_VELOCITY

	if next_anim != "" and anim_player.has_animation(next_anim):
		current_attack = next_anim
		buffered_input = ""
		current_state = State.ATTACK

		# Iniciar lunge lineal solo en heavy y launch
		if "heavy" in next_anim:
			_start_lunge(HEAVY_LUNGE_DISTANCE)
		elif "launch" in next_anim:
			_start_lunge(LAUNCH_LUNGE_DISTANCE)
		else:
			lunge_active = false

		anim_player.play(current_attack, -1, ATTACK_SPEED)
	else:
		current_attack = ""
		buffered_input = ""
		change_state(State.FALL if not is_on_floor() else State.IDLE)

func change_state(new_state: State) -> void:
	current_state = new_state
	lunge_active = false

	match current_state:
		State.IDLE:
			current_attack = ""
			buffered_input = ""
			play_anim("idle")
		State.MOVE:
			play_anim("armed_walk")
		State.FALL:
			play_anim("falling_idle")
		State.JUMP_LANDING:
			play_anim("jump_landing")
		State.BLOCK:
			current_attack = ""
			buffered_input = ""
			play_anim("block_idle")
		State.GET_UP:
			play_anim("get_up_knockback")
		State.DEATH:
			play_anim("death")
		State.DANCE:
			play_anim("dance_kratos")

func play_anim(anim_name: String, custom_speed: float = 1.0) -> void:
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name, -1, custom_speed)

func _on_animation_finished(anim_name: String) -> void:
	match current_state:
		State.ATTACK:
			if buffered_input != "":
				var input = buffered_input
				buffered_input = ""
				start_attack(input)
			else:
				current_attack = ""
				change_state(State.FALL if not is_on_floor() else State.IDLE)
		State.JUMP_LANDING:
			change_state(State.IDLE)
		State.GET_UP:
			change_state(State.IDLE)
		State.KNOCKBACK:
			change_state(State.GET_UP)

# -- API para sistemas externos --

func take_damage() -> void:
	if current_state == State.DEATH:
		return
	if current_state == State.BLOCK:
		play_anim("hit_animation_block")
	else:
		change_state(State.KNOCKBACK)

func die() -> void:
	change_state(State.DEATH)

func win() -> void:
	change_state(State.DANCE)
