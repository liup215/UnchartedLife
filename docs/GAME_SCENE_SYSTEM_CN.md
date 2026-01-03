# 游戏场景加载系统

## 概述
游戏场景加载系统实现了数据驱动的场景架构，将场景配置（数据）与场景逻辑（代码）分离。这允许灵活的场景组合而无需修改代码。

## 架构

### 核心概念："灵魂-容器-大脑"
遵循项目既定的模式：
- **灵魂（数据）**：`GameSceneData` 资源定义场景中存在什么
- **容器（场景）**：`game_scene.tscn` 是通用的外壳
- **大脑（逻辑）**：`game_scene.gd` 读取数据并生成实体

### 核心组件

#### 1. GameSceneData（资源）
完整游戏场景的主配置。

**属性：**
- `scene_id`：唯一标识符
- `scene_name`：显示名称
- `map_data`：用于静态地图/关卡的 MapData 资源
- `player_spawn`：玩家配置的 PlayerSpawnData
- `spawnable_entities`：动态实体的 SpawnableEntityData 数组
- `background_music`：可选的 AudioStream
- `ambient_sound`：可选的 AudioStream
- `scene_settings`：自定义设置的字典

#### 2. SpawnableEntityData（资源）
定义可生成的实体（NPC、载具、敌人、交互物体）。

**属性：**
- `entity_type`：类型标识符（如 "enemy"、"vehicle"、"npc"）
- `scene_path`：要实例化的场景路径
- `spawn_position`：生成的世界位置
- `entity_resource`：可选的数据资源（ActorData、VehicleData 等）
- `spawn_id`：此生成点的唯一标识符
- `additional_config`：额外配置的字典

#### 3. PlayerSpawnData（资源）
定义玩家生成配置。

**属性：**
- `spawn_position`：玩家的世界位置
- `spawn_id`：此生成点的标识符
- `player_data`：玩家数据的可选覆盖

#### 4. GameScene（场景 + 脚本）
从 GameSceneData 加载的通用场景容器。

**特性：**
- 从 MapData 加载静态地图
- 在配置位置生成玩家
- 从配置生成动态实体
- 处理 UI（HUD、SystemMenu、DialoguePanel）
- 支持保存/加载
- 与 MapManager 集成进行区块加载

## 使用方法

### 创建新的游戏场景配置

#### 步骤 1：创建 GameSceneData 资源
在 `data/game_scenes/` 中创建新的 `.tres` 文件：

```gdscript
# 在 Godot 编辑器中：
# 1. 右键点击 data/game_scenes/ 文件夹
# 2. 创建新资源 > Resource
# 3. 搜索 "GameSceneData"
# 4. 在检视器中配置属性
```

#### 步骤 2：配置地图数据
引用现有的 MapData 或创建嵌入式数据：

```gdscript
# 嵌入式 MapData 示例
map_data.map_id = "forest_level"
map_data.map_name = "魔法森林"
map_data.default_spawn_position = Vector2(640, 360)
map_data.use_chunk_loading = true
map_data.chunk_scenes = {
    Vector2i(0, 0): "res://features/map/chunks/forest_0_0.tscn"
}
```

#### 步骤 3：配置玩家生成
```gdscript
player_spawn.spawn_position = Vector2(640, 360)
player_spawn.spawn_id = "main_entrance"
player_spawn.player_data = preload("res://data/actors/player/player_data.tres")
```

#### 步骤 4：添加可生成实体
点击"添加元素"来添加 SpawnableEntityData 条目：

**示例 - 生成载具：**
```gdscript
entity_type = "vehicle"
scene_path = "res://features/vehicle/base_vehicle.tscn"
spawn_position = Vector2(800, 400)
entity_resource = preload("res://data/vehicles/basic_tank_data.tres")
spawn_id = "tank_1"
additional_config = {"assigned_map_id": "main_world"}
```

**示例 - 生成敌人：**
```gdscript
entity_type = "enemy"
scene_path = "res://features/actor/base_actor.tscn"
spawn_position = Vector2(1000, 500)
entity_resource = preload("res://data/actors/enemies/head_cutter/goblin_data.tres")
spawn_id = "goblin_1"
additional_config = {}
```

**示例 - 生成 NPC：**
```gdscript
entity_type = "npc"
scene_path = "res://features/actor/base_actor.tscn"
spawn_position = Vector2(500, 300)
entity_resource = preload("res://data/actors/npcs/merchant_data.tres")
spawn_id = "merchant_1"
additional_config = {"dialogue_id": "merchant_intro"}
```

### 使用游戏场景

#### 方法 1：直接在 main.tscn 中
```gdscript
# main.tscn
[node name="GameScene" instance=ExtResource("game_scene.tscn")]
game_scene_data = ExtResource("your_game_scene_data.tres")
```

#### 方法 2：动态加载
```gdscript
# 在代码中
var game_scene_data = load("res://data/game_scenes/my_scene.tres")
var game_scene = load("res://scenes/game_scene.tscn").instantiate()
game_scene.game_scene_data = game_scene_data
get_tree().root.add_child(game_scene)
```

