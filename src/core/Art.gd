extends Node
## Tutta la grafica è generata dal codice all'avvio (pixel art procedurale):
## font bitmap, tema dell'interfaccia, tileset dei 10 mondi, sprite e sfondi.
## Nessun asset esterno: vedi ASSETS.md.

const Sprites = preload("res://src/core/Sprites.gd")
const ArtBG = preload("res://src/core/ArtBG.gd")
const ArtPlayer = preload("res://src/core/ArtPlayer.gd")
const ArtTiles = preload("res://src/core/ArtTiles.gd")
const ArtShade = preload("res://src/core/ArtShade.gd")
const ArtDecor = preload("res://src/core/ArtDecor.gd")
const EnemyDefs = preload("res://src/game/EnemyDefs.gd")

# Font 5x7 classico (colonne, bit 0 in alto), caratteri ASCII 32..126
const FONT_HEX := "000000000000005F00000007000700147F147F14242A7F2A12231308646236495620500008070300001C2241000041221C002A1C7F1C2A08083E080800807030000808080808000060600020100804023E5149453E00427F400072494949462141494D331814127F1027454545393C4A49493141211109073649494936464949291E0000140000004034000000081422411414141414004122140802015909063E415D594E7C1211127C7F494949363E414141227F4141413E7F494949417F090909013E414151737F0808087F00417F41002040413F017F081422417F404040407F021C027F7F0408107F3E4141413E7F090909063E4151215E7F09192946264949493203017F01033F4040403F1F2040201F3F4038403F631408146303047804036159494D43007F4141410204081020004141417F04020102044040404040000307080020545478407F284444383844444428384444287F385454541800087E090218A4A49C787F0804047800447D40002040403D007F1028440000417F40007C047804787C080404783844444438FC1824241818242418FC7C08040408485454542404043F44243C4040207C1C2040201C3C4030403C44281028444C9090907C4464544C440008364100000077000000413608000201020402"

var font: FontFile
var font_big: FontFile
var theme: Theme
var _cache := {}
var _glyphs := {}


func _ready() -> void:
	_make_fonts()
	_make_theme()


# ------------------------------------------------------------------ font

func _base_cols(code: int) -> Array:
	var i := (code - 32) * 10
	var out: Array = []
	for k in range(5):
		out.append(FONT_HEX.substr(i + k * 2, 2).hex_to_int() << 2)
	return out


func _accent(ch: String, acute: bool, upper: bool) -> Array:
	var c: Array
	if ch == "i":
		c = [0, 0x44 << 2, 0x7C << 2, 0x40 << 2, 0]
	else:
		c = _base_cols(ch.unicode_at(0))
	var r := 0 if upper else 1
	c[3 if acute else 1] |= 1 << r
	c[2] |= 1 << (r + 1)
	return c


func _make_fonts() -> void:
	for code in range(32, 127):
		_glyphs[code] = _base_cols(code)
	for ch in "aeou":
		_glyphs[{"a": 0xE0, "e": 0xE8, "o": 0xF2, "u": 0xF9}[ch]] = _accent(ch, false, false)
	_glyphs[0xE9] = _accent("e", true, false)
	_glyphs[0xEC] = _accent("i", false, false)
	for ch in "AEIOU":
		_glyphs[{"A": 0xC0, "E": 0xC8, "I": 0xCC, "O": 0xD2, "U": 0xD9}[ch]] = _accent(ch, false, true)
	_glyphs[0xC9] = _accent("E", true, true)
	_glyphs[0xAB] = [0x20, 0x50, 0x20, 0x50, 0]
	_glyphs[0xBB] = [0x50, 0x20, 0x50, 0x20, 0]
	_glyphs[0x2019] = _glyphs[39]
	_glyphs[0x2013] = _glyphs[45]
	_glyphs[0x2014] = _glyphs[45]
	_glyphs[0x2026] = [0x100, 0, 0x100, 0, 0x100]
	_glyphs[0xD7] = [0x88, 0x50, 0x20, 0x50, 0x88]
	_glyphs[0x20AC] = [0x50, 0xF8, 0x154, 0x104, 0x88]
	_glyphs[0x2665] = [0x30, 0x78, 0xF0, 0x78, 0x30]
	_glyphs[0x2190] = [0x20, 0x70, 0xA8, 0x20, 0x20]
	_glyphs[0x2192] = [0x20, 0x20, 0xA8, 0x70, 0x20]
	_glyphs[0x2191] = [0x10, 0x08, 0x1FC, 0x08, 0x10]
	_glyphs[0x2193] = [0x40, 0x80, 0x1FC, 0x80, 0x40]
	font = _build_font(1)
	font_big = _build_font(2)


