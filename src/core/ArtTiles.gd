extends RefCounted
## Tileset dei mondi. Ogni mondo ha un "materiale" 64x64 ripetibile (assi di legno,
## mattoni, roccia...) da cui si ritagliano 16 varianti di ogni tile, così il motivo
## non si ripete a ogni casella; sopra si aggiungono bordi, cornici e ombre.
##
## Atlante (tile 16x16): colonne = maschera dei lati aperti (1 su, 2 destra, 4 giù,
## 8 sinistra), righe 0..15 = variante (ty % 4) * 4 + (tx % 4).
## Riga 16 = tile speciali, righe 17 e 18 = muro finto (senza e con bordo superiore).

const M := 64
const ROW_MISC := 16
const ROW_FAKE := 17
const ROW_FAKE_TOP := 18
const ROW_TOP := 19
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


static func build(world: int) -> Image:
	var img := Image.create(256, 16 * 20, false, Image.FORMAT_RGBA8)
	var mat := material(world)
	var style: String = G.WORLDS[world - 1]["style"]
	for v in range(16):
		for m in range(16):
			_solid(img, m * 16, v * 16, mat, m, v, world, style)
		for k in range(2):
			var oy := (ROW_FAKE + k) * 16
			_solid(img, v * 16, oy, mat, k, v, world, style)
			_crack(img, v * 16, oy, G.pal(world, "dark").darkened(0.45))
	_misc(img, world)
	_tops(img, world, style)
	return img


## Superfici viste dall'alto (la "terrazza" dei blocchi in 3D): v = 0 dietro, 15 davanti.
static func _tops(img: Image, world: int, style: String) -> void:
	var top := G.pal(world, "top")
	var ground := G.pal(world, "ground")
	var accent := G.pal(world, "accent")
	for v in range(16):
		var ox := v * 16
		var oy := ROW_TOP * 16
		for y in range(16):
			for x in range(16):
				var wx := (v % 4) * 16 + x
				var wy := (v / 4) * 16 + y
				var n := _vnoise(wx, wy, 8, 21) * 0.6 + _hash(wx, wy, 22) * 0.4
				var c := top.lerp(ground, 0.12 + n * 0.22)
				match style:
					"wood", "books", "brass":
						if y % 5 == 4:
							c = c.darkened(0.14)
					"brick":
						if y % 8 == 7 or (wx + (y / 8) * 8) % 16 == 0:
							c = c.darkened(0.18)
					"cloud", "wafer":
						c = top.lerp(ground, n * 0.12)
					"rock":
						if _hash(wx, wy, 23) < 0.06:
							c = Color("5f8f4a")
					"void":
						if _hash(wx, wy, 24) < 0.04:
							c = accent
					"stars", "glass":
						if _hash(wx, wy, 25) < 0.05:
							c = Color.WHITE
				# bordo anteriore più chiaro, fondo più scuro
				if y >= 14:
					c = c.lightened(0.22)
				elif y <= 1:
					c = c.darkened(0.15)
				img.set_pixel(ox + x, oy + y, c)


# ------------------------------------------------------------------ rumore

static func _hash(x: int, y: int, s := 0) -> float:
	var n := (x * 374761393 + y * 668265263 + s * 982451653) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	n = n ^ (n >> 16)
	return float(n & 0xffff) / 65535.0


## Rumore morbido ripetibile su 64 px; cs = lato della cella (divisore di 64).
static func _vnoise(x: int, y: int, cs: int, s := 0) -> float:
	var n := M / cs
	var gx := (x / cs) % n
	var gy := (y / cs) % n
	var fx := float(x % cs) / cs
	var fy := float(y % cs) / cs
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a := _hash(gx, gy, s)
	var b := _hash((gx + 1) % n, gy, s)
	var c := _hash(gx, (gy + 1) % n, s)
	var d := _hash((gx + 1) % n, (gy + 1) % n, s)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


