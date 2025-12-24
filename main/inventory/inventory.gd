extends Node
class_name Inventory

signal changed

@export var size: int = 12

# Инициализируем массив сразу
var slots: Array[Dictionary] = []

func _ready():
	if slots.is_empty():
		_prepare_slots()

func _prepare_slots():
	slots.clear()
	for i in size:
		slots.append({"id": "", "amount": 0})

func add_item(id: String, amount: int = 1) -> int:
	if slots.is_empty(): _prepare_slots()
	
	if id == "" or amount <= 0:
		return amount

	var data: ItemData = ItemDb.get_item(id)
	var max_stack := data.max_stack if data else 99

	for i in slots.size():
		if slots[i]["id"] == id and slots[i]["amount"] < max_stack:
			var can_put = max_stack - int(slots[i]["amount"])
			var put = min(can_put, amount)
			slots[i]["amount"] = int(slots[i]["amount"]) + put
			amount -= put
			if amount == 0:
				changed.emit()
				return 0

	for i in slots.size():
		if slots[i]["id"] == "":
			slots[i]["id"] = id
			slots[i]["amount"] = min(max_stack, amount)
			amount -= slots[i]["amount"]
			if amount == 0:
				changed.emit()
				return 0

	changed.emit()
	return amount
