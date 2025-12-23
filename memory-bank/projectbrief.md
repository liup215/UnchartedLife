# Project Brief: Legends of Uncharted Life

## Core Request
Develop a post-apocalyptic educational Action RPG called **Legends of Uncharted Life** that seamlessly integrates biology education with engaging gameplay.

## Key Goals
- **Game Type:** Post-Apocalyptic ARPG + Biology Educational Game
- **Target Users:** High school biology students, science enthusiasts, and teachers
- **Core Vision:** Help students understand biological principles through immersive gameplay, moving beyond memorization to true comprehension
- **Engine:** Godot 4.x
- **Architecture Requirements:**
    - **Extensible & Data-Driven:** Support easy content addition through Resource files (`.tres`)
    - **Clear Structure:** Feature-first organization with separated data, components, and functionality
    - **Reusable & Composable:** Core functionality built as reusable components with minimal inheritance

## Technical Approach
The project is built on a robust **data-driven, component-based architecture**:

- **Data Layer:** Use `Resource` files to define all game entities (enemies, weapons, behaviors, items)
- **Logic Layer:** Generic scripts and components interpret and execute data definitions
- **Scene Layer:** Scenes serve as generic containers for components
- **Educational Integration:** Biology knowledge woven into core mechanics (ATP management, gene editing, ecology restoration)

This approach ensures scalability, organization, and reusability while laying a solid foundation for educational content delivery.

## Development Model
Independent development with focus on:
1. Strong technical architecture first
2. Modular content creation
3. Iterative educational content integration
4. Community-friendly modding support (via Resource files)

## Success Criteria
- Students can explain biological concepts after gameplay
- Engaging enough to compete with non-educational games
- Easy for educators to add custom content
- Modding community can extend with new biology topics
