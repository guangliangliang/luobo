extends Node

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	_process_scene(get_tree().root)

func _on_node_added(node: Node) -> void:
	if node is Button:
		node.focus_mode = Control.FOCUS_NONE

func _process_scene(root: Node) -> void:
	for child in root.get_children():
		if child is Button:
			child.focus_mode = Control.FOCUS_NONE
		_process_scene(child)
