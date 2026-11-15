
extends Area2D

@export var min_speed: float = 50.0
@export var max_speed: float = 150.0
@export var radius: float = 25.0

var velocity: Vector2 = Vector2.ZERO
var rotation_speed: float = 0.0

func _ready() -> void:
	var angle = randf_range(0.0, TAU)
	var speed = randf_range(min_speed, max_speed)

	velocity = Vector2.from_angle(angle) * speed
	rotation_speed = randf_range(-2.0, 2.0)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color.ORANGE)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	rotation += rotation_speed * delta
