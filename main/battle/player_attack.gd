extends Control

signal attack_finished(multiplier)

@export var pulse_speed: float = 400.0
var is_active: bool = false

# Убедись, что имена узлов в дереве сцены точно такие же!
@onready var play_area: Control = $PlayArea
@onready var left_p: Control = $PlayArea/LeftPulse
@onready var right_p: Control = $PlayArea/RightPulse
@onready var target: Control = $PlayArea/TargetLine

@onready var result_label = $ResultLabel # Добавь эту ссылку

var dir := 1 # 1 = навстречу (left→, right←), -1 = обратно (left←, right→)

func _ready():
	# Если сцена запущена отдельно (как Main Scene), запускаем тест
	if get_tree().current_scene == self:
		await get_tree().process_frame # Ждем один кадр, чтобы размеры прогрузились
		start()
	else:
		# Если в составе боя — прячемся и ждем команды
		visible = false
		set_process(false)

func start():
	visible = true
	result_label.text = ""
	set_process(false)
	is_active = false

	await get_tree().process_frame
	if play_area.size.x <= 1.0:
		await play_area.resized

	# target по центру
	target.offset_left = (play_area.size.x - target.size.x) * 0.5

	# старт: left слева, right справа
	left_p.offset_left = -left_p.size.x
	right_p.offset_left = play_area.size.x

	dir = 1

	is_active = true
	set_process(true)
	
func _unhandled_input(event):
	if not is_active:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		calculate_hit()

func _process(delta):
	if not is_active:
		return

	# двигаем
	left_p.offset_left += dir * pulse_speed * delta
	right_p.offset_left -= dir * pulse_speed * delta

	# границы "игровой области"
	var min_x := 0.0
	var max_x := play_area.size.x - left_p.size.x

	# если дошли до краёв — разворачиваемся
	if dir == 1:
		# "разъехались" (левая дошла вправо) — едем обратно
		if left_p.offset_left >= max_x:
			left_p.offset_left = max_x
			right_p.offset_left = min_x
			dir = -1
	else:
		# доехали обратно влево — снова навстречу
		if left_p.offset_left <= min_x:
			left_p.offset_left = min_x
			right_p.offset_left = max_x
			dir = 1

func calculate_hit():
	var diff = abs(left_p.position.x - target.position.x)
	var multiplier = 0.0
	var text = ""
	
	if diff < 12:
		multiplier = 2.0
		text = "PERFECT!"
		result_label.modulate = Color.GREEN
	elif diff < 35:
		multiplier = 1.0
		text = "GOOD"
		result_label.modulate = Color.WHITE
	elif diff < 70:
		multiplier = 0.5
		text = "WEAK..."
		result_label.modulate = Color.GRAY
	else:
		multiplier = 0.0
		text = "MISS!"
		result_label.modulate = Color.RED
		
	result_label.text = text # Показываем текст игроку
	finish_attack(multiplier)
	
func finish_attack(mult):
	is_active = false
	set_process(false)
	attack_finished.emit(mult)

	await get_tree().create_timer(0.8).timeout
	result_label.text = ""
	visible = false
