extends Node2D
## Sfondo a parallasse: cielo, bagliore, due strati che scorrono più lenti della
## telecamera e un pulviscolo animato diverso per ogni mondo.

# pulviscolo: [quanti, colori, velocità x, velocità y, deriva, grandezza max, scia]
const AMBIENT := {
	1: [26, ["fff3b0", "ffffff"], 3.0, -4.0, 6.0, 2, 0.0],
	2: [22, ["ffffff"], 8.0, 1.0, 4.0, 2, 0.0],
	3: [30, ["e8c890", "c9a36b"], 2.0, 3.0, 5.0, 1, 0.0],
	4: [34, ["ffffff", "7fd4ff", "ffe27a"], 0.0, -7.0, 3.0, 2, 0.0],
	5: [22, ["ffd166", "ff9a6a"], 4.0, -9.0, 8.0, 1, 0.0],
	6: [24, ["ffd65a", "e6c15a"], -3.0, 10.0, 10.0, 1, 0.0],
	7: [30, ["ffffff", "7ad6c8", "ffd65a", "f08fc0"], 2.0, 12.0, 8.0, 2, 0.0],
	8: [20, ["d6ecff", "c08cff"], 0.0, -2.0, 3.0, 2, 0.0],
	9: [70, ["9fb2d6"], -70.0, 230.0, 0.0, 1, 0.03],
	10: [34, ["7b3fa0", "ff3b6b"], 2.0, -14.0, 9.0, 2, 0.0],
}
const GLOW := {
	1: ["ffe9b0", 0.14], 2: ["fff6c9", 0.2], 3: ["ffb060", 0.20], 4: ["6f8cff", 0.28], 5: ["ffb070", 0.24],
	6: ["ffc85a", 0.22], 7: ["fff0c9", 0.14], 8: ["a8c8ff", 0.22], 9: ["8fa0c0", 0.14], 10: ["a0206a", 0.26],
}

var layers: Array = []
var cam_x := 0.0
var cam_y := 0.0
var tint := Color.WHITE
var world := 1
var t := 0.0
var motes: Array = []
var glow: Sprite2D
var only_fx := false  # versione 3D: cielo e strati li disegna il 3D


func setup(w: int) -> void:
	world = w
	layers = Art.bg(w)
	if G.main != null:
		var lum: float = (G.pal(w, "sky1").get_luminance() + G.pal(w, "sky2").get_luminance()) * 0.5
		G.main.set_bloom(clampf(1.25 - 1.6 * lum, 0.08, 1.0))
	var a: Array = AMBIENT[w]
	var rng := RandomNumberGenerator.new()
	rng.seed = 500 + w
	# setup può essere richiamato per cambiare mondo (mappa, scene): si riparte da zero
	motes.clear()
	for i in range(a[0]):
		motes.append({
			"p": Vector2(rng.randf() * 600.0, rng.randf() * 320.0),
			"c": Color(a[1][rng.randi_range(0, a[1].size() - 1)]),
			"k": rng.randf_range(0.5, 1.0), "ph": rng.randf() * TAU,
			"s": rng.randi_range(1, a[5]), "z": rng.randf_range(0.25, 0.7),
		})
	if glow == null:
		glow = Sprite2D.new()
		glow.texture = Art.glow()
		glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = mat
		add_child(glow)
	glow.modulate = Color(GLOW[w][0], GLOW[w][1])


func _process(dt: float) -> void:
	t += dt
	var a: Array = AMBIENT[world]
	for m in motes:
		m["p"] += Vector2(a[2] + sin(t * 0.7 + m["ph"]) * a[4], a[3] + cos(t * 0.9 + m["ph"]) * a[4] * 0.5) * dt * m["k"]
	queue_redraw()


func _draw() -> void:
	if layers.is_empty():
		return
	var vs := get_viewport_rect().size
	if only_fx:
		glow.visible = false
		_draw_motes(vs)
		return
	draw_texture_rect(layers[0], Rect2(Vector2.ZERO, vs), false, tint)
	glow.position = Vector2(vs.x * 0.62, vs.y * 0.18)
	glow.scale = Vector2(vs.x / 64.0 * 1.5, vs.y / 64.0 * 1.6)
	glow.modulate.a = GLOW[world][1] * (0.92 + 0.08 * sin(t * 0.8)) * tint.get_luminance()
	var factors := [0.12, 0.35]
	for i in range(2):
		var tx: Texture2D = layers[i + 1]
		var w := tx.get_width()
		var off: float = -fposmod(cam_x * factors[i], float(w))
		var y: float = vs.y - tx.get_height() - cam_y * factors[i] * 0.3
		var x := off
		while x < vs.x:
			draw_texture(tx, Vector2(round(x), round(y)), tint)
			x += w
	_draw_motes(vs)


func _draw_motes(vs: Vector2) -> void:
	var streak: float = AMBIENT[world][6]
	var vel := Vector2(AMBIENT[world][2], AMBIENT[world][3])
	var area := Vector2(vs.x + 16.0, vs.y + 16.0)
	for m in motes:
		var p: Vector2 = m["p"] - Vector2(cam_x, cam_y) * m["z"]
		p = Vector2(fposmod(p.x, area.x) - 8.0, fposmod(p.y, area.y) - 8.0).round()
		var c: Color = m["c"] * tint
		if streak > 0.0:
			c.a = 0.35 * m["k"]
			draw_line(p, p - vel * streak * m["k"], c, 1.0)
		else:
			c.a = (0.25 + 0.55 * (0.5 + 0.5 * sin(t * 2.0 * m["k"] + m["ph"]))) * m["z"] * 1.3
			var s: int = m["s"]
			draw_rect(Rect2(p, Vector2(s, s)), c)
			if s > 1 and c.a > 0.55:
				draw_rect(Rect2(p + Vector2(-1, 0), Vector2(s + 2, s)), Color(c.r, c.g, c.b, c.a * 0.3))
				draw_rect(Rect2(p + Vector2(0, -1), Vector2(s, s + 2)), Color(c.r, c.g, c.b, c.a * 0.3))
