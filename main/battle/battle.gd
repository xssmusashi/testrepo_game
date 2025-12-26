extends CanvasLayer

@onready var player_attack_game = %PlayerAttack 
@onready var log_label = $VBoxContainer/LogPanel/RichTextLabel 
@onready var character_hp_bar: ProgressBar = %CharacterHPBar # Убедись, что Unique Name включен!
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var character_name_label: Label = %CharacterName
@onready var character_portrait_sprite: TextureRect = %CharacterPortrait

@onready var instruction_label: Label = %InstructionLabel

@onready var mercy_button = $VBoxContainer/ActionsPanel/Mercy

const INSTRUCTIONS = {
	"focus": "Keep your cursor inside the circle!",
	"geometry_dash": "Press SPACE to jump!",
	"fruit": "Slice them all with your mouse!",
	"shield": "Protect yourself with your mouse!"
}

@onready var attack_nodes = {
	"focus": %CharacterAttackFocus,
	"geometry_dash": %CharacterAttackGeometryDash,
	"fruit": %CharacterAttackFruitSlasher,
	"shield": %CharacterAttackShieldOrbit
}

const DEFAULT_ATTACK = "focus"

var is_spare_attempt := false # Флаг: пытаемся ли мы пощадить сейчас

var current_character_hp: int = 100
var character_damage: int = 10
var active_character_attack = null
var attack_running := false
var player_damage_to_character: float = 50.0 # Базовый урон игрока

func _ready():
	var data = BattleManager.character_data
	var char_id = BattleManager.current_character_id
	
	instruction_label.text = ""
	character_name_label.text = data["name"]
	character_portrait_sprite.texture = data["portrait"]
	
	var max_hp = data.get("hp", 100)
	current_character_hp = PlayerStorage.get_character_hp(char_id, max_hp)
	
	character_damage = data.get("damage", 10)
	
	if character_hp_bar:
		character_hp_bar.max_value = max_hp
		character_hp_bar.value = current_character_hp
	
	mercy_button.pressed.connect(_on_mercy_pressed)
	_update_mercy_status()
	
	for attack_node in attack_nodes.values():
		if attack_node:
			# Проверяем и подключаем сигнал 'finished'
			if not attack_node.finished.is_connected(_on_character_attack_finished):
				attack_node.finished.connect(_on_character_attack_finished)
	
	# 2. Инициализируем активную атаку
	var type = data.get("attack_type", "focus")
	active_character_attack = attack_nodes.get(type)
	
	# 3. Настройка UI через ГЛОБАЛЬНОЕ здоровье
	if player_hp_bar:
		player_hp_bar.max_value = BattleManager.player_max_health
		player_hp_bar.value = BattleManager.player_health

	if player_attack_game:
		if player_attack_game.has_signal("finished"):
			player_attack_game.finished.connect(_on_player_attack_finished)
	
	update_log("The battle begins!")

func update_log(text: String):
	if log_label: log_label.text = text

func _on_attack_pressed():
	if attack_running: return
	is_spare_attempt = false # Обычная атака
	attack_running = true
	disable_buttons()
	update_log("You attack...")
	player_attack_game.start()
	
func _on_mercy_pressed():
	if attack_running: return
	is_spare_attempt = true # Попытка пощады
	attack_running = true
	disable_buttons()
	update_log("You try to spare... Be perfect!")
	player_attack_game.start()

func _on_player_attack_finished(multiplier: float):
	attack_running = false
	
	if is_spare_attempt:
		# ПОЩАДА: Нужен идеальный результат (multiplier >= 1.0)
		if multiplier >= 0.95: # Даем небольшую погрешность для "идеала"
			update_log("Perfect! The enemy accepts your mercy.")
			await get_tree().create_timer(1.0).timeout
			_end_battle_peacefully()
		else:
			update_log("Your mercy wasn't convincing...")
			await get_tree().create_timer(1.0).timeout
			start_character_turn()
	else:
		# ОБЫЧНАЯ АТАКА
		var damage_dealt = int(player_damage_to_character * multiplier)
		current_character_hp -= damage_dealt
		
		# СОХРАНЕНИЕ HP: Записываем остаток здоровья сразу после удара
		PlayerStorage.save_character_hp(BattleManager.current_character_id, current_character_hp)
		
		if character_hp_bar:
			character_hp_bar.value = current_character_hp
		
		update_log("You dealt " + str(damage_dealt) + " damage!")
		
		if current_character_hp <= 0:
			_on_character_died()
		else:
			await get_tree().create_timer(1.0).timeout
			start_character_turn()

func start_character_turn():
	if active_character_attack:
		disable_buttons()
		update_log("character is attacking!")
		
		var attack_type = BattleManager.character_data.get("attack_type", DEFAULT_ATTACK)
		
		instruction_label.text = INSTRUCTIONS.get(attack_type, "Watch out!")
		
		active_character_attack.start({ "damage": character_damage, "duration": 10.0 })
	else:
		update_log("The character is confused...")
		enable_buttons()

func _on_character_attack_finished(result: Dictionary):
	attack_running = false # Сбрасываем флаг, чтобы можно было атаковать снова
	enable_buttons()
	instruction_label.text = ""
	
	if result.get("success", false):
		update_log("You dodged!!")
	else:
		var dmg = result.get("damage", character_damage)
		update_log("You took " + str(dmg) + " damage.")
		
		# Наносим урон в глобальный менеджер
		BattleManager.player_health -= dmg
		if player_hp_bar:
			player_hp_bar.value = BattleManager.player_health
			
		# СОВЕТ: Добавьте проверку на смерть игрока здесь
		if BattleManager.player_health <= 0:
			update_log("You were defeated...")
			# Тут логика проигрыша

func _on_character_died():
	update_log("The character is killed!")
	# При смерти удаляем запись о здоровье, чтобы в следующий раз он возродился (если надо)
	# Или оставляем 0, если он не должен больше появляться.
	PlayerStorage.register_kill(BattleManager.current_character_id)
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://main/main.tscn")
	
func _end_battle_peacefully():
	# Мирная победа: используем новый метод
	PlayerStorage.register_spare(BattleManager.current_character_id)
	get_tree().change_scene_to_file("res://main/main.tscn")

func _on_character_defeated():
	# ИСПОЛЬЗУЕМ: current_character_id, как указано в BattleManager
	var character_id = BattleManager.current_character_id
	if character_id != "":
		PlayerStorage.register_defeat(character_id)
	
	get_tree().change_scene_to_file("res://main/main.tscn")
	
func disable_buttons():
	for btn in [$VBoxContainer/ActionsPanel/Attack, $VBoxContainer/ActionsPanel/Inventory, $VBoxContainer/ActionsPanel/Say, $VBoxContainer/ActionsPanel/Hack]:
		if btn: btn.disabled = true

func enable_buttons():
	for btn in [$VBoxContainer/ActionsPanel/Attack, $VBoxContainer/ActionsPanel/Inventory, $VBoxContainer/ActionsPanel/Say, $VBoxContainer/ActionsPanel/Hack]:
		if btn: btn.disabled = false

func _update_mercy_status():
	# Врага можно пощадить, если его HP меньше 30%
	var enemy_hp = BattleManager.character_data["hp"]
	# Здесь можно добавить проверку: BattleManager.can_spare = (enemy_hp < 30)
	# Для теста сделаем, что пощада доступна всегда
	BattleManager.can_spare = true 
	
	# Визуально выделяем кнопку, если пощада доступна (как в Undertale)
	if BattleManager.can_spare:
		mercy_button.modulate = Color("0072ff")
	else:
		mercy_button.modulate = Color("000e1fff")
