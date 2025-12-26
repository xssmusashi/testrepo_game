extends Control

signal finished(result: Dictionary)

@export var bullet_speed: float = 180.0
@export var spawn_rate: float = 0.8
@export var shield_radius: float = 70.0 # Радиус орбиты щита
@export var parry_window_dist: float = 15.0 # "Толщина" зоны парирования
@export var shield_width_deg: float = 50.0 # Ширина щита в градусах

var is_active := false
var time_left := 10.0
var max_duration := 12
var score := 0

@onready var play_area: Control = $PlayArea
@onready var shield_pivot: Node2D = $PlayArea/ShieldPivot
@onready var bullets_container: Control = $PlayArea/BulletsContainer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var timer_progress: TextureProgressBar = $HUD/TimerProgress

@onready var shield: ColorRect = $PlayArea/ShieldPivot/Shield

func _ready():
	visible = false
	# Соединяем сигнал таймера кодом, чтобы не забыть в инспекторе
	if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func start(ctx: Dictionary = {}):
	score = 0
	time_left = ctx.get("duration", 10.0)
	visible = true
	
	# ВАЖНО: Ждем один кадр, чтобы PlayArea получила свои реальные размеры из Layout
	await get_tree().process_frame 
	
	_center_elements() # Теперь здесь размер будет правильный (например, 400x400)
	
	is_active = true
	spawn_timer.wait_time = spawn_rate
	spawn_timer.start()

func _center_elements():
	var center = play_area.size / 2
	if center == Vector2.ZERO:
		center = Vector2(200, 200)
	
	shield_pivot.visible = true
	
	shield_pivot.position = center
	
	# --- НАСТРОЙКА ВИЗУАЛА ЩИТА ---
	# 1. Устанавливаем точку опоры в центр прямоугольника
	shield.pivot_offset = shield.size / 2
	
	# 2. Поворачиваем на 90 градусов (PI/2 радиан), чтобы он стал вертикальным
	shield.rotation = PI / 2
	
	# 3. Размещаем его на орбите. 
	# Вычитаем pivot_offset, так как position у Control — это верхний левый угол.
	# Теперь центр щита будет ровно на расстоянии shield_radius.
	shield.position = Vector2(shield_radius, 0) - shield.pivot_offset
	
	bullets_container.position = Vector2.ZERO
	bullets_container.size = play_area.size

func _process(delta: float):
	if not is_active: return
	
	time_left -= delta
	timer_progress.value = (time_left / max_duration) * 100.0
	
	# --- ВРАЩЕНИЕ ЩИТА ---
	var mouse_pos = play_area.get_local_mouse_position()
	var center = play_area.size / 2
	var dir = (mouse_pos - center).normalized()
	shield_pivot.rotation = dir.angle()
	
	# Проверка всех пуль в контейнере
	_check_collisions(delta)
	
	if time_left <= 0:
		_finish(false)

func _on_spawn_timer_timeout():
	if not is_active: return
	_spawn_bullet()

func _spawn_bullet():
	var bullet = ColorRect.new()
	bullet.size = Vector2(12, 12)
	bullet.color = Color.YELLOW
	bullet.pivot_offset = bullet.size / 2
	bullets_container.add_child(bullet)
	
	var center = play_area.size / 2
	var spawn_angle = randf() * TAU
	# Спавним за краем PlayArea
	var spawn_pos = center + Vector2.from_angle(spawn_angle) * 300.0
	bullet.position = spawn_pos - bullet.size / 2
	
	# Движение к центру через Tween
	var tw = create_tween()
	tw.tween_property(bullet, "position", center - bullet.size/2, 300.0 / bullet_speed)
	tw.finished.connect(func(): _on_bullet_hit_center(bullet))

func _check_collisions(_delta):
	var center = play_area.size / 2
	var shield_angle = shield_pivot.rotation
	
	for bullet in bullets_container.get_children():
		if not bullet is Control or bullet.is_queued_for_deletion(): continue
		
		var b_pos = bullet.position + bullet.size/2
		var dist = b_pos.distance_to(center)
		
		# Если пуля пересекает "орбиту" щита
		if abs(dist - shield_radius) < parry_window_dist:
			var angle_to_bullet = (b_pos - center).angle()
			
			# Разница углов (нормированная)
			var angle_diff = abs(angle_difference(shield_angle, angle_to_bullet))
			
			if angle_diff < deg_to_rad(shield_width_deg / 2):
				_parry_bullet(bullet)

func _parry_bullet(bullet):
	# Эффект отбивания: пуля улетает назад и исчезает
	score += 1
	var tw = create_tween().set_parallel(true)
	var dir = (bullet.position - (play_area.size/2)).normalized()
	tw.tween_property(bullet, "position", bullet.position + dir * 100, 0.3)
	tw.tween_property(bullet, "modulate:a", 0.0, 0.3)
	tw.finished.connect(bullet.queue_free)

func _on_bullet_hit_center(bullet):
	if is_instance_valid(bullet) and is_active:
		bullet.queue_free()
		_finish(true) # Получили урон

func _finish(was_hit: bool):
	is_active = false
	spawn_timer.stop()
	for b in bullets_container.get_children(): b.queue_free()
	
	finished.emit({
		"success": not was_hit,
		"damage": 15 if was_hit else 0,
		"score": score
	})
	visible = false