## Sceglie un colore della scala con retinatura ordinata tra un tono e l'altro.
static func _ramp(cols: Array, t: float, x: int, y: int) -> Color:
	var n := cols.size()
	var d: float = (BAYER[(y & 3) * 4 + (x & 3)] / 16.0 - 0.5) * 0.12
	return cols[clampi(int(floor(t * n + d)), 0, n - 1)]


## Celle irregolari (pietre): ritorna [id della cella, distanza dal bordo, dx, dy dal centro].
static func _voronoi(x: int, y: int, pts: Array) -> Array:
	var d1 := 1e9
	var d2 := 1e9
	var id := 0
	var off := Vector2.ZERO
	for i in range(pts.size()):
		var p: Vector2 = pts[i]
		var dx: float = x - p.x
		var dy: float = y - p.y
		dx -= round(dx / M) * M
		dy -= round(dy / M) * M
		var d := sqrt(dx * dx + dy * dy)
		if d < d1:
			d2 = d1
			d1 = d
			id = i
			off = Vector2(dx, dy)
		elif d < d2:
			d2 = d
	return [id, d2 - d1, off.x, off.y]


static func _points(n: int, sd: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	var out: Array = []
	for i in range(n):
		out.append(Vector2(rng.randf_range(0, M), rng.randf_range(0, M)))
	return out


# ------------------------------------------------------------------ materiali

static func material(world: int) -> Image:
	var style: String = G.WORLDS[world - 1]["style"]
	var ground := G.pal(world, "ground")
	var dark := G.pal(world, "dark")
	var top := G.pal(world, "top")
	var accent := G.pal(world, "accent")
	# scala di 5 toni, dal più scuro al più chiaro
	var r: Array = [ground.lerp(dark, 0.6), ground.lerp(dark, 0.3), ground, ground.lerp(top, 0.25), ground.lerp(top, 0.5)]
	var img := Image.create(M, M, false, Image.FORMAT_RGBA8)
	var pts: Array = []
	var books: Array = []
	if style == "rock":
		pts = _points(26, 77)
	elif style == "void":
		pts = _points(14, 99)
	elif style == "books":
		books = _book_rows(ground, dark, top, accent)
	for y in range(M):
		for x in range(M):
			var c: Color = r[2]
			match style:
				"wood":
					var row := y / 8
					var px := (x + row * 20) % 32
					var pid := (x + row * 20) % M / 32
					var tone := _hash(pid, row, 3)
					c = r[2].lerp(r[1] if tone < 0.5 else r[3], absf(tone - 0.5) * 0.9)
					var g := _vnoise(x, (y * 8) % M, 16, 5)
					if g > 0.7:
						c = c.lerp(r[1], 0.55)
					elif g < 0.22:
						c = c.lerp(r[3], 0.5)
					if y % 8 == 0:
						c = r[3]
					elif y % 8 == 7 or px == 0:
						c = r[0]
					elif px == 1:
						c = r[3]
					elif (px == 4 or px == 28) and y % 8 == 3:
						c = r[0]
				"cloud":
					var n := _vnoise(x, y, 16, 1) * 0.6 + _vnoise(x, y, 8, 2) * 0.4
					c = _ramp([ground.lerp(dark, 0.5), ground.lerp(dark, 0.25), ground, ground, top], n, x, y)
				"books":
					c = books[y][x]
				"stars":
					var n := _vnoise(x, y, 16, 1) * 0.55 + _vnoise(x, y, 8, 2) * 0.3 + _hash(x, y, 4) * 0.15
					c = _ramp([r[0], r[1], r[2], r[2], r[3]], n, x, y)
				"brick":
					var row := y / 8
					var bx := (x + (row % 2) * 8) % 16
					var bid := (x + (row % 2) * 8) % M / 16
					var tone := _hash(bid, row, 6)
					c = r[2].lerp(r[1] if tone < 0.5 else r[3], absf(tone - 0.5) * 1.2)
					if tone > 0.9:
						c = r[1].lerp(accent, 0.12)
					if _hash(x, y, 8) < 0.07:
						c = c.lerp(r[0], 0.3)
					if y % 8 == 7 or bx == 15:
						c = r[0]
					elif y % 8 == 0 or bx == 0:
						c = c.lerp(r[4], 0.45)
					elif y % 8 == 6 or bx == 14:
						c = c.lerp(r[0], 0.3)
				"brass":
					var qx := x % 16
					var qy := y % 16
					c = r[2].lerp(r[3], (1.0 - qy / 15.0) * 0.5)
					if _hash(x / 6, y, 9) < 0.3:
						c = c.lerp(r[1], 0.25)
					if qx == 0 or qy == 0:
						c = r[4]
					elif qx == 15 or qy == 15:
						c = r[0]
					elif qx == 14 or qy == 14:
						c = r[1]
					elif (qx == 3 or qx == 11) and (qy == 3 or qy == 11):
						c = top
					elif (qx == 4 or qx == 12) and (qy == 4 or qy == 12):
						c = r[0]
				"wafer":
					var gx := x % 8
					var gy := y % 8
					if gx == 7 or gy == 7:
						c = r[0]
					elif gx == 0 or gy == 0:
						c = r[4]
					elif gx == 6 or gy == 6:
						c = r[1]
					elif _hash(x, y, 2) < 0.12:
						c = r[3]
				"glass":
					var w := (sin((x + y) * TAU / 32.0) + 1.0) * 0.3 + _vnoise(x, y, 8, 3) * 0.4
					c = _ramp([r[1], r[2], r[2], r[3], r[4]], w, x, y)
					if (x + y) % 32 == 0:
						c = top
					elif (x + y) % 32 == 1 or posmod(x - y, M) == 10:
						c = r[4]
				"rock":
					var v: Array = _voronoi(x, y, pts)
					var tone := _hash(v[0], 5, 1)
					c = [r[1], r[2], r[2], r[3]][int(tone * 3.99)]
					if v[1] < 1.3:
						c = r[0]
					elif v[1] < 3.0:
						c = c.lerp(r[4], 0.4) if v[2] + v[3] > 0.0 else c.lerp(r[0], 0.4)
					elif _hash(x, y, 3) < 0.08:
						c = c.lerp(r[0], 0.25)
				"void":
					var v: Array = _voronoi(x, y, pts)
					var n := _vnoise(x, y, 8, 4)
					c = _ramp([dark, dark.lerp(ground, 0.5), ground, ground.lerp(top, 0.18)], n * 0.8 + _hash(v[0], 1, 2) * 0.2, x, y)
					if v[1] < 1.2:
						c = top.darkened(0.25) if _hash(x / 3, y / 3, 5) < 0.75 else accent.darkened(0.1)
					elif v[1] < 2.4:
						c = c.lerp(top, 0.25)
			img.set_pixel(x, y, c)
	if style == "stars":
		_sparkles(img, 26, top, Color.WHITE)
	elif style == "glass":
		_sparkles(img, 9, top, Color.WHITE)
	elif style == "void":
		_sparkles(img, 6, accent.darkened(0.2), accent)
	return img


static func _sparkles(img: Image, n: int, c: Color, bright: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in range(n):
		var x := rng.randi_range(0, M - 1)
		var y := rng.randi_range(0, M - 1)
		if i % 3 == 0:
			for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
				var px: int = posmod(x + d[0], M)
				var py: int = posmod(y + d[1], M)
				img.set_pixel(px, py, img.get_pixel(px, py).lerp(c, 0.6))
			img.set_pixel(x, y, bright)
		else:
			img.set_pixel(x, y, c)


## Scaffali di libri: quattro ripiani da 16 px, con dorsi di larghezza e altezza diverse.
static func _book_rows(ground: Color, dark: Color, top: Color, accent: Color) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 313
	var cols: Array = [ground, accent.darkened(0.2), top.darkened(0.4), ground.lightened(0.15), Color("3b5a7a"), Color("4f6b3a"), Color("6a4a7a")]
	var back := dark.darkened(0.35)
	var out: Array = []
	for y in range(M):
		var row: Array = []
		row.resize(M)
		row.fill(back)
		out.append(row)
	for shelf in range(4):
		var y0 := shelf * 16
		var x := 0
		while x < M:
			var w := mini(rng.randi_range(3, 6), M - x)
			var gap := rng.randi_range(0, 3) if rng.randf() < 0.5 else 0
			var c: Color = cols[rng.randi_range(0, cols.size() - 1)]
			c = c.lerp(ground, 0.45).darkened(0.12)
			var band := rng.randi_range(2, 4)
			for yy in range(gap, 14):
				for xx in range(w):
					var k := c
					if xx == 0:
						k = c.lightened(0.12)
					elif xx == w - 1:
						k = c.darkened(0.35)
					if yy == gap:
						k = k.lightened(0.15)
					elif w > 3 and xx > 0 and xx < w - 1 and (yy == gap + band or yy == 11):
						k = top.lerp(c, 0.55)
					out[y0 + yy][x + xx] = k
			x += w
		for xx in range(M):
			out[y0 + 14][xx] = top.darkened(0.2) if (xx + shelf * 5) % 16 != 0 else top.darkened(0.4)
			out[y0 + 15][xx] = dark.darkened(0.2)
	return out


# ------------------------------------------------------------------ tile solidi

static func _solid(img: Image, ox: int, oy: int, mat: Image, mask: int, v: int, world: int, style: String) -> void:
	var vx := v % 4
	var vy := v / 4
	img.blit_rect(mat, Rect2i(vx * 16, vy * 16, 16, 16), Vector2i(ox, oy))
	if mask == 0:
		return
	var dark := G.pal(world, "dark")
	var out_c := dark.darkened(0.4)
	if mask & 4:
		for x in range(16):
			_mul(img, ox + x, oy + 13, 0.88)
			_mul(img, ox + x, oy + 14, 0.72)
			img.set_pixel(ox + x, oy + 15, out_c)
	if mask & 2:
		for y in range(16):
			_mul(img, ox + 13, oy + y, 0.9)
			_mul(img, ox + 14, oy + y, 0.76)
			img.set_pixel(ox + 15, oy + y, out_c)
	if mask & 8:
		for y in range(16):
			img.set_pixel(ox, oy + y, out_c)
			var p := img.get_pixel(ox + 1, oy + y)
			img.set_pixel(ox + 1, oy + y, p.lightened(0.22))
	if mask & 1:
		_cap(img, ox, oy, vx * 16, world, style, mask)
	# angoli esterni arrotondati
	var clear := Color(0, 0, 0, 0)
	if (mask & 1) and (mask & 8):
		img.set_pixel(ox, oy, clear)
	if (mask & 1) and (mask & 2):
		img.set_pixel(ox + 15, oy, clear)
	if (mask & 4) and (mask & 8):
		img.set_pixel(ox, oy + 15, clear)
		img.set_pixel(ox + 1, oy + 14, out_c)
	if (mask & 4) and (mask & 2):
		img.set_pixel(ox + 15, oy + 15, clear)
		img.set_pixel(ox + 14, oy + 14, out_c)


static func _mul(img: Image, x: int, y: int, k: float) -> void:
	var c := img.get_pixel(x, y)
	img.set_pixel(x, y, Color(c.r * k, c.g * k, c.b * k, c.a))


static func _mix(img: Image, x: int, y: int, c: Color, k: float) -> void:
	img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(c.r, c.g, c.b), k))


