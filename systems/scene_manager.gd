extends Node

var QuitOrQuitting: bool = false

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		QuitOrQuitting = true
		get_tree().quit()

func quit_game():
	QuitOrQuitting = true
	get_tree().quit()

func SwitchToScene(scene_path):
	get_tree().change_scene_to_file(scene_path)

func SwitchToSceneInstance(scene_instance):
	get_tree().root.add_child(scene_instance)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = scene_instance