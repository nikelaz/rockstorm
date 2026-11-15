extends Node2D

@export var speed: float = 600.0

func _ready() -> void:
	await get_tree().create_timer(2.0).timeout
	queue_free()
	
func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color.YELLOW)

func _process(delta: float) -> void:
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * speed * delta
	
	if not get_viewport_rect().has_point(global_position):
		queue_free()
