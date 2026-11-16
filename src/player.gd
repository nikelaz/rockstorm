extends Area2D

signal died(impact_position: Vector2)
signal fired
signal thrust_changed(active: bool)

const BULLET_SCENE = preload("res://src/bullet.tscn")

@onready var engine_exhaust: GPUParticles2D = $EngineExhaust

@export var rotation_rate: float = 3
@export var acceleration: float = 250.0
@export var deceleration: float = 250.0
var velocity: Vector2 = Vector2.ZERO
var alive: bool = true

func _ready() -> void:
	global_position = get_viewport_rect().size / 2.0
	rotation = -PI / 2.0
	area_entered.connect(on_area_entered)

func rotate_with_input(delta: float) -> void:
	var left_right_axis = Input.get_axis("ui_left", "ui_right")
	rotation += left_right_axis * rotation_rate * delta

func handle_acceleration(delta: float) -> void:
	var thrusting := Input.is_action_pressed("ui_up")
	engine_exhaust.emitting = thrusting
	thrust_changed.emit(thrusting)
	if thrusting:
		var direction = Vector2.RIGHT.rotated(rotation)
		velocity += direction * acceleration * delta
	else:
		velocity = velocity.move_toward(
			Vector2.ZERO,
			deceleration * delta
		)

func update_position(delta: float) -> void:
	var new_position = position + (velocity * delta)
	var viewport_size = get_viewport_rect().size
	new_position.x = clampf(new_position.x, 20.0, viewport_size.x - 20.0)
	new_position.y = clampf(new_position.y, 20.0, viewport_size.y - 20.0)
	position = new_position

func shoot() -> void:
	fired.emit()
	var bullet = BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	var direction = Vector2.RIGHT.rotated(global_rotation)
	bullet.global_position = global_position + direction * 25.0
	bullet.global_rotation = global_rotation

func handle_shooting():
	if Input.is_action_just_pressed("shoot"):
		shoot()

func _physics_process(delta: float) -> void:
	rotate_with_input(delta)
	handle_acceleration(delta)
	update_position(delta)

func _process(delta: float) -> void:
	handle_shooting()
	
func on_area_entered(area: Area2D) -> void:
	if alive and area.is_in_group("asteroids"):
		alive = false
		died.emit(get_impact_position(area.global_position))


func get_impact_position(asteroid_position: Vector2) -> Vector2:
	# Project the incoming asteroid onto the rocket's capsule surface.
	var collision: CollisionShape2D = $CollisionShape2D
	var capsule: CapsuleShape2D = collision.shape
	var incoming := collision.to_local(asteroid_position)
	var half_segment := maxf(0.0, capsule.height * 0.5 - capsule.radius)
	var nearest := Vector2(0.0, clampf(incoming.y, -half_segment, half_segment))
	var normal := (incoming - nearest).normalized()
	if normal.is_zero_approx():
		normal = Vector2.RIGHT
	return collision.to_global(nearest + normal * capsule.radius)
