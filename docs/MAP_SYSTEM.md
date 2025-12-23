# Map System Documentation

## Overview
The game now supports multiple maps/levels with automatic vehicle spawning based on map assignments. The system is designed to be data-driven, allowing easy creation of new maps without code changes.

## Architecture

### MapData Resource
Defines a map configuration with:
- `map_id`: Unique identifier (e.g., "main_world", "dungeon_1")
- `map_name`: Display name
- `map_description`: Description text
- `chunk_scenes`: Dictionary of chunk coordinates to scene paths (for chunk-based maps)
- `default_spawn_position`: Where the player spawns when entering this map
- `use_chunk_loading`: Whether to use chunk-based loading

### MapManager (Autoload)
Global singleton that:
- Maintains registry of available maps
- Tracks current active map
- Handles chunk loading/unloading
- Saves/loads map state
- Emits `map_changed` signal when switching maps

### Vehicle Map Binding
Vehicles can be assigned to specific maps:
- Set `assigned_map_id` property on Vehicle node
- Empty `assigned_map_id` = available on all maps
- Vehicle automatically hidden and disabled when not on its assigned map
- Vehicle position saved/loaded per save file

## Creating a New Map

### Step 1: Create Map Scenes
1. Create map chunk scene(s) in `features/map/chunks/`
2. Example: `dungeon_0_0.tscn` for a dungeon chunk

### Step 2: Register Map in MapManager
Option A - Code Registration (in `systems/map_manager.gd::_initialize_available_maps()`):
```gdscript
var dungeon_map = MapData.new()
dungeon_map.map_id = "dungeon_1"
dungeon_map.map_name = "Dark Dungeon"
dungeon_map.map_description = "A mysterious underground dungeon"
dungeon_map.use_chunk_loading = true
dungeon_map.chunk_scenes = {
    Vector2i(0, 0): "res://features/map/chunks/dungeon_0_0.tscn"
}
dungeon_map.default_spawn_position = Vector2(640, 360)
available_maps["dungeon_1"] = dungeon_map
```

Option B - Resource File (future enhancement):
Create `data/maps/dungeon_1.tres` and load it in MapManager.

### Step 3: Place Vehicles on Map
In scene editor (e.g., `scenes/main.tscn`):
1. Select Vehicle node
2. Set `assigned_map_id` property to map ID (e.g., "main_world")
3. Vehicle will only appear when player is on that map

### Step 4: Switch Maps
Use MapManager API:
```gdscript
# Switch to dungeon
MapManager.switch_to_map("dungeon_1")

# Switch with custom spawn position
MapManager.switch_to_map("dungeon_1", Vector2(100, 100))
```

## Save/Load Behavior

### What Gets Saved
- Current map ID
- Player position (per-map)
- Vehicle positions and map assignments
- Loaded chunks

### Loading a Save
1. SaveManager loads map ID from save file
2. MapManager switches to saved map
3. Player spawns at saved position (or map default if new)
4. Vehicles appear only on their assigned maps

## Example: Portal/Door System

```gdscript
# portal.gd
extends Area2D

@export var target_map_id: String = "dungeon_1"
@export var target_spawn_position: Vector2 = Vector2(640, 360)

func _on_body_entered(body):
    if body.is_in_group("player"):
        # Switch map and move player
        MapManager.switch_to_map(target_map_id, target_spawn_position)
        body.global_position = target_spawn_position
```

## Testing

Run `tests/map_switching_test.tscn` to verify:
- Map registration
- Save/load functionality
- MapData serialization
- Default map initialization

## Future Enhancements

1. **Map Transitions**: Add fade effects, loading screens
2. **Resource-Based Maps**: Load MapData from .tres files
3. **Dynamic Vehicle Spawning**: Spawn vehicles only when needed
4. **Map Preloading**: Load adjacent maps in background
5. **Minimap Integration**: Show current map in UI
6. **Map Discovery**: Track which maps player has visited

## API Reference

### MapManager Methods

```gdscript
# Register a new map
MapManager.register_map(map_data: MapData) -> void

# Get map data by ID
MapManager.get_map_data(map_id: String) -> MapData

# Switch to different map
MapManager.switch_to_map(map_id: String, spawn_position: Vector2 = Vector2.ZERO) -> bool

# Current map info
MapManager.current_map_id -> String
MapManager.current_map_data -> MapData
```

### EventBus Signals

```gdscript
# Emitted when map changes
EventBus.map_changed.connect(_on_map_changed)

func _on_map_changed(map_id: String, spawn_position: Vector2):
    print("Switched to map: ", map_id)
```

## Troubleshooting

**Vehicle not appearing:**
- Check `assigned_map_id` matches current map
- Ensure vehicle is in "vehicle" group
- Verify vehicle visibility is not disabled

**Map not loading:**
- Verify map is registered in MapManager
- Check chunk scene paths are correct
- Ensure map_id is unique

**Save/load issues:**
- Confirm vehicle is in "saveable" group
- Check SaveManager is loading before scene
- Verify MapManager.load_data() is called
