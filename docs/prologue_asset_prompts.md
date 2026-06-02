# 序章(Prologue) 场景图片资产生图提示词
## Prologue Asset Prompts - 针对现有场景需要的素材

---

> **使用说明**：以下提示词可直接复制到你使用的生图大模型（Midjourney/Stable Diffusion/DALL-E）中。
> 所有sprite类资产要求**透明背景**。
> 微观世界统一风格：**深色科幻生物发光风格 / Sci-fi Bioluminescent Micro-World**

---

## 1. 细胞 (Cell) - 替换现有 `cell_sprite.png`

| 资产名 | 描述 | 生图提示词 (Prompt) |
|--------|------|---------------------|
| `cell_sprite` | 濒死的细胞主体 | `A biological cell, circular shape with slight irregular organic membrane edges, dying and dim appearance, soft bioluminescent glow transitioning from red at center to darkening edges, semi-transparent cytoplasm visible inside with faint organelle silhouettes, microscopic view, top-down perspective, educational infographic style, dark background, transparent background for game sprite, isolated object, no text --ar 1:1` |
| `cell_sprite_alive` | 治疗后的健康细胞（胜利状态） | `A healthy vibrant biological cell, circular with glowing smooth membrane, bright green bioluminescent cytoplasm, active organelles visible inside (nucleus, mitochondria), full of life energy, microscopic top-down view, sci-fi bioluminescent style, transparent background, 2D game asset, isolated object --ar 1:1` |

**现有问题**：`cell_sprite.png` 是简单的圆 + modulate 染色。
**需要解决**：有机细胞膜边缘、内部半透明质感、从濒死红色到健康绿色的视觉过渡。

---

## 2. 分子 (Molecule) - 替换现有 `molecule_circle.png`

当前场景有6种分子，共用同一个 `molecule_circle.png` 白色圆遮罩，通过 `modulate` 染色区分。**需要为每种单糖生成独立的、可识别的结构图**。

| 资产名 | 对应类型 | 颜色 | 生图提示词 (Prompt) |
|--------|---------|------|---------------------|
| `mol_glucose` | 葡萄糖（正确答案） | 绿色/青绿 | `Glucose molecule, hexagonal ring pyranose structure chair conformation, 6 carbon atoms clearly visible, hydroxyl groups OH highlighted in cyan, glowing green bioluminescent aura, educational chemistry diagram style, simplified for game recognition, floating microscopic object, transparent background, 2D game sprite, no text, isolated --ar 1:1` |
| `mol_fructose` | 果糖 | 橙色 | `Fructose molecule, pentagonal furanose ring 5-carbon structure clearly distinguishable from hexagon, ketone group visible, glowing orange bioluminescent aura, educational chemistry diagram style, floating microscopic sugar molecule, transparent background, 2D game sprite, no text --ar 1:1` |
| `mol_galactose` | 半乳糖 | 黄色 | `Galactose molecule, hexagonal pyranose ring structure, C4 position hydroxyl group OH highlighted in bright yellow to show epimer difference from glucose, glowing yellow-green bioluminescent aura, educational chemistry diagram, transparent background, 2D game sprite, no text --ar 1:1` |
| `mol_sucrose` | 蔗糖 | 红色 | `Sucrose molecule, disaccharide composed of glucose and fructose units connected, compact structure, glowing red warning-danger bioluminescent aura, microscopic sugar molecule, educational style, transparent background, 2D game sprite, no text --ar 1:1` |
| `mol_lactose` | 乳糖 | 紫色 | `Lactose molecule, disaccharide milk sugar, galactose and glucose units connected, glowing purple bioluminescent aura, microscopic view, educational chemistry style, transparent background, 2D game sprite, no text --ar 1:1` |
| `mol_maltose` | 麦芽糖 | 蓝色 | `Maltose molecule, disaccharide malt sugar, two glucose units connected, glowing blue bioluminescent aura, microscopic sugar molecule, educational style, transparent background, 2D game sprite, no text --ar 1:1` |
| `mol_base_ring` | 通用环状分子底座 | 可染色 | `A simple glowing ring structure, generic sugar molecule placeholder, hexagonal soft glowing outline with energy particles inside, minimalist sci-fi style, transparent background, 2D game sprite, no text, isolated --ar 1:1` |

