## molecule.gd
## Interactive molecule object for the prologue scene
## Can be glucose (correct) or other sugars (incorrect)
class_name Molecule extends Node2D

enum MoleculeType {
	GLUCOSE,      # Correct answer - refills ammo
	FRUCTOSE,     # Wrong answer - damages player
	GALACTOSE,    # Wrong answer - damages player
	SUCROSE,      # Wrong answer - damages player
	LACTOSE,      # Wrong answer - damages player
	MALTOSE       # Wrong answer - damages player
}

@export var molecule_type: MoleculeType = MoleculeType.GLUCOSE
@export var molecule_name: String = "Glucose"
@export var damage_amount: int = 10  # HP damage for wrong molecules
@export var ammo_amount: int = 5     # Ammo refill for glucose

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var area_2d: Area2D = $Area2D
@onready var label: Label = $Label

var picked_up: bool = false

func _ready():
	_setup_visuals()
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.area_entered.connect(_on_area_entered)

func _setup_visuals():
	# Set color based on molecule type
	var color: Color
	match molecule_type:
		MoleculeType.GLUCOSE:
			color = Color.GREEN  # Correct answer is green
		MoleculeType.FRUCTOSE:
			color = Color.ORANGE
		MoleculeType.GALACTOSE:
			color = Color.YELLOW
		MoleculeType.SUCROSE:
			color = Color.RED
		MoleculeType.LACTOSE:
			color = Color.PURPLE
		MoleculeType.MALTOSE:
			color = Color.BLUE
	
	sprite_2d.modulate = color
	
	# Set label
	if label:
		label.text = molecule_name
		label.modulate = color

func _on_body_entered(body: Node2D):
	if picked_up:
		return
		
	if body.is_in_group("player"):
		_interact_with_player(body)

func _on_area_entered(area: Area2D):
	if picked_up:
		return
	
	# Check if it's a projectile hitting the molecule (could be used for shooting mechanics)
	if area.is_in_group("projectile"):
		pass  # Could implement shooting molecules to pick them up

func _interact_with_player(player: Node):
	picked_up = true
	
	if molecule_type == MoleculeType.GLUCOSE:
		# Correct molecule - refill ammo
		_give_ammo(player)
		EventBus.emit_signal("molecule_collected", molecule_type, true)
		_play_positive_feedback()
	else:
		# Wrong molecule - damage player
		_damage_player(player)
		EventBus.emit_signal("molecule_collected", molecule_type, false)
		_play_negative_feedback()
	
	# Visual feedback and removal
	_play_pickup_animation()
	await get_tree().create_timer(0.2).timeout
	queue_free()

func _give_ammo(player: Node):
	# Find the player's combat component and refill weapon ammo
	if player.has_node("ActorCombatComponent"):
		var combat_component = player.get_node("ActorCombatComponent")
		# Refill first weapon's ammo
		if combat_component.weapon_components.size() > 0:
			var weapon_comp = combat_component.weapon_components[0]
			if weapon_comp and weapon_comp.weapon_data:
				weapon_comp.current_ammo = min(
					weapon_comp.current_ammo + ammo_amount,
					weapon_comp.weapon_data.max_ammo
				)
				print("Glucose collected! Ammo +%d" % ammo_amount)

func _damage_player(player: Node):
	# Find player's health component and apply damage
	if player.has_node("AttributeComponent"):
		var attr_component = player.get_node("AttributeComponent")
		if attr_component.has_node("HealthComponent"):
			var health_component = attr_component.get_node("HealthComponent")
			health_component.take_damage(damage_amount)
			print("Wrong molecule! -%d HP" % damage_amount)

func _play_positive_feedback():
	# Visual feedback for correct pickup
	var tween = create_tween()
	tween.tween_property(sprite_2d, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(sprite_2d, "modulate:a", 0.0, 0.1)

func _play_negative_feedback():
	# Visual feedback for wrong pickup
	var tween = create_tween()
	tween.tween_property(sprite_2d, "modulate", Color.RED, 0.05)
	tween.tween_property(sprite_2d, "modulate:a", 0.0, 0.15)

func _play_pickup_animation():
	# Float up animation
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -30), 0.2)
