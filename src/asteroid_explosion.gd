extends Node2D

const DURATION := 0.8

var fiery: bool = true
var large: bool = true
var drift: Vector2 = Vector2.ZERO
var age: float = 0.0
var particles: Array[Dictionary] = []

func _ready() -> void:
	z_index = 5
	var count := 30 if large else 18
	for i in range(count):
		var direction := Vector2.from_angle(randf_range(0.0, TAU))
		particles.append({
			"velocity": direction * randf_range(35.0, 120.0) * size_factor(),
			"offset": direction * randf_range(0.0, 7.0) * size_factor(),
			"radius": randf_range(1.5, 4.5) * size_factor(),
			"lifetime": randf_range(0.5, DURATION),
			"burn_time": randf_range(0.18, 0.34),
			"angle": randf_range(0.0, TAU),
			"spin": randf_range(-5.0, 5.0),
			"shade": randf_range(0.5, 0.9),
			"flame": fiery and i % 4 == 0,
		})


func size_factor() -> float:
	return 1.0 if large else 0.65


func _process(delta: float) -> void:
	age += delta
	position += drift * delta
	if age >= DURATION:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var progress := clampf(age / DURATION, 0.0, 1.0)
	if fiery:
		# Layered translucent circles give the fire a soft, fast-fading glow.
		var flash := maxf(0.0, 1.0 - age / 0.22)
		for layer in range(5, 0, -1):
			draw_circle(Vector2.ZERO, (9.0 + age * 45.0) * size_factor() * layer / 3.0,
				Color(1.0, 0.8, 0.12, flash * 0.06), true, -1.0, true)
		draw_circle(Vector2.ZERO, (5.0 + age * 35.0) * size_factor(),
			Color(1.0, 0.95, 0.55, flash), true, -1.0, true)
	else:
		# A muted dust cloud accompanies rock impacts, without flame or sparks.
		draw_circle(Vector2.ZERO, (8.0 + progress * 30.0) * size_factor(),
			Color(0.55, 0.56, 0.6, (1.0 - progress) * 0.16), true, -1.0, true)

	for particle in particles:
		var life := clampf(age / float(particle.lifetime), 0.0, 1.0)
		var fade := 1.0 - life
		var velocity: Vector2 = particle.velocity
		var center := velocity * age / (1.0 + age * 2.0)
		var radius: float = particle.radius * (1.0 - life * 0.7)
		# Both impacts and bullet hits throw the same angular rock debris.
		var shade: float = particle.shade
		var color := Color(shade * 0.85, shade * 0.87, shade * 0.92, fade)
		var angle: float = particle.angle + particle.spin * age
		var vertices := PackedVector2Array()
		for corner in range(5):
			vertices.append(center + Vector2.from_angle(angle + corner * TAU / 5.0) * radius)
		draw_colored_polygon(vertices, color)

		if particle.flame:
			# Only a few short-lived flames, kept close to the impact.
			var heat := maxf(0.0, 1.0 - age / float(particle.burn_time))
			var flame_center: Vector2 = particle.offset + velocity * (1.0 - exp(-age * 8.0)) / 8.0
			var flame_radius: float = particle.radius * heat
			draw_circle(flame_center, flame_radius * 2.0,
				Color(1.0, 0.8, 0.12, heat * 0.15), true, -1.0, true)
			draw_line(flame_center - velocity.normalized() * flame_radius, flame_center,
				Color(1.0, lerpf(0.8, 0.95, heat), lerpf(0.12, 0.55, heat), heat), maxf(0.5, flame_radius), true)
