extends RefCounted
## Sprite "in rilievo": da una pixel art piatta ricava un'immagine al doppio della
## risoluzione che sembra un oggetto 3D illuminato.
##
## 1. Ingrandimento 2x con EPX (i contorni a scaletta si arrotondano).
## 2. Mappa di altezza: ogni forma è una cupola, più alta lontano dal bordo; ogni zona
##    di colore (occhi, cintura, maniche...) aggiunge un piccolo rilievo suo.
## 3. Normali dalla mappa di altezza e luce: diffusa da in alto a sinistra, riflesso
##    lucido, luce di contorno fredda dietro a destra, ombra nelle pieghe.
## 4. Contorno sottile, del colore del pezzo accanto ma molto più scuro.

const LIGHT := Vector3(-0.55, -0.65, 0.55)


## Ingrandimento 2x EPX/Scale2x su interi (veloce): ogni pixel diventa 2x2.
static func epx2(src: Image) -> Image:
	if src.get_format() != Image.FORMAT_RGBA8:
		src = src.duplicate()
		src.convert(Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	var a := src.get_data().to_int32_array()
	var o := PackedInt32Array()
	o.resize(w * h * 4)
	var w2 := w * 2
	for y in range(h):
		var row := y * w
		var orow := y * 2 * w2
		for x in range(w):
			var i := row + x
			var p := a[i]
			var ua := a[i - w] if y > 0 else p
			var rb := a[i + 1] if x < w - 1 else p
			var lc := a[i - 1] if x > 0 else p
			var dd := a[i + w] if y < h - 1 else p
			var k := orow + x * 2
			o[k] = ua if (lc == ua and lc != dd and ua != rb) else p
			o[k + 1] = rb if (ua == rb and ua != lc and rb != dd) else p
			o[k + w2] = lc if (dd == lc and dd != rb and lc != ua) else p
			o[k + w2 + 1] = dd if (rb == dd and rb != ua and dd != lc) else p
	return Image.create_from_data(w * 2, h * 2, false, Image.FORMAT_RGBA8, o.to_byte_array())


## Texture in alta definizione che però si disegna con la dimensione originale.
static func hires_tex(img2x: Image, logical: Vector2i) -> ImageTexture:
	var t := ImageTexture.create_from_image(img2x)
	t.set_size_override(logical)
	return t


## Solo levigatura 2x (per sfondi, tileset, icone): nessuna luce.
static func smooth_tex(img: Image) -> ImageTexture:
	return hires_tex(epx2(img), img.get_size())


## Distanza (in pixel) dal più vicino pixel "di confine", con smussatura a 8 vicini.
static func _dist(seed: PackedByteArray, w: int, h: int) -> PackedFloat32Array:
	var d := PackedFloat32Array()
	d.resize(w * h)
	for i in range(w * h):
		d[i] = 0.0 if seed[i] == 1 else 999.0
	const S2 := 1.4142
	for y in range(h):
		for x in range(w):
			var i := y * w + x
			var v := d[i]
			if v == 0.0:
				continue
			if x > 0:
				v = minf(v, d[i - 1] + 1.0)
			if y > 0:
				v = minf(v, d[i - w] + 1.0)
				if x > 0:
					v = minf(v, d[i - w - 1] + S2)
				if x < w - 1:
					v = minf(v, d[i - w + 1] + S2)
			d[i] = v
	for y in range(h - 1, -1, -1):
		for x in range(w - 1, -1, -1):
			var i := y * w + x
			var v := d[i]
			if v == 0.0:
				continue
			if x < w - 1:
				v = minf(v, d[i + 1] + 1.0)
			if y < h - 1:
				v = minf(v, d[i + w] + 1.0)
				if x < w - 1:
					v = minf(v, d[i + w + 1] + S2)
				if x > 0:
					v = minf(v, d[i + w - 1] + S2)
			d[i] = v
	return d


static func _dome(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return sqrt(t * (2.0 - t))


## Rende uno sprite piatto (1x) in rilievo, al doppio della risoluzione.
## outline: aggiunge il contorno sottile. gloss: intensità del riflesso.
static func render(src: Image, outline := true, gloss := 0.5) -> Image:
	var pad := Image.create(src.get_width() + 2, src.get_height() + 2, false, Image.FORMAT_RGBA8)
	var s1: Image = src.duplicate()
	s1.convert(Image.FORMAT_RGBA8)
	pad.blit_rect(s1, Rect2i(Vector2i.ZERO, s1.get_size()), Vector2i(1, 1))
	var img := epx2(pad)
	var w := img.get_width()
	var h := img.get_height()
	var px := img.get_data()
	var n := w * h
	# confini: fuori dalla forma (per la cupola) e cambi di colore (per i rilievi interni)
	var out := PackedByteArray()
	out.resize(n)
	var edge := PackedByteArray()
	edge.resize(n)
	var cols := px.to_int32_array()
	for y in range(h):
		for x in range(w):
			var i := y * w + x
			var solid := px[i * 4 + 3] >= 128
			out[i] = 0 if solid else 1
			if not solid:
				edge[i] = 1
				continue
			var c := cols[i]
			if (x > 0 and cols[i - 1] != c) or (x < w - 1 and cols[i + 1] != c) or (y > 0 and cols[i - w] != c) or (y < h - 1 and cols[i + w] != c):
				edge[i] = 1
	var d_out := _dist(out, w, h)
	var d_reg := _dist(edge, w, h)
	var r1 := clampf(minf(w, h) * 0.22, 3.0, 10.0)
	var hm := PackedFloat32Array()
	hm.resize(n)
	for i in range(n):
		if out[i] == 1:
			hm[i] = 0.0
		else:
			hm[i] = _dome(d_out[i] / r1) * 0.75 + _dome((d_reg[i] + 0.5) / 2.5) * 0.25
	var l := LIGHT.normalized()
	var hv := (l + Vector3(0, 0, 1)).normalized()
	var res := px.duplicate()
	for y in range(h):
		for x in range(w):
			var i := y * w + x
			if out[i] == 1:
				continue
			var hl := hm[i - 1] if x > 0 else 0.0
			var hr := hm[i + 1] if x < w - 1 else 0.0
			var hu := hm[i - w] if y > 0 else 0.0
			var hd := hm[i + w] if y < h - 1 else 0.0
			var nrm := Vector3((hl - hr) * 2.4, (hu - hd) * 2.4, 1.0).normalized()
			var diff := maxf(nrm.dot(l), 0.0)
			var lum := 0.62 + 0.7 * diff
			# ombra nelle pieghe tra zone di colore diverse
			lum *= 1.0 - 0.16 * (1.0 - clampf(d_reg[i] / 1.5, 0.0, 1.0))
			var spec := pow(maxf(nrm.dot(hv), 0.0), 22.0) * gloss
			var rim := pow(1.0 - nrm.z, 2.0) * maxf(nrm.x * 0.7 + nrm.y * 0.7, 0.0) * 0.35
			var k := i * 4
			var r := px[k] / 255.0
			var g := px[k + 1] / 255.0
			var b := px[k + 2] / 255.0
			r = r * lum + spec + rim * 0.55
			g = g * lum + spec + rim * 0.7
			b = b * lum + spec + rim * 1.0
			res[k] = int(clampf(r, 0.0, 1.0) * 255.0)
			res[k + 1] = int(clampf(g, 0.0, 1.0) * 255.0)
			res[k + 2] = int(clampf(b, 0.0, 1.0) * 255.0)
	if outline:
		for y in range(h):
			for x in range(w):
				var i := y * w + x
				if px[i * 4 + 3] > 0:
					continue
				# il contorno prende il colore del pezzo vicino, molto scurito
				var nb := -1
				if x > 0 and out[i - 1] == 0:
					nb = i - 1
				elif x < w - 1 and out[i + 1] == 0:
					nb = i + 1
				elif y > 0 and out[i - w] == 0:
					nb = i - w
				elif y < h - 1 and out[i + w] == 0:
					nb = i + w
				if nb < 0:
					continue
				var k := i * 4
				res[k] = int(px[nb * 4] * 0.22 + 10)
				res[k + 1] = int(px[nb * 4 + 1] * 0.2 + 6)
				res[k + 2] = int(px[nb * 4 + 2] * 0.24 + 16)
				res[k + 3] = 255
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, res)


## Texture pronta: sprite in rilievo che si disegna con la dimensione originale (+1 px
## di bordo per lato, come facevano già i nemici con il contorno).
static func tex3d(src: Image, outline := true, gloss := 0.5) -> ImageTexture:
	var img := render(src, outline, gloss)
	return hires_tex(img, Vector2i(img.get_width() / 2, img.get_height() / 2))
