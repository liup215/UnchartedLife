# Active Context: Godot ARPG - Vehicle System Implementation

## Current Focus
The primary focus has been on implementing a robust and physically accurate player-vehicle interaction system. This involved significant refactoring of the vehicle's physics model and creating a safe enter/exit mechanism.

## Key Decisions Made
1.  **Vehicle Physics Model:** Switched from `CharacterBody2D` to `RigidBody2D` for all vehicles. This was a critical decision to resolve physics issues where enemies could push the vehicle. The new model provides more realistic interactions but required a complete overhaul of the movement logic.
2.  **Control Scheme:** Implemented a "tank-style" control scheme for the `RigidBody2D` vehicle, where forward/backward inputs apply force and left/right inputs control angular rotation. This provides a more authentic feel for a heavy vehicle.
3.  **Safe Exiting Protocol:** Developed a multi-step, frame-aware process for exiting the vehicle to prevent physics glitches. This includes finding a safe, non-overlapping position, and temporarily disabling collisions and freezing the vehicle's physics state using `sleeping` and `await`.
4.  **AI and Player Synchronization:** Maintained the existing AI tracking system. The player node, while in the vehicle, continuously syncs its `global_position` to the vehicle. This ensures that the enemy AI, which tracks the player node, correctly follows the vehicle.

## Next Steps
1.  **Finalize Vehicle System:** The core mechanics are now in place. The immediate next step is to ensure all edge cases are handled and the system is stable.
2.  **Implement Core Combat Loop:** With the vehicle system complete, the project can now move on to implementing the core combat mechanics as outlined in the `progress.md` file. This will be the next major feature development phase.
