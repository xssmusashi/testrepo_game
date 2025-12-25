extends Control

@export var spike_scene: PackedScene

signal finished(result: Dictionary)

@export var base_damage: int = 12

# --- Игрок ---
@export var player_size: Vector2 = Vector2(26, 26)
@export var player_x: float = 60.0

# --- Генерация платформ (только снизу) ---
@export var platform_min_w: float = 180.0
@export var platform_max_w: float = 360.0
@export var platform_h: float = 26.0

# Высота нижней платформы над полом
@export var low_platform_min_y_from_ground: float = 70.0
@export var low_platform_max_y_from_ground: float = 150.0

# --- Шипы ---
@export var spike_w: float = 18.0
@export var spike_h: float = 26.0

# --- "прощение" хитбокса игрока ---
@export var player_hitbox_shrink: Vector2 = Vector2(6, 6)

# --- Узлы ---
@onready var play_area: Control = $PlayArea
@onready var ground: ColorRect = $PlayArea/Ground
@onready var player: ColorRect = $PlayArea/Player
@onready var obstacles_holder: Control = $PlayArea/Obstacles
@onready var info: Label = $InfoLabel

# Оптимизированные константы для драйва
@export var duration: float = 12.0
@export var gravity: float = 4500.0       # Снизили для более плавного полета
@export var jump_velocity: float = -950.0  # Соотношение для прыжка через 3 шипа
@export var base_speed: float = 450.0      # Быстрее оригинала
@export var speed_growth: float = 15.0
@export var rotation_speed: float = 400.0

# --- Состояние ---
var is_active := false
var t := 0.0
var v_y := 0.0
var on_ground := true

# спавн по дистанции
var spawn_dist_left := 0.0
var rng := RandomNumberGenerator.new()

func _ready():
	visible = false
	set_process(false)
	rng.randomize()

func start(ctx: Dictionary = {}):
	if ctx.has("damage"):
		base_damage = int(ctx["damage"])
	if ctx.has("duration"):
		duration = float(ctx["duration"])

	visible = true
	info.text = "DODGE!"
	clear_obstacles()

	# дождаться корректных размеров
	await get_tree().process_frame
	if play_area.size.x <= 1.0:
		await play_area.resized

	# убедимся, что у пола есть высота
	if ground.size.y <= 1.0:
		ground.custom_minimum_size.y = 24
		await get_tree().process_frame

	# игрок
	player.custom_minimum_size = player_size
	player.set_anchors_preset(Control.PRESET_TOP_LEFT)
	player.position = Vector2(player_x, get_ground_y())
	player.color = Color(0.2, 0.5, 1.0) # синий

	t = 0.0
	v_y = 0.0
	on_ground = true
	spawn_dist_left = 240.0

	is_active = true
	set_process(true)

func stop():
	if is_active:
		_finish(false, 0)

func _unhandled_input(event):
	if not is_active:
		return
	if event.is_action_pressed("ui_accept") and on_ground:
		get_viewport().set_input_as_handled()
		v_y = jump_velocity
		on_ground = false

func _process(delta):
	if not is_active:
		return

	t += delta
	var speed = base_speed + speed_growth * t

	# 1) движение препятствий
	for obs in obstacles_holder.get_children():
		obs.position.x -= speed * delta
		if obs.position.x < -obs.size.x - 240:
			obs.queue_free()

	# 2) спавн сегментов
	spawn_dist_left -= speed * delta
	if spawn_dist_left <= 0.0:
		spawn_segment(play_area.size.x + 200.0)
		spawn_dist_left = float(rng.randi_range(220, 380))

	# 3) физика игрока (Y)
	var prev_y := player.position.y

	v_y += gravity * delta
	player.position.y += v_y * delta

	# 3.1) приземление (если падаем)
	if v_y >= 0.0:
		if handle_landing(prev_y):
			v_y = 0.0
			on_ground = true
		else:
			var gy := get_ground_y()
			if player.position.y >= gy:
				player.position.y = gy
				v_y = 0.0
				on_ground = true
			else:
				on_ground = false
	else:
		on_ground = false

	v_y += gravity * delta
	player.position.y += v_y * delta

	# ВРАЩЕНИЕ: если не на земле, крутим спрайт игрока
	if not on_ground:
		player.rotation_degrees += rotation_speed * delta
	
	if v_y >= 0.0:
		if handle_landing(prev_y):
			_align_player_to_grid() # Выравниваем при посадке
			v_y = 0.0
			on_ground = true
		else:
			var gy := get_ground_y()
			if player.position.y >= gy:
				player.position.y = gy
				_align_player_to_grid() # Выравниваем при посадке на пол
				v_y = 0.0
				on_ground = true
			else:
				on_ground = false

	# 3.2) боковые упоры об платформы (не смерть)
	handle_side_pushback()

	# 4) шипы убивают
	if check_spike_hit():
		_finish(true, base_damage)
		return

	# 5) победа по времени
	if t >= duration:
		_finish(false, 0)
		return

# ----------------------------
# Геометрия / rect helpers
# ----------------------------

func _align_player_to_grid():
	var current_rot = player.rotation_degrees
	# Находим ближайший угол кратный 90
	var target_rot = round(current_rot / 90.0) * 90.0
	
	# Плавное докручивание через Tween для красоты
	var tween = create_tween()
	tween.tween_property(player, "rotation_degrees", target_rot, 0.1)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) # Исправлено здесь

