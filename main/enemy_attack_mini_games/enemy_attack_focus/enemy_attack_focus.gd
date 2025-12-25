extends Control

signal finished(result: Dictionary)

@export_group("Movement")
@export var base_speed: float = 150.0 # Быстрее, чем было
@export var randomness_factor: float = 0.8
@export var change_dir_time: float = 0.5 # Как часто меняет вектор

@export_group("Mechanics")
@export var stability_drain: float = 45.0
@export var stability_recovery: float = 12.0
@export var focus_radius: float = 65.0

var is_active := false
var time_left := 10.0
var max_duration := 1000.0
var stability := 10000.0
var current_velocity := Vector2.ZERO
var dir_change_timer := 0.0

@onready var play_area: Control = $PlayArea
@onready var focus_circle: Control = $PlayArea/FocusCircle
@onready var stability_bar: ProgressBar = $HUD/StabilityBar
@onready var timer_progress: TextureProgressBar = $HUD/TimerProgress
@onready var crosshair: Sprite2D = %Crosshair

func _ready():
	visible = false
	# Настройка визуальных размеров
	focus_circle.custom_minimum_size = Vector2(focus_radius * 2, focus_radius * 2)
	focus_circle.pivot_offset = Vector2(focus_radius, focus_radius)
	
	# ТЕПЕРЬ: Скрываем системный курсор и всегда показываем свой
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	crosshair.visible = true

func start(ctx: Dictionary = {}):
	max_duration = ctx.get("duration", 10.0)
	time_left = max_duration
	stability = 100.0
	visible = true
	is_active = true
	_pick_random_velocity()

func _process(delta: float):
	if not is_active: return
	
	# 1. Круговой таймер (исчезает по часовой стрелке)
	time_left -= delta
	timer_progress.value = (time_left / max_duration) * 100.0
	
	# 2. Управление прицелом (ЛКМ)
	_handle_input()
	
	# 3. Рандомное движение цели
	_move_target(delta)
	
	# 4. Проверка условий
	_check_focus(delta)
	
	if stability <= 0: _finish(true)
	elif time_left <= 0: _finish(false)

func _handle_input():
	# ВМЕСТО get_global_mouse_position() используем позицию на экране:
	var screen_mouse_pos = get_viewport().get_mouse_position()
	
	# Так как крестик в CanvasLayer, его position = позиция на экране
	crosshair.position = screen_mouse_pos

func _move_target(delta: float):
	# Меняем направление по таймеру для хаотичности
	dir_change_timer -= delta
	if dir_change_timer <= 0:
		_pick_random_velocity()
		dir_change_timer = randf_range(0.2, change_dir_time)

	focus_circle.position += current_velocity * delta
	
	# Отскок от краев
	var rect = play_area.get_rect()
	if focus_circle.position.x < 0 or focus_circle.position.x + focus_circle.size.x > rect.size.x:
		current_velocity.x *= -1
	if focus_circle.position.y < 0 or focus_circle.position.y + focus_circle.size.y > rect.size.y:
		current_velocity.y *= -1

func _pick_random_velocity():
	var angle = randf() * TAU
	var speed_mod = randf_range(0.8, 1.5)
	current_velocity = Vector2.from_angle(angle) * base_speed * speed_mod

func _check_focus(delta: float):
	# 1. Находим центр круга в координатах МИРА
	var world_circle_center = focus_circle.global_position + (focus_circle.size * 0.5)
	
	# 2. Переводим эту точку в координаты ЭКРАНА
	# Для этого нам нужен CanvasTransform (трансформация текущего вьюпорта)
	var screen_circle_center = get_viewport_transform() * world_circle_center
	
	# 3. Позиция крестика на ЭКРАНЕ (он уже там)
	var crosshair_screen_pos = crosshair.position 
	
	# 4. Теперь можно честно считать дистанцию
	var dist = crosshair_screen_pos.distance_to(screen_circle_center)
	
	# Дальше ваш код без изменений
	if dist <= focus_radius:
		stability = move_toward(stability, 100.0, stability_recovery * delta)
		focus_circle.modulate = Color.CYAN
	else:
		stability -= stability_drain * delta
		focus_circle.modulate = Color.RED
	
	stability_bar.value = stability

func _finish(was_hit: bool):
	is_active = false
	visible = false
	# Возвращаем стандартный курсор
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 
	
	finished.emit({"success": not was_hit, "damage": 25 if was_hit else 0})
