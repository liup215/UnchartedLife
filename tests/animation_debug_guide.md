# Animation System Debug Guide

## Overview
This guide helps debug animation-related issues in the game, particularly for Actor-based entities (Player, Enemies).

## Key Files
- `features/actor/actor.gd` - Base actor with animation logic
- `features/player/player.gd` - Player-specific movement and input
- `data/definitions/animation/animation_data.gd` - Animation data resource definition
- `data/actors/player/player_data.tres` - Player animation configurations

## Animation Flow

### Initialization (_ready)
1. `actor.gd._ready()` called
2. `_setup_animations()` creates SpriteFrames from AnimationData resources
3. Initial animation "idle_down" is played if available
4. AnimatedSprite2D is now in playing state

### Update (_physics_process)
1. Movement code sets `velocity`
2. `_update_animation()` called
3. Animation determined from velocity:
   - velocity = 0 → "idle_{direction}"
   - velocity > 0 → "walk_{direction}"
4. Animation played if name changes OR not currently playing

## Common Issues and Solutions

### Issue: Animation not playing on first movement
**Symptom**: Player position moves but animation stays on idle frame

**Possible Causes**:
1. AnimatedSprite2D.is_playing() = false
2. Animation name check preventing play
3. velocity not set before _update_animation() called

**Solution**: Ensure animation is played when velocity changes (FIX APPLIED in commit baf8215)

**Debug Steps**:
```gdscript
# Add to _update_animation() before play checks:
print("Velocity: ", velocity.length())
print("Current anim: ", visuals.animation)
print("Target anim: ", final_anim_name)
print("Is playing: ", visuals.is_playing())
```

### Issue: Animation stuttering or restarting
**Symptom**: Animation constantly restarts from frame 0

**Possible Causes**:
1. Animation play() called every frame even when unchanged
2. Animation name constantly changing

**Solution**: Ensure name comparison check is working

**Debug Steps**:
```gdscript
# Add to _update_animation():
if visuals.animation != final_anim_name:
    print("Animation changing: ", visuals.animation, " -> ", final_anim_name)
```

### Issue: Wrong animation playing
**Symptom**: Player moves but wrong direction animation plays

**Possible Causes**:
1. last_direction not updated correctly
2. Direction calculation wrong
3. Animation not defined in ActorData

**Debug Steps**:
```gdscript
# Add to _update_animation():
print("Direction: ", direction)
print("Last direction: ", last_direction)
print("Dir suffix: ", dir_suffix)
```

### Issue: Animation not defined
**Symptom**: Console error about missing animation

**Possible Causes**:
1. AnimationData not added to ActorData.animations array
2. Animation name mismatch

**Solution**: 
1. Check data/actors/{entity}/{entity}_data.tres
2. Ensure all 8 animations exist: walk_{up/down/left/right}, idle_{up/down/left/right}
3. Verify animation_name in AnimationData matches expected format

## Animation Check Conditions

### Before Fix (BUGGY)
```gdscript
if visuals.sprite_frames and 
   visuals.sprite_frames.has_animation(final_anim_name) and 
   visuals.animation != final_anim_name:
    visuals.play(final_anim_name)
```
Problem: Doesn't handle case where animation stopped

### After Fix (CORRECT)
```gdscript
if visuals.sprite_frames and 
   visuals.sprite_frames.has_animation(final_anim_name):
    if visuals.animation != final_anim_name or not visuals.is_playing():
        visuals.play(final_anim_name)
```
Plays animation if:
- Name is different, OR
- Animation is not playing

## Testing Checklist
- [ ] Player idle → move: animation starts immediately
- [ ] Player moving → stop: animation changes to idle
- [ ] Player moving → change direction: animation transitions correctly
- [ ] Enemy with AI behavior: animations work
- [ ] Multiple actors on screen: all animations work independently
- [ ] Load saved game: animations work after load

## Related Godot Concepts
- **AnimatedSprite2D**: Node that displays sprite animations
- **SpriteFrames**: Resource containing animation data
- **play(animation_name)**: Starts playing named animation
- **is_playing()**: Returns true if any animation is currently playing
- **animation**: Property containing current animation name

## Future Improvements
- Consider using AnimationTree for complex animation blending
- Add animation events/callbacks for gameplay triggers
- Implement animation speed scaling for sprint/slow effects
- Add animation priority system for combat animations