func ground_top_y() -> float:
	return play_area.size.y - ground.size.y

func get_ground_y() -> float:
	return ground_top_y() - player.size.y

func rect_local_of(node: Control) -> Rect2:
	var p = node.global_position - play_area.global_position
	return Rect2(p, node.size)

func player_rect_local(shrunk: bool = false) -> Rect2:
	var p = player.global_position - play_area.global_position
	var s = player.size
	if not shrunk:
		return Rect2(p, s)

	var sh = player_hitbox_shrink
	var ps = p + sh * 0.5
	var ss = s - sh
	return Rect2(ps, ss)

# ----------------------------
# Спавн сегмента (только снизу)
# ----------------------------

func spawn_segment(x: float):
	var g_top := ground_top_y()
	var chance := rng.randf()
	
	var last_obj_width := 0.0

	if chance < 0.4:
		# Слой шипов (1-3 шт)
		var count = rng.randi_range(1, 3)
		for i in count:
			var sx = x + i * (spike_w + 2)
			_spawn_spike(sx, g_top - spike_h, spike_w, spike_h)
		last_obj_width = count * spike_w
	elif chance < 0.8:
		# Платформа
		var plat_w := rng.randf_range(200.0, 400.0)
		var plat_y := g_top - platform_h
		_spawn_platform(x, plat_y, plat_w, platform_h)
		
		# Шанс спавна шипа НА платформе
		if rng.randf() < 0.4:
			_spawn_spike(x + plat_w/2, plat_y - spike_h, spike_w, spike_h)
		last_obj_width = plat_w
	else:
		# Пустой промежуток
		last_obj_width = 150.0

	# ВАЖНО: теперь отодвигаем следующий спавн на ширину текущего объекта + рандомный зазор
	spawn_dist_left = last_obj_width + rng.randf_range(180.0, 300.0)

func _spawn_platform(x: float, y: float, w: float, h: float) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color.WHITE
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.size = Vector2(w, h)
	c.position = Vector2(x, y)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.z_index = 4
	c.size_flags_horizontal = 0
	c.size_flags_vertical = 0
	c.set_meta("kind", "platform")
	obstacles_holder.add_child(c)
	return c

func _spawn_spike(x: float, y: float, w: float, h: float):
	var s: Control

	if spike_scene:
		s = spike_scene.instantiate()
	else:
		var c := ColorRect.new()
		c.color = Color(1, 1, 1)
		s = c

	s.set_anchors_preset(Control.PRESET_TOP_LEFT)
	s.size = Vector2(w, h)
	s.position = Vector2(x, y)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.z_index = 6
	s.size_flags_horizontal = 0
	s.size_flags_vertical = 0
	s.set_meta("kind", "spike")

	# если это Spike.gd — направление вверх
	if s is Spike:
		(s as Spike).direction = 1
		(s as Spike).queue_redraw()

	obstacles_holder.add_child(s)

# ----------------------------
# Коллизии
# ----------------------------

func handle_landing(prev_y: float) -> bool:
	var p_size = player.size
	var prev_bottom = prev_y + p_size.y
	var curr_bottom = player.position.y + p_size.y

	var p_rect = player_rect_local(false)

	for obs in obstacles_holder.get_children():
		if obs.get_meta("kind", "") != "platform":
			continue

		var o_rect = rect_local_of(obs)

		# x overlap
		var x_overlap = (p_rect.position.x < o_rect.position.x + o_rect.size.x) and \
						(p_rect.position.x + p_rect.size.x > o_rect.position.x)
		if not x_overlap:
			continue

		var platform_top = o_rect.position.y

		# падали сверху и пересекли верх платформы
		if prev_bottom <= platform_top and curr_bottom >= platform_top:
			player.position.y = platform_top - p_size.y
			return true

	return false

func handle_side_pushback():
	var p = player_rect_local(false)

	for obs in obstacles_holder.get_children():
		if obs.get_meta("kind", "") != "platform":
			continue

		var o = rect_local_of(obs)
		if not p.intersects(o):
			continue

		# если стоим на платформе — не пушим
		var p_bottom = p.position.y + p.size.y
		var o_top = o.position.y
		var standing = abs(p_bottom - o_top) <= 2.0
		if standing:
			continue

		# push влево на глубину пересечения
		var p_right = p.position.x + p.size.x
		var o_left = o.position.x
		var overlap_x = p_right - o_left
		if overlap_x > 0.0 and overlap_x < 100.0:
			_finish(true, base_damage)

func check_spike_hit() -> bool:
	var p_rect = player_rect_local(true)

	for obs in obstacles_holder.get_children():
		if obs.get_meta("kind", "") != "spike":
			continue
		var o = rect_local_of(obs)
		# небольшая “щадящая” корректировка
		o.size.y = max(0.0, o.size.y - 2.0)
		if p_rect.intersects(o):
			return true

	return false

# ----------------------------
# Завершение / утилиты
# ----------------------------

func _finish(hit: bool, damage: int):
	is_active = false
	set_process(false)
	
	if hit:
		info.text = "HIT!"
	else:
		info.text = "SAFE!"
	
	finished.emit({
		"success": not hit,
		"damage": damage,
		"survived_time": t
	})


	await get_tree().create_timer(0.6).timeout
	info.text = ""
	visible = false

func clear_obstacles():
	for c in obstacles_holder.get_children():
		c.queue_free()
