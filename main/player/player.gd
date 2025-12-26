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
			print("Нажата E! Вызываю interact() у: ", current_interactable.name)
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
	# Проверяем метод у области ИЛИ у её родителя (самой жабы)
	var target = area
	if not target.has_method("interact"):
		target = area.get_parent()
	
	if target.has_method("interact"):
		current_interactable = target
		interact_prompt.visible = true
		print("Готов к диалогу с: ", target.name)

func _on_area_exited(area):
	# Проверяем и область, и родителя при выходе
	if current_interactable == area or current_interactable == area.get_parent():
		current_interactable = null
		interact_prompt.visible = false

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
