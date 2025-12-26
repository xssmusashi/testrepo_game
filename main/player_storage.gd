extends Node

# Список ID врагов, которые были убиты
var defeated_characters: Array[String] = []

func register_defeat(character_id: String) -> void:
	if not character_id in defeated_characters:
		defeated_characters.append(character_id)

func is_character_defeated(character_id: String) -> bool:
	return character_id in defeated_characters
