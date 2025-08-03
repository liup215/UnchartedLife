# Active Context: Godot ARPG - Data-Driven Architecture & Next Steps

## Current Focus
The primary focus has shifted from implementing individual features to a major architectural refactor. We have successfully transitioned the core systems (enemies, weapons, stats) to a fully data-driven model. The current focus is now on leveraging this new architecture to build out the next layer of gameplay features.

## Key Decisions Made
1.  **Embrace "Resource-as-Soul"**: The core design philosophy is now to treat `Resource` files (`.tres`) as the "soul" of an entity, defining what it *is* and how it *behaves*. Scenes (`.tscn`) are now just generic "containers".
2.  **AI as Composable Data**: Instead of hard-coding AI in scripts, we created a system of `AIBehaviorData` resources. This allows designers to create complex AI by simply mixing and matching behavior resources in an array within an `ActorData` file.
3.  **Generic `Actor` Class**: The base `Actor` script has been stripped of all specific logic. It now functions as a generic "executor" that reads from an `ActorData` resource and delegates tasks to its components and behaviors.
4.  **Default Collision on Base Actor**: To support dynamic, data-driven spawning, a default, valid `CollisionShape2D` was added to `base_actor.tscn`. This ensures any actor instanced from the base scene can be physically interacted with immediately.

## Recent Achievements
1.  **Fully Data-Driven Entities**: Successfully refactored the weapon, health, and AI systems. It is now possible to create a new, fully functional enemy with unique stats and behaviors **purely by creating a new `.tres` file**.
2.  **Decoupling Complete**: The `Actor` scene is now completely decoupled from any specific enemy type (like `Goblin`). The old, specific `goblin.gd` script has been simplified and its hard-coded logic removed.
3.  **Architectural Documentation Updated**: All major design documents (`design_document.md`, `systemPatterns.md`, `progress.md`, `techContext.md`) have been updated to reflect this new, powerful data-driven architecture.

## Next Steps (Phase 7)
With the robust and flexible architecture now in place, the next steps are to build upon it:
1.  **Implement "Just Frame" Mechanic**: Begin work on the "Just Frame" system for the main weapon, which will reward precise timing from the player. This is the next major combat feature.
2.  **Implement Virtual Lab (First Pass)**: Start designing and implementing the first pass of the Virtual Lab UI. This will be a core part of the game's progression and item interaction systems.
3.  **Advanced Energy Systems**: Continue planning for the Hemo-Energy and Entropy Energy systems, which will build upon the existing Glucose-ATP foundation.
