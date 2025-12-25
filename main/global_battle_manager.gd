# res://main/global_battle_manager.gd
extends Node

# Данные текущего боя
var enemy_data = {
	"name": "Unknown",
	"hp": 100,
	"damage": 10,
	"attack_type": "focus", # focus, geometry_dash, fruit, shield
	"portrait": null,
	"player_damage_to_enemy": 100
}
