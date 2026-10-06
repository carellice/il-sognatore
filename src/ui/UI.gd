extends RefCounted
## Piccoli aiuti per costruire i menu dal codice.


const Heading = preload("res://src/ui/Heading.gd")
const FancyButton = preload("res://src/ui/FancyButton.gd")


static func label(text: String, big := false, col = null) -> Control:
	if big:
		var hd := Heading.new()
		if col != null:
			hd.color = col
		hd.text = text
		return hd
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if col != null:
		l.add_theme_color_override("font_color", col)
	return l


## Mette un testo su una targhetta scura semitrasparente, leggibile su ogni sfondo.
static func plate(l: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb: StyleBoxFlat = Art.hud_box().duplicate()
	sb.bg_color = Color(0.04, 0.05, 0.13, 0.82)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 3
	sb.content_margin_bottom = 2
	pc.add_theme_stylebox_override("panel", sb)
	pc.add_child(l)
	cc.add_child(pc)
	return cc


## Pulsante dei menu: alto 26 px di gioco (34 se "big", con il testo grande).
static func button(text: String, cb: Callable, min_w := 130, big := false) -> Button:
	var b: Button = FancyButton.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w + (40 if big else 16), 31 if big else 26)
	if big:
		b.add_theme_font_override("font", Art.font_big)
		b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(func():
		Snd.play("select")
		cb.call())
	return b


## Pannello centrato con una colonna di elementi. Ritorna [radice, colonna].
static func panel(parent: Node, items: Array, dim := 0.0) -> Array:
	var root := Control.new()
	G.full(root)
	if dim > 0.0:
		var bg := ColorRect.new()
		bg.color = Color(0.02, 0.02, 0.06, dim)
		G.full(bg)
		root.add_child(bg)
	var cc := CenterContainer.new()
	G.full(cc)
	root.add_child(cc)
	var pc := PanelContainer.new()
	cc.add_child(pc)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 6)
	pc.add_child(vb)
	for it in items:
		vb.add_child(it)
	parent.add_child(root)
	focus_first(vb)
	return [root, vb]


static func focus_first(n: Node) -> void:
	for c in n.get_children():
		if c is Button and not c.disabled:
			c.grab_focus.call_deferred()
			return
		if c.get_child_count() > 0:
			focus_first(c)
