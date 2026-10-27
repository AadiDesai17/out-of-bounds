extends Node2D
## Narrator box (bottom) and SYSTEM_MSG box (top) with typewriter text.
## Lines are [speaker, text] where speaker is "N" (Narrator), "S" (SYSTEM_MSG) or "F".
## Narrator lines play a pre-generated voice from res://voice/ when one exists
## (see tools/gen_voices.py); the portrait lip-syncs to it. Lowercase stage directions
## like "[sighs]" steer the voice actor and are hidden from the on-screen text.

signal finished

const NARR_RECT := Rect2(16, 272, 608, 78)
const SYS_RECT := Rect2(150, 20, 340, 88)
const FUTURE_RECT := Rect2(284, 254, 340, 88)
const NARR_TEXT_W := 520
const SYS_TEXT_W := 322
const VOICE_MUFFLED := "[muffled] Mmph! Mmmph!"

var queue: Array = []
var who := ""
var text := ""
var shown := 0.0
var blocking := false
## Shown in the narrator box while no line is playing (empty = hidden).
var idle_narrator := ""
var history: Array = []
var auto_skip := false
## Draws the player's face in the narrator portrait (the "stay" ending).
var hero_portrait := false
var t := 0.0

var _last_blip := 0
var _voiced := false
var _done_t := 0.0
var _voice := AudioStreamPlayer.new()
var _bus := -1
var _mouth := 0.0
## Pushes the narrator box out of the way (he dodges the tooltip).
var narr_off := Vector2.ZERO
static var _tags: RegEx


func _ready() -> void:
	_bus = AudioServer.get_bus_index("Voice")
	if _bus == -1:
		AudioServer.add_bus()
		_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_bus, "Voice")
		AudioServer.add_bus_effect(_bus, AudioEffectSpectrumAnalyzer.new())
	_voice.bus = "Voice"
	add_child(_voice)


## The line as shown on screen: stage directions removed.
static func clean(line: String) -> String:
	if _tags == null:
		_tags = RegEx.create_from_string("\\[[a-z ]+\\]\\s*")
	return _tags.sub(line, "", true).strip_edges()


static func voice_path(line: String) -> String:
	return "res://voice/n_%s.mp3" % line.md5_text().substr(0, 12)


## Plays the recorded voice for a narrator line. Returns false when none exists.
func speak(line: String) -> bool:
	_voice.stop()
	if not GameState.audio_enabled or line == "":
		return false
	var p := voice_path(line)
	if not ResourceLoader.exists(p):
		return false
	_voice.stream = load(p)
	_voice.play()
	return true


func stop_voice() -> void:
	_voice.stop()


## Sets the lingering narrator text and speaks it if nothing else is playing.
func say_idle(line: String) -> void:
	idle_narrator = clean(line)
	if who == "" and not GameState.narrator_muted:
		speak(line)


func talk(seq: Array) -> void:
	queue.append_array(seq)
	if not blocking:
		blocking = true
		_next()


func advance() -> void:
	if shown < text.length():
		shown = text.length()
		_voiced = false
	else:
		SoundManager.play_click()
		_next()


func narrator_rect() -> Rect2:
	return Rect2(NARR_RECT.position + narr_off, NARR_RECT.size)


func dodge() -> void:
	var tw := create_tween()
	tw.tween_property(self, "narr_off", Vector2(0, 96), 0.12)
	tw.tween_interval(1.3)
	tw.tween_property(self, "narr_off", Vector2.ZERO, 0.25)


func narrator_visible() -> bool:
	return who == "N" or idle_narrator != ""


func _next() -> void:
	_voice.stop()
	_voiced = false
	_done_t = 0.0
	if queue.is_empty():
		blocking = false
		who = ""
		text = ""
		finished.emit()
		return
	var line: Array = queue.pop_front()
	who = line[0]
	var raw: String = line[1]
	if who == "N" and GameState.narrator_muted:
		raw = VOICE_MUFFLED
	text = clean(raw)
	if who == "N":
		_voiced = speak(raw)
	else:
		history.append(text)
	shown = 0.0
	_last_blip = 0


func _process(delta: float) -> void:
	t += delta
	if auto_skip and blocking:
		shown = text.length()
		_next()
	elif who != "":
		if shown < text.length():
			_done_t = 0.0
			if _voiced:
				var dur := maxf(_voice.stream.get_length() * 0.88, 0.4)
				shown = minf(text.length() * _voice.get_playback_position() / dur, text.length())
				if not _voice.playing:
					shown = text.length()
			else:
				shown = minf(shown + delta * (24.0 + GameState.text_speed * 1.2), text.length())
				var b := int(shown) / 3
				if b != _last_blip:
					_last_blip = b
					SoundManager.play_voice("NARRATOR" if who == "N" else "UNKNOWN USER")
		else:
			_done_t += delta
			# Voiced lines play like film: they move on by themselves.
			if _voiced and not _voice.playing and _done_t > 1.0:
				_next()
	var target := 0.0
	if _voice.playing:
		var inst := AudioServer.get_bus_effect_instance(_bus, 0) as AudioEffectSpectrumAnalyzerInstance
		if inst:
			target = clampf(inst.get_magnitude_for_frequency_range(80.0, 3500.0).length() * 22.0, 0.0, 1.0)
	elif who == "N" and shown < text.length():
		target = 1.0 if int(t * 12.0) % 2 == 0 else 0.0
	_mouth = lerpf(_mouth, target, 0.5)
	queue_redraw()


