class_name PxFont
## 5x7 bitmap font baked into a texture atlas at first use.
## Lowercase letters render as uppercase.

const GW := 5
const GH := 7
const ADV := 6
const LINE := 10

const GLYPHS := {
	"A": ".###.|#...#|#...#|#####|#...#|#...#|#...#",
	"B": "####.|#...#|#...#|####.|#...#|#...#|####.",
	"C": ".###.|#...#|#....|#....|#....|#...#|.###.",
	"D": "####.|#...#|#...#|#...#|#...#|#...#|####.",
	"E": "#####|#....|#....|####.|#....|#....|#####",
	"F": "#####|#....|#....|####.|#....|#....|#....",
	"G": ".###.|#...#|#....|#.###|#...#|#...#|.####",
	"H": "#...#|#...#|#...#|#####|#...#|#...#|#...#",
	"I": ".###.|..#..|..#..|..#..|..#..|..#..|.###.",
	"J": "..###|...#.|...#.|...#.|...#.|#..#.|.##..",
	"K": "#...#|#..#.|#.#..|##...|#.#..|#..#.|#...#",
	"L": "#....|#....|#....|#....|#....|#....|#####",
	"M": "#...#|##.##|#.#.#|#.#.#|#...#|#...#|#...#",
	"N": "#...#|#...#|##..#|#.#.#|#..##|#...#|#...#",
	"O": ".###.|#...#|#...#|#...#|#...#|#...#|.###.",
	"P": "####.|#...#|#...#|####.|#....|#....|#....",
	"Q": ".###.|#...#|#...#|#...#|#.#.#|#..#.|.##.#",
	"R": "####.|#...#|#...#|####.|#.#..|#..#.|#...#",
	"S": ".####|#....|#....|.###.|....#|....#|####.",
	"T": "#####|..#..|..#..|..#..|..#..|..#..|..#..",
	"U": "#...#|#...#|#...#|#...#|#...#|#...#|.###.",
	"V": "#...#|#...#|#...#|#...#|#...#|.#.#.|..#..",
	"W": "#...#|#...#|#...#|#.#.#|#.#.#|#.#.#|.#.#.",
	"X": "#...#|#...#|.#.#.|..#..|.#.#.|#...#|#...#",
	"Y": "#...#|#...#|.#.#.|..#..|..#..|..#..|..#..",
	"Z": "#####|....#|...#.|..#..|.#...|#....|#####",
	"0": ".###.|#...#|#..##|#.#.#|##..#|#...#|.###.",
	"1": "..#..|.##..|..#..|..#..|..#..|..#..|.###.",
	"2": ".###.|#...#|....#|...#.|..#..|.#...|#####",
	"3": "####.|....#|....#|.###.|....#|....#|####.",
	"4": "...#.|..##.|.#.#.|#..#.|#####|...#.|...#.",
	"5": "#####|#....|####.|....#|....#|#...#|.###.",
	"6": ".###.|#....|#....|####.|#...#|#...#|.###.",
	"7": "#####|....#|...#.|..#..|.#...|.#...|.#...",
	"8": ".###.|#...#|#...#|.###.|#...#|#...#|.###.",
	"9": ".###.|#...#|#...#|.####|....#|....#|.###.",
	".": ".....|.....|.....|.....|.....|.##..|.##..",
	",": ".....|.....|.....|.....|.##..|..#..|.#...",
	"!": "..#..|..#..|..#..|..#..|..#..|.....|..#..",
	"?": ".###.|#...#|....#|...#.|..#..|.....|..#..",
	"'": "..#..|..#..|.#...|.....|.....|.....|.....",
	"\"": ".#.#.|.#.#.|.....|.....|.....|.....|.....",
	":": ".....|.##..|.##..|.....|.##..|.##..|.....",
	";": ".....|.##..|.##..|.....|.##..|..#..|.#...",
	"-": ".....|.....|.....|.###.|.....|.....|.....",
	"_": ".....|.....|.....|.....|.....|.....|#####",
	"(": "...#.|..#..|.#...|.#...|.#...|..#..|...#.",
	")": ".#...|..#..|...#.|...#.|...#.|..#..|.#...",
	"[": ".###.|.#...|.#...|.#...|.#...|.#...|.###.",
	"]": ".###.|...#.|...#.|...#.|...#.|...#.|.###.",
	"/": "....#|...#.|...#.|..#..|.#...|.#...|#....",
	"+": ".....|..#..|..#..|#####|..#..|..#..|.....",
	"=": ".....|.....|#####|.....|#####|.....|.....",
	"*": ".....|#.#.#|.###.|#####|.###.|#.#.#|.....",
	"#": ".#.#.|.#.#.|#####|.#.#.|#####|.#.#.|.#.#.",
	"%": "##..#|##.#.|...#.|..#..|.#...|.#.##|#..##",
	">": ".#...|..#..|...#.|....#|...#.|..#..|.#...",
	"<": "...#.|..#..|.#...|#....|.#...|..#..|...#.",
	"&": ".##..|#..#.|#.#..|.#...|#.#.#|#..#.|.##.#",
	"@": ".###.|#...#|#.###|#.#.#|#.###|#....|.###.",
	"|": "..#..|..#..|..#..|..#..|..#..|..#..|..#..",
}

