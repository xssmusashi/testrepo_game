extends CanvasLayer

signal dialogue_finished

@onready var text_label = $Panel/RichTextLabel
@onready var timer = $Timer

var lines: Array = []
var current_line: int = 0

func start_dialogue(data: Array):
	lines = data
	current_line = 0
	visible = true
	_show_line()

func _show_line():
	text_label.text = lines[current_line]
	text_label.visible_characters = 0
	timer.start()

func _on_timer_timeout():
	if text_label.visible_characters < text_label.text.length():
		text_label.visible_characters += 1
	else:
		timer.stop()

func _input(event):
	# Используем is_action_pressed вместо is_action_just_pressed
	if event.is_action_pressed("interact") and visible:
		# Добавляем проверку, чтобы не срабатывало при зажатии (echo)
		if event.is_echo(): 
			return
			
		if text_label.visible_characters < text_label.text.length():
			text_label.visible_characters = text_label.text.length() # Пропустить анимацию
		else:
			current_line += 1
			if current_line < lines.size():
				_show_line()
			else:
				visible = false
				dialogue_finished.emit() # Сообщаем, что диалог окончен
