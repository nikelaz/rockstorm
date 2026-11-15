extends Node

const MASTER_VOLUME_DB := 6.02

const GAME_MUSIC = preload("res://assets/sigmamusicart-space-ambient-background-music-462074.mp3")
const ENGINE = preload("res://assets/fronbondi_skegs-sfx-looking-straight-into-a-burning-rocket-engine-sound-effect-283448.mp3")
const SMALL_BREAK = preload("res://assets/lordsonny-small-rock-break-194553.mp3")
const SHOT = preload("res://assets/soundreality-sci-fi-gun-shot-312659.mp3")

var game_music: AudioStreamPlayer
var engine: AudioStreamPlayer
var small_break: AudioStreamPlayer
var shot: AudioStreamPlayer
var engine_fade: Tween
var music_fade: Tween
var thrusting := false


func _ready() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), MASTER_VOLUME_DB)
	for bus_name in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	game_music = make_player(GAME_MUSIC, "Music", -19.0, true)
	engine = make_player(ENGINE, "Effects", -60.0, true)
	small_break = make_player(SMALL_BREAK, "Effects", -29.94)
	shot = make_player(SHOT, "Effects", -30.0)


func make_player(stream: AudioStreamMP3, bus_name: String, volume: float, looped: bool = false) -> AudioStreamPlayer:
	var audio := AudioStreamPlayer.new()
	audio.stream = stream.duplicate()
	audio.stream.loop = looped
	audio.bus = bus_name
	audio.volume_db = volume
	audio.max_polyphony = 12 if not looped else 1
	add_child(audio)
	return audio


func set_gameplay_active(active: bool) -> void:
	if music_fade:
		music_fade.kill()
	set_thrusting(false)
	music_fade = create_tween()
	if active:
		game_music.volume_db = -60.0
		game_music.play(0.0)
		music_fade.tween_property(game_music, "volume_db", -19.0, 0.9)
	else:
		music_fade.tween_property(game_music, "volume_db", -60.0, 0.3)
		music_fade.tween_callback(game_music.stop)
		shot.stop()
		small_break.stop()


func set_thrusting(active: bool) -> void:
	if thrusting == active:
		return
	thrusting = active
	if engine_fade:
		engine_fade.kill()
	engine_fade = create_tween()
	if active:
		if not engine.playing:
			engine.volume_db = -60.0
			engine.play()
		engine_fade.tween_property(engine, "volume_db", -14.42, 0.12)
	else:
		engine_fade.tween_property(engine, "volume_db", -60.0, 0.1)
		engine_fade.tween_callback(engine.stop)


func play_shot() -> void:
	shot.play()


func play_rock_break(_small: bool) -> void:
	small_break.play()
