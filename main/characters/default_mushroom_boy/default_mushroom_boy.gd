extends CharacterBody2D

# Настройки ИИ
@export var speed := 50.0
@export var wander_time := 2.0
@export var wait_time := 1.5
@export var idle_chance_time := 30.0 # Раз в 30 секунд

# Данные для боя и диалога
@export var enemy_name: String = "Mushroom Boy"
@export var enemy_id: String = "forest_1_mushroom_boy"
@export var hp: int = 80
@export var damage: int = 8
@export var attack_type: String = "shield"
@export var portrait: Texture2D # Назначьте в инспекторе!

@export var dialogue_lines: Array[String] = ["Привет! Я просто лесной гриб.", "Не наступай на меня!"]
@export var ask_info: Dictionary = {
	"О лесе": "Этот лес полон странных существ, вроде Глорба.",
	"О тебе": "Я люблю дождь и тишину."
}

@onready var anim = $AnimatedSprite2D
@onready var dialogue_ui = get_tree().root.find_child("DialogueUI", true, false)

var move_direction := Vector2.ZERO
var ai_timer := 0.0
var idle_check_timer := 0.0
var is_talking := false
var is_playing_special_idle := false

func _ready():
	# Проверка: если враг убит, удаляем его
	if PlayerStorage.is_enemy_defeated(enemy_id):
		queue_free()
		return
	
	# Подключаем сигнал завершения анимации, чтобы выйти из idle
	if anim:
		anim.animation_finished.connect(_on_animation_finished)
	
	_choose_next_action()

func _physics_process(delta: float) -> void:
	if is_talking or is_playing_special_idle:
		velocity = Vector2.ZERO
		return

	# Таймер для редкого Idle (раз в 30 сек)
	idle_check_timer += delta
	if idle_check_timer >= idle_chance_time:
		_play_rare_idle()
		return

	# Логика перемещения
	ai_timer -= delta
	if ai_timer <= 0:
		_choose_next_action()

	velocity = move_direction * speed
	_update_animations()
	move_and_slide()

func _choose_next_action():
	# Случайно выбираем: стоять или идти
	if randf() > 0.5:
		# Выбор направления из 4 сторон
		move_direction = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN].pick_random()
		ai_timer = wander_time
	else:
		move_direction = Vector2.ZERO
		ai_timer = wait_time

func _update_animations():
	if velocity.length() == 0:
		anim.play("default") # Когда не идет — ставим в default
	else:
		# Выбор анимации ходьбы по направлению
		if abs(velocity.x) > abs(velocity.y):
			anim.play("walk_right" if velocity.x > 0 else "walk_left")
		else:
			anim.play("walk_down" if velocity.y > 0 else "walk_up")

func _play_rare_idle():
	is_playing_special_idle = true
	idle_check_timer = 0.0
	anim.play("idle") # Проигрываем idle

func _on_animation_finished():
	# Когда любая анимация закончилась, если это был idle — возвращаемся к жизни
	if anim.animation == "idle":
		is_playing_special_idle = false
		_choose_next_action()

# МЕТОД ВЗАИМОДЕЙСТВИЯ (Interact)
func interact():
	if is_talking: return
	
	is_talking = true
	velocity = Vector2.ZERO
	anim.play("default") # Замираем в покое
	
	if dialogue_ui:
		# Передаем данные в UI диалогов
		dialogue_ui.start_dialogue(dialogue_lines, enemy_name, portrait, ask_info)
		if not dialogue_ui.dialogue_finished.is_connected(_on_dialogue_finished):
			dialogue_ui.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)

func _on_dialogue_finished():
	is_talking = false
	_start_battle()

func _start_battle():
	# Передаем данные именно этого NPC в глобальный менеджер
	BattleManager.current_enemy_id = enemy_id
	BattleManager.enemy_data = {
		"name": enemy_name,
		"hp": hp,
		"damage": damage,
		"attack_type": attack_type,
		"portrait": portrait,
		"attack_first": false
	}
	get_tree().change_scene_to_file("res://main/battle/battle.tscn")
