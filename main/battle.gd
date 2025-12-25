extends CanvasLayer

@onready var player_attack_game = %PlayerAttack 
@onready var attack_button = $VBoxContainer/MainPanel/You/PanelContainer2/FunctionButtons/Attack
@onready var enemy_attack_geometry_dash = %EnemyAttackGeometryDash
@onready var enemy_attack_fruit_slash = %EnemyAttackFruitSlasher

@onready var inventory_button = $VBoxContainer/MainPanel/You/PanelContainer2/FunctionButtons/Inventory
@onready var say_button = $VBoxContainer/MainPanel/You/PanelContainer2/FunctionButtons/Say
@onready var hack_button = $VBoxContainer/MainPanel/You/PanelContainer2/FunctionButtons/Hack
@onready var inventory_ui = $VBoxContainer/InventoryUI

@onready var enemy_attack = enemy_attack_fruit_slash

# ОБЯЗАТЕЛЬНО: объявляем переменную, чтобы не было ошибки "not declared"
var attack_running := false

func _ready():
	if enemy_attack:
		enemy_attack.finished.connect(_on_enemy_attack_finished)
	if player_attack_game:
		player_attack_game.attack_finished.connect(_on_player_attack_finished)

	if inventory_button:
		inventory_button.pressed.connect(_on_inventory_pressed)

	# Инициализация инвентаря для боя
	if inventory_ui:
		# Пытаемся найти существующий узел или создаем новый
		var battle_inv = get_node_or_null("Inventory")
		if not battle_inv:
			battle_inv = Node.new()
			battle_inv.set_script(load("res://main/inventory/inventory.gd"))
			battle_inv.name = "Inventory"
			add_child(battle_inv)
		
		inventory_ui.set_inventory(battle_inv)
		# Тестовый предмет
		if battle_inv.has_method("add_item"):
			battle_inv.add_item("potion", 3)

func _on_inventory_pressed():
	if inventory_ui:
		inventory_ui.toggle_visibility()

func _on_attack_pressed():
	if attack_running:
		return
	disable_buttons()
	attack_button.release_focus()
	player_attack_game.start()

func _on_player_attack_finished(_multiplier):
	enable_buttons()
	test_enemy_attack()

func test_enemy_attack():
	disable_buttons()
	enemy_attack.start({ "damage": 12, "duration": 12.0 })

func _on_enemy_attack_finished(result: Dictionary):
	enable_buttons()
	if result.has("damage") and int(result["damage"]) > 0:
		print("PLAYER TAKE DAMAGE: ", result["damage"])


func disable_buttons():
	inventory_button.disabled = true
	attack_button.disabled = true
	say_button.disabled = true
	hack_button.disabled = true
	
func enable_buttons():
	inventory_button.disabled = false
	attack_button.disabled = false
	say_button.disabled = false
	hack_button.disabled = false
