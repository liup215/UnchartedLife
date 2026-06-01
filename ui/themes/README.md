# BioCell UI Theme

## 概述

**BioCell（细胞生态）** 是专为《Uncharted Life》设计的全新UI主题，将生物显微镜下的微观世界与科幻仪器显示屏的质感完美融合。

## 设计理念

- **沉浸感**：UI本身就是游戏世界的一部分——你正在通过一台生物观测仪器观察微观世界
- **科技感**：青色荧光、半透明面板、微发光边框，模拟高精度科学仪器
- **生命力**：有机动态背景，模拟细胞质流动和生物荧光

## 色彩系统

### 主色调
| 名称 | 色值 | 用途 |
|------|------|------|
| 背景深 | `#0B1120` | 主背景色，极深蓝黑 |
| 面板底色 | `#151E32` | UI面板背景 |
| 青色荧光 | `#2DD4BF` | 按钮边框、标题、强调元素 |
| 浅白文字 | `#E2E8F0` | 正文文字 |
| 次要文字 | `#94A3B8` | 描述、提示文字 |

### 功能色
| 名称 | 色值 | 用途 |
|------|------|------|
| 翡翠绿 | `#10B981` | 生命值、正面状态 |
| 电蓝色 | `#3B82F6` | ATP/能量条 |
| 珊瑚红 | `#EF4444` | Boss血量、警告、伤害 |
| 琥珀金 | `#F59E0B` | 选中状态、聚焦 |

## 组件样式

### 按钮
- **形状**：圆角矩形 (corner_radius = 8)
- **常态**：半透明深色底 `#1E293B` + 青色细边框 (1px)
- **悬停**：边框变亮 + 微妙青色外发光 (shadow_size = 4)
- **按下**：背景加深 `#0B1120` + 内阴影
- **禁用**：灰色边框 + 50%透明度

### 面板
- **形状**：圆角 (corner_radius = 12)
- **背景**：`#0F172A` 80%透明度
- **边框**：`#1E293B` 2px
- **装饰**：顶部可选青色细线装饰条

### 进度条
- **背景槽**：深灰 `#1E293B`，圆角
- **填充**：青色渐变 `#2DD4BF` 85%透明度
- **特效**：顶部微光效果

### 标签页
- **选中**：背景提亮 + 青色底部边框 (3px)
- **未选中**：半透明深色 + 灰色文字
- **悬停**：文字变青色

### 物品槽
- **常态**：深色面板 + 暗色边框，4px圆角
- **悬停**：青色发光边框 + 外发光阴影
- **空槽**：降低透明度至30%

## 动态效果

### 背景脉冲着色器 (`background_pulse.gdshader`)
- 有机分形布朗运动 (FBM) 噪声，产生流动质感
- 青色荧光脉动，模拟生物发光
- 微妙的细胞网格图案叠加
- 可配置参数：颜色、强度、速度、缩放

### 边框发光着色器 (`border_glow.gdshader`)
- 边缘检测发光效果
- 正弦脉动动画
- 适用于面板、物品槽的重要元素

### CRT 扫描线叠加 (`crt_overlay.gdshader`)
- 经典CRT扫描线效果
- 色彩偏移 (Chromatic Aberration)
- 暗角、噪声、闪烁
- 用于特殊UI模式或复古显示器效果

## 已应用主题的场景

| 场景 | 应用内容 |
|------|----------|
| `ui/main_menu/main_menu.tscn` | 主题 + 动态背景着色器 |
| `ui/main_menu/new_game_settings.tscn` | 主题 + 边框发光着色器 |
| `ui/character_creation/character_creation.tscn` | 主题 + 动态背景着色器 |
| `ui/hud/hud.tscn` | 主题 + 边框发光材质 |
| `ui/hud/charge_display.tscn` | 主题 |
| `ui/system_menu/system_menu.tscn` | 主题 + 动态背景着色器 |
| `ui/system_menu/inventory_ui.tscn` | 主题 |
| `ui/system_menu/item_slot.tscn` | 主题 + 边框发光着色器 |
| `ui/system_menu/equipment_ui.tscn` | 主题 |
| `ui/system_menu/character_menu.tscn` | 主题 |
| `ui/dialogue/dialogue_panel.tscn` | 主题 + 边框发光着色器 |
| `ui/loading_screen/loading_screen.tscn` | 主题 + 动态背景着色器 |
| `ui/load_game/load_game_menu.tscn` | 主题 + 动态背景着色器 |
| `ui/prologue/prologue_ui.tscn` | 主题 |

## 文件结构

```
ui/themes/
├── biocell_theme.tres           # 主主题资源（字体、颜色、样式映射）
├── styles/                       # 独立样式资源
│   ├── button_normal.tres        # 按钮常态
│   ├── button_hover.tres         # 按钮悬停
│   ├── button_pressed.tres       # 按钮按下
│   ├── button_disabled.tres      # 按钮禁用
│   ├── panel_base.tres           # 基础面板
│   ├── panel_menu.tres           # 菜单面板（带发光阴影）
│   ├── progress_bar_bg.tres      # 进度条背景
│   ├── progress_bar_fill.tres    # 进度条填充
│   ├── tab_selected.tres         # 选中标签
│   ├── tab_unselected.tres       # 未选中标签
│   ├── item_slot_normal.tres     # 物品槽常态
│   └── item_slot_hover.tres      # 物品槽悬停
└── shaders/                      # GLSL着色器
    ├── background_pulse.gdshader    # 有机流动背景
    ├── border_glow.gdshader         # 边框发光
    └── crt_overlay.gdshader         # CRT扫描线效果
```

## 如何在编辑器中使用

1. 打开任意UI场景
2. 选中根节点（Control/CanvasLayer）
3. 在Inspector中设置 `Theme = biocell_theme.tres`
4. 所有子节点会自动继承主题样式

## 自定义和扩展

### 修改颜色
直接编辑 `biocell_theme.tres` 中的颜色值，或编辑 `styles/` 文件夹中的对应 `.tres` 文件。

### 添加新组件类型
在 `biocell_theme.tres` 的 `[resource]` 节中添加新类型映射，例如：
```ini
MyCustomButton/base_type = "Button"
MyCustomButton/styles/normal = ExtResource("my_custom_normal")
```

### 调整动态效果
在场景中选择带有着色器的 ColorRect 节点，修改 ShaderMaterial 的参数：
- `glow_intensity`：发光强度 (0.0 - 1.0)
- `speed`：动画速度 (0.0 - 2.0)
- `scale`：噪声缩放 (1.0 - 50.0)

## 性能考虑

- 动态着色器在低端设备上可能消耗较多GPU资源
- 建议仅在主菜单、加载界面等静态场景使用完整背景着色器
- HUD中慎用复杂着色器，可使用材质设置调低参数
