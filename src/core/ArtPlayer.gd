extends RefCounted
## Sprite di Flavio generati per i 5 stadi di crescita (6, 9, 14, 20, 30 anni).

const CW := 24
const CH := 36
const SKIN := Color("f2c6a0")
const HAIR := Color("5a3a22")
const INK := Color("1a1423")

const SPEC := [
	{"head_w": 8, "torso": 6, "legs": 5, "shirt": "8fc3ee", "pants": "8fc3ee", "shoe": "f2c6a0", "extra": "pajama"},
	{"head_w": 8, "torso": 7, "legs": 6, "shirt": "d9534f", "pants": "24306e", "shoe": "ffffff", "extra": "backpack"},
	{"head_w": 7, "torso": 8, "legs": 8, "shirt": "3aa39a", "pants": "3b4a7a", "shoe": "e8e8f0", "extra": "hood"},
	{"head_w": 7, "torso": 9, "legs": 10, "shirt": "6b6fd6", "pants": "2e3350", "shoe": "4a2f1f", "extra": "scarf"},
	{"head_w": 7, "torso": 10, "legs": 12, "shirt": "e8e8f0", "pants": "2a2a3a", "shoe": "1a1423", "extra": "tie"},
]

# posa: [gamba A dx, gamba A accorciata, gamba B dx, gamba B accorciata, sollevamento, braccia]
const POSES := {
	"idle": [0, 0, 0, 0, 0, "down"],
	"run0": [2, 1, -2, 0, 0, "swing"],
	"run1": [0, 0, 0, 1, 1, "down"],
	"run2": [-2, 0, 2, 1, 0, "swing2"],
	"run3": [0, 1, 0, 0, 1, "down"],
	"jump": [1, 2, -1, 0, 0, "up"],
	"fall": [2, 0, -2, 1, 0, "out"],
	"hurt": [1, 1, -2, 0, 0, "up"],
	"glide": [1, 1, -1, 0, 0, "umbrella"],
}


static func frames(stage: int, dark: bool) -> Dictionary:
	var out := {}
	for name in POSES:
		out[name] = _tex(_draw(stage, name), dark)
	out["slide"] = _tex(_draw_slide(stage), dark)
	return out


static func _tex(img: Image, dark: bool) -> ImageTexture:
	if dark:
		for y in range(CH):
			for x in range(CW):
				var c := img.get_pixel(x, y)
				if c.a > 0.0:
					var l := c.get_luminance()
					img.set_pixel(x, y, Color(0.1 + l * 0.22, 0.05 + l * 0.1, 0.18 + l * 0.35))
	return Art.ArtShade.tex3d(img, true, 0.35)


static func _edge(src: Image, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= src.get_width() or y >= src.get_height():
		return true
	var c := src.get_pixel(x, y)
	return c.a < 0.5 or c.get_luminance() < 0.13


## Dà volume a uno sprite: luce da in alto a sinistra, ombra in basso a destra.
static func shade(img: Image) -> void:
	var src: Image = img.duplicate()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := src.get_pixel(x, y)
			if c.a < 0.5 or c.get_luminance() < 0.13 or c.get_luminance() > 0.97:
				continue
			if _edge(src, x, y + 1) or _edge(src, x + 1, y):
				img.set_pixel(x, y, c.darkened(0.2))
			elif _edge(src, x, y - 1):
				img.set_pixel(x, y, c.lightened(0.2))


## Contorno scuro di 1 px per staccare lo sprite dallo sfondo.
static func outline(img: Image) -> void:
	var src: Image = img.duplicate()
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
				var nx: int = x + d[0]
				var ny: int = y + d[1]
				if nx >= 0 and nx < w and ny >= 0 and ny < h and src.get_pixel(nx, ny).a > 0.5:
					img.set_pixel(x, y, INK)
					break


static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h).intersection(Rect2i(0, 0, CW, CH)), c)


