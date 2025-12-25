extends Node2D

@export var enemy_name: String = "Glorb The Frog" # Имя врага
@export var dialogue_lines: Array[String] = ["Ribbit-Ribbit!!!", "What are you doing here?", "You in wrong place, now - die!!!"]
@export var portrait: Texture2D # Сюда перетащите картинку в инспекторе

@onready var dialogue_ui = get_tree().root.find_child("DialogueUI", true, false)

func interact():
	if dialogue_ui:
		# Передаем массив строк, имя и портрет
		dialogue_ui.start_dialogue(dialogue_lines, enemy_name, portrait)
		
		if not dialogue_ui.dialogue_finished.is_connected(_start_battle):
			dialogue_ui.dialogue_finished.connect(_start_battle, CONNECT_ONE_SHOT)

func _start_battle():
	# Переход в сцену боя после диалога
	get_tree().change_scene_to_file("res://main/battle/battle.tscn")
