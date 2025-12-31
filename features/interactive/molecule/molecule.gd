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

# Constants
const PICKUP_ANIMATION_DURATION: float = 0.2  # Duration of pickup animation

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
		EventBus.molecule_collected.emit(molecule_type, true)
		_play_positive_feedback()
	else:
		# Wrong molecule - damage player
		_damage_player(player)
		EventBus.molecule_collected.emit(molecule_type, false)
		_play_negative_feedback()
	
	# Visual feedback and removal
	_play_pickup_animation()
	await get_tree().create_timer(PICKUP_ANIMATION_DURATION).timeout
	queue_free()

func _give_ammo(player: Node):
	# Find the player's combat component and refill weapon ammo
	if not player.has_node("ActorCombatComponent"):
		print("Warning: Player has no ActorCombatComponent")
		return
		
	var combat_component = player.get_node("ActorCombatComponent")
	
	# Check if player has any weapons
	if combat_component.actor_weapons.is_empty():
		print("Warning: Player has no weapons equipped")
		return
	
	# Refill first weapon's ammo
	var weapon_comp = combat_component.actor_weapons[0]
	if not weapon_comp:
		print("Warning: Weapon component is null")
		return
		
	if not weapon_comp.item_data or not weapon_comp.item_data.weapon_data:
		print("Warning: Weapon has no data")
		return
	
	var max_ammo = weapon_comp.item_data.weapon_data.ammo_capacity
	weapon_comp.current_ammo = min(
		weapon_comp.current_ammo + ammo_amount,
		max_ammo
	)
	weapon_comp.ammo_updated.emit(weapon_comp.current_ammo)
	print("Glucose collected! Ammo +%d (now %d/%d)" % [ammo_amount, weapon_comp.current_ammo, max_ammo])

func _damage_player(player: Node):
	# Find player's health component and apply damage
	if not player.has_node("AttributeComponent"):
		print("Warning: Player has no AttributeComponent")
		return
		
	var attr_component = player.get_node("AttributeComponent")
	if not attr_component.health_component:
		print("Warning: Player AttributeComponent has no health_component")
		return
		
	attr_component.health_component.take_damage(damage_amount)
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
	tween.tween_property(self, "position", position + Vector2(0, -30), PICKUP_ANIMATION_DURATION)
