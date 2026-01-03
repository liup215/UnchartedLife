extends Control

## Prologue Scene 01 - Microscope Learning Interface
## Educational scene teaching players how to use a microscope
## Includes focus controls, magnification selection, and brightness adjustment

# Microscope configuration
const DISTANCE_MIN: float = 0.0
const DISTANCE_MAX: float = 100.0
var target_distance: float = 51.0  # Perfect focus distance (randomized)
const FOCUS_TOLERANCE: float = 0.2  # Distance range for acceptable focus (narrowed)
const COARSE_ADJUSTMENT: float = 5.0
const FINE_ADJUSTMENT: float = 0.1
const VISIBILITY_RANGE: float = 4.0  # Range where image starts to become visible

# Magnification levels
const EYEPIECE_MAGS: Array[int] = [5, 10, 15]
const OBJECTIVE_MAGS: Array[int] = [4, 10, 40, 100]

# Specimen movement
const MOVE_STEP: float = 10.0  # Pixels per move
const MAX_OFFSET_RADIUS: float = 150.0  # Maximum distance from center

# UI references
@onready var microscope_view: Panel = $CenterContainer/MicroscopeView
@onready var view_content: ColorRect = $CenterContainer/MicroscopeView/ViewContent
@onready var blur_overlay: ColorRect = $CenterContainer/MicroscopeView/BlurOverlay
@onready var sample_image: TextureRect = $CenterContainer/MicroscopeView/ViewContent/SampleImage

# Control buttons
@onready var eyepiece_label: Label = $ControlPanel/LeftControls/EyepieceSection/EyepieceLabel
@onready var eyepiece_up: Button = $ControlPanel/LeftControls/EyepieceSection/EyepieceUp
@onready var eyepiece_down: Button = $ControlPanel/LeftControls/EyepieceSection/EyepieceDown

@onready var objective_label: Label = $ControlPanel/LeftControls/ObjectiveSection/ObjectiveLabel
@onready var objective_up: Button = $ControlPanel/LeftControls/ObjectiveSection/ObjectiveUp
@onready var objective_down: Button = $ControlPanel/LeftControls/ObjectiveSection/ObjectiveDown

@onready var coarse_focus_up: Button = $ControlPanel/LeftControls/FocusSection/CoarseUp
@onready var coarse_focus_down: Button = $ControlPanel/LeftControls/FocusSection/CoarseDown
@onready var fine_focus_up: Button = $ControlPanel/LeftControls/FocusSection/FineUp
@onready var fine_focus_down: Button = $ControlPanel/LeftControls/FocusSection/FineDown

@onready var brightness_slider: HSlider = $ControlPanel/LeftControls/BrightnessSection/BrightnessSlider
@onready var distance_label: Label = $ControlPanel/CenterControls/InfoSection/DistanceLabel
@onready var magnification_label: Label = $ControlPanel/CenterControls/InfoSection/MagnificationLabel

@onready var move_up: Button = $ControlPanel/RightControls/MovementSection/MovementControls/MoveUp
@onready var move_down: Button = $ControlPanel/RightControls/MovementSection/MovementRow3/MoveDown
@onready var move_left: Button = $ControlPanel/RightControls/MovementSection/MovementRow2/MoveLeft
@onready var move_right: Button = $ControlPanel/RightControls/MovementSection/MovementRow2/MoveRight

@onready var continue_button: Button = $ContinueButton

# State variables
var current_distance: float = 0.0
var current_eyepiece_index: int = 1  # Start with 10x
var current_objective_index: int = 1  # Start with 10x
var current_brightness: float = 0.5
var is_focused: bool = false
var specimen_offset: Vector2 = Vector2.ZERO  # Specimen position offset from center

func _randomize_target_distance() -> void:
	"""Generate a target distance that cannot be reached by coarse adjustment alone"""
	# Coarse steps are multiples of 5.0 (0, 5, 10, etc.)
	
	# Pick a random coarse step base (avoiding extremes)
	var min_step = int(DISTANCE_MIN / COARSE_ADJUSTMENT) + 1
	var max_step = int(DISTANCE_MAX / COARSE_ADJUSTMENT) - 2
	var coarse_base = randi_range(min_step, max_step) * COARSE_ADJUSTMENT
	
	# Add an offset that requires fine adjustment
	# Offset must be > FOCUS_TOLERANCE and < COARSE_ADJUSTMENT - FOCUS_TOLERANCE
	# This ensures even the closest coarse step is outside the focus tolerance
	var min_offset = FOCUS_TOLERANCE + 0.2
	var max_offset = COARSE_ADJUSTMENT - (FOCUS_TOLERANCE + 0.2)
	var offset = randf_range(min_offset, max_offset)
	
	target_distance = coarse_base + offset
	print("New target distance: ", target_distance)

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
	
	# Movement controls
	move_up.pressed.connect(_on_move_up_pressed)
	move_down.pressed.connect(_on_move_down_pressed)
	move_left.pressed.connect(_on_move_left_pressed)
	move_right.pressed.connect(_on_move_right_pressed)
	
	# Brightness control
	brightness_slider.value_changed.connect(_on_brightness_changed)
	brightness_slider.value = current_brightness * 100
	
	# Continue button
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

