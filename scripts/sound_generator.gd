extends Node

## OUT OF BOUNDS — Comic Procedural Audio Synthesizer
## Generates juicy cartoon sound effects, wacky speech babble, block pops, and spring boings.

var _click_stream: AudioStreamWAV
var _type_stream: AudioStreamWAV
var _error_stream: AudioStreamWAV
var _success_stream: AudioStreamWAV
var _glitch_stream: AudioStreamWAV
var _boing_stream: AudioStreamWAV
var _pop_stream: AudioStreamWAV
var _horn_stream: AudioStreamWAV
var _fanfare_stream: AudioStreamWAV

var _narrator_voice_stream: AudioStreamWAV
var _user_voice_stream: AudioStreamWAV
var _system_voice_stream: AudioStreamWAV
var _companion_voice_stream: AudioStreamWAV

# Retro & Parody Game Audio Streams
var _jump_stream: AudioStreamWAV
var _coin_stream: AudioStreamWAV
var _laser_stream: AudioStreamWAV
var _explosion_stream: AudioStreamWAV
var _slash_stream: AudioStreamWAV
var _mgs_stream: AudioStreamWAV

var _sfx_players: Array[AudioStreamPlayer] = []
const SAMPLE_RATE = 22050

func _ready() -> void:
	_generate_all_audio()
	for i in range(16):
		var p = AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)

func _generate_all_audio() -> void:
	_click_stream = _create_click()
	_type_stream = _create_blip(900.0, 0.03)
	_error_stream = _create_error()
	_success_stream = _create_success()
	_glitch_stream = _create_glitch()
	_boing_stream = _create_boing()
	_pop_stream = _create_pop()
	_horn_stream = _create_horn()
	_fanfare_stream = _create_fanfare()
	
	_narrator_voice_stream = _create_narrator_blip()
	_user_voice_stream = _create_user_blip()
	_system_voice_stream = _create_system_blip()
	_companion_voice_stream = _create_companion_blip()
	
	_jump_stream = _create_mario_jump()
	_coin_stream = _create_mario_coin()
	_laser_stream = _create_laser()
	_explosion_stream = _create_explosion()
	_slash_stream = _create_slash()
	_mgs_stream = _create_mgs_alert()

func _play_stream(stream: AudioStreamWAV, volume_db: float = -6.0, pitch_scale: float = 1.0) -> void:
	if not GameState.audio_enabled:
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = pitch_scale
			player.play()
			return

func play_click() -> void:
	_play_stream(_click_stream, -6.0, randf_range(0.9, 1.1))

func play_typewriter() -> void:
	_play_stream(_type_stream, -14.0, randf_range(0.85, 1.25))

func play_voice(speaker_name: String) -> void:
	match speaker_name:
		"NARRATOR":
			_play_stream(_narrator_voice_stream, -8.0, randf_range(0.9, 1.3))
		"UNKNOWN USER":
			_play_stream(_user_voice_stream, -10.0, randf_range(1.1, 1.5))
		"BUDDY", "COMPANION":
			_play_stream(_companion_voice_stream, -7.0, randf_range(1.0, 1.4))
		_:
			_play_stream(_system_voice_stream, -10.0, randf_range(0.8, 1.0))

func play_error() -> void:
	_play_stream(_error_stream, -4.0, 1.0)

func play_success() -> void:
	_play_stream(_success_stream, -4.0, 1.0)

func play_glitch() -> void:
	_play_stream(_glitch_stream, -2.0, randf_range(0.8, 1.3))

func play_boing() -> void:
	_play_stream(_boing_stream, -5.0, randf_range(0.95, 1.15))

func play_pop() -> void:
	_play_stream(_pop_stream, -4.0, randf_range(0.9, 1.4))

func play_horn() -> void:
	_play_stream(_horn_stream, -3.0, 1.0)

func play_fanfare() -> void:
	_play_stream(_fanfare_stream, -4.0, 1.0)

func play_mario_jump() -> void:
	_play_stream(_jump_stream, -5.0, randf_range(0.95, 1.05))

func play_mario_coin() -> void:
	_play_stream(_coin_stream, -4.0, 1.0)

func play_laser() -> void:
	_play_stream(_laser_stream, -6.0, randf_range(0.9, 1.1))

func play_explosion() -> void:
	_play_stream(_explosion_stream, -3.0, randf_range(0.85, 1.15))

func play_slash() -> void:
	_play_stream(_slash_stream, -4.0, randf_range(0.9, 1.2))

func play_mgs_alert() -> void:
	_play_stream(_mgs_stream, -2.0, 1.0)

# --- Procedural Audio Synthesizers ---

