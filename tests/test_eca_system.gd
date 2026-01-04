# test_eca_system.gd
# Test script to verify ECA (Event-Condition-Action) system functionality
extends Node

# Test results tracking
var tests_passed: int = 0
var tests_failed: int = 0

func _ready() -> void:
	print("=== ECA System Test Suite ===\n")
	
	# Run tests
	test_game_action_base()
	test_game_condition_base()
	test_game_event_data()
	test_action_show_dialog()
	test_action_spawn_actor()
	test_condition_has_item()
	test_event_with_conditions()
	
	# Print summary
	print("\n=== Test Summary ===")
	print("Tests Passed: %d" % tests_passed)
	print("Tests Failed: %d" % tests_failed)
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed")
	print("====================\n")

func test_game_action_base() -> void:
	print("\n--- Test: GameAction Base Class ---")
	var action = GameAction.new()
	
	# Test that base class exists and can be instantiated
	if action:
		pass_test("GameAction instantiated")
	else:
		fail_test("GameAction failed to instantiate")
	
	# Test that execute method exists (will show error but shouldn't crash)
	action.execute(self)
	pass_test("GameAction.execute() called without crash")

func test_game_condition_base() -> void:
	print("\n--- Test: GameCondition Base Class ---")
	var condition = GameCondition.new()
	
	# Test that base class exists and can be instantiated
	if condition:
		pass_test("GameCondition instantiated")
	else:
		fail_test("GameCondition failed to instantiate")
	
	# Test that is_met method exists (will show error but shouldn't crash)
	var result = condition.is_met(self)
	if result == false:  # Base class should return false
		pass_test("GameCondition.is_met() returns false by default")
	else:
		fail_test("GameCondition.is_met() should return false")

func test_game_event_data() -> void:
	print("\n--- Test: GameEventData ---")
	var event_data = GameEventData.new()
	event_data.event_id = "test_event"
	
	# Test instantiation
	if event_data:
		pass_test("GameEventData instantiated")
	else:
		fail_test("GameEventData failed to instantiate")
	
	# Test try_execute with no conditions or actions
	var result = event_data.try_execute(self)
	if result:
		pass_test("GameEventData.try_execute() returns true with no conditions")
	else:
		fail_test("GameEventData.try_execute() should return true with no conditions")

func test_action_show_dialog() -> void:
	print("\n--- Test: ActionShowDialog ---")
	var action = ActionShowDialog.new()
	action.speaker_name = "Test Speaker"
	action.dialog_text = "Test dialog text"
	
	if action:
		pass_test("ActionShowDialog instantiated")
	else:
		fail_test("ActionShowDialog failed to instantiate")
	
	# Connect to DialogueManager to verify dialogue is started
	var signal_received = false
	var callback = func(dialogue: DialogueData, npc_id: String):
		if npc_id == "Test Speaker":
			signal_received = true
	
	EventBus.dialogue_started.connect(callback)
	action.execute(self)
	await get_tree().create_timer(0.1).timeout  # Wait for signal processing
	
	if signal_received:
		pass_test("ActionShowDialog started dialogue via DialogueManager")
	else:
		fail_test("ActionShowDialog did not start dialogue")
	
	EventBus.dialogue_started.disconnect(callback)

func test_action_spawn_actor() -> void:
	print("\n--- Test: ActionSpawnActor ---")
	var action = ActionSpawnActor.new()
	
	if action:
		pass_test("ActionSpawnActor instantiated")
	else:
		fail_test("ActionSpawnActor failed to instantiate")
	
	# Create a test marker
	var marker = Node2D.new()
	marker.name = "TestMarker"
	marker.position = Vector2(100, 200)
	add_child(marker)
	
	# Create minimal ActorData for testing
	var actor_data = ActorData.new()
	actor_data.actor_name = "Test Actor"
	
	action.actor_data = actor_data
	action.marker_id = "TestMarker"
	
	# Count children before spawn
	var children_before = get_child_count()
	
	# Execute the action
	action.execute(self)
	
	# Check if actor was spawned (should add 1 more child beyond the marker)
	await get_tree().process_frame  # Wait for instantiation
	var children_after = get_child_count()
	
	if children_after > children_before:
		pass_test("ActionSpawnActor spawned actor successfully")
	else:
		fail_test("ActionSpawnActor did not spawn actor")
	
	# Cleanup
	marker.queue_free()

func test_condition_has_item() -> void:
	print("\n--- Test: ConditionHasItem ---")
	var condition = ConditionHasItem.new()
	condition.item_id = "Test Item"
	condition.required_count = 1
	
	if condition:
		pass_test("ConditionHasItem instantiated")
	else:
		fail_test("ConditionHasItem failed to instantiate")
	
	# Test with no player (should return false)
	var result = condition.is_met(self)
	if not result:
		pass_test("ConditionHasItem returns false when no player exists")
	else:
		fail_test("ConditionHasItem should return false when no player exists")

func test_event_with_conditions() -> void:
	print("\n--- Test: GameEventData with Conditions ---")
	
	# Create an event with a condition that will fail
	var event = GameEventData.new()
	event.event_id = "conditional_event"
	
	# Add a condition that checks for an item the player doesn't have
	var condition = ConditionHasItem.new()
	condition.item_id = "Nonexistent Item"
	condition.required_count = 1
	event.conditions.append(condition)
	
	# Add an action that would execute if condition passes
	var action = ActionShowDialog.new()
	action.speaker_name = "Test"
	action.dialog_text = "This should not appear"
	event.actions.append(action)
	
	# Try to execute - should fail due to condition
	var result = event.try_execute(self)
	
	if not result:
		pass_test("GameEventData correctly blocked execution due to failed condition")
	else:
		fail_test("GameEventData should not execute when conditions fail")
	
	# Test with no conditions (should always pass)
	var event2 = GameEventData.new()
	event2.event_id = "unconditional_event"
	event2.actions.append(action)
	
	var result2 = event2.try_execute(self)
	if result2:
		pass_test("GameEventData executes when no conditions present")
	else:
		fail_test("GameEventData should execute when no conditions present")

# Helper functions
func pass_test(message: String) -> void:
	tests_passed += 1
	print("  ✓ %s" % message)

func fail_test(message: String) -> void:
	tests_failed += 1
	print("  ✗ %s" % message)
