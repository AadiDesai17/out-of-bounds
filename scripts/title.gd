extends Screen
## Title screen: the cozy desk, the glowing CRT, and a menu whose QUIT button runs away.

const MENU := ["START GAME", "SETTINGS", "CREDITS", "QUIT"]
const QUIT_SPOTS := [Vector2(-96, 0), Vector2(92, -4), Vector2(-88, -38), Vector2(0, 2)]
const LOGO := Rect2(95, 8, 110, 70)

var hover := -1
var quit_off := Vector2.ZERO
var dodges := 0
var logo_shake := 0.0
var logo_pokes := 0
## The last shot: the door icon flickers like a spinning top that may or may not fall.
var final_flicker := false


func _btn(i: int) -> Rect2:
	var r := Rect2(110, 91 + i * 13, 80, 11)
	if i == 3:
		r.position += quit_off
	return r


func update(delta: float) -> void:
	logo_shake = maxf(logo_shake - delta * 2.5, 0.0)
	var m := wmouse()
	var h := -1
	for i in MENU.size():
		if _btn(i).has_point(m):
			h = i
	if h != hover and h >= 0:
		SoundManager.play_typewriter()
	hover = h
	if can_play() and dodges < QUIT_SPOTS.size() and _btn(3).grow(3).has_point(m):
		quit_off = QUIT_SPOTS[dodges]
		dodges += 1
		SoundManager.play_boing()
		if dodges == QUIT_SPOTS.size():
			main.talk([["N", "Fine. The quit button stays. Not that you'd ever want to leave."]])


func handle_input(event: InputEvent) -> void:
	if not clicked(event):
		return
	if hover < 0 and LOGO.has_point(wmouse()):
		_poke_logo()
		return
	match hover:
		0:
			SoundManager.play_click()
			main.start_game()
		1:
			main.open_settings()
		2:
			SoundManager.play_click()
			main.talk([
				["N", "Credits. Written, directed and narrated by me. The Narrator."],
				["N", "Also some programmers. They are not important."],
			])
		3:
			get_tree().quit()


func _poke_logo() -> void:
	logo_shake = 1.0
	SoundManager.play_boing()
	var pokes := [
		[["N", "Please don't touch the logo. It's load-bearing."]],
		[["N", "I said don't. That logo cost us the entire art budget."]],
		[["N", "Fine. Rattle it. See if I care. I care."]],
	]
	if logo_pokes < pokes.size():
		main.talk(pokes[logo_pokes])
	logo_pokes += 1


func draw_world() -> void:
	var w := world
	Art.bricks(w, Rect2(0, 0, 320, 142), 7)
	for i in 5:
		w.draw_circle(Vector2(298, 28), 170.0 - i * 32.0, Color(1, 0.7, 0.35, 0.05))
	_wall_stuff(w)
	_desk(w)
	_crt(w)
	_logo(w)
	for i in MENU.size():
		var hot := hover == i or (hover < 0 and i == 0)
		Art.button(w, _btn(i), MENU[i], hot)
		if hot:
			var r := _btn(i)
			w.draw_rect(Rect2(r.position.x + 4, r.position.y + 3, 1, 5), Art.TEAL_DARK)
			w.draw_rect(Rect2(r.position.x + 5, r.position.y + 4, 1, 3), Art.TEAL_DARK)
			w.draw_rect(Rect2(r.position.x + 6, r.position.y + 5, 1, 1), Art.TEAL_DARK)


