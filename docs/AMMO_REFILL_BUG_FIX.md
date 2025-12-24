# Ammo Refill Bug Fix Documentation

## Problem Statement
**Bug**: When ammunition runs out, entering and exiting a vehicle causes the ammunition to be refilled automatically.

## Root Cause Analysis

The bug occurred due to a design flaw in the quiz reload system:

1. **Global Signal Broadcast**: When any quiz completes successfully, `EventBus.quiz_completed.emit(true)` is broadcast globally to all listeners.

2. **Indiscriminate Reload**: The `_on_quiz_completed()` method in `WeaponComponent` was connected to this global signal. It would reload ANY weapon that had `requires_quiz_reload = true`, regardless of whether that specific weapon requested the quiz.

3. **Auto-Complete Trigger**: In `BioBlitzManager`, when the question pool is empty, it automatically completes the quiz with success=true (line 99). This was intended for testing but was enabled unconditionally.

4. **Unintended Reload Scenario**: 
   - Player fires weapon until ammo = 0
   - Player enters and exits vehicle (no direct issue here)
   - Player attempts to fire again → weapon calls `reload()`
   - `reload()` emits `request_quiz_reload` signal
   - If `BioBlitzManager` exists with empty questions, it auto-completes
   - ALL weapons with `requires_quiz_reload = true` reload their ammo

## Solution Implemented

### 1. Weapon-Specific Reload Tracking (`weapon_component.gd`)

Added a `is_waiting_for_quiz` flag to track which weapon requested the reload:

```gdscript
var is_waiting_for_quiz: bool = false  # Track if this weapon is waiting for quiz completion

func reload():
    if weapon_data.weapon_data.requires_quiz_reload:
        is_waiting_for_quiz = true  # Mark this weapon as waiting
        EventBus.request_quiz_reload.emit(weapon_data)
    else:
        current_ammo = weapon_data.weapon_data.ammo_capacity
        emit_signal("ammo_updated", current_ammo)

func _on_quiz_completed(success: bool):
    # Only reload if THIS weapon was waiting for the quiz
    if success and is_waiting_for_quiz and weapon_data and weapon_data.weapon_data.requires_quiz_reload:
        current_ammo = weapon_data.weapon_data.ammo_capacity
        emit_signal("ammo_updated", current_ammo)
        is_waiting_for_quiz = false  # Reset the flag
    elif not success and is_waiting_for_quiz:
        is_waiting_for_quiz = false  # Reset the flag even on failure
```

**Benefits**:
- Only the weapon that explicitly called `reload()` will reload when quiz completes
- Multiple weapons won't all reload from a single quiz completion
- Maintains backward compatibility with existing code

### 2. Testing Mode Control (`bio_blitz_manager.gd`)

Added `auto_complete_when_no_questions` flag to control auto-complete behavior:

```gdscript
@export var auto_complete_when_no_questions: bool = false  # For testing only, set to false in production

func display_random_question() -> void:
    if question_pool.size() > 0:
        # ... display question logic
    else:
        print("No questions in pool!")
        question_label.text = "No questions loaded!"
        # Auto-complete if no questions (for testing only)
        if auto_complete_when_no_questions:
            print("[BioBlitz] Auto-completing quiz due to empty question pool (testing mode)")
            EventBus.quiz_completed.emit(true)
        quiz_panel.visible = false
```

**Benefits**:
- Prevents accidental quiz completion in production
- Still allows testing scenarios when explicitly enabled
- Makes the testing behavior explicit and intentional

### 3. Additional Fix: Missing Signal Emission

Added missing `ammo_updated` signal emission in `_on_quiz_completed()`:

```gdscript
emit_signal("ammo_updated", current_ammo)
```

This ensures UI and other systems are properly notified when ammo changes via quiz reload.

## Testing Recommendations

1. **Ammo Persistence Test**:
   - Fire weapon until ammo = 0
   - Enter vehicle
   - Exit vehicle
   - Verify ammo is still 0
   - Try to fire → should trigger quiz
   - Complete quiz → only that weapon reloads

2. **Multiple Weapons Test**:
   - Have multiple weapons with `requires_quiz_reload = true`
   - Deplete ammo on Weapon A
   - Request reload for Weapon A
   - Complete quiz
   - Verify only Weapon A reloads, not other weapons

3. **Auto-Complete Flag Test**:
   - Set `auto_complete_when_no_questions = false` (default)
   - Trigger quiz with empty question pool
   - Verify quiz does NOT auto-complete
   - Set flag to true
   - Verify quiz DOES auto-complete

## Alternative Solutions Considered

### Option 1: Pass Weapon Data Through quiz_completed Signal
Change `EventBus.quiz_completed` to include weapon information:
```gdscript
signal quiz_completed(success: bool, weapon_data: Resource)
```

**Pros**: More explicit, clearer intent
**Cons**: Requires changes to BioBlitzManager and all listeners, larger refactor

### Option 2: Use Weapon-Specific Signals
Have each weapon create its own reload signal instead of using EventBus.

**Pros**: Complete isolation between weapons
**Cons**: More complex architecture, harder to track quiz state globally

### Chosen Solution: Flag-Based Tracking (Option 3)
**Pros**: Minimal changes, backward compatible, surgical fix
**Cons**: Relies on proper flag management

## Future Improvements

1. **Weapon-Specific Quiz Completion**: Consider passing weapon_data through quiz_completed signal for more explicit tracking.

2. **Quiz Request Queue**: If multiple weapons request reloads simultaneously, implement a queue system.

3. **UI Feedback**: Add visual feedback when weapon is waiting for quiz completion.

4. **Testing Framework**: Add automated tests for quiz reload scenarios.

## Related Files Modified

- `features/components/weapon_component.gd` - Added is_waiting_for_quiz tracking
- `scenes/blitz_battle/bio_blitz_manager.gd` - Added auto_complete_when_no_questions flag

## Conclusion

This fix addresses the root cause while maintaining minimal code changes and backward compatibility. The weapon-specific tracking ensures that quiz completions only affect the intended weapon, preventing the unwanted global reload behavior.
