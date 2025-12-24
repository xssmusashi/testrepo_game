extends Control
class_name Spike

@export var spike_color: Color = Color(1, 0.2, 0.2) # красный
@export var direction: int = 1 # 1 вверх, -1 вниз

func _ready():
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw():
	var w := size.x
	var h := size.y

	var pts: PackedVector2Array
	if direction == 1:
		# вверх: основание снизу, вершина наверху
		pts = PackedVector2Array([Vector2(0, h), Vector2(w * 0.5, 0), Vector2(w, h)])
	else:
		# вниз: основание сверху, вершина внизу
		pts = PackedVector2Array([Vector2(0, 0), Vector2(w * 0.5, h), Vector2(w, 0)])

	draw_colored_polygon(pts, spike_color)
