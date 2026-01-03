# Scene Transition System

## Overview

The Scene Transition System provides a data-driven approach to managing scene sequences, level transitions, and tutorials in the game. All transitions are configured through resource files, making it easy to create and modify game flow without changing code.

## Architecture

### Core Components

1. **SceneTransitionData** - Defines a single scene transition
2. **SceneSequenceData** - Defines a sequence of transitions
3. **MainGameManager** - Executes sequences based on data

### Data-Driven Flow

```
Resource Files (.tres) → MainGameManager → Scene Loading → Signal Handling → Next Scene
```

## Usage

### Creating a Scene Transition

Create a new `SceneTransitionData` resource:

```gdscript
# In Godot Editor:
# 1. Create New > Resource
# 2. Search for "SceneTransitionData"
# 3. Configure properties in Inspector
```

**Properties:**
- `scene_path`: Path to .tscn file to load
- `scene_id`: Unique identifier
- `scene_name`: Display name
- `loading_image`: Texture for loading screen
- `loading_text`: Text to show on loading screen
- `completion_signal`: Signal name to listen for (e.g., "tutorial_completed")
- `required_condition`: PlayerData property that must be true to load
- `is_overlay`: Whether scene is an overlay (true) or replaces content (false)
- `disable_system_menu`: Disable ESC menu during this scene
- `loading_screen_delay`: How long to show loading screen (seconds)
- `completion_flag`: PlayerData property to set to true when complete

### Creating a Scene Sequence

Create a new `SceneSequenceData` resource:

```gdscript
# In Godot Editor:
# 1. Create New > Resource
# 2. Search for "SceneSequenceData"
# 3. Add SceneTransitionData elements to transitions array
```

**Properties:**
- `sequence_id`: Unique identifier
- `sequence_name`: Display name
- `transitions`: Array of SceneTransitionData (ordered)
- `auto_start`: Should start automatically when conditions met
- `start_condition`: PlayerData property to check (e.g., "should_start_prologue")
- `on_completion`: What happens when sequence finishes
  - `CONTINUE_GAMEPLAY`: Return to normal gameplay
  - `LOAD_NEXT_SEQUENCE`: Load another sequence
  - `CUSTOM`: Custom handling (for future use)
- `next_sequence_id`: ID of next sequence (if using LOAD_NEXT_SEQUENCE)

### Configuring MainGameManager

Add sequences to main.tscn's MainGameManager:

```gdscript
# In main.tscn Inspector:
# Select Main node
# Find "active_sequences" property
# Add your SceneSequenceData resources
```

### Example: Prologue Sequence

See `data/sequences/prologue_sequence.tres` for a complete example.

```gdscript
# Prologue Sequence contains:
# 1. Microscope Tutorial (prologue_scene_01)
#    - Signals: tutorial_completed
#    - Sets: completed_microscope_tutorial
# 2. Glucose Tutorial (prologue_scene_02)
#    - Signals: prologue_completed
#    - Sets: completed_glucose_tutorial
# 3. On completion: Continue to gameplay
```

## Public API

### MainGameManager Methods

```gdscript
# Start a sequence programmatically
main_game_manager.start_sequence(sequence_data)

# Load sequence by ID
main_game_manager.load_sequence_by_id("prologue_sequence")

# Check if currently in a sequence
if main_game_manager.is_in_sequence():
    print("Sequence running")

# Check if system menu should be disabled
if main_game_manager.should_disable_system_menu():
    print("Menu disabled")
```

## Scene Requirements

### Completion Signals

Scenes in a transition must emit the specified signal when complete:

```gdscript
# In your scene script:
signal tutorial_completed  # Must match completion_signal in data

func _on_continue_pressed():
    tutorial_completed.emit()
    queue_free()  # Remove self
```

### Standard Signals

Common signal names:
- `tutorial_completed` - For tutorial scenes
- `level_completed` - For levels
- `dialogue_completed` - For dialogue sequences
- `cutscene_completed` - For cutscenes

## Integration with PlayerData

### Condition Checking

Sequences check PlayerData properties to decide if they should run:

```gdscript
# In PlayerData:
var should_start_prologue: bool = false
var completed_microscope_tutorial: bool = false

# In sequence data:
start_condition = "should_start_prologue"  # Checks PlayerData.should_start_prologue
```

### Completion Flags

When a transition completes, it can set PlayerData flags:

```gdscript
# In transition data:
completion_flag = "completed_microscope_tutorial"

# MainGameManager will execute:
PlayerData.completed_microscope_tutorial = true
```

## Advanced Usage

### Chained Sequences

Create multiple sequences that load each other:

```gdscript
# Sequence A:
on_completion = LOAD_NEXT_SEQUENCE
next_sequence_id = "sequence_b"

# Sequence B:
sequence_id = "sequence_b"
on_completion = CONTINUE_GAMEPLAY
```

### Conditional Loading

Use required_condition to skip transitions:

```gdscript
# Transition will only load if condition is met
required_condition = "has_special_item"

# MainGameManager checks:
if PlayerData.has_special_item:
    load_transition()
```

### Custom Loading Screens

Each transition can have unique loading screen content:

```gdscript
loading_image = preload("res://assets/tutorial_01.png")
loading_text = "Tutorial 1\n\nLearn the basics"
```

## Benefits

1. **No Code Changes**: Add new sequences without touching scripts
2. **Designer-Friendly**: Configure in Inspector
3. **Reusable**: Share transitions across sequences
4. **Flexible**: Support for conditions, chains, overlays
5. **Maintainable**: All flow logic in data files
6. **Testable**: Easy to test individual sequences

## Migration from Old System

### Before (Hardcoded):

```gdscript
func _start_prologue():
    var scene = load("res://prologue_01.tscn").instantiate()
    add_child(scene)
    scene.tutorial_completed.connect(_on_tutorial_done)
```

### After (Data-Driven):

```gdscript
# Just add prologue_sequence.tres to active_sequences in Inspector
# MainGameManager handles everything automatically
```

## Troubleshooting

**Q: Sequence doesn't start**
- Check start_condition is set correctly in PlayerData
- Verify auto_start is true or condition is true
- Check sequence is in active_sequences array

**Q: Scene doesn't advance**
- Verify completion_signal matches scene's signal name
- Check scene emits the signal
- Ensure scene calls queue_free() after signal

**Q: Loading screen doesn't show**
- Check loading_screen_delay is reasonable (>0.1)
- Verify loading_screen.tscn exists and works
- Check texture path is correct

**Q: Condition not working**
- Ensure property exists in PlayerData
- Check property name matches exactly (case-sensitive)
- Verify property is set to correct value

## Future Enhancements

- Save/load sequence progress
- Sequence branching (choose different paths)
- Parallel sequences (multiple at once)
- Transition animations/effects
- Progress tracking (X of Y complete)
