extends CharacterBody2D

# Настройки ИИ
@export var speed := 50.0
@export var wander_time := 2.0
@export var wait_time := 1.5
@export var idle_chance_time := 30.0 # Раз в 30 секунд

# Данные для боя и диалога
@export var character_name: String = "Mushroom Boy"
@export var character_id: String = "forest_1_mushroom_boy"
@export var hp: int = 80
@export var damage: int = 8
@export var attack_type: String = "shield"
@export var dialogue_portrait: Texture2D # Назначьте в инспекторе!
@export var battle_portrait: Texture2D

@export var dialogue_lines: Array[String] = ["Hey! I am mushroomian!", "Don't step on me!"]
@export var ask_info: Dictionary = {
	"About this place": "You are on the territory of the Legion of the Mushroom Outskirts!\nIt used to be just the outskirts.\nNow we’ve added “Legion” to the name.\nWell.\nTo sound more warlike.",
	"About yourself": "I love rain and silence.\nThe rain is still here, but I haven’t heard silence for a long time.\nI'm tired."
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
	if PlayerStorage.is_character_defeated(character_id):
		queue_free()
		return
	
	# Подключаем сигнал завершения анимации, чтобы выйти из idle
	if anim:
		anim.animation_finished.connect(_on_animation_finished)
	
	_choose_next_action()

func _physics_process(delta: float) -> void:
	if is_talking or is_playing_special_idle:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 5)
		# Если скорость стала совсем маленькой — обнуляем её для срабатывания анимации
		if velocity.length() < 1.0:
			velocity = Vector2.ZERO
		_update_animations() # Важно вызывать и здесь, чтобы при торможении включился default
		move_and_slide()
		return

	# Таймер для редкого Idle (раз в 30 сек)
	idle_check_timer += delta
	if idle_check_timer >= idle_chance_time:
		_play_rare_idle()
		return

	ai_timer -= delta
	if ai_timer <= 0:
		_choose_next_action()

	var target_velocity = move_direction * speed
	velocity = velocity.move_toward(target_velocity, speed * delta * 10)
	
	# Снаппинг: если мы почти остановились, сбрасываем в 0
	if move_direction == Vector2.ZERO and velocity.length() < 2.0:
		velocity = Vector2.ZERO
	
	_update_animations()
	move_and_slide()

func _choose_next_action():
	if randf() > 0.5:
		# Используем только чистые направления и нормализуем на всякий случай
		move_direction = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN].pick_random()
		ai_timer = wander_time
	else:
		move_direction = Vector2.ZERO
		ai_timer = wait_time

func _face_player():
	# Ищем игрока в группе "player" (рекомендуется) или просто по имени в корне
	var player = get_tree().get_first_node_in_group("player")
	
	if not player:
		# Если группа не настроена, пробуем найти узел с именем "Player"
		player = get_tree().root.find_child("Player", true, false)

	if player:
		# Вычисляем вектор направления от гриба к игроку
		var direction_to_player = player.global_position - global_position
		
		# Определяем, какая ось преобладает (горизонтальная или вертикальная)
		if abs(direction_to_player.x) > abs(direction_to_player.y):
			# Горизонтальное направление
			if direction_to_player.x > 0:
				anim.play("default_right")
			else:
				anim.play("default_left")
		else:
			# Вертикальное направление
			if direction_to_player.y > 0:
				anim.play("default_down")
			else:
				anim.play("default_up")

func _update_animations():
	# Состояние 1: РАЗГОВОР (приоритет)
	if is_talking:
		_face_player()
		return

	# Состояние 2: ПОКОЙ (не движется)
	if velocity.is_zero_approx():
		anim.play("default")
	# Состояние 3: ДВИЖЕНИЕ
	else:
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
	anim.play("default")
	
	if dialogue_ui:
		dialogue_ui.start_dialogue(dialogue_lines, character_name, dialogue_portrait, ask_info)
		
		# Используем CONNECT_ONE_SHOT для чистоты
		if not dialogue_ui.dialogue_finished.is_connected(_on_dialogue_finished):
			dialogue_ui.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
		
		if not dialogue_ui.battle_requested.is_connected(_on_battle_requested):
			dialogue_ui.battle_requested.connect(_on_battle_requested, CONNECT_ONE_SHOT)

func _on_dialogue_finished():
	# Просто возвращаемся к жизни, боя не будет
	is_talking = false
	_choose_next_action()

func _on_battle_requested():
	# Игрок нажал "Атака" — начинаем бой
	_start_battle()

func _start_battle():
	# Передаем данные именно этого NPC в глобальный менеджер
	BattleManager.current_character_id = character_id
	BattleManager.character_data = {
		"name": character_name,
		"hp": hp,
		"damage": damage,
		"attack_type": attack_type,
		"portrait": battle_portrait,
		"attack_first": false
	}
	get_tree().change_scene_to_file("res://main/battle/battle.tscn")

func _on_interact_area_body_exited(body: Node2D) -> void:
	print("Игрок вышел!")
	if is_talking and body.is_in_group("player"):
		is_talking = false
		if dialogue_ui:
			dialogue_ui.close_silently()
		_choose_next_action() # Гриб снова начинает гулять
