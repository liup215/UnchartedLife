# Story Content Structure

This directory contains all story-related scenes for Legends of Uncharted Life, organized by narrative progression.

## Directory Organization

### `/opening/`
Contains the opening animation/cutscene that plays when starting a new game.
- `opening_animation.tscn` - Main opening scene with animations and CG
- `opening_animation.gd` - Controls playback and transitions to prologue

### `/prologue/`
Contains all scenes for the game's prologue chapter.
- `prologue_scene_01.tscn` - First playable scene after opening
- `prologue_scene_02.tscn` - Second scene in prologue
- ... (additional prologue scenes)

### `/chapters/`
Contains subdirectories for each main story chapter.
```
chapters/
├── chapter_01/
│   ├── scene_01.tscn
│   ├── scene_02.tscn
│   └── ...
├── chapter_02/
│   └── ...
└── ...
```

## Scene Naming Convention

- **Opening:** `opening_animation.tscn`
- **Prologue:** `prologue_scene_##.tscn` (numbered sequentially)
- **Chapters:** `chapter_##/scene_##.tscn` (double-digit numbering)

## Scene Flow

```
New Game → Opening Animation → Prologue Scene 01 → ... → Main Game Loop
```

## Creating New Story Content

### 1. Opening/Cutscene Scenes
- Inherit from base scene or create as Control/Node2D
- Include AnimationPlayer for sequencing
- Implement `_on_animation_finished()` to trigger next scene
- Use SceneManager.SwitchToScene() for transitions

### 2. Prologue Scenes
- Set up player spawn point
- Configure initial game state
- Include dialogue and tutorial elements
- Transition to next scene or main game when complete

### 3. Chapter Scenes
- Create subdirectory for each chapter
- Number scenes sequentially within chapter
- Follow data-driven patterns from copilot-instructions.md
- Use EventBus for cross-scene communication

## Data Resources

Story-related data resources should be placed in `/data/story/`:
- Dialogue data
- Quest data
- Story-specific actor data
- Cutscene configurations

## Integration with Game Systems

Story scenes should integrate with existing systems:
- **SaveManager:** Add story progress tracking
- **EventBus:** Emit story events for achievements/unlocks
- **DialogueManager:** Use for character interactions
- **QuestManager:** Trigger story quests

## Technical Guidelines

1. **Scene Transitions:** Always use `SceneManager.SwitchToScene()` for transitions
2. **State Management:** Save story progress through SaveManager
3. **Data-Driven:** Define story content in Resources, not hardcoded
4. **Static Typing:** Follow GDScript best practices from copilot-instructions.md
5. **Performance:** Consider chunk loading for large story areas
