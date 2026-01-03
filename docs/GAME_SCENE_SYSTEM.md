# Game Scene Loading System

## Overview
The game scene loading system implements a data-driven architecture for game scenes, separating scene configuration (data) from scene logic (code). This allows for flexible scene composition without modifying code.

## Architecture

### Core Concept: "Soul-Container-Brain"
Following the project's established pattern:
- **Soul (Data)**: `GameSceneData` resource defines what exists in the scene
- **Container (Scene)**: `game_scene.tscn` is the generic shell
- **Brain (Logic)**: `game_scene.gd` reads data and spawns entities

### Key Components

#### 1. GameSceneData (Resource)
Main configuration for a complete game scene.

**Properties:**
- `scene_id`: Unique identifier
- `scene_name`: Display name
- `map_data`: MapData resource for static map/level
- `player_spawn`: PlayerSpawnData for player configuration
- `spawnable_entities`: Array of SpawnableEntityData for dynamic entities
- `background_music`: Optional AudioStream
- `ambient_sound`: Optional AudioStream
- `scene_settings`: Dictionary for custom settings

#### 2. SpawnableEntityData (Resource)
Defines a spawnable entity (NPC, vehicle, enemy, interactive object).

**Properties:**
- `entity_type`: Type identifier (e.g., "enemy", "vehicle", "npc")
- `scene_path`: Path to scene to instantiate
- `spawn_position`: World position for spawning
- `entity_resource`: Optional data resource (ActorData, VehicleData, etc.)
- `spawn_id`: Unique identifier for this spawn point
- `additional_config`: Dictionary for extra configuration

#### 3. PlayerSpawnData (Resource)
Defines player spawn configuration.

**Properties:**
- `spawn_position`: World position for player
- `spawn_id`: Identifier for this spawn point
- `player_data`: Optional override for player data

#### 4. GameScene (Scene + Script)
Generic scene container that loads from GameSceneData.

**Features:**
- Loads static map from MapData
- Spawns player at configured position
- Spawns dynamic entities from configuration
- Handles UI (HUD, SystemMenu, DialoguePanel)
- Supports save/load
- Integrates with MapManager for chunk loading

## Usage

### Creating a New Game Scene Configuration

#### Step 1: Create GameSceneData Resource
Create a new `.tres` file in `data/game_scenes/`:

```gdscript
# In Godot Editor:
# 1. Right-click data/game_scenes/ folder
# 2. Create New > Resource
# 3. Search for "GameSceneData"
# 4. Configure properties in Inspector
```

#### Step 2: Configure Map Data
Either reference an existing MapData or create an embedded one:

```gdscript
# Embedded MapData example
map_data.map_id = "forest_level"
map_data.map_name = "Enchanted Forest"
map_data.default_spawn_position = Vector2(640, 360)
map_data.use_chunk_loading = true
map_data.chunk_scenes = {
    Vector2i(0, 0): "res://features/map/chunks/forest_0_0.tscn"
}
```

#### Step 3: Configure Player Spawn
```gdscript
player_spawn.spawn_position = Vector2(640, 360)
player_spawn.spawn_id = "main_entrance"
player_spawn.player_data = preload("res://data/actors/player/player_data.tres")
```

#### Step 4: Add Spawnable Entities
Click "Add Element" to add SpawnableEntityData entries:

**Example - Spawn a Vehicle:**
```gdscript
entity_type = "vehicle"
scene_path = "res://features/vehicle/base_vehicle.tscn"
spawn_position = Vector2(800, 400)
entity_resource = preload("res://data/vehicles/basic_tank_data.tres")
spawn_id = "tank_1"
additional_config = {"assigned_map_id": "main_world"}
```

**Example - Spawn an Enemy:**
```gdscript
entity_type = "enemy"
scene_path = "res://features/actor/base_actor.tscn"
spawn_position = Vector2(1000, 500)
entity_resource = preload("res://data/actors/enemies/head_cutter/goblin_data.tres")
spawn_id = "goblin_1"
additional_config = {}
```

**Example - Spawn an NPC:**
```gdscript
entity_type = "npc"
scene_path = "res://features/actor/base_actor.tscn"
spawn_position = Vector2(500, 300)
entity_resource = preload("res://data/actors/npcs/merchant_data.tres")
spawn_id = "merchant_1"
additional_config = {"dialogue_id": "merchant_intro"}
```

### Using the Game Scene

#### Method 1: Direct in main.tscn
```gdscript
# main.tscn
[node name="GameScene" instance=ExtResource("game_scene.tscn")]
game_scene_data = ExtResource("your_game_scene_data.tres")
```

#### Method 2: Dynamic Loading
```gdscript
# In code
var game_scene_data = load("res://data/game_scenes/my_scene.tres")
var game_scene = load("res://scenes/game_scene.tscn").instantiate()
game_scene.game_scene_data = game_scene_data
get_tree().root.add_child(game_scene)
```