## Bordo superiore del terreno: la superficie su cui si cammina, diversa per ogni mondo.
static func _cap(img: Image, ox: int, oy: int, wx0: int, world: int, style: String, mask: int) -> void:
	var top := G.pal(world, "top")
	var accent := G.pal(world, "accent")
	var hi := top.lightened(0.35)
	var lo := top.darkened(0.2)
	var th := 4
	var glow := false
	match style:
		"wood", "books", "brass":
			th = 3
		"stars", "glass":
			th = 2
			glow = true
		"cloud":
			th = 5
			lo = top
		"void":
			th = 3
	for x in range(16):
		var wx := wx0 + x
		var fringe := 0
		match style:
			"cloud":
				fringe = [2, 3, 3, 2, 1, 0, 1, 2][wx % 8]
			"wafer":
				fringe = int(_hash(wx / 2, 1, 11) * 5.0) if _hash(wx / 2, 2, 11) < 0.55 else 0
			"rock":
				fringe = int(_hash(wx, 1, 12) * 2.6)
			"void":
				fringe = int(_hash(wx, 1, 13) * 3.4) if _hash(wx / 2, 3, 13) < 0.6 else 0
		img.set_pixel(ox + x, oy, hi)
		for y in range(1, th + fringe):
			img.set_pixel(ox + x, oy + y, top if y < th - 1 else lo)
		var by := th + fringe
		if glow:
			_mix(img, ox + x, oy + by, top, 0.5)
			_mix(img, ox + x, oy + by + 1, top, 0.28)
			_mix(img, ox + x, oy + by + 2, top, 0.12)
		else:
			_mul(img, ox + x, oy + by, 0.62)
			_mul(img, ox + x, oy + by + 1, 0.82)
		match style:
			"wood":
				if wx % 16 == 15:
					img.set_pixel(ox + x, oy + 1, lo)
			"brick":
				if wx % 8 == 7:
					img.set_pixel(ox + x, oy + 1, lo)
					img.set_pixel(ox + x, oy + 2, lo)
			"brass":
				if wx % 8 == 3:
					img.set_pixel(ox + x, oy + 1, hi)
				elif wx % 8 == 4:
					img.set_pixel(ox + x, oy + 1, lo.darkened(0.25))
			"books":
				if wx % 16 == 9:
					img.set_pixel(ox + x, oy + 1, lo)
			"wafer":
				if _hash(wx, 5, 14) < 0.14:
					img.set_pixel(ox + x, oy + 1, accent if wx % 2 == 0 else Color("ffd65a"))
			"void":
				if _hash(wx, 6, 15) < 0.1:
					img.set_pixel(ox + x, oy + 1, accent)
			"rock":
				if _hash(wx, 7, 16) < 0.2:
					img.set_pixel(ox + x, oy + 1, hi)
	var edge := top.darkened(0.42)
	for y in range(1, th):
		if mask & 8:
			img.set_pixel(ox, oy + y, edge)
		if mask & 2:
			img.set_pixel(ox + 15, oy + y, edge)


