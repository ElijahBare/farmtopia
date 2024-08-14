# res://scripts/multiplayer/packets/s2c/SpawnObjectPacket.gd
class_name SpawnObjectPacket
extends S2CPacket

var scene_path: String
var pos: Vector2

func _init(data: Dictionary = {}):
	super._init("SpawnObject")
	if not data.is_empty():
		scene_path = data.scene_path
		pos = data.pos

func to_dict() -> Dictionary:
	return {
		"scene_path": scene_path,
		"pos": pos
	}

func process(world: Node) -> void:
	world.spawn_object(scene_path, pos)
