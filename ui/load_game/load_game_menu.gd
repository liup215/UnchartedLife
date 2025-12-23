extends Control

@onready var slots_container = $MarginContainer/VBoxContainer/ScrollContainer/SaveSlotsContainer
@onready var back_button = $MarginContainer/VBoxContainer/BackButton

func _ready():
    back_button.pressed.connect(_on_back_pressed)
    populate_save_slots()

func populate_save_slots():
    # Clear any existing buttons
    for child in slots_container.get_children():
        child.queue_free()
        
    var metadata_list = SaveManager.get_save_slots_metadata()
    
    if metadata_list.is_empty():
        var label = Label.new()
        label.text = "No saved games found."
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        slots_container.add_child(label)
        return

    for metadata in metadata_list:
        var button = Button.new()
        var timestamp = Time.get_datetime_string_from_unix_time(metadata.timestamp)
        button.text = "%s - %s" % [metadata.player_name, timestamp]
        button.pressed.connect(_on_slot_pressed.bind(metadata.slot_id))
        slots_container.add_child(button)

func _on_slot_pressed(slot_id: String):
    PlayerData.current_slot = slot_id
    if SaveManager.load_game(slot_id):
        get_tree().change_scene_to_file("res://scenes/main.tscn")
    else:
        # This should ideally not happen
        print("Error loading game from slot: %s" % slot_id)

func _on_back_pressed():
    get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")
