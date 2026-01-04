# ECA System Usage Example

This example demonstrates how to create a prologue scene with event-driven logic using the ECA system.

## Scenario: Prologue Scene 02
A scene where:
1. Show a welcome message when scene starts
2. Spawn an enemy at a specific location
3. Have a locked door that requires a key item
4. Show a tutorial message when player finds a key

## Step-by-Step Implementation

### Step 1: Prepare the Scene

Create a scene with:
- A Node2D named "EnemySpawn1" (marker for enemy spawn)
- An Area2D named "LabDoor" (for door interaction)
- An Area2D named "KeyArea" (triggers when player finds key)

### Step 2: Create Action Resources

#### Action 1: Welcome Dialog
In Godot Inspector:
1. Create new Resource → ActionShowDialog
2. Save as `data/events/prologue/action_welcome_dialog.tres`
3. Set properties:
   ```
   speaker_name: "System"
   dialog_text: "Welcome to the Biological Research Laboratory. Your journey begins here..."
   ```

#### Action 2: Spawn Enemy
1. Create new Resource → ActionSpawnActor
2. Save as `data/events/prologue/action_spawn_slime.tres`
3. Set properties:
   ```
   actor_data: [load] res://data/actors/enemies/slime_data.tres
   marker_id: "EnemySpawn1"
   custom_scene_path: "" (leave empty for default)
   ```

#### Action 3: Door Unlock Message
1. Create new Resource → ActionShowDialog
2. Save as `data/events/prologue/action_door_unlock.tres`
3. Set properties:
   ```
   speaker_name: "System"
   dialog_text: "The laboratory door opens with a click..."
   ```

#### Action 4: Tutorial Message
1. Create new Resource → ActionShowDialog
2. Save as `data/events/prologue/action_tutorial.tres`
3. Set properties:
   ```
   speaker_name: "Tutorial"
   dialog_text: "You found a key! Items can be used to unlock new areas."
   ```

### Step 3: Create Condition Resources

#### Condition 1: Has Lab Key
1. Create new Resource → ConditionHasItem
2. Save as `data/events/prologue/condition_has_lab_key.tres`
3. Set properties:
   ```
   item_id: "Lab Key"
   required_count: 1
   ```

### Step 4: Create Event Resources

#### Event 1: Intro Sequence (on_start)
1. Create new Resource → GameEventData
2. Save as `data/events/prologue/event_intro.tres`
3. Set properties:
   ```
   event_id: "prologue_intro"
   conditions: [] (empty array - always execute)
   actions: [
     [load] res://data/events/prologue/action_welcome_dialog.tres
   ]
   ```

#### Event 2: Spawn Initial Enemy (on_start)
1. Create new Resource → GameEventData
2. Save as `data/events/prologue/event_spawn_enemy.tres`
3. Set properties:
   ```
   event_id: "spawn_initial_slime"
   conditions: [] (empty)
   actions: [
     [load] res://data/events/prologue/action_spawn_slime.tres
   ]
   ```

#### Event 3: Door Unlock (interaction)
1. Create new Resource → GameEventData
2. Save as `data/events/prologue/event_door_unlock.tres`
3. Set properties:
   ```
   event_id: "lab_door_unlock"
   conditions: [
     [load] res://data/events/prologue/condition_has_lab_key.tres
   ]
   actions: [
     [load] res://data/events/prologue/action_door_unlock.tres
   ]
   ```

#### Event 4: Key Tutorial (interaction)
1. Create new Resource → GameEventData
2. Save as `data/events/prologue/event_key_tutorial.tres`
3. Set properties:
   ```
   event_id: "key_found_tutorial"
   conditions: [] (empty)
   actions: [
     [load] res://data/events/prologue/action_tutorial.tres
   ]
   ```

### Step 5: Configure GameSceneData

1. Create or edit GameSceneData resource
2. Save as `data/game_scenes/prologue_scene_02.tres`
3. Set properties:
   ```
   scene_id: "prologue_02"
   scene_name: "Laboratory Entrance"
   
   map_data: [load] res://data/maps/lab_map.tres
   player_spawn: [your spawn data]
   
   on_start_events: [
     [load] res://data/events/prologue/event_intro.tres,
     [load] res://data/events/prologue/event_spawn_enemy.tres
   ]
   
   interaction_events: {
     "LabDoor": [load] res://data/events/prologue/event_door_unlock.tres,
     "KeyArea": [load] res://data/events/prologue/event_key_tutorial.tres
   }
   ```

### Step 6: Create the Scene

1. Create a new scene: `scenes/prologue_scene_02.tscn`
2. Root node: Node2D (or use game_scene.tscn as base)
3. Attach script: `res://scenes/game_scene.gd`
4. Set game_scene_data to your resource

