# 血管迷宫生成器 使用指南

## 概述
`VascularMazeGenerator` 是一个独立脚本，用于生成血管主题的迷宫关卡，采用分层图（Layered Graph）方法模拟从动脉到毛细血管再到静脉的生物学血管系统。

## 快速开始

### 1. 创建新场景
1. 在 Godot 中创建一个新场景，根节点为 `Node2D`
2. 将 `vascular_maze_generator.gd` 脚本附加到根节点
3. 保存场景（例如：`vascular_level_01.tscn`）

### 2. 配置所需场景

#### 墙壁场景（上皮细胞）
创建一个简单的精灵场景作为血管壁：
1. 创建新场景，根节点为 `Sprite2D`
2. 添加纹理（例如：细胞或墙壁精灵）
3. 可选：添加 `StaticBody2D` 和 `CollisionShape2D` 以实现碰撞
4. 保存为 `epithelial_cell.tscn`

示例结构：
```
Sprite2D（根节点）
├── Texture: cell_sprite.png
└── StaticBody2D
    └── CollisionShape2D（RectangleShape2D 或 CircleShape2D）
```

#### 瓣膜场景（单向阀门）
创建一个允许单向通过的瓣膜：
1. 创建新场景，根节点为 `Area2D`
2. 添加可视化精灵
3. 添加碰撞检测
4. 附加脚本以检查玩家方向，只允许单向通过
5. 保存为 `valve.tscn`

示例结构：
```
Area2D（根节点）
├── Sprite2D（瓣膜视觉效果）
└── CollisionShape2D
```

#### 玩家出生标记（可选）
1. 添加一个 `Marker2D` 节点作为生成器的子节点
2. 命名为 "PlayerSpawn" 之类的名称
3. 将其定位在玩家应该开始的位置

### 3. 分配导出变量

在 Godot 检查器中，设置以下内容：

**场景引用：**
- `Wall Scene`：将上皮细胞场景拖到此处
- `Valve Scene`：将瓣膜场景拖到此处
- `Player Spawn Marker`：选择 Marker2D 子节点

**生成参数：**
- `Layer Count`：垂直层数（默认：8）
  - 更多层 = 更复杂的迷宫
  - 推荐范围：4-12
- `Total Length`：总水平长度（像素）（默认：5000.0）
  - 更大的值 = 更长的关卡
  - 推荐范围：3000-10000

**血管属性：**
您可以调整每种血管类型的宽度和流速：
- 动脉：宽、快速流动、无间隙
- 毛细血管：窄、慢速流动、有间隙
- 静脉：最宽、中速流动、无间隙

### 4. 运行场景

运行场景时，生成器将自动创建迷宫结构：
1. 动脉段（前 20%）
2. 毛细血管网络（中间 60%）
3. 静脉段（后 20%）
4. 终点的循环触发器

## 高级配置

### 段比例
调整总长度中每段占用的比例：
```gdscript
artery_ratio = 0.2    # 总长度的 20%
capillary_ratio = 0.6  # 总长度的 60%
vein_ratio = 0.2       # 总长度的 20%
```

### 宽度倍数
控制每种血管类型的宽度：
```gdscript
artery_width_multiplier = 1.5    # 基础宽度的 1.5 倍
capillary_width_multiplier = 0.6  # 基础宽度的 0.6 倍（更窄）
vein_width_multiplier = 2.0       # 基础宽度的 2.0 倍（最宽）
```

### 流速
调整施加给玩家的推力：
```gdscript
artery_flow_speed = 500.0      # 强推力
capillary_flow_speed = 150.0   # 轻柔推力
vein_flow_speed = 300.0        # 中等推力
```

### 墙壁间隙机制
控制毛细血管壁的间隙（进出点）：
```gdscript
capillary_gap_chance = 0.15  # 15% 的几率跳过墙壁
```
更高的值 = 更多间隙 = 更容易导航

### 墙壁间距和偏移
微调墙壁放置：
```gdscript
wall_spacing = 20.0  # 墙壁精灵之间的距离
wall_offset = 50.0   # 从路径中心到墙壁的距离
```

## 工作原理

### 分层图方法
生成器创建一个分层结构：
1. **层（Layers）**：迷宫高度上的垂直划分
2. **节点（Nodes）**：每层内的点
3. **连接（Connections）**：相邻层节点之间的路径

### 三个血管段

#### 1. 动脉（前 20%）
- **特征**：少量平行路径，大多为直线
- **节点**：稀疏（layer_count / 4 条路径）
- **连接**：直接，最少分支
- **宽度**：宽（基础宽度的 1.5 倍）
- **流速**：快（500 单位）
- **间隙**：无（实心墙）
- **瓣膜**：在分支点生成

#### 2. 毛细血管（中间 60%）
- **特征**：密集网络，复杂互连
- **节点**：多（layer_count * 3 条路径）
- **连接**：多对多，创建迷宫结构
- **宽度**：窄（基础宽度的 0.6 倍）
- **流速**：慢（150 单位）
- **间隙**：随机（15% 几率跳过墙壁）
- **目的**：主要探索/解谜区域

#### 3. 静脉（后 20%）
- **特征**：路径汇聚回单个终点
- **节点**：中等（layer_count / 3 条路径）
- **连接**：所有路径合并到中心
- **宽度**：最宽（基础宽度的 2.0 倍）
- **流速**：中等（300 单位）
- **间隙**：无（实心墙）
- **传送**：终点的循环触发器返回起点

