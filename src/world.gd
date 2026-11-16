
extends Node2D

const ASTEROID_SCENE = preload("res://src/asteroid.tscn")

@export var spawn_margin: float = 60.0
@export_range(0.1, 1.0, 0.05) var target_area_size: float = 0.5

@onready var background: Sprite2D = $Background_Sprite2D
@onready var score_label: Label = $HUD/Score/Value
@onready var gameplay: Node2D = $Gameplay
@onready var player: Area2D = $Gameplay/Player
@onready var menu = $HUD/Menu
@onready var game_audio: Node = $GameAudio

var score: int = 0
var playing: bool = false
var run_paused: bool = false

func _ready() -> void:
	gameplay.child_entered_tree.connect(register_asteroid)
	player.died.connect(game_over)
	player.fired.connect(game_audio.play_shot)
	player.thrust_changed.connect(game_audio.set_thrusting)
	menu.play_requested.connect(on_play_pressed)
	update_score_label()
	resize_background()
	$AsteroidSpawnTimer.timeout.connect(spawn_asteroid)
	get_viewport().size_changed.connect(resize_background)
	set_gameplay_active(false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo() and playing:
		get_viewport().set_input_as_handled()
		if run_paused:
			resume_game()
		else:
			pause_game()

func on_play_pressed() -> void:
	if run_paused:
		resume_game()
	else:
		start_game()

func pause_game() -> void:
	if not playing or run_paused:
		return
	run_paused = true
	get_tree().paused = true
	game_audio.set_thrusting(false)
	player.engine_exhaust.emitting = false
	$HUD/Score.hide()
	menu.show_score(score_label.text, "RESUME")

func resume_game() -> void:
	if not run_paused:
		return
	run_paused = false
	get_tree().paused = false
	menu.close()
	$HUD/Score.show()


func set_gameplay_active(active: bool) -> void:
	game_audio.set_gameplay_active(active)
	gameplay.process_mode = Node.PROCESS_MODE_PAUSABLE if active else Node.PROCESS_MODE_DISABLED
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
	run_paused = false
	get_tree().paused = false
	menu.fade_out_music()
	clear_run()
	score = 0
	update_score_label()
	player.position = get_viewport_rect().size / 2.0
	player.rotation = -PI / 2.0
	player.velocity = Vector2.ZERO
	player.alive = true
	playing = true
	menu.close()
	set_gameplay_active(true)


func game_over() -> void:
	if not playing or run_paused:
		return
	playing = false
	set_gameplay_active(false)
	show_game_over.call_deferred()


func show_game_over() -> void:
	clear_run()
	menu.play_music()
	menu.show_score(score_label.text, "PLAY AGAIN")

func register_asteroid(node: Node) -> void:
	if node.is_in_group("asteroids"):
		node.connect("destroyed", add_score)
		node.connect("break_sound_requested", game_audio.play_rock_break)


func add_score(points: int) -> void:
	if not playing or run_paused:
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
	if not playing or run_paused:
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
