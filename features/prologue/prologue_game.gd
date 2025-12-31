## prologue_game.gd
## Main game logic for the prologue scene
## Spawns molecules and manages game state
extends Node2D

# Preload scenes
const MOLECULE_SCENE = preload("res://features/interactive/molecule/molecule.tscn")

@export var spawn_area_size: Vector2 = Vector2(1600, 900)
@export var molecule_count: int = 30
@export var glucose_percentage: float = 0.4  # 40% glucose, 60% other sugars

@onready var spawn_container: Node2D = $SpawnContainer
@onready var target_cell: TargetCell = $TargetCell
@onready var player: Actor = $Player
@onready var ui: Control = $UI/PrologueUI

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
	_setup_game()
	_spawn_molecules()
	_connect_signals()

func _setup_game():
	# Position target cell at center
	if target_cell:
		target_cell.position = Vector2(spawn_area_size.x / 2, spawn_area_size.y / 2)
	
	# Position player at a safe starting location
	if player:
		player.position = Vector2(200, spawn_area_size.y / 2)

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
	
	if player and player.has_node("AttributeComponent/HealthComponent"):
		var health_comp = player.get_node("AttributeComponent/HealthComponent")
		health_comp.died.connect(_on_player_died)
	
	# Connect molecule collection events
	EventBus.connect("molecule_collected", _on_molecule_collected)

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
	
	# Pause game or transition to next scene
	await get_tree().create_timer(3.0).timeout
	_return_to_menu()

func _show_game_over_screen(reason: String):
	print("=== GAME OVER ===")
	print(reason)
	
	if ui:
		ui.show_game_over(reason)
	
	# Wait before returning to menu
	await get_tree().create_timer(3.0).timeout
	_return_to_menu()

func _return_to_menu():
	# Return to main menu
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")
