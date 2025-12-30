# Story System Flow Diagram

## New Game Flow

```
┌─────────────────────┐
│   Main Menu         │
│  (main_menu.tscn)   │
└──────────┬──────────┘
           │ Click "New Game"
           ▼
┌─────────────────────┐
│ New Game Settings   │
│(new_game_settings)  │
└──────────┬──────────┘
           │ Configure & Start
           ▼
┌─────────────────────┐
│ Opening Animation   │◄─── NEW! Can skip with button or ESC
│(opening_animation)  │
└──────────┬──────────┘
           │ 8 seconds or skip
           ▼
┌─────────────────────┐
│ Prologue Scene 01   │◄─── NEW! First playable scene
│(prologue_scene_01)  │
└──────────┬──────────┘
           │ Enter exit area
           ▼
┌─────────────────────┐
│   Main Game         │
│   (main.tscn)       │
└─────────────────────┘
```

## Continue/Load Game Flow

```
┌─────────────────────┐
│   Main Menu         │
│  (main_menu.tscn)   │
└──────────┬──────────┘
           │ Click "Continue" or "Load Game"
           │ (bypasses story scenes)
           ▼
┌─────────────────────┐
│   Main Game         │
│   (main.tscn)       │
└─────────────────────┘
```

## Directory Structure

```
scenes/
├── story/                          ◄─── NEW!
│   ├── README.md                   # Documentation
│   ├── TESTING.md                  # Testing guide
│   ├── opening/
│   │   ├── opening_animation.gd
│   │   └── opening_animation.tscn  # 8-second fade animation
│   ├── prologue/
│   │   ├── prologue_scene_01.gd
│   │   └── prologue_scene_01.tscn  # First playable scene
│   └── chapters/                   # For future chapters
│       ├── chapter_01/
│       ├── chapter_02/
│       └── ...
├── main.tscn
└── ...

data/
├── story/                          ◄─── NEW!
│   └── (story data resources)
└── ...
```

## Key Components

### Opening Animation (opening_animation.gd)
- **Purpose:** Show game title and intro
- **Duration:** 8 seconds (configurable)
- **Features:**
  - Fade-in/fade-out animations
  - Skip button (bottom-right)
  - ESC key to skip
  - Auto-transition to prologue
- **Transitions to:** `prologue_scene_01.tscn`

### Prologue Scene 01 (prologue_scene_01.gd)
- **Purpose:** First playable scene, tutorial area
- **Features:**
  - Player spawn at (200, 200)
  - Camera follows player
  - Welcome message and instructions
  - Green exit area at (800, 400)
  - Emits story events via EventBus
- **Transitions to:** `main.tscn` (for now)

### Modified Files

#### ui/main_menu/main_menu.gd
```gdscript
# Before:
get_tree().change_scene_to_file("res://scenes/main.tscn")

# After:
get_tree().change_scene_to_file("res://scenes/story/opening/opening_animation.tscn")
```

#### systems/event_bus.gd
```gdscript
# Added new signals:
signal story_scene_entered(scene_id: String)
signal story_milestone_reached(milestone_id: String, data: Dictionary)
```

## Integration Points

### SceneManager
- All transitions use `SceneManager.SwitchToScene(path)`
- Consistent transition API

### EventBus
- Story events emitted: `story_scene_entered`
- Can be monitored for achievements, analytics, etc.

### SaveManager
- New games go through story scenes
- Loaded games bypass story scenes
- Story progress can be tracked separately

## Future Enhancements

1. **Opening Animation:**
   - Replace text with actual CG artwork
   - Add background music
   - Multiple animation sequences

2. **Prologue:**
   - Add NPCs with dialogue
   - Tutorial interactions
   - Quest triggers
   - Multiple connected scenes (prologue_scene_02, etc.)

3. **Chapters:**
   - Implement chapter system
   - Save points between chapters
   - Chapter-specific resources and data

4. **Story Tracking:**
   - Track completed story milestones
   - Unlock system for chapters
   - Replay functionality
