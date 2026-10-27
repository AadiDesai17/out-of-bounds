extends Screen
## The Realm of Order. Rooms:
##   "pledge"  the first room (Act I: plate puzzle; Act II: the same room again)
##   "doors"   the door hall (tooltip gag, inverted time, keypad)
##   "climax"  the door hall at the end: the exit is open

const FLOOR_Y := 132.0
const DOOR_W := 28.0
const DOOR_H := 38.0
const DOORS := [
	{"id": "path_a", "x": 52.0, "label": "PATH A"},
	{"id": "path_b", "x": 146.0, "label": "PATH B"},
	{"id": "exit", "x": 240.0, "label": "EXIT"},
]
const PLATES := [{"x": 84.0, "sym": "star"}, {"x": 140.0, "sym": "sun"}, {"x": 196.0, "sym": "moon"}]
const ORDER := ["sun", "moon", "star"]
const PLEDGE_DOOR := Rect2(282, 96, 24, 36)
const KEYPAD := Rect2(278, 98, 14, 20)
const TT_HOME := Rect2(410, 100, 176, 40)
const PAD_WIN := Rect2(250, 132, 140, 136)
const PAD_KEYS := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "CLR", "0", "OK"]
const CODE := "0814"
const WARM := Color("#ffe2a8")

var room := "pledge"
var hero_x := 20.0
var facing := 1
var walk_t := 0.0
var moving := false
var hero_gone := false
var e_was := false
var step_acc := 0.0
var has_moved := false

var pressed: Array = []
var on_plate := -1
var plate_reset := 0.0

## hidden -> shown (double-click the exit door) -> drag / free
var tt_state := "hidden"
var tt_pos := TT_HOME.position
var grab_off := Vector2.ZERO
var dodges := 0
var push_cd := 0.0
var pushing := false
## Climax: >= 0 while your trapped self walks out and you are pulled in.
var swap_t := -1.0
## The path door the hero is walking through (-1 = none).
var enter_door := -1

var pad_open := false
var pad_code := ""
var pad_err := 0.0
var flash := ""
var flash_t := 0.0


func set_room(r: String, x: float = 20.0) -> void:
	room = r
	hero_x = x
	facing = 1
	pad_open = false
	if tt_state != "hidden":
		tt_state = "shown"
	tt_pos = TT_HOME.position
	pressed.clear()


func act() -> int:
	return main.act


func pledge_open() -> bool:
	return act() >= 2 or GameState.flag("pledge_solved")


func revealed() -> bool:
	return room == "doors" and GameState.invert and GameState.narrator_muted


func hero_center() -> float:
	return hero_x + 7.5


func door_rect(i: int) -> Rect2:
	return Rect2(DOORS[i]["x"], FLOOR_Y - DOOR_H, DOOR_W, DOOR_H)


func _door_hud(i: int) -> Rect2:
	var r := door_rect(i)
	return Rect2(r.position * 2.0, r.size * 2.0)


func _gear_rect() -> Rect2:
	return Rect2(612, 6, 22, 20)


func tt_rect() -> Rect2:
	return Rect2(tt_pos, TT_HOME.size)


func _tt_visible() -> bool:
	return room == "doors" and not GameState.narrator_muted and tt_state != "hidden"


## What the hero would interact with right now ("" for nothing).
func _target() -> String:
	var c := hero_center()
	if room == "pledge":
		return "door" if c > 276.0 else ""
	if revealed() and absf(c - KEYPAD.get_center().x) < 10.0:
		return "keypad"
	for d in DOORS:
		if absf(c - (d["x"] + DOOR_W / 2.0)) < 14.0:
			return d["id"]
	return ""


func update(delta: float) -> void:
	flash_t = maxf(flash_t - delta, 0.0)
	pad_err = maxf(pad_err - delta, 0.0)
	moving = false
	var e := Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	push_cd = maxf(push_cd - delta, 0.0)
	if swap_t >= 0.0:
		swap_t += delta
	if can_play() and not pad_open and not hero_gone and not pushing:
		var dir := 0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			dir -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			dir += 1
		if dir != 0:
			facing = dir
			moving = true
			has_moved = true
			walk_t += delta
			hero_x = clampf(hero_x + dir * 64.0 * delta, 2.0, 300.0)
			step_acc += delta
			if step_acc > 0.27:
				step_acc = 0.0
				Sfx.play("step", -10.0, randf_range(0.8, 1.2))
		if e and not e_was:
			_interact()
	e_was = e
	if room == "pledge":
		_update_plates(delta)
	# The Narrator physically keeps you away from the exit until he's gagged.
	if room == "doors" and not GameState.narrator_muted and hero_center() > 212.0 and not pushing and can_play():
		_push_back()


