extends CanvasLayer

signal dialogue_finished

@onready var text_label = $Panel/RichTextLabel
@onready var timer = $Timer

var lines: Array = []
var current_line: int = 0

func _ready():
	# ГАРАНТИРУЕМ, что сигнал таймера подключен программно
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)
	visible = false

func start_dialogue(data: Array):
	lines = data
	current_line = 0
	visible = true
	# Делаем панель активной для ввода
	set_process_input(true)
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
	# Правильная проверка нажатия для функции _input
	if visible and event.is_action_pressed("interact") and not event.is_echo():
		if text_label.visible_characters < text_label.text.length():
			# Если текст еще печатается — показываем его мгновенно
			text_label.visible_characters = text_label.text.length()
			timer.stop()
		else:
			# Если текст уже весь — переходим к следующей строке
			current_line += 1
			if current_line < lines.size():
				_show_line()
			else:
				_close_dialogue()

func _close_dialogue():
	visible = false
	set_process_input(false)
	dialogue_finished.emit()