#### Method 3: Scene Transition
```gdscript
# Update main menu or scene manager
func start_game_with_scene(scene_data_path: String) -> void:
    var scene_data = load(scene_data_path)
    # Load main.tscn but with custom scene data
    # Implementation depends on your transition system
```

## API Reference

### GameScene Public Methods

```gdscript
# Get the player instance
func get_player() -> Node2D

# Get a spawned entity by its spawn_id
func get_entity(spawn_id: String) -> Node

# Get all spawned entities
func get_all_entities() -> Array

# Save game scene state
func save_data() -> Dictionary

# Load game scene state
func load_data(data: Dictionary) -> void
```

### Example: Accessing Spawned Entities
```gdscript
# In another script
var game_scene = get_node("/root/Main/GameScene")
var player = game_scene.get_player()
var tank = game_scene.get_entity("tank_1")
var all_enemies = game_scene.get_all_entities().filter(
    func(e): return e.is_in_group("enemy")
)
```

## Integration with Existing Systems

### MapManager
GameScene automatically integrates with MapManager:
- Registers map if not already registered
- Sets map_parent for chunk loading
- Switches to configured map on scene setup

### SaveManager
GameScene supports save/load:
- Player position saved/loaded automatically
- Entity states saved if they implement `save_data()/load_data()`
- Use `SaveManager.is_loading_from_save()` to check load state

### EventBus
GameScene respects existing event patterns:
- Map changes emit `EventBus.map_changed`
- Entity spawn can emit custom events
- UI interactions use existing event bus signals

## Best Practices

### 1. Entity Type Naming
Use consistent entity type names:
- `"player"` - Player character
- `"enemy"` - Enemy actors
- `"npc"` - Non-player characters
- `"vehicle"` - Drivable vehicles
- `"interactive"` - Interactive objects
- `"pickup"` - Collectible items

### 2. Spawn ID Convention
Use descriptive spawn IDs:
- `"tank_spawn_1"`, `"tank_spawn_2"` for vehicles
- `"goblin_1"`, `"goblin_2"` for enemies
- `"npc_merchant"`, `"npc_guard"` for NPCs

### 3. Scene Path Organization
Keep scene paths organized:
- Actors: `"res://features/actor/base_actor.tscn"`
- Vehicles: `"res://features/vehicle/base_vehicle.tscn"`
- Custom: `"res://features/[type]/[name].tscn"`

### 4. Resource Data Reuse
Create reusable entity data:
```
data/
  actors/
    enemies/
      goblin_data.tres
      slime_data.tres
    npcs/
      merchant_data.tres
```

### 5. Additional Config Usage
Use `additional_config` for entity-specific settings:
```gdscript
additional_config = {
    "dialogue_id": "intro_conversation",
    "quest_giver": true,
    "patrol_path": [Vector2(100, 100), Vector2(200, 100)]
}
```

## Migration from Old System

### Old Approach (main.tscn with hardcoded entities)
```
[node name="Main"]
[node name="Player" instance=...]
[node name="Enemy1" instance=...]
[node name="Enemy2" instance=...]
```

### New Approach (GameSceneData)
```gdscript
# Create game_scene_data.tres
spawnable_entities = [
    { entity_type: "player", scene_path: "...", ... },
    { entity_type: "enemy", scene_path: "...", ... },
    { entity_type: "enemy", scene_path: "...", ... }
]

# main.tscn becomes simple
[node name="GameScene" instance=ExtResource("game_scene.tscn")]
game_scene_data = ExtResource("game_scene_data.tres")
```

### Benefits
- No scene editing for entity placement
- Entity configuration in data files
- Easy to create variants (easy mode, hard mode, etc.)
- Better version control (data files vs. scene files)
- Designer-friendly (edit .tres in Inspector)

## Examples

See the following example configurations:
- `data/game_scenes/default_game_scene.tres` - Minimal example
- `data/game_scenes/example_scene_with_entities.tres` - Full example with entities

## Troubleshooting

### Entity Not Spawning
1. Check `scene_path` is correct
2. Verify entity scene exists
3. Check console for error messages
4. Ensure `entity_resource` is compatible with scene

### Player Position Wrong
1. Check if loading from save (uses saved position)
2. Verify `player_spawn.spawn_position` in GameSceneData
3. Check `MapData.default_spawn_position` as fallback

### Map Not Loading
1. Verify `map_data.map_id` is unique
2. Check `chunk_scenes` dictionary format
3. Ensure map chunks exist at specified paths

### Save/Load Issues
1. Entities must implement `save_data()/load_data()` methods
2. Check `spawn_id` is unique for each entity
3. Verify SaveManager integration

## Future Enhancements

Potential improvements:
- [ ] Scene presets (easy/medium/hard)
- [ ] Random entity placement within zones
- [ ] Entity spawn conditions (time, quest state)
- [ ] Wave-based spawning
- [ ] Dynamic entity culling for performance
- [ ] Visual scene editor tool
