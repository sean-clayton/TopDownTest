extends Spatial

onready var body = $PlayerKinematicBody
onready var player_bottom = $PlayerKinematicBody/PlayerBottom
onready var camera_rig = $CameraRig
onready var camera = $CameraRig/PlayerCamera
onready var cursor = $PlayerKinematicBody/Cursor
onready var mouse_position_label = get_node("/root/Main/UI/LabelList/MousePosition/Value")
onready var mouse_moving_label = get_node("/root/Main/UI/LabelList/MouseMoving/Value")

export var gravity = 100
export var speed = 170
export var friction = 0.8

var move_direction = Vector3()
var velocity = Vector3()

var mouse_moving = false

var locked_position = Vector2.ZERO


func _ready() -> void:
	var viewport = get_viewport()
	locked_position = viewport.size / 2
	locked_position.y -= 64.0

	get_viewport().warp_mouse(locked_position)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(_delta: float) -> void:
	move_camera_with_body()


func _physics_process(delta: float) -> void:
	move(delta)
	look_at_cursor()

	if mouse_moving:
		mouse_moving_label.text = "Yes"
		mouse_moving = false
	else:
		mouse_moving_label.text = "No"


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_moving = true

	if Input.is_action_just_released("ui_cancel"):
		get_tree().quit()


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

	velocity += move_direction * speed * delta
	velocity *= friction

	if body.is_on_floor():
		velocity.y = 0
	else:
		velocity.y -= gravity * delta

	velocity = body.move_and_slide_with_snap(
		velocity, -body.get_floor_normal(), Vector3.UP, true, 1
	)


func look_at_cursor() -> void:
	var drop_plane = Plane(Vector3.UP, player_bottom.global_transform.origin.y)

	var ray_length = 1000
	var mouse_position = locked_position
	var from = camera.project_ray_origin(mouse_position)
	var to = from + camera.project_ray_normal(mouse_position) * ray_length

	var distance = Vector3.ZERO
	distance.y = player_bottom.transform.origin.distance_to(body.transform.origin)

	var intersects_at = drop_plane.intersects_ray(from, to)
	var cursor_pos = Vector3()
	if intersects_at:
		cursor_pos = intersects_at

	cursor.global_transform.origin = cursor_pos

	if mouse_moving:
		body.look_at(cursor_pos, Vector3.UP)
		body.rotation = body.rotation * Vector3.UP

	mouse_position_label.text = String(mouse_position)
