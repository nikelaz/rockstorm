extends Control

signal play_requested

const MUSIC_VOLUME_DB := -20.0
const MUSIC_FADE_SECONDS := 0.9

@onready var final_score: Label = $Content/FinalScore
@onready var play_button: Button = $Content/Play
@onready var sound_button: Button = $Content/Sound
@onready var music_button: Button = $Content/Music
@onready var menu_music: AudioStreamPlayer = $"../../MenuMusic"

var music_fade: Tween

func _ready() -> void:
	play_button.pressed.connect(func(): play_requested.emit())
	$Content/Quit.pressed.connect(func(): get_tree().quit())
	sound_button.toggled.connect(set_sound_enabled)
	music_button.toggled.connect(set_music_enabled)
	initialize_audio_settings()
	final_score.hide()
	play_button.grab_focus()
	menu_music.bus = "Music"
	menu_music.stream = menu_music.stream.duplicate()
	menu_music.stream.loop = true
	play_music()

func initialize_audio_settings() -> void:
	var sound_enabled := not AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects"))
	sound_button.set_pressed_no_signal(sound_enabled)
	set_sound_enabled(sound_enabled)
	var music_enabled := not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music"))
	music_button.set_pressed_no_signal(music_enabled)
	set_music_enabled(music_enabled)

func set_sound_enabled(enabled: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Effects"), not enabled)
	sound_button.text = "SOUND EFFECTS: ON" if enabled else "SOUND EFFECTS: OFF"

func set_music_enabled(enabled: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not enabled)
	music_button.text = "MUSIC: ON" if enabled else "MUSIC: OFF"

func show_score(score: String, button_text: String) -> void:
	final_score.text = "SCORE\n" + score
	final_score.show()
	play_button.text = button_text
	show()
	play_button.grab_focus()

func close() -> void:
	hide()
	play_button.release_focus()

func play_music() -> void:
	if music_fade:
		music_fade.kill()
	menu_music.volume_db = MUSIC_VOLUME_DB
	menu_music.play(0.0)

func fade_out_music() -> void:
	if music_fade:
		music_fade.kill()
	music_fade = create_tween()
	music_fade.tween_property(menu_music, "volume_db", -60.0, MUSIC_FADE_SECONDS)
	music_fade.tween_callback(menu_music.stop)
