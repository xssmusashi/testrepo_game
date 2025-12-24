extends CanvasLayer

@export var player_path: NodePath
@onready var panel: Control = $Panel
@onready var grid: GridContainer = $Panel/GridContainer

var player: Node
var inv: Inventory

func _ready():
	panel.visible = false
	player = get_node(player_path)
	inv = player.get_node("Inventory") as Inventory
	inv.changed.connect(refresh)

	_build_slots()
	refresh()

func _unhandled_input(event):
	if event.is_action_pressed("inventory"):
		panel.visible = not panel.visible
		if panel.visible:
			refresh()

func _build_slots():
	for c in grid.get_children():
		c.queue_free()

	for i in inv.size:
		var b := Button.new()
		b.custom_minimum_size = Vector2(64, 64)
		grid.add_child(b)

func refresh():
	for i in inv.size:
		var b := grid.get_child(i) as Button
		var s := inv.slots[i]
		var id := String(s["id"])
		var amount := int(s["amount"])

		if id == "":
			b.text = ""
			b.icon = null
		else:
			var data: ItemData = ItemDb.get_item(id)
			b.icon = data.icon if data else null
			b.text = str(amount)
