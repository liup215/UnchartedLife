extends Control

## Prologue Scene 01 - Microscope Learning Interface
## Educational scene teaching players how to use a microscope
## Includes focus controls, magnification selection, and brightness adjustment

# Microscope configuration
const DISTANCE_MIN: float = 0.0
const DISTANCE_MAX: float = 100.0
const TARGET_DISTANCE: float = 50.0  # Perfect focus distance
const FOCUS_TOLERANCE: float = 10.0  # Distance range for acceptable focus
const COARSE_ADJUSTMENT: float = 5.0
const FINE_ADJUSTMENT: float = 0.1

# Magnification levels
const EYEPIECE_MAGS: Array[int] = [5, 10, 15]
const OBJECTIVE_MAGS: Array[int] = [4, 10, 40, 100]

# UI references
@onready var microscope_view: Panel = $CenterContainer/MicroscopeView
@onready var view_content: ColorRect = $CenterContainer/MicroscopeView/ViewContent
@onready var blur_overlay: ColorRect = $CenterContainer/MicroscopeView/BlurOverlay
@onready var sample_image: TextureRect = $CenterContainer/MicroscopeView/ViewContent/SampleImage

# Control buttons
@onready var eyepiece_label: Label = $ControlPanel/EyepieceSection/EyepieceLabel
@onready var eyepiece_up: Button = $ControlPanel/EyepieceSection/EyepieceUp
@onready var eyepiece_down: Button = $ControlPanel/EyepieceSection/EyepieceDown

@onready var objective_label: Label = $ControlPanel/ObjectiveSection/ObjectiveLabel
@onready var objective_up: Button = $ControlPanel/ObjectiveSection/ObjectiveUp
@onready var objective_down: Button = $ControlPanel/ObjectiveSection/ObjectiveDown

@onready var coarse_focus_up: Button = $ControlPanel/FocusSection/CoarseUp
@onready var coarse_focus_down: Button = $ControlPanel/FocusSection/CoarseDown
@onready var fine_focus_up: Button = $ControlPanel/FocusSection/FineUp
@onready var fine_focus_down: Button = $ControlPanel/FocusSection/FineDown

@onready var brightness_slider: HSlider = $ControlPanel/BrightnessSection/BrightnessSlider
@onready var distance_label: Label = $ControlPanel/InfoSection/DistanceLabel
@onready var magnification_label: Label = $ControlPanel/InfoSection/MagnificationLabel

@onready var continue_button: Button = $ContinueButton

# State variables
var current_distance: float = 0.0
var current_eyepiece_index: int = 1  # Start with 10x
var current_objective_index: int = 1  # Start with 10x
var current_brightness: float = 0.5
var is_focused: bool = false

func _ready() -> void:
	_setup_controls()
	_reset_distance()
	_update_display()
	
	# Hide continue button until microscope is properly focused
	if continue_button:
		continue_button.visible = false
	
	EventBus.emit_signal("story_scene_entered", "prologue_01_microscope")
	print("Microscope learning interface loaded")

func _setup_controls() -> void:
	"""Setup all control button connections"""
	# Eyepiece controls
	eyepiece_up.pressed.connect(_on_eyepiece_up_pressed)
	eyepiece_down.pressed.connect(_on_eyepiece_down_pressed)
	
	# Objective controls
	objective_up.pressed.connect(_on_objective_up_pressed)
	objective_down.pressed.connect(_on_objective_down_pressed)
	
	# Focus controls
	coarse_focus_up.pressed.connect(_on_coarse_focus_up_pressed)
	coarse_focus_down.pressed.connect(_on_coarse_focus_down_pressed)
	fine_focus_up.pressed.connect(_on_fine_focus_up_pressed)
	fine_focus_down.pressed.connect(_on_fine_focus_down_pressed)
	
	# Brightness control
	brightness_slider.value_changed.connect(_on_brightness_changed)
	brightness_slider.value = current_brightness * 100
	
	# Continue button
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

func _reset_distance() -> void:
	"""Reset focus distance when changing magnification"""
	current_distance = 0.0

