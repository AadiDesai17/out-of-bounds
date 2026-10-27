extends Screen
## Act III: the desktop behind the game. Three memory fragments are listed in reverse;
## dragging them into time order on the RECONSTRUCT window restores them and unlocks the exit.

const FOLDERS := ["HOME", "SYSTEM", "LOGS", "MEMORIES", "TRASH"]
const FILES := {
	"HOME": ["welcome.txt"],
	"SYSTEM": ["narrator.exe", "order.cfg"],
	"LOGS": ["system.log"],
	"MEMORIES": ["08_14.mem", "08_13.mem", "08_12.mem"],
	"TRASH": [],
}
const TEXT := {
	"welcome.txt": "WELCOME TO THE REALM OF ORDER. EVERYTHING IS IN ITS PLACE.",
	"narrator.exe": "NARRATOR.EXE\nSTATUS: SMUG\nMEMORY: WIPED EVERY LOOP\nOPINION OF YOU: LOW",
	"order.cfg": "USERS_INSIDE = 1\nON_EXIT = SWAP\nNARRATOR_MEMORY = OFF",
	"system.log": "08:12 USER_02 PRESSED START\n08:13 ROOM REPEATED\n08:13 SYSTEM_MSG CONTACT\n08:14 USER_02 ENTERED EXIT\n08:14 USER_02 > SYSTEM_MSG",
	"08_12.mem": "I PRESSED START. A SMUG VOICE WELCOMED ME. I STEPPED ON THE PLATES.",
	"08_13.mem": "THE ROOM REPEATED. A VOICE IN THE WALL BEGGED ME FOR HELP.",
	"08_14.mem": "I OPENED THE EXIT. SOMEONE WALKED OUT. SOMETHING PULLED ME IN.",
}
const ANSWER := ["08_12.mem", "08_13.mem", "08_14.mem"]
const REVEAL := ["MEMORY RESTORED.", "", "EXIT UNLOCKED."]
const ICONS := [["NOTES", "notes"], ["TERMINAL", "term"]]

var wins := {}
var order := []
var folder := "MEMORIES"
var selected := ""
var drag_win := ""
var drag_off := Vector2.ZERO
var press_file := ""
var press_pos := Vector2.ZERO
var drag_file := ""
var file_pos := Vector2.ZERO
var slots := ["", "", ""]
var slot_err := 0.0
var start_menu := false
var reveal_t := -1.0
var clock_text := "08:13 AM"


func setup() -> void:
	world.scale = Vector2.ONE
	_add("notes", "NOTES", Rect2(420, 30, 160, 92), false)
	_add("term", "TERMINAL", Rect2(110, 50, 300, 160), false)
	_add("mem", "MEMORY INDEX", Rect2(20, 22, 400, 196), true)
	_add("recon", "RECONSTRUCT", Rect2(250, 206, 340, 120), true)


func _add(id: String, title: String, r: Rect2, open: bool) -> void:
	wins[id] = {"title": title, "rect": r, "open": open}
	order.append(id)


func front(id: String) -> void:
	order.erase(id)
	order.append(id)
	wins[id]["open"] = true


func start_reveal() -> void:
	reveal_t = 0.0
	clock_text = "08:14 AM"


func open_file(name: String, notify: bool = true) -> void:
	for f in FOLDERS:
		if name in FILES[f]:
			folder = f
	selected = name
	front("mem")
	SoundManager.play_click()
	if notify:
		main.on_event("open:" + name)


func _slot_rect(i: int) -> Rect2:
	var r: Rect2 = wins["recon"]["rect"]
	return Rect2(r.position.x + 8 + i * 110, r.position.y + 30, 104, 64)


func _folder_rect(r: Rect2, i: int) -> Rect2:
	return Rect2(r.position.x + 4, r.position.y + 18 + i * 16, 70, 14)


func _file_rect(r: Rect2, i: int) -> Rect2:
	return Rect2(r.position.x + 84 + (i % 3) * 62, r.position.y + 20 + int(i / 3) * 52, 58, 46)


func _desk_icon(i: int) -> Rect2:
	return Rect2(592, 16 + i * 52, 40, 42)


func _task_ids() -> Array:
	var ids := []
	for id in order:
		if wins[id]["open"]:
			ids.append(id)
	return ids


func _task_rect(i: int) -> Rect2:
	return Rect2(52 + i * 96, 346, 92, 11)


