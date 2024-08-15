extends Node



var multiplayer_scene = preload("res://scenes/multi_player_player.tscn")
var multiplayer_spec_scene = preload("res://scenes/multi_player_spectator.tscn")

@onready var world_scene = get_tree().get_current_scene()

var _players_spawn_node
var host_mode_enabled = false
var multiplayer_mode_enabled = false
var respawn_point = Vector2(30, 20)

func become_host():

	print("Starting host!")
	
	_players_spawn_node = world_scene.get_node_or_null("Players")
	
	multiplayer_mode_enabled = true
	host_mode_enabled = true
	
	var server_peer = WebSocketMultiplayerPeer.new()
	server_peer.create_server(2007)

	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)
	_remove_single_player()
	

	_add_spectator_to_game(multiplayer.get_unique_id())
	
func join_as_player_2():
	print("Player 2 joining")
	var SERVER_IP = get_tree().get_current_scene().get_node_or_null("MultiPlayerHud/TextEdit")

	
	multiplayer_mode_enabled = true
	
	 
	var client_peer = WebSocketMultiplayerPeer.new()
	client_peer.encode_buffer_max_size = client_peer.encode_buffer_max_size*32
	client_peer.outbound_buffer_size = client_peer.outbound_buffer_size*32
	client_peer.inbound_buffer_size = client_peer.inbound_buffer_size* 32
	client_peer.max_queued_packets = client_peer.max_queued_packets * 4
	
	client_peer.create_client("ws://" + str(SERVER_IP.text))
	
	
	multiplayer.multiplayer_peer = client_peer
	
	
	_remove_single_player()

func _add_player_to_game(id: int):		
	print("Player %s joined the game!" % id)
	
	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	_players_spawn_node.add_child(player_to_add, true)
	
	# Set the network authority
	#player_to_add.set_network_master(id)
	world_scene._on_peer_connected(id)
	
	# If this is the local player, enable their camera
	if id == multiplayer.get_unique_id():
		var camera = player_to_add.get_node_or_null("Camera2D")
		camera.make_current()
		
	
		

func _add_spectator_to_game(id: int):
	
	var player_to_add = multiplayer_spec_scene.instantiate()
	
	_players_spawn_node.add_child(player_to_add, true)
	world_scene._on_peer_connected(id)
	#
	## If this is the local player, enable their camera
	if id == multiplayer.get_unique_id():
		var camera = player_to_add.get_node_or_null("Camera2D")
		camera.make_current()

		


func _del_player(id: int):
	print("Player %s left the game!" % id)
	if not _players_spawn_node.has_node(str(id)):
		return
	_players_spawn_node.get_node_or_null(str(id)).queue_free()
	
func _remove_single_player():
	print("Remove single player")

