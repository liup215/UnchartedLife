# Game Scene Loading System - Migration Guide

## What Changed?

The game loading system has been redesigned to be data-driven. Instead of hardcoding entities in scene files, we now configure scenes using data resources.

## Quick Start

### Before (Old System)
```gdscript
# main.tscn had hardcoded player, UI elements
[node name="Player" instance=ExtResource("player.tscn")]
position = Vector2(631, 356)
actor_data = ExtResource("player_data.tres")
```

### After (New System)
```gdscript
# main.tscn now loads a generic game scene with data
[node name="GameScene" instance=ExtResource("game_scene.tscn")]
game_scene_data = ExtResource("default_game_scene.tres")
```

All entity placement and configuration is now in `GameSceneData` resources!

## Key Benefits

1. **No Code Changes for Level Design**: Create new levels by creating `.tres` files
2. **Reusable Entities**: Define entity data once, spawn multiple times
3. **Better Version Control**: Data files are easier to merge than scene files
4. **Designer-Friendly**: Configure everything in the Inspector
5. **Dynamic Content**: Easy to add enemies, NPCs, vehicles at runtime

## File Structure

```
scenes/
  ├── game_scene.tscn        # Generic container scene
  └── game_scene.gd          # Controller script

data/
  ├── game_scenes/           # Scene configuration files
  │   ├── default_game_scene.tres
  │   └── example_scene_with_entities.tres
  └── definitions/system/
      ├── game_scene_data.gd       # Main scene config
      ├── spawnable_entity_data.gd # Entity spawn config
      └── player_spawn_data.gd     # Player spawn config
```

## Creating Your First Scene

### Step 1: Create a GameSceneData Resource

In Godot Editor:
1. Right-click `data/game_scenes/` folder
2. Select "New Resource"
3. Search for "GameSceneData"
4. Save as `my_level.tres`

### Step 2: Configure the Scene

In the Inspector:
- **Scene ID**: `my_level`
- **Scene Name**: `My First Level`
- **Map Data**: Create or select a MapData
- **Player Spawn**: Set spawn position

### Step 3: Add Entities

Click "Spawnable Entities" → "Add Element":

**For an Enemy:**
- Entity Type: `enemy`
- Scene Path: `res://features/actor/base_actor.tscn`
- Spawn Position: `Vector2(1000, 500)`
- Entity Resource: Select enemy data (e.g., `goblin_data.tres`)
- Spawn ID: `enemy_1`

**For a Vehicle:**
- Entity Type: `vehicle`
- Scene Path: `res://features/vehicle/base_vehicle.tscn`
- Spawn Position: `Vector2(800, 400)`
- Entity Resource: Select vehicle data (e.g., `basic_tank_data.tres`)
- Spawn ID: `tank_1`

### Step 4: Use Your Scene

Edit `main.tscn`:
```gdscript
[node name="GameScene" instance=ExtResource("game_scene.tscn")]
game_scene_data = ExtResource("res://data/game_scenes/my_level.tres")
```

## Examples

See these example files:
- `data/game_scenes/default_game_scene.tres` - Minimal setup
- `data/game_scenes/example_scene_with_entities.tres` - With enemies and vehicles

## Full Documentation

For complete documentation, see:
- `docs/GAME_SCENE_SYSTEM.md` - English
- `docs/GAME_SCENE_SYSTEM_CN.md` - 中文

## Common Questions

### Q: What about existing maps?
**A:** They still work! The system uses the existing MapManager for chunk loading.

### Q: Can I still manually place entities in scenes?
**A:** Yes, but it's recommended to use GameSceneData for consistency.

### Q: Does this break save/load?
**A:** No, it's fully integrated with SaveManager.

### Q: How do I spawn NPCs with dialogue?
**A:** Use `additional_config`:
```gdscript
additional_config = {
    "dialogue_id": "merchant_intro"
}
```

### Q: Can I spawn entities at runtime?
**A:** Yes! Access GameScene and call:
```gdscript
var game_scene = get_node("/root/Main/GameScene")
var entity = game_scene.get_entity("enemy_1")
```

## Support

If you encounter issues:
1. Check console for error messages
2. Verify scene paths are correct
3. Ensure entity resources are compatible
4. See troubleshooting in `docs/GAME_SCENE_SYSTEM.md`
