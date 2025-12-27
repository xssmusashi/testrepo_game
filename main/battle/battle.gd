extends CanvasLayer

signal item_used

# --- Ссылки на узлы (Unique Names) ---
@onready var player_attack_game = %PlayerAttack 
@onready var log_label: Label = $VBoxContainer/LogPanel/Label
@onready var character_hp_bar: ProgressBar = %CharacterHPBar
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var character_name_label: Label = %CharacterName
@onready var character_portrait_sprite: TextureRect = %CharacterPortrait
@onready var instruction_label: Label = %InstructionLabel

# --- Кнопки ---
@onready var attack_button = $VBoxContainer/ActionsPanel/Attack
@onready var mercy_button = $VBoxContainer/ActionsPanel/Mercy
@onready var inventory_button = $VBoxContainer/ActionsPanel/Inventory

@onready var inventory_ui = get_tree().root.find_child("InventoryUI", true, false)

var shake_strength: float = 0.0
var shake_fade: float = 20.0
@onready var main_vbox = $VBoxContainer
@onready var original_vbox_pos = main_vbox.position

# --- Константы ---
const INSTRUCTIONS = {
	"focus": "Keep your cursor inside the circle!",
	"geometry_dash": "Press SPACE to jump!",
	"fruit": "Slice them all with your mouse!",
	"shield": "Protect yourself with your mouse!"
}
const DEFAULT_ATTACK = "focus"

# --- Узлы атак противника ---
@onready var attack_nodes = {
	"focus": %CharacterAttackFocus,
	"geometry_dash": %CharacterAttackGeometryDash,
	"fruit": %CharacterAttackFruitSlasher,
	"shield": %CharacterAttackShieldOrbit
}

# --- Состояние боя ---
var current_character_hp: int = 100
var character_damage: int = 10
var active_character_attack = null
var attack_running := false
var is_spare_attempt := false
var player_damage_to_character: float = 50.0 

func _process(delta: float) -> void:
	if shake_strength > 0:
		# Постепенно уменьшаем силу тряски
		shake_strength = lerp(shake_strength, 0.0, shake_fade * delta)
		# Применяем случайное смещение к позиции VBoxContainer
		main_vbox.position = original_vbox_pos + Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		# Возвращаем в исходную позицию, когда тряска окончена
		main_vbox.position = original_vbox_pos

func apply_ui_shake(strength: float) -> void:
	shake_strength = strength

func _ready() -> void:
	_setup_battle()
	_connect_signals()
	_update_mercy_status()
	update_log("The battle begins!")
	
	if inventory_button:
		inventory_button.pressed.connect(_on_inventory_used)
		self.item_used.connect(_on_inventory_actually_used)
	
func _on_inventory_used():
	if attack_running: return
	if inventory_ui:
		inventory_ui.toggle_visibility()
		
func _on_inventory_actually_used():
	# Предмет использован, закрываем инвентарь и передаем ход врагу
	if inventory_ui:
		inventory_ui.panel.visible = false
	
	update_log("You used an item and restored health!")
	player_hp_bar.value = BattleManager.player_health # Обновляем полоску
	
	await get_tree().create_timer(1.0).timeout
	start_character_turn() # Переход хода

func _setup_battle() -> void:
	var data = BattleManager.character_data
	var char_id = BattleManager.current_character_id
	
	instruction_label.text = ""
	character_name_label.text = data.get("name", "Unknown")
	character_portrait_sprite.texture = data.get("portrait")
	
	var max_hp = data.get("hp", 100)
	current_character_hp = PlayerStorage.get_character_hp(char_id, max_hp)
	character_damage = data.get("damage", 10)
	
	if character_hp_bar:
		character_hp_bar.max_value = max_hp
		character_hp_bar.value = current_character_hp
	
	if player_hp_bar:
		player_hp_bar.max_value = BattleManager.player_max_health
		player_hp_bar.value = BattleManager.player_health

	# Инициализация атаки врага
	var type = data.get("attack_type", DEFAULT_ATTACK)
	active_character_attack = attack_nodes.get(type)

func _connect_signals() -> void:
	# Подключение кнопок
	if attack_button and not attack_button.pressed.is_connected(_on_attack_pressed):
		attack_button.pressed.connect(_on_attack_pressed)
	if mercy_button and not mercy_button.pressed.is_connected(_on_mercy_pressed):
		mercy_button.pressed.connect(_on_mercy_pressed)
	
	# ВАЖНО: В твоем player_attack.gd сигнал называется 'attack_finished'
	if player_attack_game:
		if player_attack_game.has_signal("attack_finished"):
			player_attack_game.attack_finished.connect(_on_player_attack_finished)
		elif player_attack_game.has_signal("finished"):
			player_attack_game.finished.connect(_on_player_attack_finished)
	
	# Сигналы атак врага
	for node in attack_nodes.values():
		if node and node.has_signal("finished"):
			if not node.finished.is_connected(_on_character_attack_finished):
				node.finished.connect(_on_character_attack_finished)