### 墙壁生成
墙壁沿血管路径放置，使用：
1. **Curve2D**：平滑路径表示
2. **切线计算**：`sample_baked_with_rotation()` 获取路径方向
3. **垂直偏移**：墙壁放置在路径两侧
4. **旋转**：精灵旋转以对齐血管方向

### 流场
Area2D 节点创建推力：
1. 沿路径每 100 像素放置一个
2. 将流向和速度存储为元数据
3. 当玩家进入时施加力（通过 `body_entered` 信号）

### 循环机制
静脉终点的触发器将玩家传送回起点，创建无尽循环效果。

## 与玩家的集成

生成器期望玩家：
1. 在 `"player"` 组中
2. 具有以下任一方法：
   - `apply_force(force: Vector2)` 方法用于基于物理的移动
   - 是具有 `velocity` 属性的 `CharacterBody2D` 用于运动学移动

## 获得最佳效果的提示

### 视觉设计
- 使用细长的细胞精灵作为墙壁（垂直方向）
- 使瓣膜在视觉上与众不同（不同的颜色/形状）
- 为流场添加粒子效果以获得视觉反馈

### 平衡难度
- **简单关卡**：
  - layer_count = 4
  - capillary_gap_chance = 0.25
  - 较短的 total_length (3000)
- **困难关卡**：
  - layer_count = 12
  - capillary_gap_chance = 0.1
  - 较长的 total_length (10000)

### 性能
- 保持 layer_count 合理（4-12）
- 每层创建多条路径和墙壁
- 大的层数 = 许多精灵实例
- 考虑对墙壁使用 VisibleOnScreenEnabler2D

### 教育整合
添加生物学知识：
1. 沿路径放置信息标记
2. 在关键点设置测验触发器
3. 添加解释血管类型的标签
4. 流动方向的视觉指示器

## 核心特性实现说明

### 分层节点连接法
- 使用 `vessel_layers` 数组存储每层的节点
- 动脉段：少量节点，直线连接
- 毛细血管段：多节点，错综复杂的多对多连接
- 静脉段：多条路径逐渐汇聚

### 上皮细胞墙壁
- **不使用 TileMap**，而是沿路径实例化 Sprite 场景
- 使用 `Curve2D.sample_baked_with_rotation()` 计算切线
- 墙壁的 `rotation` 跟随血管方向
- 仅在毛细血管段随机跳过墙壁生成（间隙机制）

### 游戏机制
- **单向性**：在关键分叉点生成瓣膜场景
- **推力场**：沿路径生成 Area2D，模拟血流推动玩家
- **循环**：静脉终点触发器将玩家传送回起点

### 特性差异
根据血管类型自动应用不同属性：
- 动脉：宽、快、无间隙
- 毛细血管：窄、最慢、有间隙
- 静脉：最宽、慢、无间隙

## 调试

### 启用调试绘制
添加到脚本：
```gdscript
func _draw() -> void:
    # 绘制路径用于调试
    for curve in vessel_paths:
        draw_polyline(curve.get_baked_points(), Color.RED, 2.0)
```

### 控制台输出
生成器会打印：
- "Starting maze generation..."
- 段生成进度
- "Maze generation complete!"
- 创建的总路径数
- 起点/终点位置

### 常见问题

**墙壁未出现：**
- 检查 `wall_scene` 是否已分配
- 验证墙壁场景有 Sprite2D 根节点
- 检查 wall_spacing 是否过大

**无碰撞：**
- 确保墙壁场景有 StaticBody2D + CollisionShape2D
- 检查项目设置中的碰撞层/掩码

**流动不起作用：**
- 验证玩家在 "player" 组中
- 检查玩家移动实现
- 确保正在创建流场（检查节点树）

**瓣膜未生成：**
- 在检查器中分配 valve_scene
- 检查 valve_scene 不为空

## 示例场景设置

```
VascularLevel (Node2D) [附加 vascular_maze_generator.gd]
├── PlayerSpawn (Marker2D)
└── [运行时生成的内容显示在这里]
    ├── WallSprite1 (Sprite2D)
    ├── WallSprite2 (Sprite2D)
    ├── ...
    ├── FlowField1 (Area2D)
    ├── FlowField2 (Area2D)
    ├── ...
    ├── Valve1 (Area2D)
    └── LoopTrigger (Area2D)
```

## 扩展生成器

### 自定义段类型
通过以下方式添加新的血管类型：
1. 添加到 `SegmentType` 枚举
2. 在 `_get_segment_properties()` 中添加 case
3. 使用新类型调用 `_build_vessel_segment()`

### 附加功能
考虑添加：
- 沿路径的敌人生成点
- 毛细血管中的物品拾取
- 瓣膜处的分支谜题
- 基于流量的动态宽度
- 视觉效果（脉动、流动粒子）
- 不同段的音频提示

## 技术要求

### 代码结构
- **继承自**：`Node2D`
- **类名**：`VascularMazeGenerator`
- **主函数**：`generate_maze()` - 生成完整迷宫
- **辅助函数**：`_build_vessel_segment()` - 使用 Curve2D 构建段
- **编辑器模式检查**：`_ready()` 中检查 `Engine.is_editor_hint()`

### 导出变量
所有配置通过 `@export` 变量公开：
- 场景引用（墙壁、瓣膜、出生标记）
- 生成参数（层数、长度）
- 血管属性（宽度、速度）
- 墙壁属性（间距、间隙几率）

## 许可证
《未知生命的传说》项目的一部分。
