extends Node

# Списки ID (уникальные)
var killed_characters: Array[String] = []
var spared_characters: Array[String] = []

# Словарь для сохранения HP: { "enemy_id": current_hp }
var characters_hp_state: Dictionary = {}

func register_kill(character_id: String) -> void:
	if character_id == "": return
	if not character_id in killed_characters:
		killed_characters.append(character_id)
	# Если убили, убираем из списка пощаженных на всякий случай
	if character_id in spared_characters:
		spared_characters.erase(character_id)

func register_spare(character_id: String) -> void:
	if character_id == "": return
	if not character_id in spared_characters:
		spared_characters.append(character_id)

func save_character_hp(character_id: String, hp: int) -> void:
	if character_id != "":
		characters_hp_state[character_id] = hp

func get_character_hp(character_id: String, default_hp: int) -> int:
	return characters_hp_state.get(character_id, default_hp)

func is_character_killed(character_id: String) -> bool:
	return character_id in killed_characters

func is_character_spared(character_id: String) -> bool:
	return character_id in spared_characters
