extends Node2D

@export var dialogue_lines: Array[String] = ["Ква-ква!", "Ты зашел не в то болото, приятель...", "Готовься к битве!"]
@onready var dialogue_ui = get_tree().root.find_child("DialogueUI", true, false)

func interact():
	if dialogue_ui:
		print("Запускаю диалог...")
		dialogue_ui.start_dialogue(dialogue_lines)
	else:
		print("ОШИБКА: DialogueUI не найден!")

func _start_battle():
	# Переходим в сцену боя (battle.tscn)
	# Можно передать данные о враге через глобальный скрипт или контекст
	get_tree().change_scene_to_file("res://main/battle/battle.tscn")
