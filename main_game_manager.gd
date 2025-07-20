extends Node2D

@onready var system_menu = $SystemMenu

func _ready():
    # The "saveable" nodes will now claim their own data from the SaveManager
    # when they are ready. This manager no longer needs to coordinate it.
    pass

func _unhandled_input(event):
    # Using the built-in "ui_cancel" action, which is mapped to Escape by default.
    if event.is_action_pressed("ui_cancel"):
        if system_menu.visible:
            system_menu.close_menu()
        else:
            system_menu.open_menu()
