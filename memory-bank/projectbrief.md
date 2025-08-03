# Project Brief: Godot ARPG

## Core Request
The user wants to develop an Action RPG (ARPG) using the Godot game engine. The primary focus is on creating a robust and scalable architecture with an emphasis on strong code organization and high reusability.

## Key Goals
- **Game Genre:** Action RPG (ARPG) with a strong educational focus on Biology.
- **Engine:** Godot 4.x
- **Architectural Requirements:**
    - **Scalable & Data-Driven:** The architecture must support the addition of new content (enemies, items, weapons) primarily through the creation of data resources (`.tres` files), minimizing the need for new code or scenes.
    - **Organized:** The project structure follows a feature-first approach, with clear separation between data, components, and features.
    - **Reusable & Composable:** Core functionality is built into reusable components (e.g., `HealthComponent`). Entities are built by composing these components and are defined by data, rather than through deep inheritance hierarchies.

## Initial Scope & Technical Approach
The initial task is to build a robust architectural foundation for the ARPG. The chosen approach is a **Data-Driven, Component-Based Architecture**.
- **Data Layer:** `Resource` files define all game entities.
- **Logic Layer:** Generic scripts and components interpret and act upon the data.
- **Scene Layer:** Scenes act as generic containers for components.

This approach ensures that the key goals of scalability, organization, and reusability are met from the ground up.