func _push_back() -> void:
	pushing = true
	Sfx.play("door", -6.0, 1.6)
	main.shake = 0.7
	if push_cd <= 0.0:
		main.on_event("pushback")
		push_cd = 3.0
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "hero_x", 150.0, 0.45)
	await tw.finished
	pushing = false


func _update_plates(delta: float) -> void:
	if plate_reset > 0.0:
		plate_reset -= delta
		if plate_reset <= 0.0:
			pressed.clear()
		return
	if pledge_open():
		return
	var now := -1
	for i in PLATES.size():
		if absf(hero_center() - (PLATES[i]["x"] + 8.0)) < 6.0:
			now = i
	if now != on_plate and now >= 0 and not PLATES[now]["sym"] in pressed:
		pressed.append(PLATES[now]["sym"])
		Sfx.play("plate")
		if pressed != ORDER.slice(0, pressed.size()):
			plate_reset = 0.5
			SoundManager.play_error()
			main.on_event("plate_wrong")
		elif pressed.size() == ORDER.size():
			GameState.set_flag("pledge_solved")
			main.on_event("pledge_solved")
	on_plate = now


func _interact() -> void:
	var tgt := _target()
	if tgt == "":
		return
	if tgt == "keypad":
		_open_pad()
	elif tgt == "door":
		if act() >= 2:
			main.on_event("to_doors")
		elif pledge_open():
			main.on_event("pledge_door")
		else:
			main.on_event("pledge_locked")
	elif room == "climax":
		main.on_event("climax_" + tgt)
	else:
		main.on_event(tgt)


func handle_input(event: InputEvent) -> void:
	if pad_open:
		_pad_input(event)
		return
	var hm := hmouse()
	if clicked(event):
		if _gear_rect().has_point(hm):
			main.open_settings()
		elif room == "doors" and tt_state == "hidden" and event.double_click and _door_hud(2).has_point(hm) and not GameState.narrator_muted:
			tt_state = "shown"
			SoundManager.play_pop()
			main.on_event("tooltip_shown")
		elif _tt_visible() and tt_rect().has_point(hm):
			tt_state = "drag"
			grab_off = hm - tt_pos
			main.grabbing = true
			SoundManager.play_pop()
			if not GameState.flag("tt_grab"):
				GameState.set_flag("tt_grab")
				main.on_event("tooltip_grab")
		elif revealed() and Rect2(KEYPAD.position * 2.0, KEYPAD.size * 2.0).has_point(hm):
			_open_pad()
	elif released(event) and tt_state == "drag":
		main.grabbing = false
		if main.dialog.narrator_visible() and main.dialog.narr_off.y < 4.0 and main.dialog.narrator_rect().has_point(hm):
			tt_state = "shown"
			tt_pos = TT_HOME.position
			main.on_event("narrator_muted")
		elif _door_hud(2).has_point(hm):
			tt_state = "shown"
			tt_pos = TT_HOME.position
			main.on_event("tooltip_on_door")
		else:
			tt_state = "free"
	elif event is InputEventMouseMotion and tt_state == "drag":
		tt_pos = (hm - grab_off).clamp(Vector2.ZERO, Vector2(640, 360) - TT_HOME.size)
		# He dodges twice, then he's too tired.
		var nr: Rect2 = main.dialog.narrator_rect()
		if dodges < 2 and main.dialog.narrator_visible() and main.dialog.narr_off.y < 1.0 and nr.grow(10).intersects(tt_rect()):
			dodges += 1
			main.dialog.dodge()
			main.on_event("narrator_dodge")


# --- Keypad -------------------------------------------------------------

func _open_pad() -> void:
	pad_open = true
	pad_code = ""
	SoundManager.play_click()


func _pad_btn(i: int) -> Rect2:
	return Rect2(PAD_WIN.position.x + 10 + (i % 3) * 42, PAD_WIN.position.y + 44 + int(i / 3) * 22, 38, 20)