func _build_font(scale: int) -> FontFile:
	var codes: Array = _glyphs.keys()
	var cols := 16
	var cell := 8
	var img := Image.create(cols * cell, int(ceil(codes.size() / float(cols))) * 10, false, Image.FORMAT_RGBA8)
	var f := FontFile.new()
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.hinting = TextServer.HINTING_NONE
	f.fixed_size = 10 * scale
	var sz := Vector2i(10 * scale, 0)
	var info: Array = []
	for n in range(codes.size()):
		var code: int = codes[n]
		var g: Array = _glyphs[code]
		var x0 := 0
		var x1 := 4
		if code == 32:
			x1 = 1
		elif code < 48 or code > 57:
			while x0 < 4 and g[x0] == 0:
				x0 += 1
			while x1 > x0 and g[x1] == 0:
				x1 -= 1
		var ox := (n % cols) * cell
		var oy := (n / cols) * 10
		for cx in range(x0, x1 + 1):
			for ry in range(10):
				if g[cx] & (1 << ry):
					img.set_pixel(ox + cx - x0, oy + ry, Color.WHITE)
		info.append([code, ox, oy, x1 - x0 + 1])
	if scale > 1:
		img = _epx(img)
	f.set_texture_image(0, sz, 0, img)
	f.set_cache_ascent(0, sz.x, 9.0 * scale)
	f.set_cache_descent(0, sz.x, 1.0 * scale)
	for e in info:
		var code: int = e[0]
		var w: int = e[3]
		f.set_glyph_advance(0, sz.x, code, Vector2((w + 1) * scale, 0))
		f.set_glyph_offset(0, sz, code, Vector2(0, -9 * scale))
		f.set_glyph_size(0, sz, code, Vector2(w * scale, 10 * scale))
		f.set_glyph_uv_rect(0, sz, code, Rect2(e[1] * scale, e[2] * scale, w * scale, 10 * scale))
		f.set_glyph_texture_idx(0, sz, code, 0)
	return f


## Ingrandimento 2x che smussa le diagonali (EPX / Scale2x): il testo grande non
## risulta "a blocchi" come con un semplice raddoppio dei pixel.
func _epx(src: Image) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var out := Image.create(w * 2, h * 2, false, Image.FORMAT_RGBA8)
	var none := Color(0, 0, 0, 0)
	for y in range(h):
		for x in range(w):
			var p := src.get_pixel(x, y)
			var a := src.get_pixel(x, y - 1) if y > 0 else none
			var b := src.get_pixel(x + 1, y) if x < w - 1 else none
			var c := src.get_pixel(x - 1, y) if x > 0 else none
			var d := src.get_pixel(x, y + 1) if y < h - 1 else none
			out.set_pixel(x * 2, y * 2, a if (c == a and c != d and a != b) else p)
			out.set_pixel(x * 2 + 1, y * 2, b if (a == b and a != c and b != d) else p)
			out.set_pixel(x * 2, y * 2 + 1, c if (d == c and d != b and c != a) else p)
			out.set_pixel(x * 2 + 1, y * 2 + 1, d if (b == d and b != a and d != c) else p)
	return out


