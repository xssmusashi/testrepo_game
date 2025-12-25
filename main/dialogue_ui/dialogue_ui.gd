extends CanvasLayer

signal dialogue_finished

@onready var text_label = $Panel/RichTextLabel
@onready var name_label = $Panel/NameLabel     # Узел для имени
@onready var portrait_rect = $Panel/PanelContainer/Portrait   # Узел для портрета
@onready var timer = $Timer

var lines: Array = []
var current_line: int = 0

func _ready():
	visible = false
	# Гарантируем, что таймер подключен
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)

# Обновленная функция: принимает текст, имя и портрет
func start_dialogue(data: Array, character_name: String, portrait_texture: Texture2D):
	lines = data
	current_line = 0
	name_label.text = character_name        # Устанавливаем имя
	portrait_rect.texture = portrait_texture  # Устанавливаем портрет
	visible = true
	_show_line()

func _show_line():
	if current_line < lines.size():
		text_label.text = lines[current_line]
		text_label.visible_characters = 0
		timer.start()
	else:
		_close_dialogue()

func _on_timer_timeout():
	if text_label.visible_characters < text_label.text.length():
		text_label.visible_characters += 1
	else:
		timer.stop()

func _input(event):
	# Проверяем нажатие "Enter" (ui_accept) или "E" (interact)
	var is_action = event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")
	
	if visible and is_action and not event.is_echo():
		if text_label.visible_characters < text_label.text.length():
			# Если текст еще печатается — показываем его сразу
			text_label.visible_characters = text_label.text.length()
			timer.stop()
		else:
			# Если текст закончен — переходим к следующей строке
			current_line += 1
			_show_line()

func _close_dialogue():
	visible = false
	dialogue_finished.emit() # Сигнал для врага, чтобы начать бой
