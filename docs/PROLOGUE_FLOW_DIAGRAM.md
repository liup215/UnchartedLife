# Prologue Game Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         MAIN MENU                               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  New Game                                                  │  │
│  │  Prologue (Tutorial)  ← Click this!                       │  │
│  │  Continue                                                  │  │
│  │  Load Game                                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                     PROLOGUE SCENE                              │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐   │
│  │  Objective: Collect GLUCOSE to refill ammo              │   │
│  │  Shoot the dying cell to heal it!                       │   │
│  │  Avoid other sugars - they hurt you!                    │   │
│  │                                                          │   │
│  │  Cell Health: 100 / 1000 (10.0%)                        │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                 │
│        [Player]                                                 │
│         ↓↑←→                                                    │
│         🔫                                                      │
│                                                                 │
│    🟢  🔵  🟣    [Dying Cell]     🟡  🟠  🔴                  │
│        (glucose) (others)   💔         (others)               │
│                             ↓HP                                 │
│    🟢  🟠  🟡              ❤️                  🔵  🟣  🟢     │
│                                                                 │
│  30 molecules spawned randomly                                  │
│  - 12 green (glucose) ✓                                        │
│  - 18 colored (other sugars) ✗                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      GAMEPLAY LOOP                              │
│                                                                 │
│  1. Player touches GREEN molecule (glucose)                     │
│     → Ammo +5                                                   │
│     → "✓ GLUCOSE collected! Ammo refilled!"                    │
│                                                                 │
│  2. Player touches COLORED molecule (other sugar)               │
│     → Player HP -10                                             │
│     → "✗ Wrong! [Name] is not glucose! (-10 HP)"              │
│                                                                 │
│  3. Player shoots cell                                          │
│     → Cell HP +[weapon damage]                                  │
│     → Cell flashes green                                        │
│                                                                 │
│  4. Cell continuously loses HP                                  │
│     → -1 HP per second                                          │
│     → Pulses faster when low                                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                        Game Ends When
                              ↓
        ┌────────────────────┴────────────────────┐
        ↓                                          ↓
┌─────────────────┐                    ┌─────────────────┐
│    VICTORY! ✅   │                    │  GAME OVER ❌   │
│                 │                    │                 │
│ Cell HP ≥ 500   │                    │ Player HP = 0   │
│ You healed the  │                    │ OR              │
│ cell!           │                    │ Cell HP = 0     │
│                 │                    │                 │
│ [Restart]       │                    │ [Restart]       │
│ [Main Menu]     │                    │ [Main Menu]     │
└─────────────────┘                    └─────────────────┘
```

## Game Mechanics Details

### Molecule Collection
```
Player → Touches Molecule
           ↓
    Is it Glucose?
     ↙        ↘
   YES        NO
    ↓          ↓
  Refill     Damage
  Ammo +5    HP -10
    ↓          ↓
  Green      Red
  Feedback   Feedback
```

### Cell Healing
```
Time Passes → Cell HP -1/sec
               ↓
          Cell Pulses
               ↓
          HP Bar Updates
               
Player Shoots Cell
    ↓
Bullet Hits
    ↓
Cell.take_damage() called
    ↓
Actually HEALS cell!
    ↓
Cell HP +[damage]
    ↓
Flash Green Effect
```

### Win/Lose Conditions
```
┌──────────────────────────────────────┐
│ Game State Checking (Every Frame)   │
├──────────────────────────────────────┤
│                                      │
│  Cell HP ≥ 500? → VICTORY           │
│                                      │
│  Cell HP = 0?   → DEFEAT            │
│                                      │
│  Player HP = 0? → DEFEAT            │
│                                      │
└──────────────────────────────────────┘
```

## Technical Architecture

### Component Hierarchy
```
PrologueGame (Node2D)
├── Camera2D
├── Background (ColorRect)
├── SpawnContainer (Node2D)
│   ├── Molecule (x30)
│   │   ├── Sprite2D
│   │   ├── Area2D
│   │   │   └── CollisionShape2D
│   │   └── Label
├── TargetCell (CharacterBody2D)
│   ├── Sprite2D
│   ├── CollisionShape2D
│   ├── HealthBar
│   └── Label
├── Player (Actor)
│   └── [All player components]
└── UI (CanvasLayer)
    └── PrologueUI (Control)
        ├── VBoxContainer
        │   ├── ObjectiveLabel
        │   └── CellHealthLabel
        ├── FeedbackLabel
        └── GameOverPanel
            ├── MessageLabel
            ├── RestartButton
            └── MenuButton
```

### Signal Flow
```
Molecule Collected
    ↓
EventBus.molecule_collected.emit(type, is_glucose)
    ↓
PrologueGame._on_molecule_collected()
    ↓
UI.on_molecule_collected()
    ↓
Display Feedback

Cell Health Changed
    ↓
TargetCell.health_changed.emit(current, max, %)
    ↓
PrologueGame._on_cell_health_changed()
    ↓
UI.update_cell_health()
    ↓
Update UI Display
```

### Collision System
```
Layer 1: Environment
Layer 2: Player, Player Bullets (Area2D)
Layer 4: Enemies, Target Cell

Player Bullet (Area2D)
- collision_layer = 2
- collision_mask = 4
    ↓
Can detect bodies on layer 4
    ↓
Target Cell (CharacterBody2D)
- collision_layer = 4
    ↓
Gets hit by bullets!
```
