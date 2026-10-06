extends Control
## Griglia del bestiario: un mondo per riga, i nemici non ancora incontrati restano in ombra.

const EnemyDefs = preload("res://src/game/EnemyDefs.gd")

var t := 0.0


func _process(dt: float) -> void:
	t += dt
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.06, 0.14, 0.9))
	var all_open: bool = Save.settings["mod_unlock"]
	var seen: Array = Save.gallery["bestiary"]
	if all_open:
		seen = EnemyDefs.DEFS.keys()
	var shown := int(t * 0.5) % 3
	for w in range(10):
		var col := w % 5
		var row := w / 5
		var x := 8.0 + col * 83.0
		var y := 6.0 + row * 94.0
		draw_string(Art.font, Vector2(x, y + 9), "%d. %s" % [w + 1, T.t("world_%d" % (w + 1))], HORIZONTAL_ALIGNMENT_LEFT, 80, 10, G.pal(w + 1, "top").lightened(0.3))
		var kinds: Array = G.WORLDS[w]["enemies"]
		for i in range(3):
			var kind: String = kinds[i]
			var p := Vector2(x + i * 26.0, y + 16.0)
			draw_rect(Rect2(p, Vector2(24, 26)), Color(1, 1, 1, 0.07))
			if kind in seen and Art.Sprites.SPR.has(kind):
				var tex := Art.tex(kind)
				draw_texture(tex, (p + Vector2(12, 13) - tex.get_size() * 0.5).round())
			elif kind in seen:
				draw_string(Art.font, p + Vector2(8, 17), "~", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
			else:
				draw_string(Art.font, p + Vector2(9, 17), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.35))
		var k: String = kinds[shown]
		draw_string(Art.font, Vector2(x, y + 54), T.t("en_" + k) if k in seen else "???", HORIZONTAL_ALIGNMENT_LEFT, 80, 10, Color("c9d6ff"))
		if all_open or ("boss_%d" % (w + 1)) in Save.gallery["bosses"]:
			draw_string(Art.font, Vector2(x, y + 66), T.t("boss_%d" % (w + 1)), HORIZONTAL_ALIGNMENT_LEFT, 80, 10, Color("ffd65a"))
