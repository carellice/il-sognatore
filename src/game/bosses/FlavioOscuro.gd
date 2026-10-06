extends "res://src/game/bosses/BossBase.gd"
## Flavio Oscuro, il riflesso adolescente: copia ogni mossa in ritardo; col proprio
## riflesso si premono due interruttori insieme e gli specchi crollano su di lui.

const DELAYS := [56, 44, 34]

var spr: Sprite2D
var frames := {}
var armed := true
var last_call := -9.0
var hh := 11.0
var grace := 0.0


func _reset() -> void:
	if spr == null:
		frames = Art.dark_player_frames(2)
		spr = Sprite2D.new()
		spr.texture = frames["idle"]
		add_child(spr)
	pos = Vector2(home.x, home.y - hh)
	grace = 2.0


func _on_hit() -> void:
	grace = 1.5
	for i in range(5):
		game.fx.burst(pos + Vector2(randf_range(-30, 30), -randf_range(20, 90)), Color("d6ecff"), 8, 120.0)
	Snd.play("break")


func on_switches() -> void:
	last_call = t
	if armed and invuln <= 0.0:
		armed = false
		hit()


func _tick(dt: float) -> void:
	grace -= dt
	if t - last_call > 0.15:
		armed = true
	var e = game.trail_at(DELAYS[mini(phase, 2)])
	if e != null and grace <= 0.0:
		var target := Vector2(e[0], e[1] - hh * e[4])
		pos = pos.lerp(target, 0.5)
		spr.texture = frames.get(e[3], frames["idle"])
		spr.flip_h = e[2] < 0
		touch(Rect2(pos.x - 4.0, pos.y - hh + 2.0, 8.0, hh * 2.0 - 4.0))
	spr.position = Vector2(0, hh - 17.0)
	spr.modulate.a = 0.5 if grace > 0.0 else 1.0


func _draw() -> void:
	draw_rect(Rect2(-3, -hh + 3, 2, 2), Color("ff3b6b"))
