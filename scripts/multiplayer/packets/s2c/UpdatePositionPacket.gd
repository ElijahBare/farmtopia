class_name UpdatePositionPacket
extends S2CPacket

var player_id: int
var new_position: Vector2

func _init(data: Dictionary = {}):
	super._init("UpdatePosition")
	if not data.is_empty():
		player_id = data.player_id
		new_position = data.new_position

func to_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"new_position": new_position
	}

func process(world: Node) -> void:
	var player_input = world.get_node_or_null("Players/" + str(player_id) + "/MultiplayerInput")
	if player_input:
		player_input.handle_update_position_packet(self)
