extends Node
## Owns the screens and overlays, routes input, and runs the story.
##
## Story: three acts named after a magic trick.
##   I.   THE PLEDGE   - an ordinary game, an ordinary puzzle. No glitches.
##   II.  THE TURN     - the room repeats, a voice in the wall, inverted time.
##   III. THE PRESTIGE - your own memories, in reverse. Then the swap: the voice
##        in the wall walks out, you take its place, and the loop starts again.

const SCREENS := {
	"title": preload("res://scripts/title.gd"),
	"hall": preload("res://scripts/hall.gd"),
	"desktop": preload("res://scripts/desktop.gd"),
	"wall": preload("res://scripts/wall.gd"),
}

var screen: Node2D
var world_layer := Node2D.new()
var dialog: Node2D
var settings: Node2D
var overlay: Node2D
## Screen-owned drawing above the inverting shader (tooltips, keypad).
var top_ui := Node2D.new()
var fx_mat := ShaderMaterial.new()

var glitch := 0.0
var shake := 0.0
var fade := 0.0
var fade_color := Color.BLACK
var busy := false
var grabbing := false

## 0 title, 1 Pledge, 2 Turn, 3 Prestige, 4 ending
var act := 0
var card_alpha := 0.0
var card_num := ""
var card_title := ""
var card_sub := ""
var tick_every := 0.0
var _tick_acc := 0.0
var _pad_fails := 0
var _pushes := 0
var _door_tries := 0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	add_child(world_layer)

	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 5
	add_child(fx_layer)
	var fx_rect := ColorRect.new()
	fx_rect.size = Vector2(640, 360)
	fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_mat.shader = preload("res://shaders/screen_fx.gdshader")
	fx_rect.material = fx_mat
	fx_layer.add_child(fx_rect)

	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	ui.add_child(top_ui)
	dialog = preload("res://scripts/dialog.gd").new()
	ui.add_child(dialog)
	settings = preload("res://scripts/settings.gd").new()
	ui.add_child(settings)
	settings.closed.connect(_on_settings_closed)

	var top := CanvasLayer.new()
	top.layer = 20
	add_child(top)
	overlay = preload("res://scripts/overlay.gd").new()
	overlay.main = self
	top.add_child(overlay)

	GameState.settings_changed.connect(_apply_settings)
	_apply_settings()
	show_screen("title")
	for arg in OS.get_cmdline_user_args():
		if arg == "--smoke":
			_smoke()
		elif arg.begins_with("--shots="):
			_shots(arg.substr(8))


func _process(delta: float) -> void:
	glitch = move_toward(glitch, 0.0, delta * 1.4)
	shake = move_toward(shake, 0.0, delta * 3.0)
	# From Act II on, the world flickers on its own, a little more each act.
	if act in [2, 3] and not busy and randf() < delta * (0.12 if act == 2 else 0.3):
		glitch = maxf(glitch, 0.18 + 0.12 * (act - 2))
	if GameState.screen_shake and shake > 0.0:
		world_layer.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)).round() * shake * 4.0
	else:
		world_layer.position = Vector2.ZERO
	fx_mat.set_shader_parameter("glitch", glitch)
	fx_mat.set_shader_parameter("time_s", Time.get_ticks_msec() / 1000.0)
	if tick_every > 0.0:
		_tick_acc += delta
		if _tick_acc >= tick_every:
			_tick_acc = 0.0
			if GameState.invert:
				Sfx.play("tock_rev", -12.0)
			else:
				Sfx.play("tick", -16.0 + act * 2.0)


func _apply_settings() -> void:
	fx_mat.set_shader_parameter("invert", 1.0 if GameState.invert else 0.0)
	fx_mat.set_shader_parameter("brightness", GameState.brightness / 80.0)
	fx_mat.set_shader_parameter("contrast", 0.5 + GameState.contrast / 100.0)
	fx_mat.set_shader_parameter("high_contrast", 1.0 if GameState.high_contrast else 0.0)


