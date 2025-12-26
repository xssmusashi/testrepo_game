extends CanvasLayer

@onready var player_attack_game = %PlayerAttack 
@onready var log_label = $VBoxContainer/LogPanel/RichTextLabel 
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar # Убедись, что Unique Name включен!
@onready var player_hp_bar: ProgressBar = %PlayerHPBar

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
var player_damage_to_enemy: float = 50.0 # Базовый урон игрока

func _ready():
	var data = BattleManager.enemy_data
	current_enemy_hp = data.get("hp", 100)
	enemy_damage = data.get("damage", 10)
	
	# ИСПРАВЛЕНИЕ: Связываем строковый тип атаки с узлом из словаря
	var type = data.get("attack_type", "focus")
	if type in attack_nodes:
		active_enemy_attack = attack_nodes[type]
	
	# Настройка UI
	if enemy_hp_bar:
		enemy_hp_bar.max_value = current_enemy_hp
		enemy_hp_bar.value = current_enemy_hp
		
	# Используем глобальное здоровье вместо поиска узла Player
	if player_hp_bar:
		player_hp_bar.max_value = BattleManager.player_max_health
		player_hp_bar.value = BattleManager.player_health
	
	if not player_attack_game.attack_finished.is_connected(_on_player_attack_finished):
		player_attack_game.attack_finished.connect(_on_player_attack_finished)

	# РЕАЛИЗАЦИЯ ПЕРВОГО ХОДА
	if data.get("attack_first", false):
		disable_buttons()
		update_log("Враг нападает первым!")
		await get_tree().create_timer(1.0).timeout 
		start_enemy_turn()
	else:
		update_log("Твой ход!")
		enable_buttons()

func update_log(text: String):
	if log_label: log_label.text = text

func _on_attack_pressed():
	if attack_running: return
	attack_running = true
	disable_buttons()
	update_log("Вы атакуете...")
	player_attack_game.start()

func _on_player_attack_finished(multiplier: float): # ИСПРАВЛЕНО ИМЯ (multiplier)
	attack_running = false
	var damage_dealt = int(player_damage_to_enemy * multiplier)
	current_enemy_hp -= damage_dealt
	
	if enemy_hp_bar:
		enemy_hp_bar.value = current_enemy_hp
	
	update_log("Вы нанесли " + str(damage_dealt) + " урона!")
	
	if current_enemy_hp <= 0:
		_on_enemy_died()
	else:
		await get_tree().create_timer(1.0).timeout
		start_enemy_turn()

func start_enemy_turn():
	if active_enemy_attack:
		disable_buttons()
		update_log("Враг атакует!")
		active_enemy_attack.start({ "damage": enemy_damage, "duration": 10.0 })
	else:
		update_log("Враг в замешательстве...")
		enable_buttons()

func _on_enemy_attack_finished(result: Dictionary):
	enable_buttons()
	if result.get("success", false):
		update_log("Вы уклонились!")
	else:
		var dmg = result.get("damage", enemy_damage)
		update_log("Вы получили " + str(dmg) + " урона.")
		
		# Прямое изменение глобального HP
		BattleManager.player_health -= dmg
		if player_hp_bar:
			player_hp_bar.value = BattleManager.player_health
		
		if BattleManager.player_health <= 0:
			update_log("Вы погибли...")
			await get_tree().create_timer(1.0).timeout
			# Возвращаем HP для перезапуска (или вызываем экран смерти)
			BattleManager.player_health = BattleManager.player_max_health
			get_tree().change_scene_to_file("res://main/main.tscn")

func _on_enemy_died():
	update_log("Враг повержен!")
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://main/main.tscn")

func disable_buttons():
	for btn in [$VBoxContainer/ActionsPanel/Attack, $VBoxContainer/ActionsPanel/Inventory, $VBoxContainer/ActionsPanel/Say, $VBoxContainer/ActionsPanel/Hack]:
		if btn: btn.disabled = true

func enable_buttons():
	for btn in [$VBoxContainer/ActionsPanel/Attack, $VBoxContainer/ActionsPanel/Inventory, $VBoxContainer/ActionsPanel/Say, $VBoxContainer/ActionsPanel/Hack]:
		if btn: btn.disabled = false
