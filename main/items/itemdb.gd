extends Node
class_name ItemDB

# Простейшая база: руками заполняешь в инспекторе
@export var items: Array[ItemData] = []

var _map: Dictionary = {}

func _ready():
	for it in items:
		if it and it.id != "":
			_map[it.id] = it

func get_item(id: String) -> ItemData:
	return _map.get(id, null)