func _on_eyepiece_up_pressed() -> void:
	"""Increase eyepiece magnification"""
	if current_eyepiece_index < EYEPIECE_MAGS.size() - 1:
		current_eyepiece_index += 1
		_reset_distance()
		_update_display()

func _on_eyepiece_down_pressed() -> void:
	"""Decrease eyepiece magnification"""
	if current_eyepiece_index > 0:
		current_eyepiece_index -= 1
		_reset_distance()
		_update_display()

func _on_objective_up_pressed() -> void:
	"""Increase objective magnification"""
	if current_objective_index < OBJECTIVE_MAGS.size() - 1:
		current_objective_index += 1
		_reset_distance()
		_update_display()

func _on_objective_down_pressed() -> void:
	"""Decrease objective magnification"""
	if current_objective_index > 0:
		current_objective_index -= 1
		_reset_distance()
		_update_display()

func _on_coarse_focus_up_pressed() -> void:
	"""Adjust focus using coarse knob (increase distance)"""
	current_distance = clamp(current_distance + COARSE_ADJUSTMENT, DISTANCE_MIN, DISTANCE_MAX)
	_update_display()

func _on_coarse_focus_down_pressed() -> void:
	"""Adjust focus using coarse knob (decrease distance)"""
	current_distance = clamp(current_distance - COARSE_ADJUSTMENT, DISTANCE_MIN, DISTANCE_MAX)
	_update_display()

func _on_fine_focus_up_pressed() -> void:
	"""Adjust focus using fine knob (increase distance)"""
	current_distance = clamp(current_distance + FINE_ADJUSTMENT, DISTANCE_MIN, DISTANCE_MAX)
	_update_display()

func _on_fine_focus_down_pressed() -> void:
	"""Adjust focus using fine knob (decrease distance)"""
	current_distance = clamp(current_distance - FINE_ADJUSTMENT, DISTANCE_MIN, DISTANCE_MAX)
	_update_display()

func _on_brightness_changed(value: float) -> void:
	"""Adjust brightness of the microscope view"""
	current_brightness = value / 100.0
	_update_display()

func _update_display() -> void:
	"""Update the microscope view based on current settings"""
	# Update labels
	var eyepiece_mag = EYEPIECE_MAGS[current_eyepiece_index]
	var objective_mag = OBJECTIVE_MAGS[current_objective_index]
	var total_mag = eyepiece_mag * objective_mag
	
	eyepiece_label.text = "目镜 Eyepiece: %dx" % eyepiece_mag
	objective_label.text = "物镜 Objective: %dx" % objective_mag
	magnification_label.text = "总倍数 Total Mag: %dx" % total_mag
	distance_label.text = "距离 Distance: %.1f" % current_distance
	
	# Calculate focus quality (0.0 = completely out of focus, 1.0 = perfect focus)
	var distance_from_target = abs(current_distance - TARGET_DISTANCE)
	var focus_quality = 1.0 - clamp(distance_from_target / 50.0, 0.0, 1.0)
	
	# Update blur overlay opacity (more blur when out of focus)
	if blur_overlay:
		blur_overlay.modulate.a = 1.0 - focus_quality
	
	# Update background brightness independently (ViewContent acts as backlight)
	# Brightness range: 0.0 (black) to 2.0 (pure white, overexposed)
	if view_content:
		var brightness_multiplier = current_brightness * 2.0  # Scale to 0-2 range
		view_content.modulate = Color(
			brightness_multiplier,
			brightness_multiplier,
			brightness_multiplier,
			1.0  # Keep alpha at 1.0 for consistent backlight
		)
	
	# Update sample image visibility based on focus only
	if sample_image:
		sample_image.modulate.a = focus_quality
	
	# Check if properly focused
	is_focused = distance_from_target <= FOCUS_TOLERANCE
	
	# Show continue button when properly focused
	if continue_button and is_focused:
		continue_button.visible = true

func _on_continue_pressed() -> void:
	"""Continue to next scene after learning microscope basics"""
	print("Microscope tutorial complete, transitioning to main game...")
	SceneManager.SwitchToScene("res://scenes/main.tscn")
