extends CharacterBody2D

@export var SPEED : float = 180.0
@onready var animation_tree = $AnimationTree
@onready var coords_display = $Camera2D/coord_hud/label

var direction : Vector2 = Vector2.ZERO

# Assuming water tiles are on a specific tile layer, e.g., layer 0
@export var water_layer: int = 0
@export var ground_1_layer: int = 1
@export var ground_2_layer: int = 2

@onready var camera = $Camera2D

@export var player_id:int = 1


func _ready():
	animation_tree.active = true
	
	if is_multiplayer_authority():
		camera.make_current()


 
func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _process(delta):
	update_animation_parameters()

func _physics_process(delta):
	direction = %MultiplayerSynchronizer.input_direction

	if direction:
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
	
	
	move_and_slide()


func update_animation_parameters():
	if velocity == Vector2.ZERO:
		animation_tree["parameters/conditions/is_idle"] = true
		animation_tree["parameters/conditions/is_moving"] = false
	else:
		animation_tree["parameters/conditions/is_idle"] = false
		animation_tree["parameters/conditions/is_moving"] = true
	
	if direction != Vector2.ZERO:
		animation_tree["parameters/idle/blend_position"] = direction
		animation_tree["parameters/walk/blend_position"] = direction
