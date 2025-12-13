extends SceneTree

func _initialize() -> void:
	print("[QuestTest] Initializing test...")
	_run()

func _run() -> void:
	var manager: Node = load("res://systems/quest_manager.gd").new()
	get_root().add_child(manager)

	# Build sample quest with hierarchical objectives
	var collect := ObjectiveData.new()
	collect.type = ObjectiveData.ObjectiveType.COLLECT
	collect.params = {"item_id": "glucose", "count": 3}
	collect.target_count = 3

	var defeat := ObjectiveData.new()
	defeat.type = ObjectiveData.ObjectiveType.DEFEAT
	defeat.params = {"enemy_type": "slime", "count": 2}
	defeat.target_count = 2

	var composite := ObjectiveData.new()
	composite.policy = ObjectiveData.CompletionPolicy.ALL
	composite.sub_objectives = [collect, defeat]

	var q := QuestData.new()
	q.id = "Q_SAMPLE"
	q.title_key = "QUEST_SAMPLE_TITLE"
	q.desc_key = "QUEST_SAMPLE_DESC"
	q.objectives = [composite]

	manager.register_quest(q)
	manager.start_quest(q.id)

	# Advance leaf objectives via path
	# Path [0, 0] -> composite.sub_objectives[0] (collect)
	# Path [0, 1] -> composite.sub_objectives[1] (defeat)
	for i in 3:
		manager.advance_objective(q.id, [0, 0], 1)
	for i in 2:
		manager.advance_objective(q.id, [0, 1], 1)

	print("[QuestTest] Completed run. Check console for quest_completed emission.")
	quit()