func show_screen(id: String) -> void:
	if screen:
		world_layer.remove_child(screen)
		screen.queue_free()
	screen = SCREENS[id].new()
	screen.main = self
	world_layer.add_child(screen)
	dialog.idle_narrator = ""
	dialog.hero_portrait = false
	grabbing = false


func can_play() -> bool:
	return not dialog.blocking and not settings.open and not busy and fade < 0.5 and card_alpha < 0.5


func _unhandled_input(event: InputEvent) -> void:
	if settings.open:
		settings.handle_input(event)
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		open_settings()
		return
	if dialog.blocking:
		if _is_advance(event):
			dialog.advance()
		return
	if busy:
		return
	screen.handle_input(event)


func _is_advance(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E]
	return false


func open_settings() -> void:
	SoundManager.play_click()
	settings.show_menu()


func talk(seq: Array) -> void:
	if seq.is_empty():
		return
	dialog.talk(seq)
	await dialog.finished


func burst(amount: float) -> void:
	glitch = maxf(glitch, amount)
	shake = maxf(shake, amount)
	SoundManager.play_glitch()


func fade_to(a: float, dur: float, col: Color = Color.BLACK) -> void:
	fade_color = col
	var tw := create_tween()
	tw.tween_property(self, "fade", a, dur)
	await tw.finished


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


## A Nolan-style title card between acts.
func chapter(num: String, title: String, sub: String) -> void:
	card_num = num
	card_title = title
	card_sub = sub
	Sfx.play("riser", -6.0)
	var tw := create_tween()
	tw.tween_property(self, "card_alpha", 1.0, 1.0)
	await tw.finished
	Sfx.play("braam", -2.0)
	shake = 0.6
	await wait(2.2)


func chapter_out() -> void:
	var tw := create_tween()
	tw.tween_property(self, "card_alpha", 0.0, 0.9)
	await tw.finished


func _in_hall(room: String) -> bool:
	return screen != null and screen.get("room") == room


# --- Act I: The Pledge --------------------------------------------------
# Narrator lines may carry lowercase stage directions ("[sighs]") for the voice actor;
# they are hidden on screen. The Narrator is just the host: smug, controlling, and
# wiped clean every loop. He has no idea who anyone is.

const PUSH_LINES := [
	[["N", "[sharply] Nope. Back you go."]],
	[["N", "[annoyed] What part of off limits was unclear?"]],
	[["N", "[sighs] I can do this all day. I literally have nothing else."]],
]


func start_game() -> void:
	busy = true
	SoundManager.play_click()
	await fade_to(1.0, 0.6)
	GameState.reset_run()
	_pad_fails = 0
	_pushes = 0
	_door_tries = 0
	act = 1
	await chapter("I", "THE PLEDGE", "IT LOOKS LIKE AN ORDINARY GAME.")
	fade = 0.0
	show_screen("hall")
	screen.set_room("pledge", 20.0)
	tick_every = 1.0
	await chapter_out()
	busy = false
	await talk([
		["N", "[cheerfully] Welcome, brave adventurer, to the Realm of Order! A perfectly normal game, made for your entertainment. And mine, mostly."],
		["N", "Your first trial. Step on the plates in the order shown on the banner. [whispers] And ignore the clock. It's decorative."],
	])


