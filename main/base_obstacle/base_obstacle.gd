extends Node2D

@onready var sprite = $Sprite
@onready var canopy_area = %"CanopyArea (transparensy collision)"
func _ready():
	# Соединяем сигналы программно, чтобы не делать это вручную для каждой копии
	canopy_area.body_entered.connect(_on_body_entered)
	canopy_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		var tween = create_tween()
		# Плавно делаем прозрачным (0.5) за 0.2 секунды
		tween.tween_property(sprite, "modulate:a", 0.5, 0.2)

func _on_body_exited(body):
	if body.name == "Player":
		var tween = create_tween()
		# Возвращаем полную видимость (1.0)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.2)