func _create_click() -> AudioStreamWAV:
	var frames = int(SAMPLE_RATE * 0.02)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-t * 220.0)
		var val = (randf() * 2.0 - 1.0) * env * 0.8
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_blip(freq: float, duration: float) -> AudioStreamWAV:
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var env = 1.0 - (float(i) / frames)
		var val = sin(TAU * freq * t) * env * 0.4
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_narrator_blip() -> AudioStreamWAV:
	# Comic Banjo-Kazooie style cheeky voice chirp
	var duration = 0.06
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var env = sin(PI * (float(i) / frames))
		var f = 340.0 + sin(TAU * 25.0 * t) * 80.0
		var saw = fmod(t * f, 1.0) * 2.0 - 1.0
		var val = saw * env * 0.35
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_user_blip() -> AudioStreamWAV:
	# Soft, cute, bewildered high-pitch flute chirp
	var duration = 0.05
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var env = sin(PI * (float(i) / frames))
		var val = sin(TAU * 680.0 * t) * env * 0.3
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_system_blip() -> AudioStreamWAV:
	# Cold metallic robotic diagnostic pulse
	var duration = 0.04
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-t * 70.0)
		var square = 1.0 if sin(TAU * 1200.0 * t) >= 0.0 else -1.0
		var val = square * env * 0.25
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_pop() -> AudioStreamWAV:
	# Juicy cartoon block pop
	var duration = 0.06
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / frames
		var f = lerp(850.0, 220.0, progress * progress)
		var env = sin(PI * progress)
		var val = sin(TAU * f * t) * env * 0.6
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_boing() -> AudioStreamWAV:
	# Cartoon spring boing
	var duration = 0.35
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / frames
		var f = lerp(160.0, 520.0, progress) + sin(TAU * 22.0 * t) * 35.0
		var env = exp(-t * 5.0)
		var val = sin(TAU * f * t) * env * 0.55
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_horn() -> AudioStreamWAV:
	# Funny cartoon honk/fail buzzer
	var duration = 0.25
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var env = 1.0 - (float(i) / frames)
		var square = 1.0 if sin(TAU * 140.0 * t) >= 0.0 else -1.0
		var val = square * env * 0.4
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_fanfare() -> AudioStreamWAV:
	# Happy arcade combo fanfare: C5 -> E5 -> G5 -> C6
	var duration = 0.5
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	var notes = [523.25, 659.25, 783.99, 1046.50]
	var note_dur = 0.125
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var note_idx = int(clamp(floor(t / note_dur), 0, 3))
		var f = notes[note_idx]
		var note_t = fmod(t, note_dur)
		var env = exp(-note_t * 8.0)
		var val = sin(TAU * f * t) * env * 0.45
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_error() -> AudioStreamWAV:
	var duration = 0.28
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var f = 160.0 if t < 0.14 else 120.0
		var square = 1.0 if sin(TAU * f * t) >= 0.0 else -1.0
		var env = 1.0 - (float(i) / frames)
		var val = square * env * 0.5
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_success() -> AudioStreamWAV:
	return _create_fanfare()

func _create_glitch() -> AudioStreamWAV:
	var duration = 0.22
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	var current_step = 0.0
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		if i % 18 == 0:
			current_step = randf() * 2.0 - 1.0
		var square = 1.0 if sin(TAU * 70.0 * t) > 0.0 else -1.0
		var env = 1.0 - (float(i) / frames)
		var val = (current_step * 0.7 + square * 0.3) * env * 0.6
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_companion_blip() -> AudioStreamWAV:
	# High On Life companion squeaky saw chirp
	var duration = 0.05
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var env = sin(PI * (float(i) / frames))
		var f = 720.0 + sin(TAU * 40.0 * t) * 160.0
		var saw = fmod(t * f, 1.0) * 2.0 - 1.0
		var val = saw * env * 0.35
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_mario_jump() -> AudioStreamWAV:
	var duration = 0.18
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / frames
		var f = lerp(140.0, 560.0, progress)
		var square = 1.0 if sin(TAU * f * t) >= 0.0 else -1.0
		var env = 1.0 - progress * 0.4
		var val = square * env * 0.45
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_mario_coin() -> AudioStreamWAV:
	var duration = 0.32
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var f = 987.77 if t < 0.065 else 1318.51
		var square = 1.0 if sin(TAU * f * t) >= 0.0 else -1.0
		var env = exp(-t * 8.0)
		var val = square * env * 0.45
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_laser() -> AudioStreamWAV:
	var duration = 0.13
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / frames
		var f = lerp(1700.0, 240.0, progress * progress)
		var square = 1.0 if sin(TAU * f * t) >= 0.0 else -1.0
		var env = 1.0 - progress
		var val = square * env * 0.4
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_explosion() -> AudioStreamWAV:
	var duration = 0.32
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var _progress = float(i) / frames
		var env = exp(-t * 9.0)
		var noise = (randf() * 2.0 - 1.0) * env
		var rumble = sin(TAU * 65.0 * t) * env * 0.5
		var val = (noise * 0.7 + rumble * 0.3) * 0.6
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_slash() -> AudioStreamWAV:
	var duration = 0.2
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-t * 14.0)
		var metallic = sin(TAU * 1250.0 * t) * 0.4 + sin(TAU * 2400.0 * t) * 0.25
		var whoosh = (randf() * 2.0 - 1.0) * 0.4
		var val = (metallic + whoosh) * env * 0.5
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _create_mgs_alert() -> AudioStreamWAV:
	var duration = 0.35
	var frames = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-fmod(t, 0.16) * 12.0)
		var f = 1150.0 if t < 0.16 else 1450.0
		var square = 1.0 if sin(TAU * f * t) >= 0.0 else -1.0
		var val = square * env * 0.55
		bytes.encode_s16(i * 2, int(clamp(val, -1.0, 1.0) * 32767.0))
	return _make_wav(bytes)

func _make_wav(bytes: PackedByteArray) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	return wav
