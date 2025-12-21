extends Node
class_name DialogueComponent

@export var npc_id: String = ""
@export var default_dialogue: DialogueData
@export var dialogue_table: Dictionary = {} # key -> DialogueData
@export var interactable_path: NodePath
@export var auto_register: bool = true
@export var auto_start_key: String = ""

var _interactable: InteractableComponent

func _ready() -> void:
	_interactable = _find_interactable()
	if _interactable:
		_interactable.interacted.connect(_on_interacted)
	if auto_register:
		_register_dialogues()
	if not auto_start_key.is_empty():
		start_dialogue(auto_start_key)

func start_dialogue(key: String = "", context: Dictionary = {}) -> void:
	var dlg: DialogueData = dialogue_table.get(key, default_dialogue)
	if dlg == null:
		push_warning("DialogueComponent: no dialogue for key '%s'" % key)
		return
	DialogueManager.start_dialogue(dlg, npc_id, context)

func _on_interacted(actor: Node) -> void:
	var ctx := {"actor": actor}
	var key := auto_start_key if not auto_start_key.is_empty() else ""
	start_dialogue(key, ctx)

func _find_interactable() -> InteractableComponent:
	if interactable_path != NodePath(""):
		var node := get_node_or_null(interactable_path)
		return node as InteractableComponent
	if owner and owner.has_node("InteractableComponent"):
		return owner.get_node("InteractableComponent") as InteractableComponent
	if has_node("InteractableComponent"):
		return get_node("InteractableComponent") as InteractableComponent
	return null

func _register_dialogues() -> void:
	var list: Array[DialogueData] = []
	if default_dialogue:
		list.append(default_dialogue)
	for key in dialogue_table.keys():
		var dlg = dialogue_table[key]
		if dlg is DialogueData:
			list.append(dlg)
	DialogueManager.register_dialogues(list)