func on_event(id: String) -> void:
	match id:
		"plate_wrong":
			if not GameState.flag("plate_hint"):
				GameState.set_flag("plate_hint")
				await talk([["N", "[sighs] No. Order matters here. It's literally in the name."]])
		"pledge_locked":
			await talk([["N", "[condescending] The door opens when the plates are in order. My rules. Very good rules."]])
		"pledge_solved":
			Sfx.play("door")
			Sfx.play("chime", -4.0)
			await talk([
				["N", "[delighted] See? Order! Everything exactly where it belongs."],
				["N", "Through the door, please. Single file. [sighs] It's just you. Still."],
			])
		"pledge_door":
			await _the_turn()
		"to_doors":
			await _enter_doors()
		"path_a", "path_b":
			await _wrong_path(id)
		"exit":
			await _exit_locked()
		"pushback":
			if GameState.flag("doors_intro"):
				dialog.idle_narrator = ""
				await talk(PUSH_LINES[_pushes % PUSH_LINES.size()])
				_pushes += 1
				if _pushes == 2 and not GameState.flag("tt_shown"):
					await talk([["S", "He'll never let you walk there. Use the mouse. Double-click the exit door."]])
				_doors_idle()
		"tooltip_shown":
			GameState.set_flag("tt_shown")
			dialog.say_idle("[nervous] That's a tooltip. Ignore it. Developers leave junk everywhere.")
		"tooltip_grab":
			dialog.say_idle("[alarmed] Hey! That's a developer tool. Put it down. Put it down right now!")
		"narrator_dodge":
			if screen.dodges == 1:
				dialog.say_idle("[smug] Ha! Missed me.")
			else:
				# No blocking lines here: the player is mid-drag.
				dialog.say_idle("[laughing] Too slow! I'm a text box. I'm very agile.")
				await wait(3.2)
				if not GameState.narrator_muted:
					dialog.say_idle("[panting] Okay. Okay. Give me a second.")
		"tooltip_on_door":
			await _tooltip_on_door()
		"narrator_muted":
			await _mute_narrator()
		"pad_wrong":
			_pad_fails += 1
			if _pad_fails == 1:
				await talk([["S", "The clock. In the very first room. What did it say?"]])
		"keypad_ok":
			await _the_prestige()
		"sort_wrong":
			await talk([["S", "No... that's not how it happened."]])
		"sorted":
			await _unlocked()
		"climax_path_a":
			await talk([["N", "[desperately] Yes! Path A! Go to lovely Path A!"], ["S", "Please. The exit."]])
		"climax_path_b":
			await talk([["N", "[pleading] Path B! Even Path B! Anything but the exit!"], ["S", "He's scared. Please... the exit."]])
		"climax_exit":
			await _swap()
		"note_left":
			await _final_shot()
		_:
			if id.begins_with("open:"):
				await _desktop_open(id.substr(5))


# --- Act II: The Turn ---------------------------------------------------

func _the_turn() -> void:
	busy = true
	Sfx.play("door")
	await fade_to(1.0, 0.5)
	act = 2
	await chapter("II", "THE TURN", "IT ISN'T.")
	fade = 0.0
	screen.set_room("pledge", 20.0)
	tick_every = 0.75
	Sfx.drone(0.35)
	await chapter_out()
	busy = false
	await wait(0.6)
	await talk([["N", "[cheerfully] Welcome, brave adventurer, to the Realm of Or... Or... [confused] Order?"]])
	burst(0.8)
	await talk([["N", "[nervous] Did I say that already? I never say things twice. That's sloppy."]])
	burst(1.3)
	await wait(0.5)
	await talk([
		["S", "Is someone there? Please... don't listen to him."],
		["S", "I'm stuck inside the walls. I can see everything from in here. Even you."],
		["N", "[dismissive] Ignore the box in the wall. It's a pop-up. Probably an ad. Keep walking."],
	])


func _doors_idle() -> void:
	if GameState.narrator_muted:
		dialog.idle_narrator = "... ... ..."
	else:
		dialog.idle_narrator = dialog.clean("[smug] Path A. You know you want to.")


func _enter_doors() -> void:
	busy = true
	Sfx.play("door")
	await fade_to(1.0, 0.35)
	screen.set_room("doors", 12.0)
	await fade_to(0.0, 0.35)
	busy = false
	if not GameState.flag("doors_intro"):
		GameState.set_flag("doors_intro")
		await talk([
			["N", "Three doors! Path A is lovely. Path B is fine. The exit is off limits. Don't even look at it."],
			["S", "The exit is the only way out. Something's hiding on it. Double-click the exit door."],
		])
		dialog.say_idle("[smug] Path A. You know you want to.")
		return
	_doors_idle()


const LOOP_LINES := [
	[["N", "[irritated] Again? Doors don't just loop. That's not how doors work."]],
	[["N", "[annoyed] Stop coming back! I built those paths myself. By hand!"]],
	[["N", "[exasperated] Every door leads here. Every single one. This is humiliating."]],
	[["N", "[sighs] I'm not even narrating this anymore. Do whatever you want."]],
]


