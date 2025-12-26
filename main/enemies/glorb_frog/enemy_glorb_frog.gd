extends Node2D

@export var enemy_name: String = "Глорб Жаба"
@export var hp: int = 100
@export var damage: int = 10
@export var attack_type: String = "geometry_dash" # Какую мини-игру запустить
@export var dialogue_lines: Array[String] = ["Ква-ква!", "Ты не пройдешь!"]
@export var portrait: Texture2D 
@export var attack_first: bool = false # Нападает ли враг сразу после диалога

@onready var dialogue_ui = get_tree().root.find_child("DialogueUI", true, false)

func interact():
	if dialogue_ui:
		dialogue_ui.start_dialogue(dialogue_lines, enemy_name, portrait)
		if not dialogue_ui.dialogue_finished.is_connected(_start_battle):
			dialogue_ui.dialogue_finished.connect(_start_battle, CONNECT_ONE_SHOT)

func _start_battle():
	# ЗАПОЛНЯЕМ данные для BattleManager перед сменой сцены
	BattleManager.enemy_data = {
		"name": enemy_name,
		"hp": hp,
		"damage": damage,
		"attack_type": attack_type,
		"portrait": portrait,
		"attack_first": attack_first
	}
	get_tree().change_scene_to_file("res://main/battle/battle.tscn")
