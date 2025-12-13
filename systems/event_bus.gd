# event_bus.gd
# A global event bus for decoupled communication between different game systems.
# This script should be configured as an Autoload singleton in Godot's project settings.
# Other nodes can connect to these signals via `EventBus.signal_name.connect(callable)`.
extends Node

# Signal emitted when any actor's health changes.
# Carries the actor node, its current health, and its max health.
signal actor_health_changed(actor: Node, current_health: int, max_health: int)

# Signal emitted when any actor dies.
# Carries the actor node that died.
signal actor_died(actor: Node)

# Signal emitted when an item is added to the player's inventory.
# Carries the ItemData resource and the quantity.
signal inventory_item_added(item_data: ItemData, quantity: int)

# Signal emitted when an item is used.
# Carries the actor, item, and success status.
signal item_used(actor: Actor, item: ItemData, success: bool)

# Signal emitted when item use fails.
# Carries the actor, item, and failure reason.
signal item_use_failed(actor: Actor, item: ItemData, reason: String)

# Signal emitted when a buff is applied.
# Carries the actor, buff_id, and duration.
signal buff_applied(actor: Actor, buff_id: String, duration: float)

# Signal emitted when a quest is triggered.
# Carries the quest_id and step.
signal quest_triggered(quest_id: String, step: int)

# Signal emitted when an area is unlocked.
# Carries the area_id.
signal area_unlocked(area_id: String)

# Signal emitted when a weapon requests a quiz reload.
# Carries the WeaponData resource.
signal request_quiz_reload(weapon_data: Resource)

# Signal emitted when a quiz is completed.
# Carries whether the quiz was answered correctly.
signal quiz_completed(success: bool)

# Add other global signals here as the game grows.
# For example:
# signal quest_started(quest_id: String)
# signal quest_completed(quest_id: String)

# NOTE: The engine will show warnings that these signals are "declared but never used."
# This is expected and normal for a global event bus. These signals are emitted from
# various game systems and are intended to be connected to by other systems (like UI)
# that will be built later.