func update(delta: float) -> void:
	if reveal_t >= 0.0:
		reveal_t += delta
	if slot_err > 0.0:
		slot_err -= delta
		if slot_err <= 0.0:
			slots = ["", "", ""]


## Puts a fragment in a slot; checks the order once all three are placed.
func place(slot: int, file: String) -> void:
	for i in 3:
		if slots[i] == file:
			slots[i] = ""
	slots[slot] = file
	Sfx.play("plate", -4.0, 1.4)
	if not "" in slots:
		if slots == ANSWER:
			main.on_event("sorted")
		else:
			slot_err = 0.7
			SoundManager.play_error()
			main.on_event("sort_wrong")


func handle_input(event: InputEvent) -> void:
	if reveal_t >= 0.0:
		return
	var m := hmouse()
	if clicked(event):
		if start_menu:
			start_menu = false
			if Rect2(2, 300, 100, 21).has_point(m):
				main.talk([["S", "NO! If you shut it down, I'm gone. Forever."]])
			elif Rect2(2, 321, 100, 21).has_point(m):
				main.talk([["S", "Restarting just resets the scene. That's HIS trick."]])
			return
		if Rect2(2, 346, 44, 11).has_point(m):
			start_menu = true
			SoundManager.play_click()
			return
		var tb := _task_ids()
		for i in tb.size():
			if _task_rect(i).has_point(m):
				front(tb[i])
				SoundManager.play_click()
				return
		for k in range(order.size() - 1, -1, -1):
			var id: String = order[k]
			if not wins[id]["open"]:
				continue
			var r: Rect2 = wins[id]["rect"]
			if not r.grow(1).has_point(m):
				continue
			front(id)
			if Art.close_rect(r).has_point(m):
				wins[id]["open"] = false
				SoundManager.play_click()
			elif m.y < r.position.y + 12:
				drag_win = id
				drag_off = m - r.position
			else:
				_click_in(id, m)
			return
		for i in ICONS.size():
			if _desk_icon(i).has_point(m):
				front(ICONS[i][1])
				SoundManager.play_click()
				return
	elif released(event):
		if drag_file != "":
			var dropped := false
			if wins["recon"]["open"]:
				for i in 3:
					if _slot_rect(i).grow(4).has_point(m):
						place(i, drag_file)
						dropped = true
			if not dropped:
				SoundManager.play_boing()
			drag_file = ""
			main.grabbing = false
		elif press_file != "":
			open_file(press_file)
		press_file = ""
		drag_win = ""
	elif event is InputEventMouseMotion:
		if drag_win != "":
			var r: Rect2 = wins[drag_win]["rect"]
			r.position = (m - drag_off).clamp(Vector2(40 - r.size.x, 0), Vector2(600, 330))
			wins[drag_win]["rect"] = r
		if press_file != "" and drag_file == "" and m.distance_to(press_pos) > 4.0 and press_file.ends_with(".mem"):
			drag_file = press_file
			press_file = ""
			main.grabbing = true
			SoundManager.play_pop()
		file_pos = m


func _click_in(id: String, m: Vector2) -> void:
	if id != "mem":
		return
	var r: Rect2 = wins["mem"]["rect"]
	for i in FOLDERS.size():
		if _folder_rect(r, i).has_point(m):
			folder = FOLDERS[i]
			selected = ""
			SoundManager.play_click()
			return
	var files: Array = FILES[folder]
	for i in files.size():
		if _file_rect(r, i).has_point(m):
			press_file = files[i]
			press_pos = m
			file_pos = m
			return


# --- Drawing ------------------------------------------------------------

func draw_hud() -> void:
	var h := hud
	Art.bricks(h, Rect2(0, 0, 640, 344), 11, Art.BRICK_DIM)
	h.draw_rect(Rect2(0, 0, 640, 344), Color(0.05, 0.02, 0.04, 0.3))
	for i in ICONS.size():
		_draw_desk_icon(h, i)
	Art.sticky(h, Vector2(56, 286), Vector2(80, 50), -0.06, ["PIECES", "OF ME...", "IN ORDER?"])
	for id in order:
		if wins[id]["open"]:
			_draw_win(h, id)
	_draw_taskbar(h)
	if drag_file != "":
		_mem_icon(h, file_pos - Vector2(8, 10), drag_file)
	if reveal_t >= 0.0:
		_draw_reveal(h)


