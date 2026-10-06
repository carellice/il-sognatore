extends Control
## Scritta grande da titolo (lettere levigate, sfumatura, contorno e ombra).
## Si usa come una Label: basta impostare `text`.

var text := "":
	set(v):
		text = v
		_rebuild()
var color := Color("f2f4ff")
var scale_k := 2
var logo := false
var tex: Texture2D
var t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rebuild()


func _rebuild() -> void:
	tex = Art.logo_tex(text) if logo else Art.heading_tex(text, scale_k, color)
	custom_minimum_size = tex.get_size()
	queue_redraw()


func _process(dt: float) -> void:
	if logo:
		t += dt
		queue_redraw()


func _draw() -> void:
	if tex == null:
		return
	var p := ((size - tex.get_size()) * 0.5).round()
	if not logo:
		draw_texture(tex, p)
		return
	p.y += round(sin(t * 1.6) * 2.0)
	draw_texture(tex, p)
	# riflesso che attraversa il titolo e qualche scintilla
	var w := tex.get_width()
	var sweep := fposmod(t * 90.0, w + 260.0) - 30.0
	if sweep < w:
		for i in range(3):
			var sx := sweep - i * 5.0
			if sx >= 0.0 and sx < w - 3:
				draw_texture_rect_region(tex, Rect2(p + Vector2(sx, 0), Vector2(3, tex.get_height() - 4)), Rect2(sx, 0, 3, tex.get_height() - 4), Color(1, 1, 1, 0.55 - i * 0.15))
	for i in range(5):
		var ph := t * 1.3 + i * 1.7
		var k := maxf(0.0, sin(ph))
		if k > 0.75:
			var sp := p + Vector2(fposmod(i * 97.0 + floor(ph / TAU) * 53.0, float(w)), 6 + (i * 13) % 26)
			draw_rect(Rect2(sp + Vector2(-2, 0), Vector2(5, 1)), Color(1, 1, 1, 0.9))
			draw_rect(Rect2(sp + Vector2(0, -2), Vector2(1, 5)), Color(1, 1, 1, 0.9))
