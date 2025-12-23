# map_switching_test.gd
# Test script for map switching functionality
extends Node

func _ready():
	print("=== Map Switching Test Started ===")
	
	# Test 1: Check default map initialization
	print("\n--- Test 1: Default Map Initialization ---")
	assert(MapManager.available_maps.has("main_world"), "Default map 'main_world' should exist")
	print("✓ Default map exists")
	
	assert(MapManager.current_map_id == "main_world", "Current map should be 'main_world'")
	print("✓ Current map is set to 'main_world'")
	
	assert(MapManager.current_map_data != null, "Current map data should not be null")
	print("✓ Current map data is loaded")
	
	# Test 2: Check MapData structure
	print("\n--- Test 2: MapData Structure ---")
	var map_data = MapManager.current_map_data
	assert(map_data.map_id == "main_world", "Map ID should be 'main_world'")
	print("✓ Map ID is correct")
	
	assert(not map_data.chunk_scenes.is_empty(), "Chunk scenes should not be empty")
	print("✓ Chunk scenes are defined")
	
	assert(map_data.default_spawn_position != Vector2.ZERO, "Default spawn position should be set")
	print("✓ Default spawn position is set: ", map_data.default_spawn_position)
	
	# Test 3: Register a new test map
	print("\n--- Test 3: Register New Map ---")
	var test_map = MapData.new()
	test_map.map_id = "test_map"
	test_map.map_name = "Test Map"
	test_map.default_spawn_position = Vector2(100, 100)
	test_map.use_chunk_loading = false
	
	MapManager.register_map(test_map)
	assert(MapManager.available_maps.has("test_map"), "Test map should be registered")
	print("✓ New map registered successfully")
	
	# Test 4: Save and load map data
	print("\n--- Test 4: Save/Load Map Data ---")
	var save_dict = MapManager.save_data()
	assert(save_dict.has("current_map_id"), "Save data should contain current_map_id")
	assert(save_dict["current_map_id"] == "main_world", "Saved map ID should be 'main_world'")
	print("✓ Map data saved correctly")
	
	# Simulate switching to test map
	MapManager.current_map_id = "test_map"
	var save_dict2 = MapManager.save_data()
	assert(save_dict2["current_map_id"] == "test_map", "Saved map ID should be 'test_map'")
	
	# Load back to main_world
	MapManager.load_data(save_dict)
	assert(MapManager.current_map_id == "main_world", "Loaded map ID should be 'main_world'")
	print("✓ Map data loaded correctly")
	
	# Test 5: MapData serialization
	print("\n--- Test 5: MapData Serialization ---")
	var map_dict = test_map.to_dict()
	assert(map_dict.has("map_id"), "Serialized data should have map_id")
	assert(map_dict.has("map_name"), "Serialized data should have map_name")
	assert(map_dict.has("default_spawn_position"), "Serialized data should have default_spawn_position")
	print("✓ MapData serialization works")
	
	var new_map = MapData.new()
	new_map.from_dict(map_dict)
	assert(new_map.map_id == test_map.map_id, "Deserialized map_id should match")
	assert(new_map.map_name == test_map.map_name, "Deserialized map_name should match")
	assert(new_map.default_spawn_position == test_map.default_spawn_position, "Deserialized spawn position should match")
	print("✓ MapData deserialization works")
	
	print("\n=== All Map Switching Tests Passed! ===")
	
	# Exit after tests
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
