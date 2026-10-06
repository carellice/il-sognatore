extends Node2D
## Particelle semplici (polvere, scintille, sbuffi, anelli) disegnate a mano.

var parts: Array = []
var rings: Array = []
var puffs: Array = []


func burst(pos: Vector2, col: Color, n: int, speed: float, grav := 200.0) -> void:
	for i in range(n):
		var a := randf() * TAU
		var l := randf_range(0.25, 0.6)
		parts.append({"p": pos, "v": Vector2(cos(a), sin(a)) * speed * randf_range(0.4, 1.0), "l": l, "l0": l, "c": col, "g": grav})


func ring(pos: Vector2, col: Color) -> void:
	rings.append({"p": pos, "r": 3.0, "l": 0.32, "c": col})


func spark(pos: Vector2, col: Color) -> void:
	var l := randf_range(0.4, 0.8)
	parts.append({"p": pos, "v": Vector2(randf_range(-8, 8), randf_range(-26, -8)), "l": l, "l0": l, "c": col, "g": 0.0})


## Sbuffo di polvere ai piedi (salto, atterraggio, frenata).
func puff(pos: Vector2, n := 3, col := Color(1, 1, 1, 0.55)) -> void:
	for i in range(n):
		var dir := -1.0 if i % 2 == 0 else 1.0
		puffs.append({"p": pos + Vector2(dir * randf_range(1, 4), -1), "v": Vector2(dir * randf_range(10, 28), randf_range(-14, -3)), "l": 0.38, "r": randf_range(1.5, 2.6), "c": col})


func tick(dt: float) -> void:
	for p in parts:
		p["l"] -= dt
		p["v"].y += p["g"] * dt
		p["p"] += p["v"] * dt
	for r in rings:
		r["l"] -= dt
		r["r"] += 62.0 * dt
	for p in puffs:
		p["l"] -= dt
		p["v"] *= 1.0 - 3.0 * dt
		p["p"] += p["v"] * dt
		p["r"] += 5.0 * dt
	parts = parts.filter(func(p): return p["l"] > 0.0)
	rings = rings.filter(func(r): return r["l"] > 0.0)
	puffs = puffs.filter(func(p): return p["l"] > 0.0)
	queue_redraw()


func _draw() -> void:
	for p in puffs:
		var c: Color = p["c"]
		c.a *= clampf(p["l"] * 3.0, 0.0, 1.0)
		draw_circle(p["p"].round(), p["r"], c)
	for p in parts:
		var c: Color = p["c"]
		var k: float = p["l"] / p.get("l0", 0.5)
		c.a *= clampf(k * 2.5, 0.0, 1.0)
		var s := 3.0 if k > 0.7 else (2.0 if k > 0.3 else 1.0)
		var at: Vector2 = p["p"].round()
		draw_rect(Rect2(at, Vector2(s, s)), c)
		if s > 1.0:
			draw_rect(Rect2(at, Vector2(1, 1)), Color(1, 1, 1, c.a * 0.8))
	for r in rings:
		var c: Color = r["c"]
		c.a *= clampf(r["l"] * 4.0, 0.0, 1.0)
		draw_arc(r["p"], r["r"], 0.0, TAU, 20, c, 1.5)
		draw_arc(r["p"], r["r"] * 0.7, 0.0, TAU, 16, Color(c.r, c.g, c.b, c.a * 0.35), 1.0)
