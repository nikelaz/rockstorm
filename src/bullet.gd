extends Area2D

@export var speed: float = 1000.0

func _ready() -> void:
	area_entered.connect(on_area_entered)
	auto_destroy_after_timeout()
	
func auto_destroy_after_timeout() -> void:
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _draw() -> void:
	# Local -X stays behind the bullet as it travels along local +X.
	for step in range(12, 0, -1):
		var strength := 1.0 - float(step) / 13.0
		draw_line(
			Vector2(-float(step) - 1.0, 0),
			Vector2(-float(step) + 1.0, 0),
			Color(1.0, 0.8, 0.12, strength * 0.65),
			strength * 5.0,
			true
		)
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.95, 0.55), true, -1.0, true)

func _process(delta: float) -> void:
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * speed * delta
	
	if not get_viewport_rect().has_point(global_position):
		queue_free()

func on_area_entered(area: Area2D) -> void:
	if area.is_in_group("asteroids"):
		area.call("hit")
		queue_free()
