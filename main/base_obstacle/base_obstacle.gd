extends Node2D

@onready var sprite = $Sprite
@onready var canopy_area = %"CanopyArea (transparensy collision)"

func _ready():
	canopy_area.body_entered.connect(_on_body_entered)
	canopy_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		var tween = create_tween()
		# .set_parallel() позволяет запускать обе анимации одновременно
		tween.set_parallel(true) 
		# Делаем дерево прозрачным (0.5)
		tween.tween_property(sprite, "modulate:a", 0.5, 0.2)
		# Делаем персонажа чуть прозрачным (например, 0.7), чтобы его было видно сквозь крону
		tween.tween_property(body, "modulate:a", 0.7, 0.2)

func _on_body_exited(body):
	if body.name == "Player":
		var tween = create_tween()
		tween.set_parallel(true)
		# Возвращаем дереву полную видимость
		tween.tween_property(sprite, "modulate:a", 1.0, 0.2)
		# Возвращаем персонажу полную видимость
		tween.tween_property(body, "modulate:a", 1.0, 0.2)
