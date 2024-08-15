extends Node

signal chunk_generated(chunk_pos, chunk_data)

@onready var tile_map = $TileMap
@onready var packet_handler = $PacketHandler
@export var noise_texture : NoiseTexture2D
@export var tree_noise_texture : NoiseTexture2D
@export var decorator_noise_texture : NoiseTexture2D

var chunk_size : int = 8
var render_distance : int = 3
var noise : Noise
var tree_noise : Noise
var decorator_noise : Noise
var water_tile_atlas = Vector2i(0,1)
var tree_atlas = Vector2i(12,2)
var tree_atlas2 = Vector2i(15,6)

var generated_chunks = {}
var chunk_generation_queue = []

var water_layer = 0
var ground_1_layer = 1
var ground_2_layer = 2
var cliff_layer = 3
var environment_layer = 4

var random_grass_atlas_arr = [Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(5,0)]

var spawners = []
var spawned_entities = {}

var players = []  # Dynamically track players

var world_file_path = "user://save_file.dat"

func _ready():

	packet_handler.world = $"."

	
	if OS.has_feature("dedicated_server"):

		MultiplayerManager.become_host()
	


func setup_world():
	packet_handler.setup_packets()
	
	if (is_multiplayer_authority() or OS.has_feature("dedicated_server")):
		print("Server is network master. Initializing chunk generation.")
		initialize_server()
	else:
		# Client-side initialization
		multiplayer.peer_connected.connect(self._on_peer_connected)

func initialize_server():
	print("Loading World...")
	var data = load_world()	
	noise = noise_texture.noise
	tree_noise = tree_noise_texture.noise
	decorator_noise = decorator_noise_texture.noise
	
	if len(data.keys()) > 0:
		noise.seed = data.values()[0]
		tree_noise.seed = data.values()[1]
		decorator_noise.seed = data.values()[2]
	else:
		noise.seed = randi()
		tree_noise.seed = randi()
		decorator_noise.seed = randi()
	# Add your spawners here
	add_spawner("rock", "res://scenes/entities/rock.tscn", func(x, y): 
		return randf() < 0.00125 and noise.get_noise_2d(x,y) > 0.15 and noise.get_noise_2d(x,y) < 0.6)

	add_spawner("capybara", "res://scenes/entities/capi.tscn", func(x, y): 
		return randf() < 0.0005 and noise.get_noise_2d(x,y) > 0.15 and noise.get_noise_2d(x,y) < 0.6)
	
	add_spawner("desert_rock", "res://scenes/entities/desert_rock.tscn", func(x, y): 
		return randf() < 0.0025 and noise.get_noise_2d(x,y) > 0 and noise.get_noise_2d(x,y) < 0.15)
	
	update_players_list()
	
	# Start processing chunks in the next frame
	call_deferred("start_chunk_processing")

func start_chunk_processing():
	set_process(true)
	process_chunk_queue()

func _process(_delta):
	if not is_multiplayer_authority():
		return
	
	update_players_list()
	update_chunks_for_all_players()
	process_chunk_queue()

func update_players_list():
	players = get_tree().get_current_scene().find_child("Players").get_children()

func update_chunks_for_all_players():
	for player_obj in players:
		if player_obj and player_obj.is_inside_tree():
			var player_pos = player_obj.position
			var player_chunk = world_to_chunk(player_pos)
			for x in range(player_chunk.x - render_distance, player_chunk.x + render_distance + 1):
				for y in range(player_chunk.y - render_distance, player_chunk.y + render_distance + 1):
					var chunk_pos = Vector2(x, y)
					if not generated_chunks.has(chunk_pos) and not chunk_pos in chunk_generation_queue:
						print("Queuing new chunk for player: ", chunk_pos)
						chunk_generation_queue.append(chunk_pos)

func process_chunk_queue():
	if is_multiplayer_authority() and not chunk_generation_queue.is_empty():
		var chunk_pos = chunk_generation_queue.pop_front()
		if not generated_chunks.has(chunk_pos):
			var chunk_data = generate_chunk_data(chunk_pos)
			apply_chunk_data(chunk_pos, chunk_data)
			packet_handler.send_packet(ChunkDataPacket.new({"chunk_pos": chunk_pos, "chunk_data": chunk_data}))
			generated_chunks[chunk_pos] = true

func generate_chunk_data(chunk_pos):
	var chunk_data = {}
	var start_x = chunk_pos.x * chunk_size
	var start_y = chunk_pos.y * chunk_size

	for x in range(start_x, start_x + chunk_size):
		for y in range(start_y, start_y + chunk_size):
			chunk_data[Vector2(x, y)] = generate_tile_data(x, y)

	return chunk_data

