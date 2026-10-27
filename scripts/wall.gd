extends Screen
## The ending, from inside the wall. The other you presses START and the Narrator
## welcomes them like a stranger. You can only type the message you were sent.
## Then the truth, and a note for the next loop.
## Phases: watch -> type -> reveal -> note -> done

const EXIT_LINE := "Is someone there? Please... don't listen to him."
const REVEAL := ["YOU WERE NEVER SAVING SOMEONE ELSE.", "", "THE ONE TRAPPED INSIDE", "WAS ALWAYS YOU."]
const VIEW := Rect2(70, 14, 180, 100)

var phase := "watch"
var typed := 0
var phase_t := 0.0
var hover_note := -1


func set_phase(p: String) -> void:
	phase = p
	phase_t = 0.0


func type_key() -> void:
	if phase != "type":
		return
	typed = mini(typed + 2, EXIT_LINE.length())
	SoundManager.play_typewriter()
	if typed >= EXIT_LINE.length():
		set_phase("reveal")
		Sfx.play("braam", -2.0)
		main.shake = 0.8


func update(delta: float) -> void:
	phase_t += delta
	if phase == "reveal" and phase_t > 6.5:
		set_phase("note")
		Sfx.play("chime", -6.0)
	hover_note = -1
	if phase == "note":
		for i in 3:
			if _note_rect(i).has_point(hmouse()):
				hover_note = i


func handle_input(event: InputEvent) -> void:
	if phase == "type":
		if (event is InputEventKey and event.pressed and not event.echo) or clicked(event):
			type_key()
	elif phase == "note" and clicked(event) and hover_note >= 0:
		GameState.loop_note = hover_note
		set_phase("done")
		SoundManager.play_pop()
		main.on_event("note_left")


func _note_rect(i: int) -> Rect2:
	return Rect2(125 + i * 140, 170, 110, 90)


func draw_world() -> void:
	var w := world
	Art.bricks(w, Rect2(0, 0, 320, 180), 21, Art.BRICK_COOL)
	w.draw_rect(Rect2(0, 0, 320, 180), Color(0.02, 0.05, 0.06, 0.55))
	# the game, seen from the other side of the glass
	var p := 0.5 + 0.5 * sin(t * 2.0)
	for i in 3:
		w.draw_rect(VIEW.grow(10 - i * 3), Color(0.25, 0.85, 0.76, 0.05 + 0.03 * p))
	w.draw_rect(VIEW.grow(3), Art.OUTLINE)
	Art.bricks(w, Rect2(VIEW.position, Vector2(VIEW.size.x, 72)), 3, Art.BRICK, 10.0, 5.0)
	w.draw_rect(Rect2(VIEW.position.x, VIEW.position.y + 72, VIEW.size.x, 28), Art.FLOOR)
	w.draw_rect(Rect2(VIEW.position.x + 84, VIEW.position.y + 8, 14, 30), Color("#2a3a6a"))
	for i in 3:
		Art.symbol(w, ["sun", "moon", "star"][i], Vector2(VIEW.position.x + 91, VIEW.position.y + 14 + i * 9), Art.GOLD)
	w.draw_rect(Rect2(VIEW.position.x + 130, VIEW.position.y + 12, 30, 12), Color("#120404"))
	PxFont.draw_centered(w, VIEW.position.x + 145, VIEW.position.y + 15, "08:12", Color("#ff3b2e"))
	var walk := minf(t * 14.0, 70.0)
	Art.hero(w, Vector2(roundf(VIEW.position.x + 8 + walk), VIEW.position.y + 56), int(t * 8.0) % 2 if walk < 70.0 else 0, false)
	for y in range(int(VIEW.position.y), int(VIEW.end.y), 2):
		w.draw_rect(Rect2(VIEW.position.x, y, VIEW.size.x, 1), Color(0, 0, 0, 0.22))
	w.draw_rect(VIEW, Color(0.25, 0.85, 0.76, 0.06))
	# you, on this side of the glass
	if phase != "watch":
		Art.hero(w, Vector2(152, 122), 0, false, Art.GHOST_PAL)


func draw_hud() -> void:
	var h := hud
	PxFont.draw_centered(h, 320, 238, "08:12  -  THE OTHER YOU JUST PRESSED START.", Art.PARCH)
	if phase == "type" or phase == "reveal":
		var r := Rect2(150, 252, 340, 60)
		Art.box(h, r, Art.TEAL_DARK, Art.TEAL, 2)
		h.draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, 11), Color("#123234"))
		PxFont.draw(h, r.position + Vector2(8, 4), "SYSTEM_MSG  (YOU)", Art.TEAL)
		PxFont.draw_block(h, r.position + Vector2(9, 19), PxFont.wrap(EXIT_LINE.substr(0, typed), 322), Art.TEAL, 1, 11)
	if phase == "type" and int(t * 2.5) % 2 == 0:
		var hint := "PRESS ANY KEY TO TYPE." if typed == 0 else "KEEP TYPING. YOU CAN'T CHANGE A WORD."
		PxFont.draw_centered(h, 320, 324, hint, Art.MAGENTA)
	if phase == "reveal":
		h.draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, minf(phase_t * 0.8, 0.94)))
		for i in REVEAL.size():
			var appear := 0.8 + i * 1.1
			if phase_t < appear or REVEAL[i] == "":
				continue
			var col := Art.CREAM if i == 0 else Art.TEAL
			var s := 2 if i == 0 else 3
			var jx := roundf(randf_range(-1, 1)) if phase_t - appear < 0.3 else 0.0
			PxFont.draw_centered(h, 320 + jx, 110 + i * 34, REVEAL[i], col, s)
	if phase == "note" or phase == "done":
		h.draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.9))
		PxFont.draw_centered(h, 320, 84, "LEAVE YOURSELF A NOTE.", Art.CREAM, 2)
		PxFont.draw_centered(h, 320, 110, "IT WILL BE ON THE WALL WHEN YOU START AGAIN.", Color("#8a8070"))
		for i in 3:
			var r := _note_rect(i)
			var lift := -4.0 if hover_note == i else 0.0
			var ang: float = [-0.05, 0.03, -0.02][i]
			Art.sticky(h, r.get_center() + Vector2(0, lift), r.size, ang, GameState.NOTES[i], Art.NOTE, Art.INK, 2)
			if hover_note == i:
				Art.frame(h, r.grow(6), Art.TEAL, 2)
