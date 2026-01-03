# test_game_scene_loading.gd
# Test script to verify game scene loading functionality
extends Node

func _ready() -> void:
	print("=== Game Scene Loading Test ===")
	
	# Test 1: Load data classes
	print("\n1. Testing data class loading...")
	var spawnable_data = SpawnableEntityData.new()
	spawnable_data.entity_type = "enemy"
	spawnable_data.scene_path = "res://features/actor/base_actor.tscn"
	spawnable_data.spawn_position = Vector2(100, 100)
	print("✓ SpawnableEntityData created: type=%s, pos=%s" % [spawnable_data.entity_type, spawnable_data.spawn_position])
	
	var player_spawn = PlayerSpawnData.new()
	player_spawn.spawn_position = Vector2(500, 500)
	player_spawn.spawn_id = "test_spawn"
	print("✓ PlayerSpawnData created: id=%s, pos=%s" % [player_spawn.spawn_id, player_spawn.spawn_position])
	
	var map_data = MapData.new()
	map_data.map_id = "test_map"
	map_data.map_name = "Test Map"
	print("✓ MapData created: id=%s" % map_data.map_id)
	
	# Test 2: Create GameSceneData
	print("\n2. Testing GameSceneData creation...")
	var game_scene_data = GameSceneData.new()
	game_scene_data.scene_id = "test_scene"
	game_scene_data.scene_name = "Test Scene"
	game_scene_data.map_data = map_data
	game_scene_data.player_spawn = player_spawn
	game_scene_data.spawnable_entities.append(spawnable_data)
	print("✓ GameSceneData created: id=%s, entities=%d" % [game_scene_data.scene_id, game_scene_data.spawnable_entities.size()])
	
	# Test 3: Test serialization
	print("\n3. Testing serialization...")
	var dict = game_scene_data.to_dict()
	print("✓ Serialized to dictionary: keys=%s" % dict.keys())
	
	var game_scene_data_2 = GameSceneData.new()
	game_scene_data_2.from_dict(dict)
	print("✓ Deserialized from dictionary: id=%s" % game_scene_data_2.scene_id)
	
	# Test 4: Load default game scene data
	print("\n4. Testing resource loading...")
	var default_scene = load("res://data/game_scenes/default_game_scene.tres")
	if default_scene:
		print("✓ Loaded default_game_scene.tres")
		print("  - Scene ID: %s" % default_scene.scene_id)
		print("  - Scene Name: %s" % default_scene.scene_name)
		if default_scene.map_data:
			print("  - Map ID: %s" % default_scene.map_data.map_id)
		if default_scene.player_spawn:
			print("  - Player Spawn: %s" % default_scene.player_spawn.spawn_position)
	else:
		print("✗ Failed to load default_game_scene.tres")
	
	print("\n=== Test Complete ===")
	
	# Exit after test
	await get_tree().create_timer(1.0).timeout
	print("Exiting...")
	get_tree().quit()
