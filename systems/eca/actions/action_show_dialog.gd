# action_show_dialog.gd
# Action that displays a dialog box to the player.
# Creates a dynamic DialogueData and uses DialogueManager to display it.
extends GameAction
class_name ActionShowDialog

# Name of the speaker (e.g., "NPC", "System", "Character Name")
@export var speaker_name: String = ""

# The text content to display in the dialog
@export_multiline var dialog_text: String = ""

# Optional portrait texture for the speaker
@export var portrait: Texture2D = null

# Execute the action: create dialogue and show it via DialogueManager
func execute(context: Node) -> void:
	if dialog_text.is_empty():
		push_warning("ActionShowDialog: dialog_text is empty")
		return
	
	# Create a DialogueLineData for this message
	var line_data := DialogueLineData.new()
	line_data.speaker_name = speaker_name
	line_data.text = dialog_text
	line_data.portrait = portrait
	line_data.auto_advance = false  # Require player to advance
	
	# Create a DialogueData container
	var dialogue_data := DialogueData.new()
	dialogue_data.id = "eca_dialog_" + str(Time.get_ticks_msec())  # Unique ID
	dialogue_data.lines = [line_data]
	dialogue_data.choices = []  # No choices, just a simple message
	
	# Start the dialogue through DialogueManager
	DialogueManager.start_dialogue(dialogue_data, speaker_name)
	
	print("ActionShowDialog: Showing dialog from '%s': %s" % [speaker_name, dialog_text])