func _logo(w: Node2D) -> void:
	var o := Vector2(randf_range(-2, 2), randf_range(-1, 1)).round() * logo_shake * 2.0
	if main.glitch > 0.3:
		o.x += randf_range(-4, 4)
	var pulse := 0.5 + 0.5 * sin(t * 2.4)
	if final_flicker:
		pulse = 1.0 if randf() < 0.5 else 0.0
	PxFont.draw_outlined(w, Vector2(125, 12) + o, "OUT", Art.CREAM, Art.OUTLINE, 3)
	# glowing door icon beside "OUT"
	var d := Rect2(182, 11, 14, 22).grow(0)
	d.position += o
	w.draw_rect(d.grow(5), Color(0.25, 0.85, 0.76, 0.12 + 0.16 * pulse))
	w.draw_rect(d.grow(2), Art.OUTLINE)
	w.draw_rect(d, Art.TEAL)
	w.draw_rect(d.grow(-2), Art.TEAL_DARK)
	w.draw_rect(d.grow(-2), Color(0.25, 0.85, 0.76, 0.2 + 0.35 * pulse))
	w.draw_rect(Rect2(d.end.x - 5, d.position.y + 11, 2, 2), Art.TEAL)
	for i in 9:
		var ox := roundf(sin(t * 3.0 + i * 2.0) * 2.0)
		w.draw_rect(Rect2(d.end.x + 4 + i * 3 + ox, d.position.y + (i * 7) % 20, 2 + i % 2, 2), Art.TEAL if i % 3 != 0 else Color("#1d2a2a"))
	PxFont.draw_outlined(w, Vector2(139, 37) + o, "OF", Art.CREAM, Art.OUTLINE, 2)
	PxFont.draw_outlined(w, Vector2(98, 55) + o, "BOUNDS", Art.CREAM, Art.OUTLINE, 3)
	PxFont.draw_centered(w, 151, 81, "A GAME YOU SHOULDN'T BREAK... BUT WILL.", Art.OUTLINE)
	PxFont.draw_centered(w, 150, 80, "A GAME YOU SHOULDN'T BREAK... BUT WILL.", Art.PARCH)


func _wall_stuff(w: Node2D) -> void:
	Art.sticky(w, Vector2(35, 35), Vector2(54, 50), -0.06, ["GOOD", "GAMES", "BETTER", "ESCAPES."])
	# framed landscape
	w.draw_rect(Rect2(36, 94, 44, 30), Color("#3a2416"))
	w.draw_rect(Rect2(38, 96, 40, 26), Color("#7ab8d8"))
	for i in 10:
		w.draw_rect(Rect2(46 + i, 112 - i, maxf(20 - 2 * i, 1), 1), Color("#4a6a8a"))
	w.draw_rect(Rect2(38, 112, 40, 10), Color("#4f7a4a"))
	w.draw_rect(Rect2(62, 99, 8, 2), Color.WHITE)
	w.draw_rect(Rect2(52, 108, 2, 4), Art.RED)
	# poster, or the profile note once the loop has started
	if GameState.loop_count > 0:
		w.draw_rect(Rect2(224, 10, 54, 50), Color("#3a2416"))
		w.draw_rect(Rect2(226, 12, 50, 46), Color("#0a1a1c"))
		PxFont.draw(w, Vector2(229, 20), "PROFILE:", Art.TEAL)
		PxFont.draw(w, Vector2(229, 32), "?????", Art.TEAL)
		PxFont.draw(w, Vector2(229, 44), "LOOP %02d" % GameState.loop_count, Art.MAGENTA)
	else:
		w.draw_rect(Rect2(224, 10, 54, 50), Color("#3a2416"))
		w.draw_rect(Rect2(226, 12, 50, 46), Color("#1c1410"))
		for i in 4:
			PxFont.draw_centered(w, 251, 16 + i * 10, ["SOME", "WORLDS", "AREN'T", "REAL."][i], Art.PARCH)
	# desk lamp
	for i in 14:
		w.draw_rect(Rect2(318 - i * 2, i, 3, 3), Color("#2a2a30"))
	w.draw_rect(Rect2(290, 14, 22, 6), Color("#2a2a30"))
	w.draw_rect(Rect2(285, 20, 32, 6), Color("#2a2a30"))
	w.draw_rect(Rect2(293, 26, 16, 3), Color("#ffe9a8"))
	Art.sticky(w, Vector2(302, 50), Vector2(32, 30), 0.12, ["JUST", "A", "GAME."])
	if GameState.loop_note >= 0:
		Art.sticky(w, Vector2(58, 114), Vector2(60, 40), 0.07, GameState.NOTES[GameState.loop_note])
	# plant
	w.draw_rect(Rect2(6, 123, 24, 4), Color("#a65a32"))
	w.draw_rect(Rect2(8, 127, 20, 15), Color("#8a4a2a"))
	var sway := sin(t * 1.4) * 0.15
	var leaves := [[-1.0, -1.0, 10], [1.0, -1.0, 11], [0.0, -1.0, 13], [-1.0, -0.5, 9], [1.0, -0.45, 10]]
	for leaf in leaves:
		for i in int(leaf[2]):
			var col := Color("#2e6a2e") if i % 2 else Color("#4a9a42")
			w.draw_rect(Rect2(roundf(16 + (leaf[0] + sway) * i * 1.4), roundf(122 + leaf[1] * i * 2.3), 4, 3), col)