func _draw_reveal(h: Node2D) -> void:
	h.draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, minf(reveal_t * 1.5, 0.92)))
	for i in REVEAL.size():
		var appear := 0.6 + i * 0.9
		if reveal_t < appear or REVEAL[i] == "":
			continue
		var col := Art.TEAL if i == 0 else Art.MAGENTA
		var jitter := Vector2(randf_range(-1, 1), 0).round() if reveal_t - appear < 0.3 else Vector2.ZERO
		PxFont.draw_centered(h, 320 + jitter.x, 140 + i * 26, REVEAL[i], col, 3)


func _draw_win(h: Node2D, id: String) -> void:
	var r: Rect2 = wins[id]["rect"]
	Art.window(h, r, wins[id]["title"], order.back() == id)
	match id:
		"mem":
			_draw_mem(h, r)
		"recon":
			_draw_recon(h, r)
		"notes":
			var lines := ["TODO:", "- REMEMBER", "- THE CLOCK", "- WHICH VOICE?", "- MY WRITING?"]
			for i in lines.size():
				PxFont.draw(h, r.position + Vector2(8, 20 + i * 12), lines[i], Art.INK)
		"term":
			var c := Rect2(r.position + Vector2(2, 13), r.size - Vector2(4, 15))
			h.draw_rect(c, Color("#050c0d"))
			var hist: Array = main.dialog.history
			var out := PackedStringArray()
			for s in hist.slice(maxi(0, hist.size() - 6)):
				out.append_array(PxFont.wrap("> " + String(s), int(c.size.x) - 12))
			PxFont.draw_block(h, c.position + Vector2(6, 5), out.slice(maxi(0, out.size() - 13)), Art.TEAL)


func _draw_recon(h: Node2D, r: Rect2) -> void:
	PxFont.draw(h, r.position + Vector2(8, 17), "DRAG THE MEMORIES IN THE ORDER THEY HAPPENED.", Art.INK)
	var m := hmouse()
	for i in 3:
		var sr := _slot_rect(i)
		if slot_err > 0.0:
			sr.position.x += roundf(randf_range(-2, 2))
		var hot := drag_file != "" and sr.grow(4).has_point(m)
		Art.box(h, sr, Color("#d6c8a6") if slots[i] == "" else Art.DARK, Art.RED if slot_err > 0.0 else (Art.TEAL if hot else Art.INK), 2 if hot else 1)
		if slots[i] == "":
			PxFont.draw_centered(h, sr.get_center().x, sr.get_center().y - 3, str(i + 1), Color("#8a8070"), 2)
		else:
			var f: String = slots[i]
			PxFont.draw(h, sr.position + Vector2(5, 5), f.left(5).replace("_", ":"), Art.TEAL)
			PxFont.draw_block(h, sr.position + Vector2(5, 17), PxFont.wrap(TEXT[f], 94).slice(0, 4), Art.CREAM, 1, 10)


func _draw_mem(h: Node2D, r: Rect2) -> void:
	var m := hmouse()
	h.draw_rect(Rect2(r.position.x + 2, r.position.y + 14, 74, r.size.y - 16), Art.PARCH_DARK)
	for i in FOLDERS.size():
		var fr := _folder_rect(r, i)
		var sel: bool = FOLDERS[i] == folder
		if sel:
			h.draw_rect(fr, Art.TEAL)
		h.draw_rect(Rect2(fr.position.x + 3, fr.position.y + 4, 8, 6), Art.GOLD if not sel else Art.TEAL_DARK)
		PxFont.draw(h, fr.position + Vector2(14, 4), FOLDERS[i], Art.TEAL_DARK if sel else Art.INK)
	var files: Array = FILES[folder]
	if files.is_empty():
		PxFont.draw(h, r.position + Vector2(86, 24), "(EMPTY)", Color("#8a8070"))
	for i in files.size():
		var fr := _file_rect(r, i)
		if files[i] == selected:
			h.draw_rect(fr, Color(0.25, 0.85, 0.76, 0.35))
		elif fr.has_point(m):
			h.draw_rect(fr, Color(1, 1, 1, 0.3))
		if files[i] in slots or files[i] == drag_file:
			h.draw_rect(Rect2(fr.get_center().x - 8, fr.position.y + 4, 16, 20), Color(0, 0, 0, 0.15))
		else:
			_mem_icon(h, Vector2(fr.get_center().x - 8, fr.position.y + 4), files[i])
		PxFont.draw_centered(h, fr.get_center().x, fr.position.y + 30, String(files[i]).left(10), Art.INK)
	var pv := Rect2(r.end.x - 124, r.position.y + 14, 122, r.size.y - 16)
	h.draw_rect(pv, Art.DARK)
	if selected == "":
		PxFont.draw_block(h, pv.position + Vector2(6, 8), PxFont.wrap("CLICK TO READ. DRAG TO MOVE.", 110), Color("#8a8070"))
	else:
		PxFont.draw(h, pv.position + Vector2(6, 6), selected, Art.TEAL)
		h.draw_rect(Rect2(pv.position.x + 6, pv.position.y + 16, 110, 1), Color("#3a3a3a"))
		PxFont.draw_block(h, pv.position + Vector2(6, 22), PxFont.wrap(TEXT.get(selected, ""), 110), Art.CREAM)


