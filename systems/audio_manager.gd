extends Node

var _music_player: AudioStreamPlayer
var _tween: Tween

func _ready() -> void:
    _music_player = AudioStreamPlayer.new()
    _music_player.bus = "Master" # Can be changed to "Music" if you have separate buses
    add_child(_music_player)

# Play music with a fade-in effect
# If music is already playing, it will crossfade to the new track
func play_music(stream: AudioStream, fade_duration: float = 1.0, volume_db: float = 0.0) -> void:
    print("AudioManager: play_music called with stream: ", stream)
    if stream == _music_player.stream and _music_player.playing:
        print("AudioManager: Stream already playing")
        return

    # If already playing, fade out first (or crossfade logic could be more complex)
    # For simplicity, we'll just switch and fade in
    if _music_player.playing:
        # Optional: Implement true crossfade with two players if needed
        # For now, we just stop and play new
        _music_player.stop()

    _music_player.stream = stream
    _music_player.volume_db = -80.0 # Start silent
    _music_player.play()
    print("AudioManager: Started playing stream")

    if _tween:
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(_music_player, "volume_db", volume_db, fade_duration)

# Stop music with a fade-out effect
func stop_music(fade_duration: float = 1.0) -> void:
    if not _music_player.playing:
        return

    if _tween:
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(_music_player, "volume_db", -80.0, fade_duration)
    _tween.tween_callback(_music_player.stop)

# Set volume immediately
func set_volume(volume_db: float) -> void:
    _music_player.volume_db = volume_db
