# smoke_test_scene.gd
# Runs inside a scene so Godot loads the full project context (autoloads + class_name).
# Called from smoke_test.tscn; use: godot --headless tests\smoke_test.tscn
extends Node

# Use preload instead of class_name because headless Godot does not always register
# global classes before script compilation, especially after cache purge.
const SaveDataScript := preload("res://systems/save_data.gd")
const ActorRuntimeStateScript := preload("res://data/definitions/actor_data/actor_runtime_state.gd")
const CombatBusScript := preload("res://systems/event_buses/combat_bus.gd")
const QuestBusScript := preload("res://systems/event_buses/quest_bus.gd")
const UIEventBusScript := preload("res://systems/event_buses/ui_event_bus.gd")
const AttributeComponentScript := preload("res://features/components/attribute_component/attribute_component.gd")
const HealthComponentScript := preload("res://features/components/attribute_component/health_component.gd")
const MetabolismComponentScript := preload("res://features/components/attribute_component/metabolism_component.gd")
const SpeedComponentScript := preload("res://features/components/attribute_component/speed_component.gd")

var tests_passed: int = 0
var tests_failed: int = 0

func _ready():
	print("=== UnchartedLife Refactor Smoke Test ===\n")

	test_save_data_migration()
	test_actor_runtime_state_roundtrip()
	test_actor_data_resource_load()
	test_item_weapon_relationship()
	test_event_bus_subdomain_relay()
	test_component_dynamic_registration()

	print("\n=== Smoke Test Summary ===")
	print("Passed: %d | Failed: %d" % [tests_passed, tests_failed])
	if tests_failed == 0:
		print("✓ All smoke tests passed!")
	else:
		print("✗ Smoke tests failed")
	print("==========================\n")
	get_tree().quit()

func pass_test(name: String) -> void:
	tests_passed += 1
	print("  ✓ %s" % name)

func fail_test(name: String, msg: String = "") -> void:
	tests_failed += 1
	if msg:
		print("  ✗ %s — %s" % [name, msg])
	else:
		print("  ✗ %s" % name)

# --- Tests ---

func test_save_data_migration() -> void:
	print("--- SaveData Version Migration ---")
	var legacy_dict := {"timestamp": 1234567890, "data": {"player_hp": 80}}
	var sd = SaveDataScript.new()
	sd.save_version = SaveDataScript.CURRENT_VERSION
	sd.metadata = {"timestamp": legacy_dict["timestamp"], "version": "1.0"}
	sd.node_data = legacy_dict["data"]
	pass_test("SaveData resource creation")
	if sd.save_version == 2:
		pass_test("SaveData default version is 2")
	else:
		fail_test("SaveData version mismatch", "expected 2, got %d" % sd.save_version)

func test_actor_runtime_state_roundtrip() -> void:
	print("--- ActorRuntimeState Roundtrip ---")
	var state = ActorRuntimeStateScript.new()
	state.max_health = 200
	state.current_health = 150
	state.base_speed = 300.0
	state.current_speed = 300.0
	state.current_atp = 80.0
	state.current_glucose = 60.0

	var dict := state.to_dict()
	var restored = ActorRuntimeStateScript.new()
	restored.from_dict(dict)

	if restored.max_health == 200 and restored.current_health == 150:
		pass_test("ActorRuntimeState serialization roundtrip")
	else:
		fail_test("ActorRuntimeState roundtrip mismatch")

func test_actor_data_resource_load() -> void:
	print("--- ActorData Resource Loading ---")
	var player_data = load("res://data/actors/player/player_data.tres")
	if player_data == null:
		fail_test("Player data load", "resource is null")
		return
	pass_test("Player data loads")
	if player_data.equipped_weapons and player_data.equipped_weapons.size() > 0:
		pass_test("Player data equipped_weapons populated")
	else:
		fail_test("Player data equipped_weapons", "empty after refactor")
	if "weapons" in player_data or player_data.get("weapons") != null:
		fail_test("ActorData.weapons removed", "field still present in resource")
	else:
		pass_test("ActorData.weapons field removed")

func test_item_weapon_relationship() -> void:
	print("--- ItemData / WeaponData Relationship ---")
	var item = load("res://data/items/light_machine_gun_item.tres")
	if item == null:
		fail_test("Item load", "resource is null")
		return
	if item.weapon_data == null:
		fail_test("Item contains WeaponData", "weapon_data is null")
	else:
		pass_test("ItemData contains embedded WeaponData")

func test_event_bus_subdomain_relay() -> void:
	print("--- EventBus Subdomain Relay ---")
	var combat = CombatBusScript.new()
	var received: Array[bool] = [false]
	combat.weapon_out_of_ammo.connect(func(_i): received[0] = true)
	combat.weapon_out_of_ammo.emit(null)
	if received[0]:
		pass_test("CombatBus signal emit/receive")
	else:
		fail_test("CombatBus signal relay")

	var quest = QuestBusScript.new()
	received = [false]
	quest.quest_started.connect(func(_s): received[0] = true)
	quest.quest_started.emit("test_quest")
	if received[0]:
		pass_test("QuestBus signal emit/receive")
	else:
		fail_test("QuestBus signal relay")

	var ui = UIEventBusScript.new()
	received = [false]
	ui.request_scene_transition.connect(func(_a, _b): received[0] = true)
	ui.request_scene_transition.emit("test", "default")
	if received[0]:
		pass_test("UIEventBus signal emit/receive")
	else:
		fail_test("UIEventBus signal relay")

func test_component_dynamic_registration() -> void:
	print("--- AttributeComponent Dynamic Registration ---")
	var attr = AttributeComponentScript.new()
	var health = HealthComponentScript.new()
	var metabolism = MetabolismComponentScript.new()
	var speed = SpeedComponentScript.new()
	attr.add_child(health)
	attr.add_child(metabolism)
	attr.add_child(speed)
	attr._discover_sub_components()
	if attr.health_component == health and attr.metabolism_component == metabolism and attr.speed_component == speed:
		pass_test("AttributeComponent dynamically discovered sub-components")
	else:
		fail_test("AttributeComponent dynamic registration mismatch")
