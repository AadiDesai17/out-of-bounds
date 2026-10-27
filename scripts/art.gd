class_name Art
## Shared palette, sprites and pixel-art drawing helpers.

const BRICK := [Color("#5a3324"), Color("#4e2c1f"), Color("#64392a"), Color("#46281c"), Color("#2b1912")]
const BRICK_DIM := [Color("#3a2219"), Color("#331d15"), Color("#40261c"), Color("#2e1a13"), Color("#1a0f0b")]
const BRICK_COOL := [Color("#2a1d2e"), Color("#241829"), Color("#30223a"), Color("#1e1424"), Color("#120a14")]

const OUTLINE := Color("#1a0e08")
const PARCH := Color("#e8dcc0")
const PARCH_DARK := Color("#d6c8a6")
const INK := Color("#3a2416")
const DARK := Color("#120c0a")
const TEAL := Color("#3fd9c1")
const TEAL_BTN := Color("#2ec4a8")
const TEAL_DARK := Color("#0a1a1c")
const NOTE := Color("#e8c27a")
const TORCH := Color("#ff9a3c")
const MAGENTA := Color("#e040a0")
const RED := Color("#c8322e")
const GOLD := Color("#f2c14e")
const TITLEBAR := Color("#3a4a5a")
const CREAM := Color("#f2ead8")
const WOOD := Color("#5a341c")
const FLOOR := Color("#3a2a22")

const HERO_TOP := [
	"....kkkkkk......",
	"...krrrrrrk.....",
	"..krrrrrrrrkkk..",
	"..khhssssssk....",
	"..khsssskssk....",
	"..khssssssssk...",
	"...kssssssk.....",
	"....kkssskk.....",
	"...krrrrrrrk....",
	"..ksrrrrrrrsk...",
	"..ksrrrrrrrsk...",
	"...kbbbbbbbk....",
	"...kbbbbbbbk....",
]
const LEGS_A := [
	"...kbbkkkbbk....",
	"...kbbk.kbbk....",
	"..kkkk..kkkk....",
]
const LEGS_B := [
	"....kbbbbbk.....",
	"....kbbbbbk.....",
	"....kkkkkkk.....",
]
const NARR := [
	".kkkkkkkkkkkkkk.",
	"kttttttttttttttk",
	"ktyyyyyyyyyyyytk",
	"ktyyyyyyyyyyyytk",
	"ktyykkyyyykkyytk",
	"ktyykkyyyykkyytk",
	"ktyyyyyyyyyyyytk",
	"ktyyyyyyyyyyyytk",
	"ktykyyyyyyyykytk",
	"ktyykyyyyyykyytk",
	"ktyyykkkkkkyyytk",
	"ktyyyyyyyyyyyytk",
	"kttttttttttttttk",
	".kkkkkkkkkkkkkk.",
]
const CURSOR := [
	"k........",
	"kk.......",
	"kwk......",
	"kwwk.....",
	"kwwwk....",
	"kwwwwk...",
	"kwwwwwk..",
	"kwwwwwwk.",
	"kwwwkkkk.",
	"kwwk.....",
	"kwk......",
	"kk.......",
]

const HERO_PAL := {"k": Color("#1a0e08"), "r": Color("#c8322e"), "h": Color("#5a3020"), "s": Color("#f0b98a"), "b": Color("#2f4a8a")}
const GHOST_PAL := {"k": Color("#3fd9c1"), "r": Color("#14504a"), "h": Color("#1a5a55"), "s": Color("#0e3a38"), "b": Color("#1a5a55")}
const SHADOW_PAL := {"k": Color("#ececec"), "r": Color("#e0e0e0"), "h": Color("#e0e0e0"), "s": Color("#e0e0e0"), "b": Color("#e0e0e0")}
const DARK_PAL := {"k": Color("#120a06"), "r": Color("#120a06"), "h": Color("#120a06"), "s": Color("#120a06"), "b": Color("#120a06")}
const NARR_PAL := {"k": Color("#1a0e08"), "t": Color("#3fd9c1"), "y": Color("#f2d98a")}


static func sprite(ci: CanvasItem, rows: Array, pal: Dictionary, pos: Vector2, s: float = 1.0, flip: bool = false) -> void:
	for j in rows.size():
		var row: String = rows[j]
		var n := row.length()
		for i in n:
			var ch := row[i]
			if ch == ".":
				continue
			var x := (n - 1 - i) if flip else i
			ci.draw_rect(Rect2(pos.x + x * s, pos.y + j * s, s, s), pal.get(ch, MAGENTA))


static func hero(ci: CanvasItem, pos: Vector2, frame: int, flip: bool, pal: Dictionary = HERO_PAL) -> void:
	var rows: Array = HERO_TOP + (LEGS_A if frame == 0 else LEGS_B)
	sprite(ci, rows, pal, pos, 1.0, flip)


