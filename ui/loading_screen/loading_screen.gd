extends Control

## Loading Screen
## Displays a loading screen with configurable image and text
## Supports molecule structure display for biology-themed loading screens
## Can be used during scene transitions or asset loading

signal loading_complete

const MoleculeData = preload("res://data/definitions/molecule/molecule_data.gd")

@export var loading_image: Texture2D
@export var loading_text: String = "Loading..."
@export var show_progress_bar: bool = true

@onready var center_image: TextureRect = $CenterContainer/VBoxContainer/CenterImage
@onready var molvis_container: CenterContainer = $CenterContainer/VBoxContainer/MoleculeVisualContainer
@onready var molecule_visual: Node2D = $CenterContainer/VBoxContainer/MoleculeVisualContainer/MoleculeVisual
@onready var loading_label: Label = $CenterContainer/VBoxContainer/LoadingLabel
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar

var _progress: float = 0.0
var _is_loading: bool = false

func _ready() -> void:
	# Apply exported configuration
	if loading_image and center_image:
		center_image.texture = loading_image
	
	if loading_label:
		loading_label.text = loading_text
	
	if progress_bar:
		progress_bar.visible = show_progress_bar
		progress_bar.value = 0

func set_image(image: Texture2D) -> void:
	"""Set the loading screen image"""
	loading_image = image
	if center_image:
		center_image.texture = image

func set_molecule_data(molecule_data: MoleculeData) -> void:
	"""Display a molecule structure instead of an image"""
	if molecule_data == null:
		_show_fallback_image()
		return
	
	if molecule_visual and molecule_visual.has_method("set_molecule_data"):
		molecule_visual.set_molecule_data(molecule_data)
		_show_molecule_visual()
	else:
		_show_fallback_image()

func _show_molecule_visual() -> void:
	"""Switch to molecule visual display"""
	if center_image:
		center_image.visible = false
	if molvis_container:
		molvis_container.visible = true
	# Trigger redraw
	if molecule_visual:
		molecule_visual.queue_redraw()

func _show_fallback_image() -> void:
	"""Switch back to image display (fallback)"""
	if molvis_container:
		molvis_container.visible = false
	if center_image:
		center_image.visible = true

func set_text(text: String) -> void:
	"""Set the loading screen text"""
	loading_text = text
	if loading_label:
		loading_label.text = text

func set_progress(progress: float) -> void:
	"""Update progress bar (0.0 to 1.0)"""
	_progress = clamp(progress, 0.0, 1.0)
	if progress_bar:
		progress_bar.value = _progress * 100
	
	if _progress >= 1.0:
		_on_loading_complete()

func start_loading() -> void:
	"""Start the loading process"""
	_is_loading = true
	_progress = 0.0
	visible = true
	
	if progress_bar:
		progress_bar.value = 0

func _on_loading_complete() -> void:
	"""Called when loading is complete"""
	if _is_loading:
		_is_loading = false
		loading_complete.emit()
		await get_tree().create_timer(0.5).timeout
		hide_loading_screen()

func hide_loading_screen() -> void:
	"""Hide the loading screen with fade out"""
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	visible = false
	modulate.a = 1.0

func show_loading_screen() -> void:
	"""Show the loading screen with fade in"""
	modulate.a = 0.0
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
