
class_name RequestChunkDataPacket
extends C2SPacket

var chunk_pos: Vector2

func _init(data: Dictionary = {}):
	super._init("RequestChunkGenerated")
	if not data.is_empty():
		chunk_pos = data.chunk_pos

func to_dict() -> Dictionary:
	return {
		"chunk_pos": chunk_pos
	}

func process(world: Node) -> void:
	if world.multiplayer.is_server():
		# Generate or retrieve the chunk data
		var chunk_data = world.get_chunk_data(chunk_pos)
		
		# Send the chunk data back to the requesting client
		var chunk_generated_packet = ChunkDataPacket.new({
			"chunk_pos": chunk_pos,
			"chunk_data": chunk_data
		})
		
		# Get the PacketHandler and send the response
		var packet_handler = world.get_node_or_null("PacketHandler")
		if packet_handler:
			packet_handler.send_packet(chunk_generated_packet)
