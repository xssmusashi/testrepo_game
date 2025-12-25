extends CharacterBody2D

@export var speed: float = 200.0
@onready var anim = $AnimatedSprite2D

@onready var interact_detector = $InteractDetector
@onready var interact_prompt = $InteractPrompt

@onready var inventory: Inventory = $Inventory

var current_interactable = null
var health: int = 100 # Добавим HP для урона в бою

func _ready():
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
	if area.has_method("interact"):
		current_interactable = area
		interact_prompt.visible = true

func _on_area_exited(area):
	if current_interactable == area:
		current_interactable = null
		interact_prompt.visible = false

func take_damage(amount: int):
	health -= amount
	print("HP Игрока: ", health)
	if health <= 0:
		get_tree().reload_current_scene() # Рестарт при смерти

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