**现有问题**：所有分子都是 `CircleShape2D` 白色圆 + 纯色 modulate。
**需要解决**：每种分子必须有**独立的、可识别的几何结构**（六边形vs五边形）。玩家现在只能靠颜色区分，但颜色不是可靠的教育识别方式。

---

## 3. 背景 (Background) - 替换现有纯色 `ColorRect`

当前背景：`ColorRect` 纯色 `Color(0.1, 0.1, 0.15, 1)`（深蓝黑色）。

| 资产名 | 描述 | 生图提示词 (Prompt) |
|--------|------|---------------------|
| `bg_cytoplasm_dark` | 暗色细胞质背景 | `Microscopic cytoplasm interior environment, dark navy blue and deep purple gradient background, translucent floating vesicles and microtubules, scattered bioluminescent particles, soft volumetric fog, organic cellular texture, seamless tileable 2D game background, 4K, top-down perspective --ar 16:9` |
| `bg_cytoplasm_detailed` | 带远近景深的细胞质 | `Biological cell interior cross-section view, dark atmospheric background with depth layers, blurred mitochondria in background, endoplasmic reticulum traces, glowing ATP particles floating, semi-realistic sci-fi microscopy aesthetic, 2D parallax game background with 3 depth layers --ar 16:9` |

**现有问题**：纯黑背景导致玩家无法感知“微观世界”的沉浸感。
**需要解决**：提供有生物结构暗示的暗色背景，既能烘托氛围，又不会干扰前景分子识别。

---

## 4. 玩家角色 (Player) 相关视觉

当前场景使用 `player.tscn`（玩家已有sprite）。序章场景中玩家需要更明显地与“纳米探员”身份匹配。

| 资产名 | 描述 | 生图提示词 (Prompt) |
|--------|------|---------------------|
| `player_nanobot_reticle` | 准星/瞄准器 | `Sci-fi targeting crosshair, cyan glowing hexagonal reticle with rotating corner markers, HUD interface element, biological targeting system aesthetic, transparent background, 2D game UI asset, no text --ar 1:1` |
| `player_beam_heal` | 治疗射击光束 | `Green bioluminescent healing beam, particle trail with small plus signs, soft glow effect connecting shooter to target, medical nanobot injection aesthetic, transparent background, 2D VFX sprite, vertical composition --ar 1:4` |
| `player_muzzle_glucose` | 葡萄糖发射特效 | `Green glowing muzzle flash, hexagonal particle burst, energy discharge effect, sci-fi weapon firing glucose particles, transparent background, 2D VFX --ar 1:1` |

---

## 5. 粒子特效 (Particle Effects)

| 资产名 | 描述 | 生图提示词 (Prompt) |
|--------|------|---------------------|
| `fx_correct_pickup` | 正确收集特效 | `Green energy explosion burst, small hexagonal particles spreading outward, positive success effect, soft bloom glow, transparent background, 2D game VFX --ar 1:1` |
| `fx_wrong_damage` | 错误受伤特效 | `Red electric shock effect, warning sparks, damage impact with jagged edges, painful reaction visual, transparent background, 2D game VFX --ar 1:1` |
| `fx_cell_heal_pulse` | 细胞治疗脉冲 | `Green concentric circular waves expanding outward, healing pulse effect, bioluminescent energy ring, medical restoration visual, transparent background, 2D VFX --ar 1:1` |
| `fx_ambient_dust` | 环境漂浮微粒 | `Tiny soft glowing particles, cyan and yellow motes floating in microscopic fluid, ambient dust motes, slow drift motion, transparent background, 2D particle texture --ar 1:1` |

---

## 6. UI 资产 (User Interface)

