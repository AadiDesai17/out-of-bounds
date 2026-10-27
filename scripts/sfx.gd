extends Node
## Procedural sounds for the final cut: clock ticks (forward and reversed), the bass
## hit for twists, plates, doors, footsteps, a chime and a looping drone.

const RATE := 22050

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _drone := AudioStreamPlayer.new()
var _lp := [0.0]


func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_streams["tick"] = _make(0.06, _s_tick)
	_streams["tock_rev"] = _make(0.16, _s_tock_rev)
	_streams["braam"] = _make(2.6, _s_braam)
	_streams["plate"] = _make(0.2, _s_plate)
	_streams["door"] = _make(0.9, _s_door)
	_streams["step"] = _make(0.06, _s_step)
	_streams["chime"] = _make(1.2, _s_chime)
	_streams["riser"] = _make(1.4, _s_riser)
	_streams["drone"] = _make(2.0, _s_drone, true)
	_drone.stream = _streams["drone"]
	_drone.volume_db = -80.0
	add_child(_drone)
	_drone.play()


func play(sound: String, db: float = 0.0, pitch: float = 1.0) -> void:
	if not GameState.audio_enabled:
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[sound]
			p.volume_db = db
			p.pitch_scale = pitch
			p.play()
			return


## Fades the background drone to a level between 0 and 1.
func drone(level: float, secs: float = 1.5) -> void:
	var db := -80.0 if level <= 0.001 or not GameState.audio_enabled else linear_to_db(level)
	create_tween().tween_property(_drone, "volume_db", db, secs)


func _make(dur: float, fn: Callable, loop: bool = false) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var v: float = fn.call(float(i) / RATE)
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = n
	return w


func _noise() -> float:
	return randf() * 2.0 - 1.0


func _s_tick(t: float) -> float:
	return sin(TAU * 2600.0 * t) * exp(-t * 110.0) * 0.45 + _noise() * exp(-t * 400.0) * 0.35


## A tick played backwards: swells in, then cuts off.
func _s_tock_rev(t: float) -> float:
	var r := 0.16 - t
	return (sin(TAU * 1900.0 * t) * 0.4 + _noise() * 0.18) * exp(-r * 40.0)


func _s_braam(t: float) -> float:
	var env := minf(t / 0.05, 1.0) * exp(-t * 1.05)
	var f := 49.0
	var saw := 2.0 * fmod(t * f, 1.0) - 1.0
	var saw2 := 2.0 * fmod(t * f * 1.007 + 0.3, 1.0) - 1.0
	var sub := sin(TAU * f * 0.5 * t)
	return tanh((saw + saw2) * 1.3 + sub * 1.2) * env * 0.6


func _s_plate(t: float) -> float:
	return (sin(TAU * 150.0 * t * (1.0 - t * 1.5)) * exp(-t * 26.0) + _noise() * exp(-t * 90.0) * 0.4) * 0.6


func _s_door(t: float) -> float:
	_lp[0] = lerpf(_lp[0], _noise(), 0.05)
	return (_lp[0] * 2.5 * minf(t * 6.0, 1.0) * exp(-t * 2.5) + sin(TAU * 62.0 * t) * exp(-t * 3.0) * 0.4) * 0.7


func _s_step(t: float) -> float:
	_lp[0] = lerpf(_lp[0], _noise(), 0.25)
	return _lp[0] * exp(-t * 70.0) * 0.7


func _s_chime(t: float) -> float:
	return (sin(TAU * 880.0 * t) + 0.5 * sin(TAU * 1320.0 * t) + 0.3 * sin(TAU * 1760.0 * t)) * exp(-t * 3.5) * 0.25


## Reverse-cymbal swell used before a chapter card.
func _s_riser(t: float) -> float:
	_lp[0] = lerpf(_lp[0], _noise(), 0.3)
	return _lp[0] * pow(t / 1.4, 3.0) * 0.8


func _s_drone(t: float) -> float:
	return sin(TAU * 55.0 * t) * 0.25 + sin(TAU * 82.5 * t) * 0.12 + sin(TAU * 110.5 * t) * 0.06
