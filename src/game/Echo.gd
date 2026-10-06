extends Node2D
## L'eco di Chiara: la scintilla che accompagna Flavio, dà suggerimenti con
## fumetti brevi e brilla vicino ai segreti. Più tenue a ogni mondo.

const ALPHA := [1.0, 0.92, 0.82, 0.72, 0.58, 0.46, 0.36, 0.28, 0.18, 0.12]

var game
var base_alpha := 1.0
var t := 0.0
var spr: Sprite2D
var bubble: PanelContainer
var label: Label
var say_t := 0.0
var glow := 0.0
var halo: Sprite2D


func setup(g, world: int) -> void:
	game = g
	base_alpha = ALPHA[world - 1]
	spr = Sprite2D.new()
	spr.texture = Art.tex("echo")
	add_child(spr)
	halo = Art.light(Color("ffe9a0"), 20.0, 0.4)
	spr.add_child(halo)
	bubble = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fffbe6")
	sb.border_color = Color("1a1423")
	sb.set_border_width_all(1)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 2
	sb.content_margin_bottom = 1
	sb.anti_aliasing = false
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(0, 1)
	bubble.add_theme_stylebox_override("panel", sb)
	label = Label.new()
	label.add_theme_color_override("font_color", Color("1a1423"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	if Save.settings["big_text"]:
		label.add_theme_font_override("font", Art.font_big)
		label.add_theme_font_size_override("font_size", 20)
	bubble.add_child(label)
	bubble.visible = false
	add_child(bubble)
	z_index = 20


func say(text: String, dur := 4.0) -> void:
	label.text = text
	bubble.visible = true
	bubble.reset_size()
	say_t = dur


func tick(dt: float) -> void:
	t += dt
	var p = game.player
	var target := Vector2(p.b.x - p.b.facing * 14.0, p.b.y - p.b.hh - 10.0)
	glow = move_toward(glow, 0.0, dt)
	if game.secret_pos != Vector2.ZERO and not game.secret_found:
		var d: float = game.secret_pos.distance_to(Vector2(p.b.x, p.b.y))
		if d < 120.0:
			target = game.secret_pos.lerp(Vector2(p.b.x, p.b.y - 20.0), 0.55)
			glow = 1.0
	target.y += sin(t * 3.0) * 3.0
	position = position.lerp(target, clampf(dt * 5.0, 0.0, 1.0))
	spr.modulate.a = clampf(base_alpha + glow * 0.6 + (0.5 if say_t > 0.0 else 0.0), 0.0, 1.0) * (0.8 + 0.2 * sin(t * 6.0))
	halo.modulate.a = 0.38 * clampf(base_alpha + glow + 0.25, 0.0, 1.0) * (0.85 + 0.15 * sin(t * 5.0))
	spr.scale = Vector2.ONE * (1.0 + glow * 0.4 * (0.5 + 0.5 * sin(t * 8.0)))
	if randf() < 0.08 * (base_alpha + glow):
		game.fx.spark(position, Color(1, 0.95, 0.6, base_alpha + glow))
	if say_t > 0.0:
		say_t -= dt
		bubble.position = Vector2(-bubble.size.x * 0.5, -bubble.size.y - 8.0).round()
		if say_t <= 0.0:
			bubble.visible = false
