class_name PlayerMovePacket
extends C2SPacket

var player_id: int
var direction: Vector2

func _init(data: Dictionary = {}):
	super._init("PlayerMove")
	if not data.is_empty():
		player_id = data.player_id
		direction = data.direction

func to_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"direction": direction
	}

func process(world: Node) -> void:
	var player_input = world.get_node("Players/" + str(player_id) + "/MultiplayerInput")
	if player_input:
		player_input.handle_player_move_packet(self)
