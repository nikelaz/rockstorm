extends Node2D

const ASTEROID_SCENE = preload("res://src/asteroid.tscn")

func _ready() -> void:
	$AsteroidSpawnTimer.timeout.connect(spawn_asteroid)

func spawn_asteroid() -> void:
	var asteroid = ASTEROID_SCENE.instantiate()
	add_child(asteroid)

	asteroid.position = Vector2(300, 200)

func _draw() -> void:
	draw_rect(
		Rect2(Vector2.ZERO, get_viewport_rect().size),
		Color(0.12, 0.16, 0.22)
	)
