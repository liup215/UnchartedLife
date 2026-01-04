# ECA System Quick Reference Card

## What is the ECA System?
A Resource-based Event-Condition-Action system that decouples game logic from scripts. Configure level behaviors in the Godot Inspector without writing code.

## Core Concept
```
IF (all conditions are met) THEN (execute all actions)
```

## Quick Setup (3 Steps)

### 1. Create Resources in Inspector

#### For Scene Start Events:
```
GameSceneData
  └─ on_start_events: Array[GameEventData]
      └─ GameEventData
          ├─ event_id: "welcome_message"
          ├─ conditions: [] (empty = always execute)
          └─ actions: [ActionShowDialog]
```

#### For Interaction Events:
```
GameSceneData
  └─ interaction_events: Dictionary
      └─ "DoorArea" : GameEventData
          ├─ conditions: [ConditionHasItem("Key", 1)]
          └─ actions: [ActionShowDialog("Door unlocked!")]
```

### 2. Add Area2D to Scene (for interactions)
- Add Area2D node to your scene
- Name it (e.g., "DoorArea")
- Set up collision shape
- Use same name in interaction_events Dictionary

### 3. Scene Auto-Executes
- `on_start_events` run automatically when scene loads
- `interaction_events` trigger when player enters Area2D

## Built-in Components

### Actions (What Happens)

#### ActionShowDialog
```gdscript
speaker_name: String = "NPC"
dialog_text: String = "Hello, adventurer!"
portrait: Texture2D = null (optional)
```
→ Uses DialogueManager to display message through dialogue UI

#### ActionSpawnActor
```gdscript
actor_data: ActorData = slime_data.tres
marker_id: String = "SpawnPoint1"
custom_scene_path: String = "" (optional)
```
→ Spawns actor at marker location

### Conditions (When It Happens)

#### ConditionHasItem
```gdscript
item_id: String = "Lab Key"
required_count: int = 1
```
→ Checks player inventory across all containers

## Creating Custom Components

### Custom Action Template
```gdscript
# systems/eca/actions/action_my_custom.gd
extends GameAction
class_name ActionMyCustom

@export var my_property: String = ""

func execute(context: Node) -> void:
    # Your logic here
    print("Executing: ", my_property)
    EventBus.some_signal.emit()
```

### Custom Condition Template
```gdscript
# systems/eca/conditions/condition_my_custom.gd
extends GameCondition
class_name ConditionMyCustom

@export var threshold: float = 50.0

func is_met(context: Node) -> bool:
    var player = context.get_tree().get_nodes_in_group("player")[0]
    return player.health > threshold
```

## Common Patterns

### Pattern 1: Unconditional Scene Intro
```
GameEventData:
  conditions: [] (empty)
  actions: [ActionShowDialog]
```

### Pattern 2: Quest Item Check
```
GameEventData:
  conditions: [ConditionHasItem("Quest Item", 1)]
  actions: [ActionShowDialog, ActionSpawnActor]
```

### Pattern 3: Multiple Requirements
```
GameEventData:
  conditions: [
    ConditionHasItem("Key A", 1),
    ConditionHasItem("Key B", 1)
  ]
  actions: [ActionShowDialog("Both keys found!")]
```
→ ALL conditions must be met

## Execution Flow

### On Scene Start
```
GameScene._ready()
  → _setup_scene()
    → _execute_on_start_events()
      → For each event:
          event.try_execute(self)
            → Check all conditions
            → If all pass: execute all actions
```

### On Player Interaction
```
Player enters Area2D
  → body_entered signal
    → _on_trigger_area_entered()
      → Check if body is player
      → event.try_execute(self)
```

## Accessing Game Systems

### From Actions
```gdscript
# EventBus
EventBus.dialogue_event.emit("show", payload)
EventBus.quest_started.emit(quest_id)

# Scene Tree
var player = context.get_tree().get_nodes_in_group("player")[0]
var nodes = context.get_children()

# Spawning
var instance = scene.instantiate()
context.add_child(instance)
```

### From Conditions
```gdscript
# Get Player
var player = context.get_tree().get_nodes_in_group("player")[0]

# Check Inventory
var inventory = player.inventory_component
var containers = inventory.get_all_containers()

# Check Attributes
var health = player.attribute_component.current_health
```

## Testing
Run test suite: Open `tests/test_eca_system.tscn` and press F5

## Debugging Tips

1. **Check Console Output**
   - Actions print execution messages
   - Conditions print check results

2. **Verify event_id**
   - Set descriptive event_id for easier tracking

3. **Test Conditions Separately**
   - Create test events with single conditions

4. **Check Area2D Names**
   - Must exactly match interaction_events keys

5. **Verify Player Group**
   - Player must be in "player" group for triggers

## File Locations
- Base Classes: `systems/eca/`
- Actions: `systems/eca/actions/`
- Conditions: `systems/eca/conditions/`
- Tests: `tests/test_eca_system.*`
- Docs: `docs/eca_system.md`

## Key Methods

### GameEventData
```gdscript
try_execute(context: Node) -> bool
  # Returns true if all conditions met and actions executed
```

### GameAction (Base)
```gdscript
execute(context: Node) -> void
  # Override in subclass
```

### GameCondition (Base)
```gdscript
is_met(context: Node) -> bool
  # Override in subclass
```

## Integration Points
- **EventBus**: Signal-based communication
- **InventoryComponent**: Item checking
- **ActorData**: Actor spawning
- **Scene Tree**: Node access and manipulation

## Next Steps
1. Read full documentation: `docs/eca_system.md`
2. Review implementation: `docs/eca_implementation_summary.md`
3. Run tests: `tests/test_eca_system.tscn`
4. Create custom actions/conditions as needed

---
*ECA System v1.0 - Data-Driven Event Logic for Godot 4*