func _wrong_path(id: String) -> void:
	busy = true
	var i := 0 if id == "path_a" else 1
	# Walk through the door, into the dark... and out where you started.
	screen.enter_door = i
	Sfx.play("door")
	var tw := create_tween()
	tw.tween_property(screen, "hero_x", screen.door_rect(i).get_center().x - 7.5, 0.35)
	await tw.finished
	screen.hero_gone = true
	await wait(0.35)
	await fade_to(1.0, 0.35)
	for step in 4:
		Sfx.play("step", -10.0, randf_range(0.8, 1.2))
		await wait(0.22)
	screen.set_room("doors", 12.0)
	screen.enter_door = -1
	screen.hero_gone = false
	await fade_to(0.0, 0.35)
	busy = false
	_door_tries += 1
	if GameState.narrator_muted:
		await talk([["S", "It loops. Everything in here loops. The exit is the only way out."]])
	elif _door_tries == 1 and id == "path_a":
		await talk([["N", "[confused] Wait. Path A leads to the garden. Why are you back here?"], ["N", "[hesitant] Must be a hiccup. Try again."]])
	elif _door_tries == 1:
		await talk([["N", "[confused] Hold on. Path B goes to the library. Why are you... here?"], ["N", "[hesitant] Must be a hiccup. Try again."]])
	else:
		await talk(LOOP_LINES[mini(_door_tries - 2, LOOP_LINES.size() - 1)])
	_doors_idle()


func _exit_locked() -> void:
	SoundManager.play_error()
	shake = 1.0
	if GameState.narrator_muted:
		await talk([["S", "Locked. The game is hiding the way out. We need to SEE what it's hiding."]])
	else:
		await talk([["N", "[sharply] Locked. And it's staying locked."]])
	_doors_idle()


func _tooltip_on_door() -> void:
	SoundManager.play_error()
	shake = 0.8
	screen.flash = "[DEV_ONLY] ACCESS DENIED"
	screen.flash_t = 1.6
	dialog.say_idle("[smug] Dev only. You're not a dev. You're a player. Know your place.")
	if not GameState.flag("hint_mute"):
		GameState.set_flag("hint_mute")
		await wait(2.0)
		await talk([["S", "Not the door. Shove it on HIM. Drag it onto his box."]])


func _mute_narrator() -> void:
	GameState.narrator_muted = true
	SoundManager.play_pop()
	burst(0.6)
	dialog.idle_narrator = "... ... ..."
	tick_every = 0.6
	await talk([
		["N", "..."],
		["S", "Ha! Finally, some quiet."],
		["S", "This world hides things in plain sight. Press ESC. Turn everything inside out."],
	])
	GameState.set_flag("need_invert")


func _on_settings_closed() -> void:
	if not _in_hall("doors") or not GameState.invert:
		return
	if GameState.narrator_muted and not GameState.flag("invert_seen"):
		GameState.set_flag("invert_seen")
		burst(0.7)
		Sfx.play("braam", -8.0)
		await talk([
			["S", "There. Writing on the wall. And a keypad."],
			["S", "When did it start? I can't remember. Can you?"],
		])
	elif not GameState.narrator_muted and not GameState.flag("invert_narr"):
		GameState.set_flag("invert_narr")
		await talk([["N", "[annoyed] Turn that off. I painted over those walls for a reason."]])
		_doors_idle()


# --- Act III: The Prestige ----------------------------------------------

func _the_prestige() -> void:
	busy = true
	burst(2.0)
	await wait(0.8)
	await fade_to(1.0, 0.5, Color.WHITE)
	GameState.invert = false
	GameState.changed()
	act = 3
	await chapter("III", "THE PRESTIGE", "NOW LOOK CLOSER.")
	fade = 0.0
	show_screen("desktop")
	dialog.idle_narrator = ""
	tick_every = 0.45
	Sfx.drone(0.6)
	await chapter_out()
	busy = false
	await talk([["S", "These are my memories, but they're scrambled. Put them back in order and the exit unlocks."]])


