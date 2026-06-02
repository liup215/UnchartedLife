## prologue_scene_02.gd
## Glucose collection mini-game
## Spawns molecules; player must collect ALL glucose molecules to win.
## Wrong sugars damage the player.
extends Node2D

const MoleculeData = preload("res://data/definitions/molecule/molecule_data.gd")
const ItemEffectData = preload("res://data/definitions/item/item_effect_data.gd")

# Signals
signal prologue_completed()

# Preload scenes
@export var molecule_scene: PackedScene

# Constants
const GAME_OVER_DELAY: float = 3.0

@export var molecule_count: int = 20
@export var glucose_percentage: float = 0.4  # 40% glucose, 60% other sugars

## Minimum distance from the center (molecules won't spawn closer than this).
@export var dead_radius: float = 450.0
## Target distance between adjacent molecules.
@export var min_molecule_spacing: float = 350.0

@onready var spawn_container: Node2D = $SpawnContainer
@onready var ui: Control = $UI/PrologueUI

var player: Actor = null
var game_over: bool = false
var victory: bool = false

# Progress tracking
var total_glucose_count: int = 0
var collected_glucose_count: int = 0

# Molecule data mapping — references MoleculeData resources in data/molecules/
var molecule_type_data: Dictionary = {
	"alpha_glucose": preload("res://data/molecules/alpha_glucose.tres"),
	"beta_glucose": preload("res://data/molecules/beta_glucose.tres"),
	"alpha_galactose": preload("res://data/molecules/alpha_galactose.tres"),
	"beta_galactose": preload("res://data/molecules/beta_galactose.tres"),
	"alpha_fructose": preload("res://data/molecules/alpha_fructose.tres"),
	"beta_fructose": preload("res://data/molecules/beta_fructose.tres"),
}

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("Player not found in scene tree!")
	
	_spawn_molecules()
	_connect_signals()
	
	# Initialize UI counter
	if ui:
		ui.update_glucose_counter(0, total_glucose_count)

func _spawn_molecules():
	if not spawn_container:
		push_error("SpawnContainer not found!")
		return
	
	var positions := _compute_spiral_positions()
	positions.shuffle()
	
	var actual_count: int = mini(molecule_count, positions.size())
	var glucose_count: int = int(actual_count * glucose_percentage)
	var other_count: int = actual_count - glucose_count
	
	total_glucose_count = glucose_count
	
	var pos_idx: int = 0
	
	# Spawn glucose molecules (split evenly between α and β anomers)
	for i in range(glucose_count):
		var is_alpha: bool = (i % 2 == 0)
		var key: String = "alpha_glucose" if is_alpha else "beta_glucose"
		var name: String = "α-Glucose" if is_alpha else "β-Glucose"
		_spawn_molecule(key, name, positions[pos_idx])
		pos_idx += 1
	
	# Spawn other sugar molecules (galactose and fructose variants)
	for i in range(other_count):
		var other_type := randi() % 4
		var key: String
		var name: String
		match other_type:
			0:
				key = "alpha_fructose"
				name = "α-Fructose"
			1:
				key = "beta_fructose"
				name = "β-Fructose"
			2:
				key = "alpha_galactose"
				name = "α-Galactose"
			3:
				key = "beta_galactose"
				name = "β-Galactose"
			_:
				key = "alpha_fructose"
				name = "α-Fructose"
		_spawn_molecule(key, name, positions[pos_idx])
		pos_idx += 1

func _spawn_molecule(molecule_key: String, display_name: String, pos: Vector2):
	if not molecule_scene:
		push_error("PrologueScene02: molecule_scene is not assigned")
		return
	
	var molecule: Molecule = molecule_scene.instantiate()
	
	var data := molecule_type_data.get(molecule_key) as MoleculeData
	if data != null:
		molecule.molecule_data = data
	else:
		push_error("PrologueScene02: Unknown molecule key '%s'" % molecule_key)
		molecule.queue_free()
		return
	
	molecule.interaction_effects = _build_interaction_effects(molecule_key)
	
	molecule.position = pos
	spawn_container.add_child(molecule)

func _build_interaction_effects(molecule_key: String) -> Array[ItemEffectData]:
	var effects: Array[ItemEffectData] = []
	
	if molecule_key in ["alpha_glucose", "beta_glucose"]:
		# Correct answer: restore ammo
		var ammo_effect := ItemEffectData.new()
		ammo_effect.effect_type = ItemEffectData.EffectType.RESTORE_RESOURCE
		ammo_effect.params = {"resource_type": "ammo", "amount": 5.0}
		effects.append(ammo_effect)
	else:
		# Wrong answer: damage player
		var damage_effect := ItemEffectData.new()
		damage_effect.effect_type = ItemEffectData.EffectType.HEAL
		damage_effect.params = {"amount": -10.0}
		effects.append(damage_effect)
	
	return effects

func _compute_spiral_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	const GOLDEN_ANGLE: float = 2.39996322972865332
	
	for i in range(molecule_count):
		var radius: float = dead_radius + min_molecule_spacing * sqrt(float(i))
		var angle: float = GOLDEN_ANGLE * float(i)
		positions.append(Vector2(radius * cos(angle), radius * sin(angle)))
	
	return positions

func _connect_signals():
	if player:
		player.actor_died.connect(_on_player_died)
	
	EventBus.molecule_collected.connect(_on_molecule_collected)

func _on_player_died():
	game_over = true
	_show_game_over_screen("You died!")

func _on_molecule_collected(mol_data: MoleculeData, is_correct: bool):
	if game_over:
		return
	
	if is_correct:
		collected_glucose_count += 1
		if ui:
			ui.update_glucose_counter(collected_glucose_count, total_glucose_count)
		
		if collected_glucose_count >= total_glucose_count:
			victory = true
			game_over = true
			_show_victory_screen()
	
	if ui:
		ui.on_molecule_collected(mol_data, is_correct)

func _show_victory_screen():
	GameLogger.info("story", "=== VICTORY ===")
	GameLogger.info("story", "All glucose molecules collected! Great job!")
	
	if ui:
		ui.show_victory()
	
	PlayerData.completed_glucose_tutorial = true
	
	await get_tree().create_timer(GAME_OVER_DELAY).timeout
	prologue_completed.emit()

func _show_game_over_screen(reason: String):
	GameLogger.info("story", "=== GAME OVER ===")
	GameLogger.info("story", "%s" % reason)
	
	if ui:
		ui.show_game_over(reason)
	
	await get_tree().create_timer(GAME_OVER_DELAY).timeout
	get_tree().reload_current_scene()
