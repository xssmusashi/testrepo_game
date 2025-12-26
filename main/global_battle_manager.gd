# res://main/global_battle_manager.gd
extends Node

var player_health: int = 100
var player_max_health: int = 100

var current_enemy_id: String = "" # Храним ID текущего противника

# Данные текущего боя
var enemy_data = {
	"name": "Unknown",
	"hp": 100,
	"damage": 10,
	"attack_type": "focus", # focus, geometry_dash, fruit, shield
	"portrait": null,
	"attack_first": false # Добавили флаг очередности хода
}