Scene hierarchy:
```
PrologueScene02 (Node2D)
├─ MapContainer (created automatically)
├─ EnemySpawn1 (Node2D) ← marker for enemy spawn
├─ LabDoor (Area2D) ← door interaction trigger
│  └─ CollisionShape2D
└─ KeyArea (Area2D) ← key found trigger
   └─ CollisionShape2D
```

## Execution Flow

### When Scene Loads:
```
1. GameScene._ready() executes
2. _setup_scene() runs:
   - Loads map
   - Spawns entities
   - Executes on_start_events:
     a. event_intro.try_execute()
        → Shows welcome message
     b. event_spawn_enemy.try_execute()
        → Spawns slime at EnemySpawn1
   - Binds triggers:
     a. Finds "LabDoor" Area2D
     b. Connects body_entered to event_door_unlock
     c. Finds "KeyArea" Area2D
     d. Connects body_entered to event_key_tutorial
```

### When Player Enters KeyArea:
```
1. Player body enters KeyArea
2. body_entered signal fires
3. _on_trigger_area_entered() called
4. Checks if body is player (✓)
5. event_key_tutorial.try_execute():
   - No conditions to check
   - Executes action_tutorial
   - Shows tutorial message
```

### When Player Enters LabDoor:
```
1. Player body enters LabDoor
2. body_entered signal fires
3. _on_trigger_area_entered() called
4. Checks if body is player (✓)
5. event_door_unlock.try_execute():
   - Checks condition_has_lab_key
     a. Searches player inventory
     b. If "Lab Key" found → condition passes ✓
     c. If not found → condition fails ✗
   - If condition passed:
     - Executes action_door_unlock
     - Shows unlock message
   - If condition failed:
     - Nothing happens
```

## Testing the Implementation

### In Godot Editor:
1. Open `scenes/prologue_scene_02.tscn`
2. Press F5 to run the scene
3. Observe console output:
   ```
   GameScene: Setting up scene 'Laboratory Entrance'
   GameScene: Executing 2 on_start events
   ActionShowDialog: Showing dialog from 'System': Welcome to the...
   ActionSpawnActor: Spawned actor at marker 'EnemySpawn1'
   GameScene: Binding 2 interaction triggers
   GameScene: Bound trigger 'LabDoor' to event 'lab_door_unlock'
   GameScene: Bound trigger 'KeyArea' to event 'key_found_tutorial'
   ```

### Test Interactions:
1. Move player to KeyArea
   - Should see tutorial message
2. Move player to LabDoor without key
   - Nothing happens (condition fails silently)
3. Give player Lab Key (via debug command or game logic)
4. Move player to LabDoor with key
   - Should see unlock message

## Extending the Example

### Add More Actions:
```gdscript
# After showing unlock message, also:
- ActionPlaySound (unlock sound)
- ActionOpenDoor (custom action to open door animation)
- ActionGiveItem (give player a reward)
```

### Add More Conditions:
```gdscript
# Door requires multiple items:
conditions: [
  ConditionHasItem("Lab Key", 1),
  ConditionHasItem("Access Card", 1)
]
```

### Chain Events:
```gdscript
# After unlocking door, spawn boss:
Event: door_unlock
  actions: [
    ActionShowDialog("The door opens..."),
    ActionSpawnActor(boss_data, "BossSpawnPoint")
  ]
```

## Advanced Patterns

### Pattern 1: Multi-Stage Quest
```
KeyArea triggers:
  Event A: Give key item + Show "Part 1 complete"
  
LabDoor triggers (requires key):
  Event B: Unlock door + Spawn next area enemies
```

### Pattern 2: Tutorial Sequence
```
on_start_events: [
  Event 1: Welcome message (immediate),
  Event 2: Spawn tutorial enemy (immediate),
  Event 3: Wait for combat (handled by game logic)
]

interaction_events: {
  "TutorialArea1": Tutorial about movement,
  "TutorialArea2": Tutorial about combat,
  "TutorialArea3": Tutorial about items
}
```

### Pattern 3: Branching Story
```
Condition A: Player has "Good Karma"
  → Show positive outcome dialog
  → Spawn friendly NPCs

Condition B: Player has "Bad Karma"
  → Show negative outcome dialog
  → Spawn hostile NPCs
```

## File Structure Summary
```
data/
  events/
    prologue/
      action_welcome_dialog.tres
      action_spawn_slime.tres
      action_door_unlock.tres
      action_tutorial.tres
      condition_has_lab_key.tres
      event_intro.tres
      event_spawn_enemy.tres
      event_door_unlock.tres
      event_key_tutorial.tres
  game_scenes/
    prologue_scene_02.tres

scenes/
  prologue_scene_02.tscn
```

## Conclusion

This example demonstrates:
- ✅ Data-driven scene logic
- ✅ No hardcoded scripts needed
- ✅ Easy to modify in Inspector
- ✅ Composable conditions and actions
- ✅ Clear event flow and debugging

All logic is configured through Resources, making it easy for designers to create and modify content without touching code!
