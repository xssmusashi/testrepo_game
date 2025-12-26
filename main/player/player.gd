extends CharacterBody2D

@export var speed: float = 200.0
@onready var anim = $AnimatedSprite2D

@onready var interact_detector = %InteractDetector
@onready var interact_prompt = %InteractPrompt

@onready var inventory: Inventory = $Inventory

var current_interactable = null

var health := 0

func _ready():
	# Загружаем здоровье из глобального менеджера
	health = BattleManager.player_health
	
	interact_detector.area_entered.connect(_on_area_entered)
	interact_detector.area_exited.connect(_on_area_exited)

func _physics_process(_delta):
	_handle_movement()

	if Input.is_action_just_pressed("interact") and current_interactable:
			current_interactable.interact()

func _handle_movement():
	var direction = Input.get_vector("left", "right", "up", "down")
	if direction != Vector2.ZERO:
		velocity = direction * speed
		choose_animation(direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		anim.stop()
		anim.frame = 1
	move_and_slide()

func _on_area_entered(area):
	# Ищем цель (саму область или её родителя-NPC)
	var target = area
	if not target.has_method("interact"):
		target = area.get_parent()
	
	if target.has_method("interact"):
		current_interactable = target
		
		# Пытаемся получить имя. В Mushroom Boy это 'enemy_name'
		# Используем .get(), чтобы избежать ошибки, если переменной нет
		var npc_name = target.get("character_name") 
		if not npc_name:
			npc_name = "NPC" # Имя по умолчанию
			
		# Обновляем текст подсказки
		if interact_prompt is Label:
			interact_prompt.text = "[E] " + npc_name
		elif interact_prompt.has_node("Label"): # Если Label лежит внутри спрайта
			interact_prompt.get_node("Label").text = "[E] " + npc_name
			
		interact_prompt.visible = true
		print("Готов к диалогу с: ", npc_name)

func _on_area_exited(area):
	if current_interactable == area or current_interactable == area.get_parent():
		current_interactable = null
		interact_prompt.visible = false
		# Сбрасываем текст (необязательно, но полезно для отладки)
		if interact_prompt is Label:
			interact_prompt.text = "[E]"

func take_damage(amount: int):
	health -= amount
	# Обновляем глобальный стейт, чтобы в бою или другой сцене данные были актуальны
	BattleManager.player_health = health 
	
	print("HP Игрока: ", health)
	if health <= 0:
		# Перед рестартом можно восстановить HP или оставить как есть для Game Over
		BattleManager.player_health = BattleManager.player_max_health
		get_tree().reload_current_scene()

func choose_animation(dir):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			anim.play("walk_right")
		else:
			anim.play("walk_left")
	else:
		if dir.y > 0:
			anim.play("walk_down")
		else:
			anim.play("walk_up")
