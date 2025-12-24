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

### Previous Achievements
- **Map System Refactor**: `MapManager` now loads chunks dynamically using `WorldData` resource. No more hardcoded `res://world/chunk_*.tscn` paths.
- **Inventory System**: Implemented comprehensive inventory management with `InventoryComponent`, `InventoryData` resources, and tabbed UI with item details panel.
- **Equipment System**: Added equipment slots (Weapon/Armor/Gloves/Helmet/Boots) with visual display of equipped items and stats.
- **Dialogue System**: Complete NPC dialogue system with branching choices, conditions, quest integration, and typewriter effect.
- **Quest System**: Hierarchical quest/objective system with runtime state management and event-based tracking.
- **Combat Enhancement**: Unified weapon system supporting both actors and vehicles, with charge mechanics and combo systems.

## Next Steps
- Expand BioBlitz question bank with diverse biology topics
- Implement biology-themed enemy varieties using Resource-driven system
- Add vehicle bionic modifications based on animal adaptations
- Create educational tooltips for biological systems
- Continue expanding AI behavior library with more composable behaviors
- Performance profiling and optimization for save/load system
- Add hints system for BioBlitz questions tied to ATP cost
