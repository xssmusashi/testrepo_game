extends CanvasLayer

@onready var player_attack_game = %PlayerAttack 
@onready var log_label = $VBoxContainer/LogPanel/Label 

# --- НОВОЕ: Ссылка на полоску здоровья врага ---
# Убедись, что в сцене battle.tscn у ProgressBar стоит Unique Name "EnemyHPBar"
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar 

@onready var attack_nodes = {
	"focus": %EnemyAttackFocus,
	"geometry_dash": %EnemyAttackGeometryDash,
	"fruit": %EnemyAttackFruitSlasher,
	"shield": %EnemyAttackShieldOrbit
}

var current_enemy_hp: int = 100
var enemy_damage: int = 10
var player_damage_to_enemy: int = 100
var active_enemy_attack = null
var attack_running := false

func _ready():
	var data = BattleManager.enemy_data
	current_enemy_hp = data["hp"]
	enemy_damage = data["damage"]
	player_damage_to_enemy = data["player_damage_to_enemy"]
	
	# --- НОВОЕ: Настройка полоски HP ---
	if enemy_hp_bar:
		enemy_hp_bar.max_value = current_enemy_hp
		enemy_hp_bar.value = current_enemy_hp
	
	if attack_nodes.has(data["attack_type"]):
		active_enemy_attack = attack_nodes[data["attack_type"]]
		if not active_enemy_attack.finished.is_connected(_on_enemy_attack_finished):
			active_enemy_attack.finished.connect(_on_enemy_attack_finished)
	else:
		print("ОШИБКА: Тип атаки '" + data["attack_type"] + "' не найден в словаре!")

	if player_attack_game:
		if not player_attack_game.attack_finished.is_connected(_on_player_attack_finished):
			player_attack_game.attack_finished.connect(_on_player_attack_finished)
	
	update_log("Появился " + data["name"] + "!")

func update_log(text: String):
	if log_label: log_label.text = text

func _on_attack_pressed():
	if attack_running: return
	attack_running = true
	disable_buttons()
	update_log("Вы атакуете...")
	player_attack_game.start()

func _on_player_attack_finished(multiplier):
	attack_running = false
	printt(player_damage_to_enemy)
	var damage_dealt = (player_damage_to_enemy / 10) * multiplayer
	current_enemy_hp -= int(damage_dealt)
	
	# --- НОВОЕ: Визуальное обновление HP ---
	if enemy_hp_bar:
		enemy_hp_bar.value = current_enemy_hp
	
	update_log("Вы нанесли " + str(int(damage_dealt)) + " урона!")
	
	if current_enemy_hp <= 0:
		_on_enemy_died()
		return

	await get_tree().create_timer(1.0).timeout
	start_enemy_turn()

func start_enemy_turn():
	if active_enemy_attack:
		disable_buttons()
		update_log("Ход врага: Жаба использует ГЕОМЕТРИ ДАШ!")
		active_enemy_attack.start({ "damage": enemy_damage, "duration": 10.0 })
	else:
		update_log("Враг не знает как атаковать...")
		enable_buttons()

func _on_enemy_attack_finished(result: Dictionary):
	enable_buttons()
	if result.get("success", false):
		update_log("Вы уклонились!")
	else:
		var dmg = result.get("damage", enemy_damage)
		update_log("Вы получили " + str(dmg) + " урона!")
		var player = get_tree().root.find_child("Player", true, false)
		if player: player.take_damage(dmg)

func _on_enemy_died():
	update_log("Враг повержен!")
	# Можно добавить анимацию исчезновения
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://main/main.tscn")

func disable_buttons():
	for btn in [$VBoxContainer/ActionsPanel/Attack, $VBoxContainer/ActionsPanel/Inventory, $VBoxContainer/ActionsPanel/Say, $VBoxContainer/ActionsPanel/Hack]:
		if btn: btn.disabled = true

func enable_buttons():
	for btn in [$VBoxContainer/ActionsPanel/Attack, $VBoxContainer/ActionsPanel/Inventory, $VBoxContainer/ActionsPanel/Say, $VBoxContainer/ActionsPanel/Hack]:
		if btn: btn.disabled = false