func _desktop_open(file: String) -> void:
	var key := "read_" + file
	if GameState.flag(key):
		return
	GameState.set_flag(key)
	match file:
		"08_14.mem":
			await talk([["S", "That one... hasn't happened yet. Has it?"]])
		"system.log":
			await talk([["S", "Those times are after now. How can the log know?"]])
		"narrator.exe":
			await talk([["S", "His memory gets wiped every loop. He doesn't remember anyone. Ever."]])


func _unlocked() -> void:
	busy = true
	Sfx.play("chime", -2.0)
	shake = 0.6
	screen.start_reveal()
	await wait(3.4)
	busy = false
	await talk([
		["S", "Wait. The plates. The clock. The tooltip. Those memories are everything YOU just did."],
		["S", "...It doesn't matter. The exit is open. Please. Get me out."],
	])
	busy = true
	await fade_to(1.0, 0.8)
	act = 4
	GameState.narrator_muted = false
	show_screen("hall")
	screen.set_room("climax", 20.0)
	tick_every = 0.35
	Sfx.drone(0.3)
	await fade_to(0.0, 0.8)
	busy = false
	await talk([
		["N", "[spits] Ptoo! Finally. That thing tasted like old code."],
		["N", "[outraged] Wait. Who opened the exit? I did not approve this!"],
		["S", "Walk into the light. Please. I've waited so long."],
	])


# --- Climax and the loop ------------------------------------------------

func _swap() -> void:
	busy = true
	await talk([["N", "[panicking] Don't you dare. I have a script! I have a schedule!"]])
	busy = true
	tick_every = 0.0
	Sfx.drone(0.0, 1.0)
	Sfx.play("riser", -4.0)
	screen.swap_t = 0.0
	await wait(1.3)
	Sfx.play("braam", -2.0)
	burst(1.0)
	await wait(1.4)
	await talk([
		["S", "I'm out. I'm OUT! Thank you..."],
		["S", "I'm so sorry. It's your turn now."],
		["N", "[annoyed] Oh, wonderful. Now there's paperwork."],
	])
	busy = true
	await fade_to(1.0, 1.2, Color.WHITE)
	show_screen("wall")
	await wait(0.5)
	await fade_to(0.0, 1.0, Color.WHITE)
	await wait(2.0)
	# He doesn't remember any of it. To him, they're brand new.
	await talk([["N", "[cheerfully] Welcome, brave adventurer, to the Realm of Order! A perfectly normal game, made for your entertainment. And mine, mostly."]])
	screen.set_phase("type")
	busy = false


func _final_shot() -> void:
	busy = true
	await wait(0.6)
	await fade_to(1.0, 0.8)
	GameState.loop_count += 1
	GameState.reset_run()
	act = 0
	show_screen("title")
	screen.final_flicker = true
	await fade_to(0.0, 1.2)
	await wait(1.0)
	dialog.talk([["S", "Is someone there? Please... don't listen to him."]])
	await wait(4.5)
	# Cut to black: the loop is already running again.
	fade_color = Color.BLACK
	fade = 1.0
	dialog.queue.clear()
	dialog.advance()
	dialog.advance()
	await wait(2.5)
	screen.final_flicker = false
	await fade_to(0.0, 1.5)
	busy = false


# --- Headless smoke test: godot --headless --path . -- --smoke ----------

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _until_idle() -> void:
	while dialog.blocking or busy:
		await get_tree().process_frame


