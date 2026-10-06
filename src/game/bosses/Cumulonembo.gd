extends "res://src/game/bosses/BossBase.gd"
## Il Cumulonembo: lancia fulmini; col doppio salto si raggiungono le nuvole alte
## e gli si salta sugli occhi.

const W := 60.0
const H := 26.0

var strike_x := 0.0
var bolt := ""  # "", "warn", "zap"
var bt := 0.0
var off := 0.0


func _reset() -> void:
	pos = Vector2(arena.x * 0.5, 70.0)
	st = 2.0
	bolt = ""
	off = 0.0


func _on_hit() -> void:
	off += 2.4


func _tick(dt: float) -> void:
	var pb = game.player.b
	pos.x = arena.x * 0.5 + sin(t * 0.6 * rate() + off) * 150.0
	pos.y = 70.0 + sin(t * 1.7) * 4.0
	bt -= dt
	if bolt == "" and st <= 0.0:
		bolt = "warn"
		bt = 0.75
		strike_x = pb.x
		Snd.play("warn")
	elif bolt == "warn" and bt <= 0.0:
		bolt = "zap"
		bt = 0.25
		Snd.play("slam")
		game.flash(Color(1, 1, 0.7, 0.3))
	elif bolt == "zap":
		if absf(pb.x - strike_x) < 9.0 and pb.y > pos.y:
			game.player.hurt(1, strike_x)
		if bt <= 0.0:
			bolt = ""
			st = 2.2 / rate()
	stomp(Rect2(pos.x - W * 0.5, pos.y - H * 0.5 - 3.0, W, 13.0))


func _draw() -> void:
	var dark := Color("555a6e")
	var mid := Color("7d8298")
	for d in [[-20, 2, 12], [-6, -4, 15], [10, -3, 14], [22, 3, 11], [0, 5, 13]]:
		draw_circle(Vector2(d[0], d[1]), d[2], dark)
	for d in [[-18, 0, 9], [-6, -6, 11], [10, -5, 10], [20, 1, 8]]:
		draw_circle(Vector2(d[0], d[1]), d[2], mid)
	for sx in [-10, 8]:
		draw_rect(Rect2(sx, -13, 7, 6), Color.WHITE)
		draw_rect(Rect2(sx + 2, -11, 3, 3), Color("1a1423"))
		draw_line(Vector2(sx - 1, -16), Vector2(sx + 8, -14 if sx < 0 else -18), Color("1a1423"), 1.0)
	var lx := strike_x - pos.x
	if bolt == "warn" and int(bt * 16.0) % 2 == 0:
		draw_line(Vector2(lx, 12), Vector2(lx, arena.y - pos.y), Color(1, 0.9, 0.3, 0.5), 1.0)
	elif bolt == "zap":
		var y := 12.0
		var x := lx
		while y < arena.y - pos.y - 40.0:
			var nx := lx + randf_range(-5.0, 5.0)
			draw_line(Vector2(x, y), Vector2(nx, y + 14.0), Color("ffe45e"), 3.0)
			draw_line(Vector2(x, y), Vector2(nx, y + 14.0), Color.WHITE, 1.0)
			x = nx
			y += 14.0
