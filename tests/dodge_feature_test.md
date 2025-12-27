# Dodge Feature Testing Guide

## Overview
This document describes how to test the newly implemented player dodge feature.

## Feature Requirements (from Problem Statement)
- **Trigger**: Press SPACE key
- **Visual Effect**: Leave a light-colored afterimage at the original position
- **Movement**: Player moves a distance in the movement direction
- **Invincibility**: Short invincibility period where attacks don't reduce health
- **Cost**: Consumes significant ATP; cannot dodge when ATP is insufficient

## Implementation Details

### Components Modified/Created
1. **DodgeComponent** (`features/components/dodge_component.gd`)
   - Handles dodge mechanics, ATP consumption, invincibility
   - Creates afterimage effect
   - Manages cooldown system
   
2. **HealthComponent** (`features/components/attribute_component/health_component.gd`)
   - Added invincibility flag
   - Modified `take_damage()` to check invincibility
   
3. **Player** (`features/player/player.gd`)
   - Integrated DodgeComponent
   - Added dodge input handling
   - Connected dodge callbacks

4. **EventBus** (`systems/event_bus.gd`)
   - Added dodge-related signals

5. **Project Settings** (`project.godot`)
   - Added "dodge" input action mapped to SPACE key

### Dodge Parameters (Configurable in DodgeComponent)
- **dodge_distance**: 150.0 (pixels to move)
- **dodge_duration**: 0.3 (seconds for movement)
- **dodge_atp_cost**: 30.0 (ATP consumed per dodge)
- **invincibility_duration**: 0.4 (seconds of invincibility)
- **cooldown_duration**: 0.5 (seconds before next dodge)

## Testing Steps

### 1. Basic Dodge Functionality
1. Open the project in Godot Editor
2. Run the main scene
3. Press SPACE key
4. **Expected**: Player should move in the direction they're facing/moving
5. **Expected**: Light-colored afterimage should appear at the starting position
6. **Expected**: Afterimage should fade out over 0.5 seconds

### 2. ATP Consumption
1. Monitor player's ATP bar in HUD
2. Note the current ATP value
3. Press SPACE to dodge
4. **Expected**: ATP should decrease by 30 points
5. Wait for ATP to recover
6. Repeat test

### 3. Insufficient ATP Test
1. Reduce player ATP to below 30 (via combat or sprinting)
2. Try to press SPACE to dodge
3. **Expected**: Dodge should fail
4. **Expected**: Console message: "Dodge failed: Not enough ATP"
5. **Expected**: Player should not move or create afterimage

### 4. Invincibility During Dodge
1. Position player near an enemy
2. Press SPACE to dodge
3. During the dodge movement (first 0.4 seconds), allow enemy to attack
4. **Expected**: Player should NOT take damage
5. **Expected**: Console message: "Dodge started! Invincible!"
6. Wait for invincibility to end (console: "Invincibility ended")
7. Allow enemy to attack again
8. **Expected**: Player should take damage normally

### 5. Dodge Cooldown
1. Press SPACE to perform a dodge
2. Immediately try to press SPACE again
3. **Expected**: Dodge should fail
4. **Expected**: Console message: "Dodge failed: Dodge on cooldown"
5. Wait 0.5 seconds
6. Press SPACE again
7. **Expected**: Dodge should succeed

### 6. Directional Dodge
1. Move player in different directions (up, down, left, right, diagonals)
2. Press SPACE while moving in each direction
3. **Expected**: Player should dodge in the direction of movement
4. Stand still and press SPACE
5. **Expected**: Player should dodge in the last direction faced

### 7. Dodge During Different States
1. Test dodge while standing still
2. Test dodge while walking
3. Test dodge while sprinting
4. Test dodge during combat (firing weapons)
5. **Expected**: All should work except when staggered
6. Test dodge while staggered (if toughness system is implemented)
7. **Expected**: Dodge should not work during stagger

### 8. Visual Effects
1. Perform dodge and observe afterimage
2. **Expected**: Afterimage should:
   - Match player's sprite and animation frame
   - Be semi-transparent (alpha ~0.3)
   - Remain at dodge start position
   - Fade to fully transparent over 0.5 seconds
   - Be removed after fading

### 9. Integration with Other Systems
1. Dodge while inventory is open
2. Dodge while dialogue is active (if applicable)
3. Dodge while in vehicle interaction range
4. **Expected**: Dodge should work normally unless state prevents input

## Console Output Expected
When testing, you should see these console messages:
- `"Dodge started! Invincible!"` - When dodge begins
- `"Dodge ended"` - When dodge movement completes
- `"Invincibility ended"` - When invincibility expires
- `"Dodge failed: Not enough ATP"` - When ATP < 30
- `"Dodge failed: Dodge on cooldown"` - During cooldown period
- `"Dodge failed: Already dodging"` - If trying to dodge during dodge

## Known Limitations
1. Dodge movement uses tweening, so it may not perfectly respect collision with walls
2. Afterimage only captures current sprite frame, not a full animation
3. No dodge sound effect (can be added later)
4. No visual indicator for dodge cooldown (HUD enhancement needed)

## Potential Issues to Watch For
1. **Tween conflicts**: If player is moved by other systems during dodge tween
2. **Invincibility not clearing**: If invincibility persists after dodge
3. **ATP not consumed**: If dodge works without ATP cost
4. **Afterimage persistence**: If afterimage doesn't fade or get removed
5. **Input blocking**: If dodge input blocks other inputs
6. **Collision issues**: Player may dodge through walls (collision checking not implemented)

## Performance Considerations
- Afterimage sprites are created and destroyed dynamically
- Each dodge creates one temporary sprite node
- Memory should be freed when afterimage fades
- No performance impact expected from reasonable dodge usage

## Future Enhancements
1. Add collision checking to prevent dodging through walls
2. Add dodge animation (different from walk/idle)
3. Add sound effect for dodge
4. Add visual indicator for dodge availability/cooldown
5. Add particle effects for dodge trail
6. Consider adding directional dodge animations
7. Add dodge combo system (multi-dodge with increasing ATP cost)
8. Add dodge invincibility visual effect (e.g., flash/glow)
