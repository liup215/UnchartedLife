# 场景转换系统

## 概述

场景转换系统提供了一种数据驱动的方法来管理游戏中的场景序列、关卡转换和教程。所有转换都通过资源文件配置，无需更改代码即可轻松创建和修改游戏流程。

## 架构

### 核心组件

1. **SceneTransitionData** - 定义单个场景转换
2. **SceneSequenceData** - 定义转换序列
3. **MainGameManager** - 基于数据执行序列

### 数据驱动流程

```
资源文件 (.tres) → MainGameManager → 场景加载 → 信号处理 → 下一场景
```

## 使用方法

### 创建场景转换

创建新的 `SceneTransitionData` 资源：

```gdscript
# 在 Godot 编辑器中：
# 1. 创建新资源 > Resource
# 2. 搜索 "SceneTransitionData"
# 3. 在检视器中配置属性
```

**属性：**
- `scene_path`: 要加载的 .tscn 文件路径
- `scene_id`: 唯一标识符
- `scene_name`: 显示名称
- `loading_image`: 加载屏幕的纹理
- `loading_text`: 加载屏幕显示的文本
- `completion_signal`: 要监听的信号名称（如 "tutorial_completed"）
- `required_condition`: 必须为 true 的 PlayerData 属性
- `is_overlay`: 场景是覆盖层 (true) 还是替换内容 (false)
- `disable_system_menu`: 在此场景期间禁用 ESC 菜单
- `loading_screen_delay`: 显示加载屏幕的时长（秒）
- `completion_flag`: 完成时设置为 true 的 PlayerData 属性

### 创建场景序列

创建新的 `SceneSequenceData` 资源：

```gdscript
# 在 Godot 编辑器中：
# 1. 创建新资源 > Resource
# 2. 搜索 "SceneSequenceData"
# 3. 向 transitions 数组添加 SceneTransitionData 元素
```

**属性：**
- `sequence_id`: 唯一标识符
- `sequence_name`: 显示名称
- `transitions`: SceneTransitionData 数组（有序）
- `auto_start`: 满足条件时是否自动启动
- `start_condition`: 要检查的 PlayerData 属性（如 "should_start_prologue"）
- `on_completion`: 序列完成时的操作
  - `CONTINUE_GAMEPLAY`: 返回正常游戏
  - `LOAD_NEXT_SEQUENCE`: 加载另一个序列
  - `CUSTOM`: 自定义处理（供将来使用）
- `next_sequence_id`: 下一个序列的 ID（使用 LOAD_NEXT_SEQUENCE 时）

### 配置 MainGameManager

将序列添加到 main.tscn 的 MainGameManager：

```gdscript
# 在 main.tscn 检视器中：
# 选择 Main 节点
# 找到 "active_sequences" 属性
# 添加您的 SceneSequenceData 资源
```

### 示例：序幕序列

参见 `data/sequences/prologue_sequence.tres` 获取完整示例。

```gdscript
# 序幕序列包含：
# 1. 显微镜教程 (prologue_scene_01)
#    - 信号: tutorial_completed
#    - 设置: completed_microscope_tutorial
# 2. 葡萄糖教程 (prologue_scene_02)
#    - 信号: prologue_completed
#    - 设置: completed_glucose_tutorial
# 3. 完成时: 继续游戏
```

## 公共 API

### MainGameManager 方法

```gdscript
# 通过编程方式启动序列
main_game_manager.start_sequence(sequence_data)

# 通过 ID 加载序列
main_game_manager.load_sequence_by_id("prologue_sequence")

# 检查当前是否在序列中
if main_game_manager.is_in_sequence():
    print("序列运行中")

# 检查是否应禁用系统菜单
if main_game_manager.should_disable_system_menu():
    print("菜单已禁用")
```

## 场景要求

### 完成信号

转换中的场景必须在完成时发出指定的信号：

```gdscript
# 在场景脚本中：
signal tutorial_completed  # 必须匹配数据中的 completion_signal

func _on_continue_pressed():
    tutorial_completed.emit()
    queue_free()  # 移除自身
```

### 标准信号

常见信号名称：
- `tutorial_completed` - 教程场景
- `level_completed` - 关卡
- `dialogue_completed` - 对话序列
- `cutscene_completed` - 过场动画

## 与 PlayerData 集成

### 条件检查

序列检查 PlayerData 属性以决定是否运行：

```gdscript
# 在 PlayerData 中：
var should_start_prologue: bool = false
var completed_microscope_tutorial: bool = false

# 在序列数据中：
start_condition = "should_start_prologue"  # 检查 PlayerData.should_start_prologue
```

### 完成标志

转换完成时，可以设置 PlayerData 标志：

```gdscript
# 在转换数据中：
completion_flag = "completed_microscope_tutorial"

# MainGameManager 将执行：
PlayerData.completed_microscope_tutorial = true
```

## 高级用法

### 链式序列

创建相互加载的多个序列：

```gdscript
# 序列 A：
on_completion = LOAD_NEXT_SEQUENCE
next_sequence_id = "sequence_b"

# 序列 B：
sequence_id = "sequence_b"
on_completion = CONTINUE_GAMEPLAY
```

### 条件加载

使用 required_condition 跳过转换：

```gdscript
# 仅当满足条件时才加载转换
required_condition = "has_special_item"

# MainGameManager 检查：
if PlayerData.has_special_item:
    load_transition()
```

### 自定义加载屏幕

每个转换可以有独特的加载屏幕内容：

```gdscript
loading_image = preload("res://assets/tutorial_01.png")
loading_text = "教程 1\n\n学习基础知识"
```

## 优势

1. **无需更改代码**：无需修改脚本即可添加新序列
2. **设计师友好**：在检视器中配置
3. **可重用**：跨序列共享转换
4. **灵活**：支持条件、链式、覆盖层
5. **可维护**：所有流程逻辑在数据文件中
6. **可测试**：易于测试单个序列

## 从旧系统迁移

### 之前（硬编码）：

```gdscript
func _start_prologue():
    var scene = load("res://prologue_01.tscn").instantiate()
    add_child(scene)
    scene.tutorial_completed.connect(_on_tutorial_done)
```

### 之后（数据驱动）：

```gdscript
# 只需在检视器中将 prologue_sequence.tres 添加到 active_sequences
# MainGameManager 自动处理一切
```

## 故障排除

**问：序列不启动**
- 检查 start_condition 在 PlayerData 中是否正确设置
- 验证 auto_start 为 true 或条件为 true
- 检查序列是否在 active_sequences 数组中

**问：场景不前进**
- 验证 completion_signal 是否匹配场景的信号名称
- 检查场景是否发出信号
- 确保场景在信号后调用 queue_free()

**问：加载屏幕不显示**
- 检查 loading_screen_delay 是否合理 (>0.1)
- 验证 loading_screen.tscn 存在且工作
- 检查纹理路径是否正确

**问：条件不工作**
- 确保属性存在于 PlayerData 中
- 检查属性名称是否完全匹配（区分大小写）
- 验证属性是否设置为正确的值

## 未来增强

- 保存/加载序列进度
- 序列分支（选择不同路径）
- 并行序列（同时多个）
- 转换动画/效果
- 进度跟踪（完成 X / Y）
