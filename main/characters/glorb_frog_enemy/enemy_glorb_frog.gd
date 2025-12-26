extends CharacterBody2D

@export var character_name: String = "Glorb Frog"
@export var hp: int = 100
@export var damage: int = 10
@export var attack_type: String = "fruit"
@export var dialogue_lines: Array[String] = ["Croak-Croak!", "Come on here, lets fight!"]
@export var portrait: Texture2D
@export var attack_first: bool = false

@export var character_id: String = "forest_1_glorb_frog"

# --- Настройки прыжков ---
@export var jump_distance := 120.0 
@export var jump_height := 40.0   
@export var jump_duration := 0.6  
@export var jump_delay := 2.5     

@onready var anim = $AnimatedSprite2D
@onready var dialogue_ui = get_tree().root.find_child("DialogueUI", true, false)

var last_direction: int = 0
var jump_timer: float = 0.0
var is_jumping := false
var is_talking := false # НОВЫЙ ФЛАГ: Состояние разговора

func _ready():
	if character_id == "":
		character_id = name
	
	if PlayerStorage.is_character_killed(character_id):
		queue_free()
		return
	
	velocity = Vector2.ZERO
	jump_timer = 0.0

func _physics_process(delta):
	# Если мы прыгаем или ГОВОРИМ — физику движения и таймеры не трогаем
	if is_jumping or is_talking:
		return
	
	# Логика покоя (Idle)
	velocity = Vector2.ZERO
	anim.play("idle")
	
	jump_timer += delta
	if jump_timer >= jump_delay:
		_perform_top_down_jump()
		jump_timer = 0.0
	
	move_and_slide()

func _perform_top_down_jump():
	if is_talking: return # Страховка: не прыгать, если начали говорить в этот же кадр
	
	is_jumping = true
	var direction = [-1, 1].pick_random() if last_direction == 0 else -last_direction
	last_direction = direction
	
	anim.play("jump_right" if direction > 0 else "jump_left")
	
	# 1. Физическое смещение тела
	var move_tween = create_tween()
	var target_x = position.x + (direction * jump_distance)
	move_tween.tween_property(self, "position:x", target_x, jump_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# 2. Визуальный подпрыг спрайта
	var visual_tween = create_tween()
	visual_tween.tween_property(anim, "position:y", -jump_height, jump_duration / 2.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	visual_tween.tween_property(anim, "position:y", 0.0, jump_duration / 2.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	move_tween.finished.connect(func(): is_jumping = false)

func interact():
	# Если жаба в полете, лучше запретить диалог или мгновенно её приземлить
	if is_jumping: 
		return 
		
	BattleManager.can_spare = false # В начале боя нельзя
		
	is_talking = true # ПОДНИМАЕМ ФЛАГ: ИИ замирает
	velocity = Vector2.ZERO
	anim.play("idle") # Гарантируем анимацию покоя
	
	if dialogue_ui:
		dialogue_ui.start_dialogue(dialogue_lines, character_name, portrait)
		# Подключаемся к сигналу завершения, чтобы сбросить флаг или начать бой
		if not dialogue_ui.dialogue_finished.is_connected(_on_dialogue_finished):
			dialogue_ui.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)

func _on_dialogue_finished():
	# Эта функция вызовется, когда игрок закроет последнее окно диалога
	is_talking = false # Опускаем флаг, ИИ снова может действовать
	_start_battle() # Запускаем переход в сцену боя

func _start_battle():
	BattleManager.current_character_id = character_id
	
	BattleManager.character_data = {
		"name": character_name,
		"hp": hp,
		"damage": damage,
		"attack_type": attack_type,
		"portrait": portrait,
		"attack_first": attack_first
	}
	get_tree().change_scene_to_file("res://main/battle/battle.tscn")

func _on_interact_area_body_exited(body: Node2D) -> void:
	if is_talking and body.is_in_group("player"):
		is_talking = false
		if dialogue_ui:
			# Отключаем сигнал, чтобы бой не начался случайно позже
			if dialogue_ui.dialogue_finished.is_connected(_on_dialogue_finished):
				dialogue_ui.dialogue_finished.disconnect(_on_dialogue_finished)
			dialogue_ui.close_silently()
