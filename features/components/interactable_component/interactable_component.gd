extends Area2D
class_name InteractableComponent 

signal interacted(actor)

@export var interact_action: String = "interact" # Input map action name
@export var prompt_message: String = "Press E to Interact"

var current_actor: Node = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event):
	if current_actor and event.is_action_pressed(interact_action):
		interact(current_actor)

func _on_body_entered(body):
	# Assuming the player is in the "player" group or has a specific class
	# You might want to adjust this check based on your project's structure
	if body.is_in_group("player") or body.name == "Player": 
		current_actor = body
		print(prompt_message) # Temporary debug feedback

func _on_body_exited(body):
	if body == current_actor:
		current_actor = null

func interact(actor):
	interacted.emit(actor)
