extends CharacterBody2D

@onready var animation_tree = $AnimatedSprite2D
@onready var tilemap: TileMap = get_parent().find_child("TileMap")

@export var move_speed : float = 20.0
@export var move_interval : float = 2.0
@export var land_layer: int = 1 # Adjust this based on your TileMap layer for land

var direction : Vector2 = Vector2.ZERO
var move_timer : float = 0.0

func _ready():


	if is_multiplayer_authority():
		#rpc_config("update_client", MultiplayerAPI.RPC_MODE_ANY_PEER)
		# Defer initialization to ensure the node is ready
		call_deferred("_init_rpc")
	else:
		set_process(false)

func _init_rpc():
	if is_multiplayer_authority():
		# Ensure node is fully ready before starting movement logic
		set_process(true)


func _process(delta):
	if is_multiplayer_authority():
		move_timer -= delta
		
		if move_timer <= 0:
			move_timer = move_interval
			randomize_direction()
		
		move_character(delta)
#
		## Ensure the node is ready before sending RPCs
		#if is_inside_tree():
			#rpc("update_client", position, direction)


func randomize_direction():
	var random_value = randi() % 4
	match random_value:
		0:
			direction = Vector2.LEFT
			animation_tree.play("left")
		1:
			direction = Vector2.RIGHT
			animation_tree.play("right")
		2:
			direction = Vector2.UP
			animation_tree.stop()
		3:
			direction = Vector2.DOWN
			animation_tree.stop()

func move_character(delta):
	var proposed_position = position + direction * move_speed * delta
	var tile_pos = tilemap.local_to_map(proposed_position)
	
	if tilemap.get_cell_source_id(land_layer, tile_pos) != -1:
		velocity = direction * move_speed
		move_and_slide()
#
#@rpc("any_peer", "reliable")
#func update_client(new_position: Vector2, new_direction: Vector2):
	## Clients update the position based on the server's instructions
	#position = new_position
	#direction = new_direction
	#
	#if direction == Vector2.LEFT:
		#animation_tree.play("left")
	#elif direction == Vector2.RIGHT:
		#animation_tree.play("right")
	#elif direction == Vector2.UP or direction == Vector2.DOWN:
		#animation_tree.stop()
