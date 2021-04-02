extends Spatial

onready var body = $PlayerKinematicBody
onready var player_bottom = $PlayerKinematicBody/PlayerBottom
onready var mesh = $PlayerKinematicBody/PlayerMesh
onready var camera_rig = $CameraRig
onready var camera = $CameraRig/PlayerCamera
onready var freefall_ray = $PlayerKinematicBody/FreefallRay

onready var mouse_position_label = get_node("/root/Main/UI/LabelList/MousePosition/Value")

export var gravity = 100
export var speed = 170
export var friction = 0.8

var move_direction = Vector3()
var velocity = Vector3()

const SNAP_DIRECTION = Vector3.DOWN
const SNAP_LENTH = 2
var snap_vector = SNAP_DIRECTION * SNAP_LENTH


func _ready() -> void:
	var viewport = get_viewport()
	var center_of_screen = Vector2.ZERO
	center_of_screen = viewport.size / 2

	get_viewport().warp_mouse(center_of_screen)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(_delta: float) -> void:
	move_camera_with_body()


func _physics_process(delta: float) -> void:
	move(delta)
	look_at_cursor()


func _input(_event: InputEvent) -> void:
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
	var mouse_position = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_position)
	var to = from + camera.project_ray_normal(mouse_position) * ray_length

	var distance = Vector3.ZERO
	distance.y = player_bottom.transform.origin.distance_to(body.transform.origin)

	var intersects_at = drop_plane.intersects_ray(from, to)
	var cursor_pos = Vector3()
	if intersects_at:
		cursor_pos = intersects_at + distance

	body.look_at(cursor_pos, Vector3.UP)
	body.rotation = body.rotation * Vector3.UP
	if mouse_position_label:
		mouse_position_label.text = String(mouse_position)
