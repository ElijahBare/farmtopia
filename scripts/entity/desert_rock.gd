extends Node2D

#todo make sure it doesnt border grass
# Called when the node enters the scene tree for the first time.
func _ready():
	scale.x = randf_range(0.3,0.7)
	scale.y = randf_range(0.5,0.7)
	add_to_group("saveable_entities", true)
