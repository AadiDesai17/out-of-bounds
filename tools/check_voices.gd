extends SceneTree
## Prints each narrator voice file and its length: godot --headless --path . -s tools/check_voices.gd

func _init() -> void:
	var lines: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://voice/lines.json"))
	var total := 0.0
	for key in lines:
		var text: String = lines[key]
		var path := "res://voice/n_%s.mp3" % text.md5_text().substr(0, 12)
		var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
		var secs := s.get_length() if s else -1.0
		total += maxf(secs, 0.0)
		print("%5.1fs  %s  %s" % [secs, "ok " if s else "MISSING", text.left(50)])
	print("TOTAL %.1fs" % total)
	quit()
