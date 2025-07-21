# actor.gd
# The base script for all actors in the game (Player, Enemies, etc.).
# It provides common functionality and component references.
extends CharacterBody2D

class_name Actor

# Signals
signal actor_health_changed(current_health: int, max_health: int)
signal actor_died()
signal inventory_item_added(item_data: ItemData) # Example for future use

# Components
@onready var stats_component: StatsComponent = $StatsComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var atp_component: ATPComponent = $ATPComponent
@onready var visuals: Polygon2D = $Visuals

func _ready():
    # This function is meant to be called by child classes AFTER they have
    # assigned their specific ActorData to the stats_component.
    if stats_component.data:
        # Initialize components with data from the resource
        health_component.set_max_health(stats_component.get_max_health())
        atp_component.set_max_atp(stats_component.get_max_atp())
        
        # Connect signals from components to the actor's own signals
        health_component.health_changed.connect(
            func(current, max): actor_health_changed.emit(current, max)
        )
        health_component.died.connect(
            func(): actor_died.emit()
        )
    else:
        printerr("Actor _ready() called, but no ActorData was assigned to StatsComponent.")

# --- Public API ---

func take_damage(amount: int):
    health_component.take_damage(amount)

# --- Save/Load Interface ---
# Child classes are expected to implement these if they are saveable.

func save_data() -> Dictionary:
    # Base implementation can be extended by children
    return {
        "position_x": position.x,
        "position_y": position.y,
        "current_health": health_component.current_health
    }

func load_data(data: Dictionary):
    # Base implementation can be extended by children
    position.x = data.get("position_x", position.x)
    position.y = data.get("position_y", position.y)
    
    var loaded_health = data.get("current_health", health_component.max_health)
    health_component.current_health = loaded_health
