extends Node2D

@export var dialogue_lines: Array[String] = ["Ква-ква!", "Ты зашел не в то болото, приятель...", "Готовься к битве!"]
@onready var dialogue_ui = get_tree().root.find_child("DialogueUI", true, false)

func interact():
	# Когда игрок нажал E, запускаем диалог
	if dialogue_ui:
		dialogue_ui.start_dialogue(dialogue_lines)
		# Ждем сигнала окончания диалога, чтобы начать бой
		if not dialogue_ui.dialogue_finished.is_connected(_start_battle):
			dialogue_ui.dialogue_finished.connect(_start_battle, CONNECT_ONE_SHOT)

func _start_battle():
	# Переходим в сцену боя (battle.tscn)
	# Можно передать данные о враге через глобальный скрипт или контекст
	get_tree().change_scene_to_file("res://main/battle/battle.tscn")
