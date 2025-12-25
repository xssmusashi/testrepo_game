extends Control
signal slashed

func _ready() -> void:
	# Явное подключение сигнала при старте
	mouse_entered.connect(_on_mouse_entered)
	# Задаем размер, чтобы область попадания не была нулевой
	if size == Vector2.ZERO:
		custom_minimum_size = Vector2(40, 40)

func _on_mouse_entered() -> void:
	# Проверяем, зажата ли левая кнопка мыши (разрез)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		slashed.emit()
		_split_and_die()

func _split_and_die():
	slashed.emit()
	# Логика с половинками
	for i in [-1, 1]:
		var half = ColorRect.new()
		half.size = size / 2
		# Ставим половинку в ту же позицию, где был фрукт
		half.position = global_position + Vector2(i * 10, 0)
		get_tree().current_scene.add_child(half) # Добавляем в корень сцены, чтобы не зависели от контейнера
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(half, "position", half.position + Vector2(i * 60, 200), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(half, "modulate:a", 0.0, 0.6)
		tw.finished.connect(half.queue_free)
	
	queue_free()
