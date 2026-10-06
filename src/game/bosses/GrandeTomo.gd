extends "res://src/game/bosses/BossBase.gd"
## Il Grande Tomo: spara raffiche di pagine con un varco basso (si passa solo con
## lo scatto); quando è stanco scende e gli si colpisce il segnalibro.

const W := 34.0
const H := 42.0

var volleys := 0
var low_y := 0.0


func _reset() -> void:
	low_y = home.y - H * 0.5
	pos = Vector2(home.x, 84.0)
	state = "hover"
	st = 1.6
	volleys = 2


func _on_hit() -> void:
	state = "rise"


func _tick(dt: float) -> void:
	match state:
		"hover":
			pos.y = lerpf(pos.y, 84.0 + sin(t * 2.0) * 4.0, 0.1)
			if st <= 0.0:
				_volley()
				volleys -= 1
				st = 1.7 / rate()
				if volleys <= 0:
					state = "tired"
					st = 4.2
		"tired":
			if st < 2.8:
				pos.y = move_toward(pos.y, low_y, 140.0 * dt)
			if st <= 0.0:
				state = "rise"
		"rise":
			pos.y = move_toward(pos.y, 84.0, 120.0 * dt)
			if pos.y <= 85.0:
				state = "hover"
				st = 1.0
				volleys = 2 + phase
	var body := Rect2(pos.x - W * 0.5, pos.y - H * 0.5, W, H)
	if state == "tired" and pos.y >= low_y - 1.0:
		if not stomp(Rect2(body.position.x, body.position.y - 3.0, W, 13.0)):
			touch(Rect2(body.position.x, body.position.y + 14.0, W, H - 14.0))
	else:
		touch(body.grow(-2.0))


func _volley() -> void:
	Snd.play("shoot")
	var y := home.y - 20.0
	while y > 28.0:
		game.shoot(Vector2(pos.x - 22.0, y), Vector2(-115.0 * rate(), 0), 0.0, "shot_page", 6.0, true)
		y -= 8.0


func _draw() -> void:
	var o := Vector2(-W * 0.5, -H * 0.5)
	draw_rect(Rect2(o, Vector2(W, H)), Color("8f2d3a"))
	draw_rect(Rect2(o + Vector2(3, 2), Vector2(W - 4, H - 4)), Color("fffbe6"))
	draw_rect(Rect2(o + Vector2(0, 0), Vector2(W - 3, H)), Color("b33a3a"))
	draw_rect(Rect2(o + Vector2(0, 0), Vector2(4, H)), Color("8f2d3a"))
	draw_rect(Rect2(o + Vector2(8, 5), Vector2(18, 3)), Color("ffd65a"))
	var tired := state == "tired"
	for ex in [9, 20]:
		draw_rect(Rect2(o + Vector2(ex, 14), Vector2(6, 2 if tired else 6)), Color.WHITE)
		if not tired:
			draw_rect(Rect2(o + Vector2(ex + 1, 16), Vector2(3, 3)), Color("1a1423"))
	draw_rect(Rect2(o + Vector2(8, 28), Vector2(20, 6)), Color("1a1423"))
	for i in range(5):
		draw_rect(Rect2(o + Vector2(9 + i * 4, 28), Vector2(2, 3)), Color.WHITE)
	# segnalibro: il punto debole
	var c := Color("ffd65a") if tired and int(t * 8.0) % 2 == 0 else Color("3f9a4f")
	draw_rect(Rect2(o + Vector2(13, -7), Vector2(8, 9)), c)
	draw_rect(Rect2(o + Vector2(15, -9), Vector2(4, 2)), c)
