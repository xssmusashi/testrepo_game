extends Control
signal slashed

# Переменные для хранения настроек (заполняются спавнером)
var texture_to_use: Texture2D
var region_to_use: Rect2
var display_scale: float = 3.0

@onready var visual: Sprite2D = $Visual

func setup_fruit(tex: Texture2D, reg: Rect2, sc: float):
	texture_to_use = tex
	region_to_use = reg
	display_scale = sc

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	
	if texture_to_use:
		visual.texture = texture_to_use
		visual.region_enabled = true
		visual.region_rect = region_to_use
		visual.scale = Vector2(display_scale, display_scale)
		
		# Устанавливаем размер Control-узла, чтобы мышь могла его поймать
		var s = region_to_use.size.x * display_scale
		custom_minimum_size = Vector2(s, s)
		size = custom_minimum_size
		
		# Центрируем спрайт внутри области клика
		visual.position = size / 2

func _on_mouse_entered() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_split_and_die()

func _split_and_die():
	slashed.emit()
	var container = get_parent()
	
	for i in [-1, 1]:
		var half = Sprite2D.new()
		half.texture = texture_to_use
		half.region_enabled = true
		half.scale = Vector2(display_scale, display_scale)
		
		# Режем текстуру пополам (16x32 при масштабе 1:1)
		var hw = region_to_use.size.x / 2
		var hh = region_to_use.size.y
		if i == -1: # Левая половина
			half.region_rect = Rect2(region_to_use.position.x, region_to_use.position.y, hw, hh)
		else: # Правая половина
			half.region_rect = Rect2(region_to_use.position.x + hw, region_to_use.position.y, hw, hh)
		
		container.add_child(half)
		# global_position гарантирует, что половинки появятся ровно там, где был фрукт
		half.global_position = global_position + (size / 2) + Vector2(i * 10 * display_scale, 0)
		
		var tw = container.create_tween().set_parallel(true)
		tw.tween_property(half, "position:x", half.position.x + (i * 80 * display_scale), 0.8).set_trans(Tween.TRANS_SINE)
		tw.tween_property(half, "position:y", half.position.y + 400, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(half, "modulate:a", 0.0, 0.8)
		tw.finished.connect(half.queue_free)
	
	queue_free()