## Scritta "da titolo": lettere grandi levigate, riempite con una sfumatura a fasce,
## con filo di luce in alto, contorno scuro e ombra. scale = 1, 2 o 4.
func text_image(text: String, scale: int, top: Color, mid: Color, bottom: Color, ow := 1) -> Image:
	var spans: Array = []
	var total := 0
	for ch in text:
		var code := ch.unicode_at(0)
		var g: Array = _glyphs.get(code, _glyphs[63])
		var x0 := 0
		var x1 := 4
		if code == 32:
			x1 = 1
		elif code < 48 or code > 57:
			while x0 < 4 and g[x0] == 0:
				x0 += 1
			while x1 > x0 and g[x1] == 0:
				x1 -= 1
		spans.append([g, x0, x1, total])
		total += x1 - x0 + 2
	var bmp := Image.create(maxi(1, total), 10, false, Image.FORMAT_RGBA8)
	for s in spans:
		for cx in range(s[1], s[2] + 1):
			for ry in range(10):
				if s[0][cx] & (1 << ry):
					bmp.set_pixel(s[3] + cx - s[1], ry, Color.WHITE)
	var k := 1
	while k < scale:
		bmp = _epx(bmp)
		k *= 2
	var w := bmp.get_width()
	var h := bmp.get_height()
	var pad := ow
	var drop := maxi(1, scale / 2)
	var out := Image.create(w + pad * 2, h + pad * 2 + drop, false, Image.FORMAT_RGBA8)
	var y0 := 2 * scale
	var span := maxf(1.0, 7.0 * scale - 1.0)
	var band := maxi(1, scale / 2)
	for y in range(h):
		var t := clampf(float((y - y0) / band * band) / span, 0.0, 1.0)
		var c := top.lerp(mid, t * 2.0) if t < 0.5 else mid.lerp(bottom, (t - 0.5) * 2.0)
		for x in range(w):
			if bmp.get_pixel(x, y).a < 0.5:
				continue
			var cc := c
			if y == 0 or bmp.get_pixel(x, y - 1).a < 0.5:
				cc = c.lightened(0.45)
			elif y == h - 1 or bmp.get_pixel(x, y + 1).a < 0.5:
				cc = c.darkened(0.22)
			out.set_pixel(x + pad, y + pad, cc)
	var ink := Color("1a1423")
	for i in range(ow):
		var src: Image = out.duplicate()
		for y in range(out.get_height()):
			for x in range(out.get_width()):
				if src.get_pixel(x, y).a > 0.0:
					continue
				var hit := false
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var nx := x + dx
						var ny := y + dy
						if nx >= 0 and ny >= 0 and nx < out.get_width() and ny < out.get_height() and src.get_pixel(nx, ny).a > 0.0:
							hit = true
				if hit:
					out.set_pixel(x, y, ink)
	var src2: Image = out.duplicate()
	for y in range(out.get_height() - 1, drop - 1, -1):
		for x in range(out.get_width()):
			if src2.get_pixel(x, y).a == 0.0 and src2.get_pixel(x, y - drop).a > 0.0:
				out.set_pixel(x, y, Color(0.06, 0.04, 0.12, 0.55))
	return out


func heading_tex(text: String, scale: int, col: Color) -> Texture2D:
	var k := "head:%s:%d:%s" % [text, scale, col.to_html()]
	if not _cache.has(k):
		_cache[k] = ArtShade.smooth_tex(text_image(text, scale, col.lightened(0.55), col, col.darkened(0.3).lerp(Color("c0603a"), 0.25), 1))
	return _cache[k]


## Il titolo del gioco: oro che sfuma nell'arancio, contorno doppio.
func logo_tex(text: String) -> Texture2D:
	var k := "logo:" + text
	if not _cache.has(k):
		_cache[k] = ArtShade.smooth_tex(text_image(text, 4, Color("fffbe0"), Color("ffd65a"), Color("f0803c"), 2))
	return _cache[k]


