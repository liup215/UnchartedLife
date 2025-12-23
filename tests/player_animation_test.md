# Player Animation Test Plan

## Issue
Player move 过程中，第一步只位置运动，运动动画没有播放
(During player movement, the first step only has position movement, movement animation is not playing)

## Fix Applied
Modified `features/actor/actor.gd._update_animation()` to check `visuals.is_playing()` in addition to animation name comparison. This ensures that even if the animation name matches but is not playing, it will be started.

## Manual Test Steps

### Test 1: First Movement from Idle
1. Load the game with a player character
2. Wait for player to be in idle state (idle_down animation playing)
3. Press a movement key (e.g., W for up, S for down, A for left, D for right)
4. **Expected**: Walk animation starts immediately on the first frame
5. **Verify**: Player position moves AND walk animation is visible

### Test 2: Direction Changes
1. Move player in one direction (e.g., down)
2. Quickly change to another direction (e.g., right)
3. **Expected**: Animation transitions smoothly (walk_down → walk_right)
4. **Verify**: No frame where the character moves without animation

### Test 3: Stop and Start Movement
1. Move player for a few seconds
2. Release all movement keys (character stops)
3. Wait for idle animation to play
4. Press movement key again
5. **Expected**: Walk animation plays immediately
6. **Verify**: No delay in animation starting

### Test 4: Sprinting
1. Move player while holding Shift
2. **Expected**: Walk animation plays at faster speed (or sprint animation if available)
3. **Verify**: Animation is always playing during movement

### Test 5: Multiple Direction Inputs
1. Press multiple direction keys simultaneously
2. **Expected**: Animation plays for the resulting direction
3. **Verify**: No stuttering or missing frames

### Test 6: AI Enemy Regression Check
1. Spawn an enemy with AI behavior
2. Let it move/patrol
3. **Expected**: Enemy animations work as before
4. **Verify**: No regression in AI character animations

## Expected Behavior After Fix
- Animation should play immediately when movement starts
- No frame where position changes but animation is idle
- Smooth transitions between idle and walking
- Smooth transitions between different walking directions
- No regression in existing animation behavior

## Debug Information to Check
If issues persist, add print statements to check:
```gdscript
print("Velocity: ", velocity)
print("Animation: ", visuals.animation)
print("Is Playing: ", visuals.is_playing())
print("Final Anim Name: ", final_anim_name)
```

## Related Files
- `features/actor/actor.gd` - Main animation logic
- `features/player/player.gd` - Player movement logic
- `data/actors/player/player_data.tres` - Player data with animations
