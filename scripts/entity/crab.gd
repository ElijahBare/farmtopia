extends CharacterBody2D

@onready var animation_tree = $AnimatedSprite2D
@onready var tilemap: TileMap = get_parent().find_child("TileMap")

@export var move_speed : float = 20.0
@export var move_interval : float = 2.0
@export var land_layer: int = 1 # Adjust this based on your TileMap layer for land

var direction : Vector2 = Vector2.ZERO
var move_timer : float = 0.0

func _ready():
	add_to_group("saveable_entities", true)

func _process(delta):
	move_timer -= delta
	
	if move_timer <= 0:
		move_timer = move_interval
		randomize_direction()
	
	move_character(delta)

func randomize_direction():
	# Randomize direction including up and down
	var random_value = randi() % 4
	match random_value:
		0:
			direction = Vector2.LEFT
			animation_tree.play("l	eft")
		1:
			direction = Vector2.RIGHT
			animation_tree.play("right")
		2:
			direction = Vector2.UP
			animation_tree.stop()  # No animation for up
		3:
			direction = Vector2.DOWN
			animation_tree.stop()  # No animation for down

func move_character(delta):
	var proposed_position = position + direction * move_speed * delta
	var tile_pos = tilemap.local_to_map(proposed_position)
	
	# Check if the tile at the proposed position is land
	if tilemap.get_cell_source_id(land_layer, tile_pos) != -1:
		velocity = direction * move_speed
		move_and_slide()
		
		# Check if the tile at the proposed position is land
	if tilemap.get_cell_source_id(2, tile_pos) != -1:
		velocity = direction * move_speed
		move_and_slide()
