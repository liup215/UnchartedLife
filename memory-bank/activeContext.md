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
- **Map System Refactor**: `MapManager` now loads chunks dynamically using `WorldData` resource. No more hardcoded `res://world/chunk_*.tscn` paths.
- **Inventory System**: Implemented comprehensive inventory management with `InventoryComponent`, `InventoryData` resources, and tabbed UI with item details panel.
- **Equipment System**: Added equipment slots (Weapon/Armor/Gloves/Helmet/Boots) with visual display of equipped items and stats.
- **Dialogue System**: Complete NPC dialogue system with branching choices, conditions, quest integration, and typewriter effect.
- **Quest System**: Hierarchical quest/objective system with runtime state management and event-based tracking.
- **Combat Enhancement**: Unified weapon system supporting both actors and vehicles, with charge mechanics and combo systems.

## Next Steps
- Continue to data-drive all remaining hardcoded references.
- Expand AI behavior library with more composable behaviors.
- Add more weapon types and enemy varieties using the Resource-driven system.
- Implement save/load for all new systems (inventory, quests, dialogue state).
- Performance profiling and optimization for chunk loading system.
