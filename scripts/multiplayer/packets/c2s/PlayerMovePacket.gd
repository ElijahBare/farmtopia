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
	var players_node = world.get_node_or_null("Players")
	if not players_node:
		push_error("Players node not found")
		return
	
	var player_node = players_node.get_node_or_null(str(player_id))
	if not player_node:
		push_error("Player node not found for ID: " + str(player_id))
		return
	
	var player_input = player_node.get_node_or_null("MultiplayerInput")
	if player_input:
		player_input.handle_player_move_packet(self)
	
