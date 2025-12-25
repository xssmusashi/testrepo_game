extends Control
signal slashed

func _ready() -> void:
	# Подключаем сигнал кодом, чтобы точно работало
	mouse_entered.connect(_on_mouse_entered)
	# Гарантируем область для клика
	mouse_filter = Control.MOUSE_FILTER_PASS 
	if size == Vector2.ZERO:
		custom_minimum_size = Vector2(50, 50)

func _on_mouse_entered() -> void:
	# Проверяем зажатую кнопку для "свайпа"
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_split_and_die()

func _split_and_die():
	slashed.emit() # Излучаем ОДИН раз
	
	# Логика половинок
	for i in [-1, 1]:
		var half = ColorRect.new()
		half.size = size / 2
		half.position = global_position + Vector2(i * 10, 0)
		get_parent().add_child(half) # Добавляем в контейнер
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(half, "position", half.position + Vector2(i * 100, 300), 0.5)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(half, "modulate:a", 0.0, 0.5)
		tw.finished.connect(half.queue_free)
	
	queue_free()
