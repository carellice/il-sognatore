extends Button
## Pulsante dei menu con un po' di vita: si ingrandisce appena quando è selezionato,
## si schiaccia quando lo premi, e una stellina indica quello attivo.

var k := 1.0
var hot := false
var down := false
var t := 0.0


func _ready() -> void:
	resized.connect(func(): pivot_offset = size * 0.5)
	pivot_offset = size * 0.5
	focus_entered.connect(func(): hot = true)
	focus_exited.connect(func(): hot = false)
	mouse_entered.connect(func(): if not disabled: grab_focus())
	button_down.connect(func(): down = true)
	button_up.connect(func(): down = false)


func _process(dt: float) -> void:
	t += dt
	var target := 0.95 if down else (1.06 if hot and not disabled else 1.0)
	k = lerpf(k, target, 1.0 - exp(-dt * 18.0))
	scale = Vector2(k, k)
	if hot:
		queue_redraw()


func _draw() -> void:
	if not hot or disabled:
		return
	# stellina che pulsa a sinistra del pulsante selezionato
	var c := Vector2(-7.0 + sin(t * 5.0) * 1.5, size.y * 0.5).round()
	var col := Color("ffe27a")
	draw_rect(Rect2(c + Vector2(-1, -1), Vector2(3, 3)), col)
	draw_rect(Rect2(c + Vector2(-3, 0), Vector2(7, 1)), Color(col, 0.8))
	draw_rect(Rect2(c + Vector2(0, -3), Vector2(1, 7)), Color(col, 0.8))
	draw_rect(Rect2(c, Vector2(1, 1)), Color.WHITE)
