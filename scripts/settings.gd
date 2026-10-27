extends Node2D
## Pixel settings window. Every control applies live through GameState.

signal closed

const WIN := Rect2(120, 36, 390, 262)
const TABS := ["GRAPHICS", "AUDIO", "GAMEPLAY", "ACCESSIBILITY", "CONTROLS", "ADVANCED"]

var open := false
var tab := 0
var dragging := ""
var drag_rect := Rect2()
var msg := ""
var msg_t := 0.0


func _ready() -> void:
	visible = false


func show_menu() -> void:
	open = true
	visible = true
	msg_t = 0.0


func close() -> void:
	open = false
	visible = false
	dragging = ""
	closed.emit()


func _process(delta: float) -> void:
	msg_t = maxf(msg_t - delta, 0.0)
	if open:
		queue_redraw()


func _rows() -> Array:
	match tab:
		0:
			return [["slider", "BRIGHTNESS", "brightness"], ["slider", "CONTRAST", "contrast"], ["toggle", "FULLSCREEN", "fullscreen"], ["toggle", "CRT FILTER", "crt"], ["toggle", "SCREEN SHAKE", "screen_shake"]]
		1:
			return [["slider", "MASTER VOLUME", "master_volume"], ["slider", "NARRATOR VOLUME", "narrator_volume"], ["toggle", "SOUND", "audio_enabled"]]
		2:
			return [["slider", "TEXT SPEED", "text_speed"], ["label", "SKIP TUTORIAL: NO TUTORIAL", ""], ["label", "DIFFICULTY: NARRATOR KNOWS BEST", ""]]
		3:
			return [["toggle", "COLOR BLIND MODE", "color_blind"], ["toggle", "INVERT COLORS", "invert"], ["toggle", "HIGH CONTRAST", "high_contrast"], ["label", "TIP: TRY DIFFERENT FILTERS.", ""], ["label", "YOU MIGHT SEE SOMETHING NEW.", ""]]
		4:
			return [["label", "A / D ........ WALK", ""], ["label", "E / W ........ INTERACT", ""], ["label", "MOUSE ........ POINT, DRAG", ""], ["label", "SPACE ........ NEXT LINE", ""], ["label", "ESC .......... SETTINGS", ""]]
		_:
			return [["label", "DEVELOPER MODE: [LOCKED]", ""], ["label", "REQUIRES A DEV_ONLY TOOLTIP", ""], ["label", "NARRATOR.EXE: RUNNING", ""], ["label", "END TASK: ACCESS DENIED", ""]]


func _row_y(i: int) -> float:
	return WIN.position.y + 26 + i * 22


func _tab_rect(i: int) -> Rect2:
	return Rect2(WIN.position.x + 4, WIN.position.y + 18 + i * 16, 92, 14)


func _slider_rect(i: int) -> Rect2:
	return Rect2(WIN.end.x - 112, _row_y(i) + 1, 72, 4)


func _toggle_rect(i: int) -> Rect2:
	return Rect2(WIN.end.x - 56, _row_y(i) - 2, 30, 11)


func _btn(i: int) -> Rect2:
	return Rect2(WIN.end.x - 140 + i * 68, WIN.end.y - 22, 60, 15)


func _get_val(key: String) -> Variant:
	match key:
		"fullscreen":
			return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		"narrator_volume":
			return 100.0
	return GameState.get(key)


func _set_val(key: String, v: Variant) -> void:
	match key:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if v else DisplayServer.WINDOW_MODE_WINDOWED)
		"narrator_volume":
			_say("THE NARRATOR CANNOT BE MADE QUIETER.")
			return
		_:
			GameState.set(key, v)
	GameState.changed()


func _say(s: String) -> void:
	msg = s
	msg_t = 2.5


func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		SoundManager.play_click()
		close()
		return
	var m := get_local_mouse_position()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(m)
		else:
			dragging = ""
	elif event is InputEventMouseMotion and dragging != "":
		_slide(m)


func _press(m: Vector2) -> void:
	if Art.close_rect(WIN).has_point(m) or _btn(1).has_point(m):
		SoundManager.play_click()
		close()
		return
	if _btn(0).has_point(m):
		SoundManager.play_success()
		_say("SETTINGS APPLIED. PROBABLY.")
		return
	for i in TABS.size():
		if _tab_rect(i).has_point(m):
			tab = i
			SoundManager.play_click()
			return
	var rows := _rows()
	for i in rows.size():
		var row: Array = rows[i]
		if row[0] == "toggle" and _toggle_rect(i).grow(2).has_point(m):
			SoundManager.play_click()
			_set_val(row[2], not bool(_get_val(row[2])))
			return
		if row[0] == "slider" and _slider_rect(i).grow(5).has_point(m):
			dragging = row[2]
			drag_rect = _slider_rect(i)
			_slide(m)
			return


func _slide(m: Vector2) -> void:
	var v := clampf((m.x - drag_rect.position.x) / drag_rect.size.x * 100.0, 0.0, 100.0)
	_set_val(dragging, roundf(v))


func _draw() -> void:
	if not open:
		return
	var m := get_local_mouse_position()
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.55))
	Art.window(self, WIN, "SETTINGS")
	draw_rect(Rect2(WIN.position.x + 2, WIN.position.y + 14, 96, WIN.size.y - 16), Art.PARCH_DARK)
	for i in TABS.size():
		var r := _tab_rect(i)
		if i == tab:
			draw_rect(r, Art.TEAL)
		elif r.has_point(m):
			draw_rect(r, Color(1, 1, 1, 0.25))
		PxFont.draw(self, r.position + Vector2(5, 4), TABS[i], Art.TEAL_DARK if i == tab else Art.INK)
	var rows := _rows()
	for i in rows.size():
		var row: Array = rows[i]
		var y := _row_y(i)
		PxFont.draw(self, Vector2(WIN.position.x + 108, y), row[1], Art.INK)
		if row[0] == "slider":
			var v := float(_get_val(row[2]))
			var sr := _slider_rect(i)
			draw_rect(sr, Color("#8f8468"))
			draw_rect(Rect2(sr.position, Vector2(sr.size.x * v / 100.0, sr.size.y)), Art.TEAL)
			var kx := roundf(sr.position.x + sr.size.x * v / 100.0 - 2)
			Art.box(self, Rect2(kx, sr.position.y - 3, 5, 10), Art.PARCH, Art.OUTLINE)
			PxFont.draw(self, Vector2(sr.end.x + 7, y), str(int(v)), Art.INK)
		elif row[0] == "toggle":
			var on := bool(_get_val(row[2]))
			var tr := _toggle_rect(i)
			Art.box(self, tr, Art.TEAL if on else Color("#5a5040"), Art.OUTLINE)
			PxFont.draw_centered(self, tr.get_center().x, tr.position.y + 2, "ON" if on else "OFF", Art.TEAL_DARK if on else Art.PARCH)
	Art.button(self, _btn(0), "APPLY", _btn(0).has_point(m))
	Art.button(self, _btn(1), "BACK", _btn(1).has_point(m))
	if msg_t > 0.0:
		PxFont.draw(self, Vector2(WIN.position.x + 108, WIN.end.y - 42), msg, Art.RED)
	Art.sticky(self, Vector2(WIN.end.x + 34, WIN.position.y + 64), Vector2(58, 50), 0.08, ["CHANGE", "THINGS.", "SEE", "THINGS."])
