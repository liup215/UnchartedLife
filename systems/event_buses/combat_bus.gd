# combat_bus.gd
# Signals related to combat, HP, equipment, and item usage.
extends Node
class_name CombatBus

signal actor_health_changed(actor: Node, current_health: int, max_health: int)
signal actor_died(actor: Node)
signal inventory_item_added(item_data: ItemData, quantity: int)
signal item_used(actor: Actor, item: ItemData, success: bool)
signal equipment_changed(actor: Actor)
signal item_use_failed(actor: Actor, item: ItemData, reason: String)
signal buff_applied(actor: Actor, buff_id: String, duration: float)
signal weapon_out_of_ammo(item_data: ItemData)
signal request_quiz_reload(weapon_data: Resource)
signal quiz_completed(success: bool)
