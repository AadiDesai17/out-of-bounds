extends Node2D
## Topmost layer: CRT scanlines, vignette, glitch noise, fades and the pixel cursor.

var main: Node


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var full := Rect2(0, 0, 640, 360)
	if GameState.crt:
		for y in range(0, 360, 2):
			draw_rect(Rect2(0, y, 640, 1), Color(0, 0, 0, 0.13))
		for i in 5:
			Art.frame(self, full.grow(-i * 6), Color(0.04, 0.02, 0.01, 0.09), 6)
	if main.glitch > 0.05:
		for i in int(main.glitch * 26):
			var c := Art.MAGENTA if randf() < 0.5 else Art.TEAL
			draw_rect(Rect2(randi() % 640, randi() % 360, 2 + randi() % 16, 1 + randi() % 3), c)
	if main.fade > 0.0:
		var fc: Color = main.fade_color
		fc.a = main.fade
		draw_rect(full, fc)
	if main.card_alpha > 0.0:
		var a: float = main.card_alpha
		draw_rect(full, Color(0, 0, 0, a))
		var txt_a := clampf(a * 1.4 - 0.3, 0.0, 1.0)
		PxFont.draw_centered(self, 320, 126, main.card_num, Color(Art.GOLD, txt_a), 2)
		draw_rect(Rect2(250, 146, 140, 1), Color(Art.GOLD, txt_a * 0.6))
		PxFont.draw_centered(self, 320, 158, main.card_title, Color(Art.CREAM, txt_a), 4)
		draw_rect(Rect2(250, 194, 140, 1), Color(Art.GOLD, txt_a * 0.6))
		PxFont.draw_centered(self, 320, 206, main.card_sub, Color(Art.PARCH, txt_a * 0.8))
	var m := get_global_mouse_position().floor()
	Art.sprite(self, Art.CURSOR, {"k": Art.OUTLINE, "w": Art.TEAL if main.grabbing else Color.WHITE}, m)
