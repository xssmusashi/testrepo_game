extends Control

@export var player_path: NodePath
@onready var panel: Control = $Panel
@onready var grid: GridContainer = $Panel/GridContainer

# Используем тип Node, если Inventory все еще выдает ошибку парсинга
var inv: Node 

func _ready():
	panel.visible = false
	if not player_path.is_empty():
		var player = get_node_or_null(player_path)
		if player and player.has_node("Inventory"):
			set_inventory(player.get_node("Inventory"))

func set_inventory(external_inv: Node):
	inv = external_inv
	if inv:
		if not inv.changed.is_connected(refresh):
			inv.changed.connect(refresh)
		_build_slots()
		refresh()

func toggle_visibility():
	panel.visible = !panel.visible
	if panel.visible:
		refresh()

func _build_slots():
	for c in grid.get_children():
		c.queue_free()

	if not inv: return

	for i in inv.size:
		var b := Button.new()
		b.custom_minimum_size = Vector2(64, 64)
		grid.add_child(b)

func refresh():
	# Проверка на наличие слотов
	if not inv or not "slots" in inv or inv.slots.is_empty():
		return
	
	for i in inv.size:
		if i >= grid.get_child_count(): break
		
		var b = grid.get_child(i) as Button
		var s = inv.slots[i]
		var id = String(s["id"])
		var amount = int(s["amount"])

		if id == "":
			b.text = ""
			b.icon = null
		else:
			var data: ItemData = ItemDb.get_item(id)
			b.icon = data.icon if data else null
			b.text = str(amount)