func _pad_input(event: InputEvent) -> void:
	var hm := hmouse()
	if clicked(event):
		if Art.close_rect(PAD_WIN).has_point(hm):
			pad_open = false
			SoundManager.play_click()
			return
		for i in PAD_KEYS.size():
			if _pad_btn(i).has_point(hm):
				pad_press(PAD_KEYS[i])
				return
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_0 and event.keycode <= KEY_9:
			pad_press(str(event.keycode - KEY_0))
		elif event.keycode >= KEY_KP_0 and event.keycode <= KEY_KP_9:
			pad_press(str(event.keycode - KEY_KP_0))
		elif event.keycode == KEY_BACKSPACE:
			pad_code = pad_code.left(-1)
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			pad_press("OK")


func pad_press(k: String) -> void:
	match k:
		"CLR":
			pad_code = ""
			SoundManager.play_typewriter()
		"OK":
			pad_submit()
		_:
			if pad_code.length() < 4:
				pad_code += k
			SoundManager.play_typewriter()
			if pad_code.length() == 4:
				pad_submit()


func pad_submit() -> void:
	if pad_code == CODE:
		pad_open = false
		Sfx.play("chime")
		main.on_event("keypad_ok")
	else:
		SoundManager.play_error()
		pad_err = 0.8
		pad_code = ""
		main.shake = 1.0
		main.on_event("pad_wrong")


# --- Drawing ------------------------------------------------------------

func draw_world() -> void:
	var w := world
	Art.bricks(w, Rect2(0, 0, 320, FLOOR_Y), 3 if room == "pledge" else 5)
	Art.floor_planks(w, Rect2(0, FLOOR_Y, 320, 180 - FLOOR_Y))
	if room == "pledge":
		_draw_pledge(w)
	else:
		_draw_doors(w)
	_dust(w)
	if swap_t >= 0.0:
		_draw_swap(w)
	elif not hero_gone:
		var fr := 1 if moving and int(walk_t * 8.0) % 2 == 1 else 0
		w.draw_rect(Rect2(roundf(hero_x) + 2, FLOOR_Y - 1, 12, 2), Color(0, 0, 0, 0.3))
		Art.hero(w, Vector2(roundf(hero_x), FLOOR_Y - 16 - (1 if fr == 1 else 0)), fr, facing < 0)
		if _target() != "" and can_play() and not pad_open:
			var bx := roundf(hero_x + 3)
			var by := FLOOR_Y - 30 + roundf(sin(t * 5.0))
			Art.box(w, Rect2(bx, by, 9, 11), Art.PARCH, Art.OUTLINE)
			PxFont.draw(w, Vector2(bx + 2, by + 2), "E", Art.INK)


## Your trapped self steps out of the exit as a ghost and turns solid; you fade into the wall.
func _draw_swap(w: Node2D) -> void:
	var door_x: float = DOORS[2]["x"] + 6.0
	var gx := door_x - swap_t * 24.0
	var freed := swap_t > 1.4
	Art.hero(w, Vector2(roundf(gx), FLOOR_Y - 16), int(swap_t * 8.0) % 2, true, Art.HERO_PAL if freed else Art.GHOST_PAL)
	if swap_t < 3.0:
		var px := hero_x + maxf(swap_t - 1.4, 0.0) * 10.0
		var pal: Dictionary = Art.GHOST_PAL if freed else Art.HERO_PAL
		if not freed or int(swap_t * 14.0) % 2 == 0 or swap_t < 2.2:
			Art.hero(w, Vector2(roundf(px), FLOOR_Y - 16), 0, false, pal)
	if swap_t > 1.2 and swap_t < 1.7:
		w.draw_rect(Rect2(0, 0, 320, 180), Color(0.8, 1, 0.95, 0.35))


## Floating dust in the torchlight. It drifts upward while time is inverted.
func _dust(w: Node2D) -> void:
	var dir := -1.0 if GameState.invert else 1.0
	for i in 26:
		var x := fmod(i * 53.7 + t * (2.0 + i % 3) + 400.0, 320.0)
		var y := fmod(i * 29.3 + t * 3.0 * dir + 600.0, FLOOR_Y)
		w.draw_rect(Rect2(roundf(x), roundf(y + sin(t + i) * 2.0), 1, 1), Color(1, 0.86, 0.6, 0.22 + 0.1 * sin(t * 2.0 + i)))


