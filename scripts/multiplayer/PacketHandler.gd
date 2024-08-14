
extends Node

var c2s_packet_types = {}
var s2c_packet_types = {}
var world: Node  # Reference to the proc_gen_world node

func register_packet(packet_class: GDScript) -> void:
	var instance = packet_class.new()
	if instance is C2SPacket:
		c2s_packet_types[instance.packet_type] = packet_class
	elif instance is S2CPacket:
		s2c_packet_types[instance.packet_type] = packet_class
	else:
		push_error("Unknown packet type: %s" % instance.packet_type)

func create_packet(type: String, data: Dictionary) -> Packet:
	if type.begins_with("C2S_"):
		if type in c2s_packet_types:
			return c2s_packet_types[type].new(data)
	elif type.begins_with("S2C_"):
		if type in s2c_packet_types:
			return s2c_packet_types[type].new(data)
	push_error("Unknown packet type: %s" % type)
	return null

@rpc("any_peer", "call_remote", "reliable")
func receive_packet(type: String, data: Dictionary) -> void:
	var packet = create_packet(type, data)
	if packet and world:
		packet.process(world)
	else:
		push_error("Failed to process packet: %s" % type)

func send_packet(packet: Packet) -> void:
	if not world:
		#push_error("World reference not set in PacketHandler")
		print(packet.packet_type)		
		return	
	
	if packet is C2SPacket and not world.multiplayer.is_server():
		rpc_id(1, "receive_packet", packet.packet_type, packet.to_dict())
	elif packet is S2CPacket and world.multiplayer.is_server():
		rpc("receive_packet", packet.packet_type, packet.to_dict())
	else:
		push_error("Invalid packet direction: %s" % packet.packet_type)

func setup_packets() -> void:
	register_packet(RequestChunkDataPacket)
	register_packet(PlayerMovePacket)

	register_packet(UpdatePositionPacket)
	register_packet(SpawnObjectPacket)
	register_packet(ChunkDataPacket)

