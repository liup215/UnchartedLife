# Active Context: Godot ARPG - Data-Driven Architecture & Directory Update

## Current Focus
- 目录结构已完成梳理与规范化，所有资源、组件、功能模块分层清晰，便于扩展和维护。
- WorldData资源类型已引入，地图区块场景引用已实现数据驱动，消除硬编码路径。
- 组件、数据、功能、原始资源分离，强化高内聚、低耦合。
- 继续推动所有场景、数据、资源引用走数据驱动和Inspector导出变量方式。

## Key Decisions Made
1.  **Embrace "Resource-as-Soul"**: The core design philosophy is now to treat `Resource` files (`.tres`) as the "soul" of an entity, defining what it *is* and how it *behaves*. Scenes (`.tscn`) are now just generic "containers".
2.  **AI as Composable Data**: Instead of hard-coding AI in scripts, we created a system of `AIBehaviorData` resources. This allows designers to create complex AI by simply mixing and matching behavior resources in an array within an `ActorData` file.
3.  **Generic `Actor` Class**: The base `Actor` script has been stripped of all specific logic. It now functions as a generic "executor" that reads from an `ActorData` resource and delegates tasks to its components and behaviors.
4.  **Default Collision on Base Actor**: To support dynamic, data-driven spawning, a default, valid `CollisionShape2D` was added to `base_actor.tscn`. This ensures any actor instanced from the base scene can be physically interacted with immediately.

## Recent Achievements
1.  **Fully Data-Driven Entities**: Successfully refactored the weapon, health, and AI systems. It is now possible to create a new, fully functional enemy with unique stats and behaviors **purely by creating a new `.tres` file**.
2.  **Combat/Weapon/AI Unified & Reusable**: The combat_component, weapon_component, weapon_effect, and AIBehavior have been fully refactored and unified. Now, actor, enemy, and vehicle all use the same attack logic and component structure. WeaponEffect supports flexible attack effects, and AIBehavior is assigned via data for both player and enemy, enabling true code/data reuse and extensibility.
3.  **Decoupling Complete**: The `Actor` scene is now completely decoupled from any specific enemy type (like `Goblin`). The old, specific `goblin.gd` script has been simplified and its hard-coded logic removed.
4.  **Architectural Documentation Updated**: All major design documents (`design_document.md`, `systemPatterns.md`, `progress.md`, `techContext.md`) have been updated to reflect this new, powerful data-driven architecture.
5.  **目录结构与资源引用规范化**：所有核心资源（如地图区块、武器、组件等）已按功能和用途分层，WorldData等资源型引用已替代硬编码路径。

## Next Steps
1.  持续推进所有资源、场景、数据的Inspector导出变量引用，彻底消除硬编码路径。
2.  实现和完善“Just Frame”主武器精确判定系统，提升战斗深度。
3.  设计并开发虚拟实验室（Virtual Lab）UI，作为游戏进阶与物品交互的核心入口。
4.  规划并逐步实现高级能量系统（如Hemo-Energy、Entropy Energy），基于现有Glucose-ATP体系扩展。
