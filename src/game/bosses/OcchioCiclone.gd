extends "res://src/game/bosses/BossBase.gd"
## L'Occhio del Ciclone: arena verticale piena di correnti; planando tra i venti
## si colpiscono i 3 nuclei della tempesta (uno per fase).

const CORES := [Vector2(240, 430), Vector2(120, 300), Vector2(330, 110)]

var strike_x := 0.0
var bolt := ""
var bt := 0.0


func _reset() -> void:
	st = 3.0
	bolt = ""
	pos = _core()


func _core() -> Vector2:
	var c: Vector2 = CORES[mini(phase, 2)]
	return c + Vector2(sin(t * 0.9) * 26.0, sin(t * 1.7) * 6.0)


func _tick(dt: float) -> void:
	var pb = game.player.b
	pos = _core()
	stomp(Rect2(pos.x - 12.0, pos.y - 13.0, 24.0, 16.0))
	# il vento spinge di lato chi è in aria
	if not pb.on_ground:
		pb.push_x += (1.0 if sin(t * 0.5) > 0.0 else -1.0) * 38.0
	bt -= dt
	if bolt == "" and st <= 0.0:
		bolt = "warn"
		bt = 0.8
		strike_x = pb.x
		Snd.play("warn")
	elif bolt == "warn" and bt <= 0.0:
		bolt = "zap"
		bt = 0.25
		Snd.play("slam")
		game.flash(Color(1, 1, 0.7, 0.3))
	elif bolt == "zap":
		if absf(pb.x - strike_x) < 9.0:
			game.player.hurt(1, strike_x)
		if bt <= 0.0:
			bolt = ""
			st = 2.6 / rate()


func _draw() -> void:
	for i in range(3):
		var a := t * (2.0 + i) + i * 2.0
		draw_arc(Vector2.ZERO, 16.0 + i * 5.0, a, a + 4.2, 14, Color(0.8, 0.85, 1.0, 0.7 - i * 0.2), 2.0)
	draw_circle(Vector2.ZERO, 11.0, Color("39414f"))
	draw_circle(Vector2.ZERO, 8.0, Color("ffe45e"))
	draw_circle(Vector2(sin(t) * 2.0, 0), 4.0, Color("1a1423"))
	draw_rect(Rect2(-5, -19, 10, 3), Color("ffe45e") if int(t * 6.0) % 2 == 0 else Color.WHITE)
	# vento
	var dir := 1.0 if sin(t * 0.5) > 0.0 else -1.0
	var cam := Vector2(game.cam_x, game.cam_y) - pos
	for i in range(6):
		var y := cam.y - 120.0 + i * 44.0
		var x := cam.x + fposmod(dir * t * 160.0 + i * 97.0, 520.0) - 260.0
		draw_rect(Rect2(x, y, 16, 1), Color(1, 1, 1, 0.3))
	var lx := strike_x - pos.x
	var top := cam.y - 150.0
	if bolt == "warn" and int(bt * 16.0) % 2 == 0:
		draw_line(Vector2(lx, top), Vector2(lx, top + 300.0), Color(1, 0.9, 0.3, 0.5), 1.0)
	elif bolt == "zap":
		var y := top
		var x := lx
		while y < top + 300.0:
			var nx := lx + randf_range(-5.0, 5.0)
			draw_line(Vector2(x, y), Vector2(nx, y + 14.0), Color("ffe45e"), 3.0)
			x = nx
			y += 14.0
