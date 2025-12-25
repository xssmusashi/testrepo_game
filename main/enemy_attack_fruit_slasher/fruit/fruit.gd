extends Control
signal slashed

func _ready() -> void:
	# 1. Убеждаемся, что фрукт реагирует на мышь
	mouse_filter = Control.MOUSE_FILTER_PASS 
	mouse_entered.connect(_on_mouse_entered)
	
	# 2. Гарантируем область для детекции (если в tscn не задана)
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(40, 40)

func _on_mouse_entered() -> void:
	# Проверяем зажатую кнопку для "свайпа"
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_split_and_die()

func _split_and_die():
	slashed.emit()
	var container = get_parent() # Добавляем в FruitContainer, чтобы не вылетать из панели
	
	for i in [-1, 1]:
		var half = ColorRect.new()
		# Половинка фрукта
		half.size = size / Vector2(2, 1) # Режем вертикально
		half.color = $ColorRect.color
		container.add_child(half)
		
		# Ставим в позицию фрукта
		half.position = position + Vector2(i * 5, 0)
		
		# Эффект разлета и падения
		var tw = create_tween().set_parallel(true)
		# Разлетаются в стороны (X) и ускоряются вниз (Y)
		tw.tween_property(half, "position:x", half.position.x + (i * 80), 0.8).set_trans(Tween.TRANS_SINE)
		tw.tween_property(half, "position:y", half.position.y + 400, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# Плавное исчезновение
		tw.tween_property(half, "modulate:a", 0.0, 0.8)
		tw.finished.connect(half.queue_free)
	
	queue_free()
