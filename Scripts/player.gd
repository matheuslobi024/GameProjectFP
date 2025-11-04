extends CharacterBody3D

@export var speed := 7.5
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.005

var camera
var y_rotation := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera = $Node3D/Camera3D

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		y_rotation = clamp(y_rotation - event.relative.y * mouse_sensitivity, deg_to_rad(-90), deg_to_rad(90))
		camera.rotation.x = y_rotation

func _physics_process(delta):
	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_dir = input_dir.normalized()

	var direction := (transform.basis * input_dir).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if Input.is_action_just_pressed("run"):
		speed = 10.0;
	elif Input.is_action_just_released("run"):
		speed = 7.5;

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	move_and_slide()
