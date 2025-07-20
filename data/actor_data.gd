# actor_data.gd
# A custom Resource to hold the base statistical data for any actor (player, enemy, etc.).
# This allows for easy creation and modification of actor types in the editor.
class_name ActorData
extends Resource

@export var max_health: int = 100
@export var move_speed: float = 200.0

# You can add more base stats here as needed, for example:
# @export var strength: int = 10
# @export var defense: int = 5
