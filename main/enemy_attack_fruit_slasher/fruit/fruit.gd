extends Control
signal slashed

var current_texture: Texture2D
var current_region: Rect2
var fruit_scale: float = 3.0

@onready var visual: Sprite2D = $Visual

func setup_fruit(tex: Texture2D, reg: Rect2, f_scale: float):
	current_texture = tex
	current_region = reg
	fruit_scale = f_scale

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS 
	if current_texture:
		visual.texture = current_texture
		visual.region_enabled = true
		visual.region_rect = current_region
		visual.scale = Vector2(fruit_scale, fruit_scale)
		
		# Подстраиваем размер хитбокса под масштаб
		var s = 32 * fruit_scale
		custom_minimum_size = Vector2(s, s)
		size = custom_minimum_size
		visual.position = size / 2 # Центрируем спрайт

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
		half.scale = Vector2(fruit_scale, fruit_scale)
		
		var half_w = current_region.size.x / 2
		var half_h = current_region.size.y
		
		# Режем регион атласа пополам (лево/право)
		if i == -1:
			half.region_rect = Rect2(current_region.position.x, current_region.position.y, half_w, half_h)
		else:
			half.region_rect = Rect2(current_region.position.x + half_w, current_region.position.y, half_w, half_h)
		
		container.add_child(half)
		half.global_position = global_position + (size / 2) + Vector2(i * 8 * fruit_scale, 0)
		
		# Анимация падения половинок
		var tw = container.create_tween().set_parallel(true)
		tw.tween_property(half, "position:x", half.position.x + (i * 80 * fruit_scale), 0.8).set_trans(Tween.TRANS_SINE)
		tw.tween_property(half, "position:y", half.position.y + 400, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(half, "modulate:a", 0.0, 0.8)
		tw.finished.connect(half.queue_free)
	
	queue_free()
