class_name Screen
extends Node2D
## Base for full-screen scenes. "world" is a 320x180 pixel layer drawn at 2x,
## "hud" is drawn at native 640x360 on top of it.

var main: Node
var world := Node2D.new()
var hud := Node2D.new()
var t := 0.0


func _ready() -> void:
	world.scale = Vector2(2, 2)
	add_child(world)
	add_child(hud)
	world.draw.connect(draw_world)
	hud.draw.connect(draw_hud)
	main.top_ui.draw.connect(draw_top)
	setup()


func _exit_tree() -> void:
	main.top_ui.draw.disconnect(draw_top)


func _process(delta: float) -> void:
	t += delta
	update(delta)
	world.queue_redraw()
	hud.queue_redraw()
	main.top_ui.queue_redraw()


func setup() -> void:
	pass


func update(_delta: float) -> void:
	pass


func draw_world() -> void:
	pass


func draw_hud() -> void:
	pass


## Drawn above the screen shader, so it is never inverted or dimmed.
func draw_top() -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass


func wmouse() -> Vector2:
	return world.get_local_mouse_position()


func hmouse() -> Vector2:
	return hud.get_local_mouse_position()


func can_play() -> bool:
	return main.can_play()


func clicked(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed


func released(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
