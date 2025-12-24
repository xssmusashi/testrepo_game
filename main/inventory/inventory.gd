extends Node
class_name Inventory

signal changed

@export var size: int = 12

# Каждый слот: { "id": String, "amount": int }
var slots: Array[Dictionary] = []

func _ready():
	slots.resize(size)
	for i in size:
		slots[i] = {"id": "", "amount": 0}

func add_item(id: String, amount: int = 1) -> int:
	# возвращает "сколько не влезло"
	if id == "" or amount <= 0:
		return amount

	var data: ItemData = ItemDb.get_item(id)
	var max_stack := data.max_stack if data else 99

	# 1) докладываем в существующие стаки
	for i in slots.size():
		if slots[i]["id"] == id and slots[i]["amount"] < max_stack:
			var can_put = max_stack - int(slots[i]["amount"])
			var put = min(can_put, amount)
			slots[i]["amount"] = int(slots[i]["amount"]) + put
			amount -= put
			if amount == 0:
				changed.emit()
				return 0

	# 2) кладём в пустые слоты
	for i in slots.size():
		if slots[i]["id"] == "":
			var put2 = min(max_stack, amount)
			slots[i]["id"] = id
			slots[i]["amount"] = put2
			amount -= put2
			if amount == 0:
				changed.emit()
				return 0

	changed.emit()
	return amount

func has_item(id: String, amount: int = 1) -> bool:
	var total := 0
	for s in slots:
		if s["id"] == id:
			total += int(s["amount"])
	return total >= amount

func remove_item(id: String, amount: int = 1) -> bool:
	if not has_item(id, amount):
		return false

	for i in slots.size():
		if slots[i]["id"] == id:
			var take = min(int(slots[i]["amount"]), amount)
			slots[i]["amount"] = int(slots[i]["amount"]) - take
			amount -= take
			if int(slots[i]["amount"]) <= 0:
				slots[i] = {"id": "", "amount": 0}
			if amount == 0:
				changed.emit()
				return true

	changed.emit()
	return true
