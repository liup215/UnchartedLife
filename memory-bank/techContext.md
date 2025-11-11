# Tech Context: 《执笔问道录》

## 1. 游戏引擎 (Game Engine)
- **引擎:** Godot 4.x
- **语言:** GDScript (强制使用静态类型)
- **理由:** Godot 4.x 提供了强大的功能和性能，而 GDScript 与引擎的紧密集成能够实现快速开发。静态类型能显著提升代码质量和可维护性。

## 2. 核心架构模式 (Core Architectural Patterns)

### 2.1. 数据驱动的实体架构
这是项目的基石。
- **哲学:** 数据与逻辑分离。游戏内实体的属性和行为在 `Resource` 文件 (`.tres`) 中定义，而场景 (`.tscn`) 和脚本 (`.gd`) 则是解释这些数据的通用“容器”。
- **实现:**
    - **`base_actor.tscn`**: 所有角色的通用模板。
    - **`ActorData.gd`**: 定义角色属性和行为的 `Resource`。在新设计下，它将包含与“乱墨妖”绑定的 `QuestionData`。
    - **`BookSoulSealData.gd`**: 定义“书魂印”（技能）的 `Resource`，包括其效果和类型。
    - **`QuestionData.gd`**: 定义题目的 `Resource`，包含题干、答案、题型和评估逻辑。

### 2.2. 组件化设计 (Component-Based Design)
- **理念:** 优先使用组合而非继承。游戏对象由多个可复用的小型场景/脚本（组件）构成，例如 `HealthComponent`、`CombatComponent` 和新的 `InkEnergyComponent`。

### 2.3. 全局事件总线 (Global Event Bus)
- **`EventBus` Autoload:** 继续作为解耦系统间通信的首选方案，用于广播 `skill_unlocked` 或 `pbl_project_completed` 等全局事件。

## 3. 版本控制 (Version Control)
- **系统:** Git
- **配置:** 必须正确配置 `.gitattributes` 以优化对 Godot 文本格式场景 (`.tscn`) 和资源 (`.tres`) 文件的处理。

## 4. 离线优先的技术架构建议 (Offline-First Technical Architecture)

### 4.1. 客户端 (Godot 4.x)
- **职责:** 渲染、战斗逻辑、UI、PBL 编辑器交互、本地题库管理以及与本地评估服务的通信。
- **存储:** 本地数据优先使用 SQLite 或结构化的 JSON 文件。
- **PBL 沙盒模拟:** 利用 Godot 内置的物理引擎或编写专用的模拟模块，对 PBL 提交方案进行本地模拟，并返回关键性能指标（KPIs）。

### 4.2. 本地评估引擎 (Local Evaluation Engine)
这是实现离线评估的关键。MVP（最小可行产品）阶段不依赖联网 LLM。
- **架构:** 客户端-本地服务模式。Godot 客户端通过本地网络请求（HTTP）与一个在后台运行的 Python 服务进行通信。
- **技术选型 (方案 A - 优先):**
    - **打包一个独立的 Python 运行时:** 在游戏发行包中内嵌一个轻量级的 Python 环境。
    - **集成 `SymPy` 库:** 将 SymPy 作为核心的符号计算库，用于处理数学题目的评估。
    - **通信:** Godot 通过 `HTTPRequest` 节点向本地启动的轻量级 Web 服务（如使用 Flask 或 aiohttp）发送包含题目和答案的 JSON 数据。服务处理后返回评估结果。
- **备选方案 (方案 B - 长期):**
    - 为了更深度的集成和更小的打包体积，未来可以考虑用 C++ 或 Rust 重写一个轻量级的表达式解析和符号计算库，并通过 GDExtension 直接嵌入到 Godot 中。首个版本不采用此方案。

### 4.3. 物理系统与交互 (Physics & Interaction)
- **实体类型:** 所有动态实体（玩家、敌人）统一使用 `CharacterBody2D`，因为它提供了对移动和碰撞的精确控制，非常适合 ARPG 的操作手感。
- **物理层:** 将继续使用物理层来区分不同类型的交互（如角色、世界、伤害判定区），以确保碰撞检测的准确性和效率。旧的“Vehicle”相关物理层将被重新评估或移除。