func generate_tile_data(x: int, y: int):
	var noise_val = noise.get_noise_2d(x, y)
	var tree_noise_val = tree_noise.get_noise_2d(x, y)
	var decorator_noise_val = decorator_noise.get_noise_2d(x, y)
	var tile_data = {}

	tile_data["water"] = {layer = water_layer, atlas = water_tile_atlas}
	if noise_val > 0.6:
		tile_data["cliff"] = {layer = cliff_layer, terrain = 4}
	elif noise_val > 0.15:
		tile_data["grass"] = {layer = ground_1_layer, terrain = 1}
		if noise_val > 0.3:
			tile_data["random_grass"] = {layer = ground_2_layer, atlas = random_grass_atlas_arr.pick_random()}
	elif noise_val > 0:
		tile_data["sand"] = {layer = ground_1_layer, terrain = 3}
	if randi_range(0,100) == 0 and noise_val > 0.3 and noise_val < 0.5:
		tile_data["tree"] = {layer = environment_layer, atlas = tree_atlas2}
	elif noise_val > 0 and noise_val < 0.18 and randi_range(0,200) == 0:
		tile_data["palm"] = {layer = environment_layer, atlas = tree_atlas}

	for spawner in spawners:
		if spawner["condition"].call(x, y):
			tile_data[spawner["name"]] = true
	
	return tile_data

func add_spawner(name: String, scene_path: String, condition: Callable):
	spawners.append({
		"name": name,
		"scene_path": scene_path,
		"condition": condition
	})


func spawn_object(scene_path: String, pos: Vector2):
	var scene = load(scene_path) as PackedScene
	var instance: Node2D = scene.instantiate()
	instance.position = pos * 16
	add_child(instance)
	
	if not spawned_entities.has(scene_path):
		spawned_entities[scene_path] = []
	spawned_entities[scene_path].append(pos)

	if is_multiplayer_authority():
		packet_handler.send_packet(SpawnObjectPacket.new({"scene_path": scene_path, "pos": pos}))
		print(scene_path)
		
func world_to_chunk(pos: Vector2) -> Vector2:
	return Vector2(floor(pos.x / (chunk_size * 16)), floor(pos.y / (chunk_size * 16)))

func get_chunk_data(chunk_pos: Vector2) -> Dictionary:
	if is_multiplayer_authority():
		if not generated_chunks.has(chunk_pos):
			var chunk_data = generate_chunk_data(chunk_pos)
			apply_chunk_data(chunk_pos, chunk_data)
			generated_chunks[chunk_pos] = true
			return chunk_data
		else:
			return reconstruct_chunk_data(chunk_pos)
	print("this should never happen")
	return {}

func reconstruct_chunk_data(chunk_pos: Vector2) -> Dictionary:
	var chunk_data = {}
	var start_x = chunk_pos.x * chunk_size
	var start_y = chunk_pos.y * chunk_size

	for x in range(start_x, start_x + chunk_size):
		for y in range(start_y, start_y + chunk_size):
			var pos = Vector2(x, y)
			chunk_data[pos] = {}
			for layer in [water_layer, ground_1_layer, ground_2_layer, cliff_layer, environment_layer]:
				var cell = tile_map.get_cell_atlas_coords(layer, pos)
				if cell != Vector2i(-1, -1):
					chunk_data[pos][layer] = {
						"layer": layer,
						"atlas": cell
					}
			# Add spawned entities if any
			for scene_path in spawned_entities:
				if pos in spawned_entities[scene_path]:
					chunk_data[pos][scene_path.get_file().get_basename()] = true

	return chunk_data

func save_world():
	var save_file = FileAccess.open(world_file_path, FileAccess.WRITE)
	if save_file:
		save_file.store_32(noise.seed)
		save_file.store_32(tree_noise.seed)
		save_file.store_32(decorator_noise.seed)
	
		var layers = [water_layer, ground_1_layer, ground_2_layer, cliff_layer, environment_layer]
		var tile_count = 0
		var tile_data = []
		
		for layer in layers:
			for cell_pos in tile_map.get_used_cells(layer):
				tile_count += 1
				var cell_atlas_coords = tile_map.get_cell_atlas_coords(layer, cell_pos)
				tile_data.append({
					"pos": cell_pos,
					"layer": layer,
					"atlas": cell_atlas_coords
				})
		
		save_file.store_32(tile_count)
		for tile in tile_data:
			save_file.store_float(tile["pos"].x)
			save_file.store_float(tile["pos"].y)
			save_file.store_32(tile["layer"])
			save_file.store_8(tile["atlas"].x)  
			save_file.store_8(tile["atlas"].y)  
		
		save_file.store_32(spawned_entities.size())
		for scene_path in spawned_entities:
			save_file.store_pascal_string(scene_path)
			save_file.store_32(spawned_entities[scene_path].size())
			for pos in spawned_entities[scene_path]:
				save_file.store_float(pos.x)
				save_file.store_float(pos.y)
		
		save_file.store_32(generated_chunks.size())
		for chunk_pos in generated_chunks:
			save_file.store_float(chunk_pos.x)
			save_file.store_float(chunk_pos.y)
		
		save_file.close()
		print("World saved successfully")
	else:
		print("Failed to save world")