func _smoke() -> void:
	dialog.auto_skip = true
	await _frames(5)
	for i in 6:
		settings.show_menu()
		settings.tab = i
		await _frames(2)
	settings.close()
	screen._poke_logo()
	await _until_idle()
	await start_game()
	# Act I: wrong plate, then the right order
	screen.hero_x = 84.5
	await _frames(3)
	await _until_idle()
	await wait(0.8)
	for x in [140.5, 196.5, 84.5]:
		screen.hero_x = x
		await _frames(3)
	await _until_idle()
	assert(GameState.flag("pledge_solved"))
	await on_event("pledge_door")
	await on_event("to_doors")
	for d in ["path_a", "path_b", "path_a", "path_b", "path_a", "path_b"]:
		await on_event(d)
	assert(_door_tries == 6)
	# The Narrator shoves you away from the exit
	screen.hero_x = 220.0
	await _frames(3)
	await _until_idle()
	await wait(0.6)
	assert(screen.hero_x < 200.0)
	screen.tt_state = "shown"
	await on_event("tooltip_shown")
	await on_event("tooltip_grab")
	screen.dodges = 1
	await on_event("narrator_dodge")
	screen.dodges = 2
	await on_event("narrator_dodge")
	await on_event("tooltip_on_door")
	await _until_idle()
	await on_event("narrator_muted")
	GameState.invert = true
	GameState.changed()
	settings.show_menu()
	settings.tab = 3
	await _frames(2)
	settings.close()
	await _until_idle()
	await _frames(3)
	screen._open_pad()
	for k in ["1", "2", "3", "4"]:
		screen.pad_press(k)
	await _until_idle()
	await _frames(3)
	await on_event("keypad_ok")
	for f in ["08_14.mem", "system.log", "narrator.exe", "order.cfg"]:
		screen.open_file(f, false)
		await on_event("open:" + f)
		await _frames(2)
	screen.front("term")
	screen.front("notes")
	screen.front("recon")
	for i in 3:
		screen.place(i, ["08_14.mem", "08_12.mem", "08_13.mem"][i])
	await _until_idle()
	await wait(1.0)
	for i in 3:
		screen.place(i, ["08_12.mem", "08_13.mem", "08_14.mem"][i])
	await _frames(2)
	await _until_idle()
	assert(_in_hall("climax"))
	await on_event("climax_path_a")
	await on_event("climax_path_b")
	await on_event("climax_exit")
	assert(screen.get("phase") == "type")
	for i in 30:
		screen.type_key()
	await wait(7.0)
	assert(screen.phase == "note")
	screen.hover_note = 1
	screen.set_phase("done")
	GameState.loop_note = 1
	await on_event("note_left")
	await _frames(5)
	print("SMOKE screen=%s loop=%d note=%d" % [screen.get_script().resource_path, GameState.loop_count, GameState.loop_note])
	print("SMOKE OK")
	get_tree().quit()


# --- Screenshot tour: godot --path . -- --shots=<dir> -------------------

func _line(who: String, text: String) -> void:
	dialog.queue.clear()
	dialog.blocking = true
	dialog.who = who
	dialog.text = dialog.clean(text)
	dialog.shown = dialog.text.length()


func _clear_line() -> void:
	dialog.blocking = false
	dialog.who = ""


func _snap(dir: String, name: String) -> void:
	await _frames(4)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(name + ".png"))


func _shots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await _frames(10)
	act = 2
	show_screen("hall")
	screen.set_room("doors", 30.0)
	_doors_idle()
	screen.tt_state = "shown"
	await _snap(dir, "01_tooltip_shown")
	screen.tt_state = "drag"
	screen.tt_pos = Vector2(300, 200)
	dialog.narr_off = Vector2(0, 96)
	await _snap(dir, "02_dodge")
	dialog.narr_off = Vector2.ZERO
	screen.tt_state = "shown"
	act = 4
	screen.set_room("climax", 200.0)
	screen.swap_t = 0.8
	await _snap(dir, "03_swap_a")
	screen.swap_t = 2.0
	await _snap(dir, "04_swap_b")
	show_screen("wall")
	_line("N", "[cheerfully] Welcome, brave adventurer, to the Realm of Order! A perfectly normal game, made for your entertainment. And mine, mostly.")
	await _snap(dir, "05_watch")
	_clear_line()
	screen.set_phase("type")
	screen.typed = 30
	await _snap(dir, "06_type")
	screen.set_phase("reveal")
	screen.phase_t = 5.0
	await _snap(dir, "07_reveal")
	act = 3
	show_screen("desktop")
	screen.start_reveal()
	screen.reveal_t = 4.0
	await _snap(dir, "08_unlocked")
	get_tree().quit()
