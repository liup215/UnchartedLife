# Metabolism System Test Guide

## Overview
This document provides comprehensive testing procedures for the player metabolism system, specifically ATP consumption during movement and glucose-based ATP recovery.

## Test Environment Setup

### Prerequisites
1. Open project in Godot 4.x Editor
2. Open the main scene (scenes/main.tscn)
3. Enable HUD display to monitor ATP and Glucose values
4. Ensure player has initial ATP (should be at or near max)
5. Ensure player has initial Glucose (should have enough for testing)

### How to Monitor Values
The HUD should display:
- Current ATP / Max ATP
- Current Glucose / Max Glucose

If not visible, check `ui/hud/hud.gd` and ensure the metabolism component signals are connected.

## Test Cases

### Test 1: Basal ATP Consumption (Standing Still)
**Purpose**: Verify ATP is consumed even when not moving

**Steps**:
1. Run the game
2. Note initial ATP value
3. Stand still (no input) for 5 seconds
4. Observe ATP value

**Expected Results**:
- ATP should decrease by approximately 10 points (2 ATP/sec × 5 sec)
- Glucose should decrease slightly due to basal metabolism
- ATP should automatically recover if Glucose is available

**Acceptance Criteria**:
✅ ATP decreases while standing still
✅ ATP recovers automatically using Glucose


### Test 2: Movement ATP Consumption (Walking)
**Purpose**: Verify ATP is consumed during normal movement

**Steps**:
1. Run the game
2. Note initial ATP value
3. Move the player continuously (WASD keys) for 5 seconds
4. Observe ATP value

**Expected Results**:
- ATP should decrease by approximately 25 points ((2 + 3) ATP/sec × 5 sec)
- Base consumption: 2 ATP/sec
- Movement consumption: 3 ATP/sec
- Total: 5 ATP/sec
- Glucose should be consumed to recover ATP

**Acceptance Criteria**:
✅ ATP decreases faster when moving than when standing
✅ ATP consumption rate is approximately 5 ATP/sec
✅ Glucose is consumed to maintain ATP levels


### Test 3: Sprint ATP Consumption (Running)
**Purpose**: Verify ATP is consumed at higher rate during sprinting

**Steps**:
1. Run the game
2. Note initial ATP value
3. Hold Shift key and move continuously for 5 seconds
4. Observe ATP value

**Expected Results**:
- ATP should decrease by approximately 55 points ((2 + 3 + 6) ATP/sec × 5 sec)
- Base consumption: 2 ATP/sec
- Movement consumption: 3 ATP/sec
- Sprint consumption: 6 ATP/sec
- Total: 11 ATP/sec
- Glucose should be consumed rapidly to recover ATP

**Acceptance Criteria**:
✅ ATP decreases much faster when sprinting
✅ ATP consumption rate is approximately 11 ATP/sec
✅ Glucose is consumed rapidly to maintain ATP levels


### Test 4: ATP Recovery from Glucose
**Purpose**: Verify ATP automatically recovers using Glucose

**Steps**:
1. Run the game
2. Use dodge (Space key) 3 times to deplete ATP significantly
3. Stand still and observe ATP and Glucose values
4. Wait for 10 seconds

**Expected Results**:
- ATP should gradually increase back toward max
- Glucose should decrease proportionally to ATP recovery
- Recovery rate matches consumption rate (based on conversion rate)
- If Glucose runs out, ATP will not recover

**Acceptance Criteria**:
✅ ATP increases over time when below max
✅ Glucose decreases as ATP recovers
✅ Recovery stops when Glucose is depleted


### Test 5: Glucose Depletion Scenario
**Purpose**: Verify behavior when Glucose is exhausted

**Steps**:
1. Run the game
2. Sprint continuously until Glucose is nearly depleted
3. Continue sprinting and observe ATP
4. Monitor when Glucose reaches 0

**Expected Results**:
- When Glucose > 0: ATP maintains relatively stable level
- When Glucose = 0: ATP cannot recover and will decrease continuously
- Player will eventually run out of ATP with no Glucose

**Acceptance Criteria**:
✅ ATP cannot recover when Glucose = 0
✅ ATP continues to decrease during activity without recovery
✅ System correctly handles edge case of zero Glucose


### Test 6: Dodge ATP Consumption (Existing Feature)
**Purpose**: Verify dodge still consumes ATP correctly (regression test)

**Steps**:
1. Run the game
2. Note initial ATP value
3. Press Space key to dodge
4. Observe ATP value

**Expected Results**:
- ATP should decrease by 30 points immediately
- Dodge should execute successfully
- ATP should begin recovering after dodge completes

**Acceptance Criteria**:
✅ Dodge consumes 30 ATP
✅ Cannot dodge when ATP < 30
✅ ATP recovers normally after dodge


### Test 7: Combat ATP Consumption (Regression Test)
**Purpose**: Verify combat actions still consume ATP correctly

**Steps**:
1. Run the game
2. Note initial ATP value
3. Perform light attack (left click)
4. Observe ATP value

**Expected Results**:
- ATP should decrease based on weapon's ATP cost
- Combat should function normally
- ATP should recover using Glucose

**Acceptance Criteria**:
✅ Combat consumes appropriate ATP
✅ ATP recovery works during combat


### Test 8: Stagger State Metabolism
**Purpose**: Verify metabolism continues during stagger

