extends CharacterBody2D # Изменили с Node2D для работы физики

@export var enemy_name: String = "Глорб Жаба"
@export var hp: int = 100
@export var damage: int = 10
@export var attack_type: String = "geometry_dash"
@export var dialogue_lines: Array[String] = ["Ква-ква!", "Ты не пройдешь!"]
@export var portrait: Texture2D
@export var attack_first: bool = false # Из прошлых правок

# --- Настройки прыжков ---
@export var jump_velocity := Vector2(120, -280) # Оптимально для небольших прыжков
@export var jump_delay := 3.0 # Увеличим паузу, чтобы она не скакала постоянно

@onready var anim = $AnimatedSprite2D
@onready var dialogue_ui = get_tree().root.find_child("DialogueUI", true, false)

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 0.5 # В 2 раза слабее
var last_direction: int = 0 # 0 - не прыгала, 1 - вправо, -1 - влево
var jump_timer: float = 0.0

func _ready():
	# Принудительно ставим на землю при появлении
	move_and_slide() 
	
	# Устанавливаем время первого прыжка
	jump_timer = 0.0

func _physics_process(delta):
	# 1. Применяем гравитацию
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# 2. Тормозим на земле и считаем время до прыжка
		velocity.x = move_toward(velocity.x, 0, 10)
		
		if velocity.x == 0:
			anim.play("idle")
			jump_timer += delta
			if jump_timer >= jump_delay:
				_perform_jump()
				jump_timer = 0.0

	move_and_slide()

func _perform_jump():
	# ОПРЕДЕЛЯЕМ НАПРАВЛЕНИЕ:
	# Если последний был вправо (1), теперь влево (-1). И наоборот.
	# Если это первый прыжок (0), выбираем случайно.
	var new_direction: int = 0
	
	if last_direction == 0:
		new_direction = [-1, 1].pick_random()
	else:
		new_direction = -last_direction # Всегда противоположное
	
	last_direction = new_direction
	
	# Применяем силу
	velocity.x = jump_velocity.x * new_direction
	velocity.y = jump_velocity.y
	
	# Включаем нужную анимацию
	if new_direction > 0:
		anim.play("jump_right")
	else:
		anim.play("jump_left")

func interact():
	velocity = Vector2.ZERO # Замираем при разговоре
	if dialogue_ui:
		dialogue_ui.start_dialogue(dialogue_lines, enemy_name, portrait)
		if not dialogue_ui.dialogue_finished.is_connected(_start_battle):
			dialogue_ui.dialogue_finished.connect(_start_battle, CONNECT_ONE_SHOT)

func _start_battle():
	BattleManager.enemy_data = {
		"name": enemy_name,
		"hp": hp,
		"damage": damage,
		"attack_type": attack_type,
		"portrait": portrait,
		"attack_first": attack_first
	}
	get_tree().change_scene_to_file("res://main/battle/battle.tscn")
