extends Control
signal slashed

var current_texture: Texture2D
var current_region: Rect2
var fruit_scale: float = 3.0 # Коэффициент увеличения (x3)

@onready var visual: Sprite2D = $Visual

# Принимаем данные от спавнера
func setup_fruit(tex: Texture2D, reg: Rect2, f_scale: float):
	current_texture = tex
	current_region = reg
	fruit_scale = f_scale

func _ready() -> void:
	# Подключаем сигнал наведения мыши
	mouse_entered.connect(_on_mouse_entered)
	
	if current_texture:
		visual.texture = current_texture
		visual.region_enabled = true
		visual.region_rect = current_region
		
		# ПРИМЕНЯЕМ SCALE
		visual.scale = Vector2(fruit_scale, fruit_scale)
		
		# Рассчитываем размер области клика (32 пикселя * масштаб)
		var s = 32 * fruit_scale
		custom_minimum_size = Vector2(s, s)
		size = custom_minimum_size
		
		# Центрируем спрайт внутри Control-ноды
		visual.position = custom_minimum_size / 2
	
	# Убеждаемся, что фрукт не блокирует мышь для других
	mouse_filter = Control.MOUSE_FILTER_PASS 

func _on_mouse_entered() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_split_and_die()

func _split_and_die():
	slashed.emit()
	var container = get_parent()
	
	for i in [-1, 1]:
		var half = Sprite2D.new()
		half.texture = current_texture
		half.region_enabled = true
		half.scale = Vector2(fruit_scale, fruit_scale) # Половинки тоже крупные
		
		var half_w = current_region.size.x / 2
		var half_h = current_region.size.y
		
		if i == -1: # Левая половина
			half.region_rect = Rect2(current_region.position.x, current_region.position.y, half_w, half_h)
		else: # Правая половина
			half.region_rect = Rect2(current_region.position.x + half_w, current_region.position.y, half_w, half_h)
		
		container.add_child(half)
		half.global_position = global_position + (custom_minimum_size / 2) + Vector2(i * 10 * fruit_scale, 0)
		
		var tw = container.create_tween().set_parallel(true)
		tw.tween_property(half, "position:x", half.position.x + (i * 60 * fruit_scale), 0.8).set_trans(Tween.TRANS_SINE)
		tw.tween_property(half, "position:y", half.position.y + 400, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(half, "modulate:a", 0.0, 0.8)
		tw.finished.connect(half.queue_free)
	
	queue_free()