#### 方法 3：场景转换
```gdscript
# 更新主菜单或场景管理器
func start_game_with_scene(scene_data_path: String) -> void:
    var scene_data = load(scene_data_path)
    # 加载 main.tscn 但使用自定义场景数据
    # 实现取决于您的转换系统
```

## API 参考

### GameScene 公共方法

```gdscript
# 获取玩家实例
func get_player() -> Node2D

# 通过 spawn_id 获取生成的实体
func get_entity(spawn_id: String) -> Node

# 获取所有生成的实体
func get_all_entities() -> Array

# 保存游戏场景状态
func save_data() -> Dictionary

# 加载游戏场景状态
func load_data(data: Dictionary) -> void
```

### 示例：访问生成的实体
```gdscript
# 在其他脚本中
var game_scene = get_node("/root/Main/GameScene")
var player = game_scene.get_player()
var tank = game_scene.get_entity("tank_1")
var all_enemies = game_scene.get_all_entities().filter(
    func(e): return e.is_in_group("enemy")
)
```

## 与现有系统集成

### MapManager
GameScene 自动与 MapManager 集成：
- 如果尚未注册，则注册地图
- 为区块加载设置 map_parent
- 在场景设置时切换到配置的地图

### SaveManager
GameScene 支持保存/加载：
- 玩家位置自动保存/加载
- 如果实体实现了 `save_data()/load_data()`，则保存实体状态
- 使用 `SaveManager.is_loading_from_save()` 检查加载状态

### EventBus
GameScene 遵循现有事件模式：
- 地图更改发出 `EventBus.map_changed`
- 实体生成可以发出自定义事件
- UI 交互使用现有的事件总线信号

## 最佳实践

### 1. 实体类型命名
使用一致的实体类型名称：
- `"player"` - 玩家角色
- `"enemy"` - 敌人角色
- `"npc"` - 非玩家角色
- `"vehicle"` - 可驾驶载具
- `"interactive"` - 交互物体
- `"pickup"` - 可收集物品

### 2. 生成 ID 约定
使用描述性的生成 ID：
- `"tank_spawn_1"`、`"tank_spawn_2"` 用于载具
- `"goblin_1"`、`"goblin_2"` 用于敌人
- `"npc_merchant"`、`"npc_guard"` 用于 NPC

### 3. 场景路径组织
保持场景路径有序：
- 角色：`"res://features/actor/base_actor.tscn"`
- 载具：`"res://features/vehicle/base_vehicle.tscn"`
- 自定义：`"res://features/[类型]/[名称].tscn"`

### 4. 资源数据重用
创建可重用的实体数据：
```
data/
  actors/
    enemies/
      goblin_data.tres
      slime_data.tres
    npcs/
      merchant_data.tres
```

### 5. 附加配置使用
使用 `additional_config` 进行实体特定设置：
```gdscript
additional_config = {
    "dialogue_id": "intro_conversation",
    "quest_giver": true,
    "patrol_path": [Vector2(100, 100), Vector2(200, 100)]
}
```

## 从旧系统迁移

### 旧方法（main.tscn 硬编码实体）
```
[node name="Main"]
[node name="Player" instance=...]
[node name="Enemy1" instance=...]
[node name="Enemy2" instance=...]
```

### 新方法（GameSceneData）
```gdscript
# 创建 game_scene_data.tres
spawnable_entities = [
    { entity_type: "player", scene_path: "...", ... },
    { entity_type: "enemy", scene_path: "...", ... },
    { entity_type: "enemy", scene_path: "...", ... }
]

# main.tscn 变得简单
[node name="GameScene" instance=ExtResource("game_scene.tscn")]
game_scene_data = ExtResource("game_scene_data.tres")
```

### 优势
- 无需场景编辑即可放置实体
- 数据文件中的实体配置
- 易于创建变体（简单模式、困难模式等）
- 更好的版本控制（数据文件 vs. 场景文件）
- 对设计师友好（在检视器中编辑 .tres）

## 示例

查看以下示例配置：
- `data/game_scenes/default_game_scene.tres` - 最小示例
- `data/game_scenes/example_scene_with_entities.tres` - 带实体的完整示例

## 故障排除

### 实体未生成
1. 检查 `scene_path` 是否正确
2. 验证实体场景存在
3. 检查控制台错误消息
4. 确保 `entity_resource` 与场景兼容

### 玩家位置错误
1. 检查是否从保存加载（使用保存的位置）
2. 验证 GameSceneData 中的 `player_spawn.spawn_position`
3. 检查 `MapData.default_spawn_position` 作为后备

### 地图未加载
1. 验证 `map_data.map_id` 是唯一的
2. 检查 `chunk_scenes` 字典格式
3. 确保地图区块存在于指定路径

### 保存/加载问题
1. 实体必须实现 `save_data()/load_data()` 方法
2. 检查 `spawn_id` 对每个实体是唯一的
3. 验证 SaveManager 集成

## 未来增强

潜在改进：
- [ ] 场景预设（简单/中等/困难）
- [ ] 区域内随机实体放置
- [ ] 实体生成条件（时间、任务状态）
- [ ] 基于波次的生成
- [ ] 性能优化的动态实体剔除
- [ ] 可视化场景编辑器工具
