extends RefCounted
## Sfondi a parallasse generati dal codice: cielo sfumato + due strati ripetibili.

const W := 320
const H := 300


static func layers(world: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9000 + world
	var far := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var mid := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var cf := G.pal(world, "far")
	var cm := G.pal(world, "mid")
	var acc := G.pal(world, "accent")
	var top := G.pal(world, "top")
	match world:
		1:
			for x in range(0, W, 20):
				_rect(far, x, 0, 2, H, cf)
			for i in range(26):
				_star(far, rng.randi_range(0, W), rng.randi_range(0, 150), cf.lightened(0.15))
			_rect(far, 60, 44, 70, 64, top)
			_rect(far, 64, 48, 62, 56, Color("2a3a7a"))
			_rect(far, 94, 48, 2, 56, top)
			_rect(far, 64, 75, 62, 2, top)
			_disc(far, 112, 60, 6, Color("fff3b0"))
			_rect(far, 0, 168, W, 4, cm)
			for i in range(9):
				var bx := rng.randi_range(0, W - 20)
				var bh := rng.randi_range(10, 26)
				_rect(far, bx, 168 - bh, rng.randi_range(8, 18), bh, cm.lerp(acc, rng.randf() * 0.4))
			var toy := cm.darkened(0.1)
			var x := 6
			while x < W - 30:
				var kind := rng.randi_range(0, 3)
				match kind:
					0:  # torre di cubi con le lettere
						var n := rng.randi_range(1, 3)
						for j in range(n):
							var by := H - 22 * (j + 1)
							var bx2 := x + rng.randi_range(-2, 2)
							_rect(mid, bx2, by, 22, 22, toy.lerp(acc, 0.12 * j))
							_rect(mid, bx2 + 6, by + 6, 10, 10, toy.darkened(0.18))
							_rect(mid, bx2 + 9, by + 8, 4, 6, toy.lightened(0.12))
						x += 34
					1:  # palla a spicchi
						var r := rng.randi_range(13, 18)
						_disc(mid, x + r, H - r, r, toy.lerp(acc, 0.2))
						_rect(mid, x + 2, H - r - 2, r * 2 - 3, 4, toy.lightened(0.15))
						_disc(mid, x + r - 5, H - r - 6, 3, toy.lightened(0.3))
						x += r * 2 + 12
					2:  # piramide di anelli
						for j in range(4):
							var rw := 30 - j * 6
							_rect(mid, x + j * 3, H - 8 * (j + 1), rw, 7, toy.lerp(acc if j % 2 == 0 else top, 0.22))
						_rect(mid, x + 14, H - 40, 2, 8, toy.darkened(0.2))
						_disc(mid, x + 15, H - 42, 3, toy.lerp(top, 0.3))
						x += 44
					3:  # orsetto
						_disc(mid, x + 14, H - 13, 13, toy)
						_disc(mid, x + 14, H - 32, 9, toy)
						_disc(mid, x + 6, H - 40, 4, toy)
						_disc(mid, x + 22, H - 40, 4, toy)
						_disc(mid, x + 14, H - 30, 4, toy.lightened(0.15))
						_disc(mid, x + 14, H - 12, 7, toy.lightened(0.1))
						x += 42
				x += rng.randi_range(4, 22)
		2:
			_disc(far, 50, 46, 20, Color("fff6c9"))
			for i in range(9):
				_cloud(far, rng.randi_range(0, W), rng.randi_range(30, 190), rng.randi_range(10, 18), Color(1, 1, 1, 0.55))
			for i in range(7):
				_cloud(mid, i * 48 + rng.randi_range(0, 20), rng.randi_range(230, 280), rng.randi_range(18, 28), Color(1, 1, 1, 0.9))
		3:
			var cols := [Color("7a3b3b"), Color("3b5a7a"), Color("5a7a3b"), Color("7a6a3b"), Color("5a3b6a")]
			for sy in range(20, H, 46):
				_rect(far, 0, sy + 38, W, 4, cf.darkened(0.3))
				var x := 2
				while x < W - 4:
					var bw := rng.randi_range(3, 6)
					var bh := rng.randi_range(22, 36)
					if rng.randf() < 0.85:
						_rect(far, x, sy + 38 - bh, bw, bh, cols[rng.randi_range(0, 4)].darkened(0.35))
					x += bw + 1
			for x in [30, 190]:
				_rect(mid, x, 0, 16, H, cm.darkened(0.25))
				_rect(mid, x - 4, 0, 24, 8, cm.darkened(0.1))
				_rect(mid, x + 3, 0, 2, H, cm.darkened(0.05))
			for i in range(5):
				var bx := rng.randi_range(60, W - 20)
				var by := rng.randi_range(40, 200)
				_rect(mid, bx, by, 12, 8, cols[i].darkened(0.1))
				_rect(mid, bx + 1, by + 1, 10, 1, Color(1, 1, 1, 0.5))
		4:
			for i in range(260):
				var c: Color = [Color.WHITE, Color("ffe27a"), Color("7fd4ff")][rng.randi_range(0, 2)]
				c.a = rng.randf_range(0.3, 1.0)
				far.set_pixel(rng.randi_range(0, W - 1), rng.randi_range(0, H - 1), c)
			for i in range(10):
				_star(far, rng.randi_range(4, W - 4), rng.randi_range(4, 200), Color.WHITE)
			_nebula(far, Color("8a5fd0"), 10, 150, 3)
			_nebula(far, Color("3fa0d6"), 90, 230, 9)
			_disc(far, 240, 70, 17, cm.darkened(0.25))
			_disc(far, 240, 70, 16, cm)
			_disc(far, 235, 65, 10, cm.lightened(0.14))
			_disc(far, 233, 63, 4, cm.lightened(0.3))
			for a2 in range(0, 360, 3):
				var ra := deg_to_rad(a2)
				if sin(ra) > -0.25:
					_px(far, 240 + int(cos(ra) * 27.0), 72 + int(sin(ra) * 6.0), top.darkened(0.15))
			for x in range(W):
				var wy2 := int(236 + sin(x * TAU / 160.0) * 10 + sin(x * TAU / 40.0) * 3)
				_rect(far, x, wy2, 1, H - wy2, cf.darkened(0.15))
				far.set_pixel(x, wy2, top.darkened(0.45))
			for x in range(W):
				var wy := int(250 + sin(x * TAU / 80.0) * 8 + sin(x * TAU / 32.0) * 3)
				_rect(mid, x, wy, 1, H - wy, cm.darkened(0.3))
				mid.set_pixel(x, wy, top.darkened(0.2))
		5:
			var x := 0
			while x < W:
				var bw := rng.randi_range(18, 34)
				var bh := rng.randi_range(60, 150)
				_rect(far, x, 0, bw - 2, bh, cf)
				for wy in range(8, bh - 6, 9):
					for wx in range(x + 3, x + bw - 6, 6):
						if rng.randf() < 0.3:
							_rect(far, wx, wy, 3, 4, acc.darkened(0.15))
				x += bw
			x = 0
			while x < W:
				var bw := rng.randi_range(22, 40)
				var bh := rng.randi_range(40, 100)
				_rect(mid, x, H - bh, bw - 3, bh, cm)
				_rect(mid, x, H - bh, bw - 3, 2, cm.lightened(0.15))
				for wy in range(H - bh + 8, H - 6, 10):
					for wx in range(x + 4, x + bw - 8, 7):
						if rng.randf() < 0.4:
							_rect(mid, wx, wy, 3, 5, acc)
				x += bw
		6:
			for i in range(7):
				_gear(far, rng.randi_range(0, W), rng.randi_range(20, 260), rng.randi_range(18, 46), cf)
			_gear(mid, 70, 250, 54, cm.darkened(0.2))
			_gear(mid, 250, 60, 30, cm.darkened(0.2))
			_ring(mid, 190, 190, 34, cm.darkened(0.1))
			_line(mid, 190, 190, 190, 164, cm.lightened(0.2))
			_line(mid, 190, 190, 208, 196, cm.lightened(0.2))
		7:
			var pastel := [Color("ffd9a8"), Color("c9f0e8"), Color("ffc4e2"), Color("fff0c9")]
			for i in range(5):
				var cx := i * 70 + rng.randi_range(0, 20)
				_disc(far, cx, H + 10, rng.randi_range(60, 90), pastel[i % 4].darkened(0.06))
			for i in range(5):
				var lx := i * 64 + rng.randi_range(8, 30)
				var ly := rng.randi_range(170, 220)
				_rect(mid, lx, ly, 3, H - ly, Color("fff5f0"))
				_disc(mid, lx + 1, ly, 13, cm)
				_ring(mid, lx + 1, ly, 8, Color("fff5f0"))
				_disc(mid, lx + 1, ly, 3, Color("fff5f0"))
		8:
			for i in range(5):
				var mx := i * 64 + rng.randi_range(0, 16)
				var my := rng.randi_range(30, 120)
				var mw := rng.randi_range(26, 40)
				var mh := rng.randi_range(60, 110)
				_rect(far, mx, my, mw, mh, cf.lightened(0.12))
				_rect(far, mx + 2, my + 2, mw - 4, mh - 4, cf.darkened(0.15))
				_line(far, mx + 5, my + mh - 8, mx + mw - 8, my + 6, cf.lightened(0.3))
				_line(far, mx + 9, my + mh - 6, mx + mw - 5, my + 12, cf.lightened(0.2))
			for x in [40, 200]:
				_rect(mid, x, 0, 12, H, cm.darkened(0.2))
				_rect(mid, x + 2, 0, 2, H, cm.lightened(0.1))
			for i in range(6):
				var sx := rng.randi_range(0, W - 10)
				var sy := rng.randi_range(20, 240)
				_tri(mid, sx, sy, sx + 6, sy + 16, sx - 4, sy + 10, Color(0.8, 0.9, 1.0, 0.35))
		9:
			for i in range(14):
				_cloud(far, rng.randi_range(0, W), rng.randi_range(0, 70), rng.randi_range(16, 28), cf.lightened(0.06))
			for i in range(4):
				var mx := i * 90 + rng.randi_range(0, 30)
				_tri(far, mx, H, mx + 50, 190 + rng.randi_range(0, 40), mx + 110, H, cf.darkened(0.2))
			for i in range(70):
				var rx := rng.randi_range(0, W - 1)
				var ry := rng.randi_range(0, H - 12)
				_line(mid, rx, ry, rx - 3, ry + 9, Color(0.75, 0.82, 1.0, 0.22))
			_bolt(mid, 220, 0, acc, rng)
		10:
			var x := 0
			while x < W:
				var bw := rng.randi_range(14, 30)
				_tri(far, x, 0, x + bw / 2, rng.randi_range(30, 110), x + bw, 0, cf)
				_tri(far, x, H, x + bw / 2, H - rng.randi_range(20, 80), x + bw, H, cf)
				x += bw
			for i in range(8):
				var ex := rng.randi_range(10, W - 16)
				var ey := rng.randi_range(40, 220)
				_rect(far, ex, ey, 3, 2, acc.darkened(0.25))
				_rect(far, ex + 6, ey, 3, 2, acc.darkened(0.25))
			for i in range(4):
				var tx := i * 84 + rng.randi_range(0, 30)
				_rect(mid, tx, 150, 6, 150, cm.darkened(0.3))
				_line(mid, tx + 3, 180, tx - 16, 140, cm.darkened(0.3))
				_line(mid, tx + 3, 200, tx + 24, 150, cm.darkened(0.3))
				_line(mid, tx - 16, 140, tx - 22, 120, cm.darkened(0.3))
				_line(mid, tx + 24, 150, tx + 20, 126, cm.darkened(0.3))
	var sky2 := G.pal(world, "sky2")
	_polish(far, sky2, 0.13)
	_polish(mid, sky2, 0.08)
	return [_sky(world), ImageTexture.create_from_image(far), ImageTexture.create_from_image(mid)]


const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


static func _sky(world: int) -> ImageTexture:
	var a := G.pal(world, "sky1")
	var b := G.pal(world, "sky2")
	var img := Image.create(4, H, false, Image.FORMAT_RGBA8)
	var bands := 40.0
	for y in range(H):
		var t := float(y) / (H - 1)
		for x in range(4):
			# retinatura ordinata tra una fascia e l'altra
			var k := floorf(t * bands + BAYER[(y & 3) * 4 + x] / 16.0) / bands
			img.set_pixel(x, y, a.lerp(b, clampf(k, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


## Rifinitura di uno strato: luce sui bordi in alto e a sinistra, ombra in basso e a
## destra, e un velo del colore del cielo per dare profondità.
static func _polish(img: Image, haze: Color, k: float) -> void:
	var src := img.get_data()
	var d := src.duplicate()
	var hz := [haze.r8, haze.g8, haze.b8]
	for y in range(H):
		for x in range(W):
			var i := (y * W + x) * 4
			if src[i + 3] == 0:
				continue
			var f := 1.0
			if y > 0 and src[i - W * 4 + 3] < 100:
				f = 1.2
			elif src[(y * W + (x + W - 1) % W) * 4 + 3] < 100:
				f = 1.1
			elif src[(y * W + (x + 1) % W) * 4 + 3] < 100 or (y < H - 1 and src[i + W * 4 + 3] < 100):
				f = 0.8
			# più scuro verso il basso, più velato verso l'alto
			var kk := k * (1.25 - 0.5 * y / H)
			for c in range(3):
				var v: float = minf(255.0, src[i + c] * f)
				d[i + c] = int(lerpf(v, hz[c], kk))
	img.set_data(W, H, false, Image.FORMAT_RGBA8, d)


static func _hash(x: int, y: int) -> float:
	var n := (x * 374761393 + y * 668265263) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	return float((n ^ (n >> 16)) & 0xffff) / 65535.0


static func _noise(x: float, y: float, period: int) -> float:
	var gx := int(floor(x))
	var gy := int(floor(y))
	var fx := x - gx
	var fy := y - gy
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a := _hash(posmod(gx, period), gy)
	var b := _hash(posmod(gx + 1, period), gy)
	var c := _hash(posmod(gx, period), gy + 1)
	var e := _hash(posmod(gx + 1, period), gy + 1)
	return lerpf(lerpf(a, b, fx), lerpf(c, e, fx), fy)


## Nebulosa a blocchetti retinati (ripetibile in orizzontale).
static func _nebula(img: Image, c: Color, y0: int, y1: int, sd: int) -> void:
	for by in range(y0 / 2, y1 / 2):
		for bx in range(W / 2):
			var n := _noise(bx / 20.0 + sd, by / 14.0, 8) * 0.65 + _noise(bx / 8.0 + sd, by / 6.0, 20) * 0.35
			var edge := 1.0 - absf((by * 2.0 - y0) / (y1 - y0) - 0.5) * 2.0
			n = n * (0.55 + 0.45 * edge)
			if n > 0.5:
				var a := 0.12 if n < 0.58 else (0.22 if n < 0.68 else 0.34)
				_rect(img, bx * 2, by * 2, 2, 2, Color(c.r, c.g, c.b, a))


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if y < 0 or y >= H:
		return
	x = posmod(x, W)
	if c.a < 1.0:
		c = img.get_pixel(x, y).blend(c)
	img.set_pixel(x, y, c)


static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(maxi(0, y), mini(H, y + h)):
		for xx in range(x, x + w):
			_px(img, xx, yy, c)


static func _disc(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for yy in range(-r, r + 1):
		for xx in range(-r, r + 1):
			if xx * xx + yy * yy <= r * r:
				_px(img, cx + xx, cy + yy, c)


static func _ring(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for yy in range(-r, r + 1):
		for xx in range(-r, r + 1):
			var d := xx * xx + yy * yy
			if d <= r * r and d >= (r - 2) * (r - 2):
				_px(img, cx + xx, cy + yy, c)


static func _cloud(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	var solid := Color(c.r, c.g, c.b, 1.0)
	var tmp := {}
	for d in [[0, 0, r], [-r, r / 3, r * 2 / 3], [r, r / 3, r * 3 / 4], [-r * 2, r / 2, r / 2], [r * 2, r / 2, r / 2]]:
		var rr: int = d[2]
		for yy in range(-rr, rr + 1):
			for xx in range(-rr, rr + 1):
				if xx * xx + yy * yy <= rr * rr and yy <= r / 2 - d[1] + 2:
					tmp[Vector2i(cx + d[0] + xx, cy + d[1] + yy)] = true
	for p in tmp:
		_px(img, p.x, p.y, c if c.a < 1.0 else solid)


static func _star(img: Image, x: int, y: int, c: Color) -> void:
	_px(img, x, y, c)
	for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
		_px(img, x + d[0], y + d[1], Color(c.r, c.g, c.b, c.a * 0.5))


static func _line(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var n := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in range(n + 1):
		var t := float(i) / maxf(1.0, n)
		_px(img, int(round(lerpf(x0, x1, t))), int(round(lerpf(y0, y1, t))), c)


static func _tri(img: Image, x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, c: Color) -> void:
	var a := Vector2(x0, y0)
	var b := Vector2(x1, y1)
	var d := Vector2(x2, y2)
	for yy in range(mini(y0, mini(y1, y2)), maxi(y0, maxi(y1, y2)) + 1):
		for xx in range(mini(x0, mini(x1, x2)), maxi(x0, maxi(x1, x2)) + 1):
			if Geometry2D.point_is_inside_triangle(Vector2(xx, yy), a, b, d):
				_px(img, xx, yy, c)


static func _gear(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	_disc(img, cx, cy, r, c)
	for i in range(10):
		var ang := i * TAU / 10.0
		_disc(img, cx + int(cos(ang) * (r + 2)), cy + int(sin(ang) * (r + 2)), maxi(2, r / 6), c)
	for yy in range(-r / 3, r / 3 + 1):
		for xx in range(-r / 3, r / 3 + 1):
			if xx * xx + yy * yy <= (r / 3) * (r / 3):
				var px := posmod(cx + xx, W)
				if cy + yy >= 0 and cy + yy < H:
					img.set_pixel(px, cy + yy, Color(0, 0, 0, 0))


static func _bolt(img: Image, x: int, y: int, c: Color, rng: RandomNumberGenerator) -> void:
	var px := x
	var py := y
	for i in range(9):
		var nx := px + rng.randi_range(-10, 10)
		var ny := py + rng.randi_range(8, 18)
		_line(img, px, py, nx, ny, Color(c.r, c.g, c.b, 0.5))
		px = nx
		py = ny
