extends Node2D
## Il portale di luce lasciato da Chiara alla fine del livello.

var t := 0.0


func _ready() -> void:
	var l: Sprite2D = Art.light(Color("fff3b0"), 56.0, 0.55)
	l.position = Vector2(0, -15)
	add_child(l)


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(t * 4.0)
	for i in range(4):
		var w := 13.0 - i * 3.0 + pulse * 1.5
		var h := 30.0 - i * 5.0 + pulse * 2.0
		var c := Color(1.0, 0.95, 0.65, 0.22 + i * 0.2)
		if i == 3:
			c = Color(1, 1, 1, 0.95)
		_ellipse(Vector2(0, -15), w * 0.5, h * 0.5, c)
	for i in range(5):
		var a := t * 1.7 + i * TAU / 5.0
		draw_rect(Rect2((Vector2(cos(a) * 11.0, -15.0 + sin(a) * 17.0)).round(), Vector2(2, 2)), Color(1, 1, 0.8, 0.9))


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(18):
		var a := i * TAU / 18.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)
