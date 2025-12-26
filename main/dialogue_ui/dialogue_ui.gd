extends CanvasLayer

signal dialogue_finished
signal battle_requested

@onready var text_label = $Panel/RichTextLabel
@onready var name_label = $Panel/VBoxContainer/NameLabel     # Узел для имени
@onready var portrait_rect = $Panel/VBoxContainer/PanelContainer/Portrait   # Узел для портрета
@onready var timer = $Timer
@onready var options_container = $Panel/OptionsContainer

var lines: Array = []
var current_line: int = 0
var extra_info: Dictionary = {}

func _ready():
	visible = false
	options_container.visible = false
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)

# ТЕПЕРЬ: принимаем текст, имя и портрет
func start_dialogue(data: Array, char_name: String, portrait_texture: Texture2D, extra_data: Dictionary = {}):
	lines = data
	extra_info = extra_data
	current_line = 0
	name_label.text = char_name
	portrait_rect.texture = portrait_texture
	visible = true
	options_container.visible = false
	_show_line()

func _show_line():
	if current_line < lines.size():
		text_label.text = lines[current_line]
		text_label.visible_characters = 0
		timer.start()
	else:
		if not extra_info.is_empty():
			_show_options()
		else:
			_close_dialogue()

func _on_timer_timeout():
	if text_label.visible_characters < text_label.text.length():
		text_label.visible_characters += 1
	else:
		timer.stop()

func _input(event):
	# ТЕПЕРЬ: Реагируем на Enter (ui_accept) или E (interact)
	var is_advancing = event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")
	
	if visible and is_advancing and not event.is_echo():
		if text_label.visible_characters < text_label.text.length():
			# Если текст еще "печатается" - показываем сразу всю строку
			text_label.visible_characters = text_label.text.length()
			timer.stop()
		else:
			# Если строка закончена - идем к следующей
			current_line += 1
			_show_line()

func _show_options():
	for child in options_container.get_children():
		child.queue_free()
	
	options_container.visible = true
	
	# Кнопка "АТАКА" (всегда первая или выделенная)
	var attack_btn = Button.new()
	attack_btn.text = "Attack!"
	attack_btn.pressed.connect(_on_attack_selected)
	options_container.add_child(attack_btn)
	
	for question in extra_info.keys():
		var btn = Button.new()
		btn.text = question
		btn.pressed.connect(_on_option_selected.bind(question))
		options_container.add_child(btn)
	
	var exit_btn = Button.new()
	exit_btn.text = "End dialogue"
	exit_btn.pressed.connect(_close_dialogue)
	options_container.add_child(exit_btn)

func _on_attack_selected():
	visible = false
	battle_requested.emit() # Оповещаем NPC, что пора воевать
	
func _close_dialogue():
	visible = false
	dialogue_finished.emit() # Просто закрываем окно

func _on_option_selected(question: String):
	options_container.visible = false
	# Показываем ответ как новую строку диалога
	lines = [extra_info[question]]
	current_line = 0
	_show_line()
