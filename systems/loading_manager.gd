extends Node

## Loading Manager
## Global autoload for managing loading screens
## Handles scene transitions with loading screen display

const LOADING_SCREEN_SCENE: String = "res://ui/loading_screen/loading_screen.tscn"

var loading_screen_instance: Control = null
var _is_loading: bool = false

func _ready() -> void:
	# Pre-load the loading screen scene
	_preload_loading_screen()

func _preload_loading_screen() -> void:
	"""Preload the loading screen scene"""
	var loading_scene = load(LOADING_SCREEN_SCENE)
	if loading_scene:
		loading_screen_instance = loading_scene.instantiate()
		loading_screen_instance.visible = false
		# Don't add to tree yet, will add when needed

func show_loading_screen(image: Texture2D = null, text: String = "加载中... / Loading...") -> void:
	"""Show the loading screen with optional custom image and text"""
	if not loading_screen_instance:
		_preload_loading_screen()
	
	if not loading_screen_instance:
		push_error("LoadingManager: Failed to load loading screen scene")
		return
	
	# Add to scene tree if not already added
	if not loading_screen_instance.is_inside_tree():
		get_tree().root.add_child(loading_screen_instance)
	
	# Configure the loading screen
	if image:
		loading_screen_instance.set_image(image)
	
	if text:
		loading_screen_instance.set_text(text)
	
	# Show the loading screen
	loading_screen_instance.show_loading_screen()
	_is_loading = true

func hide_loading_screen() -> void:
	"""Hide the loading screen"""
	if loading_screen_instance and loading_screen_instance.is_inside_tree():
		loading_screen_instance.hide_loading_screen()
		_is_loading = false

func set_progress(progress: float) -> void:
	"""Update loading progress (0.0 to 1.0)"""
	if loading_screen_instance:
		loading_screen_instance.set_progress(progress)

func is_loading() -> bool:
	"""Check if currently loading"""
	return _is_loading

func load_scene_with_progress(scene_path: String, custom_image: Texture2D = null, custom_text: String = "") -> void:
	"""Load a scene with progress display"""
	# Show loading screen
	var text = custom_text if custom_text else "加载场景中... / Loading scene..."
	show_loading_screen(custom_image, text)
	
	# Start loading scene
	var loader = ResourceLoader.load_threaded_request(scene_path)
	
	# Wait a frame for loading screen to show
	await get_tree().process_frame
	
	# Monitor loading progress
	while true:
		var status = ResourceLoader.load_threaded_get_status(scene_path)
		var progress = []
		status = ResourceLoader.load_threaded_get_status(scene_path, progress)
		
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# Update progress
			if progress.size() > 0:
				set_progress(progress[0])
		elif status == ResourceLoader.THREAD_LOAD_LOADED:
			# Loading complete
			set_progress(1.0)
			var scene = ResourceLoader.load_threaded_get(scene_path)
			if scene:
				# Wait for loading screen to finish
				await get_tree().create_timer(0.5).timeout
				# Change scene
				get_tree().change_scene_to_packed(scene)
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("LoadingManager: Failed to load scene: " + scene_path)
			hide_loading_screen()
			break
		
		await get_tree().process_frame