func _draw() -> void:
	if narrator_visible():
		var body := text.substr(0, int(shown)) if who == "N" else idle_narrator
		draw_narrator_box(body, who == "N" and shown >= text.length())
	if who == "S" or who == "F":
		draw_sys_box("SYSTEM_MSG" if who == "S" else "FUTURE_SELF", text.substr(0, int(shown)), FUTURE_RECT if who == "F" else SYS_RECT)


func draw_narrator_box(body: String, done: bool) -> void:
	var r := narrator_rect()
	draw_rect(Rect2(r.position + Vector2(3, 3), r.size), Color(0, 0, 0, 0.4))
	Art.box(self, r, Art.DARK, Art.TEAL, 2)
	draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, 11), Color("#1d2a2a"))
	PxFont.draw(self, r.position + Vector2(8, 4), "NARRATOR", Art.TEAL)
	var pr := Rect2(r.position.x + 8, r.position.y + 18, 52, 46)
	Art.box(self, pr, Art.DARK, Art.PARCH, 2)
	var sp := pr.position + Vector2(2, 2)
	if hero_portrait:
		Art.sprite(self, Art.HERO_TOP.slice(0, 13), Art.HERO_PAL, sp + Vector2(0, 2), 3.0)
	else:
		Art.sprite(self, Art.NARR, Art.NARR_PAL, sp, 3.0)
		if fmod(t, 3.7) < 0.13:
			draw_rect(Rect2(sp.x + 12, sp.y + 12, 6, 6), Color("#f2d98a"))
			draw_rect(Rect2(sp.x + 30, sp.y + 12, 6, 6), Color("#f2d98a"))
			draw_rect(Rect2(sp.x + 12, sp.y + 15, 6, 2), Art.OUTLINE)
			draw_rect(Rect2(sp.x + 30, sp.y + 15, 6, 2), Art.OUTLINE)
		if _mouth > 0.25:
			draw_rect(Rect2(sp.x + 15, sp.y + 33, 18, 3), Art.OUTLINE)
		if _mouth > 0.65:
			draw_rect(Rect2(sp.x + 18, sp.y + 30, 12, 3), Color("#7a1e1e"))
	PxFont.draw_block(self, r.position + Vector2(72, 20), PxFont.wrap(body, NARR_TEXT_W), Art.CREAM, 1, 11)
	if GameState.narrator_muted and not hero_portrait:
		_draw_gag(r)
	elif done and not _voiced and int(t * 3) % 2 == 0:
		_arrow(Vector2(r.end.x - 14, r.end.y - 10), Art.TEAL)


## The tooltip stuck over the Narrator's mouth, plus a mute sign.
func _draw_gag(r: Rect2) -> void:
	Art.tooltip(self, Rect2(r.position.x + 300, r.position.y + 18, 176, 40), true)
	var c := Vector2(r.end.x - 40, r.position.y + 42)
	draw_arc(c, 12, 0, TAU, 24, Art.RED, 3)
	draw_line(c + Vector2(-8, -8), c + Vector2(8, 8), Art.RED, 3)


func draw_sys_box(header: String, body: String, rect: Rect2) -> void:
	var r := rect
	if randf() < 0.04:
		r.position.x += 2
	draw_rect(Rect2(r.position + Vector2(3, 3), r.size), Color(0, 0, 0, 0.4))
	Art.box(self, r, Art.TEAL_DARK, Art.TEAL, 2)
	draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, 11), Color("#123234"))
	PxFont.draw(self, r.position + Vector2(8, 4), header, Art.TEAL)
	var lines := PxFont.wrap(body, SYS_TEXT_W)
	PxFont.draw_block(self, r.position + Vector2(9, 19), lines, Art.TEAL, 1, 11)
	if int(t * 3) % 2 == 0:
		var last := lines[lines.size() - 1]
		draw_rect(Rect2(r.position.x + 10 + PxFont.width(last) + 2, r.position.y + 19 + (lines.size() - 1) * 11, 5, 7), Art.TEAL)


func _arrow(p: Vector2, col: Color) -> void:
	draw_rect(Rect2(p.x, p.y, 7, 1), col)
	draw_rect(Rect2(p.x + 1, p.y + 1, 5, 1), col)
	draw_rect(Rect2(p.x + 2, p.y + 2, 3, 1), col)
	draw_rect(Rect2(p.x + 3, p.y + 3, 1, 1), col)
