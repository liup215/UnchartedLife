extends Node
class_name ThemeManager

## BioCell 主题管理器
## 提供运行时主题应用和动态效果控制
## 使用方式：ThemeManager.apply_biocell_theme(control_node)

const BIOCELL_THEME_PATH := "res://ui/themes/biocell_theme.tres"
const BACKGROUND_SHADER := "res://ui/themes/shaders/background_pulse.gdshader"
const BORDER_SHADER := "res://ui/themes/shaders/border_glow.gdshader"

static var _theme: Theme

## 获取 BioCell 主题资源（缓存）
static func get_biocell_theme() -> Theme:
	if _theme == null:
		_theme = load(BIOCELL_THEME_PATH) as Theme
		if _theme == null:
			push_error("ThemeManager: Failed to load BioCell theme from %s" % BIOCELL_THEME_PATH)
	return _theme

## 为主题应用节点及其所有子节点应用主题
static func apply_biocell_theme(node: Control) -> void:
	var theme := get_biocell_theme()
	if theme == null:
		return
	
	node.theme = theme
	print("ThemeManager: Applied BioCell theme to %s" % node.name)

## 为节点添加动态背景效果
## 在目标节点下创建 ColorRect 作为背景层
static func add_background_effect(parent: Control, intensity: float = 0.5, speed: float = 0.15) -> void:
	var shader := load(BACKGROUND_SHADER) as Shader
	if shader == null:
		push_error("ThemeManager: Failed to load background shader")
		return
	
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("glow_intensity", intensity)
	material.set_shader_parameter("speed", speed)
	
	# 查找或创建背景层
	var bg: ColorRect
	for child in parent.get_children():
		if child is ColorRect and child.name == "BackgroundEffect":
			bg = child
			break
	
	if bg == null:
		bg = ColorRect.new()
		bg.name = "BackgroundEffect"
		parent.add_child(bg)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	bg.material = material

## 为 PanelContainer 添加发光边框效果
static func add_border_glow(panel: PanelContainer, color: Color = Color(0.96, 0.62, 0.07, 0.5), speed: float = 1.0) -> void:
	var shader := load(BORDER_SHADER) as Shader
	if shader == null:
		push_error("ThemeManager: Failed to load border shader")
		return
	
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("border_color", color)
	material.set_shader_parameter("pulse_speed", speed)
	panel.material = material

## 根据进度条类型获取对应的颜色
static func get_progress_color(type: String) -> Color:
	match type.to_lower():
		"health", "hp":
			return Color(0.0627451, 0.72549, 0.505882, 1.0)  # 翡翠绿
		"atp", "energy", "mana":
			return Color(0.231373, 0.509804, 0.956863, 1.0)  # 电蓝色
		"boss", "enemy":
			return Color(0.937255, 0.266667, 0.266667, 1.0)  # 珊瑚红
		"experience", "xp":
			return Color(0.960784, 0.615686, 0.0705882, 1.0)  # 琥珀金
		_:
			return Color(0.176471, 0.831373, 0.74902, 1.0)   # 默认青色

## 为进度条设置类型化颜色
static func style_progress_bar(bar: ProgressBar, type: String) -> void:
	var color := get_progress_color(type)
	# 创建类型特定的填充样式
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	bar.add_theme_stylebox_override("fill", style)
