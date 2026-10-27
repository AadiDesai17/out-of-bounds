extends Node
## Settings and story flags shared by every screen.

signal settings_changed

# Settings (read by the settings window through get/set)
var audio_enabled := true
var brightness := 80.0
var contrast := 50.0
var crt := true
var invert := false
var high_contrast := false
var screen_shake := true
var color_blind := false
var master_volume := 80.0
var text_speed := 50.0

# Story
const NOTES := [["DON'T", "TRUST THE", "BOX."], ["THE CLOCK", "SAYS", "08:14."], ["JUST A", "GAME."]]
var loop_count := 0
## Which note the player left for the next loop (-1 = none yet).
var loop_note := -1
var narrator_muted := false
var flags := {}


func flag(key: String) -> bool:
	return flags.get(key, false)


func set_flag(key: String) -> void:
	flags[key] = true


func reset_run() -> void:
	flags.clear()
	narrator_muted = false
	invert = false
	changed()


func changed() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.5) / 100.0))
	settings_changed.emit()
