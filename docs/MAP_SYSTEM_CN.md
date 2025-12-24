# 地图系统文档 (Map System Documentation)

## 概述
游戏现在支持多个地图/关卡，并根据地图分配自动生成载具。该系统采用数据驱动设计，可以轻松创建新地图而无需更改代码。

## 核心功能

### 1. 默认初始地图
- 新游戏时自动加载 `main_world` 地图
- 玩家在地图的默认生成点出生
- 在 `MapManager._initialize_available_maps()` 中配置

### 2. 地图切换
- 使用 `MapManager.switch_to_map(map_id, spawn_position)` 切换地图
- 自动卸载当前地图块并加载新地图
- 发出 `EventBus.map_changed` 信号通知其他系统

### 3. 地图特定保存
- 保存时记录当前地图ID
- 保存玩家在每个地图的位置
- 加载时恢复正确的地图和玩家位置

### 4. 载具-地图绑定
- 载具可以绑定到特定地图
- 只在对应地图中显示和激活
- 载具位置随保存文件持久化

## 架构说明

### MapData 资源类
`data/definitions/system/map_data.gd`

定义地图配置：
- `map_id`: 唯一标识符（如 "main_world"）
- `map_name`: 显示名称
- `map_description`: 描述文本
- `chunk_scenes`: 地图块坐标到场景路径的字典
- `default_spawn_position`: 玩家默认生成位置
- `use_chunk_loading`: 是否使用分块加载

### MapManager 单例
`systems/map_manager.gd`

全局管理器功能：
- 维护所有可用地图的注册表
- 跟踪当前活动地图
- 处理地图块的加载/卸载
- 保存/加载地图状态
- 在地图切换时发出信号

### Vehicle 载具系统
`features/vehicle/base_vehicle.gd`

载具地图绑定：
- `assigned_map_id` 属性指定载具所属地图
- 空值 = 在所有地图中可用
- 不在当前地图时自动隐藏和禁用
- 位置随保存文件保存

## 使用方法

### 创建新地图

#### 步骤 1: 创建地图场景
在 `features/map/chunks/` 中创建地图块场景

#### 步骤 2: 在 MapManager 中注册地图
编辑 `systems/map_manager.gd` 的 `_initialize_available_maps()` 函数：

```gdscript
var dungeon_map = MapData.new()
dungeon_map.map_id = "dungeon_1"
dungeon_map.map_name = "地下城"
dungeon_map.map_description = "神秘的地下城"
dungeon_map.use_chunk_loading = true
dungeon_map.chunk_scenes = {
    Vector2i(0, 0): "res://features/map/chunks/dungeon_0_0.tscn"
}
dungeon_map.default_spawn_position = Vector2(640, 360)
available_maps["dungeon_1"] = dungeon_map
```

#### 步骤 3: 绑定载具到地图
在场景编辑器中：
1. 选择 Vehicle 节点
2. 设置 `assigned_map_id` 属性为地图ID（如 "main_world"）
3. 载具只会在该地图中出现

#### 步骤 4: 切换地图
从任何脚本调用：

```gdscript
# 切换到地下城
MapManager.switch_to_map("dungeon_1")

# 切换并指定生成位置
MapManager.switch_to_map("dungeon_1", Vector2(100, 100))
```

### 创建传送门/门

参考示例：`features/map/example_map_portal.gd`

```gdscript
extends Area2D

@export var target_map_id: String = "dungeon_1"
@export var target_spawn_position: Vector2 = Vector2(640, 360)

func _on_body_entered(body):
    if body.is_in_group("player"):
        MapManager.switch_to_map(target_map_id, target_spawn_position)
        body.global_position = target_spawn_position
```

## 保存/加载机制

### 保存的内容
- 当前地图ID
- 玩家在每个地图的位置
- 载具位置和地图分配
- 已加载的地图块

### 加载流程
1. SaveManager 从保存文件加载地图ID
2. MapManager 切换到保存的地图
3. 玩家在保存的位置出生（新游戏使用地图默认位置）
4. 载具仅在其分配的地图中显示

## 测试

运行 `tests/map_switching_test.tscn` 验证：
- 地图注册功能
- 保存/加载功能
- MapData 序列化
- 默认地图初始化

## API 参考

### MapManager 方法

```gdscript
# 注册新地图
MapManager.register_map(map_data: MapData) -> void

# 通过ID获取地图数据
MapManager.get_map_data(map_id: String) -> MapData

# 切换到不同地图
MapManager.switch_to_map(map_id: String, spawn_position: Vector2 = Vector2.ZERO) -> bool

# 当前地图信息
MapManager.current_map_id -> String
MapManager.current_map_data -> MapData
```

### EventBus 信号

```gdscript
# 地图改变时发出
EventBus.map_changed.connect(_on_map_changed)

func _on_map_changed(map_id: String, spawn_position: Vector2):
    print("切换到地图: ", map_id)
```

## 故障排除

**载具未显示：**
- 检查 `assigned_map_id` 是否匹配当前地图
- 确保载具在 "vehicle" 组中
- 验证载具可见性未被禁用

**地图无法加载：**
- 验证地图已在 MapManager 中注册
- 检查地图块场景路径是否正确
- 确保 map_id 是唯一的

**保存/加载问题：**
- 确认载具在 "saveable" 组中
- 检查 SaveManager 在场景之前加载
- 验证 MapManager.load_data() 被调用

## 未来改进

1. **地图过渡效果**：添加淡入淡出、加载屏幕
2. **基于资源的地图**：从 .tres 文件加载 MapData
3. **动态载具生成**：仅在需要时生成载具
4. **地图预加载**：在后台加载相邻地图
5. **小地图集成**：在UI中显示当前地图
6. **地图发现**：跟踪玩家访问过的地图
