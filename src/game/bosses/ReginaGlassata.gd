extends "res://src/game/bosses/BossBase.gd"
## La Regina Glassata, una torta a piani: con lo schianto sulle superfici morbide
## si rimbalza fino in cima e si rompe un piano alla volta.

const TIER_H := 34.0
const WIDTHS := [84.0, 64.0, 44.0]


func _reset() -> void:
	st = 2.0
	pos = Vector2(home.x, _top_y() + 8.0)


func _tiers() -> int:
	return PHASES - phase


func _top_y() -> float:
	return home.y - _tiers() * TIER_H - 16.0


func _on_phase() -> void:
	for i in range(3):
		game.fx.burst(Vector2(home.x + randf_range(-30, 30), _top_y() + 30.0), Color("fff5f0"), 12, 120.0)
	Snd.play("break")


func _tick(_dt: float) -> void:
	var p = game.player
	var pb = p.b
	var top := _top_y()
	pos = Vector2(home.x, top + 8.0)
	var head := Rect2(home.x - 16.0, top - 2.0, 32.0, 14.0)
	if pb.rect().intersects(head) and pb.vy > 0.0 and not p.dead:
		if pb.slamming and invuln <= 0.0:
			hit()
		p.bounce_off(true)
	else:
		for i in range(_tiers()):
			var w: float = WIDTHS[i]
			touch(Rect2(home.x - w * 0.5 + 2.0, home.y - (i + 1) * TIER_H + 3.0, w - 4.0, TIER_H - 3.0))
	if st <= 0.0:
		st = 1.6 / rate()
		var vx := clampf((pb.x - home.x) / 1.3, -150.0, 150.0)
		game.shoot(Vector2(home.x, top), Vector2(vx, -200.0), 380.0, "shot_candy")
		Snd.play("shoot")


func _draw() -> void:
	var base := home.y - pos.y
	var cols := [Color("e58fb1"), Color("f7c8a0"), Color("c9a8ff")]
	for i in range(_tiers()):
		var w: float = WIDTHS[i]
		var y := base - (i + 1) * TIER_H
		draw_rect(Rect2(-w * 0.5, y, w, TIER_H), cols[i])
		draw_rect(Rect2(-w * 0.5, y, w, 7), Color("fff5f0"))
		var x := -w * 0.5 + 4.0
		while x < w * 0.5 - 4.0:
			draw_rect(Rect2(x, y + 7, 4, 4 + int(x) % 5), Color("fff5f0"))
			x += 10.0
		draw_rect(Rect2(-w * 0.5, y + TIER_H - 3, w, 3), cols[i].darkened(0.25))
	var ty := base - _tiers() * TIER_H
	draw_rect(Rect2(-14, ty - 14, 28, 14), Color("fff5f0"))
	draw_rect(Rect2(-9, ty - 9, 4, 4), Color("1a1423"))
	draw_rect(Rect2(5, ty - 9, 4, 4), Color("1a1423"))
	draw_rect(Rect2(-4, ty - 4, 8, 2), Color("c0407a"))
	draw_colored_polygon(PackedVector2Array([Vector2(-10, ty - 14), Vector2(-10, ty - 22), Vector2(-5, ty - 17), Vector2(0, ty - 24), Vector2(5, ty - 17), Vector2(10, ty - 22), Vector2(10, ty - 14)]), Color("ffd65a"))
	draw_circle(Vector2(0, ty - 26), 3.0, Color("d9534f"))