func _reset_distance() -> void:
	"""Reset focus distance and randomize specimen position when changing magnification"""
	current_distance = 0.0
	_randomize_target_distance()
	
	# Randomize specimen position within radius when magnification changes
	var random_angle = randf() * TAU  # Random angle in radians (0 to 2π)
	var random_distance = randf() * (MAX_OFFSET_RADIUS * 2.0)  # Random distance within extended radius
	specimen_offset = Vector2(
		cos(random_angle) * random_distance,
		sin(random_angle) * random_distance
	)

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

func _on_move_up_pressed() -> void:
	"""Move specimen up (inverted: image moves down)"""
	# Microscope inverts image, so control opposite to movement
	specimen_offset.y -= MOVE_STEP
	_update_display()

func _on_move_down_pressed() -> void:
	"""Move specimen down (inverted: image moves up)"""
	# Microscope inverts image, so control opposite to movement
	specimen_offset.y += MOVE_STEP
	_update_display()

func _on_move_left_pressed() -> void:
	"""Move specimen left (inverted: image moves right)"""
	# Microscope inverts image, so control opposite to movement
	specimen_offset.x -= MOVE_STEP
	_update_display()

func _on_move_right_pressed() -> void:
	"""Move specimen right (inverted: image moves left)"""
	# Microscope inverts image, so control opposite to movement
	specimen_offset.x += MOVE_STEP
	_update_display()

func _update_display() -> void:
	"""Update the microscope view based on current settings"""
	# Update labels
	var eyepiece_mag = EYEPIECE_MAGS[current_eyepiece_index]
	var objective_mag = OBJECTIVE_MAGS[current_objective_index]
	var total_mag = eyepiece_mag * objective_mag
	
	eyepiece_label.text = "Eyepiece: %dx" % eyepiece_mag
	objective_label.text = "Objective: %dx" % objective_mag
	magnification_label.text = "Total Mag: %dx" % total_mag
	distance_label.text = "Distance: %.1f" % current_distance
	
	# Calculate focus quality (0.0 = completely out of focus, 1.0 = perfect focus)
	var distance_from_target = abs(current_distance - target_distance)
	var focus_quality = 1.0 - clamp(distance_from_target / VISIBILITY_RANGE, 0.0, 1.0)
	
	# Calculate scale based on magnification
	# Base magnification (scale 1.0) is the lowest possible setting (20x)
	var min_mag = float(EYEPIECE_MAGS[0] * OBJECTIVE_MAGS[0])
	var scale_factor = float(total_mag) / min_mag
	
	# Calculate brightness first
	var brightness_multiplier = current_brightness * 2.0  # Scale to 0-2 range
	
	# Update blur overlay opacity (more blur when out of focus)
	# Blur overlay color should match brightness to allow white at max brightness
	if blur_overlay:
		blur_overlay.modulate = Color(
			brightness_multiplier,
			brightness_multiplier,
			brightness_multiplier,
			1.0 - focus_quality  # More visible when out of focus
		)
	
	# Update background brightness independently (ViewContent acts as backlight)
	# Brightness range: 0.0 (black) to 2.0 (pure white, overexposed)
	if view_content:
		view_content.modulate = Color(
			brightness_multiplier,
			brightness_multiplier,
			brightness_multiplier,
			1.0  # Keep alpha at 1.0 for consistent backlight
		)
	
	# Update sample image visibility based on focus only
	if sample_image:
		sample_image.modulate.a = focus_quality
		
		# Apply scaling and position
		# Set pivot to center so scaling expands from the middle
		sample_image.pivot_offset = sample_image.size / 2.0
		sample_image.scale = Vector2(scale_factor, scale_factor)
		
		# Apply specimen offset position (inverted image in microscope)
		# Scale the offset so movement speed feels consistent relative to zoom
		# Negative offset because microscope inverts the image
		sample_image.position = -specimen_offset * scale_factor
	
	# Check if properly focused
	is_focused = distance_from_target <= FOCUS_TOLERANCE
	
	# Show continue button when properly focused
	if continue_button and is_focused:
		continue_button.visible = true

func _on_continue_pressed() -> void:
	"""Continue to next scene after learning microscope basics"""
	print("Microscope tutorial complete, transitioning to main game...")
	# Set flag that microscope tutorial is completed
	PlayerData.set("completed_microscope_tutorial", true)
	SceneManager.SwitchToScene("res://scenes/main.tscn")
