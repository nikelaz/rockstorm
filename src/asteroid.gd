
extends Area2D

const ASTEROID_SCENE = preload("res://src/asteroid.tscn")

@export var min_speed: float = 50.0
@export var max_speed: float = 150.0
@export var radius: float = 25.0
@export var small: bool = false

var already_hit: bool = false
var velocity: Vector2 = Vector2.ZERO
var rotation_speed: float = 0.0

func _ready() -> void:
	set_collision_shape_size()
	set_random_speed_angle()

func set_collision_shape_size() -> void:
	var circle = CircleShape2D.new()
	circle.radius = 12.5 if small else 25.0
	$CollisionShape2D.shape = circle

func set_random_speed_angle() -> void:
	var angle = randf_range(0.0, TAU)
	var speed = randf_range(min_speed, max_speed)
	velocity = Vector2.from_angle(angle) * speed
	rotation_speed = randf_range(-2.0, 2.0)

func _draw() -> void:
	var radius = 12.5 if small else 25.0
	draw_circle(Vector2.ZERO, radius, Color.ORANGE)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	rotation += rotation_speed * delta

func hit() -> void:
	if already_hit:
		return

	already_hit = true

	if small:
		queue_free()
	else:
		split.call_deferred()

func split() -> void:
	for i in range(2):
		var child = ASTEROID_SCENE.instantiate()
		child.small = true

		get_parent().add_child(child)
		child.global_position = global_position

		var angle = -0.6 if i == 0 else 0.6
		child.velocity = velocity.rotated(angle) * 1.25

	queue_free()
