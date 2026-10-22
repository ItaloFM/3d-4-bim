
extends CharacterBody3D

@export var walk_speed: float = 4.0
@export var run_speed: float = 7.0
@export var jump_speed: float = 5.0

@export var animation_player: AnimationPlayer
@export var idle_clip: String = "general/Idle_A"
@export var walk_clip: String = "movement/Walking_A"
@export var run_clip: String = "movement/Running_A"

@onready var pivot: Node3D = $CameraPivot
@onready var visual: Node3D = $Visual

var hp: int = 100
var stamina: float = 100.0
var relics: int = 0
var won: bool = false

var gravity: float = 9.8
var attack_cd: float = 0.0
var hurt_cd: float = 0.0
var dodge_time: float = 0.0
var dodge_dir: Vector3 = Vector3.ZERO


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$CameraPivot/SpringArm3D.add_excluded_object(get_rid())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			pivot.rotation.y -= event.relative.x * 0.003
			pivot.rotation.x = clampf(
				pivot.rotation.x - event.relative.y * 0.003,
				deg_to_rad(-55),
				deg_to_rad(20)
			)


func _physics_process(delta: float) -> void:
	# Aplicar gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Pular
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_speed

	# Capturar movimento WASD
	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
        "move_back"
	)

	# Direcao relativa a camera
	var direction := (
		pivot.global_transform.basis
		* Vector3(input_dir.x, 0, input_dir.y)
	)

	direction.y = 0
	direction = direction.normalized()

	# Verificar corrida
	var running := Input.is_action_pressed("run")
	var speed := run_speed if running else walk_speed

	# Movimentar personagem
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		# Girar personagem na direcao do movimento
		visual.rotation.y = lerp_angle(
			visual.rotation.y,
			atan2(-direction.x, -direction.z)
				- global_rotation.y,
			delta * 10.0
		)

		if running:
			play_animation(run_clip)
		else:
			play_animation(walk_clip)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 8.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 8.0)

		play_animation(idle_clip)

	move_and_slide()


func play_animation(animation_name: String) -> void:
	if animation_player == null:
		return

	if not animation_player.has_animation(animation_name):
		return

	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name)