static var _tex: ImageTexture
static var _index := {}


static func _build() -> void:
	var keys := GLYPHS.keys()
	var img := Image.create(keys.size() * ADV, GH, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in keys.size():
		var rows: PackedStringArray = String(GLYPHS[keys[i]]).split("|")
		for y in GH:
			for x in GW:
				if rows[y][x] == "#":
					img.set_pixel(i * ADV + x, y, Color.WHITE)
		_index[keys[i]] = i
	_tex = ImageTexture.create_from_image(img)


static func draw(ci: CanvasItem, pos: Vector2, text: String, col: Color, s: int = 1) -> void:
	if _tex == null:
		_build()
	var x := floorf(pos.x)
	var y := floorf(pos.y)
	for ch in text.to_upper():
		var i: int = _index.get(ch, -1)
		if i >= 0:
			ci.draw_texture_rect_region(_tex, Rect2(x, y, GW * s, GH * s), Rect2(i * ADV, 0, GW, GH), col)
		x += ADV * s


static func draw_outlined(ci: CanvasItem, pos: Vector2, text: String, col: Color, outline: Color, s: int = 1) -> void:
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(1, 1), Vector2(2, 2)]:
		draw(ci, pos + o * s, text, outline, s)
	draw(ci, pos, text, col, s)


static func draw_centered(ci: CanvasItem, center_x: float, y: float, text: String, col: Color, s: int = 1) -> void:
	draw(ci, Vector2(center_x - width(text, s) / 2.0, y), text, col, s)


static func draw_block(ci: CanvasItem, pos: Vector2, lines: PackedStringArray, col: Color, s: int = 1, line_h: int = LINE) -> void:
	for i in lines.size():
		draw(ci, pos + Vector2(0, i * line_h * s), lines[i], col, s)


static func width(text: String, s: int = 1) -> int:
	return maxi(0, text.length() * ADV * s - s)


## Word-wraps text to fit max_w pixels. Honors "\n".
static func wrap(text: String, max_w: int, s: int = 1) -> PackedStringArray:
	var out := PackedStringArray()
	var max_chars: int = maxi(1, int((max_w + s) / float(ADV * s)))
	for para in text.split("\n"):
		var line := ""
		for word in para.split(" "):
			var trial: String = word if line == "" else line + " " + word
			if trial.length() <= max_chars:
				line = trial
				continue
			if line != "":
				out.append(line)
			line = word
			while line.length() > max_chars:
				out.append(line.substr(0, max_chars))
				line = line.substr(max_chars)
		out.append(line)
	return out
