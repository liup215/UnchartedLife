extends SceneTree

func _init():
	var manager = BioBlitzManager.new()
	print("Starting JSON load test...")
	
	# Ensure the directory exists or use the one we know exists
	var path = "res://data/question_bank/"
	
	manager.load_questions_from_dir(path)
	
	print("Total questions loaded: ", manager.question_pool.size())
	
	if manager.question_pool.size() == 0:
		print("ERROR: No questions loaded. Check path and JSON files.")
	else:
		for i in range(manager.question_pool.size()):
			var q = manager.question_pool[i]
			print("\nQuestion ", i + 1, ":")
			print("  Text: ", q.question_text)
			print("  Options: ", q.options)
			print("  Correct Index: ", q.correct_option_index)
			print("  Type: ", q.type)
			
