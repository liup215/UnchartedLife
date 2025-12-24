# Map Switching Feature - Implementation Summary

## Overview
This document summarizes the complete implementation of the map/level switching feature for Legends of Uncharted Life.

## Problem Statement (Original Issue)
新的功能，关卡/地图切换功能，游戏需要能够设置一个默认的初始地图，还要能够在不同的地图中切换；在不同的地图中储存游戏，加载时要加载对应的地图；载具停放的位置也要和地图绑定，只能在对应地图的关卡才能找到

**Translation:**
New feature: Level/map switching functionality. The game needs to be able to set a default initial map and switch between different maps. Game saves should be map-specific, loading the corresponding map. Vehicle parking positions should also be bound to maps, only findable in their designated map/level.

## Requirements Fulfilled ✅

### 1. Default Initial Map
- ✅ Default map "main_world" automatically loads for new games
- ✅ Configured in `MapManager.DEFAULT_MAP_ID`
- ✅ Player spawns at `MapData.default_spawn_position`

### 2. Map Switching
- ✅ `MapManager.switch_to_map(map_id, spawn_position)` API
- ✅ Automatic chunk unloading/loading
- ✅ EventBus signal `map_changed` for system notifications
- ✅ Example portal implementation provided

### 3. Map-Specific Saves
- ✅ Current map ID saved with game state
- ✅ Player position preserved per map
- ✅ Correct map restored on load
- ✅ Vehicle states saved with map associations

### 4. Vehicle-Map Binding
- ✅ `assigned_map_id` property on Vehicle
- ✅ Vehicles only visible/active on assigned map
- ✅ Automatic show/hide based on current map
- ✅ Vehicle positions saved with map assignments

## Files Created/Modified

### New Files
1. `data/definitions/system/map_data.gd` - MapData resource class
2. `docs/MAP_SYSTEM.md` - English documentation
3. `docs/MAP_SYSTEM_CN.md` - Chinese documentation
4. `features/map/example_map_portal.gd` - Portal example
5. `tests/map_switching_test.gd` - Test suite
6. `tests/map_switching_test.tscn` - Test scene

### Modified Files
1. `systems/map_manager.gd` - Multi-map support
2. `systems/event_bus.gd` - Added map_changed signal
3. `features/vehicle/base_vehicle.gd` - Map binding logic
4. `systems/main_game_manager.gd` - Player spawn initialization

## Architecture

### MapData Resource
```gdscript
class_name MapData extends Resource
- map_id: String                    # Unique identifier
- map_name: String                  # Display name
- chunk_scenes: Dictionary          # Vector2i -> scene path
- default_spawn_position: Vector2   # Player spawn point
- use_chunk_loading: bool           # Chunk vs full map
```

### MapManager (Autoload)
```gdscript
- available_maps: Dictionary        # All registered maps
- current_map_id: String            # Active map
- current_map_data: MapData         # Active map data
- register_map()                    # Add new map
- switch_to_map()                   # Change maps
- save_data() / load_data()         # Persistence
```

### Vehicle Map Binding
```gdscript
@export var assigned_map_id: String  # Map assignment
- _on_map_changed()                  # Signal handler
- _update_visibility_for_current_map() # Show/hide logic
```

## Usage Guide

### Creating a New Map

1. **Create map chunk scene(s)**
   ```
   features/map/chunks/dungeon_0_0.tscn
   ```

2. **Register in MapManager**
   ```gdscript
   # In systems/map_manager.gd::_initialize_available_maps()
   var dungeon = MapData.new()
   dungeon.map_id = "dungeon_1"
   dungeon.map_name = "Dark Dungeon"
   dungeon.chunk_scenes = {
       Vector2i(0, 0): "res://features/map/chunks/dungeon_0_0.tscn"
   }
   dungeon.default_spawn_position = Vector2(640, 360)
   available_maps["dungeon_1"] = dungeon
   ```

3. **Assign vehicles to map**
   - In scene editor: Set Vehicle's `assigned_map_id` to "main_world"
   - Empty = available on all maps

4. **Create portal/door**
   ```gdscript
   extends Area2D
   @export var target_map_id: String = "dungeon_1"
   @export var target_spawn_position: Vector2 = Vector2(640, 360)
   
   func _on_body_entered(body):
       if body.is_in_group("player"):
           MapManager.switch_to_map(target_map_id, target_spawn_position)
           body.global_position = target_spawn_position
   ```

### Save/Load Flow

**Saving:**
1. MapManager.save_data() returns {"current_map_id": "main_world", ...}
2. Vehicle.save_data() returns {"assigned_map_id": "main_world", ...}
3. SaveManager stores everything to disk

**Loading:**
1. SaveManager reads save file
2. MapManager.load_data() restores current_map_id
3. Vehicle.load_data() restores assigned_map_id
4. Vehicles auto-show/hide based on current map

## API Reference

### MapManager
```gdscript
# Register a new map
MapManager.register_map(map_data: MapData) -> void

# Switch to different map
MapManager.switch_to_map(map_id: String, spawn_position: Vector2 = Vector2.ZERO) -> bool

# Get map data
MapManager.get_map_data(map_id: String) -> MapData

# Current state
MapManager.current_map_id -> String
MapManager.current_map_data -> MapData
MapManager.available_maps -> Dictionary
```

### EventBus
```gdscript
# Listen for map changes
EventBus.map_changed.connect(_on_map_changed)

func _on_map_changed(map_id: String, spawn_position: Vector2):
    print("Map changed to: ", map_id)
```

## Testing

Run `tests/map_switching_test.tscn` to verify:
- ✅ Default map initialization
- ✅ MapData structure validation
- ✅ New map registration
- ✅ Save/load functionality
- ✅ MapData serialization/deserialization

## Technical Decisions

1. **Data-Driven Design**: Maps defined as resources, not hardcoded
2. **Component-Based**: Vehicle visibility as a component behavior
3. **Signal-Based Communication**: EventBus for decoupling
4. **Backward Compatible**: Empty assigned_map_id = all maps
5. **Minimal Changes**: Surgical modifications to existing code

## Performance Considerations

- **Chunk Unloading**: All chunks unloaded on map switch to free memory
- **Physics Disabling**: Vehicles on inactive maps have physics disabled
- **Lazy Loading**: Chunks loaded only when player nearby

## Future Enhancements

1. **Resource-Based Maps**: Load MapData from .tres files
2. **Map Transitions**: Fade effects, loading screens
3. **Dynamic Vehicle Spawning**: Create vehicles on demand
4. **Map Preloading**: Background loading of adjacent maps
5. **Minimap Integration**: Show current map in UI
6. **Map Discovery System**: Track visited maps

## Migration Notes

For existing projects:
1. Vehicle nodes automatically get `assigned_map_id = ""`
2. Empty means available on all maps (backward compatible)
3. Set `assigned_map_id` in scene editor to restrict vehicles
4. Existing saves remain compatible

## Code Quality

- ✅ Static typing throughout
- ✅ Follows existing code patterns
- ✅ Comprehensive documentation
- ✅ Test coverage included
- ✅ Signal-based decoupling
- ✅ Resource-based data

## Conclusion

All requirements from the original issue have been fully implemented:
- ✅ Default initial map configuration
- ✅ Map switching functionality
- ✅ Map-specific save/load system
- ✅ Vehicle-map binding with position storage

The implementation is production-ready, well-documented, and follows the project's architectural patterns.
