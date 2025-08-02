# Active Context: Godot ARPG - Core Combat Loop & Visual Feedback

## Current Focus
The primary focus has shifted from vehicle systems to implementing a rich and responsive core combat loop. This involves creating satisfying visual feedback for combat actions, refining weapon mechanics, and establishing a complete lifecycle for all actors in the game.

## Key Decisions Made
1.  **Projectile as `Area2D`**: Decided to implement projectiles as `Area2D` nodes instead of `PhysicsBody2D`. This prevents them from exerting physical force on enemies, solving the issue of bullets pushing targets around. Collision is handled via the `body_entered` signal.
2.  **Centralized Vehicle Weapon Effect**: To simplify visual effect management, vehicles now spawn a single, shared `WeaponEffect` node. The `CombatComponent` is responsible for passing this node to the appropriate weapon during firing, which then triggers the effect. This avoids cluttering the scene with multiple effect nodes for each weapon.
3.  **Dynamic Visual Feedback System**: Implemented two key feedback systems that are dynamically created and managed via code:
    *   **Floating Damage Numbers**: A generic function in the base `Actor` class creates animated, floating damage numbers upon taking damage.
    *   **Hit & Death Effects**: Projectiles spawn hit animations, and the base `Actor` class now includes a generic death sequence (fade, shrink, and `queue_free`) triggered by its `HealthComponent`.
4.  **Asynchronous Combo Firing**: To improve the feel of rapid-fire weapons, the combo attack logic in `CombatComponent` was updated to use `await` with a `SceneTreeTimer`. This introduces a slight, non-blocking delay between shots, creating a rhythmic firing effect instead of all shots firing simultaneously.

## Recent Achievements
1.  **Complete Combat Feedback Loop**: Successfully implemented a full suite of visual feedback for combat: projectiles hit and disappear, spawn explosion effects, and deal damage that appears as floating numbers on the target.
2.  **Actor Lifecycle Finalized**: All actors inheriting from the base `Actor` class now have a complete lifecycle, from taking damage to a clean death sequence and removal from the game.
3.  **Refined Weapon Mechanics**: The vehicle's weapon systems are now more robust and visually satisfying, with a centralized effect handler and rhythmic combo firing.
4.  **Solved Numerous Bugs**: Fixed a wide range of issues, including invisible projectiles, incorrect collision layer settings, and `Tween` animation glitches.

## Next Steps
1.  **Implement "Just Frame" Mechanic**: Begin work on the "Just Frame" system, which will reward precise timing from the player. This is the next major combat feature to be implemented.
2.  **Virtual Lab UI**: Start designing and implementing the first pass of the Virtual Lab UI, which will be a core part of the game's progression and item interaction systems.
3.  **Advanced Energy Systems**: Continue planning for the Hemo-Energy and Entropy Energy systems, which will build upon the existing Glucose-ATP foundation.
