extends MultiplayerSynchronizer

@onready var player = $"."
@onready var packet_handler = get_tree().current_scene.find_child("PacketHandler")

var input_direction: Vector2 = Vector2.ZERO
@export var transmit_interval: float = 0.1
var last_transmit_time: float = 0.0

func _ready():
	set_multiplayer_authority(player.get_multiplayer_authority())
	
	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)

func _physics_process(delta):
	var new_input_direction = Input.get_vector("left", "right", "up", "down").normalized()
	
	if new_input_direction != input_direction:
		input_direction = new_input_direction
		
		if is_multiplayer_authority() and Time.get_ticks_msec() - last_transmit_time > transmit_interval * 1000:
			transmit_input()
			last_transmit_time = Time.get_ticks_msec()

func transmit_input():
	var move_packet = PlayerMovePacket.new({
		"player_id": player.get_multiplayer_authority(),
		"direction": input_direction
	})
	packet_handler.send_packet(move_packet)

# This method will be called by the PacketHandler when a PlayerMovePacket is received
func handle_player_move_packet(packet: PlayerMovePacket):
	if multiplayer.is_server():
		# Update the player's input on the server
		input_direction = packet.direction
		# You might want to validate the input here
		
		# Broadcast the validated input to all clients (including the sender for reconciliation)
		packet_handler.send_packet(UpdatePositionPacket.new({
			"player_id": packet.player_id,
			"new_position": player.position + input_direction * 10  # Adjust speed as needed
		}))
	elif packet.player_id == player.get_multiplayer_authority():
		# Update local input for reconciliation
		input_direction = packet.direction

# This method will be called by the PacketHandler when an UpdatePositionPacket is received
func handle_update_position_packet(packet: UpdatePositionPacket):
	if packet.player_id == player.get_multiplayer_authority():
		player.position = packet.new_position
