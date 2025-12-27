# Active Context: Godot ARPG - Data-Driven Architecture & Directory Update

## Current Focus
- 目录结构已完成梳理与规范化，所有资源、组件、功能模块分层清晰，便于扩展和维护。
- WorldData资源类型已引入，地图区块场景引用已实现数据驱动，消除硬编码路径。
- 组件、数据、功能、原始资源分离，强化高内聚、低耦合。
- 继续推动所有场景、数据、资源引用走数据驱动和Inspector导出变量方式。

## Key Decisions Made
1.  **Embrace "Resource-as-Soul"**: The core design philosophy is now to treat `Resource` files (`.tres`) as the "soul" of an entity, defining what it *is* and how it *behaves*. Scenes (`.tscn`) are now just generic "containers".
2.  **AI as Composable Data**: Instead of hard-coding AI behaviors in scripts, AI behaviors are now `Resource` files (`AIBehaviorData`). An enemy's AI is defined by an array of these resources, which the `Actor` script interprets.
3.  **Centralized Resource Management**: All scene references (especially map chunks via `WorldData`) are managed through Inspector-exported variables or custom Resource types, avoiding hardcoded paths.
4.  **Feature-First Directory Structure**: The project structure prioritizes features (e.g., `features/actor`, `features/vehicle`) over type-based organization, keeping related code together.

## Recent Achievements

### December 2025 Updates
- **Text-to-Speech (TTS) for Dialogue System (Current PR)**:
  - TTSManager autoload singleton using Godot's built-in DisplayServer TTS API
  - Per-line TTS configuration (enable_tts, voice_id, rate, pitch, volume)
  - DialoguePanel integration with automatic TTS playback and lifecycle management
  - TTS stops on dialogue skip, end, or interruption
  - Platform detection and graceful degradation
  - Demo dialogue and test infrastructure
  - Comprehensive documentation in English and Chinese (TTS_IMPLEMENTATION.md, TTS_README_CN.md)
  - Accessibility feature for visually impaired and reading-challenged players

- **Complete Save/Load System (PR #2)**:
  - Binary serialization (var_to_bytes/bytes_to_var) supporting all custom data types
  - Full ActorData serialization with Resource path conversion
  - Multi-slot save system with metadata tracking
  - Complete game state persistence (player, vehicle, map chunks, global singletons)
  - MapManager integration with chunk restoration
  - Vehicle state restoration with proper re-entry
  - Corrupted save file error handling
  - Deferred loading pattern for scene-dependent data

- **UI & Menu System Improvements (PR #3)**:
  - Fixed NewGameSettings visibility issue (proper menu container hiding)
  - Enhanced save file error handling with warning messages
  - New game flow: Menu → Settings → Initialize State → Load Scene
  - Continue/Load game flow with proper state restoration
  - Save game from in-game system menu (ESC key)

- **Animation System Fix (PR #4)**:
  - Fixed player walk animation displaying idle frame on first step
  - Root cause: Animation frame_indices started with idle frame (frame 0)
  - Solution: Reordered frame indices to move idle frame to end
  - Added defensive `is_playing()` check in actor animation logic
  - Created animation testing documentation and debug guides

- **Advanced Combat System Implementation**:
  - **Combo Attack System**: Light attacks with 3-stage combo progression (damage, armor break, stagger scaling)
  - **Heavy Charge System**: Hold-to-charge mechanic with 5 charge levels (2.0x to 5.0x damage multipliers)
  - **ChargeComponent**: Universal charge management supporting both hit accumulation and hold-to-charge
  - **ChargeDisplay UI**: Real-time charge level display in bottom-right corner with color-coded feedback
  - **ComboAttackData & HeavyAttackData**: Resource-based attack configuration per weapon
  - **DamageCalculator**: Comprehensive damage calculation considering all combat factors
  - **ToughnessComponent**: Complete toughness/stagger system (韧性/僵直)
  - **Stagger Mechanics**: 2-second duration with input lockout, movement lock, and visual feedback
  - **Weapon-Specific Configs**: Each weapon can have unique combo sequences and charge properties
  - Complete integration with existing combat systems (projectiles, hit detection, visual effects)

- **Map/Level Switching System**:
  - **MapData Resource**: Define maps with chunk scenes, spawn positions, and metadata
  - **Multi-Map Support**: Switch between different maps with automatic chunk loading/unloading
  - **Default Initial Map**: "main_world" configured as default map for new games
  - **Map-Specific Saves**: Current map ID and player position saved/loaded correctly
  - **Vehicle-Map Binding**: Vehicles assigned to specific maps with `assigned_map_id` property
  - **Portal System**: Example portal implementation for map transitions
  - **EventBus Integration**: `map_changed` signal for system notifications
  - Complete documentation in MAP_SYSTEM.md and MAP_SYSTEM_CN.md

### Previous Achievements (Earlier 2025)
- **Map System Refactor**: `MapManager` now loads chunks dynamically using `WorldData` resource. No more hardcoded `res://world/chunk_*.tscn` paths.
- **Inventory System**: Implemented comprehensive inventory management with `InventoryComponent`, `InventoryData` resources, and tabbed UI with item details panel.
- **Equipment System**: Added equipment slots (Weapon/Armor/Gloves/Helmet/Boots) with visual display of equipped items and stats.
- **Dialogue System**: Complete NPC dialogue system with branching choices, conditions, quest integration, and typewriter effect.
- **Quest System**: Hierarchical quest/objective system with runtime state management and event-based tracking.

## Next Steps
- **BioBlitz Enhancement:**
  - Expand question bank with diverse biology topics
  - Add different question types (multiple choice, fill-in-blank, matching)
  - Implement difficulty progression
  - Add hints system tied to ATP cost

- **Biology Content Integration:**
  - Create educational tooltips for all biological systems
  - Design biology-themed enemies (viruses, bacteria, mutated cells)
  - Build ecology restoration mini-game
  - Implement genetic modification lab interface

- **Vehicle Bionic Modifications:**
  - Create bionic modification system based on animal adaptations
  - Each modification teaches evolutionary biology concepts
  - Visual representation of modifications on vehicle

- **Combat System Polish:**
  - Balance combo progression and charge levels
  - Tune toughness/stagger mechanics
  - Add more visual effects for combat feedback
  - Create weapon-specific combo animations
  - Implement elemental damage type effectiveness

- **Map & Level Design:**
  - Create additional maps with distinct biomes
  - Design portal/transition systems between maps
  - Add map-specific enemies and challenges
  - Implement minimap and map discovery system

- **Performance & Polish:**
  - Profile combat system performance
  - Optimize damage calculation for large battles
  - Add audio feedback for combat actions
  - Improve visual effects and screen shake
