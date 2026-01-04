# action_show_dialog.gd
# Action that displays a dialog box to the player.
# Emits a signal via EventBus to trigger UI display.
extends GameAction
class_name ActionShowDialog

# Name of the speaker (e.g., "NPC", "System", "Character Name")
@export var speaker_name: String = ""

# The text content to display in the dialog
@export_multiline var dialog_text: String = ""

# Execute the action: emit signal to show dialog
func execute(context: Node) -> void:
	if dialog_text.is_empty():
		push_warning("ActionShowDialog: dialog_text is empty")
		return
	
	# Emit via EventBus for UI to catch
	# Note: This assumes a dialogue_line signal exists or we create a custom event
	# For simplicity, we'll use dialogue_event with a custom payload
	var payload: Dictionary = {
		"speaker": speaker_name,
		"text": dialog_text
	}
	EventBus.dialogue_event.emit("show_dialog", payload)
	
	print("ActionShowDialog: Showing dialog from '%s': %s" % [speaker_name, dialog_text])
