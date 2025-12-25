extends Control

@export var spike_scene: PackedScene
signal finished(result: Dictionary)

@export var base_damage: int = 12

# --- Игрок ---
@export var player_size: Vector2 = Vector2(26, 26)
@export var player_x: float = 80.0 # Чуть дальше от края для удобства

# --- Параметры объектов ---
@export var platform_h: float = 20.0
@export var spike_w: float = 18.0
@export var spike_h: float = 26.0

# --- Физика и Скорость ---
@export var duration: float = 12.0
@export var gravity: float = 4000.0       # Гравитация для быстрого падения
@export var jump_velocity: float = -1100.0 # Сильный прыжок
@export var base_speed: float = 500.0      # Начальная скорость уровня
@export var speed_growth: float = 20.0     # Постепенное ускорение
@export var rotation_speed: float = 450.0  # Скорость вращения куба

# --- Узлы ---
@onready var play_area: Control = $PlayArea
@onready var ground: ColorRect = $PlayArea/Ground
@onready var player: ColorRect = $PlayArea/Player
@onready var obstacles_holder: Control = $PlayArea/Obstacles
@onready var info: Label = $InfoLabel

# --- Состояние ---
var is_active := false
var t := 0.0
var v_y := 0.0
var on_ground := true
var spawn_dist_left := 0.0
var rng := RandomNumberGenerator.new()

func _ready():
	visible = false
	set_process(false)
	rng.randomize()

func start(ctx: Dictionary = {}):
	if ctx.has("damage"): base_damage = int(ctx["damage"])
	if ctx.has("duration"): duration = float(ctx["duration"])

	visible = true
	info.text = "DODGE!"
	clear_obstacles()

	await get_tree().process_frame
	
	# Настройка игрока
	player.custom_minimum_size = player_size
	player.size = player_size
	# ВАЖНО: Центрируем ось вращения, чтобы куб не уезжал назад
	player.pivot_offset = player_size / 2 
	player.position = Vector2(player_x, get_ground_y())
	player.rotation = 0
	
	t = 0.0
	v_y = 0.0
	on_ground = true
	spawn_dist_left = 300.0 # Задержка перед первым препятствием

	is_active = true
	set_process(true)

func _unhandled_input(event):
	if not is_active: return
	if event.is_action_pressed("ui_accept") and on_ground:
		get_viewport().set_input_as_handled()
		v_y = jump_velocity
		on_ground = false

func _process(delta):
	if not is_active: return

	t += delta
	var speed = base_speed + speed_growth * t

	# 1) ДВИЖЕНИЕ ПРЕПЯТСТВИЙ (Шипы и Платформы)
	for obs in obstacles_holder.get_children():
		obs.position.x -= speed * delta
		if obs.position.x < -400: # Удаляем, когда улетели далеко за экран
			obs.queue_free()

	# 2) СПАВН СЕГМЕНТОВ
	spawn_dist_left -= speed * delta
	if spawn_dist_left <= 0.0:
		spawn_segment(play_area.size.x + 100.0)
		# Расстояние между препятствиями
		spawn_dist_left = rng.randf_range(250.0, 450.0)

	# 3) ФИЗИКА ИГРОКА (Y) - ТОЛЬКО ОДИН РАСЧЕТ
	var prev_y := player.position.y
	v_y += gravity * delta
	player.position.y += v_y * delta

	# Вращение в прыжке
	if not on_ground:
		player.rotation_degrees += rotation_speed * delta

	# 4) ПРИЗЕМЛЕНИЕ И КОЛЛИЗИИ
	if v_y >= 0.0: # Если падаем
		if handle_landing(prev_y):
			v_y = 0.0
			on_ground = true
			_align_player_to_grid()
		else:
			var gy := get_ground_y()
			if player.position.y >= gy:
				player.position.y = gy
				v_y = 0.0
				on_ground = true
				_align_player_to_grid()
	
	# Смерть от шипов или удара в бок платформы
	if check_spike_hit() or handle_side_collision():
		_finish(true, base_damage)
		return

	if t >= duration:
		_finish(false, 0)

# --- Вспомогательные функции ---

func _align_player_to_grid():
	var target_rot = round(player.rotation_degrees / 90.0) * 90.0
	create_tween().tween_property(player, "rotation_degrees", target_rot, 0.1).set_ease(Tween.EASE_OUT)

func get_ground_y() -> float:
	return play_area.size.y - ground.size.y - player.size.y

func spawn_segment(x: float):
	var g_top = play_area.size.y - ground.size.y
	var chance = rng.randf()
	
	if chance < 0.4: # Одиночный шип или группа
		var count = rng.randi_range(1, 2)
		for i in count:
			_spawn_obj("spike", Vector2(x + i*20, g_top - spike_h), Vector2(spike_w, spike_h))
	elif chance < 0.8: # Платформа в воздухе
		var pw = rng.randf_range(150, 300)
		var py = g_top - rng.randf_range(80, 140)
		_spawn_obj("platform", Vector2(x, py), Vector2(pw, platform_h))
		if rng.randf() < 0.4: # Шип на платформе
			_spawn_obj("spike", Vector2(x + pw/2, py - spike_h), Vector2(spike_w, spike_h))

func _spawn_obj(kind: String, pos: Vector2, sz: Vector2):
	var obj: Control
	if kind == "spike" and spike_scene:
		obj = spike_scene.instantiate()
	else:
		obj = ColorRect.new()
		obj.color = Color.WHITE if kind == "platform" else Color.RED
	
	obj.size = sz
	obj.position = pos
	obj.set_meta("kind", kind)
	obstacles_holder.add_child(obj)

func handle_landing(prev_y: float) -> bool:
	var p_rect = Rect2(player.position, player.size)
	for obs in obstacles_holder.get_children():
		if obs.get_meta("kind", "") != "platform": continue
		var o_rect = Rect2(obs.position, obs.size)
		# Проверка: были над платформой, стали под её уровнем
		if p_rect.position.x < o_rect.end.x and p_rect.end.x > o_rect.position.x:
			if (prev_y + player.size.y) <= o_rect.position.y and p_rect.end.y >= o_rect.position.y:
				player.position.y = o_rect.position.y - player.size.y
				return true
	return false

func handle_side_collision() -> bool:
	var p_rect = Rect2(player.position + Vector2(2, 2), player.size - Vector2(4, 8))
	for obs in obstacles_holder.get_children():
		if obs.get_meta("kind", "") != "platform": continue
		if p_rect.intersects(Rect2(obs.position, obs.size)):
			return true # Врезался в бок платформы
	return false

func check_spike_hit() -> bool:
	var p_rect = Rect2(player.position + Vector2(4, 4), player.size - Vector2(8, 8))
	for obs in obstacles_holder.get_children():
		if obs.get_meta("kind", "") == "spike":
			if p_rect.intersects(Rect2(obs.position, obs.size)): return true
	return false

func _finish(hit: bool, damage: int):
	is_active = false
	set_process(false)
	info.text = "HIT!" if hit else "SAFE!"
	finished.emit({"success": not hit, "damage": damage})
	await get_tree().create_timer(0.6).timeout
	visible = false

func clear_obstacles():
	for c in obstacles_holder.get_children(): c.queue_free()