## Immagine di un riquadro con angoli smussati: contorno, bordo interno, corpo sfumato
## e (per i pulsanti) un labbro scuro in basso che dà spessore.
func _frame(w: int, h: int, outline: Color, border: Color, c_top: Color, c_bot: Color, lip: int, lip_col: Color, gloss := false, corners := Color(0, 0, 0, 0)) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var ex := mini(x, w - 1 - x)
			var ey := mini(y, h - 1 - y)
			var d := mini(ex, ey)
			var s := ex + ey
			if s < 2:
				continue
			var c := c_top.lerp(c_bot, float(y) / (h - 1))
			if d == 0 or s == 2:
				c = outline
			elif d == 1 or s == 3:
				c = border.lightened(0.25) if y < h / 2 else border.darkened(0.2)
				if border.a == 0.0:
					c = border
			elif y >= h - 2 - lip:
				c = lip_col
			elif y == 2:
				c = c.lightened(0.28 if gloss else 0.16)
			elif gloss and y < h * 0.48:
				# riflesso lucido sulla metà superiore
				c = c.lightened(0.1)
			elif gloss and y < h * 0.48 + 1.0:
				c = c.darkened(0.04)
			img.set_pixel(x, y, c)
	if corners.a > 0.0:
		# piccole squadrette dorate negli angoli (restano fisse nel 9-slice)
		for p in [[2, 2], [3, 2], [4, 2], [2, 3], [2, 4]]:
			for q in [[p[0], p[1]], [w - 1 - p[0], p[1]], [p[0], h - 1 - p[1]], [w - 1 - p[0], h - 1 - p[1]]]:
				img.set_pixel(q[0], q[1], corners)
		for q in [[3, 3], [w - 4, 3], [3, h - 4], [w - 4, h - 4]]:
			img.set_pixel(q[0], q[1], corners.lightened(0.4))
	return ImageTexture.create_from_image(img)


func _tbox(tex: Texture2D, top := 4, bottom := 4) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex
	s.set_texture_margin_all(5)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = top
	s.content_margin_bottom = bottom
	return s


## Riquadro scuro semitrasparente per gli elementi dell'HUD.
func hud_box(border := Color(1, 1, 1, 0.2)) -> StyleBoxFlat:
	var k := "hud:" + border.to_html()
	if not _cache.has(k):
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.04, 0.05, 0.13, 0.62)
		s.border_color = border
		s.set_border_width_all(1)
		s.set_corner_radius_all(4)
		s.anti_aliasing = false
		_cache[k] = s
	return _cache[k]


