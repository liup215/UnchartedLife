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
        health_component.died.connect(_on_death)
    else:
        printerr("Actor _ready() called, but no ActorData was assigned to StatsComponent.")

# --- Public API ---

func take_damage(amount: int):
    health_component.take_damage(amount)
    _show_damage_number(amount)

func _show_damage_number(amount: int):
    var label = Label.new()
    label.text = str(amount)
    
    # --- 关键修改：确保字体和大小 ---
    label.add_theme_font_size_override("font_size", 24)
    label.add_theme_color_override("font_color", Color.RED)
    
    label.global_position = global_position + Vector2(randf_range(-20, 20), -50)
    get_tree().get_root().add_child(label) # 添加到根节点，避免被父节点影响

    var tween = get_tree().create_tween().set_parallel() # Start a parallel tween

    # Animate vertical movement
    tween.tween_property(label, "global_position:y", label.global_position.y - 60, 1.2).set_ease(Tween.EASE_OUT)
    
    # Animate fade out
    tween.tween_property(label, "modulate:a", 0.0, 1.2).set_ease(Tween.EASE_IN)

    # Connect the finished signal to free the label
    tween.finished.connect(label.queue_free)

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

func _on_death():
    # Emit the signal for other systems to react (e.g., quest system, score manager)
    actor_died.emit()

    # 1. Disable collision
    if has_node("CollisionShape2D"):
        get_node("CollisionShape2D").set_deferred("disabled", true)

    # 2. Play death animation/effect
    var tween = create_tween()
    # Example: Fade out and shrink
    tween.set_parallel()
    tween.tween_property(self, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
    tween.tween_property(self, "scale", Vector2.ZERO, 0.5).set_ease(Tween.EASE_IN)

    # 3. Remove from scene after animation
    await tween.finished
    queue_free()
