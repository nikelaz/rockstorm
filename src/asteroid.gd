
extends Area2D

signal destroyed(points: int)

const ASTEROID_SCENE = preload("res://src/asteroid.tscn")
const EXPLOSION = preload("res://src/asteroid_explosion.gd")
const IMAGE_ASTEROID_LARGE = preload("res://assets/asteroid_large.png")

const IMAGES_ASTEROID_SMALL = [
	preload("res://assets/asteroid_small_1.png"),
	preload("res://assets/asteroid_small_2.png")
]

@export var min_speed: float = 50.0
@export var max_speed: float = 150.0
@export var radius: float = 25.0
@export var small: bool = false

var already_hit: bool = false
var velocity: Vector2 = Vector2.ZERO
var rotation_speed: float = 0.0
var collision_grace: float = 0.0

func _ready() -> void:
	area_entered.connect(on_area_entered)
	set_collision_shape_size()
	set_random_speed_angle()
	var asteroid_texture = IMAGE_ASTEROID_LARGE
	if small:
		asteroid_texture = IMAGES_ASTEROID_SMALL.pick_random()
	$Sprite2D.texture = asteroid_texture

func set_collision_shape_size() -> void:
	var circle = CircleShape2D.new()
	circle.radius = 12.5 if small else 25.0
	$CollisionShape2D.shape = circle

func set_random_speed_angle() -> void:
	var angle = randf_range(0.0, TAU)
	var speed = randf_range(min_speed, max_speed)
	velocity = Vector2.from_angle(angle) * speed
	rotation_speed = randf_range(-2.0, 2.0)

func _physics_process(delta: float) -> void:
	collision_grace = maxf(0.0, collision_grace - delta)
	position += velocity * delta
	rotation += rotation_speed * delta
	# Recheck overlaps when fragment protection ends, even if no new entry occurs.
	if collision_grace == 0.0 and not already_hit:
		for area in get_overlapping_areas():
			on_area_entered(area)

func on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("asteroids"):
		return
	if already_hit or area.already_hit or collision_grace > 0.0 or area.collision_grace > 0.0:
		return
	hit(false)
	area.hit(false)

func hit(award_points: bool = true) -> void:
	if already_hit:
		return

	already_hit = true
	var explosion = EXPLOSION.new()
	explosion.fiery = award_points
	explosion.large = not small
	explosion.position = position
	explosion.drift = velocity * 0.15
	# Hits can arrive during physics queries; add the effect after they finish.
	get_parent().add_child.call_deferred(explosion)
	if award_points:
		destroyed.emit(10 if small else 20)

	if small:
		queue_free()
	else:
		split.call_deferred()

func split() -> void:
	for i in range(2):
		var child = ASTEROID_SCENE.instantiate()
		child.small = true
		child.collision_grace = 0.35
		var side := -1.0 if i == 0 else 1.0
		var direction := velocity.normalized() if not velocity.is_zero_approx() else Vector2.RIGHT
		child.position = position + direction.rotated(PI / 2.0) * side * 14.0

		get_parent().add_child(child)

		var angle = -0.6 if i == 0 else 0.6
		child.velocity = velocity.rotated(angle) * 1.25

	queue_free()
