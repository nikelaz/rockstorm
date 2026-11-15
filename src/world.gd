
extends Node2D

const ASTEROID_SCENE = preload("res://src/asteroid.tscn")

@export var spawn_margin: float = 60.0
@export_range(0.1, 1.0, 0.05) var target_area_size: float = 0.5

@onready var background: Sprite2D = $Background_Sprite2D
@onready var score_label: Label = $HUD/Score/Value
@onready var gameplay: Node2D = $Gameplay
@onready var player: Area2D = $Gameplay/Player
@onready var menu: Control = $HUD/Menu
@onready var menu_title: Label = $HUD/Menu/Content/Title
@onready var final_score: Label = $HUD/Menu/Content/FinalScore
@onready var play_button: Button = $HUD/Menu/Content/Play

var score: int = 0
var playing: bool = false


func _ready() -> void:
	gameplay.child_entered_tree.connect(register_asteroid)
	player.died.connect(game_over)
	play_button.pressed.connect(start_game)
	update_score_label()
	resize_background()
	$AsteroidSpawnTimer.timeout.connect(spawn_asteroid)
	get_viewport().size_changed.connect(resize_background)
	set_gameplay_active(false)
	final_score.hide()
	play_button.grab_focus()


func set_gameplay_active(active: bool) -> void:
	gameplay.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	player.visible = active
	player.set_deferred("monitoring", active)
	player.engine_exhaust.emitting = false
	$HUD/Score.visible = active
	if active:
		$AsteroidSpawnTimer.start()
	else:
		$AsteroidSpawnTimer.stop()


func clear_run() -> void:
	for node in gameplay.get_children():
		if node != player:
			gameplay.remove_child(node)
			node.queue_free()


func start_game() -> void:
	clear_run()
	score = 0
	update_score_label()
	player.position = get_viewport_rect().size / 2.0
	player.rotation = -PI / 2.0
	player.velocity = Vector2.ZERO
	player.alive = true
	playing = true
	menu.hide()
	play_button.release_focus()
	set_gameplay_active(true)


func game_over() -> void:
	if not playing:
		return
	playing = false
	set_gameplay_active(false)
	show_game_over.call_deferred()


func show_game_over() -> void:
	clear_run()
	final_score.text = "SCORE\n" + score_label.text
	final_score.show()
	play_button.text = "PLAY AGAIN"
	menu.show()
	play_button.grab_focus()


func register_asteroid(node: Node) -> void:
	if node.is_in_group("asteroids"):
		node.connect("destroyed", add_score)


func add_score(points: int) -> void:
	if not playing:
		return
	score += points
	update_score_label()


func update_score_label() -> void:
	var digits := str(score)
	var formatted := ""
	for i in range(digits.length()):
		if i > 0 and (digits.length() - i) % 3 == 0:
			formatted += ","
		formatted += digits[i]
	score_label.text = formatted


func spawn_asteroid() -> void:
	if not playing:
		return
	var size = get_viewport_rect().size
	var spawn_position: Vector2

	# Pick a random edge outside the viewport
	match randi_range(0, 3):
		0: # Top
			spawn_position = Vector2(
				randf_range(0.0, size.x),
				-spawn_margin
			)
		1: # Right
			spawn_position = Vector2(
				size.x + spawn_margin,
				randf_range(0.0, size.y)
			)
		2: # Bottom
			spawn_position = Vector2(
				randf_range(0.0, size.x),
				size.y + spawn_margin
			)
		3: # Left
			spawn_position = Vector2(
				-spawn_margin,
				randf_range(0.0, size.y)
			)

	# Pick a random target in the central area
	var padding = size * (1.0 - target_area_size) / 2.0

	var target = Vector2(
		randf_range(padding.x, size.x - padding.x),
		randf_range(padding.y, size.y - padding.y)
	)

	# Calculate the direction toward that target
	var direction = (target - spawn_position).normalized()

	# Instantiate and configure the asteroid
	var asteroid = ASTEROID_SCENE.instantiate()
	gameplay.add_child(asteroid)

	asteroid.position = spawn_position
	asteroid.velocity = direction * asteroid.velocity.length()


func resize_background() -> void:
	var viewport_size = get_viewport_rect().size
	var texture_size = background.texture.get_size()

	var scale_factor = max(
		viewport_size.x / texture_size.x,
		viewport_size.y / texture_size.y
	)

	background.centered = false
	background.position = Vector2.ZERO
	background.scale = Vector2.ONE * scale_factor
