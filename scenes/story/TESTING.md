# Story System Testing Guide

## New Game Flow Testing

This document describes how to test the new story system with opening animation and prologue.

### Expected Flow

1. **Main Menu** → Click "New Game"
2. **New Game Settings** → Configure settings and click "Start"
3. **Opening Animation** → Shows game title with fade-in/fade-out animation
4. **Prologue Scene 01** → First playable scene with tutorial instructions
5. **Main Game** → Full game experience

### Testing Steps

#### 1. Test Opening Animation
- **Open Scene:** `scenes/story/opening/opening_animation.tscn`
- **Run Scene:** Press F6 in Godot Editor
- **Expected Behavior:**
  - Black background fades in
  - "Legends of Uncharted Life" title fades in
  - "A Journey Through Biology" subtitle fades in
  - Animation plays for ~8 seconds
  - Automatically transitions to prologue
  - Skip button appears in bottom-right corner
  - Pressing "Skip" or ESC key skips to prologue immediately

#### 2. Test Prologue Scene
- **Open Scene:** `scenes/story/prologue/prologue_scene_01.tscn`
- **Run Scene:** Press F6 in Godot Editor
- **Expected Behavior:**
  - Player spawns at SpawnPoint (200, 200)
  - Camera follows player smoothly
  - Green ground visible
  - Welcome message displayed at top
  - Instructions displayed below title
  - HUD displays player stats
  - Player can move with WASD
  - Green exit area visible at position (800, 400)
  - Entering exit area transitions to main game

#### 3. Test Full New Game Flow
- **Open Scene:** `ui/main_menu/main_menu.tscn`
- **Run Scene:** Press F6 in Godot Editor
- **Steps:**
  1. Click "New Game" button
  2. Configure difficulty and seed (optional)
  3. Click "Start Game"
  4. Watch opening animation (or skip it)
  5. Play through prologue scene
  6. Enter green exit area to continue to main game
- **Expected Result:** Smooth transitions between all scenes

#### 4. Test Save/Load Compatibility
- **Test Continue Game:**
  1. Complete a new game flow and play for a bit
  2. Save the game
  3. Return to main menu
  4. Click "Continue" or "Load Game"
  5. Should load directly into main.tscn (bypassing story scenes)
- **Expected Result:** Save/load works normally, story scenes only for new games

### Manual Verification Checklist

- [ ] Opening animation plays with proper timing
- [ ] Skip button works correctly
- [ ] ESC key skips animation
- [ ] Prologue scene loads after animation
- [ ] Player spawns at correct position
- [ ] Camera follows player
- [ ] Movement controls work (WASD)
- [ ] HUD displays correctly
- [ ] Exit area triggers transition to main game
- [ ] Continue/Load game bypasses story scenes
- [ ] No console errors during transitions

### Known Issues / Future Enhancements

1. **Opening Animation Placeholder:**
   - Currently uses simple text fade-in/fade-out
   - Future: Replace with actual CG artwork or video

2. **Prologue Content:**
   - Currently minimal environment with basic instructions
   - Future: Add NPCs, dialogue, tutorial interactions

3. **Chapter System:**
   - Directory structure created but not implemented
   - Future: Add multiple chapter scenes with save points

### Debugging Tips

If transitions don't work:
1. Check SceneManager autoload is configured
2. Verify scene paths in scripts match actual file locations
3. Check console for error messages
4. Ensure all resource UIDs are unique

If player doesn't spawn correctly:
1. Verify SpawnPoint exists in prologue scene
2. Check player.tscn and player_data.tres are valid
3. Ensure player ActorData resource is properly configured

### Integration with Existing Systems

The story system integrates with:
- **SceneManager:** For scene transitions
- **EventBus:** Emits `story_scene_entered` signal
- **SaveManager:** Story progress tracked separately from normal saves
- **DialogueManager:** Can be used in prologue/chapter scenes
- **QuestManager:** Story quests can trigger in specific scenes

### Files Modified/Created

**New Files:**
- `scenes/story/README.md` - Story system documentation
- `scenes/story/opening/opening_animation.gd` - Opening script
- `scenes/story/opening/opening_animation.tscn` - Opening scene
- `scenes/story/prologue/prologue_scene_01.gd` - Prologue script
- `scenes/story/prologue/prologue_scene_01.tscn` - Prologue scene

**Modified Files:**
- `ui/main_menu/main_menu.gd` - Updated new game flow to use opening animation
- `systems/event_bus.gd` - Added story system signals

**New Directories:**
- `scenes/story/opening/` - Opening animations and cutscenes
- `scenes/story/prologue/` - Prologue chapter scenes
- `scenes/story/chapters/` - Future chapter scenes
- `data/story/` - Story-related data resources
