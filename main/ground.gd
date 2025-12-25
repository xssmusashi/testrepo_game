@tool # Позволяет запускать скрипт прямо в редакторе
extends TileMapLayer

@export var randomize_now: bool = false:
	set(value):
		if value:
			randomize_tiles()
			randomize_now = false

func randomize_tiles() -> void:
	var used_cells = get_used_cells()
	
	# Набор флагов для поворотов на 90, 180, 270 градусов
	# В Godot 4 это комбинации FLIP_H, FLIP_V и TRANSPOSE
	var rotations = [
		0, # 0 градусов
		TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V, # 180 градусов
		TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H, # 90 градусов по часовой
		TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V  # 270 градусов по часовой
	]
	
	for coords in used_cells:
		var source_id = get_cell_source_id(coords)
		var atlas_coords = get_cell_atlas_coords(coords)
		
		# Выбираем случайный вариант трансформации
		var random_rotation = rotations.pick_random()
		
		# Перезаписываем клетку с новым флагом альтернативной плитки
		set_cell(coords, source_id, atlas_coords, random_rotation)
