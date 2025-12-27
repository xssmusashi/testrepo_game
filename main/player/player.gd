extends CharacterBody2D

@export var speed: float = 200.0
@onready var anim = $AnimatedSprite2D

@onready var interact_detector = %InteractDetector
@onready var interact_prompt = %InteractPrompt

@onready var inventory_ui = get_tree().root.find_child("InventoryUI", true, false)

var current_interactable = null
var interactable_candidates = [] # Список всех NPC в радиусе

var health := 0

func _ready():
	# 1. Скрываем подсказку сразу при загрузке мира
	if interact_prompt:
		interact_prompt.visible = false
	
	# 2. Восстанавливаем позицию после боя
	if BattleManager.get("last_world_position") and BattleManager.last_world_position != Vector2.ZERO:
		global_position = BattleManager.last_world_position
		BattleManager.last_world_position = Vector2.ZERO
	
	# 3. Загружаем здоровье
	health = BattleManager.player_health
	
	interact_detector.area_entered.connect(_on_area_entered)
	interact_detector.area_exited.connect(_on_area_exited)

func _input(event):
	if event.is_action_pressed("inventory"):
		if inventory_ui:
			inventory_ui.toggle_visibility()

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
	var target = _get_interactable_from_area(area)
	if target and not target in interactable_candidates:
		interactable_candidates.append(target)
		_update_interaction_state()

func _on_area_exited(area):
	var target = _get_interactable_from_area(area)
	if target in interactable_candidates:
		interactable_candidates.erase(target)
		_update_interaction_state()

func _get_interactable_from_area(area):
	var target = area
	if not target.has_method("interact"):
		target = area.get_parent()
	return target if target.has_method("interact") else null

func _update_interaction_state():
	# Если рядом никого нет — гарантированно скрываем [E]
	if interactable_candidates.is_empty():
		current_interactable = null
		interact_prompt.visible = false
		return

	# Берем последнего зашедшего в зону NPC
	current_interactable = interactable_candidates[-1]
	var npc_name = current_interactable.get("character_name")
	
	if npc_name == null:
		npc_name = "NPC"
	
	# Обновляем текст подсказки
	if interact_prompt is Label:
		interact_prompt.text = "[E] " + npc_name
	elif interact_prompt.has_node("Label"):
		interact_prompt.get_node("Label").text = "[E] " + npc_name
		
	interact_prompt.visible = true

func choose_animation(dir):
	if abs(dir.x) > abs(dir.y):
		anim.play("walk_right" if dir.x > 0 else "walk_left")
	else:
		anim.play("walk_down" if dir.y > 0 else "walk_up")
