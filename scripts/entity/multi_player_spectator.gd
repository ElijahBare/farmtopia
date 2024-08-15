extends CharacterBody2D

@export var SPEED: float = 500.0
@export var water_layer: int = 0
@export var ground_1_layer: int = 1
@export var ground_2_layer: int = 2
@export var player_id: int = 1

var direction: Vector2 = Vector2.ZERO
var zoom_sensitivity: float = 0.1
var min_zoom: float = 0.5
var max_zoom: float = 2.0

@onready var camera = $Camera2D

func _ready():
	if is_multiplayer_authority():
		camera.make_current()
	Input.set_use_accumulated_input(false)  # Makes gesture detection more responsive

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _physics_process(delta):
	direction = Input.get_vector("left", "right", "up", "down").normalized()
	

	velocity = Vector2.ZERO
	
	move_and_slide()
	
	# Handle camera zoom with keyboard/mouse
	var scroll_vector = Input.get_axis("zoom_out", "zoom_in")
	
	if typeof(scroll_vector) == TYPE_FLOAT:
		zoom_camera(1 - scroll_vector * zoom_sensitivity)

func _input(event):
	if event is InputEventPanGesture:
		handle_pan_gesture(event)
	elif event is InputEventMagnifyGesture:
		handle_magnify_gesture(event)

func handle_pan_gesture(event: InputEventPanGesture):
	# Pan the camera
	camera.position += event.delta * 10  # Adjust the multiplier to control pan speed

func handle_magnify_gesture(event: InputEventMagnifyGesture):
	# Zoom the camera
	var zoom_factor = 1 + (event.factor - 1) * zoom_sensitivity
	zoom_camera(zoom_factor)

func zoom_camera(zoom_factor):
	var new_zoom = camera.zoom * zoom_factor
	new_zoom = new_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
	camera.zoom = new_zoom