static func box(ci: CanvasItem, r: Rect2, fill: Color, border: Color, w: float = 1.0) -> void:
	ci.draw_rect(r, border)
	ci.draw_rect(r.grow(-w), fill)


static func frame(ci: CanvasItem, r: Rect2, col: Color, w: float = 1.0) -> void:
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, w), col)
	ci.draw_rect(Rect2(r.position.x, r.end.y - w, r.size.x, w), col)
	ci.draw_rect(Rect2(r.position.x, r.position.y, w, r.size.y), col)
	ci.draw_rect(Rect2(r.end.x - w, r.position.y, w, r.size.y), col)


static func dashed(ci: CanvasItem, r: Rect2, col: Color) -> void:
	var x := r.position.x
	while x < r.end.x:
		ci.draw_rect(Rect2(x, r.position.y, minf(3, r.end.x - x), 1), col)
		ci.draw_rect(Rect2(x, r.end.y - 1, minf(3, r.end.x - x), 1), col)
		x += 6
	var y := r.position.y
	while y < r.end.y:
		ci.draw_rect(Rect2(r.position.x, y, 1, minf(3, r.end.y - y)), col)
		ci.draw_rect(Rect2(r.end.x - 1, y, 1, minf(3, r.end.y - y)), col)
		y += 6


static func bricks(ci: CanvasItem, rect: Rect2, seed_val: int, pal: Array = BRICK, bw: float = 16.0, bh: float = 8.0) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_val
	ci.draw_rect(rect, pal[4])
	var row := 0
	var y := rect.position.y
	while y < rect.end.y:
		var h := minf(bh - 1, rect.end.y - y)
		var x := rect.position.x - (bw * 0.5 if row % 2 == 1 else 0.0)
		while x < rect.end.x:
			var col: Color = pal[r.randi() % 4]
			var x0 := maxf(x, rect.position.x)
			var x1 := minf(x + bw - 1, rect.end.x)
			if x1 > x0:
				ci.draw_rect(Rect2(x0, y, x1 - x0, h), col)
				ci.draw_rect(Rect2(x0, y, x1 - x0, 1), Color(1, 0.86, 0.7, 0.07))
			x += bw
		y += bh
		row += 1


static func floor_planks(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_rect(rect, FLOOR)
	ci.draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 1), Color("#5a4232"))
	var y := rect.position.y + 7
	var k := 0
	while y < rect.end.y:
		ci.draw_rect(Rect2(rect.position.x, y, rect.size.x, 1), Color("#2e2019"))
		var x := rect.position.x + float((k * 37) % 50)
		while x < rect.end.x:
			ci.draw_rect(Rect2(x, y - 6, 1, 6), Color("#2e2019"))
			x += 50
		y += 8
		k += 1


## Rectangle with a stepped arch on top.
static func arch(ci: CanvasItem, r: Rect2, col: Color) -> void:
	ci.draw_rect(r, col)
	ci.draw_rect(Rect2(r.position.x + 2, r.position.y - 2, r.size.x - 4, 2), col)
	ci.draw_rect(Rect2(r.position.x + 5, r.position.y - 4, r.size.x - 10, 2), col)
	if r.size.x > 20:
		ci.draw_rect(Rect2(r.position.x + 9, r.position.y - 5, r.size.x - 18, 1), col)


static func door(ci: CanvasItem, r: Rect2, open_light: bool = false, light: Color = Color("#f4fffd")) -> void:
	arch(ci, r.grow(2), OUTLINE)
	if open_light:
		arch(ci, r, light)
		return
	arch(ci, r, WOOD)
	var x := r.position.x + 5
	while x < r.end.x - 1:
		ci.draw_rect(Rect2(x, r.position.y - 3, 1, r.size.y + 3), Color(0, 0, 0, 0.28))
		x += 6
	ci.draw_rect(Rect2(r.position.x, r.position.y + 6, r.size.x, 2), Color("#2a1d14"))
	ci.draw_rect(Rect2(r.position.x, r.end.y - 10, r.size.x, 2), Color("#2a1d14"))
	ci.draw_rect(Rect2(r.end.x - 6, r.position.y + r.size.y * 0.5, 2, 2), GOLD)


static func plaque(ci: CanvasItem, center_x: float, y: float, text: String, hot: bool) -> void:
	var w := PxFont.width(text) + 10
	var r := Rect2(floorf(center_x - w / 2.0), y, w, 13)
	ci.draw_rect(Rect2(r.position.x + 4, y - 4, 1, 4), OUTLINE)
	ci.draw_rect(Rect2(r.end.x - 5, y - 4, 1, 4), OUTLINE)
	if hot:
		ci.draw_rect(r.grow(5), Color(1, 0.55, 0.2, 0.12))
		box(ci, r, Color("#e86a2a"), OUTLINE)
	else:
		box(ci, r, INK, OUTLINE)
		frame(ci, r.grow(-1), Color("#c89a5a"))
	PxFont.draw_centered(ci, center_x, y + 3, text, Color("#fff2d8") if hot else PARCH)