func _box(bg: Color, border: Color, bw := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(2)
	s.border_width_bottom = bw + 1
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 1
	s.shadow_offset = Vector2(0, 2)
	s.anti_aliasing = false
	s.content_margin_left = 7
	s.content_margin_right = 7
	s.content_margin_top = 4
	s.content_margin_bottom = 3
	return s


func _make_theme() -> void:
	theme = Theme.new()
	# le stesse regole vanno anche nel tema predefinito del motore, così valgono
	# ovunque (anche sotto CanvasLayer e nodi che interrompono l'eredità del tema)
	for th in [theme, ThemeDB.get_default_theme()]:
		_fill_theme(th)
	ThemeDB.fallback_font = font
	ThemeDB.fallback_font_size = 10


func _fill_theme(th: Theme) -> void:
	th.default_font = font
	th.default_font_size = 10
	var navy := Color("161a33")
	var line := Color("8fa3d9")
	for cls in ["Button", "Label"]:
		th.set_font("font", cls, font)
		th.set_font_size("font_size", cls, 10)
	var ink := Color("0b0d20")
	th.set_stylebox("normal", "Button", _tbox(_frame(16, 22, ink, Color("8fa3e6"), Color("4356ad"), Color("1f2763"), 2, Color("121845"), true), 3, 5))
	th.set_stylebox("hover", "Button", _tbox(_frame(16, 22, ink, Color("ffd65a"), Color("566fd0"), Color("2a3584"), 2, Color("161d52"), true), 3, 5))
	th.set_stylebox("pressed", "Button", _tbox(_frame(16, 22, ink, Color("ffd65a"), Color("1f2763"), Color("34418f"), 0, Color("222a5c")), 5, 3))
	th.set_stylebox("disabled", "Button", _tbox(_frame(16, 22, Color("0b0d20b0"), Color("3d4466"), Color("1b1e36"), Color("15172b"), 2, Color("101224")), 3, 5))
	var focus := _tbox(_frame(20, 26, Color("ffd65a60"), Color("ffe27a"), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0)))
	focus.set_expand_margin_all(2)
	th.set_stylebox("focus", "Button", focus)
	th.set_color("font_color", "Button", Color("e8ecff"))
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_focus_color", "Button", Color("ffe27a"))
	th.set_color("font_pressed_color", "Button", Color.WHITE)
	th.set_color("font_disabled_color", "Button", Color("5a6288"))
	th.set_color("font_color", "Label", Color("f2f4ff"))
	th.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.7))
	th.set_constant("shadow_offset_x", "Label", 1)
	th.set_constant("shadow_offset_y", "Label", 1)
	th.set_constant("line_spacing", "Label", 2)
	var pan := _tbox(_frame(20, 20, Color("0b0d20"), Color("8fa3d9"), Color(0.12, 0.13, 0.3, 0.96), Color(0.04, 0.05, 0.13, 0.97), 0, Color(0, 0, 0, 0), false, Color("e0b44a")), 9, 8)
	pan.content_margin_left = 10
	pan.content_margin_right = 10
	for cls in ["PanelContainer", "Panel"]:
		th.set_stylebox("panel", cls, pan)
	th.set_constant("outline_size", "Button", 0)
	th.set_constant("separation", "VBoxContainer", 6)
	th.set_constant("separation", "HBoxContainer", 8)
	th.set_constant("h_separation", "GridContainer", 8)
	th.set_constant("v_separation", "GridContainer", 6)


# ------------------------------------------------------------------ sprite

func tex(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var t: Texture2D = null
	if Sprites.SPR.has(key):
		var im := image_from(Sprites.SPR[key])
		if key in FLAT_ICONS or key.begins_with("ic_"):
			# icone dell'interfaccia: solo levigate
			t = ArtShade.smooth_tex(im)
		else:
			# tutto il resto in rilievo, al doppio dei dettagli (+1 px di contorno per lato)
			t = ArtShade.tex3d(im, true, 0.55 if key in ["frag", "frag2", "secret", "life", "heart"] else 0.4)
	else:
		push_warning("Sprite mancante: " + key)
		var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color.MAGENTA)
		t = ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


const FLAT_ICONS := ["pause", "hand", "heart_off"]


func image_from(rows: Array) -> Image:
	var w := 0
	for r in rows:
		w = maxi(w, r.length())
	var img := Image.create(w, rows.size(), false, Image.FORMAT_RGBA8)
	for y in range(rows.size()):
		var row: String = rows[y]
		for x in range(row.length()):
			var ch := row[x]
			if Sprites.PAL.has(ch):
				img.set_pixel(x, y, Sprites.PAL[ch])
	return img


## Versione "ombra" di uno sprite (nemici dell'Incubo, riflessi oscuri).
func shadow_tex(key: String) -> Texture2D:
	var k := "shadow:" + key
	if _cache.has(k):
		return _cache[k]
	var base := tex(key)
	var img: Image = base.get_image()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				var l := c.get_luminance()
				img.set_pixel(x, y, Color(0.12 + l * 0.35, 0.05 + l * 0.12, 0.2 + l * 0.5, 1.0))
	var t := ArtShade.hires_tex(img, Vector2i(base.get_size()))
	_cache[k] = t
	return t


func player_frames(stage: int) -> Dictionary:
	var k := "player:%d" % stage
	if not _cache.has(k):
		var t0 := Time.get_ticks_msec()
		_cache[k] = ArtPlayer.frames(stage, false)
		if "--timing" in OS.get_cmdline_user_args():
			print("Flavio stadio %d: %d ms" % [stage, Time.get_ticks_msec() - t0])
	return _cache[k]


