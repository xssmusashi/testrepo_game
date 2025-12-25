extends Control

@export var fruit_scene: PackedScene
@export var fruits_sheet: Texture2D # Сюда в инспекторе перетащи fruits.png
@export var fruit_display_scale: float = 3.0 # Регулируй x2 или x3 в инспекторе

signal finished(result: Dictionary)


var score := 0
var is_active := false
var time_left := 0.0

@onready var fruit_container: Control = $PlayArea/FruitContainer
@onready var spawn_timer: Timer = $PlayArea/SpawnTimer
@onready var trail: Line2D = $PlayArea/SlashTrail
@onready var score_label: Label = $PlayArea/HUD/Label
@onready var time_label: Label = $PlayArea/HUD/TimeLabel
@onready var play_area: Control = $PlayArea

func start(ctx: Dictionary = {}):
	score = 0
	time_left = ctx.get("duration", 12.0)
	score_label.text = "Score: 0"
	visible = true
	is_active = true
	spawn_timer.start()
	set_process(true) # Включаем обработку кадров для трейла

func _process(delta: float) -> void:
	if not is_active: return
	
	time_left -= delta
	time_label.text = str(ceil(time_left))
	
	# Обновляем след от разреза (Line2D)
	_update_slash_trail()
	
	if time_left <= 0:
		_finish()

func _update_slash_trail() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var m_pos = get_local_mouse_position()
		trail.add_point(m_pos)
		# Ограничиваем длину хвоста
		if trail.points.size() > 15:
			trail.remove_point(0)
	else:
		# Если кнопка не зажата, плавно очищаем хвост
		if trail.points.size() > 0:
			trail.remove_point(0)

func _on_spawn_timer_timeout() -> void:
	if not is_active: return
	# Выбрасываем от 1 до 3 фруктов за раз
	var count = randi_range(1, 3)
	for i in count:
		_spawn_random_fruit()
		# Небольшая задержка между фруктами в одной пачке
		await get_tree().create_timer(0.1).timeout

func _spawn_random_fruit() -> void:
	if not fruit_scene or not fruits_sheet: return
	var fruit = fruit_scene.instantiate()
	fruit_container.add_child(fruit)
	
	# Выбор региона (одна клетка 32x32)
	var idx = randi() % 11
	var col = idx % 3
	var row = idx / 3
	var region = Rect2(col * 32, row * 32, 32, 32)
	
	# Передаем масштаб
	if fruit.has_method("setup_fruit"):
		fruit.setup_fruit(fruits_sheet, region, fruit_display_scale)
	
	# Расчет позиции (с учетом масштаба, чтобы не спавнились в углу)
	var w = size.x if size.x > 100 else 1152.0
	var h = size.y if size.y > 100 else 648.0
	var start_x = randf_range(100, w - 100)
	fruit.position = Vector2(start_x, h + 100)
	
	var target_x = start_x + randf_range(-150, 150)
	var peak_y = randf_range(h * 0.2, h * 0.5)
	
	var tween_x = create_tween()
	tween_x.tween_property(fruit, "position:x", target_x, 1.6).set_trans(Tween.TRANS_LINEAR)
	
	var tween_y = create_tween()
	tween_y.tween_property(fruit, "position:y", peak_y, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(fruit, "position:y", h + 100, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	fruit.slashed.connect(_on_fruit_slashed)
	tween_y.finished.connect(func(): if is_instance_valid(fruit): fruit.queue_free())
	
func _finish() -> void:
	is_active = false
	spawn_timer.stop()
	finished.emit({
		"success": score >= 5, # Например, нужно набрать 5 очков
		"damage": 0 if score >= 5 else 12
	})
	visible = false

func _on_fruit_slashed() -> void:
	score += 1
	if score_label:
		score_label.text = "Score: " + str(score)
