# ECA System Documentation

## Overview
The Event-Condition-Action (ECA) system is a data-driven framework for defining game logic without hardcoding scripts. It allows level designers to configure events, conditions, and actions through Godot Resources in the Inspector.

## Architecture

### Core Classes

1. **GameAction** (`systems/eca/game_action.gd`)
   - Base class for all actions
   - Override `execute(context: Node)` to define behavior

2. **GameCondition** (`systems/eca/game_condition.gd`)
   - Base class for all conditions
   - Override `is_met(context: Node) -> bool` to check if condition is satisfied

3. **GameEventData** (`systems/eca/game_event_data.gd`)
   - Holds arrays of conditions and actions
   - `try_execute(context: Node)` runs actions only if ALL conditions are met

### Built-in Actions

#### ActionShowDialog
- **Location**: `systems/eca/actions/action_show_dialog.gd`
- **Properties**:
  - `speaker_name`: String - Name of the speaker
  - `dialog_text`: String - The text to display
- **Behavior**: Emits `EventBus.dialogue_event` signal with payload

#### ActionSpawnActor
- **Location**: `systems/eca/actions/action_spawn_actor.gd`
- **Properties**:
  - `actor_data`: ActorData - The actor resource to spawn
  - `marker_id`: String - Name of the marker Node2D where to spawn
  - `custom_scene_path`: String (optional) - Custom scene path if not using base_actor.tscn
- **Behavior**: Finds marker in scene and spawns actor at that position

### Built-in Conditions

#### ConditionHasItem
- **Location**: `systems/eca/conditions/condition_has_item.gd`
- **Properties**:
  - `item_id`: String - The item name to check for
  - `required_count`: int - Minimum number required
- **Behavior**: Checks player's inventory across all containers

## Integration with GameSceneData

### New Properties

```gdscript
# In GameSceneData resource:
@export var on_start_events: Array[GameEventData] = []
@export var interaction_events: Dictionary = {}
```

### on_start_events
Array of events that execute automatically when the scene loads, in order.

**Example Use Cases**:
- Show intro dialog
- Spawn initial enemies
- Check quest prerequisites
- Set up scene state based on player progress

### interaction_events
Dictionary mapping Area2D node names to GameEventData.
When player enters the Area2D, the associated event is triggered.

**Example Use Cases**:
- Door interactions (check for key item)
- NPC conversations
- Quest triggers
- Treasure chests

## GameScene Integration

The `GameScene` class automatically:
1. Executes `on_start_events` after scene setup
2. Finds Area2D nodes matching keys in `interaction_events`
3. Connects `body_entered` signals to trigger events when player enters

## Usage Examples

### Example 1: Show Dialog on Scene Start

Create a GameSceneData resource (e.g., `prologue_scene_02.tres`):

1. Create an ActionShowDialog resource:
   - speaker_name: "System"
   - dialog_text: "Welcome to the lab..."

2. Create a GameEventData resource:
   - event_id: "intro_dialog"
   - actions: [ActionShowDialog resource]

3. In GameSceneData:
   - on_start_events: [GameEventData resource]

### Example 2: Spawn Enemy at Marker

1. Create an ActorData resource for the enemy (e.g., `slime_data.tres`)

2. Add a Node2D marker in your scene named "EnemySpawn1"

3. Create an ActionSpawnActor resource:
   - actor_data: slime_data.tres
   - marker_id: "EnemySpawn1"

4. Create a GameEventData resource:
   - event_id: "spawn_initial_enemy"
   - actions: [ActionSpawnActor resource]

5. In GameSceneData:
   - on_start_events: [GameEventData resource]

### Example 3: Door with Key Requirement

1. Add an Area2D node in your scene named "LabDoor"

2. Create a ConditionHasItem resource:
   - item_id: "Lab Key"
   - required_count: 1

3. Create an ActionShowDialog resource:
   - speaker_name: "System"
   - dialog_text: "The door opens..."

4. Create a GameEventData resource:
   - event_id: "door_unlock"
   - conditions: [ConditionHasItem resource]
   - actions: [ActionShowDialog resource]

5. In GameSceneData:
   - interaction_events: {"LabDoor": GameEventData resource}

### Example 4: Multiple Actions with Conditions

Create a quest trigger that:
- Checks if player has completed a prerequisite
- Shows a dialog
- Spawns a boss enemy

1. Create ConditionHasItem for quest item

2. Create ActionShowDialog for quest start message

3. Create ActionSpawnActor for boss

4. Create GameEventData:
   - conditions: [ConditionHasItem]
   - actions: [ActionShowDialog, ActionSpawnActor]

5. Add to GameSceneData.interaction_events with an Area2D name

## Creating Custom Actions

```gdscript
# systems/eca/actions/action_custom.gd
extends GameAction
class_name ActionCustom

@export var custom_property: String = ""

func execute(context: Node) -> void:
    # Your custom logic here
    print("Custom action executed: ", custom_property)
    # Access game systems via EventBus or direct references
    EventBus.some_signal.emit()
```

## Creating Custom Conditions

```gdscript
# systems/eca/conditions/condition_custom.gd
extends GameCondition
class_name ConditionCustom

@export var threshold: float = 0.5

func is_met(context: Node) -> bool:
    # Your custom logic here
    var player = context.get_tree().get_nodes_in_group("player")[0]
    return player.some_property >= threshold
```

## Best Practices

1. **Keep Actions Small**: Each action should do one thing well
2. **Use EventBus**: Communicate with game systems through EventBus signals
3. **Descriptive event_id**: Use clear identifiers for debugging
4. **Test Conditions**: Always handle cases where conditions might fail
5. **Context Access**: Use the context node to access scene tree and game systems

## Testing

Run the test suite:
- Open `tests/test_eca_system.tscn` in Godot Editor
- Press F5 to run the test scene
- Check console output for test results

## Future Extensions

Possible additions to the ECA system:
- ActionPlayAnimation
- ActionPlaySound
- ConditionQuestComplete
- ConditionPlayerInArea
- ActionTeleportPlayer
- ActionGiveItem
- ConditionTimeOfDay
- ActionChangeMap
