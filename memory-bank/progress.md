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

## Phase 4: Core Gameplay & Biology Systems (Complete)

- [x] **Implement Glucose-ATP System:**
    - [x] Refactor `ActorData` to include new biological stats (`max_hp`, `max_atp`, etc.).
    - [x] Create `ATPComponent` to manage ATP logic with float precision.
    - [x] Implement dynamic glucose consumption based on ATP demand.
    - [x] Update HUD to display real-time Glucose and ATP values.
    - [x] Implement biological energy conversion system (glucose → ATP).
    - [x] Add basal metabolic rate for basic cellular maintenance.
- [x] **Implement Sprint System:**
    - [x] Add sprint functionality with Shift key input.
    - [x] Implement speed boost during sprinting (1.8x multiplier).
    - [x] Create tiered ATP consumption: Rest (2/sec) → Walking (5/sec) → Sprinting (11/sec).
    - [x] Integrate sprint mechanics with glucose-ATP metabolism.
- [x] **Refine Biological Accuracy:**
    - [x] Implement demand-driven glucose consumption (only when ATP < max).
    - [x] Balance ATP recovery rate to match consumption rate exactly.
    - [x] Create realistic energy management system with resource pressure.

## Phase 5: Enhanced Gameplay Systems (Next)

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
- [ ] **Advanced Energy Systems:**
    - [ ] Implement Hemo-Energy and Entropy Energy systems.
    - [ ] Create skill-based energy consumption mechanics.
    - [ ] Add environmental factors affecting metabolism.

## Key Achievements Summary

### Biological Systems Foundation ✅
The game now has a complete, scientifically-grounded energy management system:
- **Glucose as Universal Resource**: Serves as both currency and energy source
- **ATP as Action Energy**: Required for all player activities with realistic consumption rates  
- **Demand-Driven Metabolism**: Glucose consumption matches actual energy needs
- **Activity-Responsive System**: Energy costs scale realistically with activity intensity

### Core Gameplay Mechanics ✅  
- **Multi-tiered Movement System**: Walk and sprint with appropriate energy costs
- **Real-time Resource Management**: Live glucose and ATP tracking via HUD
- **Biological Accuracy**: System reflects real cellular energy processes
- **Strategic Depth**: Players must balance speed vs energy conservation

### Technical Excellence ✅
- **Float Precision Energy**: Accurate per-frame energy calculations  
- **Component Architecture**: Modular, extensible energy system design
- **Data-Driven Balance**: Easy tweaking of metabolic rates and conversion ratios
- **Performance Optimized**: Efficient real-time metabolism processing
