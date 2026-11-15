extends Node2D

const SHIP_IDLE = preload("res://assets/ship_idle.png")
const SHIP_BURNING = preload("res://assets/ship_burning.png")

@onready var sprite: Sprite2D = $Sprite2D

@export var rotation_rate: float = 4.5
@export var acceleration: float = 250.0
@export var deceleration: float = 250.0
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	global_position = get_viewport_rect().size / 2.0
	rotation = -PI / 2.0

func rotate_with_input(delta: float) -> void:
	var left_right_axis = Input.get_axis("ui_left", "ui_right")
	rotation += left_right_axis * rotation_rate * delta

func handle_acceleration(delta: float) -> void:
	if Input.is_action_pressed("ui_up"):
		var direction = Vector2.RIGHT.rotated(rotation)
		velocity += direction * acceleration * delta
		sprite.texture = SHIP_BURNING
	else:
		velocity = velocity.move_toward(
			Vector2.ZERO,
			deceleration * delta
		)
		sprite.texture = SHIP_IDLE

func update_position(delta: float) -> void:
	var new_position = position + (velocity * delta)
	var viewport_size = get_viewport_rect().size
	new_position.x = clampf(new_position.x, 20.0, viewport_size.x - 20.0)
	new_position.y = clampf(new_position.y, 20.0, viewport_size.y - 20.0)
	position = new_position

func _process(delta: float) -> void:
	rotate_with_input(delta)
	handle_acceleration(delta)
	update_position(delta)
