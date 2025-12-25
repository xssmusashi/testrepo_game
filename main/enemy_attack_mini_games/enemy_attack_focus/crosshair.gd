extends Sprite2D

@export var circle_radius: float = 200.0  # Радиус рабочей зоны
@export var circle_center: Vector2 = Vector2(576, 324) # Центр (обычно центр экрана)

func _ready() -> void:
	# Скрываем стандартный системный курсор
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	# По умолчанию крестик прозрачный
	self.modulate.a = 0

func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	
	# Обновляем позицию спрайта (крестик всегда там же, где мышь)
	global_position = mouse_pos
	
	# Проверяем условия: нажата ЛКМ и мышь внутри круга
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and is_inside_circle(mouse_pos):
		self.modulate.a = 1.0  # Показываем крестик
	else:
		self.modulate.a = 0.0  # Скрываем крестик

# Функция проверки вхождения в круг
func is_inside_circle(pos: Vector2) -> bool:
	return pos.distance_to(circle_center) <= circle_radius