func dark_player_frames(stage: int) -> Dictionary:
	var k := "dplayer:%d" % stage
	if not _cache.has(k):
		_cache[k] = ArtPlayer.frames(stage, true)
	return _cache[k]


## Alone di luce morbido (bianco che sfuma), da usare in modalità additiva.
func glow() -> Texture2D:
	if not _cache.has("glow"):
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.32), Color(1, 1, 1, 0)])
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.width = 64
		gt.height = 64
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		_cache["glow"] = gt
	return _cache["glow"]


## Bordi dello schermo leggermente più scuri, per concentrare lo sguardo al centro.
func vignette() -> Texture2D:
	if not _cache.has("vignette"):
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		g.colors = PackedColorArray([Color(0.02, 0.01, 0.06, 0), Color(0.02, 0.01, 0.06, 0.04), Color(0.02, 0.01, 0.06, 0.42)])
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.width = 96
		gt.height = 54
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.08, 1.08)
		_cache["vignette"] = gt
	return _cache["vignette"]


## Sprite di luce additiva da attaccare a un oggetto luminoso.
func light(col: Color, radius: float, alpha := 0.5) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = glow()
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if not _cache.has("add_mat"):
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_cache["add_mat"] = mat
	s.material = _cache["add_mat"]
	s.modulate = Color(col.r, col.g, col.b, alpha)
	s.scale = Vector2.ONE * (radius / 32.0)
	s.show_behind_parent = true
	return s


func decor(world: int) -> Array:
	var k := "decor:%d" % world
	if not _cache.has(k):
		_cache[k] = ArtDecor.build(world)
	return _cache[k]


func bg(world: int) -> Array:
	var k := "bg:%d" % world
	if not _cache.has(k):
		var t0 := Time.get_ticks_msec()
		var ls: Array = ArtBG.layers(world)
		for i in [1, 2]:
			ls[i] = ArtShade.smooth_tex(ls[i].get_image())
		_cache[k] = ls
		if "--timing" in OS.get_cmdline_user_args():
			print("sfondo mondo %d: %d ms" % [world, Time.get_ticks_msec() - t0])
	return _cache[k]


# ------------------------------------------------------------------ tileset

const AT_ONEWAY := Vector2i(0, 16)
const AT_SPIKE := Vector2i(1, 16)
const AT_SPIKE_D := Vector2i(2, 16)
const AT_CRATE := Vector2i(3, 16)
const AT_BOUNCY := Vector2i(4, 16)
const AT_DOOR := Vector2i(6, 16)
const AT_UPDRAFT := Vector2i(7, 16)


## Variante del motivo per la casella (il materiale si ripete ogni 4 caselle).
func variant(tx: int, ty: int) -> int:
	return (ty & 3) * 4 + (tx & 3)


func at_solid(mask: int, tx: int, ty: int) -> Vector2i:
	return Vector2i(mask, variant(tx, ty))


func at_fake(with_top: bool, tx: int, ty: int) -> Vector2i:
	return Vector2i(variant(tx, ty), ArtTiles.ROW_FAKE_TOP if with_top else ArtTiles.ROW_FAKE)


func tileset(world: int) -> TileSet:
	var k := "ts:%d" % world
	if _cache.has(k):
		return _cache[k]
	var t0 := Time.get_ticks_msec()
	var img: Image = ArtTiles.build(world)
	if "--timing" in OS.get_cmdline_user_args():
		print("tileset mondo %d: %d ms" % [world, Time.get_ticks_msec() - t0])
	# atlante levigato a 32 px per casella: il TileMapLayer si disegna a scala 0.5
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(ArtShade.epx2(img))
	src.texture_region_size = Vector2i(32, 32)
	for y in range(20):
		for x in range(16):
			src.create_tile(Vector2i(x, y))
	ts.add_source(src, 0)
	_cache[k] = ts
	return ts
