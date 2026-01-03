# main_scene_controller.gd
# Simple controller for main scene UI elements
extends Node2D

@onready var system_menu: Control = null
@onready var game_scene: Node2D = null

func _ready() -> void:
	# Get references to children
	system_menu = get_node_or_null("SystemMenu")
	game_scene = get_node_or_null("GameScene")
	
	if system_menu:
		print("MainSceneController: SystemMenu found")
	
	if game_scene:
		print("MainSceneController: GameScene found")

func _unhandled_input(event: InputEvent) -> void:
	"""Handle input for system menu"""
	if event.is_action_pressed("ui_cancel"):
		if system_menu:
			if system_menu.visible:
				system_menu.close_menu()
			else:
				system_menu.open_menu()
