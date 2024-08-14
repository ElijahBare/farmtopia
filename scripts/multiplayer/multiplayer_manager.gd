extends Node



var multiplayer_scene = preload("res://scenes/multi_player_player.tscn")

@onready var world_scene = get_tree().get_current_scene()

var _players_spawn_node
var host_mode_enabled = false
var multiplayer_mode_enabled = false
var respawn_point = Vector2(30, 20)

func become_host():
	print("Starting host!")
	
	_players_spawn_node = get_tree().get_current_scene().get_node("Players")
	
	multiplayer_mode_enabled = true
	host_mode_enabled = true
	
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(2007)
	server_peer.set_bind_ip("0.0.0.0")
	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)
	_remove_single_player()
	
	if not OS.has_feature("dedicated_server"):
		_add_player_to_game(multiplayer.get_unique_id())
	
func join_as_player_2():
	print("Player 2 joining")
	var SERVER_IP = get_tree().get_current_scene().get_node("MultiPlayerHud/TextEdit").text.split(":")[0]
	var SERVER_PORT = int(get_tree().get_current_scene().get_node("MultiPlayerHud/TextEdit").text.split(":")[1])

	
	multiplayer_mode_enabled = true
	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP, SERVER_PORT)
	
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
		var camera = player_to_add.get_node("Camera2D")
		camera.make_current()
		
func _del_player(id: int):
	print("Player %s left the game!" % id)
	if not _players_spawn_node.has_node(str(id)):
		return
	_players_spawn_node.get_node(str(id)).queue_free()
	
func _remove_single_player():
	print("Remove single player")

