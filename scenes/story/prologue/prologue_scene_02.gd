## prologue_scene_02.gd
## Glucose identification mini-game
## Spawns molecules and manages game state
extends Node2D

# Signals
signal prologue_completed()

# Preload scenes
const MOLECULE_SCENE = preload("res://features/interactive/molecule/molecule.tscn")

# Constants
const GAME_OVER_DELAY: float = 3.0  # Seconds to wait before completing/restarting

@export var spawn_area_size: Vector2 = Vector2(1600, 900)
@export var molecule_count: int = 30
@export var glucose_percentage: float = 0.4  # 40% glucose, 60% other sugars

@onready var spawn_container: Node2D = $SpawnContainer
@onready var target_cell: TargetCell = $TargetCell
@onready var ui: Control = $UI/PrologueUI

var player: Actor = null  # Will be found in the scene tree
var game_over: bool = false
var victory: bool = false

# Molecule type mapping
var molecule_types = [
	{"type": Molecule.MoleculeType.GLUCOSE, "name": "Glucose"},
	{"type": Molecule.MoleculeType.FRUCTOSE, "name": "Fructose"},
	{"type": Molecule.MoleculeType.GALACTOSE, "name": "Galactose"},
	{"type": Molecule.MoleculeType.SUCROSE, "name": "Sucrose"},
	{"type": Molecule.MoleculeType.LACTOSE, "name": "Lactose"},
	{"type": Molecule.MoleculeType.MALTOSE, "name": "Maltose"},
]

func _ready():
	# Find the player in the scene tree (it should be in the parent Main scene)
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("Player not found in scene tree!")
	
	_setup_game()
	_spawn_molecules()
	_connect_signals()

func _setup_game():
	# Position target cell at center
	if target_cell:
		target_cell.position = Vector2(spawn_area_size.x / 2, spawn_area_size.y / 2)
	
	# Note: Player positioning is handled by the main scene, not here

func _spawn_molecules():
	if not spawn_container:
		push_error("SpawnContainer not found!")
		return
	
	var glucose_count = int(molecule_count * glucose_percentage)
	var other_count = molecule_count - glucose_count
	
	# Spawn glucose molecules
	for i in range(glucose_count):
		_spawn_molecule(Molecule.MoleculeType.GLUCOSE, "Glucose")
	
	# Spawn other sugar molecules randomly
	for i in range(other_count):
		var random_index = randi() % (molecule_types.size() - 1) + 1  # Skip glucose (index 0)
		var mol_data = molecule_types[random_index]
		_spawn_molecule(mol_data["type"], mol_data["name"])

func _spawn_molecule(type: Molecule.MoleculeType, name: String):
	var molecule = MOLECULE_SCENE.instantiate()
	
	# Set molecule properties
	molecule.molecule_type = type
	molecule.molecule_name = name
	
	# Random position, avoid center where cell is
	var position = _get_random_spawn_position()
	molecule.position = position
	
	spawn_container.add_child(molecule)

func _get_random_spawn_position() -> Vector2:
	var center = Vector2(spawn_area_size.x / 2, spawn_area_size.y / 2)
	var min_distance_from_center = 200.0  # Don't spawn too close to cell
	
	var pos = Vector2.ZERO
	var attempts = 0
	while attempts < 100:
		pos = Vector2(
			randf_range(100, spawn_area_size.x - 100),
			randf_range(100, spawn_area_size.y - 100)
		)
		
		if pos.distance_to(center) > min_distance_from_center:
			break
		attempts += 1
	
	return pos

func _connect_signals():
	if target_cell:
		target_cell.cell_healed.connect(_on_cell_healed)
		target_cell.cell_died.connect(_on_cell_died)
		target_cell.health_changed.connect(_on_cell_health_changed)
	
	if player and player.has_node("AttributeComponent"):
		var attr_comp = player.get_node("AttributeComponent")
		if attr_comp.health_component:
			attr_comp.health_component.died.connect(_on_player_died)
	
	# Connect molecule collection events
	EventBus.molecule_collected.connect(_on_molecule_collected)

func _on_cell_healed():
	victory = true
	game_over = true
	_show_victory_screen()

func _on_cell_died():
	game_over = true
	_show_game_over_screen("The cell died!")

func _on_player_died():
	game_over = true
	_show_game_over_screen("You died!")

func _on_cell_health_changed(current: int, max_hp: int, percentage: float):
	# Update UI with cell health
	if ui:
		ui.update_cell_health(current, max_hp, percentage)

func _on_molecule_collected(type: Molecule.MoleculeType, is_glucose: bool):
	# Update UI with collection feedback
	if ui:
		ui.on_molecule_collected(type, is_glucose)

func _show_victory_screen():
	print("=== VICTORY ===")
	print("Congratulations! You've healed the cell!")
	print("You successfully identified glucose and restored the cell to health.")
	
	if ui:
		ui.show_victory()
	
	# Mark as completed
	PlayerData.completed_glucose_tutorial = true
	
	# Wait then emit completion signal
	await get_tree().create_timer(GAME_OVER_DELAY).timeout
	prologue_completed.emit()

func _show_game_over_screen(reason: String):
	print("=== GAME OVER ===")
	print(reason)
	
	if ui:
		ui.show_game_over(reason)
	
	# Wait before restarting (player can try again)
	await get_tree().create_timer(GAME_OVER_DELAY).timeout
	# Restart the prologue by reloading
	get_tree().reload_current_scene()
