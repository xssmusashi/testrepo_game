extends Control

@export var next_scene_path: String = "res://world.tscn" 
@export var fade_speed: float = 0.5 # Скорость затемнения

@onready var screens = [$Screen1, $Screen2, $Screen3]
@onready var enter_label = $EnterLabel
@onready var fader = $Fader # Наш черный прямоугольник сверху

var current_index = 0
var is_transitioning = false # Чтобы нельзя было спамить Enter во время анимации

func _ready():
	
	fader.modulate.a = 1.0
	create_tween().tween_property(fader, "modulate:a", 0.0, fade_speed)

	# Начальное состояние
	fader.modulate.a = 0
	for i in range(screens.size()):
		screens[i].visible = (i == 0)
	
	start_blinking()

func _input(event):
	if event.is_action_pressed("ui_accept") and not is_transitioning:
		change_screen_with_fade()

func change_screen_with_fade():
	is_transitioning = true
	
	# 1. Затемнение
	var tween = create_tween()
	tween.tween_property(fader, "modulate:a", 1.0, fade_speed)
	
	# 2. Когда экран стал черным — меняем контент
	tween.tween_callback(switch_content)
	
	# 3. Осветление
	tween.tween_property(fader, "modulate:a", 0.0, fade_speed)
	
	# 4. Разрешаем нажимать снова
	tween.tween_callback(func(): is_transitioning = false)

func switch_content():
	screens[current_index].visible = false
	current_index += 1
	
	if current_index < screens.size():
		screens[current_index].visible = true
	else:
		# Если всё кончилось, переходим в мир
		get_tree().change_scene_to_file(next_scene_path)

func start_blinking():
	var t = create_tween().set_loops()
	t.tween_property(enter_label, "modulate:a", 0.0, 0.8)
	t.tween_property(enter_label, "modulate:a", 1.0, 0.8)
