# Progress Tracker

## Phase 1: Core Architecture & Setup (Complete)

- [x] Design and implement a feature-first project structure.
- [x] Create a global event bus for decoupled communication.
- [x] Implement a data-driven actor system with `ActorData` resources.
- [x] Create base components for `Health` and `Stats`.
- [x] Build a base `Actor` scene and script.
- [x] Create `Player` and `Goblin` actors inheriting from the base actor.
- [x] Implement a main game scene (`main.tscn`).
- [x] Implement a main menu (`main_menu.tscn`) with navigation.
- [x] Implement a character creation screen (`character_creation.tscn`).
- [x] Implement a basic in-game HUD (`hud.tscn`) to display player info.
- [x] Implement a pausable in-game system menu (`system_menu.tscn`).
- [x] Debug and resolve all startup crashes and input handling issues.

## Phase 2: Save/Load System (Complete)

- [x] Design a save/load manager.
- [x] Implement logic to save player data (name, position, stats).
- [x] Implement logic to load player data.
- [x] Integrate save/load functionality with the UI (e.g., "Continue" button).
- [x] Implement multi-slot save/load functionality.
- [x] Add "Quit to Menu" and "Quit to Desktop" options.
- [x] Change system menu to be full-screen.
- [x] Debug and resolve all scene hierarchy and loading issues.

## Phase 3: World & Map System (Complete)

- [x] Debugged and fixed complex collision and AI behavior issues.
- [x] Resolved node initialization order and group lookup timing problems.
- [x] Designed a chunk-based dynamic map loading system.
- [x] Created a `TileSet` resource from image assets.
- [x] Implemented a `MapManager` singleton to handle loading map chunks.
- [x] Integrated the `MapManager` to load the initial map chunk based on player position.

## Phase 4: Core Gameplay & Biology Systems (Current)

- [ ] **Implement Glucose-ATP System:**
    - [ ] Refactor `ActorData` to include new biological stats (`max_hp`, `max_atp`, etc.).
    - [ ] Create `ATPComponent` to manage ATP logic.
    - [ ] Implement passive Glucose consumption based on metabolic rate.
    - [ ] Update HUD to display Glucose and ATP.
- [ ] **Implement Player-Vehicle Separation:**
    - [ ] Create a base `Vehicle` scene.
    - [ ] Implement logic for player to enter/exit vehicle.
    - [ ] Separate player and vehicle stats and controls.
- [ ] **Implement Core Combat Loop:**
    - [ ] Implement secondary weapon combo system.
    - [ ] Implement main weapon charging system.
    - [ ] Implement basic "Just Frame" mechanic.
- [ ] **Implement Virtual Lab (First Pass):**
    - [ ] Create the basic UI for the lab.
    - [ ] Implement the "Virtual Microscope" feature for viewing item details.