**Steps**:
1. Run the game
2. Get hit by enemy to enter stagger state
3. Observe ATP during stagger
4. Note that no movement input is processed during stagger

**Expected Results**:
- ATP still consumes at basal rate (2 ATP/sec)
- ATP continues to recover from Glucose
- No movement consumption during stagger (player can't move)

**Acceptance Criteria**:
✅ Basal metabolism continues during stagger
✅ ATP recovery works during stagger
✅ No movement ATP consumption during stagger (as player is immobile)


### Test 9: In-Vehicle Metabolism
**Purpose**: Verify player uses reduced metabolism when in vehicle

**Steps**:
1. Run the game
2. Approach a vehicle and press E to enter
3. Observe ATP consumption while in vehicle
4. Drive the vehicle and observe values

**Expected Results**:
- Player ATP consumption reduced to basal rate only
- Vehicle handles its own movement/fuel costs
- Player metabolism continues but at minimal rate

**Acceptance Criteria**:
✅ Player ATP decreases slower in vehicle
✅ ATP recovery continues in vehicle
✅ Vehicle fuel system works independently


## Performance Tests

### Test 10: Continuous Play Performance
**Purpose**: Verify no performance degradation over time

**Steps**:
1. Run the game
2. Play for 5 minutes with varied activities
3. Monitor frame rate and responsiveness
4. Check console for any error messages

**Expected Results**:
- No performance degradation
- No memory leaks
- No console errors related to metabolism
- Smooth gameplay throughout

**Acceptance Criteria**:
✅ Stable frame rate
✅ No console errors
✅ Responsive controls


## Edge Cases

### Test 11: Rapid State Changes
**Purpose**: Verify system handles rapid state transitions

**Steps**:
1. Run the game
2. Rapidly switch between standing/walking/sprinting/dodging
3. Observe ATP changes
4. Check for any glitches or incorrect values

**Expected Results**:
- ATP consumption adapts immediately to current state
- No overflow/underflow errors
- Smooth transitions between states

**Acceptance Criteria**:
✅ Correct ATP consumption for each state
✅ No value corruption
✅ Smooth state transitions


### Test 12: Zero ATP Gameplay
**Purpose**: Verify gameplay when ATP reaches 0

**Steps**:
1. Run the game
2. Deplete Glucose completely
3. Continue playing until ATP reaches 0
4. Observe what happens

**Expected Results**:
- Player can still move (movement doesn't require ATP check)
- Cannot dodge (requires 30 ATP)
- Cannot sprint (but may still walk)
- ATP stays at 0 until Glucose is available

**Acceptance Criteria**:
✅ Game doesn't crash at 0 ATP
✅ Movement restrictions work correctly
✅ System handles 0 ATP gracefully


## Code Review Checklist

### Implementation Verification
- [x] `_process_metabolism` called with correct parameters
- [x] `is_moving` based on input, not velocity
- [x] ATP consumption rates match specification
- [x] Glucose-to-ATP conversion implemented
- [x] Basal metabolic rate applies continuously
- [x] Sprint ATP only consumed when actually moving

### Integration Verification
- [ ] HUD displays correct ATP/Glucose values
- [ ] Dodge component still works correctly
- [ ] Combat system ATP consumption unaffected
- [ ] Vehicle system integration correct
- [ ] No regression in existing features


## Bug Reporting Template

If you find issues during testing, report them with this format:

```
**Test Case**: [Test number and name]
**Expected**: [What should happen]
**Actual**: [What actually happened]
**Steps to Reproduce**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Console Output**: [Any error messages]
**Additional Notes**: [Other observations]
```


## Success Criteria Summary

The metabolism system is working correctly when:
1. ✅ ATP decreases during movement (not just dodge)
2. ✅ ATP consumption rate varies by activity (rest < walk < sprint)
3. ✅ ATP automatically recovers using Glucose
4. ✅ Glucose decreases as ATP recovers
5. ✅ System handles edge cases gracefully
6. ✅ No performance issues
7. ✅ No regressions in existing features


## Notes for Developers

### Key Implementation Details
- **Input Timing**: Movement input is read BEFORE calling `_process_metabolism` to ensure accurate state detection
- **Velocity Issue**: Previous implementation checked `velocity.length()` which was stale (from previous frame)
- **Solution**: Now checks input direction directly, which reflects current frame's intent

### ATP Consumption Rates
```gdscript
Basal (always):        2.0 ATP/sec
Movement (walking):  + 3.0 ATP/sec  = 5.0 ATP/sec total
Sprint (running):    + 6.0 ATP/sec  = 11.0 ATP/sec total
Dodge (instant):       30.0 ATP per dodge
```

### Glucose-to-ATP Conversion
- Conversion rate defined in MetabolismComponent
- ATP recovery amount = ATP consumption amount
- Glucose cost = ATP recovery / conversion_rate
- If insufficient Glucose, ATP will deplete


## Related Files
- `features/player/player.gd` - Main player logic with `_process_metabolism`
- `features/components/attribute_component/metabolism_component.gd` - Core metabolism logic
- `features/components/dodge_component.gd` - Dodge ATP consumption
- `ui/hud/hud.gd` - HUD display for ATP/Glucose values


## Change History
- **2024-12-27**: Created test guide for metabolism system fix
- **2024-12-27**: Fixed ATP movement consumption bug (velocity timing issue)
