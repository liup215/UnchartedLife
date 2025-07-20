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

## Phase 3: Core Gameplay Systems (Next)

- [ ] Design an expanded Stats System (e.g., attack, defense, crit).
- [ ] Design an Inventory System for managing items.
- [ ] Design an Equipment System for equipping items to modify stats.
- [ ] Design a Skill System for character abilities.
- [ ] Implement the expanded Stats System.
- [ ] Implement the Inventory data structure and backend logic.
- [ ] Implement the Equipment data structure and backend logic.
- [ ] Implement the Skill data structure and backend logic.
- [ ] Create UI for the Inventory screen.
- [ ] Create UI for the Equipment screen.
- [ ] Create UI for the Skills screen.