func _draw_pledge(w: Node2D) -> void:
	# stained-glass window
	var win := Rect2(60, 24, 36, 54)
	Art.arch(w, win.grow(3), Color("#2b1912"))
	Art.arch(w, win, Color("#7ab8d8"))
	for i in 12:
		w.draw_rect(Rect2(win.position.x + 4 + i, win.position.y + 38 - i, maxf(24 - 2 * i, 1), 1), Color("#4a6a8a"))
	w.draw_rect(Rect2(win.position.x, win.position.y + 40, win.size.x, 14), Color("#4f7a4a"))
	w.draw_rect(Rect2(win.position.x + 26, win.position.y + 30, 3, 12), Color("#3a2416"))
	w.draw_rect(Rect2(win.position.x + 22, win.position.y + 24, 11, 8), Color("#2e6a2e"))
	w.draw_rect(Rect2(win.get_center().x - 1, win.position.y - 4, 2, win.size.y + 4), Color("#2b1912"))
	w.draw_rect(Rect2(win.position.x, win.position.y + 22, win.size.x, 2), Color("#2b1912"))
	w.draw_rect(Rect2(win.position.x - 4, win.end.y, win.size.x + 8, 4), Color("#6a5a4a"))
	# banner with the plate order
	w.draw_rect(Rect2(146, 14, 30, 2), Color("#6a4a2a"))
	w.draw_rect(Rect2(150, 16, 22, 46), Color("#2a3a6a"))
	w.draw_rect(Rect2(150, 62, 5, 6), Color("#2a3a6a"))
	w.draw_rect(Rect2(167, 62, 5, 6), Color("#2a3a6a"))
	w.draw_rect(Rect2(152, 61, 18, 2), Color("#2a3a6a"))
	w.draw_rect(Rect2(152, 18, 18, 1), Art.GOLD)
	for i in ORDER.size():
		Art.symbol(w, ORDER[i], Vector2(161, 27 + i * 12), Art.GOLD)
	# the stopped clock: 08:14 the first time, 08:13 the second
	var clock := Rect2(222, 28, 40, 18)
	Art.box(w, clock.grow(1), Color("#1a0606"), Color("#6a4a2a"))
	w.draw_rect(clock.grow(-2), Color("#120404"))
	var digits := "08:14" if act() < 2 else "08:13"
	PxFont.draw_centered(w, clock.get_center().x, clock.position.y + 6, digits, Color("#ff3b2e"))
	w.draw_rect(Rect2(clock.position.x + 4, clock.end.y + 1, clock.size.x - 8, 1), Color(1, 0.2, 0.15, 0.25))
	for x in [32.0, 120.0, 196.0, 270.0]:
		Art.torch(w, Vector2(x, 62), t)
	# floor plates, each with its symbol on a stone tablet above it
	for i in PLATES.size():
		var px: float = PLATES[i]["x"]
		var lit: bool = PLATES[i]["sym"] in pressed or (pledge_open() and act() < 2)
		var bad: bool = plate_reset > 0.0 and PLATES[i]["sym"] in pressed
		var tab := Rect2(px + 1, 92, 14, 14)
		if lit:
			w.draw_rect(tab.grow(4), Color(1, 0.8, 0.3, 0.15))
		Art.box(w, tab, Color("#3a2e26") if not lit else Color("#5a4a22"), Art.OUTLINE)
		var col := Art.RED if bad else (Art.GOLD if lit else Color("#b0a088"))
		Art.symbol(w, PLATES[i]["sym"], tab.get_center(), col)
		w.draw_rect(Rect2(px + 7, 106, 2, FLOOR_Y - 109), Color(0, 0, 0, 0.18))
		var slab := Rect2(px, FLOOR_Y - (1 if lit else 3), 16, 3 if not lit else 2)
		Art.box(w, slab, Color("#8a7a62") if not lit else Art.GOLD, Art.OUTLINE)
		if lit:
			w.draw_rect(Rect2(px - 2, FLOOR_Y - 5, 20, 4), Color(1, 0.8, 0.3, 0.2))
	# the door onward
	var open := pledge_open()
	if open:
		w.draw_rect(PLEDGE_DOOR.grow(6), Color(1, 0.9, 0.6, 0.12 + 0.05 * sin(t * 3.0)))
	Art.door(w, PLEDGE_DOOR, open, WARM)
	Art.plaque(w, PLEDGE_DOOR.get_center().x, 74, ">>", false)
	if not open:
		w.draw_rect(Rect2(PLEDGE_DOOR.get_center().x - 3, PLEDGE_DOOR.position.y + 14, 6, 6), Color("#6a6a74"))
		w.draw_rect(Rect2(PLEDGE_DOOR.get_center().x - 2, PLEDGE_DOOR.position.y + 11, 4, 3), Color("#6a6a74"))


