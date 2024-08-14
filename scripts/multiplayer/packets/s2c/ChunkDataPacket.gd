
class_name ChunkDataPacket
extends S2CPacket

var chunk_pos: Vector2
var chunk_data: Dictionary

func _init(data: Dictionary = {}):
	super._init("ChunkGenerated")
	if not data.is_empty():
		chunk_pos = data.chunk_pos
		chunk_data = data.chunk_data

func to_dict() -> Dictionary:
	return {
		"chunk_pos": chunk_pos,
		"chunk_data": chunk_data
	}

func process(world) -> void:
	if not world.multiplayer.is_server():
		world.on_chunk_generated(chunk_pos, chunk_data)
