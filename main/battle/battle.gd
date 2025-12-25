extends CanvasLayer

@onready var player_attack_game = %PlayerAttack 
@onready var log_label = $VBoxContainer/LogPanel/Label # Узел текста лога

# Узлы атак (мини-игр)
@onready var attack_nodes = {
	"focus": %EnemyAttackFocus,
	"geometry_dash": %EnemyAttackGeometryDash,
	"fruit": %EnemyAttackFruitSlasher,
	"shield": %EnemyAttackShieldOrbit
}

var current_enemy_hp: int = 100
var enemy_damage: int = 10
var active_enemy_attack = null
var attack_running := false

func _ready():
	# 1. Загружаем данные врага
	var data = BattleManager.enemy_data
	current_enemy_hp = data["hp"]
	enemy_damage = data["damage"]
	
	# 2. Выбираем нужный узел атаки
	if attack_nodes.has(data["attack_type"]):
		active_enemy_attack = attack_nodes[data["attack_type"]]
		active_enemy_attack.finished.connect(_on_enemy_attack_finished)
	
	# 3. Подключаем игрока
	if player_attack_game:
		player_attack_game.attack_finished.connect(_on_player_attack_finished)
	
	update_log("Появился " + data["name"] + "!")

func update_log(text: String):
	if log_label: log_label.text = text

func _on_attack_pressed():
	if attack_running: return
	disable_buttons()
	update_log("Вы атакуете...")
	player_attack_game.start()

# --- ПЕРЕХОД ХОДА К ВРАГУ ---
func _on_player_attack_finished(multiplier):
	var damage_dealt = 50 * multiplier
	current_enemy_hp -= int(damage_dealt)
	update_log("Вы нанесли " + str(int(damage_dealt)) + " урона!")
	
	if current_enemy_hp <= 0:
		_on_enemy_died()
		return

	# Ждем немного и запускаем атаку врага (ответный ход)
	await get_tree().create_timer(1.0).timeout
	start_enemy_turn()

func start_enemy_turn():
	if active_enemy_attack:
		disable_buttons()
		update_log("Ход врага: " + BattleManager.enemy_data["name"] + " атакует!")
		active_enemy_attack.start({ "damage": enemy_damage, "duration": 10.0 })

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
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://main/main.tscn")

# Методы блокировки кнопок (универсально)
func disable_buttons():
	for btn in [$VBoxContainer/ActionsPanel/Attack, $VBoxContainer/ActionsPanel/Inventory, $VBoxContainer/ActionsPanel/Say, $VBoxContainer/ActionsPanel/Hack]:
		if btn: btn.disabled = true
func enable_buttons():
	for btn in [$VBoxContainer/ActionsPanel/Attack, $VBoxContainer/ActionsPanel/Inventory, $VBoxContainer/ActionsPanel/Say, $VBoxContainer/ActionsPanel/Hack]:
		if btn: btn.disabled = false
