extends Control

## Loading Screen
## Displays a loading screen with configurable image and text
## Can be used during scene transitions or asset loading

signal loading_complete

@export var loading_image: Texture2D
@export var loading_text: String = "Loading..."
@export var show_progress_bar: bool = true

@onready var center_image: TextureRect = $CenterContainer/VBoxContainer/CenterImage
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