func _draw_doors(w: Node2D) -> void:
	var inv := GameState.invert
	for x in [22.0, 113.0, 207.0, 300.0]:
		Art.torch(w, Vector2(x, 66), t, inv)
	var climax := room == "climax"
	var p := 0.5 + 0.5 * sin(t * 3.0)
	if climax:
		_light_beam(w, door_rect(2), Color(0.85, 1, 0.97), p)
	for i in DOORS.size():
		var d: Dictionary = DOORS[i]
		var through := enter_door == i
		Art.door(w, door_rect(i), (climax and i == 2) or through, Color("#0a0606") if through else Color("#f4fffd"))
		Art.plaque(w, d["x"] + DOOR_W / 2.0, 76, d["label"], i == 2)
	if revealed():
		# Light colors: they read dark once the screen is inverted.
		PxFont.draw_centered(w, 160, 56, "WHEN DID IT START?", Color("#f6f6f6"), 2)
		for y in range(0, 14, 3):
			w.draw_rect(Rect2(60, y, 2, 2), Color("#d8d8d8"))
			w.draw_rect(Rect2(258, y, 2, 2), Color("#d8d8d8"))
		# your own silhouette, walking backwards through time
		var sx := 262.0 - fmod(t * 14.0, 200.0)
		Art.hero(w, Vector2(roundf(sx), FLOOR_Y - 16), int(t * 6.0) % 2, false, Art.SHADOW_PAL)
		Art.box(w, KEYPAD, Color("#d5d5d5"), Color("#f6f6f6"))
		w.draw_rect(Rect2(KEYPAD.position.x + 2, KEYPAD.position.y + 2, 10, 4), Color("#c02640"))
		for i in 3:
			for j in 3:
				w.draw_rect(Rect2(KEYPAD.position.x + 2 + i * 4, KEYPAD.position.y + 8 + j * 4, 2, 2), Color("#8a8a8a"))


func _light_beam(w: Node2D, d: Rect2, col: Color, p: float) -> void:
	var c1 := col
	c1.a = 0.14 + 0.08 * p
	w.draw_colored_polygon(PackedVector2Array([Vector2(d.position.x, FLOOR_Y), Vector2(d.end.x, FLOOR_Y), Vector2(d.end.x + 30, 180), Vector2(d.position.x - 30, 180)]), c1)
	var c2 := col
	c2.a = 0.12 + 0.08 * p
	w.draw_rect(d.grow(9), c2)
	w.draw_rect(d.grow(4), c2)


func draw_top() -> void:
	var h: Node2D = main.top_ui
	Art.box(h, _gear_rect(), Art.DARK, Art.TEAL if _gear_rect().has_point(hmouse()) else Art.PARCH)
	Art.gear(h, _gear_rect().get_center(), Art.PARCH)
	if room == "pledge" and act() == 1 and not has_moved:
		PxFont.draw(h, Vector2(9, 9), "A/D WALK    E INTERACT    ESC SETTINGS", Art.OUTLINE)
		PxFont.draw(h, Vector2(8, 8), "A/D WALK    E INTERACT    ESC SETTINGS", Art.PARCH)
	if _tt_visible():
		Art.tooltip(h, tt_rect(), tt_state != "home")
	if flash_t > 0.0:
		var fw := PxFont.width(flash, 2) + 16
		Art.box(h, Rect2(320 - fw / 2.0, 120, fw, 26), Art.DARK, Art.RED, 2)
		PxFont.draw_centered(h, 320, 126, flash, Art.RED, 2)
	if pad_open:
		_draw_pad(h)


func _draw_pad(h: Node2D) -> void:
	Art.window(h, PAD_WIN, "KEYPAD")
	var disp := Rect2(PAD_WIN.position.x + 10, PAD_WIN.position.y + 16, 120, 24)
	Art.box(h, disp, Art.TEAL_DARK, Art.OUTLINE, 2)
	var shown := "ERR" if pad_err > 0.0 else pad_code + ("_" if int(t * 3.0) % 2 == 0 else "")
	PxFont.draw_centered(h, disp.get_center().x, disp.position.y + 5, shown, Art.RED if pad_err > 0.0 else Art.TEAL, 2)
	var m := hmouse()
	for i in PAD_KEYS.size():
		Art.button(h, _pad_btn(i), PAD_KEYS[i], _pad_btn(i).has_point(m))
