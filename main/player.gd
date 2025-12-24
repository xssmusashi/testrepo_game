extends CharacterBody2D

@export var speed: float = 200.0
@onready var anim = $AnimatedSprite2D

@onready var inventory: Inventory = $Inventory

func _ready():
	# тест: добавим предмет при старте
	# inventory.add_item("potion", 2)
	pass

func _physics_process(_delta):
	var direction = Input.get_vector("left", "right", "up", "down")

	if direction != Vector2.ZERO:
		velocity = direction * speed
		choose_animation(direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		anim.stop()
		anim.frame = 1

	move_and_slide()

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