| 资产名 | 描述 | 生图提示词 (Prompt) |
|--------|------|---------------------|
| `ui_panel_glass` | 玻璃质感信息面板底 | `Dark translucent glass UI panel with cyan hexagonal border pattern, subtle sci-fi HUD texture, minimal medical interface aesthetic, transparent background, 2D game UI asset --ar 3:1` |
| `ui_healthbar_bg` | 血条/能量条背景 | `Holographic progress bar frame, dark fill area with glowing edge trim, cyan and green gradient capable display, sci-fi HUD element, transparent background --ar 4:1` |
| `ui_molecule_icon_glucose` | 任务面板葡萄糖小图标 | `Tiny glucose molecule icon, simplified hexagonal ring, glowing green, 32x32 pixel clarity, transparent background, 2D game UI icon --ar 1:1` |

---

## 7. 现有场景资产完整清单对照

根据 `prologue_game.tscn` 分析，当前场景使用的资产及替换建议：

| 当前资产路径 | 当前状态 | 建议替换为新资产 |
|-------------|---------|----------------|
| `assets/sprites/cell_sprite.png` | 简单圆形，靠 `modulate` 染色 | `cell_sprite` (濒死) + `cell_sprite_alive` (治疗后) |
| `assets/sprites/molecules/molecule_circle.png` | 圆形白色Sprite，所有分子复用 | **6个独立分子资产**：`mol_glucose`, `mol_fructose`, `mol_galactose`, `mol_sucrose`, `mol_lactose`, `mol_maltose` |
| `ColorRect` (Background) | 纯色深蓝黑矩形 | `bg_cytoplasm_dark` (平铺背景图) |
| 无 | 无准星 | 新增 `player_nanobot_reticle` |
| 无 | 无射击光束 | 新增 `player_beam_heal` |

---

## 生图设置建议 (Generation Settings)

### 负面提示词 (Negative Prompt - 所有资产通用)
```
background, solid color, frame, border, text, watermark, signature, blurry, low quality, photorealistic, 3D render, cluttered, hard shadows, crowd, human, animal, landscape, text, letters
```

### 各模型参数

**Midjourney v6**：
- 生图模式：`--v 6` 或默认
- 比例：Sprite 用 `--ar 1:1`，背景用 `--ar 16:9`
- 强调：结尾加 `--no background, solid color, text, watermark`

**Stable Diffusion XL**：
- Checkpoint：`DreamShaper` / `RevAnimated` / 等写实+卡通混合
- CFG Scale：`7-9`
- 采样器：`DPM++ 2M Karras`
- **重点**：分子结构资产建议启用 **ControlNet Canny** 或 **Lineart** 控制，先手绘六边形/五边形线稿约束 AI 生成精确结构

**DALL-E 3**：
- 提示词额外加上：`"on transparent background, isolated object, 2D game asset, clean edges, no background"`
- 生成后需手动抠图至透明背景

---

## 建议生成顺序 (Priority Order)

按视觉影响力和开发依赖排序：

1. **P0 (核心)**：`mol_glucose` — 玩家交互最频繁的元素，必须一眼可识别
2. **P0 (核心)**：`mol_fructose` — 错误选项中最具迷惑性的五边形，形状对比是关键
3. **P0 (核心)**：`cell_sprite` — 场景视觉焦点，决定微观世界质感
4. **P1 (重要)**：`bg_cytoplasm_dark` — 全局氛围基底
5. **P1 (重要)**：`mol_galactose`, `mol_sucrose`, `mol_lactose`, `mol_maltose` — 错误选项分子
6. **P2 (增强)**：粒子特效 `fx_correct_pickup`, `fx_wrong_damage`, `fx_cell_heal_pulse`
7. **P2 (增强)**：UI资产 `ui_panel_glass`, `ui_healthbar_bg`

---

*生成完成后，`.png` 文件放入对应 `assets/sprites/` 路径下，`tscn` 场景中原有的 `modulate` 染色可去除，直接使用带色彩的美术资产。*