func _desk(w: Node2D) -> void:
	w.draw_rect(Rect2(0, 142, 320, 18), Color("#7a4a2a"))
	w.draw_rect(Rect2(0, 142, 320, 1), Color("#8f5a32"))
	w.draw_rect(Rect2(0, 149, 320, 1), Color("#6a3e22"))
	w.draw_rect(Rect2(0, 155, 320, 1), Color("#6a3e22"))
	w.draw_rect(Rect2(0, 160, 320, 20), Color("#4a2a16"))
	w.draw_rect(Rect2(0, 160, 320, 1), Color("#8a5a34"))
	for g in [[20, 168, 60], [120, 172, 80], [230, 167, 70]]:
		w.draw_rect(Rect2(g[0], g[1], g[2], 1), Color("#3a2010"))
	# gamepad
	w.draw_rect(Rect2(118, 148, 28, 8), Color("#3a3a44"))
	w.draw_rect(Rect2(116, 150, 4, 8), Color("#3a3a44"))
	w.draw_rect(Rect2(144, 150, 4, 8), Color("#3a3a44"))
	w.draw_rect(Rect2(121, 151, 5, 1), Color("#1a1a20"))
	w.draw_rect(Rect2(123, 149, 1, 5), Color("#1a1a20"))
	w.draw_rect(Rect2(138, 150, 2, 2), Art.RED)
	w.draw_rect(Rect2(141, 152, 2, 2), Art.TEAL)
	# mug with steam
	w.draw_rect(Rect2(174, 133, 12, 14), Art.PARCH)
	w.draw_rect(Rect2(186, 136, 3, 2), Art.PARCH)
	w.draw_rect(Rect2(188, 136, 2, 7), Art.PARCH)
	w.draw_rect(Rect2(186, 141, 3, 2), Art.PARCH)
	w.draw_rect(Rect2(177, 137, 1, 1), Art.INK)
	w.draw_rect(Rect2(182, 137, 1, 1), Art.INK)
	w.draw_rect(Rect2(177, 140, 6, 1), Art.INK)
	for i in 3:
		var p := fmod(t * 22.0 + i * 6.0, 16.0)
		w.draw_rect(Rect2(178 + i * 3 + roundf(sin(t * 3.0 + i) * 1.5), 129 - p, 1, 2), Color(0.95, 0.9, 0.82, 0.5 - p / 34.0))
	# keyboard
	w.draw_rect(Rect2(200, 147, 90, 10), Color("#cbbf9e"))
	w.draw_rect(Rect2(200, 155, 90, 2), Color("#a89c7c"))
	for x in range(203, 286, 4):
		w.draw_rect(Rect2(x, 149, 3, 2), Color("#8f8468"))
		w.draw_rect(Rect2(x + 1, 152, 3, 2), Color("#8f8468"))


func _crt(w: Node2D) -> void:
	var pulse := 0.5 + 0.5 * sin(t * 2.4)
	if final_flicker:
		pulse = 1.0 if randf() < 0.5 else 0.0
	w.draw_rect(Rect2(214, 92, 78, 48), Color("#cbbf9e"))
	w.draw_rect(Rect2(214, 92, 78, 2), Color("#e0d6b8"))
	w.draw_rect(Rect2(288, 94, 4, 46), Color("#a89c7c"))
	w.draw_rect(Rect2(214, 137, 78, 3), Color("#a89c7c"))
	w.draw_rect(Rect2(240, 140, 24, 3), Color("#a89c7c"))
	w.draw_rect(Rect2(220, 97, 64, 38), Color("#8f8468"))
	w.draw_rect(Rect2(222, 99, 60, 34), Color("#06181a"))
	w.draw_rect(Rect2(238, 101, 28, 30), Color(0.25, 0.85, 0.76, 0.08 + 0.12 * pulse))
	w.draw_rect(Rect2(245, 104, 14, 25), Art.TEAL)
	w.draw_rect(Rect2(247, 106, 10, 23), Color("#06181a"))
	w.draw_rect(Rect2(247, 106, 10, 23), Color(0.25, 0.85, 0.76, 0.2 + 0.4 * pulse))
	for i in 6:
		w.draw_rect(Rect2(262 + fmod(t * 16.0 + i * 9.0, 18.0), 106 + i * 4, 2, 1), Art.TEAL if i % 2 else Art.MAGENTA)
	for y in range(99, 133, 2):
		w.draw_rect(Rect2(222, y, 60, 1), Color(0, 0, 0, 0.25))
	w.draw_rect(Rect2(280, 135, 2, 1), Color("#4adf6a"))
