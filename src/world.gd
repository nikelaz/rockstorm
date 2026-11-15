extends Node2D

func _draw() -> void:
	draw_rect(
		Rect2(Vector2.ZERO, get_viewport_rect().size),
		Color(0.12, 0.16, 0.22)
	)