# --- Логика игрока ---
func _on_attack_pressed() -> void:
	if attack_running: return
	_start_player_turn(false, "You attack...")

func _on_mercy_pressed() -> void:
	if attack_running: return
	
	# Проверка условий пощады конкретного NPC
	var max_hp = BattleManager.character_data.get("hp", 100)
	var threshold = BattleManager.character_data.get("mercy_threshold", 0.0)
	var current_ratio = float(current_character_hp) / float(max_hp)
	
	if current_ratio > threshold:
		# Если здоровья слишком много — выводим причину и НЕ начинаем ход
		var reason = BattleManager.character_data.get("mercy_denial", "The enemy is not ready yet!")
		update_log(reason)
		return 

	_start_player_turn(true, "You try to spare... Be perfect!")

func _start_player_turn(spare: bool, message: String) -> void:
	attack_running = true
	is_spare_attempt = spare
	set_buttons_disabled(true)
	update_log(message)
	player_attack_game.start()

func _on_player_attack_finished(multiplier: float) -> void:
	if is_spare_attempt:
		if multiplier >= 0.95:
			update_log("Perfect! The enemy accepts your mercy.")
			await get_tree().create_timer(1.0).timeout
			_end_battle_peacefully()
			return
		else:
			update_log("Your mercy wasn't convincing...")
	else:
		apply_ui_shake(8.0) # Небольшая встряска при ударе игрока
		
		var damage_dealt = int(player_damage_to_character * multiplier)
		current_character_hp -= damage_dealt
		PlayerStorage.save_character_hp(BattleManager.current_character_id, current_character_hp)
		
		if character_hp_bar:
			character_hp_bar.value = current_character_hp
		
		update_log("You dealt " + str(damage_dealt) + " damage!")
		
		if current_character_hp <= 0:
			_on_character_died()
			return

	await get_tree().create_timer(1.0).timeout
	start_character_turn()

# --- Логика противника ---
func start_character_turn() -> void:
	attack_running = true
	set_buttons_disabled(true)
	_update_mercy_status() # Обновляем состояние кнопок перед ходом врага
	
	if active_character_attack:
		update_log("The enemy is attacking!")
		var attack_type = BattleManager.character_data.get("attack_type", DEFAULT_ATTACK)
		instruction_label.text = INSTRUCTIONS.get(attack_type, "Watch out!")
		active_character_attack.start({ "damage": character_damage, "duration": 10.0 })
	else:
		update_log("The character is confused...")
		await get_tree().create_timer(1.0).timeout
		_on_character_attack_finished({"success": true, "damage": 0})

func _on_character_attack_finished(result: Dictionary) -> void:
	instruction_label.text = ""
	attack_running = false 
	set_buttons_disabled(false)
	
	if result.get("success", false):
		update_log("You dodged!!")
	else:
		apply_ui_shake(25.0) # Небольшая встряска при ударе игрока
		
		var dmg = result.get("damage", character_damage)
		update_log("You took " + str(dmg) + " damage.")
		BattleManager.player_health -= dmg
		if player_hp_bar:
			player_hp_bar.value = BattleManager.player_health
		
		if BattleManager.player_health <= 0:
			_handle_player_death()
			return
	
	_update_mercy_status()

# --- Вспомогательные функции ---
func _update_mercy_status() -> void:
	var data = BattleManager.character_data
	var max_hp = data.get("hp", 100)
	
	# Врага можно пощадить, если его HP < 30%
	var can_be_spared = (float(current_character_hp) / float(max_hp)) < 0.3
	
	# Для Mushroom Boy или тестов можно оставить всегда true
	BattleManager.can_spare = true 
	
	if mercy_button:
		mercy_button.modulate = Color("0072ff") if BattleManager.can_spare else Color.WHITE

func set_buttons_disabled(disabled: bool) -> void:
	for btn in $VBoxContainer/ActionsPanel.get_children():
		if btn is Button:
			btn.disabled = disabled

func update_log(text: String) -> void:
	if log_label: log_label.text = text

func _on_character_died() -> void:
	update_log("The character is killed!")
	PlayerStorage.register_kill(BattleManager.current_character_id)
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://main/main.tscn")
	
func _end_battle_peacefully() -> void:
	PlayerStorage.register_spare(BattleManager.current_character_id)
	get_tree().change_scene_to_file("res://main/main.tscn")

func _handle_player_death() -> void:
	update_log("You were defeated...")
	# Здесь должен быть переход на экран Game Over
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://main/main.tscn")
