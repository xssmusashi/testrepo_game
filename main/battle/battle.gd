extends CanvasLayer

@onready var player_attack_game = %PlayerAttack 
@onready var log_label = $VBoxContainer/LogPanel/RichTextLabel 
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar # Убедись, что Unique Name включен!
@onready var player_hp_bar: ProgressBar = %PlayerHPBar

@onready var instruction_label: Label = %InstructionLabel

const INSTRUCTIONS = {
	"focus": "Keep your cursor inside the circle!",
	"geometry_dash": "Press SPACE to jump!",
	"fruit": "Slice them all with your mouse!",
	"shield": "Protect yourself with your mouse!"
}

@onready var attack_nodes = {
	"focus": %EnemyAttackFocus,
	"geometry_dash": %EnemyAttackGeometryDash,
	"fruit": %EnemyAttackFruitSlasher,
	"shield": %EnemyAttackShieldOrbit
}

const DEFAULT_ATTACK = "focus"

var current_enemy_hp: int = 100
var enemy_damage: int = 10
var active_enemy_attack = null
var attack_running := false
var player_damage_to_enemy: float = 50.0 # Базовый урон игрока

func _ready():
	instruction_label.text = ""
	
	var data = BattleManager.enemy_data
	current_enemy_hp = data.get("hp", 100)
	enemy_damage = data.get("damage", 10)
	
	for attack_node in attack_nodes.values():
		if attack_node:
			# Проверяем и подключаем сигнал 'finished'
			if not attack_node.finished.is_connected(_on_enemy_attack_finished):
				attack_node.finished.connect(_on_enemy_attack_finished)
	
	# 2. Инициализируем активную атаку
	var type = data.get("attack_type", "focus")
	active_enemy_attack = attack_nodes.get(type)
	
	# 3. Настройка UI через ГЛОБАЛЬНОЕ здоровье
	if player_hp_bar:
		player_hp_bar.max_value = BattleManager.player_max_health
		player_hp_bar.value = BattleManager.player_health

	if player_attack_game:
		if player_attack_game.has_signal("finished"):
			if not player_attack_game.finished.is_connected(_on_player_attack_finished):
				player_attack_game.finished.connect(_on_player_attack_finished)
		elif player_attack_game.has_signal("attack_finished"):
			if not player_attack_game.attack_finished.is_connected(_on_player_attack_finished):
				player_attack_game.attack_finished.connect(_on_player_attack_finished)
	
	update_log("The battle begins!")

func update_log(text: String):
	if log_label: log_label.text = text

func _on_attack_pressed():
	if attack_running: return
	attack_running = true
	disable_buttons()
	update_log("You attack...")
	player_attack_game.start()

func _on_player_attack_finished(multiplier: float): # ИСПРАВЛЕНО ИМЯ (multiplier)
	attack_running = false
	var damage_dealt = int(player_damage_to_enemy * multiplier)
	current_enemy_hp -= damage_dealt
	
	if enemy_hp_bar:
		enemy_hp_bar.value = current_enemy_hp
	
	update_log("You dealed " + str(damage_dealt) + " damage!")
	
	if current_enemy_hp <= 0:
		_on_enemy_died()
	else:
		await get_tree().create_timer(1.0).timeout
		start_enemy_turn()

func start_enemy_turn():
	if active_enemy_attack:
		disable_buttons()
		update_log("Enemy is attacking!")
		
		var attack_type = BattleManager.enemy_data.get("attack_type", DEFAULT_ATTACK)
		
		instruction_label.text = INSTRUCTIONS.get(attack_type, "Watch out!")
		
		active_enemy_attack.start({ "damage": enemy_damage, "duration": 10.0 })
	else:
		update_log("The enemy is confused...")
		enable_buttons()

func _on_enemy_attack_finished(result: Dictionary):
	attack_running = false # СБРОС ФЛАГА (теперь можно снова атаковать)
	enable_buttons()
	
	instruction_label.text = ""
	
	attack_running = false
	enable_buttons()
	
	if result.get("success", false):
		update_log("You dodged!!")
	else:
		var dmg = result.get("damage", enemy_damage)
		update_log("You took " + str(dmg) + " damage.")
		
		# Наносим урон напрямую в ГЛОБАЛЬНЫЙ менеджер
		BattleManager.player_health -= dmg
		if player_hp_bar:
			player_hp_bar.value = BattleManager.player_health

func _on_enemy_died():
	update_log("The enemy is killed!")
	await get_tree().create_timer(1.5).timeout
	_on_enemy_defeated()

func _on_enemy_defeated():
	# Регистрируем победу по сохраненному ID
	var enemy_id = BattleManager.current_enemy_id
	if enemy_id != "":
		PlayerStorage.register_defeat(enemy_id)
	
	# Возвращаемся в мир
	get_tree().change_scene_to_file("res://main/main.tscn")

func disable_buttons():
	for btn in [$VBoxContainer/ActionsPanel/Attack, $VBoxContainer/ActionsPanel/Inventory, $VBoxContainer/ActionsPanel/Say, $VBoxContainer/ActionsPanel/Hack]:
		if btn: btn.disabled = true

func enable_buttons():
	for btn in [$VBoxContainer/ActionsPanel/Attack, $VBoxContainer/ActionsPanel/Inventory, $VBoxContainer/ActionsPanel/Say, $VBoxContainer/ActionsPanel/Hack]:
		if btn: btn.disabled = false
