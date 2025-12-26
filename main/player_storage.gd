extends Node

# Список ID врагов, которые были убиты
var defeated_enemies: Array[String] = []

func register_defeat(enemy_id: String) -> void:
	if not enemy_id in defeated_enemies:
		defeated_enemies.append(enemy_id)
		print("Враг повержен и занесен в базу: ", enemy_id)

func is_enemy_defeated(enemy_id: String) -> bool:
	return enemy_id in defeated_enemies
