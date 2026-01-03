extends Node2D

@onready var system_menu = $SystemMenu
@onready var game_scene: Node2D = $GameScene

func _ready():
	# GameScene handles all game/level loading (map, player, entities)
	# Main manager just coordinates UI and high-level flow
	pass

func _unhandled_input(event):
	# Using the built-in "ui_cancel" action, which is mapped to Escape by default.
	if event.is_action_pressed("ui_cancel"):
		if system_menu.visible:
			system_menu.close_menu()
		else:
			system_menu.open_menu()