static func _crack(img: Image, ox: int, oy: int, c: Color) -> void:
	for p in [[7, 0], [8, 1], [8, 2], [7, 3], [6, 4], [6, 5], [7, 6], [8, 7], [9, 8], [9, 9], [8, 10], [7, 11], [7, 12], [8, 13], [9, 14], [9, 15], [5, 5], [4, 6], [10, 9], [11, 10]]:
		img.set_pixel(ox + p[0], oy + p[1], c)


# ------------------------------------------------------------------ tile speciali

static func _misc(img: Image, world: int) -> void:
	var ground := G.pal(world, "ground")
	var dark := G.pal(world, "dark")
	var top := G.pal(world, "top")
	var accent := G.pal(world, "accent")
	var ink := dark.darkened(0.4)
	var oy := ROW_MISC * 16
	# 0: piattaforma passante
	var ox := 0
	img.fill_rect(Rect2i(ox, oy, 16, 1), top.lightened(0.35))
	img.fill_rect(Rect2i(ox, oy + 1, 16, 2), top)
	img.fill_rect(Rect2i(ox, oy + 3, 16, 1), top.darkened(0.2))
	img.fill_rect(Rect2i(ox, oy + 4, 16, 1), ink)
	for x in [3, 11]:
		img.fill_rect(Rect2i(ox + x, oy + 5, 2, 2), ground.lerp(dark, 0.5))
		img.set_pixel(ox + x, oy + 5, ground)
		img.fill_rect(Rect2i(ox + x, oy + 7, 2, 1), Color(ink.r, ink.g, ink.b, 0.5))
	img.set_pixel(ox + 7, oy + 2, top.darkened(0.2))
	img.set_pixel(ox + 15, oy + 2, top.darkened(0.2))
	# 1 e 2: spine (pavimento e soffitto), forma riconoscibile anche senza colore
	var hs := [2, 4, 6, 8, 9, 7, 5, 3]
	var steel_hi := Color("f4f6fc")
	var steel := Color("c3c9da")
	var steel_lo := Color("8088a2")
	var steel_ink := Color("2a2e44")
	for t in range(2):
		for i in range(8):
			var x := t * 8 + i
			var h: int = hs[i]
			for k in range(h):
				var c := steel
				if i < 3:
					c = steel_hi
				elif i > 4:
					c = steel_lo
				if k == h - 1:
					c = steel_ink
				if k == 0:
					c = steel_lo.darkened(0.25)
				img.set_pixel(16 + x, oy + 15 - k, c)
				img.set_pixel(32 + x, oy + k, c)
		img.set_pixel(16 + t * 8 + 3, oy + 11, accent)
		img.set_pixel(32 + t * 8 + 3, oy + 4, accent)
	# 3: cassa
	ox = 48
	var wood := Color("d19a5c")
	var wood_lo := Color("a8733f")
	var wood_ink := Color("5e3b20")
	img.fill_rect(Rect2i(ox, oy, 16, 16), wood_ink)
	img.fill_rect(Rect2i(ox + 1, oy + 1, 14, 14), wood_lo)
	img.fill_rect(Rect2i(ox + 3, oy + 3, 10, 10), wood)
	for y in [6, 9]:
		img.fill_rect(Rect2i(ox + 3, oy + y, 10, 1), wood_lo)
	for i in range(3, 13):
		img.set_pixel(ox + i, oy + i, wood_ink.lightened(0.15))
		img.set_pixel(ox + 15 - i, oy + i, wood_ink.lightened(0.15))
		if i < 12:
			img.set_pixel(ox + i + 1, oy + i, wood.lightened(0.2))
	img.fill_rect(Rect2i(ox + 1, oy + 1, 14, 1), wood.lightened(0.25))
	img.fill_rect(Rect2i(ox + 1, oy + 1, 1, 14), wood.lightened(0.1))
	img.fill_rect(Rect2i(ox + 2, oy + 14, 13, 1), wood_lo.darkened(0.2))
	for p in [[2, 2], [13, 2], [2, 13], [13, 13]]:
		img.set_pixel(ox + p[0], oy + p[1], wood_ink)
	# 4: morbido / rimbalzante
	ox = 64
	img.fill_rect(Rect2i(ox, oy + 3, 16, 13), accent.darkened(0.4))
	img.fill_rect(Rect2i(ox + 1, oy, 14, 4), accent)
	img.fill_rect(Rect2i(ox, oy + 1, 16, 2), accent)
	img.fill_rect(Rect2i(ox + 1, oy + 3, 14, 1), accent.darkened(0.2))
	img.fill_rect(Rect2i(ox + 2, oy + 1, 6, 1), accent.lightened(0.55))
	img.set_pixel(ox + 9, oy + 1, accent.lightened(0.55))
	for x in range(0, 16, 4):
		img.fill_rect(Rect2i(ox + x + 1, oy + 6, 2, 9), accent.darkened(0.2))
		img.fill_rect(Rect2i(ox + x + 1, oy + 6, 1, 9), accent.darkened(0.05))
	img.fill_rect(Rect2i(ox, oy + 15, 16, 1), accent.darkened(0.6))
	# 6: porta
	ox = 96
	img.fill_rect(Rect2i(ox, oy, 16, 16), dark.darkened(0.25))
	for x in [2, 7, 12]:
		img.fill_rect(Rect2i(ox + x, oy, 2, 16), accent)
		img.fill_rect(Rect2i(ox + x, oy, 1, 16), accent.lightened(0.35))
	img.fill_rect(Rect2i(ox, oy + 7, 16, 2), accent.darkened(0.3))
	img.fill_rect(Rect2i(ox, oy + 7, 16, 1), accent.darkened(0.1))
	# 7: corrente d'aria (freccine tenui)
	ox = 112
	var air := Color(1, 1, 1, 0.22)
	for p in [[4, 5], [3, 6], [5, 6], [11, 11], [10, 12], [12, 12]]:
		img.set_pixel(ox + p[0], oy + p[1], air)