func load_world() -> Dictionary:
	if FileAccess.file_exists(world_file_path):
		var save_file = FileAccess.open(world_file_path, FileAccess.READ)
		if save_file:
			var loaded_noise_seed = save_file.get_32()
			var loaded_tree_noise_seed = save_file.get_32()
			var loaded_decorator_noise_seed = save_file.get_32()
			
			tile_map.clear()

			# Read tile data
			var tile_count = save_file.get_32()  # Add this line to store the number of tiles
			for _i in range(tile_count):
				var cell_x = save_file.get_float()
				var cell_y = save_file.get_float()
				var layer = save_file.get_32()
				var cell_value_x = save_file.get_8()
				var cell_value_y = save_file.get_8()
				var cell_pos = Vector2i(cell_x, cell_y)
				tile_map.set_cell(layer, cell_pos, 0, Vector2i(cell_value_x, cell_value_y))  # Assuming the atlas coordinates are stored in cell_value
			
			# Read entity data
			var entity_types_count = save_file.get_32()
			for _i in range(entity_types_count):
				var scene_path = save_file.get_pascal_string()
				var entity_count = save_file.get_32()
				spawned_entities[scene_path] = []
				for _j in range(entity_count):
					var x = save_file.get_float()
					var y = save_file.get_float()
					var pos = Vector2(x, y)
					spawned_entities[scene_path].append(pos)
					spawn_object(scene_path, pos)
			
			# Read chunk data
			var chunk_count = save_file.get_32()
			for _i in range(chunk_count):
				var chunk_x = save_file.get_float()
				var chunk_y = save_file.get_float()
				var chunk_pos = Vector2(chunk_x, chunk_y)
				generated_chunks[chunk_pos] = true
				# Don't regenerate chunk data, just mark it as generated
			
			save_file.close()
			print("World loaded successfully")
			
			return {
				"noise_seed": loaded_noise_seed,
				"tree_noise_seed": loaded_tree_noise_seed,
				"decorator_noise_seed": loaded_decorator_noise_seed
			}
		else:
			print("Failed to open world file")
	else:
		print("No world file found")
	
	return {}

func _on_peer_connected(id: int):

	if is_multiplayer_authority():
		for chunk_pos in generated_chunks.keys():
			var chunk_data = get_chunk_data(chunk_pos)
			packet_handler.send_packet(ChunkDataPacket.new({"chunk_pos": chunk_pos, "chunk_data": chunk_data}))


		for scene_path in spawned_entities:
			for pos in spawned_entities[scene_path]:
				packet_handler.send_packet(SpawnObjectPacket.new({"scene_path": scene_path, "pos": pos}))


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_multiplayer_authority() and len(generated_chunks) > 0.:
			save_world()

# Client-side functions
func on_chunk_generated(chunk_pos, chunk_data):
	if not generated_chunks.has(chunk_pos):
		for tile_pos in chunk_data:
			apply_tile_data(tile_pos, chunk_data[tile_pos])
		generated_chunks[chunk_pos] = true
		print("Chunk generated and applied on client:", chunk_pos)
		

func apply_chunk_data(chunk_pos, chunk_data):
	for tile_pos in chunk_data:
		apply_tile_data(tile_pos, chunk_data[tile_pos])

func apply_tile_data(pos: Vector2, tile_data: Dictionary):
	for key in tile_data:
		var data = tile_data[key]
		
		for spawner in spawners:
			if typeof(key) != TYPE_STRING:
				print(spawner.name)
				continue
			if key == spawner["name"] and tile_data.get(key, false) == true:
				spawn_object(spawner["scene_path"], pos)
				continue
				
		if typeof(data) == TYPE_BOOL:
			continue
		
		if "atlas" in data:
			tile_map.set_cell(data["layer"], pos, 0, data["atlas"])
		if "terrain" in data:
			tile_map.set_cells_terrain_connect(data["layer"], [pos], data["terrain"], 0)



func _on_join_game_pressed():
	call_deferred("setup_world")
	MultiplayerManager.join_as_player_2()

func _on_host_game_pressed():

	call_deferred("setup_world")
	MultiplayerManager.become_host()
