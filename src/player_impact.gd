extends Node2D

signal finished

const DURATION := 0.7
const FLASH_DURATION := 0.16

var direction := Vector2.RIGHT
var age := 0.0
var sparks: Array[Dictionary] = []

func _ready() -> void:
	z_index = 6
	create_sparks()


func create_sparks() -> void:
	for i in range(36):
		# Sparks spray outward from the hull, with a few scattering in all directions.
		var angle := direction.angle() + randf_range(-1.4, 1.4)
		if i % 4 == 0:
			angle = randf_range(0.0, TAU)
		sparks.append({
			"velocity": Vector2.from_angle(angle) * randf_range(90.0, 260.0),
			"lifetime": randf_range(0.25, DURATION),
			"length": randf_range(4.0, 12.0),
			"electric": i % 5 == 0,
		})


func _process(delta: float) -> void:
	age += delta
	if age >= DURATION:
		finished.emit()
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	draw_impact_flash()
	draw_sparks()


func draw_impact_flash() -> void:
	var flash := maxf(0.0, 1.0 - age / FLASH_DURATION)
	for layer in range(4, 0, -1):
		draw_circle(Vector2.ZERO, (6.0 + age * 55.0) * layer,
			Color(1.0, 0.45, 0.08, flash * 0.09), true, -1.0, true)
	draw_circle(Vector2.ZERO, 7.0 * flash, Color(1.0, 0.96, 0.8, flash), true, -1.0, true)
	var ring_fade := maxf(0.0, 1.0 - age / 0.28)
	draw_arc(Vector2.ZERO, 5.0 + age * 100.0, 0.0, TAU, 48,
		Color(1.0, 0.7, 0.25, ring_fade * 0.65), 1.5, true)


func draw_sparks() -> void:
	for spark in sparks:
		var life := clampf(age / float(spark.lifetime), 0.0, 1.0)
		if life >= 1.0:
			continue
		var fade := 1.0 - life
		var velocity: Vector2 = spark.velocity
		var tip := velocity * age / (1.0 + age * 3.0)
		var tail := tip - velocity.normalized() * float(spark.length) * fade
		var color := Color(1.0, lerpf(0.3, 0.9, fade), 0.15, fade)
		if spark.electric:
			color = Color(0.55, 0.85, 1.0, fade)
		draw_line(tail, tip, Color(color, fade * 0.12), 5.0 * fade, true)
		draw_line(tail, tip, color, maxf(0.6, 1.8 * fade), true)
		draw_circle(tip, maxf(0.4, 1.3 * fade), Color(1.0, 0.97, 0.8, fade), true, -1.0, true)
