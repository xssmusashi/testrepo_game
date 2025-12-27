extends Control

@export var player_path: NodePath
@onready var panel: Control = $Panel
@onready var grid: GridContainer = $Panel/GridContainer

@export var slot_scene: PackedScene # Перетащите сюда inventory_slot.tscn в инспекторе

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
	# Очищаем старые слоты
	for c in grid.get_children():
		c.queue_free()

	if not inv: return

	# Создаем ровно 12 визуальных слотов (по размеру инвентаря)
	for i in inv.size:
		var slot = slot_scene.instantiate()
		grid.add_child(slot)
		
		# Подключаем кнопку внутри слота к логике использования
		var btn = slot.get_node("Button")
		btn.pressed.connect(_on_slot_pressed.bind(i))

func _on_slot_pressed(index: int):
	# Здесь логика использования (как мы писали ранее)
	print("Нажат слот: ", index)
	var slot = inv.slots[index]
	if slot["id"] == "": return
	
	var data = ItemDb.get_item(slot["id"])
	if data and data.heal_amount > 0:
		# Применяем лечение через BattleManager (он глобальный)
		BattleManager.player_health = clamp(
			BattleManager.player_health + data.heal_amount, 
			0, BattleManager.player_max_health
		)
		
		# Уменьшаем количество предметов в инвентаре
		slot["amount"] -= 1
		if slot["amount"] <= 0:
			slot["id"] = ""
		
		inv.changed.emit() # Обновляем UI
		
		# Если мы в бою, сигнализируем об использовании
		if get_tree().current_scene.name == "Battle":
			owner.emit_signal("item_used")

func refresh():
	if not inv or not "slots" in inv: return
	
	for i in inv.size:
		if i >= grid.get_child_count(): break
		
		var slot_ui = grid.get_child(i)
		var slot_data = inv.slots[i] #
		
		# Вызываем функцию обновления внутри самого слота
		slot_ui.update_slot(slot_data["id"], slot_data["amount"])
