extends "res://src/game/bosses/BossBase.gd"
## Il Leviatano di Stelle: serpente cosmico che nuota attorno all'arena;
## con la bolla si fluttua fino alla gemma sulla sua schiena.

const N := 12
const GEM := 5


func _reset() -> void:
	st = 2.5
	pos = _seg(0)


func _seg(i: int) -> Vector2:
	var a := t * 0.9 * rate() - i * 0.24
	return Vector2(arena.x * 0.5 + cos(a) * 160.0, 96.0 + sin(a) * 44.0 + sin(a * 2.0) * 10.0)


func _tick(_dt: float) -> void:
	pos = _seg(0)
	for i in range(N):
		var p := _seg(i)
		var r := Rect2(p - Vector2(8, 8), Vector2(16, 16))
		if i == GEM:
			stomp(r.grow(3.0))
		else:
			touch(r.grow(-3.0))
	if st <= 0.0:
		st = 2.6 / rate()
		game.shoot(pos, Vector2(0, 110), 0.0, "shot_ray")
		Snd.play("shoot")


func _draw() -> void:
	for i in range(N - 1, -1, -1):
		var p := _seg(i) - pos
		var rad := 10.0 if i == 0 else 8.0 - i * 0.25
		draw_circle(p, rad, Color("24348f"))
		draw_circle(p - Vector2(0, 1), rad - 2.0, Color("3f6fd6"))
		draw_rect(Rect2(p + Vector2(-2, -2), Vector2(1, 1)), Color.WHITE)
		if i == GEM:
			var c := Color("ffe27a") if int(t * 6.0) % 2 == 0 else Color.WHITE
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -15), p + Vector2(6, -8), p + Vector2(0, -2), p + Vector2(-6, -8)]), c)
		if i == 0:
			draw_rect(Rect2(p + Vector2(-5, -4), Vector2(4, 4)), Color.WHITE)
			draw_rect(Rect2(p + Vector2(2, -4), Vector2(4, 4)), Color.WHITE)
			draw_rect(Rect2(p + Vector2(-4, -2), Vector2(2, 2)), Color("1a1423"))
			draw_rect(Rect2(p + Vector2(3, -2), Vector2(2, 2)), Color("1a1423"))
