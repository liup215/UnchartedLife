# Progress Tracker: 《执笔问道录》

## 新起点：项目转型 (Project Pivot)
项目已于2025年11月完成重大设计转型，从原有的生物学科ARPG概念转向以K-12教育为核心的《执笔问道录》。以下是新的开发进度追踪。原有的开发进度已归档，其技术积累（特别是数据驱动架构）将作为新项目的基础。

---

## 长期规划与开发优先级 (Long-Term Planning & Priorities)
- **开发优先级:** 游戏体验 > 做题功能 > AI增强 > 后台云服务
    - 1. **游戏体验:** 首先实现可玩的战斗-答题循环原型，优先保证核心玩法的流畅性和乐趣。
    - 2. **做题功能:** 在游戏循环跑通后，逐步完善题目评估系统，先用简单的字符串匹配，后续再集成离线评估引擎（Python+SymPy）。
    - 3. **AI增强:** 基础AI（敌人移动/攻击）属于游戏范畴，题目生成/智能评估等高级AI为远期目标。
    - 4. **后台云服务:** 所有云端功能（如数据同步、在线PBL分享等）在单机体验完善后再考虑。

- **实施策略:** 先用“假判断”快速实现“真循环”，即先用简单判断实现战斗-答题流程，待核心体验稳定后再完善评估引擎。

---

## Phase 1: 《执笔问道录》 - 核心原型开发 (In Progress)

此阶段的目标是验证新设计的核心技术和玩法循环是否可行。

- [x] **武器与组件系统重构与功能扩展:**
    - [x] 新增 VehicleCombatComponent，支持主副武器管理、充能、发射、连击、ATP 消耗等机制。
    - [x] 实现 ActorCombatComponent，支持角色武器发射、蓄力、连击等机制。
    - [x] WeaponComponent 负责武器逻辑（发射、蓄力、弹药管理）。
    - [x] 开发 AttributeComponent，统一管理角色属性（生命、代谢等）。
    - [x] 新增 VehicleStatsComponent，管理载具性能。
    - [x] 新增 InteractableComponent，支持玩家与拾取物交互。
    - [x] 新增 InventoryComponent，支持物品存取与背包管理。
    - [x] 新增 Pickup 类，实现物品收集与视觉反馈。
    - [x] 新建玩家机关枪武器资源，包含伤害、射速、弹药等属性，并集成新武器场景。
    - [x] 现有组件已与新武器和战斗系统集成。
- [x] **BioBlitz 系统与 UI:**
    - [x] 建立 BioBlitzManager，负责基于答题的战斗循环。
    - [x] 创建 BioBlitzSelection 场景，支持章节/知识点选择。
    - [x] 新增角色菜单 UI，支持玩家选项操作。
- [x] **背包与装备 UI/流程打通:**
    - [x] System Menu Inventory 页：多容器 Tab、物品格子、详情与 Use 按钮。
    - [x] Equipment 页固定槽位（Weapon/Armor/Gloves/Helmet/Boots），显示武器伤害/射速/弹匣/弹药。
    - [x] 武器装备/卸载闭环：ItemUseService 装备时从背包移出、卸载时回填到 "weapons" 容器；EventBus.equipment_changed 驱动 UI 刷新。
- [ ] **搭建原型 - 离线评估引擎:**
    - [ ] 创建一个最小化的 Godot 场景和一个简单的 Python 脚本（使用 Flask 或类似框架）。
    - [ ] **目标:** 验证 Godot 能通过本地 HTTP 请求将数学题发送给 Python 脚本，脚本使用 SymPy 判断答案后将结果返回 Godot。**(最高优先级，需最先验证)**
- [ ] **定义核心数据结构:**
    - [ ] 在 Godot 中创建 `QuestionData.gd` 和 `BookSoulSealData.gd` 的 `Resource` 脚本。
    - [ ] **目标:** 定义这些核心数据结构的具体字段，为后续系统开发提供数据基础。
- [ ] **实现战斗-答题循环原型:**
    - [ ] 创建一个基础的“乱墨妖”敌人，当其生命值降低到阈值时，触发答题界面。
    - [ ] **目标:** 验证“战斗”与“答题”两个状态之间的切换流程。
- [ ] **重构/清理旧代码:**
    - [ ] 识别并逐步移除与旧载具系统和葡萄糖资源相关的代码和资源文件。
    - [ ] **目标:** 保持代码库的整洁，移除不再需要的历史包袱。
- [x] **Bio Blitz 原型增强:**
    - [x] 实现基于章节的 Boss 数据加载 (`bio_blitz_selection.gd`)。
    - [x] 优化战斗界面视觉效果（背景图、血条样式）。
    - [x] 修复 Boss 纹理显示问题。

---

## 已归档的前期架构探索 (Archived: "Legends of Uncharted Life" Prototype)

以下是项目转型前已完成的工作。这些工作为当前项目奠定了坚实的数据驱动架构基础。

- **Phase 1: Core Architecture & Setup (Complete)**
    - [x] Designed and implemented a feature-first project structure.
    - [x] Created a global event bus for decoupled communication.
    - [x] Implemented a data-driven actor system with `ActorData` resources.
    - [x] Created base components for `Health` and `Stats`.
    - [x] Built a base `Actor` scene and script.
    - [x] Implemented a main game scene, main menu, character creation, HUD, and system menu.

- **Phase 2: Save/Load System (Complete)**
    - [x] Designed and implemented a multi-slot save/load manager.

- **Phase 3: World & Map System (Complete)**
    - [x] Designed and implemented a chunk-based dynamic map loading system.

- **Phase 4: Core Gameplay & Biology Systems (Complete)**
    - [x] Implemented a complete Glucose-ATP energy management system.
    - [x] Implemented a sprint system with tiered energy consumption.

- **Phase 5: Enhanced Gameplay Systems (Complete)**
    - [x] Implemented a full Player-Vehicle system with `RigidBody2D` physics.
    - [x] Implemented a core combat loop with combo/charging mechanics and visual feedback.

- **Phase 6: Data-Driven Architecture Refactor (Complete)**
    - [x] Fully refactored weapon, health, and AI systems to be data-driven.
    - [x] Achieved "Resource-Only" entity creation, allowing designers to create new enemies by editing `.tres` files without writing code.
