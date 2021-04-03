extends Spatial

onready var body = $PlayerKinematicBody
onready var player_bottom = $PlayerKinematicBody/PlayerBottom
onready var camera_rig = $CameraRig
onready var camera = $CameraRig/PlayerCamera
onready var cursor = $PlayerKinematicBody/Cursor

export var speed = 160
export var walking_speed = 90
export var friction = 0.8

var current_speed = speed
var walking = false
var move_direction = Vector3()
var velocity = Vector3()


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	move_camera_with_body()


func _physics_process(delta: float) -> void:
	move(delta)
	look_at_cursor()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_released("ui_cancel"):
		get_tree().quit()
	if Input.is_action_just_released("player_secondary"):
		toggle_walk()


func toggle_walk() -> void:
	walking = ! walking
	if ! walking:
		current_speed = speed
	else:
		current_speed = walking_speed


func move_camera_with_body() -> void:
	camera_rig.global_transform.origin = body.global_transform.origin


func move(delta: float) -> void:
	move_direction = Vector3()
	var camera_basis = camera.global_transform.basis
	if Input.is_action_pressed("player_move_up"):
		move_direction -= camera_basis.z
	elif Input.is_action_pressed("player_move_down"):
		move_direction += camera_basis.z
	if Input.is_action_pressed("player_move_left"):
		move_direction -= camera_basis.x
	elif Input.is_action_pressed("player_move_right"):
		move_direction += camera_basis.x
	move_direction.y = 0
	move_direction = move_direction.normalized()

	velocity += move_direction * current_speed * delta
	velocity *= friction

	velocity = body.move_and_slide_with_snap(velocity, -body.get_floor_normal(), Vector3.UP, true)


func look_at_cursor() -> void:
	var drop_plane = Plane(Vector3.UP, player_bottom.global_transform.origin.y)
	var ray_length = 1000
	var mouse_position = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_position)
	var to = camera.project_ray_normal(mouse_position) * ray_length
	var cursor_pos = drop_plane.intersects_ray(from, to)

	body.look_at(cursor_pos, Vector3.UP)
	body.rotation = body.rotation * Vector3.UP