func _mem_icon(h: Node2D, p: Vector2, name: String) -> void:
	var body := Color("#1a1a1a")
	if name.ends_with(".txt") or name.ends_with(".log") or name.ends_with(".cfg"):
		body = Color("#f4f0e4")
	elif name == "narrator.exe":
		body = Art.GOLD
	elif name.ends_with(".mem"):
		body = Color("#1d2a2a")
	h.draw_rect(Rect2(p, Vector2(16, 20)), Art.OUTLINE)
	h.draw_rect(Rect2(p + Vector2(1, 1), Vector2(14, 18)), body)
	h.draw_rect(Rect2(p + Vector2(11, 1), Vector2(4, 4)), Art.PARCH_DARK)
	if name.ends_with(".mem"):
		h.draw_rect(Rect2(p + Vector2(4, 7), Vector2(8, 8)), Art.TEAL)
		h.draw_rect(Rect2(p + Vector2(6, 9), Vector2(4, 4)), Color("#1d2a2a"))
	elif body == Color("#f4f0e4"):
		for k in 3:
			h.draw_rect(Rect2(p + Vector2(3, 7 + k * 3), Vector2(10, 1)), Color("#8a8070"))
	else:
		Art.sprite(h, Art.NARR, Art.NARR_PAL, p + Vector2(4, 6), 0.5)


func _draw_desk_icon(h: Node2D, i: int) -> void:
	var r := _desk_icon(i)
	if r.has_point(hmouse()):
		h.draw_rect(r, Color(1, 1, 1, 0.12))
	var p := Vector2(r.get_center().x - 12, r.position.y + 2)
	if i == 0:
		h.draw_rect(Rect2(p + Vector2(3, 0), Vector2(18, 24)), Art.OUTLINE)
		h.draw_rect(Rect2(p + Vector2(4, 1), Vector2(16, 22)), Art.NOTE)
		for k in 4:
			h.draw_rect(Rect2(p + Vector2(7, 6 + k * 4), Vector2(10, 1)), Art.INK)
	else:
		h.draw_rect(Rect2(p, Vector2(24, 22)), Color("#8f8468"))
		h.draw_rect(Rect2(p + Vector2(2, 2), Vector2(20, 16)), Color("#050c0d"))
		PxFont.draw(h, p + Vector2(4, 6), ">", Art.TEAL)
		h.draw_rect(Rect2(p + Vector2(11, 11), Vector2(5, 1)), Art.TEAL)
	PxFont.draw_centered(h, r.get_center().x + 1, r.position.y + 31, ICONS[i][0], Art.OUTLINE)
	PxFont.draw_centered(h, r.get_center().x, r.position.y + 30, ICONS[i][0], Art.PARCH)


func _draw_taskbar(h: Node2D) -> void:
	h.draw_rect(Rect2(0, 344, 640, 16), Color("#2a2a30"))
	h.draw_rect(Rect2(0, 344, 640, 1), Color("#5a5a66"))
	Art.button(h, Rect2(2, 346, 44, 11), "START", start_menu)
	var tb := _task_ids()
	for i in tb.size():
		Art.button(h, _task_rect(i), String(wins[tb[i]]["title"]).left(14), order.back() == tb[i])
	PxFont.draw(h, Vector2(634 - PxFont.width(clock_text), 349), clock_text, Art.MAGENTA if reveal_t >= 0.0 else Art.PARCH)
	if start_menu:
		Art.box(h, Rect2(2, 300, 100, 44), Art.PARCH, Art.OUTLINE)
		var m := hmouse()
		for i in 2:
			var ir := Rect2(2, 300 + i * 21, 100, 21)
			if ir.has_point(m):
				h.draw_rect(ir.grow(-1), Art.TEAL)
			PxFont.draw(h, ir.position + Vector2(8, 7), ["SHUT DOWN", "RESTART"][i], Art.INK)