static func _draw(stage: int, pose_name: String) -> Image:
	var s: Dictionary = SPEC[stage]
	var p: Array = POSES[pose_name]
	var img := Image.create(CW, CH, false, Image.FORMAT_RGBA8)
	var cx := 12
	var shirt := Color(s["shirt"])
	var pants := Color(s["pants"])
	var shoe := Color(s["shoe"])
	var legs: int = s["legs"]
	var torso: int = s["torso"]
	var lift: int = p[4]
	var base := CH - 1 - lift  # ultima riga occupata dai piedi (lasciando 1 px per il contorno)
	# gambe
	for i in range(2):
		var dx: int = p[i * 2]
		var short: int = p[i * 2 + 1]
		var lx := cx - 3 + i * 4 + dx
		var top := base - legs
		var length := legs - short
		_r(img, lx, top, 2, length, pants.darkened(0.12) if i == 0 else pants)
		if stage == 1:
			_r(img, lx, top + 3, 2, length - 3, SKIN)
		_r(img, lx, top + length - 1, 3, 1, shoe)
	# busto
	var ty := base - legs - torso
	_r(img, cx - 3, ty, 6, torso, shirt)
	match s["extra"]:
		"pajama":
			for y in range(ty + 1, base, 2):
				for x in range(CW):
					if img.get_pixel(x, y) == shirt or img.get_pixel(x, y) == pants.darkened(0.12):
						img.set_pixel(x, y, Color("ffffff"))
		"backpack":
			_r(img, cx - 5, ty + 1, 2, torso - 2, Color("3f9a4f"))
		"hood":
			_r(img, cx - 4, ty, 2, 3, shirt.darkened(0.25))
			_r(img, cx - 1, ty + torso - 3, 3, 2, shirt.darkened(0.2))
		"scarf":
			_r(img, cx - 3, ty, 6, 2, Color("d9534f"))
			_r(img, cx - 5, ty + 1, 2, 4, Color("d9534f"))
		"tie":
			_r(img, cx + 1, ty + 1, 1, torso - 3, Color("8f2d3a"))
			_r(img, cx - 3, ty + torso - 1, 6, 1, Color("4a2f1f"))
	# braccia
	var arm := torso - 2
	match p[5]:
		"down":
			_r(img, cx - 4, ty + 1, 1, arm, shirt.darkened(0.2))
			_r(img, cx + 3, ty + 1, 1, arm, shirt.darkened(0.1))
			_r(img, cx + 3, ty + arm, 1, 1, SKIN)
			_r(img, cx - 4, ty + arm, 1, 1, SKIN)
		"swing", "swing2":
			var f := 1 if p[5] == "swing" else -1
			for i in range(arm):
				_r(img, cx + 3 + f * (i / 2), ty + 1 + i, 1, 1, shirt.darkened(0.1) if i < arm - 1 else SKIN)
				_r(img, cx - 4 - f * (i / 2), ty + 1 + i, 1, 1, shirt.darkened(0.2) if i < arm - 1 else SKIN)
		"up", "umbrella":
			_r(img, cx - 5, ty - 2, 1, 4, shirt.darkened(0.2))
			_r(img, cx + 4, ty - 2, 1, 4, shirt.darkened(0.1))
			_r(img, cx - 5, ty - 3, 1, 1, SKIN)
			_r(img, cx + 4, ty - 3, 1, 1, SKIN)
		"out":
			_r(img, cx - 6, ty + 1, 3, 1, shirt.darkened(0.2))
			_r(img, cx + 3, ty + 1, 3, 1, shirt.darkened(0.1))
			_r(img, cx - 7, ty, 1, 1, SKIN)
			_r(img, cx + 6, ty, 1, 1, SKIN)
	# testa
	var hw: int = s["head_w"]
	var hx := cx - 4
	var hy := ty - 7
	_r(img, hx, hy, hw, 7, SKIN)
	_r(img, hx, hy, hw, 2, HAIR)
	_r(img, hx, hy + 2, 2, 3, HAIR)
	_r(img, hx + hw - 1, hy + 2, 1, 1, HAIR)
	if stage >= 3:
		_r(img, hx + hw - 2, hy + 5, 2, 1, HAIR.lightened(0.1) if stage == 4 else SKIN)
	if pose_name == "hurt":
		_r(img, hx + hw - 4, hy + 3, 3, 1, INK)
	else:
		_r(img, hx + hw - 3, hy + 3, 1, 2, INK)
	if stage == 0:
		_r(img, hx + hw - 2, hy + 5, 1, 1, Color("f08fc0"))
	if p[5] == "umbrella":
		var uy := maxi(0, hy - 7)
		_r(img, cx + 4, uy + 3, 1, ty - 3 - uy - 3, Color("4a2f1f"))
		_r(img, cx - 3, uy + 2, 15, 1, Color("ffe45e"))
		_r(img, cx - 2, uy + 1, 13, 1, Color("ffe45e"))
		_r(img, cx, uy, 9, 1, Color("ffe45e"))
		_r(img, cx - 3, uy + 3, 1, 1, Color("c9962e"))
		_r(img, cx + 11, uy + 3, 1, 1, Color("c9962e"))
		_r(img, cx + 4, uy + 1, 1, 2, Color("c9962e"))
	return img


static func _draw_slide(stage: int) -> Image:
	var s: Dictionary = SPEC[stage]
	var img := Image.create(CW, CH, false, Image.FORMAT_RGBA8)
	var shirt := Color(s["shirt"])
	var pants := Color(s["pants"])
	var base := CH - 1
	_r(img, 1, base - 3, 8, 3, pants)
	_r(img, 0, base - 2, 2, 2, Color(s["shoe"]))
	_r(img, 8, base - 6, 8, 6, shirt)
	_r(img, 15, base - 10, 7, 7, SKIN)
	_r(img, 15, base - 10, 7, 2, HAIR)
	_r(img, 15, base - 8, 2, 3, HAIR)
	_r(img, 19, base - 7, 1, 2, INK)
	_r(img, 12, base - 2, 6, 1, shirt.darkened(0.15))
	_r(img, 18, base - 2, 1, 1, SKIN)
	return img