## A wall torch. "flip" burns downwards (time running backwards).
static func torch(ci: CanvasItem, p: Vector2, t: float, flip: bool = false) -> void:
	var f := roundf(sin(t * 11.0 + p.x))
	var glow := 0.07 + 0.025 * sin(t * 7.0 + p.x)
	ci.draw_rect(Rect2(p.x - 14, p.y - 20, 31, 34), Color(1, 0.6, 0.24, glow))
	ci.draw_rect(Rect2(p.x - 7, p.y - 12, 17, 18), Color(1, 0.6, 0.24, 0.10))
	ci.draw_rect(Rect2(p.x - 1, p.y - 1, 5, 2), Color("#6a4a2a"))
	ci.draw_rect(Rect2(p.x, p.y, 3, 8), Color("#3a2416"))
	if flip:
		ci.draw_rect(Rect2(p.x - 1, p.y + 9 - f, 5, 5), TORCH)
		ci.draw_rect(Rect2(p.x, p.y + 10 - f, 3, 3), Color("#ffd27a"))
	else:
		ci.draw_rect(Rect2(p.x - 1, p.y - 6 + f, 5, 5), TORCH)
		ci.draw_rect(Rect2(p.x, p.y - 4 + f, 3, 3), Color("#ffd27a"))


const SYMBOLS := {
	"sun": ["...#...", ".#...#.", "..###..", "#.###.#", "..###..", ".#...#.", "...#..."],
	"moon": ["..###..", ".##....", "##.....", "##.....", "##.....", ".##....", "..###.."],
	"star": ["...#...", "...#...", "..###..", "#######", "..###..", ".##.##.", "##...##"],
}


static func symbol(ci: CanvasItem, kind: String, center: Vector2, col: Color) -> void:
	sprite(ci, SYMBOLS[kind], {"#": col}, (center - Vector2(3.5, 3.5)).round())


static func sticky(ci: CanvasItem, center: Vector2, size: Vector2, angle: float, lines: Array, col: Color = NOTE, ink: Color = INK, s: int = 1) -> void:
	ci.draw_set_transform(center, angle, Vector2.ONE)
	var r := Rect2(-size / 2.0, size)
	ci.draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.25))
	ci.draw_rect(r, col)
	ci.draw_rect(Rect2(r.position.x, r.end.y - 3, r.size.x, 3), col.darkened(0.18))
	ci.draw_rect(Rect2(-5, r.position.y - 2, 10, 4), Color(0.95, 0.93, 0.85, 0.55))
	var top := r.position.y + (r.size.y - lines.size() * 9 * s) / 2.0
	for i in lines.size():
		PxFont.draw_centered(ci, 0, top + i * 9 * s, lines[i], ink, s)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func close_rect(r: Rect2) -> Rect2:
	return Rect2(r.end.x - 12, r.position.y + 1, 11, 10)


static func window(ci: CanvasItem, r: Rect2, title: String, focused: bool = true) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(3, 3), r.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(r.grow(1), OUTLINE)
	ci.draw_rect(r, PARCH)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 12)), TITLEBAR if focused else Color("#6a7480"))
	PxFont.draw(ci, r.position + Vector2(4, 3), title, PARCH)
	var x := close_rect(r)
	ci.draw_rect(x, RED)
	PxFont.draw(ci, x.position + Vector2(3, 2), "X", CREAM)


static func button(ci: CanvasItem, r: Rect2, label: String, hot: bool) -> void:
	ci.draw_rect(r.grow(1), OUTLINE)
	if hot:
		ci.draw_rect(r, TEAL_BTN)
	else:
		ci.draw_rect(r, PARCH)
		ci.draw_rect(r.grow(-1), Color("#1a1210"))
	PxFont.draw_centered(ci, r.get_center().x, floorf(r.get_center().y - 3), label, TEAL_DARK if hot else PARCH)


static func tooltip(ci: CanvasItem, r: Rect2, loose: bool) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(3, 3), r.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(r, Color("#2a2240") if loose else DARK)
	if loose:
		dashed(ci, r, PARCH)
	else:
		frame(ci, r, GOLD)
	PxFont.draw(ci, r.position + Vector2(6, 6), "TOOLTIP: SPAWNS EXIT PORTAL", GOLD)
	PxFont.draw(ci, r.position + Vector2(6, 17), "(COST: 0 HP)", GOLD)
	PxFont.draw(ci, r.position + Vector2(6, 28), "[DEV_ONLY]", GOLD)


static func gear(ci: CanvasItem, c: Vector2, col: Color) -> void:
	for i in 8:
		var d := Vector2.RIGHT.rotated(i * TAU / 8.0) * 6.0
		ci.draw_rect(Rect2((c + d - Vector2(1.5, 1.5)).round(), Vector2(3, 3)), col)
	ci.draw_circle(c, 5.0, col)
	ci.draw_circle(c, 2.0, DARK)
